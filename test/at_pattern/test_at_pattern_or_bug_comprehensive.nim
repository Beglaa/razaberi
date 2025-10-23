import unittest
import ../../pattern_matching

# =============================================================================
# BUG DISCOVERED: @ Pattern with OR Patterns Compilation Failure
# =============================================================================
#
# ISSUE: The pattern matching implementation fails to compile @ patterns where 
#        the left operand (the pattern being bound) contains OR pattern alternatives.
#
# SYMPTOMS: Compilation error: "Unsupported @ sub-pattern in nested tuple" 
#           at line 3162 in pattern_matching.nim (processTupleLayer function)
#
# ROOT CAUSE: The tuple processing logic in processTupleLayer() around line 3162
#             expects simple patterns in @ expressions, but doesn't handle cases 
#             where the @ pattern's left operand is a complex OR pattern expression.
#
# PATTERN: ((alt1 | alt2 | alt3) @ variable, other_var)
#
# EXPECTED BEHAVIOR: Should bind 'variable' to the matched alternative value
#                   and make it available in the pattern body.
#
# ACTUAL BEHAVIOR: Compilation failure due to AST parsing issue.
#
# EXAMPLES THAT SHOULD WORK BUT FAIL:
# - ((5 | 10 | 15) @ val, str): body
# - (((1 | 2) @ a, b), c): body  
# - (("exit" | "quit") @ item, status): body
#
# =============================================================================

suite "@ Pattern with OR Patterns Bug - COMPREHENSIVE FAILING TESTS":
  
  # =========================================================================
  # BASIC FAILING CASES
  # =========================================================================
  
  test "simple @ pattern with numeric OR - COMPILATION FAILS":
    # DESCRIPTION: Basic @ pattern with numeric OR alternatives
    # EXPECTED: Should bind 'val' to 10 and execute body
    # ACTUAL: Compilation error at tuple processing
    
    let data = (10, "test")
    
# This should compile and bind val=10, but currently fails
    let result = match data:
      ((5 | 10 | 15) @ val, str): "matched val: " & $val & " str: " & str
      _: "no match"
    
    check(result == "matched val: 10 str: test")
    
  test "simple @ pattern with string OR - COMPILATION FAILS":
    # DESCRIPTION: @ pattern with string OR alternatives  
    # EXPECTED: Should bind 'cmd' to "quit" and execute body
    # ACTUAL: Compilation error
    
    let data = ("quit", true)
    
    let result = match data:
      (("exit" | "quit" | "stop") @ cmd, status): "command: " & cmd & " status: " & $status
      _: "no match"
    
    check(result == "command: quit status: true")

  # =========================================================================
  # NESTED FAILING CASES
  # =========================================================================
    
  test "nested @ pattern with OR in tuple - COMPILATION FAILS":
    # DESCRIPTION: Nested tuple with @ pattern containing OR
    # EXPECTED: Should bind 'a' to 10 and work with nested structure
    # ACTUAL: Compilation error in nested tuple processing
    
    let data = ((10, 20), 30)
    
    let result = match data:
      (((5 | 10 | 15) @ a, b), c): "matched a: " & $a & " b: " & $b & " c: " & $c
      _: "no match"
    
    check(result == "matched a: 10 b: 20 c: 30")

  # =========================================================================
  # GUARD COMBINATION FAILING CASES
  # =========================================================================
    
  test "@ pattern with OR and guards - COMPILATION FAILS":
    # DESCRIPTION: @ pattern with OR alternatives plus guard conditions
    # EXPECTED: Should bind 'val' and use it in guard expression
    # ACTUAL: Compilation error before guard processing
    
    let data = (10, "test")
    
    let result = match data:
      ((5 | 10 | 15) @ val, str) and val > 8: "big val: " & $val & " str: " & str
      ((5 | 10 | 15) @ val, str): "small val: " & $val & " str: " & str  
      _: "no match"
    
    check(result == "big val: 10 str: test")

  # =========================================================================
  # COMPLEX STRUCTURAL FAILING CASES  
  # =========================================================================
    
  test "multiple @ patterns with OR in same tuple - COMPILATION FAILS":
    # DESCRIPTION: Multiple @ patterns with OR alternatives in one tuple
    # EXPECTED: Should bind both variables and work correctly
    # ACTUAL: Compilation error
    
    let data = (10, 25)
    
    let result = match data:
      ((5 | 10 | 15) @ a, (20 | 25 | 30) @ b): "matched a: " & $a & " b: " & $b
      _: "no match"
    
    check(result == "matched a: 10 b: 25")
    
  test "deeply nested @ pattern with OR - COMPILATION FAILS":
    # DESCRIPTION: Deep nesting with @ patterns containing OR
    # EXPECTED: Should handle complex nested structure
    # ACTUAL: Compilation error in deep tuple processing
    
    let data = (((10, "inner"), 20), 30)
    
    let result = match data:
      ((((5 | 10 | 15) @ val, str), mid), outer): 
        "deep: val=" & $val & " str=" & str & " mid=" & $mid & " outer=" & $outer
      _: "no match"
    
    check(result == "deep: val=10 str=inner mid=20 outer=30")

  # =========================================================================
  # MIXED PATTERN TYPE FAILING CASES
  # =========================================================================
    
  test "@ pattern with OR mixed with other patterns - COMPILATION FAILS":
    # DESCRIPTION: @ patterns with OR mixed alongside regular patterns
    # EXPECTED: Should work with mixed pattern types
    # ACTUAL: Compilation error
    
    let data = (10, "test", true)
    
    let result = match data:
      ((5 | 10 | 15) @ val, str, flag): 
        "mixed: val=" & $val & " str=" & str & " flag=" & $flag
      _: "no match"
    
    check(result == "mixed: val=10 str=test flag=true")

# =============================================================================
# ADDITIONAL DOCUMENTATION FOR DEVELOPERS
# =============================================================================
#
# IMPACT: This bug prevents using @ patterns with OR alternatives in tuple
#         positions, which is a natural and expected pattern combination.
#
# WORKAROUND: Currently, users must use separate pattern arms instead:
#   BROKEN:   ((5 | 10 | 15) @ val, str): body
#   WORKAROUND: (5, str): let val = 5; body
#               (10, str): let val = 10; body  
#               (15, str): let val = 15; body
#
# PRIORITY: High - this breaks a fundamental pattern combination that users
#           would naturally expect to work.
#
# LOCATION: The bug is in pattern_matching.nim around line 3165 in the
#           tuple processing logic (processTupleLayer function).
#
# =============================================================================