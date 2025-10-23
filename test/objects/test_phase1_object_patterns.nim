## Phase 1 - Subtask 4: Object Pattern Validation Tests
##
## Tests for compile-time object pattern validation using structural analysis
## These tests validate that object patterns are checked against scrutinee metadata

import unittest
import ../../pattern_matching

suite "Phase 1 - Object Pattern Validation":

  test "Valid object pattern with correct fields":
    type Person = object
      name: string
      age: int

    let person = Person(name: "Alice", age: 30)

    let result = match person:
      Person(name, age): name & ":" & $age
      _: "invalid"

    check result == "Alice:30"

  test "Valid object pattern with named fields":
    type Point = object
      x: int
      y: int

    let p = Point(x: 10, y: 20)

    let result = match p:
      Point(x=a, y=b): $a & "," & $b
      _: "invalid"

    check result == "10,20"

  test "Valid object pattern with partial fields":
    type Person = object
      name: string
      age: int
      email: string

    let person = Person(name: "Bob", age: 25, email: "bob@example.com")

    let result = match person:
      Person(name, age): name & ":" & $age  # Only extract name and age
      _: "invalid"

    check result == "Bob:25"

  test "Invalid field name triggers compile-time error":
    type Person = object
      name: string
      age: int

    let person = Person(name: "Bob", age: 25)

    # This should fail at compile time with clear error
    when not compiles (
      let result = match person:
        Person(name, email): name  # ← email doesn't exist!
        _: "invalid"
    ):
      check true  # Expected: should not compile
    else:
      check false  # If this compiles, validation is missing

  test "Variant object validation":
    type
      Kind = enum kInt, kStr
      Value = object
        case kind: Kind
        of kInt: intVal: int
        of kStr: strVal: string

    let val = Value(kind: kInt, intVal: 42)

    let result = match val:
      Value(kind: kInt, intVal: x): $x
      Value(kind: kStr, strVal: s): s
      _: "unknown"

    check result == "42"

  test "Field name typo gives helpful error":
    type Point = object
      x, y: int

    let p = Point(x: 10, y: 20)

    # Typo: should be 'x' not 'xx'
    when not compiles (
      let result = match p:
        Point(xx, y): $xx  # ← typo!
        _: "invalid"
    ):
      check true  # Expected: should not compile
    else:
      check false  # If this compiles, validation is missing

  test "Type name mismatch detected":
    type
      Person = object
        name: string
      Point = object
        x, y: int

    let person = Person(name: "Alice")

    # Wrong type name
    when not compiles (
      let result = match person:
        Point(name): name  # ← Wrong type!
        _: "invalid"
    ):
      check true  # Expected: should not compile
    else:
      check false  # If this compiles, validation is missing

  test "Empty object pattern (type check only)":
    type Empty = object

    let e = Empty()

    let result = match e:
      Empty(): "matched"
      _: "no match"

    check result == "matched"

  test "Nested object pattern with validation":
    type
      Address = object
        city: string
        zip: int
      Person = object
        name: string
        address: Address

    let person = Person(
      name: "Charlie",
      address: Address(city: "NYC", zip: 10001)
    )

    let result = match person:
      Person(name, address): name & ":" & address.city
      _: "invalid"

    check result == "Charlie:NYC"

  test "Object with @ pattern":
    type Point = object
      x, y: int

    let p = Point(x: 5, y: 10)

    let result = match p:
      Point(x @ px, y @ py): $px & "," & $py
      _: "invalid"

    check result == "5,10"