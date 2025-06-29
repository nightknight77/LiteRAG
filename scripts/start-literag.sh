#!/bin/bash

# Enhanced LiteRAG startup script with health monitoring

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
COMPOSE_FILE="$PROJECT_ROOT/docker-compose.yml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
MAX_WAIT_TIME=180  # 3 minutes max wait time
HEALTH_CHECK_INTERVAL=5
RESOURCE_CHECK_INTERVAL=10

log() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[$(date '+%H:%M:%S')] WARNING:${NC} $1"
}

error() {
    echo -e "${RED}[$(date '+%H:%M:%S')] ERROR:${NC} $1"
}

success() {
    echo -e "${GREEN}[$(date '+%H:%M:%S')] SUCCESS:${NC} $1"
}

check_docker() {
    if ! command -v docker &> /dev/null; then
        error "Docker is not installed or not in PATH"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        error "Docker daemon is not running"
        exit 1
    fi
    
    success "Docker is available and running"
}

check_system_resources() {
    local available_memory=$(sysctl -n hw.memsize)
    local available_memory_gb=$((available_memory / 1024 / 1024 / 1024))
    
    log "System resources:"
    log "  Available memory: ${available_memory_gb}GB"
    log "  CPU cores: $(sysctl -n hw.ncpu)"
    
    if [ $available_memory_gb -lt 8 ]; then
        warn "Less than 8GB RAM available. LiteRAG may experience performance issues."
    fi
}

pre_flight_checks() {
    log "Running pre-flight checks..."
    
    check_docker
    check_system_resources
    
    # Check if ports are available
    local ports=(8000 8001 6333 6334)
    for port in "${ports[@]}"; do
        if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
            warn "Port $port is already in use"
        fi
    done
    
    # Create necessary directories
    mkdir -p "$PROJECT_ROOT/vector-db/storage"
    mkdir -p "$PROJECT_ROOT/embedding-service/models"
    mkdir -p "$PROJECT_ROOT/data"
    
    success "Pre-flight checks completed"
}

monitor_startup() {
    local service=$1
    local url=$2
    local max_attempts=$((MAX_WAIT_TIME / HEALTH_CHECK_INTERVAL))
    local attempt=0
    
    log "Monitoring $service startup..."
    
    while [ $attempt -lt $max_attempts ]; do
        if curl -s -f "$url" >/dev/null 2>&1; then
            success "$service is healthy"
            return 0
        fi
        
        attempt=$((attempt + 1))
        echo -n "."
        sleep $HEALTH_CHECK_INTERVAL
    done
    
    error "$service failed to become healthy within $MAX_WAIT_TIME seconds"
    return 1
}

# Simplified service check that just tests if port is responding
check_service_port() {
    local service=$1
    local port=$2
    local max_attempts=$((MAX_WAIT_TIME / HEALTH_CHECK_INTERVAL))
    local attempt=0
    
    log "Waiting for $service on port $port..."
    
    while [ $attempt -lt $max_attempts ]; do
        # Try nc first, fallback to bash TCP test
        if nc -z localhost $port 2>/dev/null || timeout 1 bash -c "</dev/tcp/localhost/$port" 2>/dev/null; then
            success "$service is responding on port $port"
            return 0
        fi
        
        attempt=$((attempt + 1))
        echo -n "."
        sleep $HEALTH_CHECK_INTERVAL
    done
    
    error "$service failed to start within $MAX_WAIT_TIME seconds"
    return 1
}

monitor_resources() {
    log "Monitoring container resource usage..."
    
    # Get container stats
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" \
        $(docker-compose -f "$COMPOSE_FILE" ps -q) 2>/dev/null || true
}

cleanup_on_exit() {
    echo
    log "Cleaning up..."
    # Kill background jobs
    jobs -p | xargs -r kill 2>/dev/null || true
}

main() {
    trap cleanup_on_exit EXIT
    
    echo "🚀 Starting LiteRAG - Local Second Brain System"
    echo "================================================"
    
    cd "$PROJECT_ROOT"
    
    pre_flight_checks
    
    log "Starting Docker Compose services..."
    docker-compose -f "$COMPOSE_FILE" up -d
    
    if [ $? -ne 0 ]; then
        error "Failed to start Docker Compose services"
        exit 1
    fi
    
    log "Services started. Waiting for health checks..."
    echo
    
    # Monitor each service startup
    local services_healthy=true
    
    # First check if ports are responding (faster)
    if ! check_service_port "Qdrant" "6333"; then
        services_healthy=false
    elif ! monitor_startup "Qdrant" "http://localhost:6333/"; then
        services_healthy=false
    fi
    
    if ! check_service_port "Embedding Service" "8001"; then
        services_healthy=false
    elif ! monitor_startup "Embedding Service" "http://localhost:8001/health"; then
        services_healthy=false
    fi
    
    if ! check_service_port "RAG API" "8000"; then
        services_healthy=false
    elif ! monitor_startup "RAG API" "http://localhost:8000/health"; then
        services_healthy=false
    fi
    
    echo
    
    if [ "$services_healthy" = true ]; then
        success "🎉 All services are healthy and ready!"
        echo
        log "Service URLs:"
        log "  RAG API:          http://localhost:8000"
        log "  Embedding Service: http://localhost:8001"
        log "  Qdrant Dashboard: http://localhost:6333/dashboard"
        echo
        log "API Documentation:"
        log "  RAG API Docs:     http://localhost:8000/docs"
        log "  Embedding Docs:   http://localhost:8001/docs"
        echo
        
        # Show initial resource usage
        monitor_resources
        
        # Start background resource monitoring if requested
        if [ "${1:-}" = "--monitor" ]; then
            log "Starting continuous resource monitoring (press Ctrl+C to stop)..."
            while true; do
                sleep $RESOURCE_CHECK_INTERVAL
                echo
                log "Resource usage update:"
                monitor_resources
            done
        else
            log "💡 Tip: Run with --monitor flag for continuous resource monitoring"
            log "💡 Tip: Use 'docker-compose logs -f' to view service logs"
        fi
    else
        error "❌ Some services failed to start properly"
        log "Checking service logs..."
        docker-compose -f "$COMPOSE_FILE" logs --tail=20
        exit 1
    fi
}

# Handle script arguments
case "${1:-}" in
    --help|-h)
        echo "LiteRAG Startup Script"
        echo
        echo "Usage: $0 [OPTIONS]"
        echo
        echo "Options:"
        echo "  --monitor    Start with continuous resource monitoring"
        echo "  --help, -h   Show this help message"
        echo
        echo "This script starts the LiteRAG system with optimizations for MacBook Pro M4."
        echo "It includes pre-flight checks, health monitoring, and resource tracking."
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac