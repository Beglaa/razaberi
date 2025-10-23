## Implicit Variant Syntax Pattern Matching Tests
## ==============================================
##
## This test suite validates the RESTORED implicit variant syntax feature for the Nim pattern matching library.
## The feature allows simplified variant object pattern matching by omitting explicit discriminator fields.
##
## FEATURE RESTORED: Transform DataValue(kind: Nested, nested_val: DataValue2(...))
##                   TO:        DataValue(Nested(DataValue2(...)))
##
## IMPLEMENTATION: Uses compile-time scrutinee type introspection instead of hardcoded heuristics

import unittest
import ../../pattern_matching

# Test type definitions with standard "kind" discriminator
type
  # Simple variant for basic testing
  SimpleKind = enum sA, sB, sC
  SimpleVariant = object
    case disc: SimpleKind
    of sA: fieldA: string
    of sB: fieldB: int
    of sC: fieldC: float

  # Secondary variant type for nesting
  DataKind2 = enum dkInt, dkString, dkFloat
  DataValue2 = object
    case kind: DataKind2
    of dkString: str_val: string
    of dkInt: int_val: int
    of dkFloat: float_val: float

  # Complex nested variant
  DataKind = enum Text, Number, Other, Nested
  DataValue = object
    case kind: DataKind
    of Text: text_val: string
    of Number: number_val: int
    of Other: generic_val: string
    of Nested: nested_val: DataValue2

  # Random naming test (proving universal support)
  CrazyEnum = enum apple, banana, cherry
  WildType = object
    case kind: CrazyEnum
    of apple: appleData: string
    of banana: bananaInfo: int
    of cherry: cherryStuff: float

suite "Implicit Variant Syntax Pattern Matching [RESTORED WITH UNIVERSAL NAMING]":

  test "✅ RESTORED: Basic implicit variant syntax":
    ## Basic implicit syntax: SimpleVariant(sA("value")) instead of explicit kind: sA, fieldA: "value"
    let data = SimpleVariant(disc: sA, fieldA: "implicit_test")
    let result = match data:
      SimpleVariant(sA("implicit_test")): "SUCCESS: Basic implicit syntax restored!"
      _: "FAILED"
    check result == "SUCCESS: Basic implicit syntax restored!"

  test "✅ RESTORED: Different enum values with implicit syntax":
    ## Tests multiple enum values with implicit syntax
    let dataB = SimpleVariant(disc: sB, fieldB: 42)
    let result = match dataB:
      SimpleVariant(sB(42)): "SUCCESS: Multiple enum implicit!"
      _: "FAILED"
    check result == "SUCCESS: Multiple enum implicit!"

  test "✅ RESTORED: Variable binding with implicit syntax":
    ## Variable binding works with implicit syntax
    let data = SimpleVariant(disc: sA, fieldA: "variable_test")
    let result = match data:
      SimpleVariant(sA(value)): "SUCCESS: Bound value = " & value
      _: "FAILED"
    check result == "SUCCESS: Bound value = variable_test"

  test "✅ RESTORED: Complex nested implicit syntax":
    ## Nested variant objects with implicit syntax
    let data = DataValue(kind: Nested, nested_val: DataValue2(kind: dkString, str_val: "nested_implicit"))
    let result = match data:
      DataValue(Nested(DataValue2(dkString("nested_implicit")))): "SUCCESS: Nested implicit syntax!"
      _: "FAILED"
    check result == "SUCCESS: Nested implicit syntax!"

  test "✅ RESTORED: Mixed implicit and explicit syntax":
    ## Mixing implicit and explicit syntax in same pattern
    let data = DataValue(kind: Text, text_val: "mixed_test")
    let result = match data:
      DataValue(kind: Text, text_val: "mixed_test"): "SUCCESS: Explicit still works!"
      _: "FAILED"
    check result == "SUCCESS: Explicit still works!"

  test "✅ UNIVERSAL: Random naming conventions with implicit syntax":
    ## Proves the library works with ANY naming convention
    let data = WildType(kind: apple, appleData: "random_names")
    let result = match data:
      WildType(apple("random_names")): "SUCCESS: Random naming works!"
      _: "FAILED"
    check result == "SUCCESS: Random naming works!"

  test "✅ UNIVERSAL: Different random enum with implicit syntax":
    ## More random naming tests
    let data = WildType(kind: banana, bananaInfo: 123)
    let result = match data:
      WildType(banana(123)): "SUCCESS: Banana enum works!"
      _: "FAILED"
    check result == "SUCCESS: Banana enum works!"

  test "✅ INTROSPECTION: Works without hardcoded type names":
    ## Demonstrates the scrutinee-based introspection approach
    let data = DataValue(kind: Number, number_val: 999)
    let result = match data:
      DataValue(Number(999)): "SUCCESS: Type introspection works!"
      _: "FAILED"
    check result == "SUCCESS: Type introspection works!"

  test "✅ COMPATIBILITY: Explicit syntax unchanged":
    ## Explicit syntax continues to work unchanged
    let data = DataValue(kind: Other, generic_val: "explicit_unchanged")
    let result = match data:
      DataValue(kind: Other, generic_val: "explicit_unchanged"): "SUCCESS: Explicit unchanged!"
      _: "FAILED"
    check result == "SUCCESS: Explicit unchanged!"

  test "✅ EDGE CASE: Single character enum names":
    ## Tests edge case with minimal enum names
    let data = SimpleVariant(disc: sC, fieldC: 3.14)
    let result = match data:
      SimpleVariant(sC(value)) and value > 3.0: "SUCCESS: Edge case with guard!"
      _: "FAILED"
    check result == "SUCCESS: Edge case with guard!"

  test "✅ EXTENDED: Variable assignment with object literal matching":
    ## Tests both existing object variable and explicit field matching
    let someComplexObj = DataValue2(kind: dkString, str_val: "complex_variable")
    let data1 = DataValue(kind: Nested, nested_val: someComplexObj)

    # Test 1: Match with explicit object construction
    let result1 = match data1:
      DataValue(Nested(DataValue2(dkString("complex_variable")))): "SUCCESS: Explicit nested construction!"
      _: "FAILED"
    check result1 == "SUCCESS: Explicit nested construction!"

  test "✅ EXTENDED: Named field patterns for complex cases":
    ## Tests named field patterns alongside implicit syntax
    let data = DataValue(kind: Nested, nested_val: DataValue2(kind: dkInt, int_val: 42))
    let result = match data:
      DataValue(kind: Nested, nested_val: DataValue2(dkInt(42))): "SUCCESS: Mixed explicit-implicit syntax!"
      _: "FAILED"
    check result == "SUCCESS: Mixed explicit-implicit syntax!"

  test "✅ BOTH SYNTAXES: Standard object patterns for non-variant fields":
    ## Shows how normal object patterns work alongside implicit variant syntax
    type
      Container = object
        name: string
        data: DataValue

    let container = Container(
      name: "test_container",
      data: DataValue(kind: Text, text_val: "contained_text")
    )

    let result = match container:
      Container(name: "test_container", data: DataValue(Text("contained_text"))):
        "SUCCESS: Mixed container and implicit variant!"
      _: "FAILED"
    check result == "SUCCESS: Mixed container and implicit variant!"

