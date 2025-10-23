## Comprehensive Negative Tests for Variant Object Pattern Errors
## =================================================================
##
## This test suite validates compile-time error detection for invalid variant
## object patterns in the Nim pattern matching library.
##
## Test Categories:
## 1. Wrong variant constructor names (non-existent constructors)
## 2. Accessing fields from wrong variant branch (branch safety violations)
## 3. Invalid discriminator values (wrong discriminator patterns)
## 4. Missing discriminator field (patterns without discriminator)
## 5. UFCS constructor syntax errors (Status.InvalidConstructor)
## 6. Field count mismatches (wrong number of fields for variant constructor)
## 7. Type name mismatches in UFCS patterns
## 8. Typo detection and suggestions
##
## All tests use `shouldNotCompile` template to verify compile-time rejection.

import unittest
import ../../pattern_matching
import ../../variant_dsl

suite "Negative Tests: Variant Object Errors":

  template shouldNotCompile(code: untyped): bool =
    not compiles(code)

  template shouldCompile(code: untyped): bool =
    compiles(code)

  # =========================================================================
  # Category 1: Wrong Variant Constructor Names
  # =========================================================================

  test "wrong variant constructor name - non-existent constructor":
    check shouldNotCompile (
      block:
        variant Status:
          Active(code: int)
          Inactive()

        let s = Status.Active(200)
        let result = match s:
          Status.Pending(): "pending"  # Pending doesn't exist
          _: "other"
    )

  test "wrong variant constructor name - typo in constructor":
    check shouldNotCompile (
      block:
        variant Status:
          Active(code: int)
          Inactive()

        let s = Status.Active(200)
        let result = match s:
          Status.Activ(200): "active"  # Typo: Activ instead of Active
          _: "other"
    )

  test "wrong variant constructor name - case mismatch":
    check shouldNotCompile (
      block:
        variant Status:
          Active(code: int)
          Inactive()

        let s = Status.Active(200)
        let result = match s:
          Status.active(200): "active"  # Wrong case: active instead of Active
          _: "other"
    )

  test "wrong variant constructor name - completely invalid":
    check shouldNotCompile (
      block:
        variant Result:
          Success(value: string)
          Error(message: string)

        let r = Result.Success("ok")
        let result = match r:
          Result.Failure("msg"): "failure"  # Failure doesn't exist
          _: "other"
    )

  # =========================================================================
  # Category 2: Accessing Fields from Wrong Variant Branch
  # =========================================================================

  test "branch safety violation - accessing field from different branch (traditional syntax)":
    check shouldNotCompile (
      block:
        type
          Kind = enum kInt, kStr
          Value = object
            case kind: Kind
            of kInt: intVal: int
            of kStr: strVal: string

        let v = Value(kind: kInt, intVal: 42)
        let result = match v:
          Value(kind: kInt, strVal: s): s  # strVal doesn't exist in kInt branch
          _: "other"
    )

  test "branch safety violation - field from wrong branch in nested variant":
    check shouldNotCompile (
      block:
        type
          InnerKind = enum ikA, ikB
          Inner = object
            case kind: InnerKind
            of ikA: valA: int
            of ikB: valB: string

          OuterKind = enum okX, okY
          Outer = object
            case kind: OuterKind
            of okX: innerX: Inner
            of okY: valY: float

        let obj = Outer(kind: okX, innerX: Inner(kind: ikA, valA: 99))
        let result = match obj:
          Outer(kind: okX, innerX: Inner(kind: ikA, valB: v)): v  # valB is in ikB branch
          _: "other"
    )

  test "branch safety violation - multiple wrong fields":
    check shouldNotCompile (
      block:
        type
          NodeKind = enum nkEmpty, nkLeaf, nkBranch
          Node = object
            case kind: NodeKind
            of nkEmpty: discard
            of nkLeaf: leafValue: int
            of nkBranch:
              left: int
              right: int

        let n = Node(kind: nkLeaf, leafValue: 42)
        let result = match n:
          Node(kind: nkLeaf, left: l, right: r): $l  # left/right are in nkBranch
          _: "other"
    )

  # =========================================================================
  # Category 3: Invalid Discriminator Values
  # =========================================================================

  test "invalid discriminator value - enum value doesn't exist":
    check shouldNotCompile (
      block:
        type
          Kind = enum kInt, kStr
          Value = object
            case kind: Kind
            of kInt: intVal: int
            of kStr: strVal: string

        let v = Value(kind: kInt, intVal: 42)
        let result = match v:
          Value(kind: kFloat, floatVal: f): $f  # kFloat doesn't exist in Kind enum
          _: "other"
    )

  test "invalid discriminator value - wrong type":
    check shouldNotCompile (
      block:
        type
          Kind = enum kInt, kStr
          Value = object
            case kind: Kind
            of kInt: intVal: int
            of kStr: strVal: string

        let v = Value(kind: kInt, intVal: 42)
        let result = match v:
          Value(kind: "kInt", intVal: x): $x  # String instead of enum
          _: "other"
    )

  test "invalid discriminator value - integer instead of enum":
    check shouldNotCompile (
      block:
        type
          Kind = enum kInt, kStr
          Value = object
            case kind: Kind
            of kInt: intVal: int
            of kStr: strVal: string

        let v = Value(kind: kInt, intVal: 42)
        let result = match v:
          Value(kind: 0, intVal: x): $x  # 0 instead of kInt
          _: "other"
    )

  # =========================================================================
  # Category 4: Missing Discriminator Field
  # =========================================================================

  test "missing discriminator field - no kind specified":
    check shouldNotCompile (
      block:
        type
          Kind = enum kInt, kStr
          Value = object
            case kind: Kind
            of kInt: intVal: int
            of kStr: strVal: string

        let v = Value(kind: kInt, intVal: 42)
        let result = match v:
          Value(intVal: x): $x  # Missing discriminator field 'kind'
          _: "other"
    )

  test "missing discriminator field - accessing branch-specific field without discriminator":
    check shouldNotCompile (
      block:
        type
          NodeKind = enum nkEmpty, nkLeaf, nkBranch
          Node = object
            case kind: NodeKind
            of nkEmpty: discard
            of nkLeaf: leafValue: int
            of nkBranch:
              left: int
              right: int

        let n = Node(kind: nkLeaf, leafValue: 42)
        let result = match n:
          Node(leafValue: v): $v  # Missing discriminator 'kind'
          _: "other"
    )

  # =========================================================================
  # Category 5: UFCS Constructor Syntax Errors
  # =========================================================================

  test "UFCS - invalid constructor name":
    check shouldNotCompile (
      block:
        variant Status:
          Active(code: int)
          Inactive()

        let s = Status.Active(200)
        let result = match s:
          Status.InvalidConstructor(): "invalid"  # InvalidConstructor doesn't exist
          _: "other"
    )

  test "UFCS - wrong type name in pattern":
    check shouldNotCompile (
      block:
        variant Status:
          Active(code: int)
          Inactive()

        let s = Status.Active(200)
        let result = match s:
          Result.Active(200): "active"  # Result type doesn't exist
          _: "other"
    )

  test "UFCS - type name doesn't match scrutinee":
    check shouldNotCompile (
      block:
        variant Status:
          Active(code: int)
          Inactive()

        variant Result:
          Success(value: string)
          Error(message: string)

        let s = Status.Active(200)
        let result = match s:
          Result.Success("ok"): "success"  # Wrong type: Result instead of Status
          _: "other"
    )

  test "UFCS - constructor with wrong field count (too few fields with wildcard)":
    check shouldNotCompile (
      block:
        variant Result:
          Success(value: string, code: int)
          Error(message: string)

        let r = Result.Success("ok", 200)
        let result = match r:
          Result.Success(_): "success"  # Missing one field - has 2, provides 1
          _: "other"
    )

  test "UFCS - constructor with extra parameters":
    check shouldNotCompile (
      block:
        variant Status:
          Active(code: int)
          Inactive()

        let s = Status.Inactive()
        let result = match s:
          Status.Inactive(999): "inactive"  # Inactive has no parameters
          _: "other"
    )

  # =========================================================================
  # Category 6: Field Count Mismatches
  # =========================================================================

  test "field count mismatch - too many fields in pattern":
    check shouldNotCompile (
      block:
        variant Result:
          Success(value: string)
          Error(message: string)

        let r = Result.Success("ok")
        let result = match r:
          Result.Success(value, extra): "success"  # Too many fields
          _: "other"
    )

  test "field count mismatch - too few fields in pattern":
    check shouldNotCompile (
      block:
        variant Complex:
          Data(x: int, y: int, z: int)
          Empty()

        let c = Complex.Data(1, 2, 3)
        let result = match c:
          Complex.Data(x, y): "partial"  # Missing field z
          _: "other"
    )

  test "field count mismatch - no fields when fields required (using wildcard pattern)":
    check shouldNotCompile (
      block:
        variant Result:
          Success(value: string, status: int)
          Error(message: string)

        let r = Result.Success("ok", 200)
        let result = match r:
          Result.Success(_): "empty"  # Success requires 2 fields but provides 1
          _: "other"
    )

  test "field count mismatch - fields provided when none expected":
    check shouldNotCompile (
      block:
        variant Status:
          Active(code: int)
          Inactive()

        let s = Status.Inactive()
        let result = match s:
          Status.Inactive(x): "inactive"  # Inactive has no fields
          _: "other"
    )

  # =========================================================================
  # Category 7: Type Name Mismatches in UFCS Patterns
  # =========================================================================

  test "UFCS type mismatch - completely different type":
    check shouldNotCompile (
      block:
        variant Status:
          Active(code: int)
          Inactive()

        type Point = object
          x: int
          y: int

        let s = Status.Active(200)
        let result = match s:
          Point.Active(200): "wrong type"  # Point is not Status
          _: "other"
    )

  test "UFCS type mismatch - similar name but different type":
    check shouldNotCompile (
      block:
        variant StatusA:
          Active(code: int)
          Inactive()

        variant StatusB:
          Active(code: int)
          Inactive()

        let s = StatusA.Active(200)
        let result = match s:
          StatusB.Active(200): "wrong variant"  # StatusB is not StatusA
          _: "other"
    )

  # =========================================================================
  # Category 8: Typo Detection and Suggestions
  # =========================================================================

  test "typo detection - single character difference in constructor":
    check shouldNotCompile (
      block:
        variant Result:
          Success(value: string)
          Error(message: string)

        let r = Result.Success("ok")
        let result = match r:
          Result.Succes("ok"): "typo"  # Succes instead of Success
          _: "other"
    )

  test "typo detection - transposed characters in constructor":
    check shouldNotCompile (
      block:
        variant Status:
          Active(code: int)
          Inactive()

        let s = Status.Active(200)
        let result = match s:
          Status.Acitve(200): "typo"  # Acitve instead of Active
          _: "other"
    )

  test "typo detection - missing character in field name":
    check shouldNotCompile (
      block:
        type
          Kind = enum kInt, kStr
          Value = object
            case kind: Kind
            of kInt: intValue: int
            of kStr: strValue: string

        let v = Value(kind: kInt, intValue: 42)
        let result = match v:
          Value(kind: kInt, intValu: x): $x  # intValu instead of intValue
          _: "other"
    )

  test "typo detection - wrong discriminator field name":
    check shouldNotCompile (
      block:
        type
          Kind = enum kInt, kStr
          Value = object
            case kind: Kind
            of kInt: intVal: int
            of kStr: strVal: string

        let v = Value(kind: kInt, intVal: 42)
        let result = match v:
          Value(knd: kInt, intVal: x): $x  # knd instead of kind
          _: "other"
    )

  # =========================================================================
  # Category 9: Complex Nested Variant Errors
  # =========================================================================

  test "nested variant - wrong inner constructor":
    check shouldNotCompile (
      block:
        variant Inner:
          Value(x: int)
          Empty()

        variant Outer:
          Contains(inner: Inner)
          Nothing()

        let o = Outer.Contains(Inner.Value(42))
        let result = match o:
          Outer.Contains(Inner.Invalid(x)): $x  # Invalid constructor in Inner
          _: "other"
    )

  test "nested variant - wrong discriminator in nested variant":
    check shouldNotCompile (
      block:
        type
          InnerKind = enum ikA, ikB
          Inner = object
            case kind: InnerKind
            of ikA: valA: int
            of ikB: valB: string

          OuterKind = enum okX, okY
          Outer = object
            case kind: OuterKind
            of okX: innerX: Inner
            of okY: valY: float

        let obj = Outer(kind: okX, innerX: Inner(kind: ikA, valA: 99))
        let result = match obj:
          Outer(kind: okX, innerX: Inner(kind: ikC, valC: v)): $v  # ikC doesn't exist
          _: "other"
    )

  test "nested variant - field from wrong branch in nested structure":
    check shouldNotCompile (
      block:
        type
          L2Kind = enum l2A, l2B
          L2 = object
            case kind: L2Kind
            of l2A: valA: int
            of l2B: valB: string

          L1Kind = enum l1X, l1Y
          L1 = object
            case kind: L1Kind
            of l1X: l2x: L2
            of l1Y: valY: float

        let obj = L1(kind: l1X, l2x: L2(kind: l2A, valA: 99))
        let result = match obj:
          L1(kind: l1X, l2x: L2(kind: l2A, valB: v)): v  # valB is in l2B branch
          _: "other"
    )

  # =========================================================================
  # Category 10: Mixed Traditional and UFCS Syntax Errors
  # =========================================================================

  test "mixing UFCS and traditional syntax incorrectly":
    check shouldNotCompile (
      block:
        variant Status:
          Active(code: int)
          Inactive()

        let s = Status.Active(200)
        let result = match s:
          Status.Active(kind: sActive, code: 200): "mixed"  # Can't mix UFCS with explicit kind
          _: "other"
    )

  test "UFCS with explicit discriminator field":
    check shouldNotCompile (
      block:
        variant Result:
          Success(value: string)
          Error(message: string)

        let r = Result.Success("ok")
        let result = match r:
          Result.Success(kind: rSuccess, value: "ok"): "explicit"  # UFCS shouldn't have explicit kind
          _: "other"
    )

  # =========================================================================
  # Category 11: Edge Cases
  # =========================================================================

  test "empty variant constructor with parameters in pattern":
    check shouldNotCompile (
      block:
        variant Status:
          Active(code: int)
          Inactive()

        let s = Status.Inactive()
        let result = match s:
          Status.Inactive(bogus): "invalid"  # Inactive has no parameters
          _: "other"
    )

  test "wrong parameter type in UFCS pattern":
    check shouldNotCompile (
      block:
        variant Result:
          Success(value: string)
          Error(message: string)

        let r = Result.Success("ok")
        let result = match r:
          Result.Success(42): "wrong type"  # 42 is int, should be string
          _: "other"
    )

  test "multiple constructors in single pattern":
    check shouldNotCompile (
      block:
        variant Status:
          Active(code: int)
          Inactive()

        let s = Status.Active(200)
        let result = match s:
          Status.Active(200).Inactive(): "invalid"  # Can't chain constructors
          _: "other"
    )

  # NOTE: This test is commented out because without explicit UFCS validation,
  # the pattern matching library may fall back to treating "Active(200)" as
  # a general object pattern, which could match if there's an Active type in scope.
  # This is a known limitation - UFCS patterns require the Type.Constructor syntax.
  #
  # test "variant pattern without type prefix":
  #   check shouldNotCompile (
  #     block:
  #       variant Status:
  #         Active(code: int)
  #         Inactive()
  #
  #       let s = Status.Active(200)
  #       let result = match s:
  #         Active(200): "missing type"  # Should be Status.Active(200)
  #         _: "other"
  #   )

  # =========================================================================
  # Positive Control Tests - Verify Valid Patterns Compile
  # =========================================================================

  test "CONTROL: valid UFCS pattern compiles":
    check shouldCompile (
      block:
        variant Status:
          Active(code: int)
          Inactive()

        let s = Status.Active(200)
        let result = match s:
          Status.Active(200): "active"
          Status.Inactive(): "inactive"
          _: "other"
    )

  test "CONTROL: valid traditional variant pattern compiles":
    check shouldCompile (
      block:
        type
          Kind = enum kInt, kStr
          Value = object
            case kind: Kind
            of kInt: intVal: int
            of kStr: strVal: string

        let v = Value(kind: kInt, intVal: 42)
        let result = match v:
          Value(kind: kInt, intVal: x): $x
          _: "other"
    )

  test "CONTROL: valid nested variant pattern compiles":
    check shouldCompile (
      block:
        variant Inner:
          Value(x: int)
          Empty()

        variant Outer:
          Contains(inner: Inner)
          Nothing()

        let o = Outer.Contains(Inner.Value(42))
        let result = match o:
          Outer.Contains(Inner.Value(x)): $x
          _: "other"
    )
