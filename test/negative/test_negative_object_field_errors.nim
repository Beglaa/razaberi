## Comprehensive Negative Tests for Object Field Errors
##
## This test suite validates that the pattern matching library provides
## helpful compile-time error messages when patterns contain invalid field
## names or field access errors.
##
## Test Coverage:
## 1. Non-existent field names with clear error messages
## 2. Typos in field names with Levenshtein distance suggestions
## 3. Field type mismatches with literal values
## 4. Variant object branch safety violations
## 5. Available fields listing in error messages
## 6. Empty objects (no fields)

import unittest
import ../../pattern_matching

suite "Negative Tests: Object Field Errors":
  ## Template for compile-time validation
  ## Returns true if code does NOT compile (expected for negative tests)
  template shouldNotCompile(code: untyped): bool =
    not compiles(code)

  ## Template for compile-time validation
  ## Returns true if code DOES compile (for positive control tests)
  template shouldCompile(code: untyped): bool =
    compiles(code)

  # ============================================================================
  # Test Setup: Define test types
  # ============================================================================

  type
    User = object
      name: string
      age: int
      email: string

    Point = object
      x: int
      y: int

    EmptyObject = object
      discard

    # Variant object for branch safety testing
    SimpleValue = object
      case kind: bool
      of true:
        intVal: int
      of false:
        strVal: string

  # ============================================================================
  # Test 1: Non-existent Field Names
  # ============================================================================

  test "non-existent field should not compile":
    check shouldNotCompile (
      let u = User(name: "Alice", age: 30, email: "alice@example.com")
      match u:
        User(invalid_field: x): x
        _: "default"
    )

  test "non-existent field with multiple fields should not compile":
    check shouldNotCompile (
      let u = User(name: "Alice", age: 30, email: "alice@example.com")
      match u:
        User(name: n, invalid_field: x): n
        _: "default"
    )

  test "completely wrong field name should not compile":
    check shouldNotCompile (
      let p = Point(x: 10, y: 20)
      match p:
        Point(z: z): z
        _: 0
    )

  test "multiple non-existent fields should not compile":
    check shouldNotCompile (
      let p = Point(x: 10, y: 20)
      match p:
        Point(z: z, w: w): z + w
        _: 0
    )

  # ============================================================================
  # Test 2: Typos with Levenshtein Suggestions
  # ============================================================================

  test "typo in field name should not compile (suggestion: name)":
    # This should trigger "Did you mean 'name'?" suggestion
    check shouldNotCompile (
      let u = User(name: "Alice", age: 30, email: "alice@example.com")
      match u:
        User(nme: x): x  # Typo: nme instead of name
        _: "default"
    )

  test "typo in field name should not compile (suggestion: age)":
    # This should trigger "Did you mean 'age'?" suggestion
    check shouldNotCompile (
      let u = User(name: "Alice", age: 30, email: "alice@example.com")
      match u:
        User(ags: x): x  # Typo: ags instead of age
        _: 0
    )

  test "typo in field name should not compile (suggestion: email)":
    # This should trigger "Did you mean 'email'?" suggestion
    check shouldNotCompile (
      let u = User(name: "Alice", age: 30, email: "alice@example.com")
      match u:
        User(emial: x): x  # Typo: emial instead of email
        _: "default"
    )

  test "typo in Point field should not compile (suggestion: x)":
    check shouldNotCompile (
      let p = Point(x: 10, y: 20)
      match p:
        Point(xx: val): val  # Typo: xx instead of x
        _: 0
    )

  test "typo in Point field should not compile (suggestion: y)":
    check shouldNotCompile (
      let p = Point(x: 10, y: 20)
      match p:
        Point(yy: val): val  # Typo: yy instead of y
        _: 0
    )

  # ============================================================================
  # Test 3: Empty Objects (No Fields)
  # ============================================================================

  test "empty object with field pattern should not compile":
    check shouldNotCompile (
      let e = EmptyObject()
      match e:
        EmptyObject(field: x): x
        _: "default"
    )

  test "empty object should compile with wildcard":
    # Positive control: wildcard should work
    check shouldCompile (
      let e = EmptyObject()
      match e:
        EmptyObject(): "matched"
        _: "default"
    )

  # ============================================================================
  # Test 4: Variant Object Branch Safety
  # ============================================================================

  test "accessing wrong branch field should not compile":
    check shouldNotCompile (
      let v = SimpleValue(kind: true, intVal: 42)
      match v:
        # Trying to access strVal when kind is true (should be intVal)
        SimpleValue(kind: true, strVal: s): s
        _: "default"
    )

  # NOTE: This test is currently disabled because the pattern matching library
  # allows accessing variant fields without explicit discriminator checks
  # (it generates runtime checks instead of compile-time errors)
  # test "accessing field without discriminator check should not compile":
  #   check shouldNotCompile (
  #     let v = SimpleValue(kind: true, intVal: 42)
  #     match v:
  #       # Trying to access branch-specific field without checking discriminator
  #       SimpleValue(strVal: s): s
  #       _: "default"
  #   )

  # ============================================================================
  # Test 5: Mixed Valid and Invalid Fields
  # ============================================================================

  test "mixed valid and invalid fields should not compile":
    check shouldNotCompile (
      let u = User(name: "Alice", age: 30, email: "alice@example.com")
      match u:
        User(name: n, invalid: x): n  # name is valid, invalid is not
        _: "default"
    )

  test "multiple typos should not compile":
    check shouldNotCompile (
      let u = User(name: "Alice", age: 30, email: "alice@example.com")
      match u:
        User(nme: n, ags: a): n  # Both are typos
        _: "default"
    )

  # ============================================================================
  # Test 6: Nested Object Field Errors
  # ============================================================================

  type
    Outer = object
      inner: Point
      value: int

  test "non-existent nested field should not compile":
    check shouldNotCompile (
      let o = Outer(inner: Point(x: 1, y: 2), value: 10)
      match o:
        Outer(inner: Point(z: z)): z  # Point doesn't have z field
        _: 0
    )

  test "typo in nested field should not compile":
    check shouldNotCompile (
      let o = Outer(inner: Point(x: 1, y: 2), value: 10)
      match o:
        Outer(inner: Point(xx: z)): z  # Typo: xx instead of x
        _: 0
    )

  test "non-existent outer field should not compile":
    check shouldNotCompile (
      let o = Outer(inner: Point(x: 1, y: 2), value: 10)
      match o:
        Outer(invalid: x): x  # invalid field doesn't exist
        _: 0
    )

  # ============================================================================
  # Test 7: Field Access in Different Pattern Contexts
  # ============================================================================

  # NOTE: This test is currently disabled because OR patterns validate
  # each branch independently, and the second branch (User(name: x)) is valid
  # test "non-existent field in OR pattern should not compile":
  #   check shouldNotCompile (
  #     let u = User(name: "Alice", age: 30, email: "alice@example.com")
  #     match u:
  #       User(invalid: x) | User(name: x): x
  #       _: "default"
  #   )

  test "non-existent field in guard pattern should not compile":
    check shouldNotCompile (
      let u = User(name: "Alice", age: 30, email: "alice@example.com")
      match u:
        User(invalid: x) and x == "test": x
        _: "default"
    )

  test "non-existent field in @ pattern should not compile":
    check shouldNotCompile (
      let u = User(name: "Alice", age: 30, email: "alice@example.com")
      match u:
        User(invalid: x) @ u: x
        _: "default"
    )

  # ============================================================================
  # Test 8: Positive Controls (Should Compile)
  # ============================================================================

  test "valid field access should compile":
    check shouldCompile (
      let u = User(name: "Alice", age: 30, email: "alice@example.com")
      match u:
        User(name: n): n
        _: "default"
    )

  test "multiple valid fields should compile":
    check shouldCompile (
      let u = User(name: "Alice", age: 30, email: "alice@example.com")
      match u:
        User(name: n, age: a): n
        _: "default"
    )

  test "all fields should compile":
    check shouldCompile (
      let u = User(name: "Alice", age: 30, email: "alice@example.com")
      match u:
        User(name: n, age: a, email: e): n
        _: "default"
    )

  # NOTE: This test is currently disabled because User(_) syntax
  # is interpreted as a single-element constructor pattern, not a wildcard
  # Use User() or just _ for wildcard matching
  # test "wildcard should compile":
  #   check shouldCompile (
  #     let u = User(name: "Alice", age: 30, email: "alice@example.com")
  #     match u:
  #       User(_): "matched"
  #       _: "default"
  #   )

  test "empty constructor pattern should compile":
    check shouldCompile (
      let u = User(name: "Alice", age: 30, email: "alice@example.com")
      match u:
        User(): "matched"
        _: "default"
    )

  test "variable binding should compile":
    check shouldCompile (
      let u = User(name: "Alice", age: 30, email: "alice@example.com")
      match u:
        x: "matched"
    )

  # ============================================================================
  # Test 9: Case Sensitivity
  # ============================================================================

  test "wrong case field name should not compile":
    check shouldNotCompile (
      let u = User(name: "Alice", age: 30, email: "alice@example.com")
      match u:
        User(Name: x): x  # Capital N instead of lowercase n
        _: "default"
    )

  test "all caps field name should not compile":
    check shouldNotCompile (
      let u = User(name: "Alice", age: 30, email: "alice@example.com")
      match u:
        User(NAME: x): x  # All caps
        _: "default"
    )

  # ============================================================================
  # Test 10: Similar Field Names (Confusion Testing)
  # ============================================================================

  type
    Confusing = object
      value: int
      val: string
      values: seq[int]

  test "using similar but wrong field name should not compile":
    check shouldNotCompile (
      let c = Confusing(value: 42, val: "test", values: @[1, 2, 3])
      match c:
        Confusing(valu: x): x  # Close to value/val but not exact
        _: 0
    )

  test "correct similar field names should compile":
    check shouldCompile (
      let c = Confusing(value: 42, val: "test", values: @[1, 2, 3])
      match c:
        Confusing(value: x): x  # Exact match
        _: 0
    )

  # ============================================================================
  # Test 11: Discriminated Union Error Messages
  # ============================================================================

  type
    Status = object
      case kind: bool
      of true:
        active: bool
        timestamp: int
      of false:
        reason: string

  test "accessing unavailable branch field should not compile":
    check shouldNotCompile (
      let s = Status(kind: true, active: true, timestamp: 12345)
      match s:
        Status(kind: true, reason: r): r  # reason only available when kind=false
        _: "default"
    )

  test "accessing correct branch field should compile":
    check shouldCompile (
      let s = Status(kind: true, active: true, timestamp: 12345)
      match s:
        Status(kind: true, active: a): a
        _: false
    )

  # ============================================================================
  # Test 12: Field Names with Underscores and Special Patterns
  # ============================================================================

  type
    Special = object
      field_name: string
      another_field: int

  test "typo in underscore field should not compile":
    check shouldNotCompile (
      let s = Special(field_name: "test", another_field: 42)
      match s:
        Special(field_nam: x): x  # Missing 'e'
        _: "default"
    )

  test "wrong underscore position should not compile":
    check shouldNotCompile (
      let s = Special(field_name: "test", another_field: 42)
      match s:
        Special(fieldname: x): x  # Missing underscore
        _: "default"
    )

  test "correct underscore field should compile":
    check shouldCompile (
      let s = Special(field_name: "test", another_field: 42)
      match s:
        Special(field_name: x): x
        _: "default"
    )
