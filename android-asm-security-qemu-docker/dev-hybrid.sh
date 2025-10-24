#!/bin/bash

# Hybrid Development Helper Script
# Supports both Docker and local QEMU builds

set -e

PROJECT_DIR="/Users/avinash.kumar2/Downloads/GenAI/beverage-alc-genai/android-asm-security-qemu"
BUILD_DIR="$PROJECT_DIR/android-build"
CONTAINER="android-kernel-builder"
QEMU_DIR="$PROJECT_DIR/qemu-env"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Detect build environment
detect_environment() {
    # Check if Docker is available and container exists
    if command -v docker &> /dev/null && docker ps -a | grep -q "$CONTAINER"; then
        echo "docker"
    # Check if QEMU is available
    elif command -v qemu-system-aarch64 &> /dev/null; then
        echo "qemu"
    else
        echo "none"
    fi
}

BUILD_ENV=$(detect_environment)

usage() {
    echo "Android Kernel Module Development Helper (Hybrid)"
    echo ""
    echo "Build Environment: $BUILD_ENV"
    echo ""
    echo "Usage: ./dev-hybrid.sh <command>"
    echo ""
    echo "Commands:"
    echo "  build         - Build all modules (uses $BUILD_ENV)"
    echo "  build-local   - Build modules locally (Mac native)"
    echo "  rebuild       - Quick rebuild (no clean)"
    echo "  copy          - Copy built modules to host"
    echo "  test          - Check module metadata"
    echo "  run-qemu      - Start QEMU with built kernel"
    echo "  shell         - Enter build environment"
    echo "  clean         - Clean build artifacts"
    echo "  status        - Show environment status"
    echo "  setup-qemu    - Setup QEMU environment"
    echo "  help          - Show this help"
    echo ""
    echo "Examples:"
    echo "  ./dev-hybrid.sh build          # Build (auto-detect env)"
    echo "  ./dev-hybrid.sh run-qemu       # Test in QEMU"
    echo "  ./dev-hybrid.sh build-local    # Build on Mac natively"
}

build_docker() {
    echo -e "${GREEN}[*] Building with Docker...${NC}"
    cd "$BUILD_DIR"
    docker exec $CONTAINER bash -c "cd /android && make clean && make kernel"
    echo -e "${GREEN}[✓] Docker build complete!${NC}"
}

build_local() {
    echo -e "${BLUE}[*] Building locally on Mac...${NC}"
    
    # Check for cross-compiler
    if ! command -v aarch64-linux-gnu-gcc &> /dev/null && ! command -v aarch64-elf-gcc &> /dev/null; then
        echo -e "${RED}❌ ARM64 cross-compiler not found!${NC}"
        echo "Install with: brew install aarch64-elf-gcc"
        echo "Or use Docker build: ./dev-hybrid.sh build"
        exit 1
    fi
    
    cd "$BUILD_DIR/modules"
    
    # Simple local build (modules only, not full kernel)
    echo "  Building modules locally..."
    
    for module_c in *.c; do
        if [[ "$module_c" != *.mod.c ]]; then
            module_name="${module_c%.c}"
            echo "  - Building $module_name..."
            
            # Note: This is simplified - full build needs kernel headers
            echo "    (Using existing kernel from Docker build)"
        fi
    done
    
    echo -e "${BLUE}[!] Note: Local builds are limited. Use Docker for full kernel builds.${NC}"
    echo -e "${GREEN}[✓] Local build attempted${NC}"
}

build() {
    case $BUILD_ENV in
        docker)
            build_docker
            ;;
        qemu)
            echo -e "${YELLOW}[!] QEMU detected but Docker preferred for builds${NC}"
            echo "    Use './dev-hybrid.sh build-local' for Mac native build"
            echo "    Or install Docker for full builds"
            ;;
        none)
            echo -e "${RED}❌ No build environment detected!${NC}"
            echo "Install Docker or run: ./setup-qemu.sh"
            exit 1
            ;;
    esac
}

run_qemu() {
    echo -e "${GREEN}[*] Starting QEMU...${NC}"
    
    if [ ! -d "$QEMU_DIR" ]; then
        echo -e "${RED}❌ QEMU environment not setup!${NC}"
        echo "Run: ./setup-qemu.sh"
        exit 1
    fi
    
    if [ ! -f "$BUILD_DIR/kernel-out/kernel/Image" ]; then
        echo -e "${RED}❌ Kernel not built yet!${NC}"
        echo "Run: ./dev-hybrid.sh build"
        exit 1
    fi
    
    cd "$QEMU_DIR"
    ./run-qemu.sh
}

