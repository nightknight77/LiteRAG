from fastapi import FastAPI, HTTPException, UploadFile, File
from pydantic import BaseModel
from qdrant_client import QdrantClient
from qdrant_client.models import Distance, VectorParams, PointStruct
import httpx
import os
import logging
import uuid
import asyncio
from typing import List, Optional
import re

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="RAG API", version="1.0.0")

QDRANT_HOST = os.getenv("QDRANT_HOST", "localhost")
QDRANT_PORT = os.getenv("QDRANT_PORT", "6333")
EMBEDDING_SERVICE_URL = os.getenv("EMBEDDING_SERVICE_URL", "http://localhost:8001")
COLLECTION_NAME = "documents"
MAX_CONCURRENT_REQUESTS = int(os.getenv("MAX_CONCURRENT_REQUESTS", "10"))
REQUEST_TIMEOUT = int(os.getenv("REQUEST_TIMEOUT", "30"))
MAX_BATCH_SIZE = int(os.getenv("MAX_BATCH_SIZE", "50"))

qdrant_client = None
request_semaphore = None
http_client = None

@app.on_event("startup")
async def startup_event():
    global qdrant_client, request_semaphore, http_client
    
    # Initialize request limiting
    request_semaphore = asyncio.Semaphore(MAX_CONCURRENT_REQUESTS)
    
    # Initialize persistent HTTP client
    http_client = httpx.AsyncClient(timeout=REQUEST_TIMEOUT)
    
    logger.info(f"Connecting to Qdrant at {QDRANT_HOST}:{QDRANT_PORT}")
    try:
        qdrant_client = QdrantClient(host=QDRANT_HOST, port=int(QDRANT_PORT))
        
        # Create collection if it doesn't exist
        collections = qdrant_client.get_collections().collections
        if not any(collection.name == COLLECTION_NAME for collection in collections):
            qdrant_client.create_collection(
                collection_name=COLLECTION_NAME,
                vectors_config=VectorParams(size=768, distance=Distance.COSINE)
            )
            logger.info(f"Created collection: {COLLECTION_NAME}")
        else:
            logger.info(f"Collection {COLLECTION_NAME} already exists")
            
    except Exception as e:
        logger.error(f"Failed to connect to Qdrant: {e}")
        raise e

class Document(BaseModel):
    text: str
    metadata: Optional[dict] = {}

class QueryRequest(BaseModel):
    query: str
    limit: Optional[int] = 10

class QueryResponse(BaseModel):
    results: List[dict]

def chunk_text(text: str, chunk_size: int = 500, overlap: int = 50) -> List[str]:
    """Simple text chunking by character count with overlap"""
    if len(text) <= chunk_size:
        return [text]
    
    chunks = []
    start = 0
    while start < len(text):
        end = start + chunk_size
        chunk = text[start:end]
        
        # Try to break at sentence boundary
        if end < len(text):
            last_period = chunk.rfind('.')
            last_newline = chunk.rfind('\n')
            break_point = max(last_period, last_newline)
            if break_point > start + chunk_size // 2:
                chunk = text[start:break_point + 1]
                end = break_point + 1
        
        chunks.append(chunk.strip())
        start = end - overlap
        
        if start >= len(text):
            break
    
    return [chunk for chunk in chunks if chunk.strip()]

async def get_embeddings_batch(texts: List[str]) -> List[List[float]]:
    """Get embeddings from the embedding service with intelligent batching"""
    if len(texts) <= MAX_BATCH_SIZE:
        return await _get_embeddings_single_batch(texts)
    
    # Split into smaller batches for memory efficiency
    all_embeddings = []
    for i in range(0, len(texts), MAX_BATCH_SIZE):
        batch = texts[i:i + MAX_BATCH_SIZE]
        batch_embeddings = await _get_embeddings_single_batch(batch)
        all_embeddings.extend(batch_embeddings)
    
    return all_embeddings

async def _get_embeddings_single_batch(texts: List[str]) -> List[List[float]]:
    """Get embeddings for a single batch"""
    async with request_semaphore:
        response = await http_client.post(
            f"{EMBEDDING_SERVICE_URL}/embeddings",
            json={"texts": texts}
        )
        if response.status_code != 200:
            raise HTTPException(status_code=500, detail=f"Embedding service error: {response.text}")
        return response.json()["embeddings"]


@app.get("/health")
async def health_check():
    return {"status": "healthy", "qdrant_host": QDRANT_HOST}

@app.post("/ingest")
async def ingest_document(document: Document):
    try:
        # Chunk the document
        chunks = chunk_text(document.text)
        logger.info(f"Created {len(chunks)} chunks from document")
        
        # Get embeddings for all chunks with intelligent batching
        embeddings = await get_embeddings_batch(chunks)
        
        # Store in Qdrant
        points = []
        for i, (chunk, embedding) in enumerate(zip(chunks, embeddings)):
            point_id = str(uuid.uuid4())
            points.append(PointStruct(
                id=point_id,
                vector=embedding,
                payload={
                    "text": chunk,
                    "chunk_index": i,
                    **document.metadata
                }
            ))
        
        qdrant_client.upsert(
            collection_name=COLLECTION_NAME,
            points=points
        )
        
        return {"message": f"Ingested document with {len(chunks)} chunks", "chunks": len(chunks)}
        
    except Exception as e:
        logger.error(f"Error ingesting document: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/ingest/file")
async def ingest_file(file: UploadFile = File(...)):
    try:
        content = await file.read()
        text = content.decode('utf-8')
        
        document = Document(
            text=text,
            metadata={"filename": file.filename, "content_type": file.content_type}
        )
        
        return await ingest_document(document)
        
    except Exception as e:
        logger.error(f"Error ingesting file: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/query", response_model=QueryResponse)
async def query_documents(request: QueryRequest):
    try:
        # Get embedding for query
        query_embedding = await get_embeddings_batch([request.query])
        
        # Search in Qdrant
        search_results = qdrant_client.search(
            collection_name=COLLECTION_NAME,
            query_vector=query_embedding[0],
            limit=request.limit
        )
        
        results = []
        for result in search_results:
            results.append({
                "text": result.payload["text"],
                "score": result.score,
                "metadata": {k: v for k, v in result.payload.items() if k != "text"}
            })
        
        return QueryResponse(results=results)
        
    except Exception as e:
        logger.error(f"Error querying documents: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/collections/info")
async def get_collection_info():
    try:
        info = qdrant_client.get_collection(COLLECTION_NAME)
        return {"collection": COLLECTION_NAME, "info": info}
    except Exception as e:
        logger.error(f"Error getting collection info: {e}")
        raise HTTPException(status_code=500, detail=str(e))