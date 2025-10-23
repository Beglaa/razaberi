import unittest
import ../../pattern_matching
import std/math

suite "Critical Bug: Numeric Type Coercion in Pattern Matching":
  test "integer literal coercion bug - signed vs unsigned":
    # CRITICAL BUG DEMONSTRATION  
    # Bug: Type-safe comparison logic may be too restrictive
    # Location: pattern_matching.nim lines 334-355 (generateTypeSafeComparison)
    
    # The library implements strict type checking to prevent coercion bugs
    # However, this may be overly strict and reject valid patterns
    
    let signed_value: int = 42
    let unsigned_value: uint = 42u
    
    # These should behave differently due to strict type checking
    var signed_matched = false
    var unsigned_matched = false
    
    # Test signed int with int literal (should match)
    let signed_result = match signed_value:
      42: 
        signed_matched = true
        "matched signed"
      _: "no match"
    
    check signed_matched == true
    
    # Test unsigned int with int literal (may fail due to strict typing)
    let unsigned_result = match unsigned_value:
      42:  # This is an int literal, but value is uint
        unsigned_matched = true
        "matched unsigned"
      _: "no match"
    
    # BUG: This might fail due to overly strict type checking
    # The generateTypeSafeComparison only allows SomeSignedInt with int literals
    # But doesn't handle mixed signed/unsigned cases
    if not unsigned_matched:
      check false # BUG CONFIRMED: uint value 42u doesn't match int literal 42
      
    # The question is: should 42u match pattern 42? 
    # Rust allows this, but this library may be too strict
    check unsigned_matched == true

  test "float literal coercion edge case":
    # Test float vs int literal matching
    let float_value: float = 42.0
    let int_value: int = 42
    
    var float_with_int_matched = false
    var int_with_float_matched = false
    
    # Float value with int literal pattern  
    let result1 = match float_value:
      42:  # int literal
        float_with_int_matched = true
        "float matched int"
      _: "no match"
        
    # Int value with float literal pattern
    let result2 = match int_value:
      42.0:  # float literal
        int_with_float_matched = true  
        "int matched float"
      _: "no match"
    
    # Both should fail due to strict type checking - verify with unittest assertions
    check float_with_int_matched == false # Expected: float 42.0 did not match int pattern 42 (strict typing)
    check int_with_float_matched == false # Expected: int 42 did not match float pattern 42.0 (strict typing)

  test "type coercion with variables - the real bug":
    # POTENTIAL BUG: What happens with variable patterns?
    # The strict type checking only applies to literals, not variables
    
    # This test reveals whether the type checking is consistent
    let int_val = 42
    let float_val = 42.0
    
    var int_var_matched = false
    var float_var_matched = false
    
    # Variable binding should work regardless of literal type issues
    let int_result = match int_val:
      x: 
        int_var_matched = true
        x  # Bind to variable
      _: 0
    
    let float_result = match float_val:
      y:
        float_var_matched = true
        y
      _: 0.0
        
    check int_var_matched == true
    check float_var_matched == true
    check int_result == 42
    check float_result == 42.0

  test "numeric literal edge case - zero values":
    # Test edge case: zero values with different types
    let zero_int: int = 0
    let zero_float: float = 0.0
    let zero_uint: uint = 0u
    
    var matched_patterns = 0
    
    # All of these should work with their respective literal types
    let int_zero_result = match zero_int:
      0: 
        matched_patterns += 1
        "int zero"
      _: "no match"
    
    let float_zero_result = match zero_float:
      0.0:
        matched_patterns += 1
        "float zero" 
      _: "no match"
      
    let uint_zero_result = match zero_uint:
      0u:  # uint literal - but parser might treat this as int
        matched_patterns += 1
        "uint zero"
      _: "no match"
    
    check matched_patterns == 3
    
    # Now test the cross-type cases that should fail
    var cross_type_matches = 0
    
    # These should all fail due to strict type checking
    let cross1 = match zero_int:
      0.0: cross_type_matches += 1; "matched"  # int vs float literal
      _: "no match"
      
    let cross2 = match zero_float:  
      0: cross_type_matches += 1; "matched"    # float vs int literal
      _: "no match"
      
    # cross_type_matches should be 0 if type checking works correctly
    check cross_type_matches == 0

  test "potential bounds checking bug in numeric comparisons":
    # Test potential overflow/underflow in numeric patterns
    
    let max_int = int.high
    let min_int = int.low
    
    var overflow_handled = true
    
    try:
      let result = match max_int:
        x and x > 0:
          "positive max"
        _: "other"
      check result == "positive max"
    except:
      overflow_handled = false
      
    check overflow_handled == true
    
    # Test with potentially problematic range checks
    let small_val = 5
    var range_bug_detected = false
    
    try:
      let result = match small_val:
        x and x in 1..10: "in range"
        x and x in 100..1000: "large range"  
        _: "out of range"
      
      if result != "in range":
        range_bug_detected = true
        
    except Exception as e:
      check false # Range check bug occurred
      range_bug_detected = true
      
    check range_bug_detected == false