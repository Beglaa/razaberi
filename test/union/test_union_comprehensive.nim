## Union Comprehensive Integration Tests
## Tests end-to-end integration of all union features

import unittest
import strutils
import ../../union_type
import ../../pattern_matching

# Test types
type Point_Comp = object
  x, y: int

# Union types for integration testing
type Result_Comp = union(int, string, bool)
type Shape_Comp = union(Point_Comp, int, string)
type Result_Nominal1 = union(int, string)
type Result_Nominal2 = union(int, string)

suite "Union Comprehensive Integration":

  test "end-to-end: construction, checking, extraction, matching":
    # Construction
    let r1 = Result_Comp.init(42)
    let r2 = Result_Comp.init("hello")
    let r3 = Result_Comp.init(true)

    # Type checking
    check r1.holds(int)
    check r2.holds(string)
    check r3.holds(bool)

    # Value extraction
    check r1.get(int) == 42
    check r2.get(string) == "hello"
    check r3.get(bool) == true

    # Pattern matching (using explicit variant object syntax)
    let msg1 = match r1:
      Result_Comp(kind: ukInt, val0: v): "int: " & $v
      _: "other"

    let msg2 = match r2:
      Result_Comp(kind: ukString, val1: v): "string: " & v
      _: "other"

    let msg3 = match r3:
      Result_Comp(kind: ukBool, val2: v): "bool: " & $v
      _: "other"

    check msg1 == "int: 42"
    check msg2 == "string: hello"
    check msg3 == "bool: true"

  test "complex nested pattern with guards":
    let shapes = @[
      Shape_Comp.init(Point_Comp(x: 10, y: 20)),
      Shape_Comp.init(42),
      Shape_Comp.init("circle")
    ]

    var results: seq[string] = @[]

    for shape in shapes:
      let desc = match shape:
        Shape_Comp(kind: ukPoint_Comp, val0: p) and p.x > 5: "large point"
        Shape_Comp(kind: ukPoint_Comp, val0: p): "small point"
        Shape_Comp(kind: ukInt, val1: i) and i > 50: "large int"
        Shape_Comp(kind: ukInt, val1: i): "small int"
        Shape_Comp(kind: ukString, val2: s): "shape: " & s
        _: "unknown"

      results.add(desc)

    check results[0] == "large point"
    check results[1] == "small int"
    check results[2] == "shape: circle"

  test "type safety across different union types":
    proc processResult1(r: Result_Nominal1): string =
      match r:
        Result_Nominal1(kind: ukInt, val0: i): "result int: " & $i
        Result_Nominal1(kind: ukString, val1: s): "result string: " & s
        _: "unknown"

    proc processResult2(r: Result_Nominal2): string =
      match r:
        Result_Nominal2(kind: ukInt, val0: i): "response int: " & $i
        Result_Nominal2(kind: ukString, val1: s): "response string: " & s
        _: "unknown"

    let r = Result_Nominal1.init(42)
    let s = Result_Nominal2.init(42)

    check processResult1(r) == "result int: 42"
    check processResult2(s) == "response int: 42"

    # This should not compile - type mismatch
    check not compiles (
      processResult1(s)
    )

    check not compiles (
      processResult2(r)
    )

  test "pattern matching with tryGet":
    let r = Result_Comp.init(42)

    # Combine tryGet with pattern matching
    let value = r.tryGet(int)

    let msg = match value:
      Some(x): "value: " & $x
      None(): "no value"

    check msg == "value: 42"

  test "pattern matching in proc return":
    proc describe(r: Result_Comp): string =
      match r:
        Result_Comp(kind: ukInt, val0: i): "number: " & $i
        Result_Comp(kind: ukString, val1: s): "text: " & s
        Result_Comp(kind: ukBool, val2: b): "flag: " & $b

    check describe(Result_Comp.init(99)) == "number: 99"
    check describe(Result_Comp.init("test")) == "text: test"
    check describe(Result_Comp.init(false)) == "flag: false"

  test "equality with pattern matching":
    let r1 = Result_Comp.init(42)
    let r2 = Result_Comp.init(42)
    let r3 = Result_Comp.init("hello")

    # Test equality
    check r1 == r2
    check r1 != r3

    # Pattern match on equality result
    let same = if r1 == r2:
      match r1:
        Result_Comp(kind: ukInt, val0: i): "same int: " & $i
        _: "same other"
    else:
      "different"

    check same == "same int: 42"

  test "collection of unions with pattern matching":
    let items = @[
      Result_Comp.init(1),
      Result_Comp.init("two"),
      Result_Comp.init(3),
      Result_Comp.init(true),
      Result_Comp.init("five")
    ]

    var ints: seq[int] = @[]
    var strings: seq[string] = @[]

    for item in items:
      match item:
        Result_Comp(kind: ukInt, val0: i):
          ints.add(i)
        Result_Comp(kind: ukString, val1: s):
          strings.add(s)
        _:
          discard

    check ints == @[1, 3]
    check strings == @["two", "five"]

  test "string representation with pattern matching":
    let r = Result_Comp.init(42)
    let repr_str = $r

    # Pattern match based on string representation content
    let has_number = "42" in repr_str

    check has_number

  test "reassignment with pattern matching":
    var r = Result_Comp.init(0)

    # Use pattern matching to decide next state
    # Loop: 0->1->2->3->done->true
    for i in 0..<5:
      r = match r:
        Result_Comp(kind: ukInt, val0: x) and x < 3: Result_Comp.init(x + 1)
        Result_Comp(kind: ukInt, val0: x): Result_Comp.init("done")
        Result_Comp(kind: ukString, val1: s): Result_Comp.init(true)
        Result_Comp(kind: ukBool, val2: b): Result_Comp.init(0)

    # After 5 iterations: 0->1->2->3->done->true
    check r.holds(bool)
    check r.get(bool) == true
