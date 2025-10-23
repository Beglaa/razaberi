import unittest
import ../../pattern_matching

# ============================================================================
# @ PATTERN PARENTHESES BREAK BUG - CRITICAL BUG TEST
# ============================================================================
# BUG DESCRIPTION:
# In @-pattern processing with parentheses like (_ @ var) or (identifier @ var),
# when a wildcard or catch-all variable pattern is detected, the code incorrectly 
# uses `break` to exit the main pattern matching loop instead of just handling 
# the current pattern case.
#
# LOCATION: Lines 5001 and 5042 in pattern_matching.nim
# IMPACT: Patterns after parenthesized @-patterns are completely skipped
# 
# This test should FAIL until the bug is fixed.

suite "@ Pattern Parentheses Break Bug - CRITICAL":

  test "Parenthesized wildcard @ pattern should not break subsequent pattern processing":
    # This should process both patterns, but currently breaks after the first
    var result = ""
    
    let value1 = 42
    match value1:
      (_ @ captured) and captured > 50:
        result = "large"
      (_ @ captured) and captured < 50: 
        result = "small"  # This should match but is currently skipped due to break bug
      _:
        result = "fallback"
    
    # BUG: Currently result = "" because the break exits the loop entirely
    check result == "small"

  test "Parenthesized variable @ pattern should not break subsequent pattern processing":
    # Similar bug with variable patterns in parentheses
    var result = ""
    
    let value2 = "test"
    match value2:
      (x @ alias) and x.len > 10:
        result = "long"
      (y @ alias) and y.len < 10:
        result = "short"  # This should match but is currently skipped due to break bug
      _:
        result = "fallback"
    
    # BUG: Currently result = "" because the break exits the loop entirely  
    check result == "short"

  test "Complex case with multiple parenthesized @ patterns":
    # More complex case to demonstrate the scope of the bug
    var results: seq[string] = @[]
    
    for testValue in [1, 5, 10, 15]:
      var result = ""
      match testValue:
        (_ @ val) and val == 1:
          result = "one"
        (_ @ val) and val in 2..5:
          result = "low"   # This should match for value 5
        (_ @ val) and val in 6..10:
          result = "medium" # This should match for value 10
        (_ @ val) and val > 10:
          result = "high"   # This should match for value 15
        _:
          result = "unknown"
      
      results.add(result)
    
    # BUG: All values after first match are likely incorrect due to early break
    check results[0] == "one"     # Should work
    check results[1] == "low"     # BUG: Likely fails due to break
    check results[2] == "medium"  # BUG: Likely fails due to break  
    check results[3] == "high"    # BUG: Likely fails due to break

  test "Nested parenthesized @ patterns with guards":
    # Test the specific problematic code paths
    var result = ""
    
    let testData = (name: "test", value: 42)
    match testData:
      (data @ alias) and data.value > 100:
        result = "high_value"
      (data @ alias) and data.value < 100:
        result = "low_value"  # Should match but may be skipped
      _:
        result = "no_match"
    
    check result == "low_value"

  test "Parenthesized @ patterns with different data types":
    # Test across different data types to ensure the bug affects all cases
    var stringResult = ""
    var intResult = ""
    var boolResult = ""
    
    # String case
    let str = "hello"
    match str:
      (_ @ s) and s.len > 10:
        stringResult = "long"
      (_ @ s) and s.len <= 10:
        stringResult = "normal"  # Should match
      _:
        stringResult = "unknown"
    
    # Integer case  
    let num = 7
    match num:
      (_ @ n) and n > 10:
        intResult = "big"
      (_ @ n) and n <= 10:
        intResult = "small"  # Should match
      _:
        intResult = "unknown"
        
    # Boolean case
    let flag = true
    match flag:
      (_ @ b) and not b:
        boolResult = "false"
      (_ @ b) and b:
        boolResult = "true"   # Should match
      _:
        boolResult = "unknown"
    
    check stringResult == "normal"
    check intResult == "small" 
    check boolResult == "true"

  test "Regression test: ensure fix doesn't break valid @ pattern behavior":
    # This test verifies that fixing the bug doesn't break existing functionality
    var result = ""
    
    let value = 25
    match value:
      (_ @ x) and x > 30:
        result = "high"
      (_ @ x):  # This should match and bind the value
        result = "got_" & $x
    
    # This should work both before and after the fix
    check result == "got_25"

  test "Performance impact test: multiple @ patterns should all be evaluated":
    # Ensure the bug doesn't cause performance issues by skipping pattern evaluation
    var matchCount = 0
    
    for i in 1..10:
      match i:
        (_ @ x) and x == 1:
          matchCount += 1
        (_ @ x) and x == 2:
          matchCount += 1  # Bug may prevent this from being reached
        (_ @ x) and x == 3:
          matchCount += 1  # Bug may prevent this from being reached
        (_ @ x) and x in 4..10:
          matchCount += 1  # Bug may prevent this from being reached
        _:
          discard
    
    # All 10 values should match exactly one pattern each
    check matchCount == 10

# ============================================================================
# WORKLOG ENTRY FOR BUG
# ============================================================================
# ## @ Pattern Break Bug - Loop Control
# **Timestamp:** 2025-08-26
# **Issue:** @ patterns with parentheses like (_ @ var) and (identifier @ var) 
#            use incorrect `break` statements that exit the main pattern matching 
#            loop instead of just handling the current pattern case.
# **Location:** Lines 5001 and 5042 in pattern_matching.nim  
# **Impact:** Patterns after parenthesized @ patterns are completely skipped,
#             causing match expressions to fail to evaluate subsequent arms.
# **Test File:** test_at_pattern_parentheses_break_bug.nim
# **Status:** Discovered - needs fix implementation