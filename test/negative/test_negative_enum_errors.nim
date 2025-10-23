## Negative Tests: Enum Pattern Errors
##
## Tests compile-time validation of invalid enum patterns
## Uses shouldNotCompile template to verify errors are caught at compile time
##
## Test Coverage:
## 1. Non-existent enum values
## 2. Object constructor syntax on enum (invalid)
## 3. Sequence pattern on enum (invalid)
## 4. Wrong enum type values (mixing enums)
## 5. Tuple pattern on enum (invalid)
## 6. Table pattern on enum (invalid)
## 7. Invalid literals on enum
## 8. Verify valid patterns still compile (control tests)

import unittest
import ../../pattern_matching

suite "Negative Tests: Enum Pattern Errors":

  template shouldNotCompile(code: untyped): bool =
    not compiles(code)

  template shouldCompile(code: untyped): bool =
    compiles(code)

  # ============================================================================
  # Test Setup: Define test enum types
  # ============================================================================

  type
    Color = enum
      red, green, blue

    Status = enum
      Active, Inactive, Pending

    Priority = enum
      high, medium, low

    Direction = enum
      North, South, East, West

    Mode = enum
      Fast, Slow

  # ============================================================================
  # Test 1: Non-existent Enum Values
  # ============================================================================

  test "non-existent enum value should not compile":
    check shouldNotCompile (
      let c = red
      match c:
        orange: "orange color"  # orange doesn't exist in Color enum
        _: "other"
    )

  test "typo in enum value should not compile":
    check shouldNotCompile (
      let s = Active
      match s:
        Activ: "active"  # Typo: should be Active
        _: "other"
    )

  test "wrong case enum value should not compile":
    check shouldNotCompile (
      let p = high
      match p:
        High: "high priority"  # Wrong case: should be 'high' not 'High'
        _: "other"
    )

  # ============================================================================
  # Test 2: Object Constructor Syntax on Enum (Invalid)
  # ============================================================================

  test "object constructor on enum should not compile":
    check shouldNotCompile (
      let c = red
      match c:
        Color(x, y): "constructor pattern"  # Enums don't support object constructor syntax
        _: "other"
    )

  test "enum value with parentheses should not compile":
    check shouldNotCompile (
      let s = Active
      match s:
        Active(x): "status with field"  # Enums have no fields
        _: "other"
    )

  test "enum with field binding should not compile":
    check shouldNotCompile (
      let d = North
      match d:
        North(value): "north with value"  # Enum values don't have fields
        _: "other"
    )

  # ============================================================================
  # Test 3: Sequence Pattern on Enum (Invalid)
  # ============================================================================

  test "sequence pattern on enum should not compile":
    check shouldNotCompile (
      let c = red
      match c:
        [red, green]: "sequence of colors"  # Enum is not a sequence
        _: "other"
    )

  test "array destructuring on enum should not compile":
    check shouldNotCompile (
      let s = Active
      match s:
        [a, b, c]: "destructured array"  # Enum cannot be destructured as array
        _: "other"
    )

  test "spread pattern on enum should not compile":
    check shouldNotCompile (
      let p = high
      match p:
        [first, *rest]: "spread pattern"  # Enum doesn't support spread
        _: "other"
    )

  # ============================================================================
  # Test 4: Wrong Enum Type Values (Mixing Enums)
  # ============================================================================

  test "mixing values from different enums should not compile":
    check shouldNotCompile (
      let c = red
      match c:
        Active: "wrong enum"  # 'Active' is from Status, not Color
        _: "other"
    )

  test "OR pattern with wrong enum type should not compile":
    check shouldNotCompile (
      let c = red
      match c:
        red | high: "mixed enums"  # 'high' is from Priority, not Color
        _: "other"
    )

  test "set pattern with wrong enum type should not compile":
    check shouldNotCompile (
      let s = Active
      match s:
        {Active, Fast}: "mixed enum set"  # 'Fast' is from Mode, not Status
        _: "other"
    )

  # ============================================================================
  # Test 5: Tuple Pattern on Enum (Invalid)
  # ============================================================================

  test "tuple pattern on enum should not compile":
    check shouldNotCompile (
      let c = red
      match c:
        (red, green): "tuple pattern"  # Enum is not a tuple
        _: "other"
    )

  test "tuple destructuring on enum should not compile":
    check shouldNotCompile (
      let s = Active
      match s:
        (x, y, z): "destructured tuple"  # Enum cannot be destructured as tuple
        _: "other"
    )

  # ============================================================================
  # Test 6: Table Pattern on Enum (Invalid)
  # ============================================================================

  test "table pattern on enum should not compile":
    check shouldNotCompile (
      let c = red
      match c:
        {"color": value}: "table pattern"  # Enum is not a table
        _: "other"
    )

  test "dictionary destructuring on enum should not compile":
    check shouldNotCompile (
      let p = high
      match p:
        {"level": x, "value": y}: "dict pattern"  # Enum is not a dictionary
        _: "other"
    )

  # ============================================================================
  # Test 7: Invalid Literals on Enum
  # ============================================================================

  test "string literal on enum should not compile":
    check shouldNotCompile (
      let c = red
      match c:
        "red": "string literal"  # String literal doesn't match enum
        _: "other"
    )

  test "integer literal on enum should not compile":
    check shouldNotCompile (
      let s = Active
      match s:
        42: "integer literal"  # Integer doesn't match enum (even if ordinal matches)
        _: "other"
    )

  test "float literal on enum should not compile":
    check shouldNotCompile (
      let p = high
      match p:
        3.14: "float literal"  # Float doesn't match enum
        _: "other"
    )

  # ============================================================================
  # Test 8: Verify Valid Patterns Still Compile
  # ============================================================================

  test "valid enum literal pattern should compile":
    check shouldCompile (
      let c = red
      match c:
        red: "red color"
        _: "other"
    )

  test "valid enum OR pattern should compile":
    check shouldCompile (
      let s = Active
      match s:
        Active | Inactive: "active or inactive"
        _: "other"
    )

  test "valid enum set pattern should compile":
    check shouldCompile (
      let p = high
      match p:
        {high, medium}: "high or medium"
        _: "other"
    )

  test "valid enum @ pattern binding should compile":
    check shouldCompile (
      let c = red
      match c:
        red @ x: $x  # @ pattern binding should work
        _: "other"
    )

  test "valid enum wildcard pattern should compile":
    check shouldCompile (
      let s = Active
      match s:
        _: "any status"
    )

  # ============================================================================
  # Test 9: Edge Cases
  # ============================================================================

  test "single value enum should work":
    type SingleEnum = enum
      OnlyValue

    check shouldCompile (
      let e = OnlyValue
      match e:
        OnlyValue: "single value"
    )

  test "enum with explicit ordinals should validate correctly":
    type StatusWithOrdinals = enum
      Active = 1
      Inactive = 2
      Pending = 3

    check shouldCompile (
      let s = Active
      match s:
        Active: "active"
        Inactive: "inactive"
        _: "other"
    )
