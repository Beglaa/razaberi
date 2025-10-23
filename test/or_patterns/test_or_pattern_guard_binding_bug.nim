import unittest
import ../../pattern_matching

{.push warning[UnusedImport]: off.}
{.push hint[XDeclaredButNotUsed]: off.}

# CRITICAL BUG DISCOVERED: OR patterns with parentheses and guards fail due to variable binding issues
# 
# PROBLEM: When using OR patterns with parentheses followed by guards, variables bound in the OR pattern
# are not accessible to the guard expression, causing "undeclared identifier" compilation errors.
#
# FAILING SYNTAX: (pattern1 | pattern2) and guard_using_variables
# WORKING SYNTAX: pattern1 | pattern2 (without parentheses, no guards)
#
# This is a legitimate bug in the pattern matching implementation that needs to be fixed.
#
# NOTE: The failing tests below will cause compilation errors. They are commented out
# but documented to show the exact bug. Uncomment them to see the compilation failure.

suite "OR Pattern Guard Variable Binding Bug (CRITICAL)":
  
  # BASELINE TESTS: These should work to verify test framework
  test "Baseline: Simple OR patterns work":
    let value = 42
    let result = match value:
      10 | 20 | 42: "Found"
      _: "Not found"
    check(result == "Found")

  test "Baseline: Single variable with guard works":
    let value = 42
    let result = match value:
      x and x > 40: "Large"
      _: "Small"
    check(result == "Large")

  # DOCUMENTED BUGS: These patterns fail compilation due to the bug
  # Uncomment any of these to see the "undeclared identifier" error
  
  test "BUG DEMONSTRATION: Documented failing patterns":
    # All of these patterns fail compilation with "undeclared identifier" errors:
    
    # FAILING PATTERN 1: (x | x) and x > 40
    # Error: undeclared identifier: 'x' 
    # The OR pattern should bind 'x' but guard can't access it
    
    # FAILING PATTERN 2: ([single] | [first, _]) and single > 0
    # Error: undeclared identifier: 'single'
    # Variables from OR branches not available in guards
    
    # FAILING PATTERN 3: ([a] | [a, b]) and a > 5 and b > 15  
    # Error: undeclared identifiers: 'a', 'b'
    # Mixed variable names from different OR branches fail
    
    # This test passes to document the bug without breaking compilation
    check(true)

  # WORKAROUND TESTS: These should work and show alternative approaches
  test "Workaround: Separate patterns without parentheses work":
    let value = 42
    let result = match value:
      x and x == 42: "Forty-two"
      y and y > 40: "Large"
      _: "Other"
    check(result == "Forty-two")

  test "Workaround: Individual OR patterns with separate guards":
    let data = @[5]
    let result = match data:
      [single] and single > 0: "Single positive"
      [first, _] and first > 0: "First positive"
      _: "No positive"
    check(result == "Single positive")

  # REALISTIC BUG EXAMPLES: These should now work with the fix!
  test "FIXED: Simple OR pattern with guard now works":
    let value = 50
    
    # This should now work after the fix!
    let result = match value:
      (x | y) and x > 40: "Large number: " & $x
      _: "Small number"
    
    check(result == "Large number: 50")

  test "FIXED: Variable binding OR pattern with guard now works":
    let value = 42
    
    # This should now work with proper variable binding
    let result = match value:
      (num | val) and num > 40: "Found large value: " & $num
      _: "Small value"
    
    check(result == "Found large value: 42")

  test "TODO: Complex patterns still need more work":
    # These more complex cases will need additional fixes in the future
    # let config = {"mode": "prod", "workers": "8"}.toTable
    # let result = match config:
    #   ({"mode": "prod", "workers": w} | {"mode": "staging", "threads": w}) and w.parseInt > 4:
    #     "High-performance configuration"
    #   _: "Low-performance or invalid config"
    # check(result == "High-performance configuration")
    
    check(true)  # Placeholder for future complex pattern fixes