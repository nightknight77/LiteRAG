#!/bin/bash

# LiteRAG Cleanup and Maintenance Script
# Helps maintain optimal performance and clean up resources

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

log() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}[$(date '+%H:%M:%S')] ✓${NC} $1"
}

warn() {
    echo -e "${YELLOW}[$(date '+%H:%M:%S')] ⚠${NC} $1"
}

error() {
    echo -e "${RED}[$(date '+%H:%M:%S')] ✗${NC} $1"
}

confirm() {
    local prompt="$1"
    local default="${2:-n}"
    
    if [ "$default" = "y" ]; then
        prompt="$prompt [Y/n]"
    else
        prompt="$prompt [y/N]"
    fi
    
    read -p "$prompt: " -n 1 -r
    echo
    
    if [ "$default" = "y" ]; then
        [[ ! $REPLY =~ ^[Nn]$ ]]
    else
        [[ $REPLY =~ ^[Yy]$ ]]
    fi
}

stop_services() {
    log "Stopping LiteRAG services..."
    cd "$PROJECT_ROOT"
    
    if docker-compose -f "$COMPOSE_FILE" ps -q | grep -q .; then
        docker-compose -f "$COMPOSE_FILE" down
        success "Services stopped"
    else
        log "No running services found"
    fi
}

cleanup_docker() {
    log "Cleaning up Docker resources..."
    
    # Remove stopped containers
    local stopped_containers=$(docker ps -a -q --filter "status=exited")
    if [ -n "$stopped_containers" ]; then
        docker rm $stopped_containers
        success "Removed stopped containers"
    fi
    
    # Remove unused images
    docker image prune -f
    success "Removed unused images"
    
    # Remove unused volumes (with confirmation)
    if confirm "Remove unused Docker volumes? This will free up disk space"; then
        docker volume prune -f
        success "Removed unused volumes"
    fi
    
    # Remove unused networks
    docker network prune -f
    success "Removed unused networks"
}

clear_vector_db() {
    if confirm "Clear vector database? This will delete all ingested documents" "n"; then
        log "Clearing vector database..."
        rm -rf "$PROJECT_ROOT/vector-db/storage/"*
        success "Vector database cleared"
    fi
}

clear_model_cache() {
    if confirm "Clear embedding model cache? Models will be re-downloaded on next start" "n"; then
        log "Clearing model cache..."
        rm -rf "$PROJECT_ROOT/embedding-service/models/"*
        success "Model cache cleared"
    fi
}

optimize_qdrant() {
    log "Optimizing Qdrant storage..."
    
    # Start only Qdrant for optimization
    cd "$PROJECT_ROOT"
    docker-compose -f "$COMPOSE_FILE" up -d qdrant
    
    # Wait for Qdrant to be ready
    sleep 10
    
    # Trigger optimization
    curl -X POST "http://localhost:6333/collections/documents/index" \
         -H "Content-Type: application/json" \
         -d '{}' >/dev/null 2>&1 && success "Qdrant optimization triggered" || warn "Could not trigger optimization"
    
    docker-compose -f "$COMPOSE_FILE" stop qdrant
}

show_disk_usage() {
    log "Disk usage for LiteRAG components:"
    echo "=================================="
    
    if [ -d "$PROJECT_ROOT/vector-db/storage" ]; then
        local vector_size=$(du -sh "$PROJECT_ROOT/vector-db/storage" 2>/dev/null | cut -f1)
        echo "Vector database: $vector_size"
    fi
    
    if [ -d "$PROJECT_ROOT/embedding-service/models" ]; then
        local model_size=$(du -sh "$PROJECT_ROOT/embedding-service/models" 2>/dev/null | cut -f1)
        echo "Model cache: $model_size"
    fi
    
    if [ -d "$PROJECT_ROOT/data" ]; then
        local data_size=$(du -sh "$PROJECT_ROOT/data" 2>/dev/null | cut -f1)
        echo "Data directory: $data_size"
    fi
    
    # Docker usage
    echo
    echo "Docker usage:"
    docker system df
    echo
}

main() {
    echo "🧹 LiteRAG Cleanup and Maintenance"
    echo "=================================="
    echo
    
    case "${1:-}" in
        --quick|-q)
            log "Quick cleanup (no confirmations)..."
            stop_services
            cleanup_docker
            success "Quick cleanup completed"
            ;;
        --full|-f)
            log "Full cleanup with confirmations..."
            stop_services
            cleanup_docker
            clear_vector_db
            clear_model_cache
            success "Full cleanup completed"
            ;;
        --disk-usage|-d)
            show_disk_usage
            ;;
        --optimize|-o)
            optimize_qdrant
            ;;
        --stop|-s)
            stop_services
            ;;
        *)
            log "Interactive cleanup mode"
            echo
            show_disk_usage
            echo
            
            if confirm "Stop running services?"; then
                stop_services
            fi
            
            if confirm "Clean up Docker resources?"; then
                cleanup_docker
            fi
            
            clear_vector_db
            clear_model_cache
            
            if confirm "Optimize Qdrant database?"; then
                optimize_qdrant
            fi
            
            success "Cleanup completed"
            ;;
    esac
}

# Handle script arguments
case "${1:-}" in
    --help|-h)
        echo "LiteRAG Cleanup and Maintenance"
        echo
        echo "Usage: $0 [OPTIONS]"
        echo
        echo "Options:"
        echo "  --quick, -q      Quick cleanup (stop services, clean Docker)"
        echo "  --full, -f       Full cleanup with confirmations"
        echo "  --disk-usage, -d Show disk usage for components"
        echo "  --optimize, -o   Optimize Qdrant database"
        echo "  --stop, -s       Just stop services"
        echo "  --help, -h       Show this help message"
        echo
        echo "Default: Interactive mode with confirmations"
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac