## Union Type Bug: Reference and Pointer Types
## =============================================
##
## BUG DESCRIPTION:
## Union types fail to compile when using reference types (ref T) or pointer types (ptr T)
## because the generated `$` operator tries to stringify the reference/pointer directly,
## but Nim doesn't provide `$` operators for `ref int`, `ref string`, `ptr int`, etc.
##
## ROOT CAUSE:
## 1. The `generateTypeSignature` proc in union_type.nim doesn't handle nnkRefTy or nnkPtrTy nodes
## 2. The generated `$` proc (line 882-909) calls `$u.fieldN` directly without checking if
##    the type is a reference/pointer that needs dereferencing
## 3. The generated `==` proc works because Nim provides == for refs (pointer comparison),
##    but `$` fails for basic ref types
##
## EXPECTED BEHAVIOR (after fix):
## - ref types should work correctly: `ref int` and `int` should be distinct types in the union
## - String representation should handle refs by dereferencing: $r should work
## - Equality should work correctly (already does via pointer comparison)
## - Pattern matching should work with ref types
##
## TEST STRATEGY:
## The workaround tests use type aliases with custom $ operators.
## The bug demonstration tests show what SHOULD work after the fix.

import unittest
import ../../union_type
import ../../pattern_matching
import std/[options, strutils]

# ============================================================================
# WORKAROUND TYPE DEFINITIONS - These work by providing custom $ operators
# ============================================================================

type
  RefInt = ref int
  RefString = ref string

# Provide $ operators for ref types
proc `$`(r: RefInt): string =
  if r.isNil: "nil" else: $r[]

proc `$`(r: RefString): string =
  if r.isNil: "nil" else: $r[]

# NOW the union should work (with the workaround)
type
  RefUnionWorkaround = union(RefInt, RefString)
  RefIntUnion = union(RefInt, string)

# ============================================================================
# AFTER FIX: These types should now compile successfully
# ============================================================================

# These should now work with the fix:
type RefUnionDirect = union(ref int, ref string)
type PtrUnionDirect = union(ptr int, ptr string)
type MixedUnion = union(int, ref int)

# ============================================================================
# TEST SUITE
# ============================================================================

