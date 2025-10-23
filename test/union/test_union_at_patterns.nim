## GAP-14: Union Type @ Patterns with Type-Based Syntax
## Testing comprehensive @ pattern scenarios with union types

import std/unittest
import ../../union_type
import ../../pattern_matching

type Result = union(int, string)
type Value = union(int, string, bool)

type Error = object
  msg: string
proc `==`(a, b: Error): bool = a.msg == b.msg
type Response = union(int, Error)

# Nested union types for testing @ patterns at multiple levels
type InnerResult = union(int, string)
type OuterContainer = union(InnerResult, bool)

suite "GAP-14: Union @ Patterns - Basic":

  test "@ pattern with type-based syntax - int":
    let r = Result.init(42)

    let result = match r:
      int(v) @ captured:
        check v == 42
        check captured.holds(int)
        check captured.get(int) == 42
        "matched"
      string(s) @ captured: "string"

    check result == "matched"

  test "@ pattern with type-based syntax - string":
    let r = Result.init("hello")

    let result = match r:
      int(v) @ captured: "int"
      string(s) @ captured:
        check s == "hello"
        check captured.holds(string)
        check captured.get(string) == "hello"
        "matched"

    check result == "matched"

  test "@ pattern without inner binding":
    let r = Result.init(100)

    let result = match r:
      int @ captured:
        check captured.holds(int)
        check captured.get(int) == 100
        "int captured"
      string @ captured: "string"

    check result == "int captured"

suite "GAP-14: Union @ Patterns - With Guards":

  test "@ pattern with guard on extracted value":
    let r = Result.init(75)

    let result = match r:
      int(v) @ captured and v > 50:
        check v == 75
        check captured.holds(int)
        "large"
      int(v) @ captured:
        "small"
      string(s) @ captured: "string"

    check result == "large"

  test "@ pattern with guard on captured union":
    let r = Result.init(42)

    let result = match r:
      int(v) @ captured and captured.holds(int):
        check v == 42
        "verified"
      string(s) @ captured: "string"

    check result == "verified"

  test "@ pattern with multiple guards":
    let r = Value.init(85)

    let result = match r:
      int(v) @ captured and v >= 90: "A"
      int(v) @ captured and v >= 80:
        check v == 85
        check captured.holds(int)
        "B"
      int(v) @ captured: "C"
      _: "F"

    check result == "B"

suite "GAP-14: Union @ Patterns - With OR":

  # Note: Complex OR + @ combinations are beyond GAP-14 scope
  # GAP-14 focuses on basic @ patterns like: int(v) @ captured

  test "OR pattern with @ - separate branches":
    # This is the recommended approach
    let r1 = Value.init(42)
    let r2 = Value.init("text")
    let r3 = Value.init(true)

    proc classify(v: Value): string =
      match v:
        int @ captured:
          "number: " & $captured.get(int)
        string @ captured:
          "text: " & captured.get(string)
        bool @ captured: "bool"

    check classify(r1) == "number: 42"
    check classify(r2) == "text: text"
    check classify(r3) == "bool"

suite "GAP-14: Union @ Patterns - Complex Types":

  test "@ pattern with custom object type":
    let r = Response.init(Error(msg: "failed"))

    let result = match r:
      int(v) @ captured: "int"
      Error(e) @ captured:
        check e.msg == "failed"
        check captured.holds(Error)
        check captured.get(Error).msg == "failed"
        "error: " & e.msg

    check result == "error: failed"

  test "@ pattern with wildcard inner pattern":
    let r = Result.init("test")

    let result = match r:
      int(_) @ captured:
        "int: " & $captured.get(int)
      string(_) @ captured:
        check captured.holds(string)
        "string: " & captured.get(string)

    check result == "string: test"

suite "GAP-14: Union @ Patterns - Edge Cases":

  test "Multiple @ patterns in same match":
    let r1 = Result.init(10)
    let r2 = Result.init("hello")

    proc process(r: Result): string =
      match r:
        int(v) @ cap1:
          $v & ":" & $cap1.get(int)
        string(s) @ cap2:
          s & ":" & cap2.get(string)

    check process(r1) == "10:10"
    check process(r2) == "hello:hello"

  test "@ pattern with nested union types":
    # Create nested union: Outer contains Inner which contains int
    let inner = InnerResult.init(42)
    let outer = OuterContainer.init(inner)

    let result = match outer:
      InnerResult(innerUnion) @ outerCap:
        # outerCap captures the outer union
        # innerUnion is bound to the InnerResult value
        check outerCap.holds(InnerResult)

        # Now match on the inner union
        match innerUnion:
          int(v) @ innerCap:
            check v == 42
            check innerCap.holds(int)
            "nested int: " & $v
          string(s) @ innerCap:
            "nested string: " & s
      bool(b) @ outerCap:
        "bool: " & $b

    check result == "nested int: 42"

  test "@ pattern with deeply nested unions":
    # Test with string inside inner union
    let inner = InnerResult.init("hello")
    let outer = OuterContainer.init(inner)

    let result = match outer:
      InnerResult(innerUnion) @ outerCap:
        match innerUnion:
          int(v) @ innerCap: "int: " & $v
          string(s) @ innerCap:
            check s == "hello"
            check innerCap.holds(string)
            check outerCap.holds(InnerResult)
            "string: " & s
      bool(b): "bool"

    check result == "string: hello"
