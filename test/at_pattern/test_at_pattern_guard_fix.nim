import unittest
include ../../pattern_matching

# ============================================================================
# @ PATTERN WITH GUARD BUG FIX TEST
# ============================================================================
# This test validates the fix for @ patterns combined with guards.
# The bug occurred when parsing patterns like:
# - (1 | 2) @ val and val > 0
# - ((1 | 2) @ first_val and first_val > 0, (3 | 4) @ second_val and second_val < 10)
# ============================================================================

suite "@ Pattern with Guard Bug Fix":

  test "Simple @ Pattern with Guard":
    let data = 2
    var result = false
    var captured_val = 0
    
    match data:
      (1 | 2) @ val and val > 0:
        result = true
        captured_val = val
      _:
        result = false
    
    check result == true
    check captured_val == 2

  test "Literal @ Pattern with Guard":
    let data = 5
    var result = false
    var captured_val = 0
    
    match data:
      5 @ val and val > 3:
        result = true
        captured_val = val
      _:
        result = false
    
    check result == true
    check captured_val == 5

  test "Basic Tuple @ Pattern with Guards":
    let data = (2, 3)
    var result = false
    var captured_first = 0
    var captured_second = 0
    
    match data:
      ((1 | 2) @ first_val and first_val > 0, (3 | 4) @ second_val and second_val < 10):
        result = true
        captured_first = first_val
        captured_second = second_val
      _:
        result = false
    
    check result == true
    check captured_first == 2
    check captured_second == 3

  test "Mixed Simple and Complex @ Patterns":
    let data = (10, 20)
    var result = false
    var captured_first = 0
    var captured_second = 0
    
    match data:
      (10 @ first_val and first_val == 10, (15 | 20 | 25) @ second_val and second_val >= 15):
        result = true
        captured_first = first_val
        captured_second = second_val
      _:
        result = false
    
    check result == true
    check captured_first == 10
    check captured_second == 20

  test "Guard with Multiple Conditions":
    let data = 15
    var result = false
    var captured_val = 0
    
    match data:
      (10 | 15 | 20) @ val and val > 10 and val < 20:
        result = true
        captured_val = val
      _:
        result = false
    
    check result == true
    check captured_val == 15