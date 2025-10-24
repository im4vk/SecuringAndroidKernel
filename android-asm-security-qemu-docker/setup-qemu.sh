#!/bin/bash
# Setup QEMU environment for Android kernel testing on Mac

set -e

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║       QEMU Setup for Android Kernel Development          ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo

# Check if running on Mac
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ This script is designed for macOS"
    exit 1
fi

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo "❌ Homebrew not found. Install from https://brew.sh"
    exit 1
fi

echo "✅ Running on macOS"
echo "✅ Homebrew found"
echo

# Install QEMU if not present
echo "[1/5] Checking QEMU..."
if ! command -v qemu-system-aarch64 &> /dev/null; then
    echo "  Installing QEMU..."
    brew install qemu
else
    echo "  ✅ QEMU already installed"
fi

# Install cross-compilation toolchain
echo "[2/5] Checking ARM64 cross-compiler..."
if ! command -v aarch64-linux-gnu-gcc &> /dev/null; then
    echo "  Installing cross-compiler toolchain..."
    brew install aarch64-elf-gcc
    # Alternative: install from ARM website or use Docker for building
    echo "  Note: For full kernel compilation, you may need additional tools"
else
    echo "  ✅ Cross-compiler found"
fi

# Download minimal ARM64 Linux image for testing
echo "[3/5] Setting up test environment..."
mkdir -p qemu-env
cd qemu-env

if [ ! -f "rootfs.ext4" ]; then
    echo "  Creating minimal root filesystem..."
    # Create a minimal ext4 image
    dd if=/dev/zero of=rootfs.ext4 bs=1M count=512
    mkfs.ext4 -F rootfs.ext4
    echo "  ✅ Root filesystem created"
else
    echo "  ✅ Root filesystem exists"
fi

# Create kernel config
echo "[4/5] Creating QEMU launch script..."
cat > run-qemu.sh << 'EOF'
#!/bin/bash
# Run QEMU with Android kernel

KERNEL="../android-build/kernel-out/kernel/Image"
ROOTFS="rootfs.ext4"
MODULES_DIR="../android-build/kernel-out/kernel"

if [ ! -f "$KERNEL" ]; then
    echo "❌ Kernel image not found. Build first with: ./dev.sh build"
    exit 1
fi

echo "Starting QEMU..."
echo "Kernel: $KERNEL"
echo "Modules: $MODULES_DIR"
echo

qemu-system-aarch64 \
    -machine virt \
    -cpu cortex-a57 \
    -smp 2 \
    -m 2048 \
    -kernel "$KERNEL" \
    -append "console=ttyAMA0 root=/dev/vda rw" \
    -drive if=none,file="$ROOTFS",format=raw,id=hd \
    -device virtio-blk-device,drive=hd \
    -netdev user,id=net0 \
    -device virtio-net-device,netdev=net0 \
    -nographic \
    -serial mon:stdio

EOF
chmod +x run-qemu.sh

echo "  ✅ QEMU launch script created"

# Create module loader script
echo "[5/5] Creating module test script..."
cat > test-modules.sh << 'EOF'
#!/bin/bash
# Test modules in QEMU

echo "Module Testing Script"
echo "====================="
echo
echo "Available modules:"
ls -1 ../android-build/kernel-out/kernel/*.ko 2>/dev/null || echo "  No modules built yet"
echo
echo "To test in QEMU:"
echo "  1. Start QEMU: ./run-qemu.sh"
echo "  2. In QEMU shell, run:"
echo "     insmod /path/to/calculator.ko num1=42 num2=58"
echo "     dmesg | tail -50"
echo "     rmmod calculator"
echo

EOF
chmod +x test-modules.sh

cd ..

echo
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                  ✅ QEMU SETUP COMPLETE                   ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo
echo "Next steps:"
echo "  1. Build kernel:  ./dev.sh build"
echo "  2. Start QEMU:    cd qemu-env && ./run-qemu.sh"
echo "  3. Test modules:  (in QEMU)"
echo
echo "Note: You'll need a proper Linux userspace in the rootfs"
echo "      For now, use Docker for full builds, QEMU for testing"
echo

