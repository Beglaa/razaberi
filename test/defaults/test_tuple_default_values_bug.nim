import unittest
import ../../pattern_matching

# TUPLE DEFAULT VALUES PATTERN BUG - MISSING FEATURE PARITY
#
# BUG DISCOVERED: Tuple patterns do not support default values while sequence patterns do
#
# CRITICAL BUG: The pattern matching library supports default values for sequence patterns:
# [x, y = 10, z = 0] but does not support equivalent syntax for tuple patterns: (x, y = 10, z = 0)
# This is a significant inconsistency and missing feature that breaks symmetry between
# sequence and tuple pattern matching.
#
# TECHNICAL ISSUE:
# The tuple pattern processing in processTupleLayer (around line 4200-4600) does not include
# the extractDefaultValue logic that exists for sequence patterns. When the parser encounters
# tuple elements with = syntax, it fails with "Unsupported tuple element at layer 1".
#
# IMPACT:
# - Users cannot write flexible tuple patterns that work with tuples of varying lengths
# - Missing feature parity between sequence [x, y=10] and tuple (x, y=10) patterns  
# - Forces users to write multiple pattern arms for different tuple sizes
# - Breaks the principle of least surprise - sequences support defaults but tuples don't

suite "Tuple Default Values Pattern Bug":
  
  test "BUG: Simple tuple pattern with single default value fails":
    let input = (42,)  # Single element tuple
    
    # This should work: if tuple has one element, use it; if missing elements, use defaults
    # Currently fails with: "Unsupported tuple element at layer 1"
    # FIXED: Compilation test now enabled - tuple defaults work!
    let result = match input:
      (x, y = 10): x + y  # Should use x=42, y=10 (default)
      _: 0
    
    check result == 52  # 42 + 10

  test "BUG: Tuple pattern with multiple default values fails":
    let input1 = (5,)      # One element tuple
    let input2 = (5, 15)   # Two element tuple  
    let input3 = (5, 15, 25) # Three element tuple
    
    # FIXED: These should all work with different numbers of defaults applied
    let result1 = match input1:
      (x, y = 100, z = 200): x + y + z  # Should be 5 + 100 + 200 = 305
      _: 0
    
    let result2 = match input2:
      (x, y = 100, z = 200): x + y + z  # Should be 5 + 15 + 200 = 220  
      _: 0
    
    let result3 = match input3:
      (x, y = 100, z = 200): x + y + z  # Should be 5 + 15 + 25 = 45
      _: 0
    
    check result1 == 305
    check result2 == 220  
    check result3 == 45

  test "BUG: Tuple default values should work with @ patterns":
    let input = (100,)  # Single element tuple
    
    # FIXED: @ patterns with defaults should work like in sequences
    let result = match input:
      (value @ v, multiplier = 2): v * multiplier  # Should use value=100, multiplier=2 (default)
      _: 0
    
    check result == 200  # 100 * 2

  test "BUG: Nested tuple patterns with defaults should work":
    let input = ((42, "test"),)  # Nested tuple with one outer element
    
    # FIXED: Complex nested patterns with defaults should work
    let result = match input:
      ((x, name), bonus = 10): x + bonus  # Should use nested (42, "test") and bonus=10 default
      _: 0
    
    check result == 52  # 42 + 10

  test "BUG COMPARISON: Sequence default values work correctly (for reference)":
    let seq_input = @[42]  # Single element sequence
    
    # This works fine - demonstrates the expected behavior for tuples
    let result = match seq_input:
      [x, y = 10]: x + y  # Uses x=42, y=10 (default)
      _: 0
    
    check result == 52  # 42 + 10
    
    # This shows tuple patterns should have equivalent functionality

  test "FIXED: Tuple patterns now support defaults instead of workarounds":
    let input1 = (42,)     # Single element tuple
    let input2 = (42, 10)  # Two element tuple
    
    # NEW: Both cases can now use same pattern with defaults!
    let result1 = match input1:
      (x, y = 10): x + y  # Uses default y=10
      _: 0
    
    let result2 = match input2:  
      (x, y = 10): x + y  # Uses actual y=10  
      _: 0
    
    check result1 == 52  # 42 + 10
    check result2 == 52  # 42 + 10
    
    # IMPROVEMENT: Both cases now use same elegant pattern: (x, y = 10)

# COMPILATION TEST TO VERIFY BUG EXISTS
#
# Uncomment the following test to see the actual compilation error:
# "Unsupported tuple element at layer 1"

when true:  # Set to true to see the bug
  suite "Tuple Default Values Compilation Bug":
    test "COMPILATION BUG: This will fail to compile":
      let input = (42,)
      let result = match input:
        (x, y = 10): x + y  # This causes compilation error
        _: 0
      check result == 52