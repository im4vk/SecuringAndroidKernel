.PHONY: all kernel modules clean test

all: kernel modules

kernel:
	@echo "Building Android kernel with security features..."
	@./build-kernel.sh

modules:
	@echo "Security modules included in kernel build"

clean:
	@echo "Cleaning build artifacts..."
	rm -rf /android/out/*
	cd /android/kernel/kernel-src && make mrproper
	@echo "Cleaning modules directory..."
	cd /android/modules && make clean || true
	cd /android/modules && rm -f *.o *.ko *.mod *.mod.c *.order *.symvers .*.cmd .*.o || true

test:
	@echo "Testing kernel modules..."
	@echo "Kernel image: $(shell ls -lh /android/out/kernel/Image 2>/dev/null || echo 'Not built')"
	@echo "Security modules:"
	@ls -lh /android/out/kernel/*.ko 2>/dev/null || echo "  No modules built yet"

info:
	@echo "=========================================="
	@echo "Android Build System"
	@echo "=========================================="
	@echo "Kernel source: /android/kernel/kernel-src"
	@echo "Build output:  /android/out"
	@echo "Modules:       /android/modules"
	@echo ""
	@echo "Security Modules:"
	@echo "  - syscall_monitor.c : System call monitoring"
	@echo "  - process_guard.c   : Process security"
	@echo "  - memory_shield.c   : Memory protection"
	@echo ""
	@echo "Commands:"
	@echo "  make kernel   : Build kernel"
	@echo "  make modules  : Build security modules"
	@echo "  make test     : Test build"
	@echo "  make clean    : Clean build"
	@echo "=========================================="

