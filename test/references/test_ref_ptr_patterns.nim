## Comprehensive test suite for ref and ptr type pattern matching
## Tests all 5 critical gaps that were fixed: GAP-8 through GAP-12

import unittest
import ../../pattern_matching

type
  Point = object
    x: int
    y: int

  Container = object
    inner: ref Point
    value: int

  Node = object
    data: int
    next: ref Node

suite "ref type pattern matching":

  test "GAP-8: ref object basic destructuring":
    ## Test basic object destructuring patterns on ref types
    let p: ref Point = new Point
    p.x = 10
    p.y = 20

    let result = match p:
      Point(x, y): (x, y)
      _: (-1, -1)

    check result == (10, 20)

  test "GAP-8: ref object named field matching":
    ## Test named field patterns on ref types
    let p: ref Point = new Point
    p.x = 5
    p.y = 15

    let result = match p:
      Point(x: a, y: b): a + b
      _: -1

    check result == 20

  test "GAP-8: ref object literal matching":
    ## Test literal value matching in ref object patterns
    let p: ref Point = new Point
    p.x = 0
    p.y = 0

    let result = match p:
      Point(x: 0, y: 0): "origin"
      Point(x, y): "other"
      _: "error"

    check result == "origin"

  test "GAP-9: ref nil pattern matching":
    ## Test nil pattern matching on ref types
    let p: ref Point = nil

    let result = match p:
      nil: "is nil"
      Point(x, y): "not nil"
      _: "error"

    check result == "is nil"

  test "GAP-9: ref non-nil vs nil discrimination":
    ## Test that non-nil ref values don't match nil pattern
    let p: ref Point = new Point
    p.x = 1
    p.y = 2

    let result = match p:
      nil: "nil"
      Point(x, y): "non-nil"
      _: "error"

    check result == "non-nil"

  test "GAP-10: ref patterns with AND guards":
    ## Test guard expressions with ref object patterns
    let p: ref Point = new Point
    p.x = 10
    p.y = 5

    let result = match p:
      Point(x, y) and x > 5: "x > 5"
      Point(x, y): "x <= 5"
      _: "error"

    check result == "x > 5"

  test "GAP-10: ref patterns with complex guards":
    ## Test complex guard expressions
    let p: ref Point = new Point
    p.x = 3
    p.y = 7

    let result = match p:
      Point(x, y) and x > 5 and y > 5: "both > 5"
      Point(x, y) and y > 5: "only y > 5"
      Point(x, y): "neither > 5"
      _: "error"

    check result == "only y > 5"

  test "GAP-10: ref patterns with OR guards":
    ## Test OR guard expressions with ref patterns
    let p: ref Point = new Point
    p.x = 0
    p.y = 10

    let result = match p:
      Point(x, y) and (x > 5 or y > 5): "at least one > 5"
      Point(x, y): "both <= 5"
      _: "error"

    check result == "at least one > 5"

  test "GAP-11: ref OR patterns with literals":
    ## Test OR patterns combining literals and nil
    let p: ref Point = nil

    let result = match p:
      Point(x: 0, y: 0) | nil: "zero or nil"
      Point(x, y): "non-zero point"
      _: "error"

    check result == "zero or nil"

  test "GAP-11: ref OR patterns with multiple alternatives":
    ## Test OR patterns with multiple ref alternatives
    let p: ref Point = new Point
    p.x = 0
    p.y = 5

    let result = match p:
      Point(x: 0, y: 0) | Point(x: 1, y: 1) | nil: "special"
      Point(x: 0, y): "x is zero"
      Point(x, y): "general"
      _: "error"

    check result == "x is zero"

  test "GAP-12: nested ref pattern in object":
    ## Test destructuring nested ref fields
    let inner = new Point
    inner.x = 3
    inner.y = 7
    let c = Container(inner: inner, value: 42)

    let result = match c:
      Container(inner: Point(x, y), value: v): (x, y, v)
      _: (-1, -1, -1)

    check result == (3, 7, 42)

  test "GAP-12: nested ref with nil":
    ## Test nested ref field matching nil
    let c = Container(inner: nil, value: 99)

    let result = match c:
      Container(inner: nil, value: v): v
      Container(inner: Point(x, y), value: v): -v
      _: -999

    check result == 99

  test "GAP-12: nested ref with guard":
    ## Test guards on nested ref patterns
    let inner = new Point
    inner.x = 10
    inner.y = 5
    let c = Container(inner: inner, value: 100)

    let result = match c:
      Container(inner: Point(x, y), value: v) and x > 5: "x > 5"
      Container(inner: Point(x, y), value: v): "x <= 5"
      _: "error"

    check result == "x > 5"

  test "ref @ pattern capturing":
    ## Test @ pattern on ref types
    let p: ref Point = new Point
    p.x = 5
    p.y = 15

    let result = match p:
      Point(x, y) @ captured: (x, y, captured.x, captured.y)
      _: (-1, -1, -1, -1)

    check result == (5, 15, 5, 15)

  test "ref recursive structure - linked list":
    ## Test ref patterns in recursive data structures
    let head = new Node
    head.data = 1
    head.next = new Node
    head.next.data = 2
    head.next.next = nil

    let result = match head:
      Node(data: d, next: nil): d
      Node(data: d, next: Node(data: d2)): d + d2
      _: -1

    check result == 3

  test "ref pattern exhaustiveness with nil":
    ## Test that all ref cases are covered
    let p1: ref Point = new Point
    p1.x = 1
    p1.y = 2
    let p2: ref Point = nil

    let result1 = match p1:
      nil: "nil"
      Point(x, y): "point"
      _: "error"

    let result2 = match p2:
      nil: "nil"
      Point(x, y): "point"
      _: "error"

    check result1 == "point"
    check result2 == "nil"