suite "Union Type - Reference and Pointer Types Bug":

  test "WORKAROUND: Using type aliases with custom $ operators":
    let ri = new int
    ri[] = 42
    let u1 = RefUnionWorkaround.init(ri)
    check $u1 == "42"

    let rs = new string
    rs[] = "hello"
    let u2 = RefUnionWorkaround.init(rs)
    check $u2 == "hello"

    # Type checking works
    check u1.holds(RefInt)
    check not u1.holds(RefString)
    check u2.holds(RefString)
    check not u2.holds(RefInt)

  test "WORKAROUND: nil ref handling with custom $ operator":
    let nilRef: RefInt = nil
    let u = RefIntUnion.init(nilRef)
    check $u == "nil"

    let validRef = new int
    validRef[] = 100
    let u2 = RefIntUnion.init(validRef)
    check $u2 == "100"

  test "WORKAROUND: Pattern matching with ref types":
    let ri = new int
    ri[] = 42
    let u = RefUnionWorkaround.init(ri)

    # Pattern matching works with workaround
    let msg = match u:
      RefUnionWorkaround(kind: ukRefInt, val0: v): "int: " & $v
      RefUnionWorkaround(kind: ukRefString, val1: s): "string: " & $s

    check msg == "int: 42"

  test "WORKAROUND: Extraction methods work with ref types":
    let ri = new int
    ri[] = 99
    let u = RefUnionWorkaround.init(ri)

    # get() works
    let extracted = u.get(RefInt)
    check extracted[] == 99

    # tryGet() works
    let maybe = u.tryGet(RefInt)
    check maybe.isSome
    check maybe.get()[] == 99

    let maybeStr = u.tryGet(RefString)
    check maybeStr.isNone

  test "WORKAROUND: Equality comparison with ref types":
    let r1 = new int
    r1[] = 42
    let r2 = new int
    r2[] = 42

    let u1 = RefUnionWorkaround.init(r1)
    let u2 = RefUnionWorkaround.init(r2)
    let u3 = RefUnionWorkaround.init(r1)  # Same reference

    # Different references with same value are not equal (pointer comparison)
    check u1 != u2

    # Same reference is equal
    check u1 == u3

  test "FIXED: Direct ref types now work":
    # This now works with the fix!
    let ri = new int
    ri[] = 42
    let u = RefUnionDirect.init(ri)
    check $u == "42"

    let rs = new string
    rs[] = "hello"
    let u2 = RefUnionDirect.init(rs)
    check $u2 == "hello"

  test "FIXED: Direct ptr types now work":
    # This now works with the fix!
    var x = 42
    let u = PtrUnionDirect.init(addr x)
    check $u == "42"

    var s = "world"
    let u2 = PtrUnionDirect.init(addr s)
    check $u2 == "world"

  test "FIXED: Mixed ref and value types work":
    # This now works with the fix!
    let u1 = MixedUnion.init(42)
    check $u1 == "42"
    check u1.holds(int)
    check not u1.holds(ref int)

    let ri = new int
    ri[] = 100
    let u2 = MixedUnion.init(ri)
    check $u2 == "100"
    check not u2.holds(int)
    check u2.holds(ref int)

  test "FIXED: nil refs stringify correctly":
    let nilRef: ref int = nil
    let u = RefUnionDirect.init(nilRef)
    check $u == "nil"

  test "FIXED: ref int and int are distinct types":
    # Verify type signatures are different
    let u1 = MixedUnion.init(42)
    let ri = new int
    ri[] = 42
    let u2 = MixedUnion.init(ri)

    # Same value, different types
    check $u1 == "42"
    check $u2 == "42"
    check u1.holds(int)
    check u2.holds(ref int)

  test "FIXED: repr() shows ref type format":
    # repr() uses Nim's system.repr() - shows "ref value" format
    let ri = new int
    ri[] = 99
    let u = RefUnionDirect.init(ri)

    # $ shows user-friendly value
    check $u == "99"

    # repr() shows Nim's standard ref format: "ref 99"
    let debugStr = repr(u)
    check debugStr == "ref 99"

  test "FIXED: repr() for nil refs":
    let nilRef: ref int = nil
    let u = RefUnionDirect.init(nilRef)

    # Both $ and repr() show "nil"
    check $u == "nil"
    check repr(u) == "nil"

  test "FIXED: repr() shows ptr type format":
    var x = 123
    let u = PtrUnionDirect.init(addr x)

    # $ shows value
    check $u == "123"

    # repr() shows Nim's standard ptr format: "ptr 123"
    let debugStr = repr(u)
    check debugStr == "ptr 123"

  test "FIXED: repr() for normal types same as $":
    let u = MixedUnion.init(42)

    # For normal types, repr() same as $
    check $u == "42"
    check repr(u) == "42"

## ============================================================================
## SUMMARY OF BUG
## ============================================================================
##
## The union type implementation doesn't properly handle reference (ref T) and
## pointer (ptr T) types when they are used directly (not as type aliases).
##
## Issues:
## 1. generateTypeSignature() in union_type.nim:420-482 doesn't handle nnkRefTy or nnkPtrTy nodes
##    - Falls through to else case which uses repr
##    - Doesn't generate proper type signatures for ref/ptr types
## 2. Generated $ operator (union_type.nim:882-909) calls `$u.fieldN` directly
##    - Works for types that have $ operators
##    - FAILS for ref int, ref string, ptr int, ptr string (no $ operators in stdlib)
## 3. No compile-time validation to warn users about this limitation
##
## Fix Requirements:
## 1. Update generateTypeSignature() to handle nnkRefTy and nnkPtrTy:
##    - ref int → "Ref_int"
##    - ptr string → "Ptr_string"
##    - This ensures ref int ≠ int in type signatures
##
## 2. Update $ operator generation to detect and handle ref/ptr types:
##    - Check if field type is nnkRefTy or nnkPtrTy
##    - Generate deref code: if not value.isNil: $(value[]) else: "nil"
##    - This makes $ work for all ref/ptr types
##
## 3. Consider equality operator:
##    - Current: pointer comparison (works but might not be desired)
##    - Option: value comparison (dereference and compare values)
##    - Document the behavior clearly
##
## Current Workaround:
##   type RefInt = ref int
##   proc `$`(r: RefInt): string = if r.isNil: "nil" else: $r[]
##   type MyUnion = union(RefInt, string)  # Now works!
##
## After Fix:
##   type MyUnion = union(ref int, string)  # Should work directly!
##   let r = new int
##   r[] = 42
##   let u = MyUnion.init(r)
##   check $u == "42"  # Should work without workarounds
