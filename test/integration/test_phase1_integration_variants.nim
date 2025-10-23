## Phase 1 Integration Tests - Variant Objects
## Tests variant (discriminated union) objects with structural validation

import unittest
import ../../pattern_matching

suite "Phase 1 Integration - Variant Objects":

  test "Simple variant object matching":
    type
      Kind = enum kInt, kStr, kFloat
      Value = object
        case kind: Kind
        of kInt: intVal: int
        of kStr: strVal: string
        of kFloat: floatVal: float

    let v1 = Value(kind: kInt, intVal: 42)
    let v2 = Value(kind: kStr, strVal: "hello")
    let v3 = Value(kind: kFloat, floatVal: 3.14)

    let r1 = match v1:
      Value(kind: kInt, intVal: x): $x
      _: "other"

    let r2 = match v2:
      Value(kind: kStr, strVal: s): s
      _: "other"

    let r3 = match v3:
      Value(kind: kFloat, floatVal: f): $f
      _: "other"

    check r1 == "42"
    check r2 == "hello"
    check r3 == "3.14"

  test "Variant with sequence field":
    type
      Kind = enum kSingle, kMultiple
      Data = object
        case kind: Kind
        of kSingle: value: int
        of kMultiple: values: seq[int]

    let d1 = Data(kind: kSingle, value: 100)
    let d2 = Data(kind: kMultiple, values: @[1, 2, 3])

    let r1 = match d1:
      Data(kind: kSingle, value: v): $v
      _: "other"

    let r2 = match d2:
      Data(kind: kMultiple, values: [a, b, c]): $a & "," & $b & "," & $c
      _: "other"

    check r1 == "100"
    check r2 == "1,2,3"

  test "Nested variant objects":
    type
      InnerKind = enum ikA, ikB
      Inner = object
        case kind: InnerKind
        of ikA: valA: int
        of ikB: valB: string

      OuterKind = enum okX, okY
      Outer = object
        case kind: OuterKind
        of okX: innerX: Inner
        of okY: valY: float

    let obj1 = Outer(kind: okX, innerX: Inner(kind: ikA, valA: 99))
    let obj2 = Outer(kind: okX, innerX: Inner(kind: ikB, valB: "test"))
    let obj3 = Outer(kind: okY, valY: 2.5)

    let r1 = match obj1:
      Outer(kind: okX, innerX: Inner(kind: ikA, valA: v)): "A:" & $v
      _: "other"

    let r2 = match obj2:
      Outer(kind: okX, innerX: Inner(kind: ikB, valB: v)): "B:" & v
      _: "other"

    let r3 = match obj3:
      Outer(kind: okY, valY: v): "Y:" & $v
      _: "other"

    check r1 == "A:99"
    check r2 == "B:test"
    check r3 == "Y:2.5"

  test "Variant with multiple branches":
    type
      NodeKind = enum nkEmpty, nkLeaf, nkBranch, nkTree
      Node = object
        case kind: NodeKind
        of nkEmpty: discard
        of nkLeaf: leafValue: int
        of nkBranch:
          left: int
          right: int
        of nkTree:
          nodes: seq[int]
          name: string

    let n1 = Node(kind: nkEmpty)
    let n2 = Node(kind: nkLeaf, leafValue: 42)
    let n3 = Node(kind: nkBranch, left: 10, right: 20)
    let n4 = Node(kind: nkTree, nodes: @[1, 2, 3], name: "root")

    let r1 = match n1:
      Node(kind: nkEmpty): "empty"
      _: "other"

    let r2 = match n2:
      Node(kind: nkLeaf, leafValue: v): "leaf:" & $v
      _: "other"

    let r3 = match n3:
      Node(kind: nkBranch, left: l, right: r): "branch:" & $l & "," & $r
      _: "other"

    let r4 = match n4:
      Node(kind: nkTree, nodes: [a, b, c], name: n): "tree:" & n & ":" & $a & "," & $b & "," & $c
      _: "other"

    check r1 == "empty"
    check r2 == "leaf:42"
    check r3 == "branch:10,20"
    check r4 == "tree:root:1,2,3"

  test "Variant object in tuple":
    type
      Kind = enum kInt, kStr
      Value = object
        case kind: Kind
        of kInt: intVal: int
        of kStr: strVal: string

    let data = (Value(kind: kInt, intVal: 100), "label")

    let result = match data:
      (Value(kind: kInt, intVal: v), label): label & ":" & $v
      _: "other"

    check result == "label:100"

  test "Sequence of variant objects":
    type
      Kind = enum kInt, kStr
      Value = object
        case kind: Kind
        of kInt: intVal: int
        of kStr: strVal: string

    let items = @[
      Value(kind: kInt, intVal: 10),
      Value(kind: kStr, strVal: "hello")
    ]

    # Match first element
    let r1 = match items:
      [Value(kind: kInt, intVal: v), _]: $v
      _: "other"

    # Match second element
    let r2 = match items:
      [_, Value(kind: kStr, strVal: s)]: s
      _: "other"

    check r1 == "10"
    check r2 == "hello"

  test "Complex variant with nested structures":
    type
      DataKind = enum dkSimple, dkComplex
      Data = object
        case kind: DataKind
        of dkSimple:
          value: int
        of dkComplex:
          values: seq[int]
          metadata: (string, int)

    let d = Data(kind: dkComplex, values: @[1, 2, 3], metadata: ("test", 100))

    let result = match d:
      Data(kind: dkComplex, values: [a, b, c], metadata: (label, count)):
        label & ":" & $a & "," & $b & "," & $c & ":" & $count
      _: "other"

    check result == "test:1,2,3:100"

  test "3-level nested variant objects":
    type
      L3Kind = enum l3A, l3B
      L3 = object
        case kind: L3Kind
        of l3A: valA: int
        of l3B: valB: string

      L2Kind = enum l2X, l2Y
      L2 = object
        case kind: L2Kind
        of l2X: l3x: L3
        of l2Y: valY: float

      L1Kind = enum l1P, l1Q
      L1 = object
        case kind: L1Kind
        of l1P: l2p: L2
        of l1Q: valQ: bool

    let obj = L1(kind: l1P, l2p: L2(kind: l2X, l3x: L3(kind: l3A, valA: 777)))

    let result = match obj:
      L1(kind: l1P, l2p: L2(kind: l2X, l3x: L3(kind: l3A, valA: v))): $v
      _: "other"

    check result == "777"

  test "Variant with guards":
    type
      Kind = enum kInt, kStr
      Value = object
        case kind: Kind
        of kInt: intVal: int
        of kStr: strVal: string

    let v1 = Value(kind: kInt, intVal: 100)
    let v2 = Value(kind: kInt, intVal: 50)

    let r1 = match v1:
      Value(kind: kInt, intVal: v) and v > 75: "high:" & $v
      Value(kind: kInt, intVal: v): "low:" & $v
      _: "other"

    let r2 = match v2:
      Value(kind: kInt, intVal: v) and v > 75: "high:" & $v
      Value(kind: kInt, intVal: v): "low:" & $v
      _: "other"

    check r1 == "high:100"
    check r2 == "low:50"