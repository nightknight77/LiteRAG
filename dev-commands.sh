#!/bin/bash
# Development Commands for RAG System

set -e

# Color codes for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

show_help() {
    echo -e "${BLUE}LiteRAG Development Commands${NC}"
    echo ""
    echo "Usage: ./dev-commands.sh [command]"
    echo ""
    echo "Commands:"
    echo "  install      Install all dependencies"
    echo "  test         Run tests for all services"
    echo "  lint         Run linting for all services"
    echo "  format       Format code with black and isort"
    echo "  typecheck    Run mypy type checking"
    echo "  start-local  Start services locally (requires Qdrant running)"
    echo "  clean        Clean Poetry caches and lock files"
    echo ""
    echo "Docker commands:"
    echo "  docker-build  Build Docker images"
    echo "  docker-up     Start with Docker Compose"
    echo "  docker-down   Stop Docker Compose"
    echo "  docker-logs   View Docker logs"
}

install_deps() {
    echo -e "${GREEN}📦 Installing dependencies...${NC}"
    echo "Installing RAG API dependencies..."
    cd rag-api && poetry install && cd ..
    echo "Installing Embedding Service dependencies..."
    cd embedding-service && poetry install && cd ..
    echo -e "${GREEN}✅ Dependencies installed${NC}"
}

run_tests() {
    echo -e "${GREEN}🧪 Running tests...${NC}"
    echo "Running integration tests from root directory..."
    poetry run pytest tests/ -v
    echo -e "${GREEN}✅ Tests completed${NC}"
}

run_lint() {
    echo -e "${GREEN}🔍 Running linting...${NC}"
    echo "Linting RAG API..."
    cd rag-api && poetry run flake8 . && cd ..
    echo "Linting Embedding Service..."
    cd embedding-service && poetry run flake8 . && cd ..
    echo -e "${GREEN}✅ Linting completed${NC}"
}

format_code() {
    echo -e "${GREEN}🎨 Formatting code...${NC}"
    echo "Formatting RAG API..."
    cd rag-api && poetry run black . && poetry run isort . && cd ..
    echo "Formatting Embedding Service..."
    cd embedding-service && poetry run black . && poetry run isort . && cd ..
    echo -e "${GREEN}✅ Code formatted${NC}"
}

run_typecheck() {
    echo -e "${GREEN}🔍 Running type checking...${NC}"
    echo "Type checking RAG API..."
    cd rag-api && poetry run mypy . && cd ..
    echo "Type checking Embedding Service..."
    cd embedding-service && poetry run mypy . && cd ..
    echo -e "${GREEN}✅ Type checking completed${NC}"
}

start_local() {
    echo -e "${YELLOW}🚀 Starting services locally...${NC}"
    echo -e "${YELLOW}Make sure Qdrant is running: docker run -p 6333:6333 qdrant/qdrant${NC}"
    echo ""
    echo "Starting Embedding Service on port 8001..."
    cd embedding-service
    poetry run uvicorn main:app --port 8001 &
    EMBEDDING_PID=$!
    cd ..
    
    echo "Starting RAG API on port 8000..."
    cd rag-api
    poetry run uvicorn main:app --port 8000 &
    RAG_PID=$!
    cd ..
    
    echo -e "${GREEN}✅ Services started${NC}"
    echo "Embedding Service PID: $EMBEDDING_PID"
    echo "RAG API PID: $RAG_PID"
    echo ""
    echo "To stop services:"
    echo "kill $EMBEDDING_PID $RAG_PID"
}

clean_cache() {
    echo -e "${GREEN}🧹 Cleaning caches...${NC}"
    cd rag-api && poetry cache clear --all pypi && cd ..
    cd embedding-service && poetry cache clear --all pypi && cd ..
    rm -f rag-api/poetry.lock embedding-service/poetry.lock
    echo -e "${GREEN}✅ Caches cleaned${NC}"
}

docker_build() {
    echo -e "${GREEN}🐳 Building Docker images...${NC}"
    docker-compose build
    echo -e "${GREEN}✅ Docker images built${NC}"
}

docker_up() {
    echo -e "${GREEN}🐳 Starting with Docker Compose...${NC}"
    docker-compose up -d
    echo -e "${GREEN}✅ Services started with Docker${NC}"
}

docker_down() {
    echo -e "${GREEN}🐳 Stopping Docker Compose...${NC}"
    docker-compose down
    echo -e "${GREEN}✅ Docker services stopped${NC}"
}

docker_logs() {
    echo -e "${GREEN}🐳 Viewing Docker logs...${NC}"
    docker-compose logs -f
}

# Main command dispatcher
case "${1:-help}" in
    "install")
        install_deps
        ;;
    "test")
        run_tests
        ;;
    "lint")
        run_lint
        ;;
    "format")
        format_code
        ;;
    "typecheck")
        run_typecheck
        ;;
    "start-local")
        start_local
        ;;
    "clean")
        clean_cache
        ;;
    "docker-build")
        docker_build
        ;;
    "docker-up")
        docker_up
        ;;
    "docker-down")
        docker_down
        ;;
    "docker-logs")
        docker_logs
        ;;
    "help"|*)
        show_help
        ;;
esac