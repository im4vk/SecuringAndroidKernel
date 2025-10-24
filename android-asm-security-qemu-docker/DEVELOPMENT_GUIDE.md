# Development Guide: Custom Security Modules

Complete guide to add, modify, test, and build custom kernel modules.

---

## 📝 Quick Start: Add Custom Code

### Option 1: Modify Existing Module

**Example: Add file monitoring to syscall_monitor**

1. **Edit the module:**
```bash
cd android-build/modules
nano syscall_monitor.c  # or use your editor
```

2. **Add your custom code:**
```c
// Add after existing includes
#include <linux/fs.h>

// Add new monitoring function
static int monitor_file_access(struct kprobe *p, struct pt_regs *regs) {
    monitored_syscalls++;
    
    // Your custom logic here
    pr_info("[SECURITY] File access detected!\n");
    
    return 0;
}

// Add new kprobe
static struct kprobe kp_file = {
    .symbol_name = "vfs_read",
    .pre_handler = monitor_file_access,
};

// Update init function to register new probe
static int __init syscall_monitor_init(void) {
    // ... existing code ...
    
    // Add this:
    ret = register_kprobe(&kp_file);
    if (ret < 0) {
        pr_warn("Failed to register kprobe for file access: %d\n", ret);
    } else {
        pr_info("✓ Monitoring: file access\n");
    }
    
    return 0;
}

// Update exit function
static void __exit syscall_monitor_exit(void) {
    unregister_kprobe(&kp_open);
    unregister_kprobe(&kp_execve);
    unregister_kprobe(&kp_file);  // Add this
    
    // ... rest of code ...
}
```

3. **Rebuild:**
```bash
cd /Users/avinash.kumar2/Downloads/GenAI/beverage-alc-genai/android-asm-security/android-build
docker exec android-kernel-builder bash -c "cd /android && make clean && make kernel"
```

4. **Copy updated module:**
```bash
docker cp android-kernel-builder:/android/out/kernel/syscall_monitor.ko ./kernel-out/kernel/
```

---

### Option 2: Create New Module from Scratch

**Example: Create network_monitor.c**

1. **Create new file:**
```bash
cd android-build/modules
cat > network_monitor.c << 'EOF'
/*
 * Network Monitor Security Module
 * Monitors network activity for security analysis
 */

#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/net.h>
#include <linux/socket.h>

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Your Name");
MODULE_DESCRIPTION("Network Activity Monitoring");
MODULE_VERSION("1.0");

static unsigned long packets_monitored = 0;
static unsigned long suspicious_connections = 0;

static int __init network_monitor_init(void) {
    pr_info("========================================\n");
    pr_info("Network Monitor Security Module Loading\n");
    pr_info("========================================\n");
    pr_info("✓ Network monitoring enabled\n");
    pr_info("✓ Packet inspection active\n");
    pr_info("========================================\n");
    
    return 0;
}

static void __exit network_monitor_exit(void) {
    pr_info("========================================\n");
    pr_info("Network Monitor Security Module Unloaded\n");
    pr_info("Packets monitored: %lu\n", packets_monitored);
    pr_info("Suspicious connections: %lu\n", suspicious_connections);
    pr_info("========================================\n");
}

module_init(network_monitor_init);
module_exit(network_monitor_exit);
EOF
```

2. **Update build script:**
```bash
# Edit build-kernel.sh to include new module
# The script already builds all .c files in modules/
```

3. **Build:**
```bash
docker exec android-kernel-builder bash -c "cd /android && make kernel"
```

4. **Copy:**
```bash
docker cp android-kernel-builder:/android/out/kernel/network_monitor.ko ./kernel-out/kernel/
```

---

## 🔧 Development Workflow

### Full Development Cycle

```bash
# 1. Start development environment
cd android-build
docker-compose up -d
docker exec -it android-kernel-builder bash

# Inside container:
cd /android

# 2. Edit module
vi modules/syscall_monitor.c

# 3. Build
make kernel

# 4. Check output
ls -lh /android/out/kernel/

# 5. Test syntax
cd /android/out/kernel
strings syscall_monitor.ko | grep description

# 6. Exit container
exit

# 7. Copy to host
docker cp android-kernel-builder:/android/out/kernel/syscall_monitor.ko ./kernel-out/kernel/
```

---

## 🧪 Testing Your Module

### Test 1: Syntax Check (On Host)

```bash
cd android-build/modules
gcc -fsyntax-only -I/usr/src/linux-headers-$(uname -r)/include syscall_monitor.c
```

