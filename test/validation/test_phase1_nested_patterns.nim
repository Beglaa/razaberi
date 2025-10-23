## Tests for Phase 1 Subtask 10: Nested Pattern Validation with Metadata
##
## This test suite validates that nested patterns are properly validated
## using structural metadata analysis at every nesting level.

import unittest
import options
import tables
import ../../pattern_matching

suite "Phase 1: Nested Pattern Validation":

  test "Nested object pattern validation":
    type
      Inner = object
        value: int
      Outer = object
        inner: Inner

    let obj = Outer(inner: Inner(value: 42))

    let result = match obj:
      Outer(inner: Inner(value: v)): $v
      _: "no match"
    check result == "42"

  test "Deep nesting (3 levels)":
    type
      Level3 = object
        data: int
      Level2 = object
        level3: Level3
      Level1 = object
        level2: Level2

    let obj = Level1(level2: Level2(level3: Level3(data: 99)))

    let result = match obj:
      Level1(level2: Level2(level3: Level3(data: d))): $d
      _: "no match"
    check result == "99"

  test "Deep nesting (4 levels)":
    type
      Level4 = object
        value: string
      Level3 = object
        level4: Level4
      Level2 = object
        level3: Level3
      Level1 = object
        level2: Level2

    let obj = Level1(level2: Level2(level3: Level3(level4: Level4(value: "deep"))))

    let result = match obj:
      Level1(level2: Level2(level3: Level3(level4: Level4(value: v)))): v
      _: "no match"
    check result == "deep"

  test "Nested tuple in object":
    type
      Point = tuple[x: int, y: int]
      Container = object
        point: Point

    let obj = Container(point: (10, 20))

    let result = match obj:
      Container(point: (x, y)): $x & "," & $y
      _: "no match"
    check result == "10,20"

  test "Nested object with multiple fields":
    type
      Address = object
        street: string
        city: string
      Person = object
        name: string
        address: Address

    let person = Person(
      name: "Alice",
      address: Address(street: "Main St", city: "NYC")
    )

    let result = match person:
      Person(name: n, address: Address(city: c)): n & " from " & c
      _: "no match"
    check result == "Alice from NYC"

  test "Nested Option in object":
    type
      Container = object
        maybeValue: Option[int]

    let obj1 = Container(maybeValue: some(42))
    let obj2 = Container(maybeValue: none(int))

    let result1 = match obj1:
      Container(maybeValue: Some(v)): $v
      _: "none"
    check result1 == "42"

    let result2 = match obj2:
      Container(maybeValue: None()): "none"
      _: "some"
    check result2 == "none"

  test "Nested sequence in object":
    type
      Container = object
        items: seq[int]

    let obj = Container(items: @[1, 2, 3])

    let result = match obj:
      Container(items: [first, *rest]): $first & "," & $rest.len
      _: "no match"
    check result == "1,2"

  test "Nested table in object":
    type
      Container = object
        data: Table[string, int]

    var obj = Container(data: {"name": 42, "age": 30}.toTable)

    let result = match obj:
      Container(data: {"name": n}): $n
      _: "no match"
    check result == "42"

  test "Mixed nested patterns":
    type
      Inner = object
        value: int
        tag: string
      Outer = object
        inner: Inner
        count: int

    let obj = Outer(
      inner: Inner(value: 100, tag: "test"),
      count: 5
    )

    let result = match obj:
      Outer(inner: Inner(value: v, tag: t), count: c): $v & "-" & t & "-" & $c
      _: "no match"
    check result == "100-test-5"

  test "Nested pattern with guards":
    type
      Inner = object
        value: int
      Outer = object
        inner: Inner

    let obj1 = Outer(inner: Inner(value: 100))
    let obj2 = Outer(inner: Inner(value: 50))

    let result1 = match obj1:
      Outer(inner: Inner(value: v)) and v > 70: "high"
      _: "low"
    check result1 == "high"

    let result2 = match obj2:
      Outer(inner: Inner(value: v)) and v > 70: "high"
      _: "low"
    check result2 == "low"

  test "Deeply nested variant objects":
    type
      InnerKind = enum ikA, ikB
      Inner = object
        case kind: InnerKind
        of ikA: valueA: int
        of ikB: valueB: string

      Outer = object
        inner: Inner

    let obj1 = Outer(inner: Inner(kind: ikA, valueA: 42))
    let obj2 = Outer(inner: Inner(kind: ikB, valueB: "test"))

    let result1 = match obj1:
      Outer(inner: Inner(kind: ikA, valueA: v)): $v
      _: "no match"
    check result1 == "42"

    let result2 = match obj2:
      Outer(inner: Inner(kind: ikB, valueB: v)): v
      _: "no match"
    check result2 == "test"

  test "Nested @ patterns":
    type
      Inner = object
        value: int
      Outer = object
        inner: Inner

    let obj = Outer(inner: Inner(value: 42))

    let result = match obj:
      Outer(inner: Inner(value: 42) @ innerObj): $innerObj.value
      _: "no match"
    check result == "42"

  test "Very deep nesting (5 levels)":
    type
      L5 = object
        data: int
      L4 = object
        l5: L5
      L3 = object
        l4: L4
      L2 = object
        l3: L3
      L1 = object
        l2: L2

    let obj = L1(l2: L2(l3: L3(l4: L4(l5: L5(data: 123)))))

    let result = match obj:
      L1(l2: L2(l3: L3(l4: L4(l5: L5(data: d))))): $d
      _: "no match"
    check result == "123"