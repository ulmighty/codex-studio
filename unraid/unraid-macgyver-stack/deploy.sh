#!/bin/bash
# ============================================================================
# UNRAID MACGYVER STACK - MASTER DEPLOYMENT SCRIPT
# ============================================================================
# Atlas - Expert Unraid & Docker Solutions Architect
# Version: 1.0.0
# ============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Load environment variables
PROJECT_ROOT="/mnt/user/docker_builds/unraid-macgyver-stack"
cd "$PROJECT_ROOT"

if [ ! -f ".env" ]; then
    echo -e "${RED}Error: .env file not found!${NC}"
    exit 1
fi

source .env

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_section() {
    echo -e "\n${PURPLE}============================================================${NC}"
    echo -e "${PURPLE}$1${NC}"
    echo -e "${PURPLE}============================================================${NC}\n"
}

# Check if running on Unraid
check_unraid() {
    if [ ! -f "/etc/unraid-version" ]; then
        log_error "This script must be run on Unraid!"
        exit 1
    fi
}

# Check Docker version
check_docker() {
    local docker_version=$(docker version --format '{{.Server.Version}}' 2>/dev/null)
    if [ -z "$docker_version" ]; then
        log_error "Docker is not installed or not running!"
        exit 1
    fi
    log_info "Docker version: $docker_version"
}

# Check for required tools
check_dependencies() {
    local deps=("docker" "openssl" "jq" "curl" "git")
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            log_error "Missing dependency: $dep"
            exit 1
        fi
    done
    
    log_success "All dependencies verified"
}

# ============================================================================
# STAGE 1: INITIAL ANALYSIS & RESEARCH
# ============================================================================

stage1_research() {
    log_section "STAGE 1: INITIAL ANALYSIS & RESEARCH"
    
    # Create research documentation
    mkdir -p "$PROJECT_ROOT/docs/research"
    
    # Document base image strategy
    cat > "$PROJECT_ROOT/docs/research/base-image-strategy.md" << 'EOF'
# Base Image Strategy

## Selected Base Images

1. **debian:bullseye-slim** (18 apps)
   - Stable, well-tested base
   - Excellent package availability
   - Python, .NET, Node.js support
   - Size: ~80MB base

2. **alpine:latest** (8 apps) 
   - Minimal attack surface
   - Size: ~5MB base
   - Perfect for Go binaries
   - musl libc (watch for compatibility)

3. **nvidia/cuda:12.3.1-runtime-ubuntu22.04** (3 apps)
   - GPU acceleration support
   - CUDA 12.3.1 for latest GPUs
   - Ubuntu 22.04 LTS base
   - Size: ~2GB (includes CUDA)

4. **php:8.3-fpm-alpine** (4 apps)
   - Latest PHP 8.3
   - FPM for performance
   - Alpine for minimal size
   - Size: ~30MB base

## Security Hardening

- Non-root user (uid:99, gid:100 for Unraid)
- Minimal packages installed
- No package manager in final stage
- Read-only root filesystem where possible
- Dropped capabilities
- Security scanning with Trivy
EOF

    # Document Vault integration patterns
    cat > "$PROJECT_ROOT/docs/research/vault-patterns.md" << 'EOF'
# Vault Integration Patterns

## Bidirectional Flow

### INTO Applications
- Vault Agent sidecar pattern
- Template rendering for configs
- Environment variable injection
- File-based secret delivery

### FROM Applications
- API key harvesting
- Service URL registration
- Health status updates
- Metric collection

## AppRole Authentication
- One AppRole per application
- Least-privilege policies
- Auto-renewal of tokens
- Wrapped secret IDs

## Secret Paths
```
secret/
├── global/           # Shared secrets
├── <app>/           # App-specific secrets
│   ├── api_key      # Generated API key
│   ├── url          # Service URL
│   └── config/      # Configuration values
└── integration/     # Inter-app connections
```
EOF

    log_success "Research documentation created"
    
    # Analyze existing Docker containers for port conflicts
    log_info "Analyzing existing Docker containers..."
    
    local used_ports=$(docker ps --format "table {{.Ports}}" | grep -oE '[0-9]+' | sort -nu || true)
    
    if [ -n "$used_ports" ]; then
        echo "$used_ports" > "$PROJECT_ROOT/docs/research/used-ports.txt"
        log_warning "Found existing containers using ports. Saved to used-ports.txt"
    fi
    
    log_success "Stage 1 complete: Research and analysis documented"
}

