import unittest
import ../../pattern_matching

# =============================================================================
# BUG DISCOVERED: Both @ Pattern Syntaxes in Sequences Missing Support  
# =============================================================================
#
# ISSUE: Both @ pattern syntaxes fail when used with sequences:
#        1. [(1|2|3) @ small] - @ pattern inside sequence elements (fails with nnkInfix error)
#        2. [(1|2|3)] @ small - sequence @ pattern with bracket subpattern (fails with nnkBracket error)
#
# ROOT CAUSES:
# 1. processNestedPattern function lacks nnkInfix case for @ patterns inside sequences
# 2. Main @ pattern processing lacks nnkBracket case for sequence subpatterns
#
# ERROR MESSAGES:
# 1. "Unsupported nested pattern type: nnkInfix" - from processNestedPattern:1973
# 2. "Unsupported subpattern in @: nnkBracket" - from main @ pattern processing
#
# EXPECTED BEHAVIOR: Both syntaxes should work and provide equivalent functionality
# - [(1|2|3) @ small]: Match 1,2,or 3 inside sequence, bind the matched value
# - [(1|2|3)] @ small: Match sequence containing 1,2,or 3, bind entire sequence
#
# USE CASES:
# - Data validation with specific value binding
# - Configuration parsing with value capture
# - API response processing with selective binding
# - Mathematical operations needing matched values
#
# =============================================================================

