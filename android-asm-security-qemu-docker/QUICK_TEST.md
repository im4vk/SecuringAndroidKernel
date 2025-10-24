# Quick Test: Add Custom Code Right Now

Follow these steps to test adding your own custom code immediately.

---

## 🎯 Goal

Add a custom function that counts **every file read** on the system.

---

## Step 1: Edit Module (2 minutes)

```bash
cd /Users/avinash.kumar2/Downloads/GenAI/beverage-alc-genai/android-asm-security/android-build/modules
```

Open `syscall_monitor.c` and add this code:

### Add after line 18 (after existing variables):

```c
static int file_reads = 0;  // ADD THIS LINE
```

### Add after line 23 (after `monitor_execve` function):

```c
// ADD THIS ENTIRE FUNCTION
static int monitor_file_read(struct kprobe *p, struct pt_regs *regs) {
    file_reads++;
    
    // Log every 100 reads
    if (file_reads % 100 == 0) {
        pr_info("[CUSTOM] File reads: %d\n", file_reads);
    }
    
    return 0;
}
```

### Add after line 35 (after `kp_execve` struct):

```c
// ADD THIS STRUCT
static struct kprobe kp_read = {
    .symbol_name = "vfs_read",
    .pre_handler = monitor_file_read,
};
```

### Update init function - add after line 55:

```c
    // ADD THESE LINES
    ret = register_kprobe(&kp_read);
    if (ret < 0) {
        pr_warn("Failed to register kprobe for read: %d\n", ret);
    } else {
        pr_info("✓ Monitoring: file reads\n");
    }
```

### Update exit function - add after line 68:

```c
    unregister_kprobe(&kp_read);  // ADD THIS LINE
    pr_info("Total file reads: %d\n", file_reads);  // ADD THIS LINE
```

---

## Step 2: Rebuild (5 minutes)

```bash
cd /Users/avinash.kumar2/Downloads/GenAI/beverage-alc-genai/android-asm-security/android-build

# Rebuild
docker exec android-kernel-builder bash -c "cd /android && make clean && make kernel"

# Check if successful
docker exec android-kernel-builder ls -lh /android/out/kernel/syscall_monitor.ko
```

**Expected output:**
```
-rw-r--r-- 1 root root 41K Oct 8 14:30 syscall_monitor.ko
```

---

## Step 3: Copy to Host

```bash
docker cp android-kernel-builder:/android/out/kernel/syscall_monitor.ko ./kernel-out/kernel/
```

---

## Step 4: Verify Changes

```bash
strings ./kernel-out/kernel/syscall_monitor.ko | grep -i "file reads"
```

**Expected output:**
```
[CUSTOM] File reads: %d
Total file reads: %d
```

---

## ✅ Success!

You've just:
1. ✅ Added custom code to monitor file reads
2. ✅ Built the modified module
3. ✅ Verified your changes are in the binary

---

## 🧪 Test on Real Android (Optional)

If you have an Android device/emulator with your custom kernel:

```bash
# Push module
adb push ./kernel-out/kernel/syscall_monitor.ko /data/local/tmp/
adb shell

# In device shell
su
cd /data/local/tmp
insmod syscall_monitor.ko

# Trigger some file reads
ls /system
cat /proc/version
ps

# Check logs
dmesg | tail -50

# Expected output:
# [SECURITY] Monitored 100 syscalls
# [CUSTOM] File reads: 100
# [CUSTOM] File reads: 200
# ...

# Unload
rmmod syscall_monitor
dmesg | tail -20

# Expected output:
# Total file reads: 1234
```

---

## 📝 What You Learned

- ✅ How to add variables
- ✅ How to add functions
- ✅ How to register kprobes
- ✅ How to rebuild modules
- ✅ How to verify changes

---

## 🚀 Next Challenge

Try adding:
1. **Network packet counter** - Track network activity
2. **Process name logger** - Log every process that starts
3. **Timer** - Print stats every 60 seconds

See `DEVELOPMENT_GUIDE.md` for examples!

