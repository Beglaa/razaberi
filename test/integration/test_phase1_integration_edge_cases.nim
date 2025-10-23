## Phase 1 Integration Tests - Edge Cases
## Tests edge cases and corner scenarios

import unittest
import options
import ../../pattern_matching

suite "Phase 1 Integration - Edge Cases":

  test "Empty object":
    type Empty = object

    let e = Empty()

    let result = match e:
      Empty(): "empty"
      _: "no match"

    check result == "empty"

  test "Single-field object":
    type Single = object
      value: int

    let s = Single(value: 42)

    let result = match s:
      Single(value: v): $v
      _: "no match"

    check result == "42"

  test "Object with Option field (Some)":
    type Config = object
      value: Option[int]

    let c = Config(value: some(42))

    let result = match c:
      Config(value: Some(x)): $x
      _: "none"

    check result == "42"

  test "Object with Option field (None)":
    type Config = object
      value: Option[int]

    let c = Config(value: none(int))

    let result = match c:
      Config(value: None()): "empty"
      _: "has value"

    check result == "empty"

  test "Ref object patterns":
    type Person = ref object
      name: string
      age: int

    let p = Person(name: "Alice", age: 30)

    let result = match p:
      Person(name: n, age: a): n & ":" & $a
      _: "no match"

    check result == "Alice:30"

  test "Generic object patterns":
    type Container[T] = object
      value: T

    let c = Container[int](value: 42)

    let result = match c:
      Container(value: v): $v
      _: "no match"

    check result == "42"

  test "Generic object with multiple type parameters":
    type Pair[A, B] = object
      first: A
      second: B

    let p = Pair[int, string](first: 100, second: "test")

    let result = match p:
      Pair(first: f, second: s): $f & ":" & s
      _: "no match"

    check result == "100:test"

  test "Tuple with single element":
    let data = (42,)

    let result = match data:
      (x,): $x
      _: "no match"

    check result == "42"

  test "Empty tuple":
    let data = ()

    let result = match data:
      (): "empty"
      _: "no match"

    check result == "empty"

  test "Sequence with single element":
    let data = @[42]

    let result = match data:
      [x]: $x
      _: "no match"

    check result == "42"

  test "Empty sequence":
    let data: seq[int] = @[]

    let result = match data:
      []: "empty"
      _: "not empty"

    check result == "empty"

  test "Object with bool field":
    type Flag = object
      enabled: bool
      value: int

    let f1 = Flag(enabled: true, value: 100)
    let f2 = Flag(enabled: false, value: 200)

    # Explicit version: Pattern with guard checking the boolean value
    let r1 = match f1:
      Flag(enabled: e, value: v) and e == true: "enabled:" & $v
      Flag(enabled: e, value: v): "disabled:" & $v

    # Implicit version: Can also use variable binding and check later
    let r2 = match f2:
      Flag(enabled: e, value: v) and e == true: "enabled:" & $v
      Flag(enabled: e, value: v): "disabled:" & $v

    check r1 == "enabled:100"
    check r2 == "disabled:200"

  test "Object with char field":
    type Letter = object
      ch: char
      code: int

    let l = Letter(ch: 'A', code: 65)

    let result = match l:
      Letter(ch: c, code: n): $c & ":" & $n
      _: "no match"

    check result == "A:65"

  test "Nested Option types":
    let data: Option[Option[int]] = some(some(42))

    let result = match data:
      Some(Some(x)): $x
      Some(None()): "inner none"
      None(): "outer none"

    check result == "42"

  test "Object with array field":
    type Container = object
      items: array[3, int]
      name: string

    let c = Container(items: [1, 2, 3], name: "box")

    let result = match c:
      Container(items: [a, b, c], name: n): n & ":" & $a & "," & $b & "," & $c
      _: "no match"

    check result == "box:1,2,3"

  test "Tuple with mixed primitive types":
    let data = (42, "hello", 3.14, true, 'X')

    let result = match data:
      (n, s, f, b, c): $n & s & $f & $b & $c
      _: "no match"

    check result == "42hello3.14trueX"

  test "Object with nil ref field":
    type
      Node = ref object
        value: int
        next: Node

    let n = Node(value: 42, next: nil)

    let result = match n:
      Node(value: v, next: nil): "terminal:" & $v
      _: "has next"

    check result == "terminal:42"

  test "Object with multiple Option fields":
    type Data = object
      opt1: Option[int]
      opt2: Option[string]

    let d = Data(opt1: some(42), opt2: none(string))

    let result = match d:
      Data(opt1: Some(x), opt2: None()): "partial:" & $x
      Data(opt1: Some(x), opt2: Some(s)): "full:" & $x & ":" & s
      _: "empty"

    check result == "partial:42"

  test "Sequence with all same values":
    let data = @[5, 5, 5, 5]

    let result = match data:
      [a, b, c, d]: $a & $b & $c & $d
      _: "no match"

    check result == "5555"

  test "Object with string field containing special characters":
    type Message = object
      text: string

    let m = Message(text: "hello\nworld\t!")

    let result = match m:
      Message(text: t): t
      _: "no match"

    check result == "hello\nworld\t!"

  test "Wildcard in various positions":
    let data = (1, 2, 3, 4, 5)

    let r1 = match data:
      (_, b, c, d, e): $b & $c & $d & $e
      _: "no match"

    let r2 = match data:
      (a, _, c, d, e): $a & $c & $d & $e
      _: "no match"

    let r3 = match data:
      (a, b, c, d, _): $a & $b & $c & $d
      _: "no match"

    check r1 == "2345"
    check r2 == "1345"
    check r3 == "1234"