# ============================================================================
# STAGE 2: FOUNDATION INFRASTRUCTURE
# ============================================================================

stage2_foundation() {
    log_section "STAGE 2: FOUNDATION INFRASTRUCTURE"
    
    # Create Docker network
    if ! docker network inspect "$NETWORK_NAME" &> /dev/null; then
        log_info "Creating Docker network: $NETWORK_NAME"
        docker network create \
            --driver bridge \
            --subnet 172.25.0.0/16 \
            --gateway 172.25.0.1 \
            --opt com.docker.network.bridge.name="br-macgyver" \
            "$NETWORK_NAME"
        log_success "Network created"
    else
        log_info "Network $NETWORK_NAME already exists"
    fi
    
    # Generate mkcert certificates
    if [ "$SKIP_CERT_GENERATION" != "true" ]; then
        log_info "Generating TLS certificates..."
        ./build/scripts/generate-certs.sh
    fi
    
    # Deploy core infrastructure in order
    log_info "Deploying Vault..."
    ./build/scripts/deploy-vault.sh
    
    log_info "Deploying Traefik..."
    ./build/scripts/deploy-traefik.sh
    
    log_info "Deploying Gluetun VPN..."
    ./build/scripts/deploy-gluetun.sh
    
    log_info "Deploying PostgreSQL..."
    ./build/scripts/deploy-postgresql.sh
    
    log_success "Stage 2 complete: Foundation infrastructure deployed"
}

# ============================================================================
# STAGE 3: PREPARE BASE IMAGES
# ============================================================================

stage3_base_images() {
    log_section "STAGE 3: PREPARE BASE IMAGES"
    
    log_info "Generating application configurations..."
    ./build/scripts/app-builder.sh
    
    log_success "Stage 3 complete: Base images and configurations prepared"
}

# ============================================================================
# STAGE 4: DEPLOY APPLICATIONS
# ============================================================================

stage4_deploy_apps() {
    log_section "STAGE 4: DEPLOY APPLICATIONS"
    
    log_info "Deploying all applications..."
    ./build/scripts/deploy-all-apps.sh all
    
    log_success "Stage 4 complete: All applications deployed"
}

# ============================================================================
# STAGE 5: CONFIGURE INTEGRATIONS
# ============================================================================

stage5_integrations() {
    log_section "STAGE 5: CONFIGURE INTEGRATIONS"
    
    log_info "Configuring Vault policies for applications..."
    ./build/scripts/configure-vault-policies.sh
    
    log_info "Setting up inter-app connections..."
    ./build/scripts/configure-app-connections.sh
    
    log_success "Stage 5 complete: Integrations configured"
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
    log_section "UNRAID MACGYVER STACK DEPLOYMENT"
    log_info "Project: $PROJECT_NAME v$BUILD_VERSION"
    log_info "Domain: $DOMAIN"
    log_info "Build Path: $BUILD_PATH"
    
    # Pre-flight checks
    check_unraid
    check_docker
    check_dependencies
    
    # Execute stages based on arguments
    case "${1:-all}" in
        "stage1"|"research")
            stage1_research
            ;;
        "stage2"|"foundation")
            stage2_foundation
            ;;
        "stage3"|"prepare")
            stage3_base_images
            ;;
        "stage4"|"deploy")
            stage4_deploy_apps
            ;;
        "stage5"|"integrate")
            stage5_integrations
            ;;
        "all")
            stage1_research
            stage2_foundation
            stage3_base_images
            stage4_deploy_apps
            stage5_integrations
            ;;
        *)
            echo "Usage: $0 [stage1|stage2|stage3|stage4|stage5|all]"
            echo "  stage1: Research and analysis"
            echo "  stage2: Deploy core infrastructure (Vault, Traefik, Gluetun, PostgreSQL)"
            echo "  stage3: Prepare base images and generate configurations"
            echo "  stage4: Deploy all applications"
            echo "  stage5: Configure integrations and connections"
            echo "  all: Run all stages"
            exit 1
            ;;
    esac
    
    log_success "Deployment script completed successfully!"
}

# Run main function
main "$@"