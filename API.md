# LiteRAG API Documentation

This document provides comprehensive API documentation for LiteRAG, designed for easy integration with MCP servers and other applications.

## Base URLs

- **RAG API**: `http://localhost:8000`
- **Embedding Service**: `http://localhost:8001`

## RAG API Endpoints

### Health Check

Check the health status of the RAG API service.

**Endpoint**: `GET /health`

**Response**:
```json
{
  "status": "healthy",
  "qdrant_host": "qdrant"
}
```

**Example**:
```bash
curl http://localhost:8000/health
```

---

### Ingest Document

Ingest a text document with optional metadata for semantic search.

**Endpoint**: `POST /ingest`

**Headers**:
- `Content-Type: application/json`

**Request Schema**:
```json
{
  "text": "string (required)",
  "metadata": "object (optional)"
}
```

**Request Example**:
```json
{
  "text": "Python is a high-level programming language known for its simplicity and readability.",
  "metadata": {
    "source": "programming_guide",
    "topic": "python",
    "author": "technical_writer"
  }
}
```

**Response Schema**:
```json
{
  "message": "string",
  "chunks": "integer"
}
```

**Response Example**:
```json
{
  "message": "Ingested document with 3 chunks",
  "chunks": 3
}
```

**Example**:
```bash
curl -X POST http://localhost:8000/ingest \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Python is a versatile programming language...",
    "metadata": {"source": "tutorial", "difficulty": "beginner"}
  }'
```

---

### Ingest File

Upload and ingest a text file for semantic search.

**Endpoint**: `POST /ingest/file`

**Headers**:
- `Content-Type: multipart/form-data`

**Request**: Multipart form with file upload

**Response Schema**:
```json
{
  "message": "string",
  "chunks": "integer"
}
```

**Example**:
```bash
curl -X POST http://localhost:8000/ingest/file \
  -F "file=@document.txt"
```

---

### Query Documents

Perform semantic search on ingested documents.

**Endpoint**: `POST /query`

**Headers**:
- `Content-Type: application/json`

**Request Schema**:
```json
{
  "query": "string (required)",
  "limit": "integer (optional, default: 10)"
}
```

**Request Example**:
```json
{
  "query": "What is Python programming?",
  "limit": 5
}
```

**Response Schema**:
```json
{
  "results": [
    {
      "text": "string",
      "score": "float",
      "metadata": "object"
    }
  ]
}
```

**Response Example**:
```json
{
  "results": [
    {
      "text": "Python is a high-level programming language known for its simplicity...",
      "score": 0.9234,
      "metadata": {
        "source": "programming_guide",
        "topic": "python",
        "chunk_index": 0
      }
    }
  ]
}
```

**Example**:
```bash
curl -X POST http://localhost:8000/query \
  -H "Content-Type: application/json" \
  -d '{
    "query": "machine learning libraries",
    "limit": 3
  }'
```

---

### Collection Information

Get information about the document collection.

**Endpoint**: `GET /collections/info`

**Response Schema**:
```json
{
  "collection": "string",
  "info": "object"
}
```

**Example**:
```bash
curl http://localhost:8000/collections/info
```

## Embedding Service Endpoints

### Health Check

Check the health status of the embedding service.

**Endpoint**: `GET /health`

**Response**:
```json
{
  "status": "healthy",
  "model": "all-MiniLM-L6-v2"
}
```

**Example**:
```bash
curl http://localhost:8001/health
```

---

### Generate Embeddings

Generate vector embeddings for an array of text strings.

**Endpoint**: `POST /embeddings`

**Headers**:
- `Content-Type: application/json`

**Request Schema**:
```json
{
  "texts": ["string", "string", ...]
}
```

**Request Example**:
```json
{
  "texts": [
    "Hello world",
    "This is a test sentence",
    "Machine learning is fascinating"
  ]
}
```

**Response Schema**:
```json
{
  "embeddings": [
    [0.1, 0.2, 0.3, ...],
    [0.4, 0.5, 0.6, ...],
    [0.7, 0.8, 0.9, ...]
  ]
}
```

**Example**:
```bash
curl -X POST http://localhost:8001/embeddings \
  -H "Content-Type: application/json" \
  -d '{
    "texts": ["Hello world", "Another text example"]
  }'
```

## Error Responses

All endpoints return standard HTTP status codes and JSON error responses.

### Common Error Format

```json
{
  "detail": "Error description"
}
```

### Status Codes

- **200**: Success
- **400**: Bad Request - Invalid input data
- **422**: Unprocessable Entity - Validation error
- **500**: Internal Server Error - Service unavailable or processing error

### Example Error Responses

**400 Bad Request**:
```json
{
  "detail": "Invalid request format"
}
```

**500 Internal Server Error**:
```json
{
  "detail": "Embedding service error: Connection failed"
}
```

## MCP Server Integration Notes

### Authentication
- No authentication required for local development
- All endpoints are publicly accessible on localhost

### Rate Limiting
- No rate limiting implemented
- Consider implementing client-side throttling for heavy usage

### Data Types
- All text inputs support UTF-8 encoding
- Embeddings are 384-dimensional float arrays
- Similarity scores range from 0.0 to 1.0 (higher = more similar)

### Best Practices
1. **Chunking**: Documents are automatically chunked (500 chars, 50 char overlap)
2. **Metadata**: Use consistent metadata schemas for better organization
3. **Query Optimization**: Keep queries concise and specific for better results
4. **Batch Processing**: Use single `/ingest` calls rather than multiple small ones

### Service Dependencies
- RAG API depends on both Qdrant and Embedding Service
- Embedding Service is independent
- Start all services with `docker-compose up -d` before API calls