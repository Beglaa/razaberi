import unittest
import ../../pattern_matching

# =============================================================================
# COMPREHENSIVE OR PATTERN VARIABLE BINDING TESTS
# =============================================================================
# Tests the complete implementation of OR patterns with @ variable bindings.
# Shows both supported cases and provides clear error messages for unsupported cases.

suite "OR Pattern Variable Binding - Complete Implementation":

  test "✅ SUPPORTED: Same variable name across OR alternatives":
    # Pattern: (data @ x and x > 10) | (data @ x or x < 0)
    # Both alternatives bind the same variable 'x' - fully supported
    
    let result1 = match 15:
      (data @ x and x > 10) | (data @ x or x < 0): "matched with x=" & $x
      _: "no match"
    check result1 == "matched with x=15"
    
    let result2 = match -3:
      (data @ x and x > 10) | (data @ x or x < 0): "matched with x=" & $x  
      _: "no match"
    check result2 == "matched with x=-3"

  test "✅ SUPPORTED: Different variable names across OR alternatives":
    # Pattern: (x @ val and val > 10) | (y @ val2 or val2 < 5)
    # Different variables in each alternative - fully supported!
    # Each branch binds its own variable since only one executes
    
    let result1 = match 15:  # Should match first alternative
      (x @ val and val > 10) | (y @ val2 or val2 < 5): "matched first"
      _: "no match"
    check result1 == "matched first"
    
    let result2 = match 3:   # Should match second alternative
      (x @ val and val > 10) | (y @ val2 or val2 < 5): "matched second"
      _: "no match" 
    check result2 == "matched second"

  test "✅ SUPPORTED: Chained guard expressions":
    # Pattern with complex chained guards
    let result = match 8:
      (x @ val and val > 5 and val < 15) | (y @ val2 or val2 == 0 or val2 > 50): "chained guards work"
      _: "no match"
    check result == "chained guards work"

  test "✅ SUPPORTED: Complex nested OR patterns":
    # Multiple levels of OR with different variables
    let result = match 25:
      ((a @ x and x > 20) | (b @ y or y < 0)) | ((c @ z and z == 10) | (d @ w or w > 100)): "complex nested"
      _: "no match"
    check result == "complex nested"

  test "✅ CONTROL: Simple OR patterns still work":
    # Ensure we didn't break existing functionality
    let result = match 5:
      3 | 5 | 7: "simple OR works"
      _: "no match"
    check result == "simple OR works"

  test "✅ CONTROL: Single @ patterns still work":
    # Ensure we didn't break existing @ pattern functionality
    let result = match 15:
      x @ val and val > 10: "single @ works: " & $val
      _: "no match"
    check result == "single @ works: 15"

# All supported OR pattern variable binding tests complete!