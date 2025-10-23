## Union Type Checking Tests
## Tests for holds() type checking procs

import unittest
import ../../union_type

# Define test types at module level
type Result_TypeCheck = union(int, string)
type Value_TypeCheck = union(int, float, string, bool)

suite "Union Type Checking":

  test "holds returns true for correct type":
    let r = Result_TypeCheck.init(42)

    check r.holds(int)
    check not r.holds(string)

  test "holds with string type":
    let r = Result_TypeCheck.init("hello")

    check r.holds(string)
    check not r.holds(int)

  test "holds with multiple types":
    let v = Value_TypeCheck.init(3.14)

    check not v.holds(int)
    check v.holds(float)
    check not v.holds(string)
    check not v.holds(bool)

  test "holds after reassignment":
    var r = Result_TypeCheck.init(42)
    check r.holds(int)

    r = Result_TypeCheck.init("hello")
    check r.holds(string)
    check not r.holds(int)

  test "holds with int":
    let v1 = Value_TypeCheck.init(42)
    check v1.holds(int)
    check not v1.holds(float)

  test "holds with bool":
    let v1 = Value_TypeCheck.init(true)
    check v1.holds(bool)
    check not v1.holds(int)

  test "holds is type-safe":
    let r1 = Result_TypeCheck.init(42)
    let r2 = Result_TypeCheck.init("world")

    # Each holds only its own type
    check r1.holds(int)
    check not r1.holds(string)
    check r2.holds(string)
    check not r2.holds(int)