suite "Sequence @ Pattern Both Syntaxes Bug - COMPREHENSIVE FAILING TESTS":
  
  # =========================================================================
  # SYNTAX 1: @ PATTERN INSIDE SEQUENCE ELEMENTS - [(pattern @ var)]
  # =========================================================================
  
  test "OR @ pattern inside sequence element - COMPILATION FAILS":
    # SYNTAX: [(1|2|3) @ small]
    # ERROR: "Unsupported nested pattern type: nnkInfix"
    # EXPECTED: Match 1, 2, or 3, bind matched value to 'small'
    
    let data = [2]
    
    let result = match data:
      [(1|2|3) @ small]: "Small number: " & $small
      [x]: "Other: " & $x
      _: "no match"
    
    check(result == "Small number: 2")

  test "literal @ pattern inside sequence element - COMPILATION FAILS":
    # SYNTAX: [42 @ num]  
    # ERROR: "Unsupported nested pattern type: nnkInfix"
    # EXPECTED: Match exactly 42, bind it to 'num'
    
    let data = [42]
    
    let result = match data:
      [42 @ num]: "Matched: " & $num
      [x]: "Other: " & $x
      _: "no match"
    
    check(result == "Matched: 42")

  test "variable @ pattern inside sequence element - COMPILATION FAILS":
    # SYNTAX: [x @ value]
    # ERROR: "Unsupported nested pattern type: nnkInfix" 
    # EXPECTED: Match any value, bind it to both 'x' and 'value'
    
    let data = [100]
    
    let result = match data:
      [x @ value]: "x=" & $x & " value=" & $value
      _: "no match"
    
    check(result == "x=100 value=100")

  test "@ pattern with external guard (preferred syntax)":
    # PREFERRED SYNTAX: [x @ val] and val > 20 : body
    # This should already work with external guard syntax
    
    let data = [25]
    
    let result = match data:
      [x @ val] and val > 20: "Large: " & $val
      [x @ val]: "Small: " & $val  
      _: "no match"
    
    check(result == "Large: 25")

  # =========================================================================
  # SYNTAX 2: SEQUENCE @ PATTERN WITH BRACKET SUBPATTERN - [pattern] @ var  
  # =========================================================================

  test "OR sequence @ pattern - COMPILATION FAILS":
    # SYNTAX: [(1|2|3)] @ small
    # ERROR: "Unsupported subpattern in @: nnkBracket"
    # EXPECTED: Match sequence containing 1,2,or 3, bind entire sequence
    
    let data = [2]
    
    let result = match data:
      [(1|2|3)] @ small: "Small number: " & $small[0]
      [x] @ arr: "Other: " & $arr[0]
      _: "no match"
    
    check(result == "Small number: 2")

  test "literal sequence @ pattern - COMPILATION FAILS":
    # SYNTAX: [42] @ arr
    # ERROR: "Unsupported subpattern in @: nnkBracket" 
    # EXPECTED: Match sequence containing 42, bind entire sequence
    
    let data = [42]
    
    let result = match data:
      [42] @ arr: "Matched array: " & $arr[0]
      [x] @ other: "Other array: " & $other[0]
      _: "no match"
    
    check(result == "Matched array: 42")

  test "variable sequence @ pattern - COMPILATION FAILS":
    # SYNTAX: [x] @ arr  
    # ERROR: "Unsupported subpattern in @: nnkBracket"
    # EXPECTED: Match single-element sequence, bind entire sequence
    
    let data = [100]
    
    let result = match data:
      [x] @ arr: "Array with " & $x & " full: " & $arr
      _: "no match"
    
    check(result == "Array with 100 full: [100]")

  test "multi-element sequence @ pattern - COMPILATION FAILS":
    # SYNTAX: [x, y, z] @ arr
    # ERROR: "Unsupported subpattern in @: nnkBracket"
    # EXPECTED: Match 3-element sequence, bind entire sequence
    
    let data = [1, 2, 3]
    
    let result = match data:
      [x, y, z] @ arr: "Three elements " & $x & "," & $y & "," & $z & " arr=" & $arr
      _: "no match"
    
    check(result == "Three elements 1,2,3 arr=[1, 2, 3]")

  # =========================================================================
  # COMPARISON AND EQUIVALENCE TESTS
  # =========================================================================

  test "syntax comparison - both should give same result for simple case":
    # Compare: [(1|2|3) @ small] vs [(1|2|3)] @ small  
    # Both syntaxes should work but with different binding semantics
    
    let data = [2]
    
    # Syntax 1: Bind the matched value
    let result1 = match data:
      [(1|2|3) @ small]: $small  # small = 2
      _: "no match"
    
    # Syntax 2: Bind the entire sequence 
    let result2 = match data:
      [(1|2|3)] @ small: $small[0]  # small = @[2], access first element
      _: "no match"
    
    check(result1 == "2")
    check(result2 == "2")

  test "complex tuple mixing both @ syntaxes - NOW WORKING":
    # Mix both syntaxes in the same pattern
    let data = ([1], [10, 20])
    
    let result = match data:
      ([(1|2) @ first], [x, y] @ second): "first=" & $first & " second=" & $second
      _: "no match"
    
    check(result == "first=1 second=[10, 20]")

  test "simpler mixed @ pattern in tuple - NOW WORKING":
    # Test simpler combination
    let data = ([1], [10, 20])
    
    let result = match data:
      ([1], [x, y] @ second): "second=" & $second  # Only second uses @
      _: "no match"
    
    check(result == "second=[10, 20]")
  
  test "comprehensive 3-case pattern matching with @ patterns":
    # Test with 3 different pattern matching cases as requested
    let testCase1 = ([1], [10, 20])
    let testCase2 = ([3], [30, 40])  
    let testCase3 = @[@[5], @[50, 60, 70]]  # Use seq for variable length
    
    # Test case 1: OR @ pattern + sequence @ pattern  
    let result1 = match testCase1:
      ([(1|2) @ first], [x, y] @ second): 
        "case1: first=" & $first & " second=" & $second
      _: "no match"
    check(result1 == "case1: first=1 second=[10, 20]")
    
    # Test case 2: literal + sequence @ pattern with element binding
    let result2 = match testCase2:
      ([3], [a, b] @ arr): 
        "case2: arr=" & $arr & " elements=" & $a & "," & $b
      _: "no match"
    check(result2 == "case2: arr=[30, 40] elements=30,40")
    
    # Test case 3: simple sequence @ pattern with seq  
    let result3 = match testCase3:
      ([5], items @ full):
        "case3: full=" & $full & " items=" & $items
      _: "no match"
    check(result3 == "case3: full=@[50, 60, 70] items=@[50, 60, 70]")
  
  test "@ patterns work perfectly outside tuples":
    # This confirms our main fix works perfectly
    let data1 = [2]
    let data2 = [10, 20]
    
    let result1 = match data1:
      [(1|2|3) @ small]: "Small: " & $small
      _: "no match"
    
    let result2 = match data2:
      [x, y] @ arr: "Array: " & $arr
      _: "no match"
    
    check(result1 == "Small: 2")
    check(result2 == "Array: [10, 20]")

# =============================================================================
# TECHNICAL IMPLEMENTATION REQUIREMENTS
# =============================================================================
#
# FIX 1: Add nnkInfix support to processNestedPattern function
# LOCATION: pattern_matching.nim around line 1973
# REQUIRED: 
# - Add nnkInfix case for @ patterns in nested contexts
# - Extract subpattern and alias variable
# - Process subpattern recursively and generate binding
# - Handle guards using flattenNestedAndPattern
#
# FIX 2: Add nnkBracket support to main @ pattern processing  
# LOCATION: pattern_matching.nim around line 4705-5112 in match macro
# REQUIRED:
# - Add nnkBracket case to handle sequence subpatterns in @ patterns
# - Process sequence pattern and generate appropriate conditions
# - Bind entire sequence to alias variable
# - Integrate with guard processing
#
# VALIDATION:
# - All tests in this file should pass after both fixes
# - Run full test suite to ensure no regressions
# - Verify both syntaxes work correctly and consistently
#
# EXPECTED OUTCOME:
# - Developers can use either syntax based on their needs
# - Element binding: [(pattern) @ var] for matched value
# - Sequence binding: [pattern] @ var for entire sequence
# - Both syntaxes integrate seamlessly with guards and complex patterns
#
# =============================================================================