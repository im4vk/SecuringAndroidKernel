#!/bin/bash
set -e

echo "=========================================="
echo "Building Android Kernel with Security Mods"
echo "=========================================="

KERNEL_DIR="/android/kernel/kernel-src"
OUT_DIR="/android/out/kernel"
MODULES_DIR="/android/modules"

cd $KERNEL_DIR

# Configure kernel
echo "[1/5] Configuring kernel..."
make ARCH=arm64 defconfig

# Enable required kernel features for security modules
echo "[2/5] Enabling security features..."
scripts/config --enable CONFIG_MODULES
scripts/config --enable CONFIG_MODULE_UNLOAD
scripts/config --enable CONFIG_SECURITY
scripts/config --enable CONFIG_AUDIT
scripts/config --enable CONFIG_SECURITYFS

# Build kernel
echo "[3/5] Building kernel (this may take 15-30 minutes)..."
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- -j$(nproc)

# Build security modules
echo "[4/5] Building security modules..."
cd $MODULES_DIR

# Auto-generate Makefile from all .c files (excluding .mod.c files)
echo "  Auto-detecting modules..."
MODULE_LIST=$(find . -maxdepth 1 -name "*.c" ! -name "*.mod.c" -exec basename {} .c \; | sed 's/$/.o/' | tr '\n' ' ')

if [ -z "$MODULE_LIST" ]; then
    echo "  No module source files found!"
    exit 1
fi

echo "  Found modules: $MODULE_LIST"

# Always regenerate Makefile to pick up new files
cat > Makefile << EOF
# Auto-generated Makefile - will be regenerated on each build
# To add a new module: just create a new .c file in this directory!
obj-m += $MODULE_LIST
KERNEL_DIR := $KERNEL_DIR
all:
	make -C \$(KERNEL_DIR) M=\$(PWD) ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- modules
clean:
	make -C \$(KERNEL_DIR) M=\$(PWD) clean
EOF

# Build all modules
echo "  Building all modules..."
make

# Copy output
echo "[5/5] Copying build artifacts..."
mkdir -p $OUT_DIR
cp $KERNEL_DIR/arch/arm64/boot/Image $OUT_DIR/
find $MODULES_DIR -name "*.ko" -exec cp {} $OUT_DIR/ \;

echo ""
echo "✅ Kernel build complete!"
echo "   Kernel image: $OUT_DIR/Image"
echo "   Modules: $OUT_DIR/*.ko"

