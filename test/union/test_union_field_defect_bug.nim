## Test to reproduce FieldDefect bug in variant object pattern matching
##
## BUG: Pattern matching library incorrectly attempts to access fields
## BEFORE checking the discriminator value, causing FieldDefect exceptions.
##
## Expected: Check discriminator FIRST, then access appropriate field
## Actual: Access field, then check discriminator → FieldDefect
##
## Reference: /union/BUG_variant_object_field_access.md

import unittest
import ../../union_type
import ../../pattern_matching

# Custom error type for union
type Error_PM = object
  code: int
  message: string

# Union types for testing (must be at module level)
type Result_Div = union(int, Error_PM)
type Value3 = union(int, string, Error_PM)

suite "Union FieldDefect Bug Reproduction":

  test "BUG: Two patterns with Error value (second pattern should match)":
    ## This test reproduces the exact bug from BUG_variant_object_field_access.md
    ## When the second pattern should match, the library attempts to access
    ## the first pattern's field (val0) before checking discriminator,
    ## causing FieldDefect.

    # Create instance with Error_PM (kind = ukError_PM, val1 = Error_PM(...))
    let r = Result_Div.init(Error_PM(code: 400, message: "test error"))

    # This SHOULD work but currently causes FieldDefect
    # Expected: Check r.kind == ukInt → false, skip first pattern
    #           Check r.kind == ukError_PM → true, execute second pattern
    # Actual: Try to access r.val0 → FieldDefect (val0 invalid when kind=ukError_PM)
    let msg = match r:
      Result_Div(kind: ukInt, val0: v): "result: " & $v
      Result_Div(kind: ukError_PM, val1: e): "error: " & e.message

    check msg == "error: test error"

  test "BUG: Pattern order reversal (first is Error, second is Int)":
    ## Same bug, different field access order
    ## When Int value matches second pattern, library tries to access val1
    ## before checking discriminator

    let r = Result_Div.init(42)

    # This SHOULD work but currently causes FieldDefect
    let msg = match r:
      Result_Div(kind: ukError_PM, val1: e): "error: " & e.message
      Result_Div(kind: ukInt, val0: v): "result: " & $v

    check msg == "result: 42"

  test "Control: Single pattern with Error (should work)":
    ## This works because there's only one pattern - no field access conflict
    let r = Result_Div.init(Error_PM(code: 400, message: "test"))

    let msg = match r:
      Result_Div(kind: ukError_PM, val1: e): "error: " & e.message
      _: "other"

    check msg == "error: test"

  test "Control: First pattern matches Int (should work)":
    ## This works because the first pattern matches immediately
    let r = Result_Div.init(42)

    let msg = match r:
      Result_Div(kind: ukInt, val0: v): "result: " & $v
      Result_Div(kind: ukError_PM, val1: e): "error: " & e.message

    check msg == "result: 42"

  test "BUG: Three patterns with middle pattern should match":
    ## Testing more complex case with multiple patterns
    let v = Value3.init("hello")

    # Middle pattern should match
    let msg = match v:
      Value3(kind: ukInt, val0: i): "int: " & $i
      Value3(kind: ukString, val1: s): "string: " & s
      Value3(kind: ukError_PM, val2: e): "error: " & e.message

    check msg == "string: hello"

  test "BUG: Three patterns with last pattern should match":
    ## Last pattern should match - tests if bug affects all non-first patterns
    let v = Value3.init(Error_PM(code: 500, message: "server error"))

    # Last pattern should match
    let msg = match v:
      Value3(kind: ukInt, val0: i): "int: " & $i
      Value3(kind: ukString, val1: s): "string: " & s
      Value3(kind: ukError_PM, val2: e): "error: " & e.message

    check msg == "error: server error"
