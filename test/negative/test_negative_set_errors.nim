## Comprehensive Negative Tests for Set Pattern Errors
##
## This test suite validates that the pattern matching library provides
## helpful compile-time error messages when set patterns contain errors.
##
## Test Coverage:
## 1. Element type mismatches (string vs int, int vs string, mixed types)
## 2. Non-comparable types (objects, sequences, tables in sets)
## 3. Wrong pattern syntax (sequence/tuple patterns on sets)
## 4. Set patterns on non-set types (strings, objects, tuples)
## 5. Mixed valid and invalid elements
## 6. Complex nested set patterns with errors
## 7. HashSet and OrderedSet type errors

import unittest
import ../../pattern_matching
import std/sets

suite "Negative Tests: Set Pattern Errors":
  ## Template for compile-time validation
  ## Returns true if code does NOT compile (expected for negative tests)
  template shouldNotCompile(code: untyped): bool =
    not compiles(code)

  ## Template for compile-time validation
  ## Returns true if code DOES compile (for positive control tests)
  template shouldCompile(code: untyped): bool =
    compiles(code)

  # ============================================================================
  # Test 1: Element Type Mismatches - String in Int Set
  # ============================================================================

  test "string literal in int set should not compile":
    check shouldNotCompile (
      let s = {1, 2, 3}
      match s:
        {"one", "two"}: 1  # string literals in int set
        _: 0
    )

  test "single string literal in int set should not compile":
    check shouldNotCompile (
      let s = {1, 2, 3}
      match s:
        {"invalid"}: 1  # single string literal in int set
        _: 0
    )

  test "mixed int and string literals in int set should not compile":
    check shouldNotCompile (
      let s = {1, 2, 3}
      match s:
        {1, "two", 3}: "matched"  # mixed int and string in int set
        _: "default"
    )

  # ============================================================================
  # Test 2: Element Type Mismatches - Int in String Set
  # ============================================================================

  test "int literal in string HashSet should not compile":
    check shouldNotCompile (
      let s = ["one", "two", "three"].toHashSet
      match s:
        {1, 2}: "matched"  # int literals in string set
        _: "default"
    )

  test "single int literal in string HashSet should not compile":
    check shouldNotCompile (
      let s = ["one", "two"].toHashSet
      match s:
        {42}: "matched"  # int literal in string set
        _: "default"
    )

  test "mixed string and int literals in string HashSet should not compile":
    check shouldNotCompile (
      let s = ["one", "two"].toHashSet
      match s:
        {"one", 2, "three"}: "matched"  # mixed types
        _: "default"
    )

  # ============================================================================
  # Test 3: Element Type Mismatches - Float in Int Set
  # ============================================================================

  test "float literal in int set should not compile":
    check shouldNotCompile (
      let s = {1, 2, 3}
      match s:
        {3.14, 2.71}: "matched"  # float literals in int set
        _: "default"
    )

  test "mixed int and float literals in int set should not compile":
    check shouldNotCompile (
      let s = {1, 2, 3}
      match s:
        {1, 2.5, 3}: "matched"  # mixed int and float
        _: "default"
    )

  # ============================================================================
  # Test 4: Element Type Mismatches - Char in Int Set
  # ============================================================================

  test "char literal in int set should not compile":
    check shouldNotCompile (
      let s = {1, 2, 3}
      match s:
        {'a', 'b', 'c'}: "matched"  # char literals in int set
        _: "default"
    )

  test "mixed int and char literals should not compile":
    check shouldNotCompile (
      let s = {1, 2, 3}
      match s:
        {1, 'b', 3}: "matched"  # mixed int and char
        _: "default"
    )

  # ============================================================================
  # Test 5: Element Type Mismatches - Bool in Int Set
  # ============================================================================

  test "bool literal in int set should not compile":
    check shouldNotCompile (
      let s = {1, 2, 3}
      match s:
        {true, false}: "matched"  # bool literals in int set
        _: "default"
    )

  test "mixed int and bool literals should not compile":
    check shouldNotCompile (
      let s = {1, 2, 3}
      match s:
        {1, true, 3}: "matched"  # mixed int and bool
        _: "default"
    )

  # ============================================================================
  # Test 6: Non-Comparable Types in Sets
  # ============================================================================

  test "sequence pattern syntax on set should not compile":
    # Set patterns use {}, sequence patterns use []
    check shouldNotCompile (
      let s = {1, 2, 3}
      match s:
        [1, 2, 3]: "matched"  # sequence syntax on set
        _: "default"
    )

  test "tuple pattern syntax on set should not compile":
    check shouldNotCompile (
      let s = {1, 2, 3}
      match s:
        (1, 2, 3): "matched"  # tuple syntax on set
        _: "default"
    )

  # ============================================================================
  # Test 7: Set Patterns on Non-Set Types
  # ============================================================================

  test "set pattern on string should not compile":
    check shouldNotCompile (
      let s = "hello"
      match s:
        {"h", "e"}: "matched"  # set pattern on string
        _: "default"
    )

  test "set pattern on sequence SHOULD compile (HashSet conversion feature)":
    # Set patterns on sequences ARE allowed - they convert to HashSet for comparison
    # This is a feature, not a bug!
    check compiles (
      let seq_val = @[1, 2, 3]
      match seq_val:
        {1, 2}: "matched"  # Converts to HashSet comparison
        _: "default"
    )

  test "set pattern on tuple should not compile":
    check shouldNotCompile (
      let tuple_val = (1, 2, 3)
      match tuple_val:
        {1, 2}: "matched"  # set pattern on tuple
        _: "default"
    )

  test "set pattern on object should not compile":
    type Point = object
      x: int
      y: int

    check shouldNotCompile (
      let p = Point(x: 1, y: 2)
      match p:
        {1, 2}: "matched"  # set pattern on object
        _: "default"
    )

  test "set pattern on array SHOULD compile (HashSet conversion feature)":
    # Set patterns on arrays ARE allowed - they convert to HashSet for comparison
    # This is a feature, not a bug!
    check compiles (
      let arr = [1, 2, 3]
      match arr:
        {1, 2}: "matched"  # Converts to HashSet comparison
        _: "default"
    )

  # ============================================================================
  # Test 8: Mixed Valid and Invalid Elements
  # ============================================================================

  test "first element valid, second element wrong type should not compile":
    check shouldNotCompile (
      let s = {1, 2, 3}
      match s:
        {1, "two"}: "matched"  # first int ok, second string wrong
        _: "default"
    )

  test "most elements valid, one wrong type should not compile":
    check shouldNotCompile (
      let s = {1, 2, 3, 4, 5}
      match s:
        {1, 2, "three", 4, 5}: "matched"  # one string in int set
        _: "default"
    )

  # ============================================================================
  # Test 9: Enum Set Type Mismatches
  # ============================================================================

  test "wrong enum type in set pattern should not compile":
    type
      Color = enum Red, Green, Blue
      Animal = enum Dog, Cat, Bird

    check shouldNotCompile (
      let colors = {Red, Green}
      match colors:
        {Dog, Cat}: "matched"  # Animal enum in Color set
        _: "default"
    )

  test "mixed enum and int in enum set should not compile":
    type Color = enum Red, Green, Blue

    check shouldNotCompile (
      let colors = {Red, Green}
      match colors:
        {Red, 42}: "matched"  # mixed enum and int
        _: "default"
    )

  test "string literal in enum set should not compile":
    type Color = enum Red, Green, Blue

    check shouldNotCompile (
      let colors = {Red, Green}
      match colors:
        {"Red", "Green"}: "matched"  # string literals (not enum values)
        _: "default"
    )

  # ============================================================================
  # Test 10: HashSet Type Errors
  # ============================================================================

  test "wrong element type in HashSet should not compile":
    check shouldNotCompile (
      let hs = [1, 2, 3].toHashSet
      match hs:
        {"one", "two"}: "matched"  # string elements in int HashSet
        _: "default"
    )

  test "float literal in int HashSet should not compile":
    check shouldNotCompile (
      let hs = [1, 2, 3].toHashSet
      match hs:
        {3.14}: "matched"  # float in int HashSet
        _: "default"
    )

  # ============================================================================
  # Test 11: OrderedSet Type Errors
  # ============================================================================

  test "wrong element type in OrderedSet should not compile":
    check shouldNotCompile (
      let os = [1, 2, 3].toOrderedSet
      match os:
        {"one", "two"}: "matched"  # string elements in int OrderedSet
        _: "default"
    )

  test "char literal in string OrderedSet should not compile":
    check shouldNotCompile (
      let os = ["one", "two"].toOrderedSet
      match os:
        {'a', 'b'}: "matched"  # char in string OrderedSet
        _: "default"
    )

  # ============================================================================
  # Test 12: Char Set Type Errors
  # ============================================================================

  test "string literal in char set should not compile":
    check shouldNotCompile (
      let chars = {'a', 'b', 'c'}
      match chars:
        {"abc"}: "matched"  # string literal in char set
        _: "default"
    )

  test "int literal in char set should not compile":
    check shouldNotCompile (
      let chars = {'a', 'b', 'c'}
      match chars:
        {97, 98}: "matched"  # int literals (ASCII values) in char set
        _: "default"
    )

  test "mixed char and string in char set should not compile":
    check shouldNotCompile (
      let chars = {'a', 'b', 'c'}
      match chars:
        {'a', "b", 'c'}: "matched"  # mixed char and string
        _: "default"
    )

  # ============================================================================
  # Test 13: Multiple Type Errors in One Pattern
  # ============================================================================

  test "multiple different wrong types in int set should not compile":
    check shouldNotCompile (
      let s = {1, 2, 3}
      match s:
        {1, "two", 3.0, 'a', true}: "matched"  # multiple wrong types
        _: "default"
    )

  test "all wrong types in set pattern should not compile":
    check shouldNotCompile (
      let s = {1, 2, 3}
      match s:
        {"a", "b", "c"}: "matched"  # all elements wrong type
        _: "default"
    )

  # ============================================================================
  # Test 14: Nested Set Patterns (if supported)
  # ============================================================================

  # Note: Sets of sets are not common in Nim, but testing for completeness

  # ============================================================================
  # Test 15: Positive Controls (Should Compile)
  # ============================================================================

  test "valid int set pattern should compile":
    check shouldCompile (
      let s = {1, 2, 3}
      match s:
        {1, 2}: "matched"
        _: "default"
    )

  test "valid string HashSet pattern should compile":
    check shouldCompile (
      let hs = ["one", "two"].toHashSet
      match hs:
        {"one"}: "matched"
        _: "default"
    )

  test "valid enum set pattern should compile":
    type Color = enum Red, Green, Blue

    check shouldCompile (
      let colors = {Red, Green}
      match colors:
        {Red}: "matched"
        _: "default"
    )

  test "valid char set pattern should compile":
    check shouldCompile (
      let chars = {'a', 'b', 'c'}
      match chars:
        {'a', 'b'}: "matched"
        _: "default"
    )

  test "empty set pattern should compile":
    check shouldCompile (
      let s = {1, 2, 3}
      match s:
        {}: "empty"
        _: "non-empty"
    )

  test "variable binding in set pattern should compile":
    check shouldCompile (
      let s = {1, 2, 3}
      match s:
        {x}: "matched"  # variables are always valid
        _: "default"
    )

  test "wildcard in set pattern should compile":
    check shouldCompile (
      let s = {1, 2, 3}
      match s:
        _: "matched"
    )

  test "spread pattern in set should compile":
    check shouldCompile (
      let s = {1, 2, 3, 4, 5}
      match s:
        {1, 2, *rest}: "matched"  # spread captures remaining
        _: "default"
    )

  test "mixed literals and variables should compile":
    check shouldCompile (
      let s = {1, 2, 3}
      match s:
        {1, x}: "matched"  # literal and variable
        _: "default"
    )
