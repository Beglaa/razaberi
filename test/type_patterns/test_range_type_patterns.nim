## Comprehensive Tests for Range Type Pattern Matching
##
## This test suite validates that range type detection uses proper structural
## metadata analysis instead of string-based heuristics.
##
## Test Coverage:
## 1. Range types in set patterns
## 2. Range types in sequence patterns
## 3. Range types in tuple patterns
## 4. Range types in table patterns
## 5. Integer literals matching range types
## 6. Type compatibility validation

import unittest
import std/tables
import ../../pattern_matching

suite "Range Type Pattern Matching":

  # ============================================================================
  # Test 1: Range Types in Set Patterns
  # ============================================================================

  test "integer literals match range type in set patterns":
    type SmallInt = range[0..10]
    let smallSet: set[SmallInt] = {1.SmallInt, 2, 3}

    let result = match smallSet:
      {1.SmallInt, 2, 3}: "matched range set"
      _: "no match"

    check result == "matched range set"

  test "empty set with range type":
    type SmallInt = range[0..10]
    let emptySet: set[SmallInt] = {}

    let result = match emptySet:
      {}: "empty range set"
      _: "no match"

    check result == "empty range set"

  test "subset operations with range type sets":
    type SmallInt = range[0..10]
    let smallSet: set[SmallInt] = {1.SmallInt, 2}

    let result = match smallSet:
      x <= {1.SmallInt, 2, 3}: "subset of range set"
      _: "no match"

    check result == "subset of range set"

  # ============================================================================
  # Test 2: Range Types in Sequence Patterns
  # ============================================================================

  test "sequence of range type with integer literals":
    type ByteRange = range[0..255]
    let bytes: seq[ByteRange] = @[10.ByteRange, 20, 30]

    let result = match bytes:
      [a, b, c]: $a & "-" & $b & "-" & $c
      _: "no match"

    check result == "10-20-30"

  test "sequence of range type with literal matching":
    type SmallInt = range[0..10]
    let nums: seq[SmallInt] = @[1.SmallInt, 2, 3]

    let result = match nums:
      [1.SmallInt, 2, 3]: "exact match"
      _: "no match"

    check result == "exact match"

  test "empty sequence with range type":
    type SmallInt = range[0..10]
    let emptySeq: seq[SmallInt] = @[]

    let result = match emptySeq:
      []: "empty sequence"
      _: "no match"

    check result == "empty sequence"

  # ============================================================================
  # Test 3: Range Types in Tuple Patterns
  # ============================================================================

  test "tuple with range type elements":
    type SmallInt = range[0..10]
    let tuple1: (SmallInt, SmallInt) = (5.SmallInt, 7)

    let result = match tuple1:
      (a, b): $a & "," & $b
      _: "no match"

    check result == "5,7"

  test "tuple with mixed range and regular types":
    type SmallInt = range[0..10]
    let tuple2: (SmallInt, string) = (5.SmallInt, "hello")

    let result = match tuple2:
      (n, s): $n & ":" & s
      _: "no match"

    check result == "5:hello"

  # ============================================================================
  # Test 4: Range Types in Table Patterns
  # ============================================================================

  test "table with range type values":
    type SmallInt = range[0..10]
    let table2: Table[string, SmallInt] = {"a": 1.SmallInt, "b": 2.SmallInt}.toTable

    let result = match table2:
      {"a": n}: $n
      _: "no match"

    check result == "1"

  # ============================================================================
  # Test 5: Integer Literals Matching Range Types
  # ============================================================================

  test "integer literal compatibility with range type":
    type ByteValue = range[0..255]
    let value: ByteValue = 42.ByteValue

    # This tests that integer literals can match range types
    let bytes: seq[ByteValue] = @[10.ByteValue, 20, 30]
    let result = match bytes:
      [10.ByteValue, 20, 30]: "literals match range"
      _: "no match"

    check result == "literals match range"

  test "range type with guards":
    type SmallInt = range[0..10]
    let num: SmallInt = 7.SmallInt

    let result = match num:
      n and n > 5: "greater than 5"
      n and n <= 5: "less or equal to 5"
      _: "no match"

    check result == "greater than 5"

  # ============================================================================
  # Test 6: Metadata-Based Type Detection
  # ============================================================================

  test "verify metadata detects range type correctly":
    # This test verifies that analyzeConstructMetadata properly detects range types
    # by using them in patterns - if metadata is wrong, validation would fail
    type
      TinyInt = range[0..5]
      SmallInt = range[0..10]

    let set1: set[TinyInt] = {1.TinyInt, 2}
    let set2: set[SmallInt] = {1.SmallInt, 2}

    # Both should match successfully
    let result1 = match set1:
      {1.TinyInt, 2}: "tiny int set"
      _: "no match"

    let result2 = match set2:
      {1.SmallInt, 2}: "small int set"
      _: "no match"

    check result1 == "tiny int set"
    check result2 == "small int set"

  test "multiple range types in same pattern":
    type
      Range1 = range[0..10]
      Range2 = range[0..100]

    let tuple1: (Range1, Range2) = (5.Range1, 50.Range2)

    let result = match tuple1:
      (a, b): $a & "," & $b
      _: "no match"

    check result == "5,50"

  # ============================================================================
  # Test 7: Complex Nested Patterns with Range Types
  # ============================================================================

  test "nested sequences with range types":
    type SmallInt = range[0..10]
    let nested: seq[seq[SmallInt]] = @[@[1.SmallInt, 2], @[3.SmallInt, 4]]

    let result = match nested:
      [[a, b], [c, d]]: $a & $b & $c & $d
      _: "no match"

    check result == "1234"

  test "object with range type fields":
    type
      SmallInt = range[0..10]
      Point = object
        x: SmallInt
        y: SmallInt

    let p = Point(x: 3.SmallInt, y: 7.SmallInt)

    let result = match p:
      Point(x: a, y: b): $a & "," & $b
      _: "no match"

    check result == "3,7"

  # ============================================================================
  # Test 8: Range Type Validation Edge Cases
  # ============================================================================

  test "range type preserves bounds semantically":
    # While we don't validate bounds at compile time (that's Nim's job),
    # we ensure pattern matching works correctly with range types
    type SmallInt = range[0..10]
    let nums: seq[SmallInt] = @[0.SmallInt, 5, 10]

    let result = match nums:
      [first, middle, last]: $first & "-" & $middle & "-" & $last
      _: "no match"

    check result == "0-5-10"

  test "character range types":
    type LowerCaseLetter = range['a'..'z']
    let chars: set[LowerCaseLetter] = {'a', 'b', 'c'}

    let result = match chars:
      x and x.card == 3: "three letters"
      _: "no match"

    check result == "three letters"
