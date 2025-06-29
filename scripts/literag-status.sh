#!/bin/bash

# LiteRAG Status and Resource Monitor
# Shows current system status and resource usage

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
COMPOSE_FILE="$PROJECT_ROOT/docker-compose.yml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}$1${NC}"
}

success() {
    echo -e "${GREEN}✓ $1${NC}"
}

error() {
    echo -e "${RED}✗ $1${NC}"
}

warn() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

info() {
    echo -e "${CYAN}ℹ $1${NC}"
}

check_service_health() {
    local service_name=$1
    local url=$2
    
    if curl -s -f "$url" >/dev/null 2>&1; then
        success "$service_name is healthy"
        return 0
    else
        error "$service_name is not responding"
        return 1
    fi
}

show_container_status() {
    log "Container Status:"
    echo "=================="
    
    if ! docker-compose -f "$COMPOSE_FILE" ps 2>/dev/null; then
        error "No containers found or docker-compose not accessible"
        return 1
    fi
    echo
}

show_resource_usage() {
    log "Resource Usage:"
    echo "==============="
    
    # Get container stats
    local containers=$(docker-compose -f "$COMPOSE_FILE" ps -q 2>/dev/null)
    
    if [ -z "$containers" ]; then
        error "No running containers found"
        return 1
    fi
    
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" $containers
    echo
    
    # Calculate total memory usage
    local total_memory=$(docker stats --no-stream --format "{{.MemUsage}}" $containers | \
        awk '{gsub(/[^0-9.]/, "", $1); sum += $1} END {printf "%.1f", sum}')
    
    info "Total estimated memory usage: ~${total_memory}MB"
    echo
}

show_service_health() {
    log "Service Health Checks:"
    echo "====================="
    
    check_service_health "Qdrant" "http://localhost:6333/health"
    check_service_health "Embedding Service" "http://localhost:8001/health"
    check_service_health "RAG API" "http://localhost:8000/health"
    echo
}

show_collection_info() {
    log "Qdrant Collection Info:"
    echo "======================="
    
    local collection_info=$(curl -s "http://localhost:8000/collections/info" 2>/dev/null)
    
    if [ $? -eq 0 ] && [ -n "$collection_info" ]; then
        echo "$collection_info" | python3 -m json.tool 2>/dev/null || echo "$collection_info"
    else
        warn "Could not retrieve collection information"
    fi
    echo
}

show_system_resources() {
    log "System Resources:"
    echo "================="
    
    local total_memory=$(sysctl -n hw.memsize)
    local total_memory_gb=$((total_memory / 1024 / 1024 / 1024))
    local cpu_cores=$(sysctl -n hw.ncpu)
    
    info "Total system memory: ${total_memory_gb}GB"
    info "CPU cores: $cpu_cores"
    
    # Memory pressure info (macOS specific)
    if command -v memory_pressure &> /dev/null; then
        local mem_pressure=$(memory_pressure 2>/dev/null | head -1)
        info "Memory pressure: $mem_pressure"
    fi
    
    echo
}

show_port_usage() {
    log "Port Usage:"
    echo "==========="
    
    local ports=(8000 8001 6333 6334)
    for port in "${ports[@]}"; do
        if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
            local process=$(lsof -Pi :$port -sTCP:LISTEN | tail -1 | awk '{print $1}')
            success "Port $port is in use by $process"
        else
            warn "Port $port is not in use"
        fi
    done
    echo
}

show_logs() {
    local service=${1:-}
    local lines=${2:-20}
    
    if [ -n "$service" ]; then
        log "Recent logs for $service (last $lines lines):"
        echo "=============================================="
        docker-compose -f "$COMPOSE_FILE" logs --tail=$lines "$service"
    else
        log "Recent logs for all services (last $lines lines):"
        echo "================================================="
        docker-compose -f "$COMPOSE_FILE" logs --tail=$lines
    fi
}

main() {
    cd "$PROJECT_ROOT"
    
    echo "🔍 LiteRAG System Status Report"
    echo "==============================="
    echo
    
    show_container_status
    show_service_health
    show_resource_usage
    show_system_resources
    show_port_usage
    show_collection_info
    
    case "${1:-}" in
        --logs|-l)
            show_logs "${2:-}" "${3:-20}"
            ;;
        --logs-follow|-f)
            log "Following logs (press Ctrl+C to stop):"
            docker-compose -f "$COMPOSE_FILE" logs -f "${2:-}"
            ;;
        --monitor|-m)
            log "Starting continuous monitoring (press Ctrl+C to stop):"
            while true; do
                clear
                main
                sleep 10
            done
            ;;
    esac
}

# Handle script arguments
case "${1:-}" in
    --help|-h)
        echo "LiteRAG Status Monitor"
        echo
        echo "Usage: $0 [OPTIONS] [SERVICE]"
        echo
        echo "Options:"
        echo "  --logs, -l [SERVICE] [LINES]    Show recent logs (default: 20 lines)"
        echo "  --logs-follow, -f [SERVICE]     Follow logs in real-time"
        echo "  --monitor, -m                   Continuous monitoring mode"
        echo "  --help, -h                      Show this help message"
        echo
        echo "Services: qdrant, embedding-service, rag-api"
        echo
        echo "Examples:"
        echo "  $0                              Show status report"
        echo "  $0 --logs rag-api 50           Show last 50 lines of rag-api logs"
        echo "  $0 --logs-follow               Follow all service logs"
        echo "  $0 --monitor                   Continuous monitoring"
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac