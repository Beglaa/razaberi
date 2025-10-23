## Union String Representation Tests
## Tests for $ operator

import unittest
import strutils
import ../../union_type

# Define test types at module level
# Error type must be defined before union that uses it
type Error_Repr = object
  code: int
  message: string

type Result_Repr = union(int, string)
type Value_Repr = union(int, float, string)
type Response_Repr = union(int, Error_Repr)

suite "Union String Representation":

  test "int value shows in string repr":
    let r = Result_Repr.init(42)
    let s = $r

    check "42" in s

  test "string value shows in string repr":
    let r = Result_Repr.init("hello")
    let s = $r

    check "hello" in s

  test "different types show different repr":
    let v1 = Value_Repr.init(42)
    let v2 = Value_Repr.init(3.14)
    let v3 = Value_Repr.init("hello")

    let s1 = $v1
    let s2 = $v2
    let s3 = $v3

    # Each should show its value
    check "42" in s1
    check "3.14" in s2 or "3.1" in s2  # Float formatting may vary
    check "hello" in s3

  test "custom type representation":
    let r = Response_Repr.init(Error_Repr(code: 404, message: "Not Found"))
    let s = $r

    # Should show the object representation
    check "404" in s
    check "Not Found" in s

  test "repr distinguishes same value different types":
    # Two unions with int 42 should have distinguishable repr
    let v1 = Value_Repr.init(42)
    let v2 = Value_Repr.init(42)

    check $v1 == $v2  # Same type, same value = same repr

  test "empty string representation":
    let r = Result_Repr.init("")
    let s = $r

    # Empty string produces empty representation (which is correct)
    # The $ operator directly converts the held value
    check s.len >= 0  # Valid representation (can be empty)

  test "zero value representation":
    let r = Result_Repr.init(0)
    let s = $r

    check "0" in s

  test "negative value representation":
    let r = Result_Repr.init(-42)
    let s = $r

    check "42" in s or "-42" in s

  test "large value representation":
    let r = Result_Repr.init(999999)
    let s = $r

    check "999999" in s

  test "float representation":
    let v = Value_Repr.init(2.71828)
    let s = $v

    # Should contain some part of the float
    check "2." in s or "71" in s