### Test 2: Build Check (In Container)

```bash
docker exec android-kernel-builder bash -c "cd /android && make kernel 2>&1 | tail -50"
```

### Test 3: Module Info

```bash
# Check module metadata
docker exec android-kernel-builder bash -c "strings /android/out/kernel/syscall_monitor.ko | grep -E '(version|description|author|license)'"
```

### Test 4: Load Test (Requires Android device/emulator)

```bash
# On Android device with custom kernel:
adb push ./kernel-out/kernel/syscall_monitor.ko /data/local/tmp/
adb shell
su
cd /data/local/tmp
insmod syscall_monitor.ko
dmesg | tail -30
lsmod | grep syscall
rmmod syscall_monitor
dmesg | tail -20
```

---

## 💡 Common Customizations

### 1. Add Kernel Parameter

```c
// Add module parameter
static char *target = "all";
module_param(target, charp, 0644);
MODULE_PARM_DESC(target, "Target to monitor (all, specific_pid, etc)");

// Use it
static int __init my_module_init(void) {
    pr_info("Monitoring target: %s\n", target);
    // ...
}

// Load with parameter
// insmod my_module.ko target="specific"
```

### 2. Add Proc File Interface

```c
#include <linux/proc_fs.h>
#include <linux/seq_file.h>

// Proc file handler
static int my_proc_show(struct seq_file *m, void *v) {
    seq_printf(m, "Syscalls monitored: %d\n", monitored_syscalls);
    seq_printf(m, "Suspicious calls: %d\n", suspicious_calls);
    return 0;
}

static int my_proc_open(struct inode *inode, struct file *file) {
    return single_open(file, my_proc_show, NULL);
}

static const struct proc_ops my_proc_ops = {
    .proc_open = my_proc_open,
    .proc_read = seq_read,
    .proc_lseek = seq_lseek,
    .proc_release = single_release,
};

// In init function
static int __init my_module_init(void) {
    proc_create("syscall_monitor", 0, NULL, &my_proc_ops);
    // ...
}

// Read with: cat /proc/syscall_monitor
```

### 3. Add Timer for Periodic Tasks

```c
#include <linux/timer.h>

static struct timer_list my_timer;

static void timer_callback(struct timer_list *t) {
    pr_info("[PERIODIC] Syscalls: %d, Suspicious: %d\n", 
            monitored_syscalls, suspicious_calls);
    
    // Re-arm timer for 60 seconds
    mod_timer(&my_timer, jiffies + msecs_to_jiffies(60000));
}

static int __init my_module_init(void) {
    timer_setup(&my_timer, timer_callback, 0);
    mod_timer(&my_timer, jiffies + msecs_to_jiffies(60000));
    // ...
}

static void __exit my_module_exit(void) {
    del_timer(&my_timer);
    // ...
}
```

### 4. Add Netlink for User-Space Communication

```c
#include <linux/netlink.h>
#include <net/netlink.h>
#include <net/net_namespace.h>

#define NETLINK_USER 31

static struct sock *nl_sk = NULL;

static void nl_recv_msg(struct sk_buff *skb) {
    // Handle messages from userspace
    pr_info("Received message from userspace\n");
}

static int __init my_module_init(void) {
    struct netlink_kernel_cfg cfg = {
        .input = nl_recv_msg,
    };
    
    nl_sk = netlink_kernel_create(&init_net, NETLINK_USER, &cfg);
    if (!nl_sk) {
        pr_err("Error creating netlink socket\n");
        return -ENOMEM;
    }
    // ...
}
```

---

## 🎯 Real-World Examples

### Example 1: File Integrity Monitor

```c
/*
 * File Integrity Monitor
 * Detects unauthorized file modifications
 */

#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/kprobes.h>
#include <linux/fs.h>

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Security Team");
MODULE_DESCRIPTION("File Integrity Monitoring");

static const char *protected_paths[] = {
    "/system/bin/",
    "/system/lib/",
    "/vendor/bin/",
    NULL
};

static bool is_protected_path(const char *path) {
    int i;
    for (i = 0; protected_paths[i] != NULL; i++) {
        if (strstr(path, protected_paths[i])) {
            return true;
        }
    }
    return false;
}

static int monitor_file_write(struct kprobe *p, struct pt_regs *regs) {
    // Check if writing to protected path
    // Log if suspicious
    pr_alert("[FILE_MONITOR] Write detected to protected area!\n");
    return 0;
}

static struct kprobe kp_write = {
    .symbol_name = "vfs_write",
    .pre_handler = monitor_file_write,
};

static int __init fim_init(void) {
    register_kprobe(&kp_write);
    pr_info("File Integrity Monitor active\n");
    return 0;
}

static void __exit fim_exit(void) {
    unregister_kprobe(&kp_write);
    pr_info("File Integrity Monitor stopped\n");
}

module_init(fim_init);
module_exit(fim_exit);
```

