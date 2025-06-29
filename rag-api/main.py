from fastapi import FastAPI, HTTPException, UploadFile, File
from pydantic import BaseModel
from qdrant_client import QdrantClient
from qdrant_client.models import Distance, VectorParams, PointStruct
import httpx
import os
import logging
import uuid
from typing import List, Optional
import re

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="RAG API", version="1.0.0")

QDRANT_HOST = os.getenv("QDRANT_HOST", "localhost")
QDRANT_PORT = os.getenv("QDRANT_PORT", "6333")
EMBEDDING_SERVICE_URL = os.getenv("EMBEDDING_SERVICE_URL", "http://localhost:8001")
COLLECTION_NAME = "documents"

qdrant_client = None

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

async def get_embeddings(texts: List[str]) -> List[List[float]]:
    """Get embeddings from the embedding service"""
    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{EMBEDDING_SERVICE_URL}/embeddings",
            json={"texts": texts},
            timeout=30.0
        )
        if response.status_code != 200:
            raise HTTPException(status_code=500, detail=f"Embedding service error: {response.text}")
        return response.json()["embeddings"]

@app.on_event("startup")
async def startup_event():
    global qdrant_client
    logger.info(f"Connecting to Qdrant at {QDRANT_HOST}:{QDRANT_PORT}")
    try:
        qdrant_client = QdrantClient(host=QDRANT_HOST, port=int(QDRANT_PORT))
        
        # Create collection if it doesn't exist
        collections = qdrant_client.get_collections().collections
        if not any(collection.name == COLLECTION_NAME for collection in collections):
            qdrant_client.create_collection(
                collection_name=COLLECTION_NAME,
                vectors_config=VectorParams(size=384, distance=Distance.COSINE)
            )
            logger.info(f"Created collection: {COLLECTION_NAME}")
        else:
            logger.info(f"Collection {COLLECTION_NAME} already exists")
            
    except Exception as e:
        logger.error(f"Failed to connect to Qdrant: {e}")
        raise e

@app.get("/health")
async def health_check():
    return {"status": "healthy", "qdrant_host": QDRANT_HOST}

@app.post("/ingest")
async def ingest_document(document: Document):
    try:
        # Chunk the document
        chunks = chunk_text(document.text)
        logger.info(f"Created {len(chunks)} chunks from document")
        
        # Get embeddings for all chunks
        embeddings = await get_embeddings(chunks)
        
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
        query_embedding = await get_embeddings([request.query])
        
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