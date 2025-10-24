# QEMU Setup Guide - Run Without Docker

## Overview

This guide shows you how to build and test Android kernel modules using **QEMU on your Mac** instead of Docker.

---

## 🎯 What You Get

| Feature | Docker | QEMU (Mac) |
|---------|--------|------------|
| Build kernel | ✅ Full | ⚠️ Limited* |
| Build modules | ✅ Yes | ✅ Yes (with headers) |
| Test modules | ❌ No runtime | ✅ Full runtime! |
| See actual output | ❌ No | ✅ Yes via dmesg! |
| Pass parameters | ❌ No | ✅ Yes! |

*QEMU on Mac can test, Docker still recommended for full kernel builds

---

## 🚀 Quick Start

### Step 1: Setup QEMU
```bash
cd /Users/avinash.kumar2/Downloads/GenAI/beverage-alc-genai/android-asm-security-qemu

# Make scripts executable
chmod +x setup-qemu.sh dev-hybrid.sh

# Run setup
./setup-qemu.sh
```

### Step 2: Build Kernel (Use Docker or existing build)
```bash
# If Docker available
./dev-hybrid.sh build

# Check status
./dev-hybrid.sh status
```

### Step 3: Test in QEMU
```bash
# Start QEMU with your kernel
./dev-hybrid.sh run-qemu

# In QEMU, load your modules
insmod /path/to/calculator.ko num1=42 num2=58
dmesg | tail -100
```

---

## 📋 Detailed Setup

### Prerequisites

Install Homebrew packages:
```bash
# Install QEMU
brew install qemu

# Install cross-compiler (optional, for local builds)
brew install aarch64-elf-gcc

# Or use Docker just for building
brew install docker
```

---

## 🔧 Usage Modes

### Mode 1: Docker Build + QEMU Test (Recommended)
```bash
# Build with Docker (full kernel + modules)
./dev-hybrid.sh build

# Test in QEMU (see actual output!)
./dev-hybrid.sh run-qemu
```

### Mode 2: Pure QEMU (No Docker)
```bash
# Setup QEMU
./setup-qemu.sh

# Use pre-built kernel or build locally
# (Local build has limitations)

# Test in QEMU
./dev-hybrid.sh run-qemu
```

### Mode 3: Hybrid (Best of Both)
```bash
# Check what's available
./dev-hybrid.sh status

# Auto-selects best option
./dev-hybrid.sh build
```

---

## 🧪 Testing Your Calculator Module in QEMU

### Start QEMU
```bash
./dev-hybrid.sh run-qemu
```

### In QEMU Shell

```bash
# Navigate to modules
cd /path/to/modules

# Load calculator with parameters
insmod calculator.ko num1=100 num2=50

# See YOUR actual output!
dmesg | tail -100
```

**Expected Output:**
```
========================================
   Calculator Module Loaded
========================================

🔹 Using module parameters:
─────────────────────────────────────
Module Parameters:
  100 + 50 = 150      ← YOUR INPUT!
  100 - 50 = 50
  100 * 50 = 5000
  100 / 50 = 2

🔹 Testing different values:
─────────────────────────────────────
Test 1: Small numbers:
  10 + 5 = 15
  ...
```

### Unload Module
```bash
rmmod calculator

dmesg | tail -20
# See exit message with your values!
```

---

## 🎨 Architecture

```
┌─────────────────────────────────────────┐
│  Mac (Your Computer)                    │
│                                         │
│  ┌──────────────┐    ┌──────────────┐  │
│  │   Docker     │    │    QEMU      │  │
│  │  (Build)     │───▶│  (Test)      │  │
│  │              │    │              │  │
│  │  • Compile   │    │  • Boot      │  │
│  │  • Link      │    │  • Load      │  │
│  │  • Generate  │    │  • Run       │  │
│  │    .ko files │    │  • dmesg     │  │
│  └──────────────┘    └──────────────┘  │
│                                         │
│  OR pure QEMU if no Docker              │
└─────────────────────────────────────────┘
```

---

## 📁 File Structure

