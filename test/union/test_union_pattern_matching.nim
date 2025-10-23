## Union Pattern Matching Integration Tests
## Tests pattern matching integration with union types
## Union types ARE variant objects, so they use object constructor patterns
##
## SYNTAX: Union types use EXPLICIT variant syntax only:
## - Explicit: Result_PM(kind: ukInt, val0: v)
##
## Note: Implicit syntax (Result_PM(ukInt(v))) is NOT supported for union types
## because unions use generated type names (UnionType1_int_string) with type aliases.
## The implicit syntax requires the actual type name, not aliases.

import unittest
import strutils
import ../../union_type
import ../../pattern_matching

# Define test types at module level
# Custom types must come before unions that use them
type Point_PM = object
  x, y: int
type Error_PM = object
  code: int
  message: string

# Union types
type Result_PM = union(int, string)
type Value_PM = union(int, float, string, bool)
type Data_PM = union(int, seq[int])
type Shape_PM = union(Point_PM, int, string)
type Result_Error = union(int, string, Error_PM)
type Result_Div = union(int, Error_PM)
type State_PM = union(int, string, bool)
type JsonValue = union(int, string, bool, seq[int])

suite "Union Pattern Matching - Basic Variant Patterns":

  test "simple variant pattern matching with int":
    let r = Result_PM.init(42)

    let msg = match r:
      Result_PM(kind: ukInt, val0: v): "integer: " & $v
      Result_PM(kind: ukString, val1: v): "string: " & v

    check msg == "integer: 42"

  test "variant pattern with string":
    let r = Result_PM.init("hello")

    let msg = match r:
      Result_PM(kind: ukInt, val0: v): "int"
      Result_PM(kind: ukString, val1: v): "string: " & v

    check msg == "string: hello"

  test "variant pattern with multiple types":
    let v = Value_PM.init(3.14)

    let result = match v:
      Value_PM(kind: ukInt, val0: x): "int"
      Value_PM(kind: ukFloat, val1: x): "float: " & $x
      Value_PM(kind: ukString, val2: x): "string"
      Value_PM(kind: ukBool, val3: x): "bool"

    check "3.1" in result  # Float formatting may vary

  test "variant pattern exhaustiveness":
    let r = Result_PM.init(42)

    # All patterns covered
    let msg = match r:
      Result_PM(kind: ukInt, val0: v): "int"
      Result_PM(kind: ukString, val1: v): "string"

    check msg == "int"

suite "Union Pattern Matching - Guards":

  test "guard with comparison":
    let r = Result_PM.init(42)

    let msg = match r:
      Result_PM(kind: ukInt, val0: v) and v > 50: "large"
      Result_PM(kind: ukInt, val0: v) and v > 0: "small"
      Result_PM(kind: ukInt, val0: v): "zero or negative"
      Result_PM(kind: ukString, val1: v): "string"

    check msg == "small"

  test "guard with range":
    let v = Result_PM.init(5)

    let msg = match v:
      Result_PM(kind: ukInt, val0: x) and x in 1..10: "in range"
      Result_PM(kind: ukInt, val0: x): "out of range"
      Result_PM(kind: ukString, val1: x): "string"

    check msg == "in range"

  test "guard with multiple conditions":
    let r = Result_PM.init(75)

    let msg = match r:
      Result_PM(kind: ukInt, val0: v) and v > 70 and v < 80: "70-80"
      Result_PM(kind: ukInt, val0: v) and v > 50: "50+"
      Result_PM(kind: ukInt, val0: v): "other"
      Result_PM(kind: ukString, val1: v): "string"

    check msg == "70-80"

  test "string guard":
    let r = Result_PM.init("hello world")

    let msg = match r:
      Result_PM(kind: ukString, val1: s) and s.len > 10: "long"
      Result_PM(kind: ukString, val1: s) and s.len > 5: "medium"
      Result_PM(kind: ukString, val1: s): "short"
      Result_PM(kind: ukInt, val0: i): "int"

    check msg == "long"

