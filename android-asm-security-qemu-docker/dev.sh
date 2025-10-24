#!/bin/bash

# Development Helper Script
# Quick commands for kernel module development

set -e

PROJECT_DIR="/Users/avinash.kumar2/Downloads/GenAI/beverage-alc-genai/android-asm-security"
BUILD_DIR="$PROJECT_DIR/android-build"
CONTAINER="android-kernel-builder"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

usage() {
    echo "Android Kernel Module Development Helper"
    echo ""
    echo "Usage: ./dev.sh <command>"
    echo ""
    echo "Commands:"
    echo "  build         - Clean build all modules"
    echo "  rebuild       - Quick rebuild (no clean)"
    echo "  copy          - Copy built modules to host"
    echo "  test          - Check module metadata"
    echo "  shell         - Enter container shell"
    echo "  logs          - Show kernel build logs"
    echo "  clean         - Clean build artifacts"
    echo "  status        - Show container and build status"
    echo "  push          - Push module to Android device (ADB)"
    echo "  help          - Show this help"
    echo ""
    echo "Examples:"
    echo "  ./dev.sh build          # Build all modules"
    echo "  ./dev.sh copy           # Copy to kernel-out/"
    echo "  ./dev.sh push           # Push to Android device"
}

build() {
    echo -e "${GREEN}[*] Building kernel modules...${NC}"
    cd "$BUILD_DIR"
    docker exec $CONTAINER bash -c "cd /android && make clean && make kernel"
    echo -e "${GREEN}[✓] Build complete!${NC}"
}

rebuild() {
    echo -e "${GREEN}[*] Quick rebuild (no clean)...${NC}"
    cd "$BUILD_DIR"
    docker exec $CONTAINER bash -c "cd /android && make kernel"
    echo -e "${GREEN}[✓] Rebuild complete!${NC}"
}

copy_modules() {
    echo -e "${GREEN}[*] Copying modules to host...${NC}"
    cd "$BUILD_DIR"
    docker cp $CONTAINER:/android/out/kernel/ ./kernel-out/
    echo -e "${GREEN}[✓] Modules copied to: $BUILD_DIR/kernel-out/kernel/${NC}"
    ls -lh "$BUILD_DIR/kernel-out/kernel/"
}

test_modules() {
    echo -e "${GREEN}[*] Testing module metadata...${NC}"
    echo ""
    echo "=== syscall_monitor.ko ==="
    docker exec $CONTAINER bash -c "strings /android/out/kernel/syscall_monitor.ko | grep -E '(version|description|author)'"
    echo ""
    echo "=== process_guard.ko ==="
    docker exec $CONTAINER bash -c "strings /android/out/kernel/process_guard.ko | grep -E '(version|description|author)'"
    echo ""
    echo "=== memory_shield.ko ==="
    docker exec $CONTAINER bash -c "strings /android/out/kernel/memory_shield.ko | grep -E '(version|description|author)'"
}

shell() {
    echo -e "${GREEN}[*] Entering container shell...${NC}"
    echo -e "${YELLOW}Tip: You're now in /android directory${NC}"
    echo -e "${YELLOW}     Edit modules in: /android/modules/${NC}"
    echo -e "${YELLOW}     Build with: make kernel${NC}"
    echo ""
    cd "$BUILD_DIR"
    docker exec -it $CONTAINER bash
}

logs() {
    echo -e "${GREEN}[*] Showing build logs...${NC}"
    docker logs $CONTAINER --tail 50
}

clean() {
    echo -e "${GREEN}[*] Cleaning build artifacts...${NC}"
    docker exec $CONTAINER bash -c "cd /android && make clean"
    echo -e "${GREEN}[✓] Clean complete!${NC}"
}

status() {
    echo -e "${GREEN}=== Container Status ===${NC}"
    docker ps | grep $CONTAINER || echo -e "${RED}Container not running${NC}"
    echo ""
    echo -e "${GREEN}=== Build Status ===${NC}"
    docker exec $CONTAINER bash -c "ls -lh /android/out/kernel/ 2>/dev/null" || echo -e "${YELLOW}Not built yet${NC}"
    echo ""
    echo -e "${GREEN}=== Source Files ===${NC}"
    ls -lh "$BUILD_DIR/modules/"*.c
}

push_to_device() {
    echo -e "${GREEN}[*] Pushing modules to Android device...${NC}"
    
    # Check if adb is available
    if ! command -v adb &> /dev/null; then
        echo -e "${RED}[!] Error: adb not found${NC}"
        echo "Please install Android SDK platform-tools"
        exit 1
    fi
    
    # Check if device is connected
    if ! adb devices | grep -q "device$"; then
        echo -e "${RED}[!] Error: No Android device connected${NC}"
        echo "Please connect device and enable USB debugging"
        exit 1
    fi
    
    echo -e "${YELLOW}[*] Pushing to /data/local/tmp/${NC}"
    adb push "$BUILD_DIR/kernel-out/kernel/syscall_monitor.ko" /data/local/tmp/
    adb push "$BUILD_DIR/kernel-out/kernel/process_guard.ko" /data/local/tmp/
    adb push "$BUILD_DIR/kernel-out/kernel/memory_shield.ko" /data/local/tmp/
    
    echo ""
    echo -e "${GREEN}[✓] Modules pushed!${NC}"
    echo ""
    echo "To load on device:"
    echo "  adb shell"
    echo "  su"
    echo "  cd /data/local/tmp"
    echo "  insmod syscall_monitor.ko"
    echo "  insmod process_guard.ko"
    echo "  insmod memory_shield.ko"
    echo "  dmesg | tail -50"
}

# Main command handler
case "$1" in
    build)
        build
        ;;
    rebuild)
        rebuild
        ;;
    copy)
        copy_modules
        ;;
    test)
        test_modules
        ;;
    shell)
        shell
        ;;
    logs)
        logs
        ;;
    clean)
        clean
        ;;
    status)
        status
        ;;
    push)
        push_to_device
        ;;
    help|--help|-h|"")
        usage
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        echo ""
        usage
        exit 1
        ;;
esac

