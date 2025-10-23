## Union Type OR Pattern Workaround Tests
## Tests for handling multiple union types with same body using .holds() method
##
## Background: OR patterns like `int(_) | string(_)` don't work with union types
## Workaround: Use guards with .holds() method for checking multiple types

import unittest
import ../../union_type
import ../../pattern_matching

# Test types
type Result = union(int, string, bool)
type Simple = union(int, string)
type Triple = union(int, float, bool)

suite "Union Type OR Pattern Workaround - Using .holds()":

  # ==================== Basic .holds() OR Patterns ====================

  test "holds() with OR for int|string - int value":
    let r1 = Result.init(42)

    let msg = match r1:
      (int | string ) @ x: "int or string: " & $x
      x and x.holds(bool): "bool: " & $x
      _: "unknown"

    check msg == "int or string: 42"

  test "holds() with OR for int|string - string value":
    let r2 = Result.init("hello")

    let msg = match r2:
      x and (x.holds(int) or x.holds(string)): "int or string: " & $x
      x and x.holds(bool): "bool: " & $x
      _: "unknown"

    check msg == "int or string: hello"

  test "holds() with OR for int|string - bool value":
    let r3 = Result.init(true)

    let msg = match r3:
      x and (x.holds(int) or x.holds(string)): "int or string: " & $x
      x and x.holds(bool): "bool: " & $x
      _: "unknown"

    check msg == "bool: true"

  # ==================== Multiple OR Groups ====================

  test "multiple holds() OR groups in same match":
    let r1 = Triple.init(42)
    let r2 = Triple.init(3.14)
    let r3 = Triple.init(true)

    let msg1 = match r1:
      x and (x.holds(int) or x.holds(float)): "numeric: " & $x
      x and x.holds(bool): "boolean: " & $x
      _: "unknown"

    let msg2 = match r2:
      x and (x.holds(int) or x.holds(float)): "numeric: " & $x
      x and x.holds(bool): "boolean: " & $x
      _: "unknown"

    let msg3 = match r3:
      x and (x.holds(int) or x.holds(float)): "numeric: " & $x
      x and x.holds(bool): "boolean: " & $x
      _: "unknown"

    check msg1 == "numeric: 42"
    check msg2 == "numeric: 3.14"
    check msg3 == "boolean: true"

  # ==================== Exhaustiveness with .holds() ====================

  test "holds() OR patterns are exhaustive when all types covered":
    # This should compile - all 3 types covered
    let r = Result.init(42)

    let msg = match r:
      x and (x.holds(int) or x.holds(string)): "data"
      x and x.holds(bool): "flag"
      _: "unreachable"  # Wildcard makes it exhaustive

    check msg == "data"

  test "holds() without wildcard still needs exhaustiveness":
    # Even with .holds(), we need wildcard or explicit coverage
    let r = Simple.init(42)

    # This works because wildcard catches all
    let msg = match r:
      x and x.holds(int): "int: " & $x
      _: "string"  # Wildcard for exhaustiveness

    check msg == "int: 42"

  # ==================== Comparison: holds() vs Type Patterns ====================

  test "holds() OR equivalent to separate type patterns":
    let r1 = Simple.init(42)
    let r2 = Simple.init("hello")

    # Approach 1: Using .holds() OR
    let msg1a = match r1:
      x and (x.holds(int) or x.holds(string)): "value: " & $x
      _: "unreachable"

    let msg2a = match r2:
      x and (x.holds(int) or x.holds(string)): "value: " & $x
      _: "unreachable"

    # Approach 2: Separate type patterns (traditional)
    let msg1b = match r1:
      int(v): "value: " & $v
      string(s): "value: " & s

    let msg2b = match r2:
      int(v): "value: " & $v
      string(s): "value: " & s

    # Both approaches should give same result
    check msg1a == msg1b
    check msg2a == msg2b

  # ==================== Guards with .holds() ====================

  test "holds() OR combined with additional guards":
    let r1 = Result.init(42)
    let r2 = Result.init(10)
    let r3 = Result.init("test")

    let msg1 = match r1:
      x and (x.holds(int) or x.holds(string)) and (
        (x.holds(int) and x.get(int) > 20) or
        (x.holds(string) and x.get(string).len > 2)
      ): "large value"
      x and (x.holds(int) or x.holds(string)): "small value"
      _: "other"

    let msg2 = match r2:
      x and (x.holds(int) or x.holds(string)) and (
        (x.holds(int) and x.get(int) > 20) or
        (x.holds(string) and x.get(string).len > 2)
      ): "large value"
      x and (x.holds(int) or x.holds(string)): "small value"
      _: "other"

    let msg3 = match r3:
      x and (x.holds(int) or x.holds(string)) and (
        (x.holds(int) and x.get(int) > 20) or
        (x.holds(string) and x.get(string).len > 2)
      ): "large value"
      x and (x.holds(int) or x.holds(string)): "small value"
      _: "other"

    check msg1 == "large value"   # 42 > 20
    check msg2 == "small value"   # 10 <= 20
    check msg3 == "large value"   # "test".len > 2

  # ==================== Wildcard Patterns with .holds() ====================

  test "holds() OR with wildcard in pattern":
    let r = Result.init(42)

    # Can still use wildcard for "don't care about value"
    let msg = match r:
      x and (x.holds(int) or x.holds(string)): "is data type"
      _: "is other type"

    check msg == "is data type"

  # ==================== Nested Matches with .holds() ====================

  test "nested matches with holds() OR patterns":
    let outer = Result.init(42)
    let inner = Result.init("test")

    let msg = match outer:
      x and (x.holds(int) or x.holds(string)):
        match inner:
          y and (y.holds(int) or y.holds(string)): "both data"
          _: "outer data, inner other"
      _: "outer other"

    check msg == "both data"
