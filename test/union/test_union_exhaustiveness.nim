## Phase 4: Exhaustiveness Checking Tests
## Tests for compile-time verification that all union types are covered

import unittest
import options
import ../../union_type
import ../../pattern_matching

# Test types
type
  Error_EX = object
    code: int
    message: string

  User_EX = object
    name: string
    age: int

# Union types for testing
type Result_EX = union(int, string, Error_EX)
type Simple_EX = union(int, string)
type Triple_EX = union(int, string, bool)
type Container_EX = union(int, seq[string], User_EX)
# Note: Generic unions not yet supported, testing with concrete types
type SeqOrOption_EX = union(seq[int], Option[int])

suite "Union Type Exhaustiveness Checking - Phase 4":

  # ==================== Compile-Time Helpers ====================

  template shouldNotCompile(code: untyped): bool =
    not compiles(code)

  template shouldCompile(code: untyped): bool =
    compiles(code)

  # ==================== Non-Exhaustive Patterns (Should Fail) ====================

  suite "Non-exhaustive patterns should not compile":

    test "missing one type in 2-type union":
      check shouldNotCompile (
        let r = Simple_EX.init(42)
        let msg = match r:
          int(v): "int"
          # Missing: string
      )

    test "missing one type in 3-type union":
      check shouldNotCompile (
        let r = Result_EX.init(42)
        let msg = match r:
          int(v): "int"
          string(s): "string"
          # Missing: Error_EX
      )

    test "missing two types in 3-type union":
      check shouldNotCompile (
        let r = Result_EX.init(42)
        let msg = match r:
          int(v): "int"
          # Missing: string, Error_EX
      )

    test "completely empty match":
      check shouldNotCompile (
        let r = Simple_EX.init(42)
        let msg = match r:
          discard  # No patterns at all
      )

    test "missing custom type":
      check shouldNotCompile (
        let r = Container_EX.init(42)
        let msg = match r:
          int(v): "int"
          seq[string](s): "seq"
          # Missing: User_EX
      )

  # ==================== Exhaustive Patterns (Should Compile) ====================

  suite "Exhaustive patterns should compile":

    test "all types covered in 2-type union":
      check shouldCompile (
        let r = Simple_EX.init(42)
        let msg = match r:
          int(v): "int"
          string(s): "string"
      )

    test "all types covered in 3-type union":
      check shouldCompile (
        let r = Result_EX.init(42)
        let msg = match r:
          int(v): "int"
          string(s): "string"
          Error_EX(e): "error"
      )

    test "wildcard catches remaining types":
      check shouldCompile (
        let r = Result_EX.init(42)
        let msg = match r:
          int(v): "int"
          _: "other"
      )

    test "wildcard with no other patterns":
      check shouldCompile (
        let r = Simple_EX.init(42)
        let msg = match r:
          _: "any"
      )

    test "all types with guards are still exhaustive":
      check shouldCompile (
        let r = Result_EX.init(42)
        let msg = match r:
          int(v) and v > 100: "large"
          int(v): "small"
          string(s): "string"
          Error_EX(e): "error"
      )

  # ==================== Wildcard Position Tests ====================

  suite "Wildcard position handling":

    test "wildcard at end makes pattern exhaustive":
      check shouldCompile (
        let r = Triple_EX.init(42)
        let msg = match r:
          int(v): "int"
          _: "other"
      )

    test "wildcard in middle is rejected (dead code)":
      # Note: Match macro requires wildcard to be last pattern
      # Patterns after wildcard are dead code and cause compile error
      check shouldNotCompile (
        let r = Triple_EX.init(42)
        let msg = match r:
          int(v): "int"
          _: "other"
          string(s): "string"  # Dead code - will error
      )

    test "wildcard at start is rejected (dead code)":
      # Note: Match macro requires wildcard to be last pattern
      check shouldNotCompile (
        let r = Triple_EX.init(42)
        let msg = match r:
          _: "any"
          int(v): "int"  # Dead code - will error
      )

  # ==================== Generic Type Exhaustiveness ====================

  suite "Generic type exhaustiveness":

    test "seq/option union requires exact type matching":
      check shouldNotCompile (
        let c = SeqOrOption_EX.init(some(42))
        let msg = match c:
          seq[int](s): "seq"
          # Missing: Option[int]
      )

    test "seq/option union with all types covered":
      check shouldCompile (
        let c = SeqOrOption_EX.init(some(42))
        let msg = match c:
          seq[int](s): "seq"
          Option[int](o): "option"
      )

    test "seq/option union with wildcard":
      check shouldCompile (
        let c = SeqOrOption_EX.init(some(42))
        let msg = match c:
          seq[int](s): "seq"
          _: "other"
      )

  # ==================== Runtime Behavior Tests ====================

  suite "Runtime behavior with exhaustive patterns":

    test "exhaustive pattern matches correctly - all types":
      let r1 = Result_EX.init(42)
      let r2 = Result_EX.init("hello")
      let r3 = Result_EX.init(Error_EX(code: 404, message: "Not Found"))

      let msg1 = match r1:
        int(v): "int: " & $v
        string(s): "string: " & s
        Error_EX(e): "error: " & $e.code

      let msg2 = match r2:
        int(v): "int: " & $v
        string(s): "string: " & s
        Error_EX(e): "error: " & $e.code

      let msg3 = match r3:
        int(v): "int: " & $v
        string(s): "string: " & s
        Error_EX(e): "error: " & $e.code

      check msg1 == "int: 42"
      check msg2 == "string: hello"
      check msg3 == "error: 404"

    test "exhaustive pattern with wildcard works":
      let r1 = Simple_EX.init(42)
      let r2 = Simple_EX.init("test")

      let msg1 = match r1:
        int(v): "int: " & $v
        _: "other"

      let msg2 = match r2:
        int(v): "int: " & $v
        _: "other"

      check msg1 == "int: 42"
      check msg2 == "other"

    test "exhaustive pattern with guards":
      let r1 = Result_EX.init(42)
      let r2 = Result_EX.init(200)

      let msg1 = match r1:
        int(v) and v > 100: "large"
        int(v): "small: " & $v
        string(s): "string"
        Error_EX(e): "error"

      let msg2 = match r2:
        int(v) and v > 100: "large"
        int(v): "small: " & $v
        string(s): "string"
        Error_EX(e): "error"

      check msg1 == "small: 42"
      check msg2 == "large"

  # ==================== Edge Cases ====================

  suite "Edge cases and special scenarios":

    test "type appears multiple times with different guards":
      check shouldCompile (
        let r = Result_EX.init(42)
        let msg = match r:
          int(v) and v > 100: "large"
          int(v) and v > 0: "positive"
          int(v): "zero or negative"
          string(s): "string"
          Error_EX(e): "error"
      )

    test "backwards compatible syntax is exhaustive":
      check shouldCompile (
        let r = Simple_EX.init(42)
        let msg = match r:
          Simple_EX(kind: ukInt, val0: v): "int"
          Simple_EX(kind: ukString, val1: s): "string"
      )

    test "mixing new and old syntax":
      check shouldCompile (
        let r = Simple_EX.init(42)
        let msg = match r:
          int(v): "int"
          Simple_EX(kind: ukString, val1: s): "string"
      )

    test "nested matches are independently exhaustive":
      check shouldCompile (
        let r1 = Simple_EX.init(42)
        let r2 = Simple_EX.init("test")

        let msg = match r1:
          int(v):
            match r2:
              int(i): "both int"
              string(s): "int and string"
          string(s):
            match r2:
              int(i): "string and int"
              string(s2): "both string"
      )

  # ==================== Error Message Quality ====================

  suite "Error message verification":

    test "error message lists missing types":
      # This test verifies that the error message is helpful
      # We can't easily test the exact message, but we verify it doesn't compile
      check shouldNotCompile (
        let r = Triple_EX.init(42)
        let msg = match r:
          int(v): "int"
          # Should report: missing string, bool
      )

    test "error message with single missing type":
      check shouldNotCompile (
        let r = Simple_EX.init(42)
        let msg = match r:
          int(v): "int"
          # Should report: missing string
      )
