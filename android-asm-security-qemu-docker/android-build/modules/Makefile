# Auto-generated Makefile - will be regenerated on each build
# To add a new module: just create a new .c file in this directory!
obj-m += calculator.o process_guard.o syscall_monitor.o memory_shield.o 
KERNEL_DIR := /android/kernel/kernel-src
all:
	make -C $(KERNEL_DIR) M=$(PWD) ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- modules
clean:
	make -C $(KERNEL_DIR) M=$(PWD) clean
