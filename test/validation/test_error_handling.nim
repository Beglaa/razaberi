import unittest
import tables
import options
import ../../pattern_matching

suite "Error Handling Tests":
  test "should raise MatchError on non-exhaustive patterns":
    expect MatchError:
      discard match 99:
        1 : "one"
        2 : "two"
        _ : raise newException(MatchError, "Non-exhaustive pattern test")
  
  test "should handle empty input gracefully":
    let empty_str = ""
    let result = match empty_str:
      "" : "empty string"
      _ : "not empty"
    check(result == "empty string")

suite "Pattern Evaluation Order Tests":
  test "should evaluate patterns in order (first match wins)":
    let result1 = match 10:
      x and x > 5 : "first"
      10 : "second"
      _ : "third"
    check(result1 == "first")
    
    let result2 = match 3:
      x and x > 5 : "first"
      3 : "second"
      _ : "third"
    check(result2 == "second")

  test "should match wildcard when it's the last pattern":
    let result = match 5:
      10 : "ten"
      _ : "wildcard"
    check(result == "wildcard")

suite "Error Boundary Tests":
  test "should handle malformed table access patterns gracefully":
    let incomplete = {"a": "value"}.toTable
    # This should not match when required key is missing
    let result = match incomplete:
      {"a": a, "missing": missing} : "should not match"
      {"a": a} : "partial match: " & a
      _ : "no match"
    check(result == "partial match: value")

  test "should handle sequence patterns requiring more elements than available":
    let short_seq = @[1, 2]
    let result = match short_seq:
      [a, b, c] : "three elements"
      [a, b] : "two elements: " & $a & ", " & $b
      _ : "other pattern"
    check(result == "two elements: 1, 2")

  test "should handle spread patterns with insufficient elements":
    let tiny = @[42]
    let result = match tiny:
      [first, *middle, last] : "has middle"
      [single] : "single element: " & $single
      [] : "empty"
      _ : "other"
    check(result == "single element: 42")

  test "should handle table pattern with non-existent keys":
    let basic = {"x": "10"}.toTable
    let result = match basic:
      {"x": x, "y": y, "z": z} : "all three"
      {"x": x, "y": y} : "x and y"
      {"x": x} : "just x: " & x
      _ : "no match"
    check(result == "just x: 10")

  test "should handle empty pattern matching edge cases":
    let empty_seq: seq[string] = @[]
    let result = match empty_seq:
      [head, *tail] : "not empty"
      [] : "confirmed empty"
      _ : "other"
    check(result == "confirmed empty")

  test "should handle complex nested access with missing data":
    let partial_data = {"user": {"name": "Bob"}.toTable}.toTable
    let result = match partial_data:
      {"user": user_info} : "user data available with " & $user_info.len & " fields"
      _ : "no user"
    check(result == "user data available with 1 fields")

suite "Pattern Evaluation Order Edge Cases":
  test "should respect pattern evaluation order with guards":
    let val = 15
    let result = match val:
      x and x > 10 : "first match"
      15 : "literal match"
      x and x > 12 : "second match"
      _ : "default"
    check(result == "first match")

  test "should handle overlapping patterns correctly":
    let text = "test"
    let result = match text:
      s and s.len == 4 : "length 4"
      "test" : "literal test"
      _ : "other"
    check(result == "length 4")

  test "should handle guard priority over literal matches":
    let number = 42
    let result = match number:
      x and x > 40 : "in range"
      42 : "exact match"
      _ : "other"
    check(result == "in range")