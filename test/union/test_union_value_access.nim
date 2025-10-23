## Union Value Access Tests
## Tests for get() and tryGet() value extraction procs

import unittest
import options
import ../../union_type

# Define test types at module level
type Result_Access = union(int, string)
type Value_Access = union(int, float, string)
type Data_Access = union(int, seq[int])

suite "Union Value Access - get":

  test "get extracts correct int value":
    let r = Result_Access.init(42)
    check r.get(int) == 42

  test "get extracts correct string value":
    let r = Result_Access.init("hello")
    check r.get(string) == "hello"

  test "get raises on wrong type":
    let r = Result_Access.init("hello")

    expect ValueError:
      discard r.get(int)

  test "get with float value":
    let v = Value_Access.init(3.14)
    check v.get(float) == 3.14

  test "get with seq value":
    let d = Data_Access.init(@[1, 2, 3])
    let s = d.get(seq[int])
    check s == @[1, 2, 3]

  test "get error raised for wrong type extraction":
    let v = Value_Access.init(42)

    expect ValueError:
      discard v.get(string)

    expect ValueError:
      discard v.get(float)

suite "Union Value Access - tryGet":

  test "tryGet returns Some for correct type":
    let r = Result_Access.init(42)

    let maybe = r.tryGet(int)
    check maybe.isSome
    check maybe.get() == 42

  test "tryGet returns None for wrong type":
    let r = Result_Access.init(42)

    let maybe = r.tryGet(string)
    check maybe.isNone

  test "tryGet with multiple types":
    let v = Value_Access.init(3.14)

    check v.tryGet(int).isNone
    check v.tryGet(float).isSome
    check v.tryGet(string).isNone
    check v.tryGet(float).get() == 3.14

  test "tryGet with string type":
    let r = Result_Access.init("world")

    let maybe_str = r.tryGet(string)
    let maybe_int = r.tryGet(int)

    check maybe_str.isSome
    check maybe_str.get() == "world"
    check maybe_int.isNone

  test "tryGet with seq type":
    let d = Data_Access.init(@[10, 20, 30])

    let maybe_seq = d.tryGet(seq[int])
    let maybe_int = d.tryGet(int)

    check maybe_seq.isSome
    check maybe_seq.get() == @[10, 20, 30]
    check maybe_int.isNone

  test "tryGet safe pattern":
    let r = Result_Access.init(42)

    # Safe pattern - no exceptions
    if r.tryGet(int).isSome:
      let val = r.tryGet(int).get()
      check val == 42
    else:
      fail()
