import ../../pattern_matching
import std/unittest

# BUG DISCOVERED: Numeric Type Coercion Bug in Pattern Matching
#
# BUG DESCRIPTION:
# The pattern matching library incorrectly performs implicit type coercion
# when matching numeric literal patterns against values of different numeric types.
# This violates type safety and can lead to unexpected behavior.
#
# FAILING CASE: 
# - Value: 42.0 (float)  
# - Pattern: 42 (integer literal)
# - Expected: Should NOT match (different types)
# - Actual: Matches incorrectly due to implicit coercion
#
# ROOT CAUSE: 
# The pattern matching library's literal comparison logic doesn't properly
# distinguish between different numeric types. It appears to use Nim's
# implicit conversion rules rather than strict type matching.
#
# This is a type safety bug that could cause runtime errors or unexpected
# behavior in applications that rely on strict type matching.

suite "Numeric Type Coercion Bug":
  
  test "float value should NOT match integer pattern - BUG":
    let float_val: float = 42.0
    
    # This test will FAIL due to the bug
    # The integer pattern 42 should NOT match float value 42.0
    let result = match float_val:
      42: "integer match"     # BUG: This incorrectly matches
      42.0: "float match"     # This should be the correct match
      _: "no match"
    
    # This will fail because the bug causes integer pattern to match first
    check result == "float match"
  
  test "int value should NOT match float pattern - BUG":
    let int_val: int = 42
    
    # Test the reverse case
    let result = match int_val:
      42.0: "float match"     # BUG: This might incorrectly match int
      42: "integer match"     # This should be the correct match
      _: "no match"
    
    # This tests if the bug affects both directions
    check result == "integer match"
  
  test "different integer types should be distinct - BUG":
    let int8_val: int8 = 100
    let int16_val: int16 = 100
    let int32_val: int32 = 100
    
    # Test if different integer types are properly distinguished
    let result1 = match int8_val:
      100i8: "int8 match"     # Should only match int8 literal
      100i16: "int16 match"   # Should NOT match
      100: "int match"        # Should NOT match  
      _: "no match"
    
    let result2 = match int16_val:
      100i16: "int16 match"   # Should only match int16 literal
      100i8: "int8 match"     # Should NOT match
      100: "int match"        # Should NOT match
      _: "no match"
    
    let result3 = match int32_val:
      100i32: "int32 match"   # Should match int32 literal  
      100: "int match"        # Regular int literal - should this match?
      _: "no match"
    
    check result1 == "int8 match"
    check result2 == "int16 match"  
    check result3 == "int32 match"
  
  test "float subtypes should be distinct - BUG":
    let float32_val: float32 = 3.14
    let float64_val: float64 = 3.14
    
    # Test if float32 vs float64 are properly distinguished
    let result1 = match float32_val:
      3.14'f32: "float32 match"
      3.14: "float match"       # Generic float literal
      _: "no match"
    
    let result2 = match float64_val:
      3.14: "float64 match"     # Should match float64 
      3.14'f32: "float32 match" # Should NOT match float32
      _: "no match"
    
    check result1 == "float32 match"
    check result2 == "float64 match"
  
  test "type coercion with guards should maintain type safety - BUG":
    let mixed_float: float = 25.5
    
    # Test if type coercion bug affects guard expressions
    let result = match mixed_float:
      x and x == 25: "int comparison"    # Should NOT match (different types)
      x and x == 25.5: "float comparison" # Should match
      _: "no match"
    
    check result == "float comparison"
  
  test "complex numeric types (rationals, complex) edge case":
    # This tests if the library handles edge cases correctly
    # These might expose additional type coercion issues
    let big_int = 999999999999999999'i64
    let small_int = 42'i32
    
    let result1 = match big_int:
      999999999999999999'i64: "big int match"
      999999999999999999: "generic int match"
      _: "no match"
    
    let result2 = match small_int:
      42'i32: "small int32 match" 
      42: "generic int match"
      _: "no match"
    
    check result1 == "big int match"
    check result2 == "small int32 match"
  
  test "zero values across types should be distinct - BUG":
    # Zero is a common edge case that might trigger coercion bugs
    let zero_int: int = 0
    let zero_float: float = 0.0
    let zero_uint: uint = 0
    
    let result1 = match zero_int:
      0: "int zero"
      0.0: "float zero"     # Should NOT match  
      0u: "uint zero"       # Should NOT match
      _: "no match"
    
    let result2 = match zero_float:
      0.0: "float zero"
      0: "int zero"         # Should NOT match
      _: "no match"
    
    let result3 = match zero_uint:
      0u: "uint zero" 
      0: "int zero"         # Should NOT match
      _: "no match"
    
    check result1 == "int zero"
    check result2 == "float zero"
    check result3 == "uint zero"