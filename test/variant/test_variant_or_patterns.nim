import unittest
import ../../variant_dsl
import ../../pattern_matching

# ============================================================================
# VARIANT DSL OR PATTERN TESTING - CODE GENERATION & RUNTIME BEHAVIOR
# ============================================================================
# Purpose: Test that OR patterns work correctly with variant DSL UFCS syntax
# Bug: TokenType.Number | TokenType.Operator fails exhaustiveness and codegen
# ============================================================================

suite "Variant DSL OR Patterns - Code Generation":

  test "simple OR pattern with two UFCS constructors should match correctly":
    variant TokenType:
      Number(value: int)
      Operator(op: string)
      Keyword(word: string)
      Whitespace()

    let number = TokenType.Number(42)
    let plus = TokenType.Operator("+")
    let ifKeyword = TokenType.Keyword("if")

    # BUG FIX TEST: This should work!
    let result1 = match number:
      TokenType.Number | TokenType.Operator: "Number or Operator"
      TokenType.Keyword | TokenType.Whitespace: "Keyword or Whitespace"

    check result1 == "Number or Operator"

    let result2 = match plus:
      TokenType.Number | TokenType.Operator: "Number or Operator"
      TokenType.Keyword | TokenType.Whitespace: "Keyword or Whitespace"

    check result2 == "Number or Operator"

    let result3 = match ifKeyword:
      TokenType.Number | TokenType.Operator: "Number or Operator"
      TokenType.Keyword | TokenType.Whitespace: "Keyword or Whitespace"

    check result3 == "Keyword or Whitespace"

  test "chained OR pattern with three UFCS constructors should match all":
    variant TokenType:
      Number(value: int)
      Operator(op: string)
      Keyword(word: string)
      Whitespace()

    let number = TokenType.Number(42)
    let plus = TokenType.Operator("+")
    let ifKeyword = TokenType.Keyword("if")

    let result1 = match number:
      TokenType.Number | TokenType.Operator | TokenType.Keyword: "Symbol"
      TokenType.Whitespace: "Space"

    check result1 == "Symbol"

    let result2 = match plus:
      TokenType.Number | TokenType.Operator | TokenType.Keyword: "Symbol"
      TokenType.Whitespace: "Space"

    check result2 == "Symbol"

    let result3 = match ifKeyword:
      TokenType.Number | TokenType.Operator | TokenType.Keyword: "Symbol"
      TokenType.Whitespace: "Space"

    check result3 == "Symbol"

  test "OR pattern should NOT match values from other branch":
    variant Status:
      Active(count: int)
      Inactive()
      Pending(reason: string)

    let active = Status.Active(10)
    let inactive = Status.Inactive()

    let result1 = match active:
      Status.Active | Status.Pending: "Working"
      Status.Inactive: "Not working"

    check result1 == "Working"

    let result2 = match inactive:
      Status.Active | Status.Pending: "Working"
      Status.Inactive: "Not working"

    check result2 == "Not working"

  test "OR pattern with zero-parameter constructors should work":
    variant SimpleState:
      On()
      Off()
      Standby()

    let on = SimpleState.On()
    let off = SimpleState.Off()
    let standby = SimpleState.Standby()

    let result1 = match on:
      SimpleState.On | SimpleState.Standby: "Active"
      SimpleState.Off: "Inactive"

    check result1 == "Active"

    let result2 = match off:
      SimpleState.On | SimpleState.Standby: "Active"
      SimpleState.Off: "Inactive"

    check result2 == "Inactive"

    let result3 = match standby:
      SimpleState.On | SimpleState.Standby: "Active"
      SimpleState.Off: "Inactive"

    check result3 == "Active"

  test "mixed OR and individual patterns should work together":
    variant Result:
      Success(value: int)
      Warning(msg: string)
      Error(errorCode: int)
      Critical(criticalCode: int)

    let success = Result.Success(42)
    let warning = Result.Warning("test")
    let error = Result.Error(404)
    let critical = Result.Critical(500)

    let result1 = match success:
      Result.Success: "ok"
      Result.Warning | Result.Error: "issues"
      Result.Critical: "bad"

    check result1 == "ok"

    let result2 = match warning:
      Result.Success: "ok"
      Result.Warning | Result.Error: "issues"
      Result.Critical: "bad"

    check result2 == "issues"

    let result3 = match error:
      Result.Success: "ok"
      Result.Warning | Result.Error: "issues"
      Result.Critical: "bad"

    check result3 == "issues"

    let result4 = match critical:
      Result.Success: "ok"
      Result.Warning | Result.Error: "issues"
      Result.Critical: "bad"

    check result4 == "bad"

  test "OR pattern with wildcard should compile and work":
    variant Color:
      Red()
      Green()
      Blue()
      Yellow()

    let red = Color.Red()
    let yellow = Color.Yellow()

    let result1 = match red:
      Color.Red | Color.Green: "primary"
      _: "other"

    check result1 == "primary"

    let result2 = match yellow:
      Color.Red | Color.Green: "primary"
      _: "other"

    check result2 == "other"

  test "nested variant with OR patterns should work":
    variant Inner:
      A(aVal: int)
      B(bVal: int)

    variant Outer:
      X(inner: Inner)
      Y(value: int)

    let innerA = Inner.A(10)
    let innerB = Inner.B(20)
    let outerX = Outer.X(innerA)
    let outerY = Outer.Y(30)

    # Test outer OR pattern
    let result = match outerX:
      Outer.X | Outer.Y: "matched"

    check result == "matched"

  test "OR pattern preserves match evaluation order":
    variant Priority:
      High(highLevel: int)
      Medium(mediumLevel: int)
      Low(lowLevel: int)

    let high = Priority.High(1)
    let medium = Priority.Medium(2)

    var executionOrder: seq[string] = @[]

    let result1 = match high:
      Priority.High | Priority.Medium:
        executionOrder.add("first")
        "urgent"
      Priority.Low:
        executionOrder.add("second")
        "lazy"

    check result1 == "urgent"
    check executionOrder == @["first"]

    executionOrder = @[]

    let result2 = match medium:
      Priority.High | Priority.Medium:
        executionOrder.add("first")
        "urgent"
      Priority.Low:
        executionOrder.add("second")
        "lazy"

    check result2 == "urgent"
    check executionOrder == @["first"]

suite "Variant DSL OR Patterns - Edge Cases":

  test "single-variant OR (redundant but valid) should work":
    variant Flag:
      On()
      Off()

    let on = Flag.On()

    # Redundant but syntactically valid
    let result = match on:
      Flag.On | Flag.On: "duplicate"
      Flag.Off: "off"

    check result == "duplicate"

  test "OR pattern at end of match should work":
    variant State:
      Running()
      Stopped()
      Paused()

    let paused = State.Paused()

    let result = match paused:
      State.Running: "running"
      State.Stopped | State.Paused: "not running"

    check result == "not running"

  test "multiple OR patterns in same match should work":
    variant Grade:
      A()
      B()
      C()
      D()
      F()

    let gradeB = Grade.B()
    let gradeD = Grade.D()

    let result1 = match gradeB:
      Grade.A | Grade.B: "pass"
      Grade.C | Grade.D: "acceptable"
      Grade.F: "fail"

    check result1 == "pass"

    let result2 = match gradeD:
      Grade.A | Grade.B: "pass"
      Grade.C | Grade.D: "acceptable"
      Grade.F: "fail"

    check result2 == "acceptable"
