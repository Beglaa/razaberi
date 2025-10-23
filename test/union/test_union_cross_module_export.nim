## Test for UT-4: Cross-Module Export Markers
##
## Tests that union types exported from one module can be fully used in another module,
## including access to:
## - The kind discriminator field
## - Enum values for pattern matching
## - Variant object fields
##
## This test covers the bug where generated enum and variant object types were not
## exported with `*`, breaking cross-module usage.

import unittest
import ../../union_type
import ../../pattern_matching

# Define union types at module level for export
type Result* = union(int, string)
type ComplexResult* = union(int, string, seq[int])

suite "UT-4: Cross-Module Export Markers":

  test "kind field is accessible":
    let r = Result.init(42)
    # This should compile - kind field must be exported
    check r.kind == ukInt

  test "enum values are accessible":
    let r1 = Result.init(42)
    let r2 = Result.init("hello")

    # Enum values must be accessible for pattern matching
    check r1.kind == ukInt
    check r2.kind == ukString

  test "case statement with discriminator works":
    let r = Result.init(42)

    var matched = false
    case r.kind:
      of ukInt:
        matched = true
      of ukString:
        discard

    check matched

  test "variant fields are accessible":
    let r = Result.init(42)

    # Variant fields (val0, val1) must be exported
    case r.kind:
      of ukInt:
        check r.val0 == 42
      of ukString:
        discard

  test "pattern matching with union types":
    let r = Result.init("test")

    let result = match r:
      int(v): "int: " & $v
      string(s): "string: " & s

    check result == "string: test"

  test "cross-module usage with complex types":
    let r1 = ComplexResult.init(42)
    let r2 = ComplexResult.init("hello")
    let r3 = ComplexResult.init(@[1, 2, 3])

    # All enum values should be accessible
    check r1.kind == ukInt
    check r2.kind == ukString
    check r3.kind == ukSeq_int

    # All variant fields should be accessible
    check r1.val0 == 42
    check r2.val1 == "hello"
    check r3.val2 == @[1, 2, 3]
