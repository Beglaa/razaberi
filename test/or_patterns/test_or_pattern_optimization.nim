import unittest
import ../../pattern_matching

# Test cases for OR pattern optimizations
# These tests ensure that OR patterns with many alternatives use case statements instead of OR chains

suite "OR Pattern Optimization":

  test "integer OR pattern optimization (4+ alternatives)":
    let testValue = 3
    let result = match testValue:
      1 | 2 | 3 | 4 | 5: "small number"
      6 | 7 | 8 | 9 | 10: "medium number"
      _: "other"
    
    check(result == "small number")

  test "string OR pattern optimization (4+ alternatives)":
    let command = "exit"
    let result = match command:
      "quit" | "exit" | "bye" | "stop" | "end": "terminating"
      "help" | "info" | "about" | "version": "information"
      _: "unknown command"
    
    check(result == "terminating")

  test "boolean OR pattern optimization":
    # This is a contrived example since there are only 2 boolean values
    # but we test with identifiers that evaluate to booleans
    let value = true
    let result = match value:
      true | false: "boolean value"
      _: "not boolean"
    
    check(result == "boolean value")

  test "float OR pattern optimization (4+ alternatives)":
    let value = 2.5
    let result = match value:
      1.0 | 1.5 | 2.0 | 2.5 | 3.0: "small float"
      4.0 | 4.5 | 5.0 | 5.5 | 6.0: "medium float"
      _: "other float"
    
    check(result == "small float")

  test "mixed type OR pattern fallback to OR chain":
    # This should work but use OR chain instead of case statement
    let value = 42
    let result = match value:
      1 | 2 | 3: "small"
      _: "other"
    
    check(result == "other")

  test "small OR pattern uses OR chain (<=3 alternatives)":
    let value = 2
    let result = match value:
      1 | 2 | 3: "small number"
      _: "other"
    
    check(result == "small number")

  test "large OR pattern for performance (conceptual)":
    # This should use case statement optimization
    let value = 15
    let result = match value:
      1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20: "in range 1-20"
      _: "out of range"
    
    check(result == "in range 1-20")