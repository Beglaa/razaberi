import std/unittest
import ../../pattern_matching
import ../helper/ccheck

suite "Type Pattern Syntax Tests (string(x), int(y), float(z))":
  test "should support string(x) type pattern":
    let value: auto = "hello"
    let result = match value:
      int(i): "Integer: " & $i
      string(s): "String: " & $s
      float(f): "Float: " & $f
      _: "Unknown"
    check(result == "String: hello")

  test "should support int(x) type pattern":
    let value: auto = 42
    let result = match value:
      string(s): "String: " & $s
      int(i): "Integer: " & $i
      float(f): "Float: " & $f
      _: "Unknown"
    check(result == "Integer: 42")

  test "should support float(x) type pattern":
    let value: auto = 3.14
    let result = match value:
      int(i): "Integer: " & $i
      float(f): "Float: " & $f
      string(s): "String: " & $s
      _: "Unknown"
    check(result == "Float: 3.14")

  test "should support bool(x) type pattern":
    let value: auto = true
    let result = match value:
      bool(b): "Boolean: " & $b
      int(i): "Integer: " & $i
      _: "Unknown"
    check(result == "Boolean: true")

  test "should support char(x) type pattern":
    let value: auto = 'X'
    let result = match value:
      char(c): "Char: " & c
      string(s): "String: " & $s
      _: "Unknown"
    check(result == "Char: X")

  test "should support int8(x) type pattern":
    let value: int8 = 127
    let result = match value:
      int8(i): "Int8: " & $i
      int(i): "Int: " & $i
      _: "Unknown"
    check(result == "Int8: 127")

  test "should support int16(x) type pattern":
    let value: int16 = 32767
    let result = match value:
      int16(i): "Int16: " & $i
      int(i): "Int: " & $i
      _: "Unknown"
    check(result == "Int16: 32767")

  test "should support int32(x) type pattern":
    let value: int32 = 2147483647
    let result = match value:
      int32(i): "Int32: " & $i
      int(i): "Int: " & $i
      _: "Unknown"
    check(result == "Int32: 2147483647")

  test "should support int64(x) type pattern":
    let value: int64 = 9223372036854775807'i64
    let result = match value:
      int64(i): "Int64: " & $i
      int(i): "Int: " & $i
      _: "Unknown"
    check(result == "Int64: 9223372036854775807")

  test "should support uint(x) type pattern":
    let value: uint = 42'u
    let result = match value:
      uint(u): "Uint: " & $u
      int(i): "Int: " & $i
      _: "Unknown"
    check(result == "Uint: 42")

  test "should support float32(x) type pattern":
    let value: float32 = 3.14'f32
    let result = match value:
      float32(f): "Float32: " & $f
      float(f): "Float: " & $f
      _: "Unknown"
    check(result == "Float32: 3.14")

  test "should support float64(x) type pattern":
    let value: float64 = 2.718'f64
    let result = match value:
      float64(f): "Float64: " & $f
      float(f): "Float: " & $f
      _: "Unknown"
    check(result == "Float64: 2.718")

  test "should support byte(x) type pattern":
    let value: byte = 255
    let result = match value:
      byte(b): "Byte: " & $b
      int(i): "Int: " & $i
      _: "Unknown"
    check(result == "Byte: 255")

  test "should support wildcard in type patterns":
    let value: auto = 42
    let result = match value:
      string(_): "Some string"
      int(_): "Some int"
      _: "Unknown"
    check(result == "Some int")

  test "should support type patterns with guards":
    let value: auto = 42
    let result = match value:
      int(i) and i > 50: "Large int: " & $i
      int(i) and i > 0: "Positive int: " & $i
      int(i): "Int: " & $i
      _: "Unknown"
    check(result == "Positive int: 42")

  test "should support nested type patterns in tuples":
    let value: (string, int) = ("hello", 42)
    let result = match value:
      (string(s), int(i)): s & ": " & $i
      _: "No match"
    check(result == "hello: 42")

  test "should fallback to wildcard when no type matches":
    let value: auto = 42
    let result = match value:
      string(s): "String: " & $s
      bool(b): "Bool: " & $b
      _: "Fallback"
    check(result == "Fallback")

  test "should work with multiple type patterns":
    proc testValue(value: auto): string =
      match value:
        string(s): "String: " & $s
        int(i): "Int: " & $i
        float(f): "Float: " & $f
        _: "Unknown"

    check(testValue("hello") == "String: hello")
    check(testValue(42) == "Int: 42")
    check(testValue(3.14) == "Float: 3.14")

  test "should be equivalent to 'x is string' syntax":
    # Both syntaxes should produce the same result
    let value: auto = "test"

    let result1 = match value:
      s is string: "String: " & $s
      i is int: "Int: " & $i
      _: "Unknown"

    let result2 = match value:
      string(s): "String: " & $s
      int(i): "Int: " & $i
      _: "Unknown"

    check(result1 == result2)
    check(result1 == "String: test")

# Union type compatibility tests are in test/union/test_union_pattern_matching.nim
# The type pattern syntax (string(x), int(y), etc.) properly distinguishes between:
# 1. Union variant extraction: union(int, string) matched with string(x) extracts string variant
# 2. Type checking: normal values matched with string(x) checks if value is string type
# This distinction is made using structural metadata queries (ckVariantObject vs ckSimpleType)
