import unittest
import ../../pattern_matching

# Test ONLY the same-variable cases that should work with my current implementation
suite "Variable Binding Same Variable Cases - SHOULD WORK":

  test "Same variable x in OR alternatives with and/or guards":
    # Pattern: (data @ x and x > 10) | (data @ x or x < 0)
    # Both alternatives bind the same variable 'x' - this should work
    
    let result1 = match 15:
      (data @ x and x > 10) | (data @ x or x < 0): "matched with x=" & $x
      _: "no match"
    check result1 == "matched with x=15"
    
    let result2 = match -3:
      (data @ x and x > 10) | (data @ x or x < 0): "matched with x=" & $x  
      _: "no match"
    check result2 == "matched with x=-3"

  test "Control: Simple OR patterns without @ should still work":
    # Control test - simple OR patterns without @ should work
    let result = match 5:
      3 | 5 | 7: "matched simple or"
      _: "no match"
    check result == "matched simple or"

  test "Control: Single @ patterns should still work":
    # Control test - single @ patterns should work
    let result1 = match 15:
      x @ val and val > 10: "and guard works: " & $val
      _: "no match"
    check result1 == "and guard works: 15"