import unittest
import std/tables
import ../../pattern_matching

# ============================================================================
# BUG DISCOVERED: @ Patterns Not Supported in Table Value Positions
# ============================================================================
#
# CRITICAL BUG: The table pattern implementation does not support @ patterns
# in table value positions, causing compilation errors with the message:
# "Unsupported table value pattern 'nnkInfix' for key..."
#
# LOCATION: pattern_matching.nim around lines 3175-3188 in table processing
# ERROR MESSAGE: "Supported table value patterns: literals (42, "text"), 
# variables (x), wildcards (_), nested tables {"nested_key": value}"
#
# ROOT CAUSE: The table pattern processing case statement handles literals,
# variables, and nested tables but is missing support for nnkInfix patterns
# created by @ expressions in table values.
#
# EXPECTED BEHAVIOR: @ patterns should work in table values like other patterns:
# {"key": value @ var} should bind the table value to 'var' variable.

suite "Table @ Pattern Values Bug":

  test "@pattern in table values should compile and work":
    let data = {"grade": "A", "points": "95"}.toTable
    
    # This should work but currently fails with compilation error
    # "Unsupported table value pattern 'nnkInfix'"
    let result = match data:
      {"grade": "A" @ g, "points": points}: 
        "grade bound as: " & g & ", points: " & points
      _: "no match"
    
    check result == "grade bound as: A, points: 95"

  test "Simple @pattern in table should work now":
    let data = {"key": "value"}.toTable
    
    # This was the core bug - @ patterns didn't work in table values
    let result = match data:
      {"key": "value" @ v}: 
        "bound value: " & v
      _: "no match"
    
    check result == "bound value: value"

  test "Multiple @patterns in table values":
    let data = {"name": "Alice", "city": "NYC"}.toTable
    
    # Multiple @ patterns in table values
    let result = match data:
      {"name": "Alice" @ n, "city": city}:
        "person: " & n & ", city: " & city
      _: "no match"
    
    check result == "person: Alice, city: NYC"

  test "@pattern with wildcard":
    let data = {"temperature": "75"}.toTable
    
    # Wildcard @ pattern - should bind any value
    let result = match data:
      {"temperature": _ @ t}:
        "temp: " & t
      _: "no match"
    
    check result == "temp: 75"

# ============================================================================
# COMPILATION TEST TO VERIFY BUG EXISTS
# ============================================================================

suite "Table @ Pattern Compilation Test":
  
  test "Compilation test - @pattern in table value should compile":
    # This test verifies that the bug has been fixed
    let compiles = compiles(
      block:
        let data = {"key": "value"}.toTable
        discard match data:
          {"key": "value" @ v}: "bound: " & v
          _: "no match"
    )
    
    # With the fix, this should now be true
    check compiles == true

# ============================================================================
# BUG ANALYSIS AND FIX GUIDANCE
# ============================================================================
#
# ANALYSIS:
# The table pattern processing in pattern_matching.nim handles table value patterns
# in a case statement around lines 3093-3188. The cases include:
# - nnkIdent: Variable binding or wildcards  
# - Literal types: Direct value comparison
# - nnkTableConstr: Nested tables
# - nnkBracket, nnkCall, nnkObjConstr, etc.: Delegated to processNestedPattern
#
# MISSING: nnkInfix case for @ patterns
#
# FIX NEEDED:
# Add nnkInfix case to handle @ patterns in table values, similar to how
# other pattern contexts handle @ patterns. The fix should:
# 1. Detect @ operator in nnkInfix patterns  
# 2. Extract the value pattern and alias variable
# 3. Generate appropriate binding and condition code
# 4. Handle guard expressions if present
#
# SIMILAR WORKING CODE:
# Look at how @ patterns are handled in other contexts like tuple processing
# or sequence processing for implementation guidance.
#
# ============================================================================