```
android-asm-security-qemu/
├── dev-hybrid.sh           # New hybrid script
├── setup-qemu.sh           # QEMU setup
├── dev.sh                  # Original Docker script
├── qemu-env/              # QEMU environment
│   ├── run-qemu.sh        # Launch QEMU
│   ├── test-modules.sh    # Test helpers
│   └── rootfs.ext4        # Root filesystem
└── android-build/
    ├── modules/           # Your .c files
    └── kernel-out/        # Built modules
```

---

## 🔍 Command Reference

### Setup & Status
```bash
./setup-qemu.sh              # One-time QEMU setup
./dev-hybrid.sh status       # Check environment
```

### Building
```bash
./dev-hybrid.sh build        # Auto-detect best method
./dev-hybrid.sh build-local  # Force local build (limited)
./dev-hybrid.sh clean        # Clean all
```

### Testing
```bash
./dev-hybrid.sh run-qemu     # Start QEMU
./dev-hybrid.sh test         # Check module metadata
```

### Development
```bash
./dev-hybrid.sh shell        # Enter build environment
```

---

## 🆚 Docker vs QEMU Comparison

### Use Docker When:
- ✅ Building full Android kernel from source
- ✅ Need complete Linux environment
- ✅ Want reproducible builds
- ✅ Have Docker installed

### Use QEMU When:
- ✅ **Testing modules with real input/output**
- ✅ Want to see actual `dmesg` output
- ✅ Need to test different parameters
- ✅ Want interactive testing
- ✅ No Docker available

### Best Approach:
**Use BOTH!**
1. Build with Docker (fast, complete)
2. Test with QEMU (see real results!)

---

## 🐛 Troubleshooting

### QEMU Not Starting
```bash
# Check QEMU installation
brew list qemu

# Reinstall if needed
brew reinstall qemu
```

### Kernel Not Found
```bash
# Build first
./dev-hybrid.sh build

# Check if exists
ls -lh android-build/kernel-out/kernel/Image
```

### Modules Not Loading in QEMU
```bash
# Check modules exist
ls -lh android-build/kernel-out/kernel/*.ko

# In QEMU, check kernel version match
uname -r
modinfo calculator.ko | grep vermagic
```

### Can't See Module Output
```bash
# In QEMU, check kernel log level
dmesg -n 8  # Enable all messages

# Then load module
insmod calculator.ko num1=10 num2=5

# Check output
dmesg | tail -50
```

---

## 💡 Tips & Tricks

### Tip 1: Quick Test Cycle
```bash
# Terminal 1: Keep QEMU running
./dev-hybrid.sh run-qemu

# Terminal 2: Build new version
./dev-hybrid.sh build

# Terminal 1 (in QEMU): Reload module
rmmod calculator
insmod calculator.ko num1=NEW num2=VALUES
dmesg | tail
```

### Tip 2: Save QEMU State
```bash
# In QEMU monitor (Ctrl+A, then C)
savevm mystate

# Later, restore
loadvm mystate
```

### Tip 3: Share Files with QEMU
```bash
# Add to run-qemu.sh:
-virtfs local,path=/path/to/modules,mount_tag=modules,security_model=none
```

---

## 🎓 Learning Path

1. **Start with Docker** (Easy builds)
2. **Setup QEMU** (See actual output!)
3. **Test modules** (Real parameters!)
4. **Iterate quickly** (Build → Test → Repeat)

---

## 📚 Next Steps

1. ✅ Run `./setup-qemu.sh`
2. ✅ Build: `./dev-hybrid.sh build`
3. ✅ Test: `./dev-hybrid.sh run-qemu`
4. ✅ Load module in QEMU
5. ✅ See YOUR code run!

---

## 🎉 Benefits of This Setup

| Before (Docker only) | After (Docker + QEMU) |
|---------------------|----------------------|
| ❌ Can't test modules | ✅ Full testing |
| ❌ Can't see output | ✅ See dmesg! |
| ❌ Can't pass parameters | ✅ Pass any values! |
| ❌ Just verify binary | ✅ Actually RUN code! |

**Now you can:**
- See your `pr_info()` messages
- Test different input values
- Watch module load/unload
- Debug in real-time

---

*Created: October 8, 2025*  
*Purpose: Enable QEMU testing without requiring Docker*

