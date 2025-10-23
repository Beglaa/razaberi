import unittest
import tables
import options
import ../../pattern_matching

suite "Basic Type System Tests":
  test "should work with numeric ranges":
    let score = 85
    let result = match score:
      x and x >= 90 : "A grade"
      x and x >= 80 : "B grade"
      x and x >= 70 : "C grade"
      _ : "below C"
    check(result == "B grade")

  test "should work with string length guards":
    let text = "hello"
    let result = match text:
      s and s.len > 10 : "very long"
      s and s.len > 5 : "long"
      s and s.len > 0 : "short"
      _ : "empty"
    check(result == "short")

suite "Distinct Type Tests":
  test "should handle distinct types with guards":
    type UserId = distinct int
    
    let user_id = UserId(123)
    let result = match user_id:
      id and int(id) == 123 : "found user 123"
      id and int(id) == 456 : "found user 456"
      _ : "unknown user"
    check(result == "found user 123")

suite "Enum Type Tests":
  test "should handle enum types with OR patterns":
    type Color = enum
      Red, Green, Blue, Yellow, Orange
    
    let color = Red
    let result = match color:
      Red | Orange | Yellow : "warm color"
      Blue | Green : "cool color"
      _ : "other color"
    check(result == "warm color")

suite "Container Type Tests":
  test "should handle sequence patterns":
    let items = @[1, 2, 3]
    let result = match items:
      [] : "empty"
      [single] : "one item: " & $single
      [a, b] : "two items"
      [a, b, c] : "three items: " & $a & ", " & $b & ", " & $c
      _ : "many items"
    check(result == "three items: 1, 2, 3")

  test "should handle table patterns":
    let data = {"name": "Alice", "age": "30"}.toTable
    let result = match data:
      {"name": name, "age": age} : name & " is " & age & " years old"
      {"name": name} : "name only: " & name
      _ : "no data"
    check(result == "Alice is 30 years old")

suite "Option Type Tests":
  test "should handle Option patterns":
    let opt1 = some(42)
    let result1 = match opt1:
      Some(x) : "value: " & $x
      None() : "no value"
    check(result1 == "value: 42")
    
    let opt2: Option[int] = none(int)
    let result2 = match opt2:
      Some(x) : "value: " & $x
      None() : "no value"
    check(result2 == "no value")

suite "Array vs Sequence Tests":
  test "should handle both arrays and sequences":
    let fixed_array = [1, 2, 3, 4, 5]
    let result1 = match fixed_array:
      [1, 2, 3, 4, 5] : "exact array match"
      _ : "no match"
    check(result1 == "exact array match")
    
    let dynamic_seq = @[1, 2, 3, 4, 5]
    let result2 = match dynamic_seq:
      [1, 2, 3, 4, 5] : "exact seq match"
      _ : "no match"
    check(result2 == "exact seq match")