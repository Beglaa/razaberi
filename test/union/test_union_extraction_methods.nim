## Phase 2: Type Extraction Methods Tests
## Tests for multiple extraction patterns: toType(), tryType(), expectType(), etc.

import unittest
import options
import strutils
import ../../union_type

# Test types
type
  Error_EM = object
    code: int
    message: string

  User_EM = object
    name: string
    age: int

# Union types for testing
type Result_EM = union(int, string, Error_EM)
type Container_EM = union(int, seq[string], User_EM)
type Number_EM = union(int, float)
type Simple_EM = union(int, string)

suite "Union Type Extraction Methods - Phase 2":

  # ==================== Pattern 1: Conditional Extraction (if statement) ====================

  suite "Pattern 1: Conditional extraction with toType(var)":

    test "toInt extracts int value successfully":
      let r = Result_EM.init(42)
      if r.toInt(x):
        check x == 42
      else:
        fail()

    test "toInt fails when holding different type":
      let r = Result_EM.init("hello")
      var extracted = false
      if r.toInt(x):
        extracted = true
      check not extracted

    test "toInt with mutable binding":
      let r = Simple_EM.init(10)
      if r.toInt(var x):
        check x == 10
        x = 20  # x is mutable with var syntax
        check x == 20
      else:
        fail()

    test "toString extraction":
      let r = Result_EM.init("test")
      if r.toString(s):
        check s == "test"
      else:
        fail()

    test "custom type extraction":
      let err = Error_EM(code: 404, message: "Not Found")
      let r = Result_EM.init(err)
      if r.toError_EM(e):
        check e.code == 404
        check e.message == "Not Found"
      else:
        fail()

    test "seq extraction":
      let items = @["a", "b", "c"]
      let c = Container_EM.init(items)
      if c.toSeq_string(s):
        check s.len == 3
        check s[0] == "a"
      else:
        fail()

    test "extraction without using value":
      let r = Result_EM.init(42)
      if r.toInt(ignored):
        check true  # Just checking type, not using value
      else:
        fail()

  # ==================== Pattern 2: Direct Extraction with Default ====================

  suite "Pattern 2: Extraction with default parameter":

    test "toIntOrDefault(default) returns value when present":
      let r = Number_EM.init(42)
      let value = r.toIntOrDefault(0)
      check value == 42

    test "toIntOrDefault(default) returns default when absent":
      let r = Number_EM.init(3.14)
      let value = r.toIntOrDefault(999)
      check value == 999

    test "toStringOrDefault(default) with empty string default":
      let r = Simple_EM.init(42)
      let text = r.toStringOrDefault("N/A")
      check text == "N/A"

    test "toTypeOrDefault(default) with custom type":
      let r = Container_EM.init(42)
      let defaultUser = User_EM(name: "Unknown", age: 0)
      let user = r.toUser_EMOrDefault(defaultUser)
      check user.name == "Unknown"
      check user.age == 0

    test "extraction with zero as default":
      let r = Number_EM.init(3.14)
      let value = r.toIntOrDefault(0)
      check value == 0

  # ==================== Pattern 3: Direct Extraction (panics) ====================

  suite "Pattern 3: Direct extraction toType() - panics on wrong type":

    test "toInt() extracts correct type":
      let r = Simple_EM.init(42)
      let value = r.toInt()
      check value == 42

    test "toString() extracts string":
      let r = Simple_EM.init("hello")
      let text = r.toString()
      check text == "hello"

    test "toInt() raises ValueError on wrong type":
      let r = Simple_EM.init("not an int")
      expect(ValueError):
        discard r.toInt()

    test "toType() with custom type":
      let user = User_EM(name: "Alice", age: 30)
      let c = Container_EM.init(user)
      let extracted = c.toUser_EM()
      check extracted.name == "Alice"
      check extracted.age == 30

    test "ValueError message from toType()":
      let r = Result_EM.init("string value")
      try:
        discard r.toInt()
        fail()
      except ValueError as e:
        check "int" in e.msg or "type" in e.msg.toLowerAscii()

  # ==================== Pattern 4: Safe Extraction (returns Option) ====================

  suite "Pattern 4: Safe extraction with tryType()":

    test "tryInt() returns Some when holding int":
      let r = Simple_EM.init(42)
      let maybeInt = r.tryInt()
      check maybeInt.isSome
      check maybeInt.get() == 42

    test "tryInt() returns None when holding different type":
      let r = Simple_EM.init("hello")
      let maybeInt = r.tryInt()
      check maybeInt.isNone

    test "tryString() returns Some for string":
      let r = Result_EM.init("test")
      let maybeStr = r.tryString()
      check maybeStr.isSome
      check maybeStr.get() == "test"

    test "tryType() with custom objects":
      let err = Error_EM(code: 500, message: "Error")
      let r = Result_EM.init(err)
      let maybeErr = r.tryError_EM()
      check maybeErr.isSome
      check maybeErr.get().code == 500

    test "chaining with Option operations":
      let r = Number_EM.init(21)
      let maybeInt = r.tryInt()
      let doubled = if maybeInt.isSome: maybeInt.get() * 2 else: 0
      check doubled == 42

    test "tryType() never raises exceptions":
      let r = Simple_EM.init("safe")
      let maybeInt = r.tryInt()
      let maybeStr = r.tryString()
      check maybeInt.isNone
      check maybeStr.isSome

  # ==================== Pattern 5: Checked Conversion (assertions) ====================

  suite "Pattern 5: Checked conversion with expectType()":

    test "expectInt() extracts value with default message":
      let r = Simple_EM.init(42)
      let value = r.expectInt()
      check value == 42

    test "expectInt() with custom error message":
      let r = Simple_EM.init(42)
      let value = r.expectInt("Expected integer value")
      check value == 42

    test "expectString() assertion":
      let r = Simple_EM.init("test")
      let text = r.expectString("Must be string")
      check text == "test"

    test "expectInt() raises AssertionDefect on wrong type":
      let r = Simple_EM.init("not int")
      expect(AssertionDefect):
        discard r.expectInt()

    test "expectType() with custom message in error":
      let r = Result_EM.init("string")
      try:
        discard r.expectInt("Critical: expected int")
        fail()
      except AssertionDefect as e:
        check "Critical" in e.msg or "expected int" in e.msg

    test "expectType() for custom objects":
      let user = User_EM(name: "Bob", age: 25)
      let c = Container_EM.init(user)
      let extracted = c.expectUser_EM("Expected user object")
      check extracted.name == "Bob"

  # ==================== Combined Patterns & Edge Cases ====================

  suite "Combined patterns and edge cases":

    test "all patterns work on same union value":
      let r = Simple_EM.init(42)

      # Pattern 1: Conditional
      if r.toInt(x):
        check x == 42

      # Pattern 2: With default
      let v2 = r.toIntOrDefault(0)
      check v2 == 42

      # Pattern 3: Direct
      let v3 = r.toInt()
      check v3 == 42

      # Pattern 4: Try
      let v4 = r.tryInt()
      check v4.isSome

      # Pattern 5: Expect
      let v5 = r.expectInt()
      check v5 == 42

    test "extraction with zero values":
      let r = Number_EM.init(0)
      check r.toIntOrDefault(-1) == 0
      check r.tryInt().get() == 0
      check r.expectInt() == 0

    test "extraction with negative values":
      let r = Number_EM.init(-42)
      check r.toInt() == -42
      if r.toInt(x):
        check x == -42

    test "extraction with empty strings":
      let r = Simple_EM.init("")
      check r.toString() == ""
      check r.toStringOrDefault("default") == ""

    test "extraction with float precision":
      let r = Number_EM.init(3.14159)
      let f = r.toFloat()
      check abs(f - 3.14159) < 0.00001

    test "multiple sequential extractions":
      let r1 = Simple_EM.init(10)
      let r2 = Simple_EM.init(20)
      let r3 = Simple_EM.init(30)

      let sum = r1.toInt() + r2.toInt() + r3.toInt()
      check sum == 60

    test "extraction in conditional chains":
      let r = Result_EM.init(42)

      let result =
        if r.toInt(v): "int: " & $v
        elif r.toString(s): "string: " & s
        else: "other"

      check result == "int: 42"