suite "Union Pattern Matching - Complex Types":

  test "custom object in union":
    let v = Shape_PM.init(Point_PM(x: 10, y: 20))

    let msg = match v:
      Shape_PM(kind: ukPoint_PM, val0: p): "point: " & $p.x & "," & $p.y
      Shape_PM(kind: ukInt, val1: i): "int: " & $i
      Shape_PM(kind: ukString, val2: s): "string: " & s

    check msg == "point: 10,20"

  test "nested object pattern":
    let r = Result_Error.init(Error_PM(code: 404, message: "Not Found"))

    let msg = match r:
      Result_Error(kind: ukInt, val0: i): "int"
      Result_Error(kind: ukString, val1: s): "string"
      Result_Error(kind: ukError_PM, val2: e) and e.code == 404: "not found"
      Result_Error(kind: ukError_PM, val2: e): "other error"

    check msg == "not found"

  test "seq in union":
    let d = Data_PM.init(@[1, 2, 3])

    let msg = match d:
      Data_PM(kind: ukInt, val0: i): "single"
      Data_PM(kind: ukSeq_int, val1: s) and s.len > 2: "multiple"
      Data_PM(kind: ukSeq_int, val1: s): "few"

    check msg == "multiple"

suite "Union Pattern Matching - Wildcard and Default":

  test "wildcard pattern":
    let v = Value_PM.init("hello")

    let msg = match v:
      Value_PM(kind: ukInt, val0: i): "int"
      Value_PM(kind: ukFloat, val1: f): "float"
      _: "other"

    check msg == "other"

  test "default case":
    let r = Value_PM.init(true)

    let msg = match r:
      Value_PM(kind: ukInt, val0: i): "int"
      Value_PM(kind: ukString, val2: s): "string"
      _: "other type"

    check msg == "other type"

suite "Union Pattern Matching - Real-World Scenarios":

  test "error handling with union":
    # Result_Div defined at module level

    proc divide(a, b: int): Result_Div =
      if b == 0:
        Result_Div.init(Error_PM(code: 400, message: "division by zero"))
      else:
        Result_Div.init(a div b)

    let r1 = divide(10, 2)
    let r2 = divide(10, 0)

    let msg1 = match r1:
      Result_Div(kind: ukInt, val0: v): "result: " & $v
      Result_Div(kind: ukError_PM, val1: e): "error: " & e.message

    let msg2 = match r2:
      Result_Div(kind: ukInt, val0: v): "result: " & $v
      Result_Div(kind: ukError_PM, val1: e): "error: " & e.message

    check msg1 == "result: 5"
    check msg2 == "error: division by zero"

  test "state machine with union":
    # State_PM defined at module level

    var state = State_PM.init(0)

    # Transition based on current state
    state = match state:
      State_PM(kind: ukInt, val0: i) and i < 10: State_PM.init(i + 1)
      State_PM(kind: ukInt, val0: i): State_PM.init("done")
      State_PM(kind: ukString, val1: s): State_PM.init(true)
      State_PM(kind: ukBool, val2: b): State_PM.init(0)

    check state.holds(int)
    check state.get(int) == 1

  test "json-like value with union":
    # JsonValue defined at module level

    let values = @[
      JsonValue.init(42),
      JsonValue.init("hello"),
      JsonValue.init(true),
      JsonValue.init(@[1, 2, 3])
    ]

    var results: seq[string] = @[]
    for val in values:
      let msg = match val:
        JsonValue(kind: ukInt, val0: i): "int: " & $i
        JsonValue(kind: ukString, val1: s): "string: " & s
        JsonValue(kind: ukBool, val2: b): "bool: " & $b
        JsonValue(kind: ukSeq_int, val3: a): "array: " & $a.len & " items"

      results.add(msg)

    check results[0] == "int: 42"
    check results[1] == "string: hello"
    check results[2] == "bool: true"
    check results[3] == "array: 3 items"
