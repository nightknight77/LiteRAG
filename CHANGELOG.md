# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Rebranded project to LiteRAG for better clarity
- Initial open source release preparation
- Comprehensive documentation and contributing guidelines
- GitHub Actions CI/CD workflows
- Security scanning and vulnerability reporting
- Issue and pull request templates

## [1.0.0] - 2024-12-29

### Added
- **RAG API Service**: FastAPI-based service for document ingestion and querying
  - Document text chunking with sentence boundary detection
  - REST API for document ingestion (`/ingest`, `/ingest/file`)
  - Semantic search endpoint (`/query`)
  - Collection management and health checks
- **Embedding Service**: Dedicated service for text vectorization
  - sentence-transformers integration (all-MiniLM-L6-v2 model)
  - Batch embedding generation
  - Model caching and management
- **Vector Database**: Qdrant integration for storing and searching embeddings
  - COSINE distance similarity
  - 384-dimensional vectors
  - Metadata storage and filtering
- **Docker Compose**: Complete containerized deployment
  - Service orchestration and networking
  - Volume management for persistence
  - Development and production configurations
- **Poetry Integration**: Modern Python dependency management
  - Development dependencies (testing, linting, formatting)
  - Lock files for reproducible builds
  - Docker integration with Poetry
- **Development Tools**:
  - Automated setup script (`setup-dev.sh`)
  - Development command wrapper (`dev-commands.sh`)
  - Code formatting (Black, isort)
  - Linting (flake8) and type checking (mypy)
  - Testing framework setup
- **API Documentation**: Comprehensive endpoint documentation
  - Request/response schemas
  - curl examples
  - MCP integration guidance
- **n8n Integration**: Ready for workflow automation
  - HTTP Request node examples
  - Webhook integration patterns

### Technical Details
- **Languages**: Python 3.11+
- **Frameworks**: FastAPI, Pydantic, sentence-transformers
- **Database**: Qdrant vector database
- **Deployment**: Docker, Docker Compose
- **Dependencies**: Poetry for package management
- **Architecture**: Microservices with REST APIs

### Documentation
- README with quick start guide
- API documentation with examples
- Development setup instructions
- Architecture overview
- Troubleshooting guide

[Unreleased]: https://github.com/username/literag/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/username/literag/releases/tag/v1.0.0