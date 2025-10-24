/*
 * Syscall Monitor Security Module
 * Monitors and logs system calls for security analysis
 */

#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/kallsyms.h>
#include <linux/kprobes.h>
#include <linux/syscalls.h>

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Android Security Team");
MODULE_DESCRIPTION("System Call Monitoring for Security");
MODULE_VERSION("1.0");

static int monitored_syscalls = 0;
static int suspicious_calls = 0;
static int file_reads = 0;  // CUSTOM: Track file reads

// Monitor open() syscall
static int monitor_open(struct kprobe *p, struct pt_regs *regs) {
    monitored_syscalls++;
    return 0;
}

// Monitor execve() syscall
static int monitor_execve(struct kprobe *p, struct pt_regs *regs) {
    monitored_syscalls++;
    
    // Log potential suspicious activity
    if (monitored_syscalls % 100 == 0) {
        pr_info("[SECURITY] Monitored %d syscalls\n", monitored_syscalls);
    }
    
    return 0;
}

// CUSTOM: Monitor file reads
static int monitor_file_read(struct kprobe *p, struct pt_regs *regs) {
    file_reads++;
    
    // Log every 100 file reads
    if (file_reads % 100 == 0) {
        pr_info("[CUSTOM] File reads: %d\n", file_reads);
    }
    
    return 0;
}

static struct kprobe kp_open = {
    .symbol_name = "do_sys_open",
    .pre_handler = monitor_open,
};

static struct kprobe kp_execve = {
    .symbol_name = "do_execve",
    .pre_handler = monitor_execve,
};

// CUSTOM: Kprobe for file reads
static struct kprobe kp_read = {
    .symbol_name = "vfs_read",
    .pre_handler = monitor_file_read,
};

static int __init syscall_monitor_init(void) {
    int ret;
    
    pr_info("========================================\n");
    pr_info("Syscall Monitor Security Module Loading\n");
    pr_info("========================================\n");
    
    // Register kprobe for open()
    ret = register_kprobe(&kp_open);
    if (ret < 0) {
        pr_warn("Failed to register kprobe for open: %d\n", ret);
    } else {
        pr_info("✓ Monitoring: open() syscall\n");
    }
    
    // Register kprobe for execve()
    ret = register_kprobe(&kp_execve);
    if (ret < 0) {
        pr_warn("Failed to register kprobe for execve: %d\n", ret);
    } else {
        pr_info("✓ Monitoring: execve() syscall\n");
    }
    
    // CUSTOM: Register kprobe for file reads
    ret = register_kprobe(&kp_read);
    if (ret < 0) {
        pr_warn("Failed to register kprobe for read: %d\n", ret);
    } else {
        pr_info("✓ Monitoring: file reads (CUSTOM)\n");
    }
    
    pr_info("Syscall monitor active!\n");
    pr_info("========================================\n");
    
    return 0;
}

static void __exit syscall_monitor_exit(void) {
    unregister_kprobe(&kp_open);
    unregister_kprobe(&kp_execve);
    unregister_kprobe(&kp_read);  // CUSTOM: Unregister file read monitor
    
    pr_info("========================================\n");
    pr_info("Syscall Monitor Security Module Unloaded\n");
    pr_info("Total syscalls monitored: %d\n", monitored_syscalls);
    pr_info("Suspicious calls detected: %d\n", suspicious_calls);
    pr_info("Total file reads: %d (CUSTOM)\n", file_reads);  // CUSTOM: Show file read count
    pr_info("========================================\n");
}

module_init(syscall_monitor_init);
module_exit(syscall_monitor_exit);

