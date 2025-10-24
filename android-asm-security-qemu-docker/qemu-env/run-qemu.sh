#!/bin/bash
# Run QEMU with Android kernel

KERNEL="../android-build/kernel-out/kernel/Image"
MODULES_DIR="../android-build/kernel-out/kernel"

if [ ! -f "$KERNEL" ]; then
    echo "❌ Kernel image not found at: $KERNEL"
    echo "Build first with: cd .. && ./dev-hybrid.sh build"
    exit 1
fi

echo "╔═══════════════════════════════════════════╗"
echo "║   Starting QEMU with Android Kernel       ║"
echo "╚═══════════════════════════════════════════╝"
echo
echo "Kernel: $KERNEL"
echo "Modules: $MODULES_DIR"
echo
echo "Available modules:"
ls -1 "$MODULES_DIR"/*.ko 2>/dev/null || echo "  No modules built"
echo
echo "Starting QEMU..."
echo "Note: Press Ctrl+A, then X to exit QEMU"
echo

# Simple QEMU command - boots to kernel panic (expected without full rootfs)
# But will show kernel boot messages and allow module testing if we had initramfs
qemu-system-aarch64 \
    -machine virt \
    -cpu cortex-a57 \
    -smp 2 \
    -m 2048 \
    -kernel "$KERNEL" \
    -append "console=ttyAMA0 earlyprintk=serial" \
    -nographic \
    -serial mon:stdio

echo
echo "QEMU exited"

