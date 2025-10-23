## Test-Driven Development: Variant Equality Operator Generation
##
## This test file defines the expected behavior for automatically generated
## equality operators on variant objects created through variant_dsl.nim.
##
## Testing Strategy:
## 1. Zero-parameter variants (no fields)
## 2. Single-parameter variants (one field per case)
## 3. Multi-parameter variants (multiple fields per case)
## 4. Nested variants (variants containing other variants)
## 5. Complex field types (objects, sequences, etc.)
## 6. Mixed variants (some empty, some with fields)

import unittest
import ../../variant_dsl

# Test 1: Zero-parameter variants
variant Signal:
  Ready()
  NotReady()

suite "Variant Equality - Zero Parameter":
  test "same discriminator, no fields - should be equal":
    let sig1 = Signal.Ready()
    let sig2 = Signal.Ready()
    check sig1 == sig2

  test "different discriminator - should not be equal":
    let sig1 = Signal.Ready()
    let sig2 = Signal.NotReady()
    check sig1 != sig2

# Test 2: Single-parameter variants
variant SimpleValue:
  IntValue(x: int)
  StrValue(s: string)
  BoolValue(b: bool)

suite "Variant Equality - Single Parameter":
  test "same discriminator, same field value - should be equal":
    let v1 = SimpleValue.IntValue(42)
    let v2 = SimpleValue.IntValue(42)
    check v1 == v2

  test "same discriminator, different field value - should not be equal":
    let v1 = SimpleValue.IntValue(42)
    let v2 = SimpleValue.IntValue(99)
    check v1 != v2

  test "different discriminator - should not be equal":
    let v1 = SimpleValue.IntValue(42)
    let v2 = SimpleValue.StrValue("42")
    check v1 != v2

  test "string field - same value should be equal":
    let v1 = SimpleValue.StrValue("hello")
    let v2 = SimpleValue.StrValue("hello")
    check v1 == v2

  test "string field - different value should not be equal":
    let v1 = SimpleValue.StrValue("hello")
    let v2 = SimpleValue.StrValue("world")
    check v1 != v2

# Test 3: Multi-parameter variants
# Note: Nim requires different field names in different variant branches
variant Point:
  Point2D(x2d: int, y2d: int)
  Point3D(x3d: int, y3d: int, z3d: int)

suite "Variant Equality - Multi Parameter":
  test "2D points - same coordinates should be equal":
    let p1 = Point.Point2D(10, 20)
    let p2 = Point.Point2D(10, 20)
    check p1 == p2

  test "2D points - different x should not be equal":
    let p1 = Point.Point2D(10, 20)
    let p2 = Point.Point2D(99, 20)
    check p1 != p2

  test "2D points - different y should not be equal":
    let p1 = Point.Point2D(10, 20)
    let p2 = Point.Point2D(10, 99)
    check p1 != p2

  test "3D points - all fields same should be equal":
    let p1 = Point.Point3D(1, 2, 3)
    let p2 = Point.Point3D(1, 2, 3)
    check p1 == p2

  test "3D points - z differs should not be equal":
    let p1 = Point.Point3D(1, 2, 3)
    let p2 = Point.Point3D(1, 2, 99)
    check p1 != p2

  test "2D vs 3D - different discriminator should not be equal":
    let p1 = Point.Point2D(10, 20)
    let p2 = Point.Point3D(10, 20, 0)
    check p1 != p2

# Test 4: Mixed variants (some empty, some with fields)
# Note: Field names must be unique across all branches in Nim
variant Status:
  Idle()
  Processing(procTaskId: int)
  Complete(completeTaskId: int, message: string)
  Failed()

suite "Variant Equality - Mixed":
  test "empty variant - same discriminator should be equal":
    let s1 = Status.Idle()
    let s2 = Status.Idle()
    check s1 == s2

  test "empty variant - different discriminator should not be equal":
    let s1 = Status.Idle()
    let s2 = Status.Failed()
    check s1 != s2

  test "single field - same value should be equal":
    let s1 = Status.Processing(100)
    let s2 = Status.Processing(100)
    check s1 == s2

  test "single field - different value should not be equal":
    let s1 = Status.Processing(100)
    let s2 = Status.Processing(200)
    check s1 != s2

  test "multi field - both fields same should be equal":
    let s1 = Status.Complete(100, "success")
    let s2 = Status.Complete(100, "success")
    check s1 == s2

  test "multi field - first field differs should not be equal":
    let s1 = Status.Complete(100, "success")
    let s2 = Status.Complete(200, "success")
    check s1 != s2

  test "multi field - second field differs should not be equal":
    let s1 = Status.Complete(100, "success")
    let s2 = Status.Complete(100, "failed")
    check s1 != s2

  test "empty vs field - different discriminator should not be equal":
    let s1 = Status.Idle()
    let s2 = Status.Processing(1)
    check s1 != s2

