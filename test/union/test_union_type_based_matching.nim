## Phase 3: Type-Based Pattern Matching Tests
## Tests for concise union pattern matching: int(v) instead of Result(kind: ukInt, val0: v)

import unittest
import ../../union_type
import ../../pattern_matching

# Test types
type
  Error_TBM = object
    code: int
    message: string

  Point_TBM = object
    x: int
    y: int

# Union types
type Result_TBM = union(int, string, Error_TBM)
type Value_TBM = union(int, float, bool, string)
type Container_TBM = union(int, Point_TBM, seq[int])

suite "Union Type-Based Pattern Matching - Phase 3":

  suite "Basic type-based patterns":

    test "match int with binding":
      let r = Result_TBM.init(42)
      let msg = match r:
        int(v): "int: " & $v
        string(s): "string: " & s
        Error_TBM(e): "error"
      check msg == "int: 42"

    test "match string with binding":
      let r = Result_TBM.init("hello")
      let msg = match r:
        int(v): "int: " & $v
        string(s): "string: " & s
        Error_TBM(e): "error"
      check msg == "string: hello"

    test "match custom type with binding":
      let err = Error_TBM(code: 404, message: "Not Found")
      let r = Result_TBM.init(err)
      let msg = match r:
        int(v): "int: " & $v
        string(s): "string: " & s
        Error_TBM(e): "error: " & $e.code
      check msg == "error: 404"

    test "match without binding - just type check":
      let r = Result_TBM.init(42)
      let hasInt = match r:
        int: true
        _: false
      check hasInt == true

    test "match multiple types without binding":
      let r1 = Value_TBM.init(42)
      let r2 = Value_TBM.init(3.14)
      let r3 = Value_TBM.init(true)

      let m1 = match r1:
        int: "int"
        _: "other"

      let m2 = match r2:
        float: "float"
        _: "other"

      let m3 = match r3:
        bool: "bool"
        _: "other"

      check m1 == "int"
      check m2 == "float"
      check m3 == "bool"

  suite "Type-based patterns with guards":

    test "int pattern with comparison guard":
      let r = Result_TBM.init(42)
      let msg = match r:
        int(v) and v > 100: "large"
        int(v): "small: " & $v
        _: "other"
      check msg == "small: 42"

    test "int pattern with range guard":
      let r = Value_TBM.init(50)
      let msg = match r:
        int(v) and v in 1..10: "tiny"
        int(v) and v in 11..100: "medium"
        int(v): "large"
        _: "other"
      check msg == "medium"

    test "string pattern with guard":
      let r = Result_TBM.init("hello")
      let msg = match r:
        string(s) and s.len > 10: "long string"
        string(s): "short string: " & s
        _: "other"
      check msg == "short string: hello"

    test "multiple conditions in guard":
      let r = Value_TBM.init(42)
      let msg = match r:
        int(v) and v > 0 and v < 100: "positive small"
        int(v): "other int"
        _: "not int"
      check msg == "positive small"

  suite "Complex type patterns":

    test "nested object in union":
      let pt = Point_TBM(x: 10, y: 20)
      let c = Container_TBM.init(pt)
      let msg = match c:
        int(v): "int: " & $v
        Point_TBM(p): "point: " & $p.x & "," & $p.y
        seq[int](s): "seq"
      check msg == "point: 10,20"

    test "sequence pattern in union":
      let items = @[1, 2, 3]
      let c = Container_TBM.init(items)
      let msg = match c:
        int(v): "int"
        Point_TBM(p): "point"
        seq[int](s): "seq len: " & $s.len
      check msg == "seq len: 3"

    test "accessing fields from matched object":
      let err = Error_TBM(code: 500, message: "Internal Error")
      let r = Result_TBM.init(err)
      let info = match r:
        int(v): ("int", v, "")
        string(s): ("string", 0, s)
        Error_TBM(e): ("error", e.code, e.message)

      check info[0] == "error"
      check info[1] == 500
      check info[2] == "Internal Error"

  suite "Pattern ordering and exhaustiveness":

    test "first matching pattern wins":
      let r = Value_TBM.init(42)
      let msg = match r:
        int(v) and v > 0: "positive"
        int(v): "any int"  # This won't be reached for positive
        _: "other"
      check msg == "positive"

    test "wildcard catches unmatched":
      let r = Value_TBM.init("text")
      let msg = match r:
        int(v): "int"
        float(f): "float"
        _: "other"
      check msg == "other"

    test "all types covered without wildcard":
      let r1 = Result_TBM.init(42)
      let r2 = Result_TBM.init("hello")
      let r3 = Result_TBM.init(Error_TBM(code: 1, message: "err"))

      let m1 = match r1:
        int(v): "int"
        string(s): "string"
        Error_TBM(e): "error"

      let m2 = match r2:
        int(v): "int"
        string(s): "string"
        Error_TBM(e): "error"

      let m3 = match r3:
        int(v): "int"
        string(s): "string"
        Error_TBM(e): "error"

      check m1 == "int"
      check m2 == "string"
      check m3 == "error"

  suite "Edge cases and special scenarios":

    test "match with zero values":
      let r = Value_TBM.init(0)
      let msg = match r:
        int(v) and v == 0: "zero"
        int(v): "nonzero"
        _: "other"
      check msg == "zero"

    test "match with negative values":
      let r = Value_TBM.init(-42)
      let msg = match r:
        int(v) and v < 0: "negative: " & $v
        int(v): "positive"
        _: "other"
      check msg == "negative: -42"

    test "match with empty string":
      let r = Result_TBM.init("")
      let msg = match r:
        string(s) and s.len == 0: "empty"
        string(s): "nonempty"
        _: "other"
      check msg == "empty"

    test "match with boolean values":
      let r1 = Value_TBM.init(true)
      let r2 = Value_TBM.init(false)

      let m1 = match r1:
        bool(b) and b: "true"
        bool(b): "false"
        _: "other"

      let m2 = match r2:
        bool(b) and b: "true"
        bool(b): "false"
        _: "other"

      check m1 == "true"
      check m2 == "false"

    test "match returns value from expression":
      let r = Result_TBM.init(10)
      let doubled = match r:
        int(v): v * 2
        _: 0
      check doubled == 20

    test "nested matches possible":
      let r = Result_TBM.init(42)
      let category = match r:
        int(v):
          if v < 10: "small"
          elif v < 100: "medium"
          else: "large"
        _: "unknown"
      check category == "medium"

  suite "Backwards compatibility":

    test "explicit variant syntax still works":
      let r = Result_TBM.init(42)
      let msg = match r:
        Result_TBM(kind: ukInt, val0: v): "int: " & $v
        Result_TBM(kind: ukString, val1: s): "string: " & s
        _: "other"
      check msg == "int: 42"

    test "mixing old and new syntax":
      let r = Result_TBM.init("hello")
      let msg = match r:
        int(v): "int (new syntax)"
        Result_TBM(kind: ukString, val1: s): "string (old syntax): " & s
        _: "other"
      check msg == "string (old syntax): hello"
