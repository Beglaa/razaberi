## Test: Variant DSL Equality - Missing == Operator Error Detection
##
## Tests that variant DSL generates helpful compile-time errors when field types
## lack equality operators, and verifies the solution works correctly.

import unittest
import ../../variant_dsl

# ============================================================================
# Test 1: Manual variant object WITHOUT == (should produce error)
# ============================================================================

type
  ColorKind = enum ckRed, ckGreen, ckBlue
  Color = object
    case kind: ColorKind
    of ckRed: rVal: int
    of ckGreen: gVal: int
    of ckBlue: bVal: int

# This SHOULD fail with helpful error message:
# Uncomment to see the error:
#
# variant Container:
#   Empty()
#   WithColor(color: Color)
#
# Expected error:
# Type 'Color' in variant 'Container' requires an explicit equality operator (==).
#
#   Field: color (type: Color)
#   Variant: Container
#
#   Solution: Define a custom `==` operator for type 'Color'
#
#   Example:
#   proc `==`(a, b: Color): bool =
#     # Compare fields of Color
#     # For variant objects, check discriminator first
#     # For regular objects, compare all fields
#     result = ... # your comparison logic

# ============================================================================
# Test 2: Manual variant object WITH == (should work)
# ============================================================================

type
  ShapeKind = enum skCircle, skRectangle
  Shape = object
    case kind: ShapeKind
    of skCircle: radius: float
    of skRectangle: width, height: float

# Define custom == operator for Shape (variant object)
proc `==`(a, b: Shape): bool =
  if a.kind != b.kind:
    return false

  case a.kind:
  of skCircle:
    result = a.radius == b.radius
  of skRectangle:
    result = a.width == b.width and a.height == b.height

suite "Variant Equality - Missing Operator Error Detection":

  test "variant with field type that HAS == compiles successfully":
    variant Geometry:
      EmptyGeometry()
      WithShape(shape: Shape)

    # Should compile and work
    let g1 = Geometry.WithShape(Shape(kind: skCircle, radius: 5.0))
    let g2 = Geometry.WithShape(Shape(kind: skCircle, radius: 5.0))
    let g3 = Geometry.WithShape(Shape(kind: skCircle, radius: 10.0))

    # Equality should work
    check g1 == g2
    check g1 != g3

  test "variant with multiple field types all having == works":
    type
      Point = object
        x, y: int

    proc `==`(a, b: Point): bool =
      a.x == b.x and a.y == b.y

    variant Container:
      OnlyPoint(point: Point)
      OnlyShape(shape: Shape)
      Both(p: Point, s: Shape)

    let c1 = Container.Both(Point(x: 1, y: 2), Shape(kind: skCircle, radius: 5.0))
    let c2 = Container.Both(Point(x: 1, y: 2), Shape(kind: skCircle, radius: 5.0))
    let c3 = Container.Both(Point(x: 1, y: 2), Shape(kind: skCircle, radius: 10.0))

    check c1 == c2
    check c1 != c3

  test "nested variant DSL types work (both have generated ==)":
    variant Inner:
      IntValue(x: int)
      StrValue(s: string)

    variant Outer:
      Empty()
      WithInner(inner: Inner)

    let o1 = Outer.WithInner(Inner.IntValue(42))
    let o2 = Outer.WithInner(Inner.IntValue(42))
    let o3 = Outer.WithInner(Inner.IntValue(99))

    check o1 == o2
    check o1 != o3

  test "regular object with == works in variant":
    type
      Person = object
        name: string
        age: int

    proc `==`(a, b: Person): bool =
      a.name == b.name and a.age == b.age

    variant Record:
      NoPerson()
      WithPerson(person: Person)

    let r1 = Record.WithPerson(Person(name: "Alice", age: 30))
    let r2 = Record.WithPerson(Person(name: "Alice", age: 30))
    let r3 = Record.WithPerson(Person(name: "Bob", age: 30))

    check r1 == r2
    check r1 != r3

  test "primitive types in variants work (have default ==)":
    variant Data:
      IntData(value: int)
      StrData(text: string)
      BoolData(flag: bool)

    let d1 = Data.IntData(42)
    let d2 = Data.IntData(42)
    let d3 = Data.IntData(99)

    check d1 == d2
    check d1 != d3

  test "seq types in variants work (have default ==)":
    variant Collection:
      Empty()
      IntList(ints: seq[int])
      StrList(strings: seq[string])

    let c1 = Collection.IntList(@[1, 2, 3])
    let c2 = Collection.IntList(@[1, 2, 3])
    let c3 = Collection.IntList(@[1, 2, 3, 4])

    check c1 == c2
    check c1 != c3
