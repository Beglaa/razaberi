## Phase 1 Integration Tests - Mixed Pattern Types
## Tests combining different pattern types together

import unittest
import tables
import options
import ../../pattern_matching

suite "Phase 1 Integration - Mixed Pattern Types":

  test "Object with tuple fields":
    type Container = object
      point: (int, int)
      name: string

    let c = Container(point: (10, 20), name: "test")

    let result = match c:
      Container(point: (x, y), name: n): n & ":" & $x & "," & $y
      _: "no match"

    check result == "test:10,20"

  test "Tuple containing objects":
    type Point = object
      x, y: int

    let data = (Point(x: 1, y: 2), "label")

    let result = match data:
      (Point(x, y), label): label & ":" & $x & "," & $y
      _: "no match"

    check result == "label:1,2"

  test "Sequence of objects":
    type Item = object
      id: int
      value: string

    let items = @[Item(id: 1, value: "a"), Item(id: 2, value: "b")]

    let result = match items:
      [Item(id: 1, value: v1), Item(id: 2, value: v2)]: v1 & v2
      _: "no match"

    check result == "ab"

  test "Table with object values":
    type Config = object
      enabled: bool
      value: int

    let data = {"app": Config(enabled: true, value: 100)}.toTable

    let result = match data:
      {"app": Config(enabled: e, value: v)}: $e & ":" & $v
      _: "no match"

    check result == "true:100"

  test "Object with Option fields":
    type Data = object
      id: int
      optValue: Option[string]

    let d1 = Data(id: 1, optValue: some("hello"))
    let d2 = Data(id: 2, optValue: none(string))

    let r1 = match d1:
      Data(id: i, optValue: Some(s)): $i & ":" & s
      _: "no match"

    let r2 = match d2:
      Data(id: i, optValue: None()): $i & ":none"
      _: "no match"

    check r1 == "1:hello"
    check r2 == "2:none"

  test "Nested tuples with objects":
    type Point = object
      x, y: int

    let data = ((Point(x: 1, y: 2), "first"), (Point(x: 3, y: 4), "second"))

    let result = match data:
      ((Point(x: x1, y: y1), label1), (Point(x: x2, y: y2), label2)):
        label1 & ":" & $x1 & "," & $y1 & "|" & label2 & ":" & $x2 & "," & $y2
      _: "no match"

    check result == "first:1,2|second:3,4"

  test "Object with sequence and tuple fields":
    type Container = object
      items: seq[int]
      position: (int, int)
      name: string

    let c = Container(items: @[10, 20, 30], position: (5, 15), name: "box")

    let result = match c:
      Container(items: [a, b, c], position: (x, y), name: n):
        n & ":" & $a & "," & $b & "," & $c & "@" & $x & "," & $y
      _: "no match"

    check result == "box:10,20,30@5,15"

  test "Sequence of tuples containing objects":
    type Person = object
      name: string
      age: int

    let data = @[(Person(name: "Alice", age: 30), 100), (Person(name: "Bob", age: 25), 200)]

    let result = match data:
      [(Person(name: n1, age: a1), score1), (Person(name: n2, age: a2), score2)]:
        n1 & ":" & $a1 & ":" & $score1 & "|" & n2 & ":" & $a2 & ":" & $score2
      _: "no match"

    check result == "Alice:30:100|Bob:25:200"

  test "Table with tuple values":
    let data = {"a": (1, 2), "b": (3, 4)}.toTable

    let result = match data:
      {"a": (x1, y1), "b": (x2, y2)}: $x1 & "," & $y1 & "|" & $x2 & "," & $y2
      _: "no match"

    check result == "1,2|3,4"

  test "Complex mixed: object with nested structures":
    type
      InnerData = object
        values: seq[int]
      OuterData = object
        inner: InnerData
        label: string
        position: (int, int)

    let obj = OuterData(
      inner: InnerData(values: @[1, 2, 3]),
      label: "test",
      position: (10, 20)
    )

    let result = match obj:
      OuterData(inner: InnerData(values: [a, b, c]), label: l, position: (x, y)):
        l & ":" & $a & "," & $b & "," & $c & "@" & $x & "," & $y
      _: "no match"

    check result == "test:1,2,3@10,20"