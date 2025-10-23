import unittest
import tables
import options
import ../../pattern_matching

suite "Option Type Pattern Tests":
  test "should match Some(value) pattern":
    let opt1 = some(42)
    let result1 = match opt1:
      Some(x) : "Found: " & $x
      None() : "Empty"
    check(result1 == "Found: 42")
    
    let opt2 = some("hello")
    let result2 = match opt2:
      Some(s) : "String: " & s
      None() : "Empty"
    check(result2 == "String: hello")

  test "should match None() pattern":
    let opt1: Option[int] = none(int)
    let result1 = match opt1:
      Some(x) : "Found: " & $x
      None() : "Empty"
    check(result1 == "Empty")
    
    let opt2: Option[string] = none(string)
    let result2 = match opt2:
      Some(s) : "String: " & s
      None() : "Empty"
    check(result2 == "Empty")

  test "should handle Option patterns with guards":
    let opt: Option[int] = some(15)
    let result = match opt:
      Some(x) and x > 10 : "Big number: " & $x
      Some(x) : "Small number: " & $x
      None() : "No value"
    check(result == "Big number: 15")

  test "should handle Option patterns with different types":
    type Person = object
      name: string
      age: int
    
    let person_opt = some(Person(name: "Alice", age: 30))
    let result = match person_opt:
      Some(person) : person.name & " is " & $person.age & " years old"
      None() : "No person"
    check(result == "Alice is 30 years old")

  test "should handle Option type checking":
    let opt1 = some(42)
    let result1 = match opt1:
      Some(x) and x == 42 : "Special number"
      Some(x) : "Other number: " & $x
      None() : "No value"
    check(result1 == "Special number")

  test "should handle nested Option patterns":
    let nested = some(some(42))
    let result = match nested:
      Some(inner) and inner.isSome : "Nested value: " & $inner.get
      Some(inner) : "Inner None"
      None() : "Outer None"
    check(result == "Nested value: 42")

    let partial = some(none(int))
    let result2 = match partial:
      Some(inner) and inner.isSome : "Nested value: " & $inner.get
      Some(inner) : "Inner None"
      None() : "Outer None"
    check(result2 == "Inner None")

  test "someTo should support type patterns (x is Type)":
    # Test 1: Basic int type pattern
    let opt1 = some(42)
    var matched1 = false
    if opt1.someTo(x is int):
      check(x == 42)
      check(typeof(x) is int)
      matched1 = true
    check(matched1)  # someTo(x is int) should match Some(42)

    # Test 2: String type pattern
    let opt2 = some("hello")
    var matched2 = false
    if opt2.someTo(s is string):
      check(s == "hello")
      check(typeof(s) is string)
      matched2 = true
    check(matched2)  # someTo(s is string) should match Some("hello")

    # Test 3: Type pattern with None should not match
    let opt3: Option[int] = none(int)
    var matched3 = false
    if opt3.someTo(x is int):
      matched3 = true
    check(not matched3)  # someTo(x is int) should not match None

  test "someTo should support combined type patterns with guards":
    # Test 1: Type pattern + value guard
    let opt1 = some(50)
    var matched1 = false
    if opt1.someTo(x is int and x > 10):
      check(x == 50)
      check(x > 10)
      matched1 = true
    check(matched1)  # someTo(x is int and x > 10) should match Some(50)

    # Test 2: Type pattern + value guard that fails
    let opt2 = some(5)
    var matched2 = false
    if opt2.someTo(x is int and x > 10):
      matched2 = true
    check(not matched2)  # someTo(x is int and x > 10) should not match Some(5)

    # Test 3: String type pattern + length guard
    let opt3 = some("hello world")
    var matched3 = false
    if opt3.someTo(s is string and s.len > 5):
      check(s == "hello world")
      check(s.len > 5)
      matched3 = true
    check(matched3)  # someTo(s is string and s.len > 5) should match

  test "someTo type patterns should work with compile-time optimization":
    # When Option[T] type matches the type pattern, Nim's `is` operator
    # optimizes the check at compile-time

    # Test 1: Exact type match - compile-time optimized
    let opt1: Option[int] = some(100)
    var matched1 = false
    if opt1.someTo(x is int):
      check(x == 100)
      matched1 = true
    check(matched1)  # Compile-time optimized type check should work

    # Test 2: Type mismatch detection at runtime/compile-time
    let opt2: Option[string] = some("test")
    var matched2 = false
    if opt2.someTo(s is string):
      check(s == "test")
      matched2 = true
    check(matched2)  # Type pattern should match correct type

  test "someTo should handle complex type patterns":
    # Test 1: Multiple guards with type pattern
    let opt1 = some(25)
    var matched1 = false
    if opt1.someTo(x is int and x > 20 and x < 30):
      check(x == 25)
      matched1 = true
    check(matched1)  # Complex guards with type pattern should work

    # Test 2: Type pattern in else-if chain
    let opt2: Option[int] = some(15)
    var result2 = ""
    if opt2.someTo(x is int and x > 50):
      result2 = "big"
    elif opt2.someTo(x is int and x > 10):
      result2 = "medium"
    else:
      result2 = "small"
    check(result2 == "medium")  # Type patterns in elif should work

    # Test 3: Type pattern with range check
    let opt3 = some(7)
    var matched3 = false
    if opt3.someTo(x is int and x in 1..10):
      check(x == 7)
      matched3 = true
    check(matched3)  # Type pattern with range check should work

  test "someTo type patterns should provide clear type information":
    # This test verifies that type patterns improve code readability
    # by making the type of the bound variable explicit

    # Without seeing the Option declaration, it's clear x is int
    proc processUnknownOption(opt: Option[int]): string =
      if opt.someTo(x is int and x > 0):
        # It's immediately clear that x is int from the pattern
        return "Positive: " & $x
      else:
        return "None or non-positive"

    check(processUnknownOption(some(42)) == "Positive: 42")
    check(processUnknownOption(some(-5)) == "None or non-positive")
    check(processUnknownOption(none(int)) == "None or non-positive")

  test "someTo should work with custom types in type patterns":
    type
      Person = object
        name: string
        age: int

    # Test 1: Custom type pattern
    let opt1 = some(Person(name: "Alice", age: 30))
    var matched1 = false
    if opt1.someTo(p is Person):
      check(p.name == "Alice")
      check(p.age == 30)
      matched1 = true
    check(matched1)  # Type pattern should work with custom types

    # Test 2: Custom type pattern with guard
    let opt2 = some(Person(name: "Bob", age: 25))
    var matched2 = false
    if opt2.someTo(p is Person and p.age > 20):
      check(p.name == "Bob")
      check(p.age > 20)
      matched2 = true
    check(matched2)  # Custom type pattern with guard should work