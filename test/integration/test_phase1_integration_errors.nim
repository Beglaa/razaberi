## Phase 1 Integration Tests - Error Handling and Validation
## Tests error cases and ensures proper error handling

import unittest
import options
import ../../pattern_matching

suite "Phase 1 Integration - Error Handling":

  test "Unmatched pattern raises MatchError":
    type Person = object
      name: string
      age: int

    let p = Person(name: "Alice", age: 30)

    expect MatchError:
      let result = match p:
        Person(name: "Bob", age: a): $a

  test "Wildcard prevents MatchError":
    type Person = object
      name: string
      age: int

    let p = Person(name: "Alice", age: 30)

    let result = match p:
      Person(name: "Bob", age: a): "bob"
      _: "other"

    check result == "other"

  test "Sequence size mismatch falls through":
    let data = @[1, 2]

    let result = match data:
      [a, b, c]: "three"
      [a, b]: "two"
      _: "other"

    check result == "two"

  test "Tuple size match with correct pattern":
    let data = (1, 2)

    let result = match data:
      (a, b): "two"
      _: "other"

    check result == "two"

  test "Type mismatch handled with guards":
    let value = 42

    let result = match value:
      x and x > 100: "large"
      x and x > 50: "medium"
      x: "small"

    check result == "small"

  test "Option None handling":
    let opt: Option[int] = none(int)

    let result = match opt:
      Some(x): $x
      None(): "empty"

    check result == "empty"

  test "Variant discriminator mismatch falls through":
    type
      Kind = enum kInt, kStr
      Value = object
        case kind: Kind
        of kInt: intVal: int
        of kStr: strVal: string

    let v = Value(kind: kInt, intVal: 42)

    let result = match v:
      Value(kind: kStr, strVal: s): "str:" & s
      Value(kind: kInt, intVal: x): "int:" & $x
      _: "other"

    check result == "int:42"

  test "Multiple patterns with guards":
    let values = @[10, 50, 150]

    let r1 = match values[0]:
      x and x > 100: "large"
      x and x > 25: "medium"
      x: "small"

    let r2 = match values[1]:
      x and x > 100: "large"
      x and x > 25: "medium"
      x: "small"

    let r3 = match values[2]:
      x and x > 100: "large"
      x and x > 25: "medium"
      x: "small"

    check r1 == "small"
    check r2 == "medium"
    check r3 == "large"

  test "Object field access with fallback":
    type Point = object
      x, y: int

    let p = Point(x: 100, y: 200)

    let result = match p:
      Point(x: 50, y: y): "x=50"
      Point(x: x, y: 200): "y=200"
      Point(x: x, y: y): "other"

    check result == "y=200"

  test "Nested pattern mismatch falls through":
    type
      Inner = object
        value: int
      Outer = object
        inner: Inner

    let obj = Outer(inner: Inner(value: 42))

    let result = match obj:
      Outer(inner: Inner(value: 100)): "100"
      Outer(inner: Inner(value: 42)): "42"
      _: "other"

    check result == "42"

  test "Empty sequence handling":
    let data: seq[int] = @[]

    let result = match data:
      [a, b]: "two"
      [a]: "one"
      []: "empty"
      _: "other"

    check result == "empty"

  test "Guard evaluation order":
    let value = 75

    let result = match value:
      x and x > 50 and x < 80: "range1"
      x and x > 70: "range2"
      _: "other"

    check result == "range1"

  test "OR pattern with guards":
    let value = 5

    let result = match value:
      x and x in [1, 2, 3] and x > 2: "small>2"
      (4 | 5 | 6): "medium"
      _: "other"

    check result == "medium"

  test "Ref object nil check":
    type Node = ref object
      value: int

    let n: Node = nil

    let result = match n:
      nil: "nil"
      Node(value: v): "value"

    check result == "nil"

  test "Complex nested structure with variable binding":
    type
      Inner = object
        value: int
      Middle = object
        inner: Inner
        count: int
      Outer = object
        middle: Middle

    let obj = Outer(middle: Middle(inner: Inner(value: 42), count: 10))

    let result = match obj:
      Outer(middle: Middle(inner: Inner(value: 100), count: c)): "v=100"
      Outer(middle: Middle(inner: Inner(value: v), count: c)): "v=" & $v & ",c=" & $c

    check result == "v=42,c=10"

  test "Multiple OR patterns with fallback":
    let value = 15

    let result = match value:
      1 | 2 | 3: "first"
      4 | 5 | 6: "second"
      10 | 15 | 20: "third"
      _: "other"

    check result == "third"

  test "Tuple with Option fields":
    let data = (some(42), none(string))

    let result = match data:
      (Some(x), Some(s)): "both"
      (Some(x), None()): "first:" & $x
      (None(), Some(s)): "second"
      (None(), None()): "none"

    check result == "first:42"

  test "Sequence pattern with guards":
    let data = @[10, 20, 30]

    let result = match data:
      [a, b, c] and a > 50: "a>50"
      [a, b, c] and b > 15: "b>15"
      [a, b, c]: "all"
      _: "other"

    check result == "b>15"

  test "Variant with nested Option":
    type
      Kind = enum kValue, kNone
      Container = object
        case kind: Kind
        of kValue: value: Option[int]
        of kNone: discard

    let c = Container(kind: kValue, value: some(42))

    let result = match c:
      Container(kind: kValue, value: Some(x)): "value:" & $x
      Container(kind: kValue, value: None()): "none"
      Container(kind: kNone): "empty"

    check result == "value:42"

  test "Deep nesting with multiple fallback patterns":
    type
      L3 = object
        val: int
      L2 = object
        l3: L3
      L1 = object
        l2: L2

    let obj = L1(l2: L2(l3: L3(val: 42)))

    let result = match obj:
      L1(l2: L2(l3: L3(val: 100))): "100"
      L1(l2: L2(l3: L3(val: 50))): "50"
      L1(l2: L2(l3: L3(val: 42))): "42"
      _: "other"

    check result == "42"

  test "Pattern ordering importance":
    let value = 50

    # More specific pattern first
    let r1 = match value:
      x and x == 50: "exact"
      x and x > 25: "range"
      _: "other"

    # More general pattern first (should still match correctly)
    let r2 = match value:
      x and x > 25: "range"
      x and x == 50: "exact"
      _: "other"

    check r1 == "exact"
    check r2 == "range"  # First matching pattern wins