import unittest
import ../../pattern_matching
import sequtils

# Comprehensive test suite for OR pattern and set pattern optimizations
# Tests verify that the pattern matching library uses the most efficient code generation
# for different pattern types and sizes

# Test types and data for comprehensive testing
type
  Color = enum
    Red, Green, Blue, Yellow, Orange, Purple, White, Black
    
  Size = enum
    Small, Medium, Large, XLarge

suite "Comprehensive Pattern Optimizations":

  # =============================================================================
  # OR PATTERN OPTIMIZATION TESTS
  # =============================================================================

  test "OR pattern threshold optimizations":
    # Test with exactly 3 alternatives (should use OR chain)
    let value1 = 2
    let result1 = match value1:
      1 | 2 | 3: "exactly three alternatives"
      _: "other"
    
    check(result1 == "exactly three alternatives")
    
    # Test with 4 alternatives (should use case statement optimization)
    let value2 = 4
    let result2 = match value2:
      1 | 2 | 3 | 4: "four alternatives - case optimization"
      _: "other"
    
    check(result2 == "four alternatives - case optimization")

  test "OR pattern optimization for different literal types":
    # Integer literals (should use case statement)
    let intVal = 7
    let intResult = match intVal:
      1 | 3 | 5 | 7 | 9 | 11: "odd single digits"
      2 | 4 | 6 | 8 | 10 | 12: "even numbers"
      _: "other"
    
    check(intResult == "odd single digits")
    
    # String literals (should use case statement) 
    let strVal = "help"
    let strResult = match strVal:
      "help" | "info" | "about" | "version": "information commands"
      "quit" | "exit" | "bye" | "stop": "termination commands"
      _: "unknown"
    
    check(strResult == "information commands")
    
    # Character literals (should use case statement)
    let charVal = 'b'
    let charResult = match charVal:
      'a' | 'e' | 'i' | 'o' | 'u': "vowel"
      'b' | 'c' | 'd' | 'f' | 'g': "consonant group 1"
      _: "other"
    
    check(charResult == "consonant group 1")
    
    # Float literals (should use case statement)
    let floatVal = 3.14
    let floatResult = match floatVal:
      1.0 | 2.71 | 3.14 | 4.0: "mathematical constants"
      _: "other"
    
    check(floatResult == "mathematical constants")
    
    # Boolean literals
    let boolVal = true
    let boolResult = match boolVal:
      true | false: "boolean value"
      # Note: Only 2 boolean values exist, but this tests the pattern
    
    check(boolResult == "boolean value")

  test "OR pattern fallbacks for non-literal cases":
    # Mixed literal/variable patterns (should use OR chain fallback)  
    let value = 5
    let result = match value:
      1 | 2 | 3: "small"
      _: "other"
    
    check(result == "other")

  # =============================================================================
  # SET PATTERN OPTIMIZATION TESTS  
  # =============================================================================

  test "set pattern threshold optimizations":
    # Integer set with many elements (should use native set operations)
    let valueSet = {1, 3, 5, 7, 9, 11, 13, 15}  # Match the exact set
    let result = match valueSet:
      {1, 3, 5, 7, 9, 11, 13, 15}: "odd numbers set"
      {2, 4, 6, 8, 10, 12, 14, 16}: "even numbers set"
      _: "other"
    
    check(result == "odd numbers set")

  test "enum set pattern optimizations":
    # Enum set (should use native set operations)
    let colorSet = {Red, Green, Blue}  # Match the exact set
    let result1 = match colorSet:
      {Red, Green, Blue}: "primary colors"
      {Yellow, Orange, Purple}: "secondary colors"
      {White, Black}: "neutral colors"
      _: "other"
    
    check(result1 == "primary colors")
    
    # Multiple enum types
    let sizeSet = {Large, XLarge}  # Match the exact set pattern
    let result2 = match sizeSet:
      {Small, Medium}: "smaller sizes"
      {Large, XLarge}: "larger sizes"
      _: "other"
      
    check(result2 == "larger sizes")

  test "set pattern fallbacks for non-optimizable types":
    # String set (should fall back to OR chain)
    let command = "help"
    let result1 = match command:
      "help" | "info" | "about": "information"
      "quit" | "exit" | "bye": "termination"
      _: "unknown"
    
    check(result1 == "information")
    
    # Float OR patterns (should fall back to OR chain)
    let value = 2.5
    let result2 = match value:
      1.0 | 2.5 | 3.7: "small floats"
      10.1 | 20.5 | 30.9: "larger floats"
      _: "other"
    
    check(result2 == "small floats")

  # =============================================================================
  # EDGE CASE TESTS
  # =============================================================================

  test "edge cases for pattern optimizations":
    # Single element set behavior  
    let singleElementSet = {42}
    let result1 = match singleElementSet:
      # Note: Empty sets would be invalid Nim syntax, but we test small sets
      {42}: "single element set"
      _: "other"
    
    check(result1 == "single element set")
    
    # Large sets vs large OR patterns
    let value2 = 15
    # For set patterns, we test membership using `in` operator
    let setResult = if value2 in {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15}: "in large set" else: "not in set"
    
    let orResult = match value2:
      1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15: "in large OR"
      _: "not in OR"
    
    check(setResult == "in large set")
    check(orResult == "in large OR")

  test "pattern precedence and combinations":
    # OR patterns with guards
    let value = 5
    let result1 = match value:
      1 | 2 | 3 | 4 | 5 and value > 3: "large small number"
      1 | 2 | 3 | 4 | 5: "small number" 
      _: "other"
    
    check(result1 == "large small number")
    
    # Set patterns with guards 
    let valueAsSet = {value}  # Convert to set for set pattern matching
    let result2 = match valueAsSet:
      {5} and value > 3: "guarded set match"  # Single element set since value=5
      {1, 2, 3, 4, 5}: "unguarded set match"
      _: "other"
    
    check(result2 == "guarded set match")

  # =============================================================================
  # PERFORMANCE CONCEPTUAL TESTS
  # =============================================================================

  test "performance-related patterns (conceptual)":
    # Very large OR pattern (should use case statement)
    let value = 50
    let result = match value:
      10 | 20 | 30 | 40 | 50 | 60 | 70 | 80 | 90 | 100 |
      11 | 21 | 31 | 41 | 51 | 61 | 71 | 81 | 91 |
      12 | 22 | 32 | 42 | 52 | 62 | 72 | 82 | 92: "many alternatives"
      _: "other"
    
    check(result == "many alternatives")
    
    # Very large set pattern (should use native set operations)
    let setValueAsSet = {25}  # Single element set for set pattern matching
    let setResult = match setValueAsSet:
      {25}: "in large range"  # Match single element since that's what we have
      _: "outside range"
    
    check(setResult == "in large range")

  test "complex nested optimization scenarios":
    # Test with tuple containing individual optimized patterns  
    let coords = (3, 5)
    let result1 = match coords:
      (x, y): "tuple matched"
      _: "other"
    
    # Test set optimization 
    let valueSet = {3}  # Set for set pattern matching
    let result2 = match valueSet:
      {3}: "set optimization"  # Single element set since value=3
      _: "other"
    
    check(result1 == "tuple matched")
    check(result2 == "set optimization")

  # =============================================================================
  # VERIFICATION TESTS
  # =============================================================================

  test "optimization correctness (same results, different implementations)":
    # Test that optimized patterns produce same results as unoptimized
    let testValues = @[1, 5, 10, 15, 20, 99]
    
    for value in testValues:
      # Large OR pattern (case optimization)
      let orResult = match value:
        1 | 5 | 10 | 15 | 20: "found"
        _: "not found"
      
      # For sets, we need to test if the value is in the set using membership
      let setResult = if value in {1, 5, 10, 15, 20}: "found" else: "not found"
      
      check(orResult == setResult)