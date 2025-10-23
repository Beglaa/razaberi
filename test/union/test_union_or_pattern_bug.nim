## BUG: Union type OR patterns broken in two ways
##
## BUG 1: Pattern Matching Logic - OR patterns match wrong types
## Location: pattern_matching.nim:5227-5360 (transformUnionTypePattern)
## Issue: Function only handles nnkCall and nnkIdent, returns nnkInfix unchanged
## Result: OR patterns like `int | string` are not transformed to union discriminator checks
##
## BUG 2: Exhaustiveness Checking - OR patterns not counted
## Location: pattern_matching.nim:5478-5647 (checkUnionExhaustiveness)
## Issue: Function doesn't handle nnkInfix nodes at all (missing case)
## Result: False "non-exhaustive" errors even when all types covered
##
## Root Cause: Both functions ignore nnkInfix nodes (OR patterns)
##
## Expected Behavior:
## - `int | string` should transform to: discriminator == ukInt OR discriminator == ukString
## - Exhaustiveness should count both int and string as covered
##
## Actual Behavior:
## - Pattern matches incorrect types (matches everything!)
## - Exhaustiveness reports all types missing

import ../../union_type
import ../../pattern_matching
import std/unittest

type
  TwoTypes = union(int, string)
  ThreeTypes = union(int, string, bool)
  FourTypes = union(int, string, bool, float)

suite "BUG: Union OR pattern matching logic":
  # ==================== Basic OR Pattern Matching ====================
  test "simple OR pattern should match correct types only":
    # Pattern: int | string should match int OR string, NOT bool
    let u1 = ThreeTypes.init(42)
    let u2 = ThreeTypes.init("hello")
    let u3 = ThreeTypes.init(true)

    proc classify(x: ThreeTypes): string =
      match x:
        int | string: "numeric or text"
        bool: "boolean"

    check classify(u1) == "numeric or text"  # int → should match first
    check classify(u2) == "numeric or text"  # string → should match first
    check classify(u3) == "boolean"          # bool → should match second (FAILS: matches first!)

  test "individual type patterns with binding should work":
    # Pattern: int(a), string(s) should bind the matched value
    let u1 = ThreeTypes.init(100)
    let u2 = ThreeTypes.init("test")
    let u3 = ThreeTypes.init(false)

    proc format(x: ThreeTypes): string =
      match x:
        int(a): "int: " & $a
        string(s): "string: " & s
        bool: "bool"

    check format(u1) == "int: 100"
    check format(u2) == "string: test"
    check format(u3) == "bool"

  test "chained OR should match any alternative":
    let u1 = FourTypes.init(42)
    let u2 = FourTypes.init("text")
    let u3 = FourTypes.init(true)
    let u4 = FourTypes.init(3.14)

    proc classify(x: FourTypes): string =
      match x:
        int | string | bool: "primitive"
        float: "floating"

    check classify(u1) == "primitive"
    check classify(u2) == "primitive"
    check classify(u3) == "primitive"
    check classify(u4) == "floating"

  test "multiple OR patterns should not interfere":
    let u1 = FourTypes.init(10)
    let u2 = FourTypes.init(true)

    proc classify(x: FourTypes): string =
      match x:
        int | float: "number"
        string | bool: "other"

    check classify(u1) == "number"
    check classify(u2) == "other"

  # Note: Guards with @ patterns on unions have separate bugs
  # Keeping tests focused on OR patterns only

suite "BUG: Union OR pattern exhaustiveness checking":
  # ==================== Exhaustiveness Detection ====================
  test "OR covering all types should be exhaustive":
    # This SHOULD compile without wildcard
    # Pattern: int | string covers both types (all 2 types)
    # Expected: Compiles successfully
    # Actual: Error "Missing union types: int, string"

    let u = TwoTypes.init(42)
    let result = match u:
      int | string: "covered"

    check result == "covered"

  test "OR with additional pattern should be exhaustive":
    # Pattern 1: int | string (2 types)
    # Pattern 2: bool (1 type)
    # Total: 3/3 types covered
    # Expected: Compiles successfully
    # Actual: Error "Missing union types: int, string"

    let u = ThreeTypes.init(true)
    let result = match u:
      int | string: "int or string"
      bool: "bool"

    check result == "bool"

  test "chained OR should count all alternatives":
    # Pattern: int | string | bool covers all 3 types
    # Expected: Compiles successfully
    # Actual: Error "Missing union types: int, string, bool"

    let u = ThreeTypes.init("test")
    let result = match u:
      int | string | bool: "all covered"

    check result == "all covered"

  test "separate type bindings should count for exhaustiveness":
    # Pattern 1: int(val) covers int
    # Pattern 2: string(val) covers string
    # Pattern 3: bool covers bool
    # Total: 3/3 types covered

    let u = ThreeTypes.init(42)
    let result = match u:
      int(val): $val
      string(val): $val
      bool(val): $val

    check result == "42"

  test "partial OR should warn about missing types":
    # Pattern: int | string (2 types)
    # Missing: bool, float (2 types)
    # Expected: Error "Missing union types: bool, float"
    # Actual: Error "Missing union types: int, string, bool, float" (all reported!)

    let u = FourTypes.init(42)
    let result = match u:
      int | string: "covered"
      _: "fallback required"

    check result == "covered"

## Test Summary:
## Matching Logic: 5 tests demonstrating incorrect pattern matching
## Exhaustiveness: 5 tests demonstrating false non-exhaustive errors
## Total: 10 comprehensive tests
##
## After fix:
## - All pattern matching tests should pass
## - Exhaustiveness tests should compile without "_: fallback" wildcards
