import asyncio
import logging
import os
from typing import List

import torch
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from sentence_transformers import SentenceTransformer

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="Embedding Service", version="1.0.0")

MODEL_NAME = os.getenv("MODEL_NAME", "all-MiniLM-L6-v2")
BATCH_SIZE = int(os.getenv("BATCH_SIZE", "32"))
MAX_CONCURRENT_REQUESTS = int(os.getenv("MAX_CONCURRENT_REQUESTS", "5"))
TORCH_NUM_THREADS = int(os.getenv("TORCH_NUM_THREADS", "2"))

model = None
request_semaphore = None


@app.on_event("startup")
async def startup_event():
    global model, request_semaphore

    # Configure PyTorch for memory efficiency
    torch.set_num_threads(TORCH_NUM_THREADS)
    if torch.cuda.is_available():
        torch.cuda.empty_cache()

    # Initialize request limiting
    request_semaphore = asyncio.Semaphore(MAX_CONCURRENT_REQUESTS)

    logger.info(f"Loading model: {MODEL_NAME}")
    try:
        model = SentenceTransformer(MODEL_NAME, cache_folder="/app/models")
        # Optimize model for inference
        model.eval()
        logger.info(f"Model loaded successfully with batch_size={BATCH_SIZE}")
    except Exception as e:
        logger.error(f"Failed to load model: {e}")
        raise e


class EmbeddingRequest(BaseModel):
    texts: List[str]


class EmbeddingResponse(BaseModel):
    embeddings: List[List[float]]


def batch_texts(texts: List[str], batch_size: int) -> List[List[str]]:
    """Split texts into batches for memory-efficient processing"""
    return [texts[i : i + batch_size] for i in range(0, len(texts), batch_size)]


@app.get("/health")
async def health_check():
    return {"status": "healthy", "model": MODEL_NAME}


@app.post("/embeddings", response_model=EmbeddingResponse)
async def create_embeddings(request: EmbeddingRequest):
    if model is None:
        raise HTTPException(status_code=500, detail="Model not loaded")

    async with request_semaphore:
        try:
            # Process in batches to manage memory
            all_embeddings = []
            text_batches = batch_texts(request.texts, BATCH_SIZE)

            for batch in text_batches:
                # Run encoding in thread pool to avoid blocking
                batch_embeddings = await asyncio.get_event_loop().run_in_executor(
                    None,
                    lambda: model.encode(
                        batch, convert_to_tensor=False, show_progress_bar=False
                    ),
                )
                all_embeddings.extend(batch_embeddings.tolist())

                # Clear memory between batches
                if torch.cuda.is_available():
                    torch.cuda.empty_cache()

            return EmbeddingResponse(embeddings=all_embeddings)

        except Exception as e:
            logger.error(f"Error creating embeddings: {e}")
            raise HTTPException(status_code=500, detail=str(e))
