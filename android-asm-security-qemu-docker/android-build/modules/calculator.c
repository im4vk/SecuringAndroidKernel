/*
 * Simple Calculator Kernel Module
 * Takes two numbers as parameters and prints their sum
 */

#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Your Name");
MODULE_DESCRIPTION("Calculator - Add Two Numbers");
MODULE_VERSION("1.0");

// Module parameters - these are the "inputs"
static int num1 = 30;
static int num2 = 10;

// Make parameters accessible when loading module
module_param(num1, int, 0644);
module_param(num2, int, 0644);

// Parameter descriptions
MODULE_PARM_DESC(num1, "First number");
MODULE_PARM_DESC(num2, "Second number");

// FUNCTION: Calculate and print results
static void calculate_and_print(int a, int b, const char *label) {
    int sum = a + b;
    int sub = a - b;
    int mul = a * b;
    int div = (b != 0) ? (a / b) : 0;
    
    pr_info("─────────────────────────────────────\n");
    pr_info("%s:\n", label);
    pr_info("  %d + %d = %d\n", a, b, sum);
    pr_info("  %d - %d = %d\n", a, b, sub);
    pr_info("  %d * %d = %d\n", a, b, mul);
    if (b != 0) {
        pr_info("  %d / %d = %d\n", a, b, div);
    } else {
        pr_info("  %d / %d = ERROR (division by zero)\n", a, b);
    }
}

static int __init calculator_init(void) {
    pr_info("========================================\n");
    pr_info("   Calculator Module Loaded\n");
    pr_info("========================================\n");
    
    // Call function with module parameters
    pr_info("\n🔹 Using module parameters:\n");
    calculate_and_print(num1, num2, "Module Parameters");
    
    // Call function with different hardcoded values
    pr_info("\n🔹 Testing different values:\n");
    calculate_and_print(10, 5, "Test 1: Small numbers");
    calculate_and_print(100, 25, "Test 2: Larger numbers");
    calculate_and_print(7, 3, "Test 3: Prime-ish");
    calculate_and_print(50, 2, "Test 4: Division test");
    calculate_and_print(15, 0, "Test 5: Division by zero");
    
    // Call function with negative numbers
    pr_info("\n🔹 Testing negative numbers:\n");
    calculate_and_print(-10, 5, "Test 6: Negative + Positive");
    calculate_and_print(-20, -5, "Test 7: Both negative");
    
    pr_info("\n========================================\n");
    pr_info("✅ All calculations complete!\n");
    pr_info("========================================\n");
    
    return 0;
}

static void __exit calculator_exit(void) {
    pr_info("========================================\n");
    pr_info("   Calculator Module Unloaded\n");
    pr_info("========================================\n");
    
    // Call function one last time with final values
    pr_info("🔹 Final calculation before exit:\n");
    calculate_and_print(num1, num2, "Exit Values");
    
    pr_info("========================================\n");
    pr_info("Goodbye!\n");
    pr_info("========================================\n");
}

module_init(calculator_init);
module_exit(calculator_exit);

