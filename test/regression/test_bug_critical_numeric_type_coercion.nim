import unittest
import ../../pattern_matching

# ============================================================================
# CRITICAL BUG TEST: Numeric Type Coercion in Pattern Matching
# ============================================================================
# 
# BUG DESCRIPTION:
# The generateTypeSafeComparison function in pattern_matching.nim:334-355 
# implements overly restrictive type safety that prevents valid numeric
# pattern matches between compatible types (e.g., uint vs int literals).
#
# EXPECTED BEHAVIOR:
# Pattern matching should allow natural numeric literals to match compatible
# numeric types, similar to how Rust and other pattern matching systems work.
#
# ACTUAL BEHAVIOR: 
# uint values cannot match int literal patterns, forcing unnatural syntax
# with explicit type suffixes.
#
# CRITICAL IMPACT:
# - Breaks intuitive pattern matching for ports, sizes, counts
# - Forces verbose type-aware patterns instead of natural value patterns
# - Inconsistent with Nim's regular expression type coercion behavior
#
# LOCATION: pattern_matching.nim:334-355 (generateTypeSafeComparison function)

suite "Critical Bug: Numeric Type Coercion in Pattern Matching":

  test "Bug Demo: uint8 values should match int literal patterns":
    let value_uint8: uint8 = 42u8
    
    var matched = false
    
    # This should match but currently fails due to type safety bug
    match value_uint8:
      42: matched = true   # BUG: This fails - uint8 cannot match int literal
      _: matched = false
    
    # Currently fails - this is the BUG
    check matched == true  # This will FAIL, demonstrating the bug
  
  test "Bug Demo: uint16 port numbers should match int literals":
    # Real-world scenario: network port matching
    let port: uint16 = 8080u16
    
    var result = ""
    
    match port:
      80: result = "HTTP"
      443: result = "HTTPS"  
      8080: result = "Dev HTTP"  # BUG: This should match but fails
      _: result = "Unknown"
    
    # Currently fails - port 8080u16 doesn't match literal 8080
    check result == "Dev HTTP"  # This will FAIL, demonstrating the bug
  
  test "Bug Demo: uint32 values should match int literal patterns":
    let count: uint32 = 1000000u32
    
    var category = ""
    
    match count:
      0: category = "Empty"
      1000000: category = "Million"  # BUG: This should match but fails
      _: category = "Other"
    
    # Currently fails - uint32 cannot match int literal  
    check category == "Million"  # This will FAIL, demonstrating the bug
  
  test "Bug Demo: uint64 sizes should match int literal patterns":
    let filesize: uint64 = 1024u64
    
    var description = ""
    
    match filesize:
      0: description = "Empty file"
      1024: description = "1KB file"  # BUG: This should match but fails
      _: description = "Other size"
    
    # Currently fails - uint64 cannot match int literal
    check description == "1KB file"  # This will FAIL, demonstrating the bug
  
  test "Verification: Variable patterns work correctly (bug only affects literals)":
    # This test verifies that variable patterns work fine - the bug is specific to literal matching
    let value_uint8: uint8 = 42u8
    
    var captured_value: uint8 = 0
    
    match value_uint8:
      x: captured_value = x  # Variable patterns work correctly
    
    # This should pass - variable binding works fine
    check captured_value == 42u8
  
  test "Verification: Same type literals work (confirming bug is type-specific)":
    # This test confirms that matching works when types align exactly
    let value_uint8: uint8 = 42u8
    
    var matched = false
    
    match value_uint8:
      42u8: matched = true  # Same type literal - works correctly
      _: matched = false
    
    # This should pass - exact type match works
    check matched == true
  
  test "Bug Demo: Mixed numeric types in OR patterns":
    # Tests that OR patterns with mixed numeric types fail
    let port: uint16 = 80u16
    
    var service = ""
    
    match port:
      80 | 8080: service = "HTTP"  # BUG: uint16 cannot match int literals in OR pattern
      443 | 8443: service = "HTTPS"
      _: service = "Unknown"
    
    # Currently fails - OR pattern with mixed types doesn't work
    check service == "HTTP"  # This will FAIL, demonstrating the bug
  
  test "Rust Behavior: Untyped float literals default to float64":
    # Tests Rust-style behavior where untyped float literals default to float64
    # and cannot match float32 values (maintaining strict type safety)
    let temperature: float32 = 98.6  # float32 value from untyped literal
    
    var status = ""
    
    match temperature:
      98.6: status = "Normal"    # ❌ float32 cannot match float64 literal (98.6 defaults to f64)
      _: status = "Type Safe"    # ✅ This branch should be taken
    
    # This should pass - cross-float-type matching properly fails (Rust behavior)
    check status == "Type Safe"
    
  test "Rust Behavior: Untyped float literals work with correct target type":
    # Tests that untyped float literals work when the target type is compatible
    let temperature: float64 = 98.6  # float64 value from untyped literal
    
    var status = ""
    
    match temperature:
      98.6: status = "Normal"  # ✅ float64 matches float64 literal (both default to f64)
      _: status = "Abnormal"
    
    # This should pass - same float type matching works
    check status == "Normal"
    
  test "Rust Behavior: Typed literals require exact type match":
    # Tests that typed literals require exact type matching (Rust-style strict typing)
    let temperature: float32 = 98.6f32  # Explicitly typed float32 literal
    
    var status = ""
    
    match temperature:
      98.6f32: status = "Normal"  # ✅ Exact type match works
      _: status = "Abnormal"
    
    # This should pass - exact typed literal match
    check status == "Normal"
    
  test "Rust Behavior: Cross-type float matching fails correctly":
    # Tests that different float types don't match (maintaining type safety)
    let temperature: float64 = 98.6
    
    var status = ""
    
    match temperature:
      98.6f32: status = "Normal"  # ❌ Should fail - float64 vs float32 literal
      _: status = "Type Safe"
    
    # This should pass - cross-type matching properly fails
    check status == "Type Safe"
  
  test "Bug Impact: Real-world configuration matching":
    # Real-world scenario showing practical impact
    type Config = object
      port: uint16
      maxConnections: uint32
      bufferSize: uint64
    
    let config = Config(port: 3000u16, maxConnections: 100u32, bufferSize: 8192u64)
    
    var isValid = false
    
    # Natural pattern matching that should work but fails due to bug
    match (config.port, config.maxConnections, config.bufferSize):
      (3000, 100, 8192): isValid = true  # BUG: Tuple with mixed types fails
      _: isValid = false
    
    # Currently fails - mixed numeric types in tuples don't match
    check isValid == true  # This will FAIL, demonstrating the bug