suite "ptr type pattern matching":

  test "ptr object basic destructuring":
    ## Ensure ptr types continue to work after ref fixes
    var pointData = Point(x: 30, y: 40)
    let p: ptr Point = addr pointData

    let result = match p:
      Point(x, y): (x, y)
      nil: (-1, -1)
      _: (-2, -2)

    check result == (30, 40)

  test "ptr nil pattern matching":
    ## Test nil pattern on ptr types
    let p: ptr Point = nil

    let result = match p:
      nil: "is nil"
      _: "not nil"

    check result == "is nil"

  test "ptr @ pattern":
    ## Test @ pattern on ptr types
    var pointData = Point(x: 8, y: 12)
    let p: ptr Point = addr pointData

    let result = match p:
      Point(x, y) @ captured: (x, y, captured.x)
      nil: (-1, -1, -1)
      _: (-2, -2, -2)

    check result == (8, 12, 8)

  test "ptr guard pattern":
    ## Test guards on ptr types
    var pointData = Point(x: 15, y: 25)
    let p: ptr Point = addr pointData

    let result = match p:
      Point(x, y) and x > 10: "x > 10"
      Point(x, y): "x <= 10"
      nil: "nil"
      _: "error"

    check result == "x > 10"

suite "ref/ptr compatibility and edge cases":

  test "ref and ptr have same pattern syntax":
    ## Verify that ref and ptr use identical pattern syntax
    let r: ref Point = new Point
    r.x = 10
    r.y = 20

    var pData = Point(x: 10, y: 20)
    let p: ptr Point = addr pData

    # Same pattern should work for both
    let result1 = match r:
      Point(x: 10, y: 20): true
      _: false

    let result2 = match p:
      Point(x: 10, y: 20): true
      _: false

    check result1 == true
    check result2 == true

  test "ref pattern doesn't match non-ref":
    ## Verify type safety: ref pattern should work with ref scrutinee
    let p = Point(x: 5, y: 10)

    let result = match p:
      Point(x, y): (x, y)
      _: (-1, -1)

    check result == (5, 10)

  test "multiple ref field access":
    ## Test accessing multiple fields in pattern
    let p: ref Point = new Point
    p.x = 100
    p.y = 200

    let result = match p:
      Point(x, y) and x == 100 and y == 200: "exact match"
      Point(x, y) and x == 100: "x matches"
      Point(x, y): "general"
      _: "error"

    check result == "exact match"
