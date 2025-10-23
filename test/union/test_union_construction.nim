## Union Construction Tests
## Tests for type-scoped init() constructor procs

import unittest
import options
import ../../union_type

# Define test types at module level
# Error type must be defined before union that uses it
type Error_Construct = object
  message: string

type Result_Construct = union(int, string)
type Response_Construct = union(int, Error_Construct)
type Data_Construct = union(int, seq[int])
type Value_Construct = union(int, float, string)

suite "Union Construction":

  test "init with int value":
    let r = Result_Construct.init(42)
    check r.kind is enum

  test "init with string value":
    let s = Result_Construct.init("hello")
    check s.kind is enum

  test "init with custom type":
    let e = Response_Construct.init(Error_Construct(message: "failed"))
    check e.kind is enum

  test "init with generic type":
    let d = Data_Construct.init(@[1, 2, 3])
    check d.kind is enum

  test "init overload resolution":
    let v1 = Value_Construct.init(42)       # int
    let v2 = Value_Construct.init(3.14)     # float
    let v3 = Value_Construct.init("hello")  # string

    check v1.kind != v2.kind
    check v2.kind != v3.kind
    check v1.kind != v3.kind

  test "init with seq type":
    let d1 = Data_Construct.init(@[1, 2, 3])
    let d2 = Data_Construct.init(42)

    check d1.kind != d2.kind

  test "init preserves value type":
    # Values should be retrievable later (tested in value_access)
    let r1 = Result_Construct.init(42)
    let r2 = Result_Construct.init("world")

    # Different constructors produce different discriminators
    check r1.kind != r2.kind
