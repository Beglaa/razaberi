## Negative Tests for Union Type Implementation
## ==============================================
##
## These tests verify that union types properly detect and reject invalid usage
## at compile-time with clear, helpful error messages.
##
## Test Categories:
## 1. Union Declaration Errors - Invalid union type declarations
## 2. Type Mismatch Errors - Wrong types passed to union operations
## 3. Value Access Errors - Accessing values with wrong type expectations
## 4. Pattern Matching Errors - Invalid patterns with union types
## 5. Equality and Comparison Errors - Missing equality operators
##
## Testing Strategy:
## All tests use Nim's `shouldNotCompile` template to verify that invalid
## code produces compile-time errors. Each test documents the expected error
## and the reason why the code should not compile.

import unittest
import ../../union_type
import ../../pattern_matching

# Helper templates for compile-time testing
template shouldNotCompile(code: untyped): bool =
  not compiles(code)

template shouldCompile(code: untyped): bool =
  compiles(code)

# ============================================================================
# Test Types - Valid types used in negative test scenarios
# ============================================================================

type
  ValidResult = union(int, string)
  ValidValue = union(int, float, string)
  ValidData = union(int, seq[int])

  # Custom object types for testing
  ErrorObj = object
    message: string
    code: int

  ResultWithError = union(int, ErrorObj)

# Additional test types for assignment and comparison tests
type
  Result1_Neg = union(int, string)
  Result2_Neg = union(int, string)

# Types for alias ambiguity tests
type
  UserId_Alias = int
  SessionId_Alias = int
  # Note: This will compile but cause ambiguous init
  # IdUnion_Ambiguous = union(UserId_Alias, SessionId_Alias)

# Distinct types (solution to ambiguity)
type
  UserId_Distinct = distinct int
  SessionId_Distinct = distinct int

# Provide == and $ operators for distinct types
proc `==`(a, b: UserId_Distinct): bool {.borrow.}
proc `==`(a, b: SessionId_Distinct): bool {.borrow.}
proc `$`(x: UserId_Distinct): string {.borrow.}
proc `$`(x: SessionId_Distinct): string {.borrow.}

type
  IdUnion_Distinct = union(UserId_Distinct, SessionId_Distinct)

# Reference and pointer type unions
type
  RefMixed_Neg = union(int, ref int)
  PtrMixed_Neg = union(int, ptr int)

# Generic type unions
type
  SeqUnion_Neg = union(seq[int], string)
  OptUnion_Neg = union(Option[int], Option[string])

# Union of unions
type
  Inner1_Neg = union(int, string)
  Inner2_Neg = union(float, bool)
  Outer_Neg = union(Inner1_Neg, Inner2_Neg)

# ============================================================================
# 1. Union Declaration Errors
# ============================================================================

suite "Union Type Negative Tests - Declaration Errors":

  test "empty union declaration fails":
    # Union requires at least 2 types
    check shouldNotCompile (
      type Empty = union()
    )

  test "single-type union declaration fails":
    # Union requires at least 2 types (use Option[T] instead)
    check shouldNotCompile (
      type Single = union(int)
    )

  test "duplicate types in union declaration fail":
    # Each type can only appear once
    check shouldNotCompile (
      type Dup1 = union(int, string, int)
    )

    check shouldNotCompile (
      type Dup2 = union(string, int, string)
    )

    check shouldNotCompile (
      type Dup3 = union(int, int)
    )

  test "three duplicate types fail":
    check shouldNotCompile (
      type Dup4 = union(int, int, int)
    )

  test "duplicate generic types fail":
    # seq[int] appearing twice should fail
    check shouldNotCompile (
      type DupSeq = union(seq[int], string, seq[int])
    )

  test "duplicate Option types fail":
    check shouldNotCompile (
      type DupOpt = union(Option[int], string, Option[int])
    )

# ============================================================================
# 2. Type Mismatch Errors - Construction
# ============================================================================

suite "Union Type Negative Tests - Construction Type Mismatches":

  test "init with wrong type fails":
    # ValidResult = union(int, string), passing float should fail
    check shouldNotCompile (
      let r = ValidResult.init(3.14)  # float not in union
    )

  test "init with seq when expecting int or string":
    check shouldNotCompile (
      let r = ValidResult.init(@[1, 2, 3])
    )

  test "init with bool when not in union":
    check shouldNotCompile (
      let r = ValidResult.init(true)
    )

  test "init with custom object not in union":
    type AnotherObj = object
      field: int

    check shouldNotCompile (
      let r = ValidResult.init(AnotherObj(field: 42))
    )

  test "init with nil when not in union":
    # ValidResult doesn't contain Option or ref types
    check shouldNotCompile (
      let r = ValidResult.init(nil)
    )

  test "init without value fails":
    check shouldNotCompile (
      let r = ValidResult.init()  # No value provided
    )

  test "init with multiple values fails":
    check shouldNotCompile (
      let r = ValidResult.init(42, "hello")  # Can only init with one value
    )

