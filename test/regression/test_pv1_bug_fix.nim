## Test for PV-1 Bug Fix: Substring Match False Positive in Variant Constructor Validation
##
## This test verifies that pattern_validation.nim correctly validates variant constructors
## by checking the 'k' separator before constructor names in discriminator values.
##
## Bug: Previously used simple endsWith() without separator validation
## Fix: Now checks that character before constructor name is 'k' (separator)

import ../../pattern_matching
import unittest

suite "PV-1 Bug Fix - Variant Constructor Validation with Separator Check":

  test "constructor name as suffix should not match longer constructor":
    # Bug scenario: "Active" should NOT match "IntActive" even though
    # "skIntActive".endsWith("Active") returns true
    type
      StatusKind = enum
        skIntActive,   # Discriminator: "skIntActive" - has "Active" as suffix
        skActive       # Discriminator: "skActive" - exact match for "Active"

      Status = object
        case kind: StatusKind
        of skIntActive:
          value: int
          timestamp: int  # 2 fields
        of skActive:
          id: int         # 1 field (different count!)

    let activeStatus = Status(kind: skActive, id: 100)
    let intActiveStatus = Status(kind: skIntActive, value: 200, timestamp: 123)

    # Test 1: Status.Active should match skActive (not skIntActive)
    let result1 = match activeStatus:
      Status.Active(x): "Active: " & $x
      Status.IntActive(v, t): "IntActive: " & $v & ", " & $t
      _: "no match"

    check result1 == "Active: 100"

    # Test 2: Status.IntActive should match skIntActive
    let result2 = match intActiveStatus:
      Status.Active(x): "Active: " & $x
      Status.IntActive(v, t): "IntActive: " & $v & ", " & $t
      _: "no match"

    check result2 == "IntActive: 200, 123"

  test "validation should reject incorrect field count using correct branch":
    # With the bug, validation might use wrong branch for field count checking
    # Now it should correctly identify the branch and validate field count
    type
      ResultKind = enum
        rkIntError,    # Discriminator: "rkIntError" - 2 fields
        rkError        # Discriminator: "rkError" - 1 field

      Result = object
        case kind: ResultKind
        of rkIntError:
          code: int
          message: string  # 2 fields
        of rkError:
          error: string    # 1 field

    let err = Result(kind: rkError, error: "failed")

    # This should work: Error has 1 field, we provide 1 field
    let result = match err:
      Result.Error(e): "Error: " & e
      Result.IntError(c, m): "IntError: " & $c & " - " & m
      _: "no match"

    check result == "Error: failed"

  test "multiple constructors with shared suffixes handled correctly":
    # Complex scenario: Multiple constructors share suffixes
    # "State" appears as suffix in: "rkInitState", "rkActiveState", "rkState"
    type
      ComplexKind = enum
        rkInitState,    # Suffix "State", prefix char 't'
        rkActiveState,  # Suffix "State", prefix char 'e'
        rkState         # Exact match "State", prefix char 'k' ✓

      Complex = object
        case kind: ComplexKind
        of rkInitState:
          init: int
        of rkActiveState:
          active: int
        of rkState:
          state: int

    let s1 = Complex(kind: rkState, state: 1)
    let s2 = Complex(kind: rkInitState, init: 2)
    let s3 = Complex(kind: rkActiveState, active: 3)

    # State pattern should ONLY match rkState (where char before "State" is 'k')
    let r1 = match s1:
      Complex.State(x): "State: " & $x
      Complex.InitState(x): "InitState: " & $x
      Complex.ActiveState(x): "ActiveState: " & $x
      _: "no match"

    check r1 == "State: 1"

    # InitState should match rkInitState (where char before "InitState" is 'k')
    let r2 = match s2:
      Complex.State(x): "State: " & $x
      Complex.InitState(x): "InitState: " & $x
      Complex.ActiveState(x): "ActiveState: " & $x
      _: "no match"

    check r2 == "InitState: 2"

    # ActiveState should match rkActiveState (where char before "ActiveState" is 'k')
    let r3 = match s3:
      Complex.State(x): "State: " & $x
      Complex.InitState(x): "InitState: " & $x
      Complex.ActiveState(x): "ActiveState: " & $x
      _: "no match"

    check r3 == "ActiveState: 3"

  test "edge case: single letter constructor names":
    # Edge case: Very short constructor names
    type
      ShortKind = enum
        skIntA,  # "A" is suffix, but prefix char is 't' (not 'k')
        skA      # "A" exact match with 'k' prefix ✓

      Short = object
        case kind: ShortKind
        of skIntA:
          intVal: int
        of skA:
          val: int

    let s1 = Short(kind: skA, val: 42)
    let s2 = Short(kind: skIntA, intVal: 99)

    let r1 = match s1:
      Short.A(x): "A: " & $x
      Short.IntA(x): "IntA: " & $x
      _: "no match"

    check r1 == "A: 42"

    let r2 = match s2:
      Short.A(x): "A: " & $x
      Short.IntA(x): "IntA: " & $x
      _: "no match"

    check r2 == "IntA: 99"
