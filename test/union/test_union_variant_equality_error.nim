## Test: Union types with variant objects - Error Handling and Solutions
##
## This test demonstrates:
## 1. Variant objects WITHOUT custom == fail with helpful error message
## 2. Using variant_dsl automatically provides == and works perfectly

import unittest
import ../../union_type
import ../../variant_dsl

# ============================================================================
# Test 1: Variant Object Without Custom == (Should Fail)
# ============================================================================

type
  ColorKind = enum ckRed, ckGreen, ckBlue
  ColorWithoutEq = object
    case kind: ColorKind
    of ckRed: rVal: int
    of ckGreen: gVal: int
    of ckBlue: bVal: int

# ============================================================================
# Test 2: Using variant_dsl (Auto-generates == and Works!)
# ============================================================================

# variant_dsl automatically generates == operator
variant Status:
  Ready()
  Loading(progress: int)
  Error(message: string)

# This works because variant_dsl generated `==` for Status
type StatusUnion = union(Status, string)

# Another variant_dsl example with multiple parameter types
variant Result:
  Success(value: int)
  Failure(msg: string, code: int)
  Pending()

type ResultUnion = union(Result, string)

# ============================================================================
# Test Suite
# ============================================================================

suite "Variant Object Equality - Error and Solution":

  test "variant object without custom == fails at compile-time":
    # Verify that union creation fails without custom ==
    const willFail = not compiles(
      type ColorUnion = union(ColorWithoutEq, string)
    )

    check willFail == true

    # The actual error message (when attempted) includes:
    # - Problem explanation: variant objects need custom ==
    # - Complete solution with code example
    # - Step-by-step implementation guide
    # - Reference to solution test files

  test "variant_dsl auto-generates == and works perfectly":
    # Create Status values using variant_dsl
    let ready = Status.Ready()
    let loading = Status.Loading(50)
    let error = Status.Error("timeout")

    # Create union values - works because == is auto-generated!
    let u1 = StatusUnion.init(ready)
    let u2 = StatusUnion.init(loading)
    let u3 = StatusUnion.init(error)
    let u4 = StatusUnion.init("unknown")

    # Type checking works
    check u1.holds(Status)
    check u2.holds(Status)
    check u3.holds(Status)
    check u4.holds(string)
    check not u4.holds(Status)

    # Equality works (using auto-generated ==)
    let u5 = StatusUnion.init(Status.Ready())
    check u1 == u5  # Both Ready()

    let u6 = StatusUnion.init(Status.Loading(50))
    check u2 == u6  # Same progress

    # Value extraction works
    let extracted = u2.get(Status)
    check extracted.kind == skLoading
    check extracted.progress == 50

  test "variant_dsl supports zero-param, single-param, and multi-param variants":
    # Using Result and ResultUnion declared at module level

    # Zero-param
    let pending = Result.Pending()
    let up = ResultUnion.init(pending)
    check up.holds(Result)

    # Single-param
    let success = Result.Success(42)
    let us = ResultUnion.init(success)
    check us.holds(Result)

    # Multi-param
    let failure = Result.Failure("not found", 404)
    let uf = ResultUnion.init(failure)
    check uf.holds(Result)

    # Equality works for all
    let up2 = ResultUnion.init(Result.Pending())
    check up == up2

# ============================================================================
# Summary
# ============================================================================
##
## This test demonstrates two approaches:
##
## 1. **Without variant_dsl**: Manual variant objects need custom ==
##    - Compile-time error with comprehensive guidance
##    - User must define == operator manually
##    - See test_union_variant_equality_solution.nim for examples
##
## 2. **With variant_dsl**: Automatic == generation
##    - Zero boilerplate
##    - Works immediately with unions
##    - Supports all variant patterns (zero/single/multi param)
##    - Recommended for new code!
##
## **Recommendation**: Use variant_dsl for cleaner, safer code!