# Test 5: Complex field types
type
  Record = object
    id: int
    name: string

variant Container:
  Empty()
  Single(item: Record)
  Multiple(items: seq[int])

suite "Variant Equality - Complex Types":
  test "object field - same record should be equal":
    let c1 = Container.Single(Record(id: 1, name: "test"))
    let c2 = Container.Single(Record(id: 1, name: "test"))
    check c1 == c2

  test "object field - different id should not be equal":
    let c1 = Container.Single(Record(id: 1, name: "test"))
    let c2 = Container.Single(Record(id: 2, name: "test"))
    check c1 != c2

  test "object field - different name should not be equal":
    let c1 = Container.Single(Record(id: 1, name: "test"))
    let c2 = Container.Single(Record(id: 1, name: "other"))
    check c1 != c2

  test "sequence field - same sequence should be equal":
    let c1 = Container.Multiple(@[1, 2, 3])
    let c2 = Container.Multiple(@[1, 2, 3])
    check c1 == c2

  test "sequence field - different sequence should not be equal":
    let c1 = Container.Multiple(@[1, 2, 3])
    let c2 = Container.Multiple(@[1, 2, 4])
    check c1 != c2

  test "sequence field - different length should not be equal":
    let c1 = Container.Multiple(@[1, 2, 3])
    let c2 = Container.Multiple(@[1, 2])
    check c1 != c2

# Test 6: Nested variants
variant Inner:
  InnerA(aValue: int)
  InnerB(bText: string)

variant Outer:
  OuterEmpty()
  OuterNested(nestedInner: Inner)
  OuterDual(firstInner: Inner, secondInner: Inner)

suite "Variant Equality - Nested Variants":
  test "nested variant - same inner variant should be equal":
    let o1 = Outer.OuterNested(Inner.InnerA(42))
    let o2 = Outer.OuterNested(Inner.InnerA(42))
    check o1 == o2

  test "nested variant - different inner value should not be equal":
    let o1 = Outer.OuterNested(Inner.InnerA(42))
    let o2 = Outer.OuterNested(Inner.InnerA(99))
    check o1 != o2

  test "nested variant - different inner discriminator should not be equal":
    let o1 = Outer.OuterNested(Inner.InnerA(42))
    let o2 = Outer.OuterNested(Inner.InnerB("42"))
    check o1 != o2

  test "dual nested - both same should be equal":
    let o1 = Outer.OuterDual(Inner.InnerA(1), Inner.InnerB("test"))
    let o2 = Outer.OuterDual(Inner.InnerA(1), Inner.InnerB("test"))
    check o1 == o2

  test "dual nested - first differs should not be equal":
    let o1 = Outer.OuterDual(Inner.InnerA(1), Inner.InnerB("test"))
    let o2 = Outer.OuterDual(Inner.InnerA(2), Inner.InnerB("test"))
    check o1 != o2

  test "dual nested - second differs should not be equal":
    let o1 = Outer.OuterDual(Inner.InnerA(1), Inner.InnerB("test"))
    let o2 = Outer.OuterDual(Inner.InnerA(1), Inner.InnerB("other"))
    check o1 != o2

# Test 7: Edge cases
variant Edge:
  Zero(zeroVal: int)
  NegInt(negVal: int)
  EmptyStr(strVal: string)

suite "Variant Equality - Edge Cases":
  test "zero value comparison":
    let e1 = Edge.Zero(0)
    let e2 = Edge.Zero(0)
    check e1 == e2

  test "negative value comparison":
    let e1 = Edge.NegInt(-100)
    let e2 = Edge.NegInt(-100)
    check e1 == e2

  test "negative values differ":
    let e1 = Edge.NegInt(-100)
    let e2 = Edge.NegInt(-200)
    check e1 != e2

  test "empty string comparison":
    let e1 = Edge.EmptyStr("")
    let e2 = Edge.EmptyStr("")
    check e1 == e2

  test "empty vs non-empty string":
    let e1 = Edge.EmptyStr("")
    let e2 = Edge.EmptyStr("x")
    check e1 != e2
