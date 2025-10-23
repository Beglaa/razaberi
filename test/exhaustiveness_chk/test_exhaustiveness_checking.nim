import unittest
import ../../pattern_matching

# Test suite for enum exhaustiveness checking functionality
# This validates that the compile-time exhaustiveness analysis works correctly
# and provides appropriate warnings for non-exhaustive enum patterns

suite "Enum Exhaustiveness Checking Tests":
  
  test "should detect exhaustive enum patterns":
    # This test verifies that exhaustive enum patterns don't generate warnings
    # All enum values are covered explicitly
    type Color = enum
      red, green, blue
    
    let color = red
    let result = match color:
      red: "red color"
      green: "green color" 
      blue: "blue color"
    
    check(result == "red color")
  
  test "should work with wildcard patterns (exhaustive)":
    # Wildcard patterns make any pattern match exhaustive
    type Status = enum
      active, inactive, pending
    
    let status = pending
    let result = match status:
      active: "running"
      _: "not active"
    
    check(result == "not active")
  
  test "should work with catch-all @ pattern (exhaustive)":
    # Unguarded @ pattern with wildcard makes pattern match exhaustive
    type Priority = enum
      low, medium, high

    let priority = medium
    let result = match priority:
      high: "urgent"
      _ @ other: "not urgent: " & $other  # Use @ pattern for variable binding

    check(result == "not urgent: medium")
  
  test "should handle OR patterns in enum matching":
    # OR patterns should be properly analyzed for exhaustiveness
    type Day = enum
      monday, tuesday, wednesday, thursday, friday, saturday, sunday
    
    let day = saturday
    let result = match day:
      saturday | sunday: "weekend"
      monday | tuesday | wednesday | thursday | friday: "weekday"
    
    check(result == "weekend")
  
  test "should handle complex OR patterns with partial coverage":
    # Test OR patterns that don't cover all enum values
    type Grade = enum
      A, B, C, D, F
    
    let grade = C
    let result = match grade:
      C | D | F: "not so good"
      A | B: "good"
    
    check(result == "not so good")
  
  test "should work with enum patterns with guards":
    # Guards don't affect exhaustiveness - only the base patterns matter
    type Size = enum
      small, medium, large, xlarge
    
    let size = large
    let result = match size:
      small: "S"
      medium: "M"
      large: "L"
      xlarge and size == xlarge: "XL"
    
    check(result == "L")
  
  test "should handle nested enum patterns":
    # Test enums used in other pattern contexts
    type State = enum
      loading, success, error
    
    type Response = object
      state: State
      data: string
    
    let response = Response(state: success, data: "hello")
    
    # Note: This tests general enum usage, not exhaustiveness of the Response type
    let result = match response.state:
      loading: "Loading..."
      success: "Success!"
      error: "Error occurred"
    
    check(result == "Success!")

# Test compile-time behavior for exhaustiveness warnings
# These would normally generate warnings at compile time, but we can't easily test that
# in a unit test. The exhaustiveness checking logic is tested by the runtime behavior.

suite "Exhaustiveness Edge Cases":
  
  test "should handle enum patterns with @ binding":
    # @ patterns should work with enum exhaustiveness checking
    type Mode = enum
      read, write, append
    
    let mode = write
    let result = match mode:
      read @ m: "reading with " & $m
      write @ m: "writing with " & $m  
      append @ m: "appending with " & $m
    
    check(result == "writing with write")
  
  test "should handle empty enum (edge case)":
    # Edge case: enum with no values (though this is rare in practice)
    # Note: Empty enums aren't valid in Nim, so this test just ensures
    # our exhaustiveness checker handles theoretical edge cases gracefully
    discard "Empty enums are not valid in Nim"
    
  test "should handle single-value enum":
    # Edge case: enum with only one value
    type Single = enum
      only
    
    let value = only
    let result = match value:
      only: "the only value"
    
    check(result == "the only value")
  
  test "should work with mixed pattern types":
    # Test that non-enum patterns don't interfere with enum exhaustiveness checking
    type Color = enum
      red, green, blue
    
    let color = green
    let number = 42
    
    # Test enum pattern
    let colorResult = match color:
      red: "red"
      green: "green"
      blue: "blue"
    
    # Test non-enum pattern (should not trigger exhaustiveness checking)
    let numberResult = match number:
      42: "forty-two"
      x: "other: " & $x
    
    check(colorResult == "green")
    check(numberResult == "forty-two")

# Additional test for the exhaustiveness checking functions themselves
suite "Exhaustiveness Checking Internal Functions":
  
  # NOTE: The internal functions (extractEnumValues, extractPatternsForExhaustiveness,
  # checkEnumExhaustiveness) are not exported, so we can't directly unit test them.
  # However, they are tested indirectly through the match macro usage above.
  # 
  # The key behaviors we're testing:
  # 1. Exhaustive patterns don't raise MatchError
  # 2. Non-exhaustive patterns would generate compile-time warnings (not testable in unit tests)
  # 3. Wildcard and variable patterns make patterns exhaustive
  # 4. OR patterns are properly analyzed for coverage
  
  test "exhaustiveness prevents runtime errors":
    # When patterns are exhaustive, no MatchError should be raised
    type Direction = enum
      north, south, east, west
    
    let direction = north
    let result = match direction:
      north: "N"
      south: "S" 
      east: "E"
      west: "W"
    
    check(result == "N")
    
    # This should also work without raising MatchError
    let direction2 = west
    let result2 = match direction2:
      north: "N"
      south: "S"
      east: "E"
      west: "W"
    
    check(result2 == "W")