### Example 2: Process Whitelist

```c
/*
 * Process Whitelist
 * Only allows specific processes to run
 */

#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/sched.h>
#include <linux/kprobes.h>

MODULE_LICENSE("GPL");

static const char *whitelist[] = {
    "init",
    "zygote",
    "system_server",
    NULL
};

static bool is_whitelisted(const char *name) {
    int i;
    for (i = 0; whitelist[i] != NULL; i++) {
        if (strcmp(name, whitelist[i]) == 0) {
            return true;
        }
    }
    return false;
}

static int check_process(struct kprobe *p, struct pt_regs *regs) {
    struct task_struct *task = current;
    
    if (!is_whitelisted(task->comm)) {
        pr_warn("[WHITELIST] Blocking: %s (PID: %d)\n", 
                task->comm, task->pid);
        // Could send signal to kill process
        // send_sig(SIGKILL, task, 1);
    }
    
    return 0;
}

static struct kprobe kp_exec = {
    .symbol_name = "do_execve",
    .pre_handler = check_process,
};

static int __init whitelist_init(void) {
    register_kprobe(&kp_exec);
    pr_info("Process whitelist active\n");
    return 0;
}

static void __exit whitelist_exit(void) {
    unregister_kprobe(&kp_exec);
}

module_init(whitelist_init);
module_exit(whitelist_exit);
```

---

## 🐛 Debugging Tips

### 1. Enable Debug Messages

```c
// Add to your module
#define DEBUG 1

#ifdef DEBUG
    #define debug_print(fmt, ...) \
        pr_info("[DEBUG] " fmt, ##__VA_ARGS__)
#else
    #define debug_print(fmt, ...) do {} while(0)
#endif

// Use it
debug_print("Variable value: %d\n", my_var);
```

### 2. Check Kernel Logs

```bash
# In Android
adb shell dmesg | grep -i "security\|monitor\|guard\|shield"

# Filter by module
adb shell dmesg | grep syscall_monitor

# Watch in real-time
adb shell dmesg -w
```

### 3. Verify Module Loaded

```bash
adb shell lsmod | grep monitor
adb shell cat /proc/modules | grep monitor
```

### 4. Check Module Info

```bash
# On host before loading
docker exec android-kernel-builder bash -c \
  "modinfo /android/out/kernel/syscall_monitor.ko"
```

---

## 📦 Build Commands Reference

```bash
# Clean build
docker exec android-kernel-builder bash -c "cd /android && make clean && make kernel"

# Quick rebuild (only modules)
docker exec android-kernel-builder bash -c "cd /android && make modules"

# Build specific module
docker exec android-kernel-builder bash -c "cd /android/modules && make syscall_monitor.ko"

# Check build errors
docker exec android-kernel-builder bash -c "cd /android && make kernel 2>&1 | grep -i error"

# Copy all modules to host
docker cp android-kernel-builder:/android/out/kernel/ ./kernel-out/

# Restart container
docker-compose down && docker-compose up -d
```

---

## ⚠️ Important Notes

1. **Kernel Version Match:** Your module MUST match the kernel version you're loading it into
2. **GPL License:** Required for most kernel functions
3. **Testing:** Always test in emulator/VM before real device
4. **Backup:** Keep backups before modifying system
5. **Root Required:** Loading modules requires root access
6. **Symbols:** Some kernel symbols may not be exported in all builds

---

## 🚀 Next Steps

1. **Modify existing module** with your custom logic
2. **Build** using provided commands
3. **Test** in Android emulator
4. **Deploy** to device
5. **Monitor** kernel logs for your output
6. **Iterate** based on results

---

## 📚 Resources

- **Kernel API:** https://www.kernel.org/doc/html/latest/
- **Module Programming:** https://tldp.org/LDP/lkmpg/2.6/html/
- **Kprobes:** https://www.kernel.org/doc/Documentation/kprobes.txt
- **Android Kernel:** https://source.android.com/docs/core/architecture/kernel

---

**Ready to develop? Start editing modules in `android-build/modules/` and rebuild!**

