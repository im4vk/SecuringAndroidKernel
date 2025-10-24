# How to Add Custom Code - Simple Guide

## 🎯 3 Ways to Add Your Code

---

## Method 1: Quick Edit (Easiest) ⚡

**Use the helper script:**

```bash
cd /Users/avinash.kumar2/Downloads/GenAI/beverage-alc-genai/android-asm-security

# 1. Edit your code
nano android-build/modules/syscall_monitor.c

# 2. Build
./dev.sh build

# 3. Copy to host
./dev.sh copy

# Done!
```

---

## Method 2: Container Shell (Best for Development) 🔧

```bash
# 1. Enter container
./dev.sh shell

# 2. Edit inside container
cd /android/modules
vi syscall_monitor.c

# 3. Build
cd /android
make kernel

# 4. Check output
ls -lh /android/out/kernel/

# 5. Exit
exit

# 6. Copy to host
./dev.sh copy
```

---

## Method 3: Direct Docker Commands (Advanced) 🚀

```bash
# Edit on host
nano android-build/modules/syscall_monitor.c

# Build directly
docker exec android-kernel-builder bash -c "cd /android && make kernel"

# Copy
docker cp android-kernel-builder:/android/out/kernel/syscall_monitor.ko ./android-build/kernel-out/kernel/
```

---

## 📝 Example: Add File Read Counter

**Edit:** `android-build/modules/syscall_monitor.c`

### Step 1: Add variable (line 19)
```c
static int file_reads = 0;
```

### Step 2: Add function (after line 23)
```c
static int monitor_file_read(struct kprobe *p, struct pt_regs *regs) {
    file_reads++;
    if (file_reads % 100 == 0) {
        pr_info("[CUSTOM] File reads: %d\n", file_reads);
    }
    return 0;
}
```

### Step 3: Add kprobe (after line 35)
```c
static struct kprobe kp_read = {
    .symbol_name = "vfs_read",
    .pre_handler = monitor_file_read,
};
```

### Step 4: Register in init (line 55)
```c
ret = register_kprobe(&kp_read);
if (ret >= 0) {
    pr_info("✓ Monitoring: file reads\n");
}
```

### Step 5: Unregister in exit (line 68)
```c
unregister_kprobe(&kp_read);
pr_info("Total file reads: %d\n", file_reads);
```

### Step 6: Build
```bash
./dev.sh build
```

---

## 🛠️ Helper Script Commands

```bash
./dev.sh build     # Clean build
./dev.sh rebuild   # Quick rebuild
./dev.sh copy      # Copy to host
./dev.sh test      # Test modules
./dev.sh shell     # Enter container
./dev.sh status    # Show status
./dev.sh push      # Push to Android device
./dev.sh clean     # Clean build
./dev.sh help      # Show help
```

---

## 🧪 Test Your Changes

### On Host (Quick Check)
```bash
# Check module was rebuilt
ls -lh android-build/kernel-out/kernel/syscall_monitor.ko

# Verify your code is in the binary
strings android-build/kernel-out/kernel/syscall_monitor.ko | grep "file reads"
```

### On Android Device
```bash
# Push module
adb push android-build/kernel-out/kernel/syscall_monitor.ko /data/local/tmp/

# Load
adb shell
su
cd /data/local/tmp
insmod syscall_monitor.ko

# Test (trigger some activity)
ls /system
cat /proc/version

# Check logs
dmesg | grep "file reads"

# Unload
rmmod syscall_monitor
```

---

## 📚 Complete Guides

- **QUICK_TEST.md** - Follow step-by-step to add code now
- **DEVELOPMENT_GUIDE.md** - Complete reference with examples
- **android-build/BUILD_RESULTS.md** - Testing & deployment

---

## 💡 Common Tasks

### Add timer (periodic tasks)
```c
#include <linux/timer.h>
static struct timer_list my_timer;

static void timer_callback(struct timer_list *t) {
    pr_info("Timer fired!\n");
    mod_timer(&my_timer, jiffies + msecs_to_jiffies(60000));
}

// In init:
timer_setup(&my_timer, timer_callback, 0);
mod_timer(&my_timer, jiffies + msecs_to_jiffies(60000));

// In exit:
del_timer(&my_timer);
```

### Add module parameter
```c
static int threshold = 100;
module_param(threshold, int, 0644);
MODULE_PARM_DESC(threshold, "Alert threshold");

// Use: insmod module.ko threshold=200
```

### Add proc file
```c
#include <linux/proc_fs.h>
#include <linux/seq_file.h>

static int my_proc_show(struct seq_file *m, void *v) {
    seq_printf(m, "Stats: %d\n", my_counter);
    return 0;
}

// Read with: cat /proc/my_module
```

---

## ⚠️ Important Notes

1. **Always test in emulator first**
2. **Keep backups** of working modules
3. **Check kernel logs** for errors: `dmesg`
4. **Module must match kernel version**
5. **Requires root access** to load

---

## 🚀 Start Now!

```bash
# Try the quick test
cat QUICK_TEST.md

# Or dive into full guide
cat DEVELOPMENT_GUIDE.md

# Happy coding! 🎉
```

cat << 'EOF'
╔═══════════════════════════════════════════════════════════════╗
║            HOW TO USE THE CALCULATOR MODULE                   ║
╚═══════════════════════════════════════════════════════════════╝

📝 THE KERNEL WAY TO "INPUT" NUMBERS:

In kernel modules, you pass parameters when loading the module.

═══════════════════════════════════════════════════════════════

🚀 USAGE ON ANDROID DEVICE:

1. Push module to device:
   adb push calculator.ko /data/local/tmp/

2. Load with parameters (THIS IS YOUR INPUT):
   adb shell
   su
   insmod /data/local/tmp/calculator.ko num1=10 num2=20

3. See the result:
   dmesg | tail -20

   Expected output:
   ========================================
      Calculator Module Loaded
   ========================================
   Number 1: 10
   Number 2: 20
   Sum:      10 + 20 = 30
   Subtract: 10 - 20 = -10
   Multiply: 10 * 20 = 200
   Divide:   10 / 20 = 0
   ========================================

4. Unload:
   rmmod calculator

═══════════════════════════════════════════════════════════════

💡 DIFFERENT EXAMPLES:

Example 1 (Add 100 + 50):
   insmod calculator.ko num1=100 num2=50
   # Output: Sum: 100 + 50 = 150

Example 2 (Add 7 + 3):
   insmod calculator.ko num1=7 num2=3
   # Output: Sum: 7 + 3 = 10

Example 3 (Negative numbers):
   insmod calculator.ko num1=-5 num2=10
   # Output: Sum: -5 + 10 = 5

Example 4 (Default - no parameters):
   insmod calculator.ko
   # Output: Sum: 0 + 0 = 0

═══════════════════════════════════════════════════════════════

🧪 TEST IN DOCKER CONTAINER (No Android needed):

1. Enter container:
   docker exec -it android-kernel-builder bash

2. Load module with parameters:
   insmod /android/out/kernel/calculator.ko num1=25 num2=75

3. Check kernel log:
   dmesg | tail -20

4. Unload:
   rmmod calculator
   dmesg | tail -10

═══════════════════════════════════════════════════════════════

🔑 KEY POINTS:

✅ num1=XX num2=YY are YOUR INPUTS
✅ The module calculates and prints to kernel log
✅ Use dmesg to see results
✅ You can load/unload multiple times with different numbers

═══════════════════════════════════════════════════════════════
EOF