# ============================================================================
# ADDITIONAL EDGE CASE TESTS FOR COMPREHENSIVE BUG COVERAGE
# ============================================================================

  test "Edge Case: Zero values across numeric types":
    # Tests zero value matching across different numeric types
    let zero_uint: uint = 0u
    let zero_uint8: uint8 = 0u8
    let zero_uint16: uint16 = 0u16
    
    var results: seq[bool] = @[]
    
    # All of these should match zero but currently fail
    match zero_uint:
      0: results.add(true)
      _: results.add(false)
    
    match zero_uint8:
      0: results.add(true)
      _: results.add(false)
    
    match zero_uint16:
      0: results.add(true)
      _: results.add(false)
    
    # All should be true but will be false due to bug
    check results == @[true, true, true]  # This will FAIL
  
  test "Edge Case: Maximum value edge cases":
    # Tests edge cases with maximum values for different types
    let max_uint8: uint8 = 255u8
    
    var matched = false
    
    match max_uint8:
      255: matched = true  # BUG: Should match but fails
      _: matched = false
    
    check matched == true  # This will FAIL
  
  test "Edge Case: Pattern matching with arithmetic expressions":
    # Tests if the bug affects computed values
    let computed: uint = uint(42 + 58)  # Results in 100u
    
    var result = ""
    
    match computed:
      100: result = "Century"  # BUG: Should match but fails
      _: result = "Other"
    
    check result == "Century"  # This will FAIL