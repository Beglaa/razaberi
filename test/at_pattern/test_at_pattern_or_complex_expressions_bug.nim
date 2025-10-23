import unittest
import ../../pattern_matching

# ============================================================================
# BUG TEST: @ Pattern with OR Patterns Compilation Failure
# ============================================================================
# 
# DISCOVERED BUG: The @ pattern implementation fails to compile when the left
# operand of @ contains OR patterns or other complex expressions.
#
# LOCATION: Lines 4015-4140 in pattern_matching.nim - processTupleLayer function
# ERROR: "Unsupported @ sub-pattern in nested tuple" at line 4140
#
# EXPECTED BEHAVIOR: @ patterns should work with any valid pattern expression
# on the left side, including OR patterns, nested patterns, and complex expressions.
#
# This comprehensive test demonstrates multiple scenarios where this bug occurs.

suite "@ Pattern with OR Patterns Bug":

  test "Simple tuple @ pattern with OR on left side - SHOULD WORK":
    let data = (10, "test")
    
    # This should bind 'val' to 10 and 'str' to "test"
    # BUT currently fails with "Unsupported @ sub-pattern in nested tuple"
    let result = match data:
      ((5 | 10 | 15) @ val, str): "matched val: " & $val & " str: " & str
      _: "no match"
    
    check result == "matched val: 10 str: test"

  test "Complex OR pattern with multiple alternatives @ binding":
    let data = (42, "hello")
    
    # OR pattern with many alternatives
    let result = match data:
      ((1|5|10|15|20|25|30|35|40|42|45|50) @ number, text): 
        "Found number " & $number & " with text: " & text
      _: "no match"
    
    check result == "Found number 42 with text: hello"

  test "Nested tuple with @ OR pattern":
    let data = ((3, "inner"), "outer")
    
    # @ pattern with OR in nested tuple context
    let result = match data:
      (((1 | 2 | 3) @ innerNum, innerStr), outerStr):
        "inner: " & $innerNum & ":" & innerStr & ", outer: " & outerStr
      _: "no match"
    
    check result == "inner: 3:inner, outer: outer"

  test "@ pattern with chained OR patterns":
    type Color = enum Red, Green, Blue, Yellow, Purple
    let data = (Red, 100)
    
    # Chained OR patterns with @ binding
    let result = match data:
      ((Red | Green | Blue) @ color, intensity):
        "Primary color: " & $color & " with intensity " & $intensity
      ((Yellow | Purple) @ color, intensity):
        "Secondary color: " & $color & " with intensity " & $intensity  
      _: "unknown color"
    
    check result == "Primary color: Red with intensity 100"

  test "@ pattern with OR containing literals and variables":
    let data = (7, "mixed")
    
    # Mix of literals and potential variable bindings in OR
    let result = match data:
      ((1 | 5 | 7 | 10) @ num, content):
        "Recognized number: " & $num & ", content: " & content
      _: "unrecognized"
    
    check result == "Recognized number: 7, content: mixed"

  test "Triple nested @ pattern with OR expressions":
    let data = (((2, "level3"), "level2"), "level1")
    
    # Deep nesting with @ OR patterns at different levels
    let result = match data:
      ((((1 | 2 | 3) @ deep, deepStr) @ mid, midStr), topStr):
        "deep: " & $deep & ":" & deepStr & ", mid level, top: " & topStr
      _: "no match"
    
    check result == "deep: 2:level3, mid level, top: level1"

  test "@ pattern with OR in sequence context":
    let data = [(5, "first"), (10, "second")]
    
    # @ OR pattern within sequence destructuring
    let result = match data:
      [((5 | 10 | 15) @ first, firstStr), ((5 | 10 | 15) @ second, secondStr)]:
        "first: " & $first & ":" & firstStr & ", second: " & $second & ":" & secondStr
      _: "no match"
    
    check result == "first: 5:first, second: 10:second"

  test "@ pattern with boolean OR expressions":
    let data = (true, "boolean_test")
    
    # Boolean literals in OR with @ binding
    let result = match data:
      ((true | false) @ flag, description):
        "Boolean flag: " & $flag & " - " & description
      _: "no match"
        
    check result == "Boolean flag: true - boolean_test"

  test "@ pattern with string literals OR":
    let data = ("hello", 123)
    
    # String literals in OR pattern with @ binding  
    let result = match data:
      (("hello" | "world" | "test") @ greeting, number):
        "Greeting: " & greeting & ", number: " & $number
      _: "no match"
    
    check result == "Greeting: hello, number: 123"

  test "Complex @ pattern with mixed types in OR":
    let data = (42, "integer")
    
    # This tests OR patterns containing different literal types
    # Note: In Nim, this might be a type compatibility challenge
    let result = match data:
      ((42 | 100) @ value, desc):  # Keep same type for now
        "Integer value: " & $value & " - " & desc
      _: "no match"
    
    check result == "Integer value: 42 - integer"

  test "@ pattern with parenthesized OR expressions":
    let data = (8, "grouped")
    
    # Explicitly grouped OR expressions with @ binding
    let result = match data:
      ((5 | (6 | 7) | 8) @ grouped_num, text):
        "Grouped number: " & $grouped_num & " with " & text
      _: "no match"
    
    check result == "Grouped number: 8 with grouped"

# ============================================================================
# Additional Edge Cases for @ OR Pattern Bug
# ============================================================================

  test "@ pattern with OR in guard context":
    let data = (15, "guarded")
    
    # @ OR pattern combined with guard expression
    let result = match data:
      ((10 | 15 | 20) @ val, text) and val > 12:
        "Large value: " & $val & " - " & text
      _: "small or no match"
    
    check result == "Large value: 15 - guarded"

  test "Multiple @ OR patterns in single match":
    let data = (5, 10, "double")
    
    # Multiple @ OR patterns in the same match expression  
    let result = match data:
      ((1 | 5 | 9) @ first, (8 | 10 | 12) @ second, desc):
        "first: " & $first & ", second: " & $second & " - " & desc
      _: "no match"
    
    check result == "first: 5, second: 10 - double"

# ============================================================================
# COMPILATION TEST SECTION
# ============================================================================
# These tests specifically verify that the patterns compile without errors

suite "@ OR Pattern Compilation Tests":

  test "Compilation test - simple @ OR pattern":
    # This test ensures the pattern compiles without "Unsupported @ sub-pattern" error
    let compiles = compiles(
      block:
        let data = (10, "test")
        discard match data:
          ((5 | 10) @ val, str): "ok"
          _: "fail"
    )
    check compiles == true

  test "Compilation test - nested @ OR pattern":
    # Test compilation of nested @ OR patterns
    let compiles = compiles(
      block:
        let data = ((1, "inner"), "outer") 
        discard match data:
          (((1 | 2) @ inner, str1), str2): "ok"
          _: "fail"
    )
    check compiles == true

  test "Compilation test - complex @ OR with many alternatives":
    # Test compilation with many OR alternatives
    let compiles = compiles(
      block:
        let data = (42, "test")
        discard match data:
          ((1|2|3|4|5|10|15|20|25|30|35|40|42|45|50) @ num, str): "ok"  
          _: "fail"
    )
    check compiles == true