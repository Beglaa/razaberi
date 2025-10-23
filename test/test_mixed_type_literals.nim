## Test: Mixed-Type Literal Patterns
##
## Tests that pattern matching correctly handles mixed literal types across
## different pattern arms, including boolean literals which previously caused
## type mismatch errors.
##
## Bug Fix: Added `when compiles()` guard to boolean literal handling in
## generateLiteralPattern() to prevent type mismatch errors when mixing
## boolean patterns with non-boolean scrutinees.

import ../pattern_matching
import std/unittest

suite "Mixed Type Literal Patterns":

  test "int scrutinee with mixed-type patterns including boolean":
    # This previously failed with: type mismatch: int == bool
    let value: int = 42

    let result = match value:
      42: "matched int 42"
      "hello": "matched string"
      3.14: "matched float"
      'c': "matched char"
      true: "matched true"
      false: "matched false"
      _: "no match"

    check result == "matched int 42"

  test "string scrutinee with mixed-type patterns including boolean":
    let value: string = "hello"

    let result = match value:
      42: "matched int"
      "hello": "matched string hello"
      3.14: "matched float"
      'c': "matched char"
      true: "matched true"
      false: "matched false"
      _: "no match"

    check result == "matched string hello"

  test "float scrutinee with mixed-type patterns including boolean":
    let value: float = 3.14

    let result = match value:
      42: "matched int"
      "hello": "matched string"
      3.14: "matched float 3.14"
      'c': "matched char"
      true: "matched true"
      false: "matched false"
      _: "no match"

    check result == "matched float 3.14"

  test "char scrutinee with mixed-type patterns including boolean":
    let value: char = 'c'

    let result = match value:
      42: "matched int"
      "hello": "matched string"
      3.14: "matched float"
      'c': "matched char c"
      true: "matched true"
      false: "matched false"
      _: "no match"

    check result == "matched char c"

  test "bool scrutinee with mixed-type patterns":
    let value: bool = true

    let result = match value:
      42: "matched int"
      "hello": "matched string"
      3.14: "matched float"
      'c': "matched char"
      true: "matched true"
      false: "matched false"
      _: "no match"

    check result == "matched true"

  test "bool false scrutinee with mixed-type patterns":
    let value: bool = false

    let result = match value:
      42: "matched int"
      "hello": "matched string"
      3.14: "matched float"
      'c': "matched char"
      true: "matched true"
      false: "matched false"
      _: "no match"

    check result == "matched false"

  test "all primitive types in single match - int scrutinee":
    # Comprehensive test with all primitive literal types
    let intVal: int = 100

    let result = match intVal:
      100: "int 100"
      "text": "string"
      2.5: "float"
      'x': "char"
      true: "bool true"
      false: "bool false"
      _: "other"

    check result == "int 100"

  test "all primitive types in single match - bool scrutinee":
    let boolVal: bool = true

    let result = match boolVal:
      100: "int"
      "text": "string"
      2.5: "float"
      'x': "char"
      true: "bool true"
      false: "bool false"
      _: "other"

    check result == "bool true"

  test "mixed types with OR patterns including boolean":
    let value: int = 42

    let result = match value:
      1 | 2 | 3: "small int"
      42 | 100: "specific int"
      true | false: "bool"  # Should compile but not match int scrutinee
      "a" | "b": "string"   # Should compile but not match int scrutinee
      _: "other"

    check result == "specific int"

  test "boolean OR pattern with non-bool scrutinee":
    let value: string = "test"

    let result = match value:
      true | false: "bool"      # Should compile, won't match
      "test": "matched string"
      _: "other"

    check result == "matched string"

  test "boolean literal in compound pattern with guards":
    let value: int = 42

    let result = match value:
      true: "bool true"
      false: "bool false"
      x and x > 40: "int > 40"
      _: "other"

    check result == "int > 40"

  test "wildcard still matches with mixed boolean patterns":
    let value: float = 99.9

    let result = match value:
      42: "int"
      true: "bool"
      "text": "string"
      _: "wildcard"

    check result == "wildcard"

  test "mixed types with @ binding and boolean patterns":
    let value: int = 42

    let result = match value:
      true @ b: "bool: " & $b
      42 @ num: "int: " & $num
      "x" @ s: "string: " & $s
      _: "other"

    check result == "int: 42"

  test "boolean pattern doesn't interfere with subsequent arms":
    # Ensure boolean patterns that don't match don't prevent
    # later arms from executing
    let value: string = "match_me"

    let result = match value:
      true: "bool true"
      false: "bool false"
      42: "int"
      "match_me": "found it"
      _: "not found"

    check result == "found it"