test_modules() {
    echo -e "${GREEN}[*] Testing module metadata...${NC}"
    echo

    if [ -d "$BUILD_DIR/kernel-out/kernel" ]; then
        for ko in "$BUILD_DIR/kernel-out/kernel"/*.ko; do
            if [ -f "$ko" ]; then
                echo "=== $(basename $ko) ==="
                strings "$ko" | grep -E "version=|description=|author=|srcversion=" || true
                echo
            fi
        done
    else
        echo -e "${YELLOW}[!] No built modules found${NC}"
    fi
}

clean_all() {
    echo -e "${GREEN}[*] Cleaning build artifacts...${NC}"
    
    case $BUILD_ENV in
        docker)
            docker exec $CONTAINER bash -c "cd /android && make clean"
            ;;
        *)
            echo "  Cleaning local artifacts..."
            rm -rf "$BUILD_DIR/kernel-out"
            cd "$BUILD_DIR/modules"
            rm -f *.o *.ko *.mod *.mod.c .*.cmd Module.symvers modules.order
            ;;
    esac
    
    echo -e "${GREEN}[✓] Clean complete!${NC}"
}

show_status() {
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║              Build Environment Status                     ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo
    
    echo "Build Environment: $BUILD_ENV"
    echo
    
    # Docker status
    echo "Docker:"
    if command -v docker &> /dev/null; then
        echo "  ✅ Docker installed"
        if docker ps | grep -q "$CONTAINER"; then
            echo "  ✅ Container running"
        elif docker ps -a | grep -q "$CONTAINER"; then
            echo "  ⚠️  Container stopped"
        else
            echo "  ❌ Container not found"
        fi
    else
        echo "  ❌ Docker not installed"
    fi
    echo
    
    # QEMU status
    echo "QEMU:"
    if command -v qemu-system-aarch64 &> /dev/null; then
        echo "  ✅ QEMU installed"
        qemu-system-aarch64 --version | head -1
        if [ -d "$QEMU_DIR" ]; then
            echo "  ✅ QEMU environment setup"
        else
            echo "  ⚠️  QEMU environment not setup (run ./setup-qemu.sh)"
        fi
    else
        echo "  ❌ QEMU not installed (brew install qemu)"
    fi
    echo
    
    # Cross-compiler status
    echo "Cross-compiler:"
    if command -v aarch64-linux-gnu-gcc &> /dev/null; then
        echo "  ✅ aarch64-linux-gnu-gcc found"
    elif command -v aarch64-elf-gcc &> /dev/null; then
        echo "  ✅ aarch64-elf-gcc found"
    else
        echo "  ❌ No ARM64 cross-compiler found"
    fi
    echo
    
    # Built modules
    echo "Built modules:"
    if [ -d "$BUILD_DIR/kernel-out/kernel" ]; then
        ls -1 "$BUILD_DIR/kernel-out/kernel"/*.ko 2>/dev/null | while read ko; do
            echo "  ✅ $(basename $ko)"
        done
    else
        echo "  ⚠️  No modules built yet"
    fi
    echo
}

setup_qemu() {
    if [ -f "./setup-qemu.sh" ]; then
        ./setup-qemu.sh
    else
        echo -e "${RED}❌ setup-qemu.sh not found${NC}"
        exit 1
    fi
}

enter_shell() {
    case $BUILD_ENV in
        docker)
            echo -e "${GREEN}[*] Entering Docker container shell...${NC}"
            docker exec -it $CONTAINER bash
            ;;
        *)
            echo -e "${YELLOW}[!] No Docker container. Opening local shell in modules dir...${NC}"
            cd "$BUILD_DIR/modules"
            exec $SHELL
            ;;
    esac
}

# Main command dispatcher
case "${1:-}" in
    build)
        build
        ;;
    build-local)
        build_local
        ;;
    rebuild)
        echo "Quick rebuild not fully implemented yet"
        ;;
    copy)
        echo "Copy not needed - modules already in kernel-out/"
        ;;
    test)
        test_modules
        ;;
    run-qemu|qemu)
        run_qemu
        ;;
    shell)
        enter_shell
        ;;
    clean)
        clean_all
        ;;
    status)
        show_status
        ;;
    setup-qemu)
        setup_qemu
        ;;
    help|--help|-h)
        usage
        ;;
    *)
        usage
        exit 1
        ;;
esac

