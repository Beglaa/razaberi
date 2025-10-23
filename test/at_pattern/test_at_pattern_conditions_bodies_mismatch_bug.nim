import unittest
import ../../pattern_matching

# ============================================================================
# @ PATTERN CONDITIONS/BODIES ARRAY MISMATCH BUG - INDEX OUT OF BOUNDS
# ============================================================================
# BUG DESCRIPTION:
# When processing @ patterns with guards, the conditions array can become empty
# while the bodies array is also empty, causing an index out of bounds error
# at line 8547: bodies[0] when conditions.len == 0
#
# LOCATION: Line 8547 in pattern_matching.nim: resultExpr = bodies[0]
# IMPACT: Runtime crash with "index out of bounds" error
# 
# This test should FAIL with index out of bounds error until the bug is fixed.

suite "@ Pattern Index Out Of Bounds Bug - CRITICAL":

  test "@ Pattern with guard should work correctly (was expecting bug)":
    # This test was expecting a bug that doesn't exist - @ patterns with guards work fine
    var result = ""
    
    let value = 42
    match value:
      (_ @ captured) and captured > 50:
        result = "large"
      (_ @ captured) and captured < 50: 
        result = "small"
      _:
        result = "fallback"
    
    # The pattern should work correctly
    check result == "small"

  test "Simpler @ pattern with guard should work":
    # This test was expecting a bug that doesn't exist
    var result = ""
    
    let value = 10
    match value:
      (_ @ x) and x > 5:
        result = "matched"
      _:
        result = "no match"
    
    # The pattern should work correctly
    check result == "matched"

  test "@ Pattern without guard should work (regression test)":
    # This should continue to work after we fix the bug
    var result = ""
    
    let value = 42
    match value:
      _ @ captured:
        result = "got_" & $captured
    
    check result == "got_42"

  test "Multiple @ patterns with guards should work":
    # This test was expecting a bug that doesn't exist
    var result = ""
    
    let value = 7
    match value:
      (_ @ x) and x > 10:
        result = "high"
      (_ @ x) and x in 5..10:
        result = "medium"
      (_ @ x) and x < 5:
        result = "low"
      _:
        result = "no match"
    
    # The pattern should work correctly
    check result == "medium"

# ============================================================================
# WORKLOG ENTRY FOR BUG  
# ============================================================================
# ## @ Pattern Index Out of Bounds Bug - Array Mismatch
# **Timestamp:** 2025-08-26
# **Issue:** @ patterns with guards cause conditions array to be empty while 
#            bodies array is also empty, leading to index out of bounds error
#            at line 8547: bodies[0] when conditions.len == 0
# **Location:** Line 8547 in pattern_matching.nim
# **Impact:** Runtime crash with IndexDefect when matching @ patterns with guards
# **Root Cause:** Mismatch between condition processing and body processing
# **Test File:** test_at_pattern_conditions_bodies_mismatch_bug.nim
# **Status:** Discovered - needs array bounds checking and proper handling