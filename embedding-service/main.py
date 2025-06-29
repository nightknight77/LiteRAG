from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from sentence_transformers import SentenceTransformer
import os
import logging
from typing import List

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="Embedding Service", version="1.0.0")

MODEL_NAME = os.getenv("MODEL_NAME", "all-MiniLM-L6-v2")
model = None

class EmbeddingRequest(BaseModel):
    texts: List[str]

class EmbeddingResponse(BaseModel):
    embeddings: List[List[float]]

@app.on_event("startup")
async def startup_event():
    global model
    logger.info(f"Loading model: {MODEL_NAME}")
    try:
        model = SentenceTransformer(MODEL_NAME, cache_folder="/app/models")
        logger.info("Model loaded successfully")
    except Exception as e:
        logger.error(f"Failed to load model: {e}")
        raise e

@app.get("/health")
async def health_check():
    return {"status": "healthy", "model": MODEL_NAME}

@app.post("/embeddings", response_model=EmbeddingResponse)
async def create_embeddings(request: EmbeddingRequest):
    if model is None:
        raise HTTPException(status_code=500, detail="Model not loaded")
    
    try:
        embeddings = model.encode(request.texts)
        return EmbeddingResponse(embeddings=embeddings.tolist())
    except Exception as e:
        logger.error(f"Error creating embeddings: {e}")
        raise HTTPException(status_code=500, detail=str(e))