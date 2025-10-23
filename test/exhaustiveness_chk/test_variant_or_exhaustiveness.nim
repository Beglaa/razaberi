import unittest
import ../../variant_dsl
import ../../pattern_matching
import ../helper/ccheck

# ============================================================================
# VARIANT DSL OR PATTERN EXHAUSTIVENESS TESTING
# ============================================================================
# Purpose: Test exhaustiveness checking for OR patterns with variant DSL UFCS syntax
# Bug: TokenType.Number | TokenType.Operator not recognized in exhaustiveness checker
# ============================================================================

suite "Variant DSL OR Patterns - Exhaustiveness Checking":

  test "OR pattern covering all variants should be exhaustive":
    variant Binary:
      Zero()
      One()

    check shouldCompile (
      let x = Binary.Zero()
      let result = match x:
        Binary.Zero | Binary.One: "covered"
    )

  test "OR pattern covering all variants in multiple arms should be exhaustive":
    variant Tri:
      A()
      B()
      C()

    check shouldCompile (
      let x = Tri.A()
      let result = match x:
        Tri.A | Tri.B: "first"
        Tri.C: "second"
    )

  test "chained OR covering all variants should be exhaustive":
    variant Quad:
      W()
      X()
      Y()
      Z()

    check shouldCompile (
      let x = Quad.W()
      let result = match x:
        Quad.W | Quad.X | Quad.Y | Quad.Z: "all"
    )

  test "partial OR pattern should not be exhaustive":
    variant Color:
      Red()
      Green()
      Blue()

    check shouldNotCompile (
      let x = Color.Red()
      let result = match x:
        Color.Red | Color.Green: "covered"
        # Missing: Blue
    )

  test "OR pattern missing one variant should not be exhaustive":
    variant State:
      Active()
      Inactive()
      Pending()
      Failed()

    check shouldNotCompile (
      let x = State.Active()
      let result = match x:
        State.Active | State.Pending: "working"
        State.Inactive: "stopped"
        # Missing: Failed
    )

  test "OR pattern with wildcard should be exhaustive":
    variant Status:
      Ok()
      Warning()
      Error()

    check shouldCompile (
      let x = Status.Ok()
      let result = match x:
        Status.Ok | Status.Warning: "good"
        _: "other"
    )

  test "multiple OR patterns covering all should be exhaustive":
    variant Priority:
      Critical()
      High()
      Medium()
      Low()

    check shouldCompile (
      let x = Priority.Critical()
      let result = match x:
        Priority.Critical | Priority.High: "urgent"
        Priority.Medium | Priority.Low: "not urgent"
    )

  test "mixed individual and OR patterns covering all should be exhaustive":
    variant Level:
      Max()
      High()
      Medium()
      Low()
      Min()

    check shouldCompile (
      let x = Level.Max()
      let result = match x:
        Level.Max: "max"
        Level.High | Level.Medium: "mid"
        Level.Low | Level.Min: "low"
    )

  test "OR pattern at end covering remaining variants should be exhaustive":
    variant Grade:
      A()
      B()
      C()
      D()
      F()

    check shouldCompile (
      let x = Grade.A()
      let result = match x:
        Grade.A: "excellent"
        Grade.B | Grade.C | Grade.D | Grade.F: "other"
    )

suite "Variant DSL OR Patterns - Exhaustiveness with Parameters":

  test "OR pattern with parameters covering all should be exhaustive":
    variant TokenType:
      Number(value: int)
      Operator(op: string)
      Keyword(word: string)
      Whitespace()

    check shouldCompile (
      let x = TokenType.Number(42)
      let result = match x:
        TokenType.Number | TokenType.Operator: "symbol"
        TokenType.Keyword | TokenType.Whitespace: "other"
    )

  test "OR pattern with parameters missing variant should not be exhaustive":
    variant Result:
      Success(val: int)
      Warning(msg: string)
      Error(code: int)

    check shouldNotCompile (
      let x = Result.Success(42)
      let result = match x:
        Result.Success | Result.Warning: "ok-ish"
        # Missing: Error
    )

  test "mixed zero-param and param variants with OR should be exhaustive":
    variant Response:
      Ok()
      Created(createdId: int)
      Updated(updatedId: int)
      NotFound()

    check shouldCompile (
      let x = Response.Ok()
      let result = match x:
        Response.Ok | Response.NotFound: "simple"
        Response.Created | Response.Updated: "with data"
    )

suite "Variant DSL OR Patterns - Complex Exhaustiveness":

  test "nested OR patterns should count correctly":
    variant Flag:
      Red()
      Green()
      Blue()
      Yellow()

    check shouldCompile (
      let x = Flag.Red()
      let result = match x:
        Flag.Red | Flag.Green: "primary"
        Flag.Blue | Flag.Yellow: "secondary"
    )

  test "OR pattern covering subset with separate arms should be exhaustive":
    variant Mode:
      Read()
      Write()
      Execute()
      Delete()

    check shouldCompile (
      let x = Mode.Read()
      let result = match x:
        Mode.Read | Mode.Write: "rw"
        Mode.Execute: "x"
        Mode.Delete: "d"
    )

  test "single variant repeated in OR should still count as one":
    variant Switch:
      On()
      Off()

    check shouldCompile (
      let x = Switch.On()
      let result = match x:
        Switch.On | Switch.On: "on"  # Redundant but valid
        Switch.Off: "off"
    )

  test "OR pattern with individual pattern covering all should be exhaustive":
    variant Traffic:
      Red()
      Yellow()
      Green()

    check shouldCompile (
      let x = Traffic.Red()
      let result = match x:
        Traffic.Red: "stop"
        Traffic.Yellow | Traffic.Green: "go-ish"
    )

suite "Variant DSL OR Patterns - Exhaustiveness Error Messages":

  test "missing variants in OR pattern should list all missing":
    variant Hex:
      D0()
      D1()
      D2()
      D3()
      D4()
      D5()

    check shouldNotCompile (
      let x = Hex.D0()
      let result = match x:
        Hex.D0 | Hex.D1 | Hex.D2: "covered"
        # Missing: D3, D4, D5
    )

  test "empty OR arms should not be exhaustive":
    variant Bool:
      True()
      False()

    check shouldNotCompile (
      let x = Bool.True()
      let result = match x:
        # No patterns
        discard
    )

suite "Variant DSL OR Patterns - Comparison with Explicit Syntax":

  test "UFCS OR and explicit OR should both be exhaustive":
    variant Status:
      Active()
      Inactive()

    # UFCS syntax
    check shouldCompile (
      let x = Status.Active()
      let result1 = match x:
        Status.Active | Status.Inactive: "covered"
    )

    # Explicit discriminator syntax (already working)
    check shouldCompile (
      let x = Status.Active()
      let result2 = match x:
        Status(kind: skActive) | Status(kind: skInactive): "covered"
    )

  # Note: Mixing UFCS and explicit syntax in the same match is not recommended
  # and may not work correctly with exhaustiveness checking. Use one style consistently.

