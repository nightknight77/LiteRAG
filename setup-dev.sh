#!/bin/bash
# Local Development Setup Script for LiteRAG

set -e

echo "🚀 Setting up LiteRAG for local development..."

# Check if Poetry is installed
if ! command -v poetry &> /dev/null; then
    echo "❌ Poetry not found. Installing Poetry..."
    curl -sSL https://install.python-poetry.org | python3 -
    echo "✅ Poetry installed. Please restart your terminal or run: source ~/.bashrc"
    exit 1
fi

echo "📦 Installing dependencies for RAG API..."
cd rag-api
poetry install
cd ..

echo "📦 Installing dependencies for Embedding Service..."
cd embedding-service
poetry install
cd ..

echo "🔧 Creating development environment files..."

# Create .env files if they don't exist
if [ ! -f rag-api/.env ]; then
    cat > rag-api/.env << EOF
QDRANT_HOST=localhost
QDRANT_PORT=6333
EMBEDDING_SERVICE_URL=http://localhost:8001
EOF
    echo "✅ Created rag-api/.env"
fi

if [ ! -f embedding-service/.env ]; then
    cat > embedding-service/.env << EOF
MODEL_NAME=all-MiniLM-L6-v2
EOF
    echo "✅ Created embedding-service/.env"
fi

echo "📋 Development setup complete!"
echo ""
echo "🔄 Next steps:"
echo "1. Start Qdrant: docker run -p 6333:6333 -p 6334:6334 qdrant/qdrant"
echo "2. Start Embedding Service: cd embedding-service && poetry run uvicorn main:app --port 8001"
echo "3. Start RAG API: cd rag-api && poetry run uvicorn main:app --port 8000"
echo ""
echo "Or use Docker Compose for the complete stack:"
echo "docker-compose up -d"