# Quick Start: Docker vs QEMU

## 🎯 The Problem You Wanted to Solve

**Before:** Docker builds modules, but you **can't actually run and test them**  
**Now:** QEMU lets you **load modules, pass inputs, and see real output!**

---

## ⚡ Super Quick Start

```bash
# 1. Setup (one time)
./setup-qemu.sh

# 2. Build (uses Docker if available, otherwise local)
./dev-hybrid.sh build

# 3. Run QEMU and test!
./dev-hybrid.sh run-qemu

# In QEMU:
insmod calculator.ko num1=42 num2=58
dmesg | tail -100  # SEE YOUR OUTPUT!
```

---

## 📊 What Changed

### Old Way (Docker Only)
```bash
./dev.sh build              # Build modules
strings calculator.ko       # Can only check strings
grep "Test" calculator.ko   # Can only verify code exists
# ❌ Can't actually RUN the module
# ❌ Can't see pr_info() output
# ❌ Can't pass parameters
```

### New Way (Docker + QEMU)
```bash
./dev-hybrid.sh build         # Build modules (same)
./dev-hybrid.sh run-qemu      # Start QEMU
# In QEMU:
insmod calculator.ko num1=42 num2=58  # ✅ Pass real input!
dmesg                                  # ✅ See real output!
```

---

## 🔄 Complete Workflow Comparison

### Workflow 1: Docker Only (What you had)
```
Edit .c → Build → Verify strings → ❓ (can't test)
```

### Workflow 2: QEMU Only (New)
```
Edit .c → Build locally → Test in QEMU → See results! ✅
```

### Workflow 3: Hybrid (Recommended!)
```
Edit .c → Build (Docker) → Test (QEMU) → See results! ✅✅
```

---

## 🎮 Interactive Example

### Terminal Session Example:
```bash
# Terminal Window 1: Start QEMU
$ ./dev-hybrid.sh run-qemu
Starting QEMU...
[QEMU boots]

# You're now in QEMU shell
/ # ls /modules
calculator.ko  memory_shield.ko  process_guard.ko  syscall_monitor.ko

/ # insmod /modules/calculator.ko num1=100 num2=50

/ # dmesg | tail -30
========================================
   Calculator Module Loaded
========================================

🔹 Using module parameters:
─────────────────────────────────────
Module Parameters:
  100 + 50 = 150    ← YOUR ACTUAL INPUT!
  100 - 50 = 50
  100 * 50 = 5000
  100 / 50 = 2

🔹 Testing different values:
─────────────────────────────────────
Test 1: Small numbers:
  10 + 5 = 15
  10 - 5 = 5
  10 * 5 = 50
  10 / 5 = 2
...
[All your function calls execute!]

/ # rmmod calculator

/ # dmesg | tail -10
========================================
   Calculator Module Unloaded
========================================
🔹 Final calculation before exit:
─────────────────────────────────────
Exit Values:
  100 + 50 = 150
  ...
Goodbye!
```

---

## 🆚 Feature Matrix

| Feature | Docker | QEMU | Docker+QEMU |
|---------|--------|------|-------------|
| **Build kernel** | ✅ Full | ⚠️ Limited | ✅ Full (Docker) |
| **Build modules** | ✅ | ✅ | ✅ |
| **Load modules** | ❌ | ✅ | ✅ (QEMU) |
| **Pass parameters** | ❌ | ✅ | ✅ (QEMU) |
| **See pr_info()** | ❌ | ✅ | ✅ (QEMU) |
| **See dmesg** | ❌ | ✅ | ✅ (QEMU) |
| **Interactive testing** | ❌ | ✅ | ✅ (QEMU) |
| **Fast builds** | ✅ | ⚠️ | ✅ (Docker) |

**Winner:** Docker + QEMU = Best of both! 🏆

---

## 🎯 Commands You Need

### Setup (Once)
```bash
./setup-qemu.sh
```

### Build
```bash
./dev-hybrid.sh build       # Auto-detect (Docker or local)
./dev-hybrid.sh status      # Check what's available
```

### Test
```bash
./dev-hybrid.sh run-qemu    # Start QEMU

# In QEMU:
insmod calculator.ko num1=X num2=Y
dmesg | tail -100
rmmod calculator
```

### Development
```bash
nano android-build/modules/calculator.c  # Edit
./dev-hybrid.sh build                    # Build
./dev-hybrid.sh run-qemu                 # Test
```

---

## 🎓 What This Solves

### Your Original Questions:

**Q: "Can I pass input to calculator?"**  
✅ **A: Yes! In QEMU:** `insmod calculator.ko num1=42 num2=58`

**Q: "Can I see the output?"**  
✅ **A: Yes! In QEMU:** `dmesg` shows all your `pr_info()` messages

**Q: "Can I test without Android device?"**  
✅ **A: Yes! QEMU emulates ARM64 Linux**

**Q: "Do I still need Docker?"**  
⚠️ **A: Recommended for builds, QEMU for testing**

---

## 🚀 Try It Now!

```bash
# 1. Check status
./dev-hybrid.sh status

# 2. If Docker available:
./dev-hybrid.sh build        # Fast, reliable build

# 3. If no Docker:
brew install qemu            # Install QEMU
./setup-qemu.sh             # Setup environment
./dev-hybrid.sh build-local  # Local build (limited)

# 4. Test (works either way):
./dev-hybrid.sh run-qemu     # Boot QEMU

# 5. In QEMU:
insmod calculator.ko num1=999 num2=111
dmesg
# See YOUR code running with YOUR inputs!
```

---

## 💡 Pro Tips

### Tip 1: Keep QEMU Running
```bash
# Terminal 1: QEMU (leave open)
./dev-hybrid.sh run-qemu

# Terminal 2: Development
nano calculator.c
./dev-hybrid.sh build

# Terminal 1: Hot reload
rmmod calculator
insmod calculator.ko num1=NEW num2=VALUES
```

### Tip 2: Test Multiple Values
```bash
# In QEMU:
for i in 10 20 30 40 50; do
    insmod calculator.ko num1=$i num2=5
    rmmod calculator
done
dmesg  # See all results!
```

### Tip 3: Debug Mode
```bash
# In QEMU:
dmesg -n 8              # Show all kernel messages
insmod calculator.ko
dmesg -c                # Clear and show
```

---

## 🎉 Summary

### What You Got:

1. **Setup script** (`setup-qemu.sh`)
   - Installs QEMU
   - Creates test environment
   - One-time setup

2. **Hybrid script** (`dev-hybrid.sh`)
   - Auto-detects Docker/QEMU
   - Works with either or both
   - Seamless switching

3. **QEMU testing**
   - Actually RUN your modules
   - Pass real parameters
   - See real output
   - Interactive debugging

4. **Keeps existing functionality**
   - Docker still works
   - All old commands work
   - New commands added
   - Nothing breaks!

---

## 🔗 Next Steps

1. Run `./setup-qemu.sh`
2. Run `./dev-hybrid.sh status` to check
3. Run `./dev-hybrid.sh build` to build
4. Run `./dev-hybrid.sh run-qemu` to test
5. **Load your calculator and see it work!**

---

**Bottom Line:** You can now test your modules for real, without needing an Android device! 🎊

---

*Created: October 8, 2025*  
*Purpose: Enable real module testing with QEMU*