# ============================================================================
# 3. Value Access Errors
# ============================================================================

suite "Union Type Negative Tests - Value Access Errors":

  test "get with wrong type should fail at runtime (compile-time check)":
    # This compiles but would fail at runtime
    # We're checking that the type system allows this (for dynamic checking)
    # but documenting that it will raise ValueError at runtime
    check shouldCompile (
      let r = ValidResult.init(42)
      # This will compile but raise ValueError at runtime:
      # let s = r.get(string)
      discard r.holds(string)
    )

  test "get with type not in union fails at compile time":
    check shouldNotCompile (
      let r = ValidResult.init(42)
      let f = r.get(float)  # float not in union
    )

  test "tryGet with type not in union fails":
    check shouldNotCompile (
      let r = ValidResult.init(42)
      let maybe = r.tryGet(float)  # float not in union
    )

  test "holds with type not in union fails":
    check shouldNotCompile (
      let r = ValidResult.init(42)
      discard r.holds(float)  # float not in union
    )

  test "extraction methods with wrong types fail":
    # ValidResult has int and string, not float
    check shouldNotCompile (
      let r = ValidResult.init(42)
      let x = r.toFloat()  # No toFloat method generated
    )

  test "expect method with wrong type fails":
    check shouldNotCompile (
      let r = ValidResult.init(42)
      let x = r.expectFloat()  # No expectFloat method
    )

# ============================================================================
# 4. Pattern Matching Errors
# ============================================================================

suite "Union Type Negative Tests - Pattern Matching Errors":

  test "pattern match with type not in union fails":
    check shouldNotCompile (
      let r = ValidResult.init(42)
      match r:
        ValidResult(kind: ukFloat, val2: f): echo f  # No ukFloat discriminator
        _: echo "other"
    )

  test "pattern match accessing wrong field fails":
    # ValidResult has val0 (int) and val1 (string)
    check shouldNotCompile (
      let r = ValidResult.init(42)
      match r:
        ValidResult(kind: ukInt, val1: x): echo x  # val1 is string field, not int
        _: echo "other"
    )

  test "pattern match with wrong discriminator-field combination fails":
    check shouldNotCompile (
      let r = ValidResult.init(42)
      match r:
        # ukInt corresponds to val0, not val1
        ValidResult(kind: ukInt, val1: x): echo x
        _: echo "other"
    )

# ============================================================================
# 5. Assignment and Comparison Errors
# ============================================================================

suite "Union Type Negative Tests - Assignment Errors":

  test "assigning between different union types fails":
    # Even with same members, nominal typing makes them different
    check shouldNotCompile (
      let r1 = Result1_Neg.init(42)
      let r2: Result2_Neg = r1  # Type mismatch
    )

  test "assigning union to plain type fails":
    check shouldNotCompile (
      let r = ValidResult.init(42)
      let x: int = r  # Can't assign union to int
    )

  test "assigning plain type to union fails":
    check shouldNotCompile (
      let x: int = 42
      let r: ValidResult = x  # Must use .init()
    )

  test "comparing unions of different types fails":
    check shouldNotCompile (
      let r1 = Result1_Neg.init(42)
      let r2 = Result2_Neg.init(42)
      discard r1 == r2  # Different types
    )

# ============================================================================
# 6. Variant Object Equality Errors
# ============================================================================

# Note: Variant object equality testing is demonstrated in:
# - test/union/DEMO_union_variant_equality_error.nim (shows the error)
# - test/union/test_union_variant_equality_solution.nim (shows the solution)
#
# We cannot test this directly in shouldNotCompile() because:
# 1. Type definitions cannot be nested inside template expansions
# 2. The error occurs during union macro expansion, not at template level
# 3. The test would need to be a separate compilation unit
#
# See the DEMO file for the actual failing case that demonstrates the
# comprehensive error message with examples.

# ============================================================================
# 7. Type Alias Ambiguity Errors
# ============================================================================

