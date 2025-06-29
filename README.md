# LiteRAG

[![CI](https://github.com/username/literag/workflows/CI/badge.svg)](https://github.com/username/literag/actions)
[![Security](https://github.com/username/literag/workflows/Security/badge.svg)](https://github.com/username/literag/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python 3.11+](https://img.shields.io/badge/python-3.11+-blue.svg)](https://www.python.org/downloads/)
[![Docker](https://img.shields.io/badge/docker-ready-blue.svg)](https://www.docker.com/)

A lightweight, containerized RAG (Retrieval-Augmented Generation) system for local deployment and workflow integration.

## Architecture

- **Qdrant**: Vector database for storing document embeddings
- **Embedding Service**: FastAPI service using sentence-transformers (all-MiniLM-L6-v2)
- **RAG API**: Main API service for document ingestion and querying
- **Docker Compose**: Orchestrates all services

## Quick Start

1. **Start the system:**
   ```bash
   docker-compose up -d
   ```

2. **Wait for services to initialize** (first run downloads models):
   ```bash
   docker-compose logs -f
   ```

3. **Test the system:**
   ```bash
   poetry install
   poetry run python tests/test_rag.py
   ```

## API Endpoints

### RAG API (Port 8000)

#### Health Check
```bash
curl http://localhost:8000/health
```

#### Ingest Document
```bash
curl -X POST http://localhost:8000/ingest \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Your document text here",
    "metadata": {"source": "example", "type": "text"}
  }'
```

#### Ingest File  
```bash
curl -X POST http://localhost:8000/ingest/file \
  -F "file=@your_document.txt"
```

#### Query Documents
```bash
curl -X POST http://localhost:8000/query \
  -H "Content-Type: application/json" \
  -d '{
    "query": "What is this about?",
    "limit": 5
  }'
```

#### Collection Info
```bash
curl http://localhost:8000/collections/info
```

### Embedding Service (Port 8001)

#### Health Check
```bash
curl http://localhost:8001/health
```

#### Generate Embeddings
```bash
curl -X POST http://localhost:8001/embeddings \
  -H "Content-Type: application/json" \
  -d '{"texts": ["Hello world", "Another text"]}'
```

## n8n Integration

For n8n workflows, use HTTP Request nodes:

1. **Document Ingestion Node:**
   - Method: POST
   - URL: `http://localhost:8000/ingest`
   - Body: JSON with `text` and optional `metadata`

2. **Query Node:**
   - Method: POST  
   - URL: `http://localhost:8000/query`
   - Body: JSON with `query` and optional `limit`

## Data Persistence

- Vector data: `./vector-db/storage/`
- Models cache: `./embedding-service/models/`
- Upload data: `./data/`

## Troubleshooting

### Check service status:
```bash
docker-compose ps
```

### View logs:
```bash
docker-compose logs rag-api
docker-compose logs embedding-service
docker-compose logs qdrant
```

### Restart services:
```bash
docker-compose restart
```

### Clean restart:
```bash
docker-compose down
docker-compose up -d
```

### Reset all data:
```bash
docker-compose down -v
rm -rf vector-db/storage embedding-service/models
docker-compose up -d
```

## Configuration

Environment variables in `docker-compose.yml`:

- `MODEL_NAME`: Embedding model (default: all-MiniLM-L6-v2)
- `QDRANT_HOST/PORT`: Vector database connection
- `EMBEDDING_SERVICE_URL`: Internal service URL

## System Requirements

- Docker & Docker Compose
- ~2GB RAM for models and services
- ~1GB disk space for models and data

## Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details on:

- Setting up the development environment
- Code style and standards
- Submitting pull requests
- Reporting issues

### Quick Start for Contributors

1. Fork the repository
2. Set up development environment: `./setup-dev.sh`
3. Make your changes
4. Run tests: `./dev-commands.sh test`
5. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Security

For security concerns, please review our [Security Policy](SECURITY.md).

## Acknowledgments

- [Qdrant](https://qdrant.tech/) for the vector database
- [sentence-transformers](https://www.sbert.net/) for embedding models
- [FastAPI](https://fastapi.tiangolo.com/) for the API framework