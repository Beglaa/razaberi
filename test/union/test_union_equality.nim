## Union Equality Tests
## Tests for == operator

import unittest
import ../../union_type

# Define test types at module level
# Point type must be defined before union that uses it
type Point_Equality = object
  x, y: int

type Result_Equality = union(int, string)
type Value_Equality = union(int, Point_Equality)
type Multi_Equality = union(int, float, string)

suite "Union Equality":

  test "equal values of same type":
    let r1 = Result_Equality.init(42)
    let r2 = Result_Equality.init(42)

    check r1 == r2

  test "unequal values of same type":
    let r1 = Result_Equality.init(42)
    let r2 = Result_Equality.init(99)

    check r1 != r2

  test "values of different types are not equal":
    let r1 = Result_Equality.init(42)
    let r2 = Result_Equality.init("hello")

    check r1 != r2

  test "string equality":
    let r1 = Result_Equality.init("hello")
    let r2 = Result_Equality.init("hello")
    let r3 = Result_Equality.init("world")

    check r1 == r2
    check r1 != r3

  test "custom type equality":
    let v1 = Value_Equality.init(Point_Equality(x: 1, y: 2))
    let v2 = Value_Equality.init(Point_Equality(x: 1, y: 2))
    let v3 = Value_Equality.init(Point_Equality(x: 3, y: 4))

    check v1 == v2
    check v1 != v3

  test "int vs custom type not equal":
    let v1 = Value_Equality.init(42)
    let v2 = Value_Equality.init(Point_Equality(x: 1, y: 2))

    check v1 != v2

  test "multiple type equality":
    let m1 = Multi_Equality.init(42)
    let m2 = Multi_Equality.init(42)
    let m3 = Multi_Equality.init(3.14)
    let m4 = Multi_Equality.init("hello")

    check m1 == m2
    check m1 != m3
    check m1 != m4
    check m3 != m4

  test "float equality":
    let m1 = Multi_Equality.init(3.14)
    let m2 = Multi_Equality.init(3.14)
    let m3 = Multi_Equality.init(2.71)

    check m1 == m2
    check m1 != m3

  test "empty string equality":
    let r1 = Result_Equality.init("")
    let r2 = Result_Equality.init("")
    let r3 = Result_Equality.init("a")

    check r1 == r2
    check r1 != r3

  test "zero values equality":
    let r1 = Result_Equality.init(0)
    let r2 = Result_Equality.init(0)
    let r3 = Result_Equality.init(1)

    check r1 == r2
    check r1 != r3