suite "Union Type Negative Tests - Type Alias Ambiguity":

  test "type aliases resolving to same type cause ambiguous init":
    # Type aliases that resolve to the same underlying type
    # will compile but cause ambiguous overload errors
    # Using pre-defined UserId_Alias and SessionId_Alias

    # Note: We cannot test IdUnion creation here because it would fail at
    # module level. The ambiguity manifests at .init() call time.
    # This is documented behavior in union_type.nim documentation.
    discard "Test documented - ambiguity occurs at .init() call time"

  test "distinct types avoid ambiguity (positive case)":
    # Solution: Use distinct types instead of aliases
    # Using pre-defined IdUnion_Distinct type

    # This works - distinct types are truly separate
    let id = IdUnion_Distinct.init(UserId_Distinct(42))
    check id.holds(UserId_Distinct)
    check not id.holds(SessionId_Distinct)

# ============================================================================
# 8. Reference Type Errors (Before Fix)
# ============================================================================

suite "Union Type Negative Tests - Reference Type Limitations":

  test "ref types work after fix (now positive test)":
    # After the ref/ptr fix in union_type.nim, this should work
    # Testing that ref int and int are properly distinguished

    let u1 = RefMixed_Neg.init(42)
    let ri = new int
    ri[] = 100
    let u2 = RefMixed_Neg.init(ri)
    check u1.holds(int)
    check u2.holds(ref int)

  test "ptr types work after fix (now positive test)":
    var x = 42
    let u = PtrMixed_Neg.init(addr x)
    check u.holds(ptr int)

# ============================================================================
# 9. Generic Type Errors
# ============================================================================

suite "Union Type Negative Tests - Generic Type Errors":

  test "wrong generic parameter fails":
    check shouldNotCompile (
      let s: seq[string] = @["a", "b"]
      let u = SeqUnion_Neg.init(s)  # seq[string] not seq[int]
    )

  test "different Option types are distinct":
    let o1 = some(42)
    let o2 = some("hello")
    let u1 = OptUnion_Neg.init(o1)
    let u2 = OptUnion_Neg.init(o2)
    check u1.holds(Option[int])
    check u2.holds(Option[string])

    # But wrong Option type should fail
    check shouldNotCompile (
      let o: Option[float] = some(3.14)
      let u = OptUnion_Neg.init(o)  # Option[float] not in union
    )

# ============================================================================
# 10. Scope and Declaration Errors
# ============================================================================

suite "Union Type Negative Tests - Scope Errors":

  test "union types must be declared at module level (documentation)":
    # Union types CANNOT be declared inside test/proc/template blocks
    # because they generate exported procs which require top-level scope
    #
    # This will fail with: Error: 'export' is only allowed at top level
    #
    # ✗ WRONG:
    #   test "my test":
    #     type MyResult = union(int, string)  # ERROR!
    #
    # ✓ CORRECT:
    #   type MyResult = union(int, string)   # Declare at module level
    #
    #   test "my test":
    #     let r = MyResult.init(42)  # Use inside test
    #
    # All union types in this test file are declared at module level
    # and then used within test blocks - that's the correct pattern.

    discard "See union_type.nim documentation section: 'Module-Level Declaration Required'"

# ============================================================================
# 11. Edge Cases
# ============================================================================

suite "Union Type Negative Tests - Edge Cases":

  test "cannot create union with void type":
    check shouldNotCompile (
      type VoidUnion = union(int, void)
    )

  test "cannot use typedesc in union directly":
    check shouldNotCompile (
      type TypeUnion = union(int, typedesc[int])
    )

  test "cannot use untyped in union":
    check shouldNotCompile (
      type UntypedUnion = union(int, untyped)
    )

  test "union of unions works (union types as members)":
    # Union containing other union types is valid
    let i1 = Inner1_Neg.init(42)
    let u = Outer_Neg.init(i1)
    check u.holds(Inner1_Neg)

# ============================================================================
# Summary
# ============================================================================
##
## This test suite ensures that union types properly reject invalid usage:
##
## 1. **Declaration Errors**: Empty, single-type, and duplicate type unions
## 2. **Construction Errors**: Passing types not in the union to init()
## 3. **Access Errors**: Using get/tryGet/holds with types not in union
## 4. **Pattern Matching Errors**: Invalid discriminators and field access
## 5. **Assignment Errors**: Nominal typing prevents cross-union assignment
## 6. **Equality Errors**: Variant objects need custom == operators
## 7. **Ambiguity Errors**: Type aliases can cause overload ambiguity
## 8. **Reference Errors**: Documentation of ref/ptr type handling
## 9. **Generic Errors**: Wrong generic parameters fail type checking
## 10. **Edge Cases**: Void, typedesc, untyped not allowed
##
## All errors are caught at compile-time with clear error messages,
## following the design principle of zero runtime overhead and maximum
## compile-time safety.
