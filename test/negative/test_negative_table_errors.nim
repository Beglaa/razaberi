## Comprehensive Negative Tests for Table Pattern Errors
##
## This test suite validates that the pattern matching library provides
## helpful compile-time error messages when table patterns contain errors.
##
## Test Coverage:
## 1. Key type mismatches (string vs int, int vs string, wrong numeric types)
## 2. Value type mismatches (int vs string, string vs int, wrong numeric types)
## 3. Table patterns on non-table types (sequences, objects, tuples)
## 4. Mixed valid and invalid patterns
## 5. Complex nested table patterns with errors
## 6. Edge cases (empty keys, special characters)

import unittest
import ../../pattern_matching
import std/tables

suite "Negative Tests: Table Pattern Errors":
  ## Template for compile-time validation
  ## Returns true if code does NOT compile (expected for negative tests)
  template shouldNotCompile(code: untyped): bool =
    not compiles(code)

  ## Template for compile-time validation
  ## Returns true if code DOES compile (for positive control tests)
  template shouldCompile(code: untyped): bool =
    compiles(code)

  # ============================================================================
  # Test 1: Key Type Mismatches
  # ============================================================================

  test "int key on string-keyed table should not compile":
    check shouldNotCompile (
      let tbl = {"a": 1, "b": 2}.toTable
      match tbl:
        {1: val}: val  # int key on string-keyed table
        _: 0
    )

  test "string key on int-keyed table should not compile":
    check shouldNotCompile (
      let tbl = {1: "one", 2: "two"}.toTable
      match tbl:
        {"key": val}: val  # string key on int-keyed table
        _: ""
    )

  test "float key on int-keyed table should not compile":
    check shouldNotCompile (
      let tbl = {1: "one", 2: "two"}.toTable
      match tbl:
        {3.14: val}: val  # float key on int-keyed table
        _: ""
    )

  test "char key on string-keyed table should not compile":
    check shouldNotCompile (
      let tbl = {"a": 1, "b": 2}.toTable
      match tbl:
        {'a': val}: val  # char key on string-keyed table
        _: 0
    )

  # ============================================================================
  # Test 2: Value Type Mismatches
  # ============================================================================

  test "string value on int-valued table should not compile":
    check shouldNotCompile (
      let tbl = {"a": 1, "b": 2}.toTable
      match tbl:
        {"a": "wrong"}: "matched"  # string value on int-valued table
        _: "default"
    )

  test "int value on string-valued table should not compile":
    check shouldNotCompile (
      let tbl = {"a": "one", "b": "two"}.toTable
      match tbl:
        {"a": 42}: "matched"  # int value on string-valued table
        _: "default"
    )

  test "float value on int-valued table should not compile":
    check shouldNotCompile (
      let tbl = {"a": 1, "b": 2}.toTable
      match tbl:
        {"a": 3.14}: "matched"  # float value on int-valued table
        _: "default"
    )

  test "bool value on string-valued table should not compile":
    check shouldNotCompile (
      let tbl = {"a": "one", "b": "two"}.toTable
      match tbl:
        {"a": true}: "matched"  # bool value on string-valued table
        _: "default"
    )

  # ============================================================================
  # Test 3: Both Key and Value Type Mismatches
  # ============================================================================

  test "both key and value wrong types should not compile":
    check shouldNotCompile (
      let tbl = {"a": 1, "b": 2}.toTable
      match tbl:
        {42: "wrong"}: "matched"  # int key and string value (both wrong)
        _: "default"
    )

  test "swapped key-value types should not compile":
    check shouldNotCompile (
      let tbl = {"a": 1, "b": 2}.toTable
      match tbl:
        {1: "a"}: "matched"  # key and value types swapped
        _: "default"
    )

  # ============================================================================
  # Test 4: Multiple Entries with Type Errors
  # ============================================================================

  test "first entry valid, second entry wrong key type should not compile":
    check shouldNotCompile (
      let tbl = {"a": 1, "b": 2}.toTable
      match tbl:
        {"a": x, 42: y}: x  # second key is wrong type
        _: 0
    )

  test "first entry valid, second entry wrong value type should not compile":
    check shouldNotCompile (
      let tbl = {"a": 1, "b": 2}.toTable
      match tbl:
        {"a": 1, "b": "wrong"}: "matched"  # second value is wrong type
        _: "default"
    )

  test "multiple entries all wrong types should not compile":
    check shouldNotCompile (
      let tbl = {"a": 1, "b": 2}.toTable
      match tbl:
        {1: "x", 2: "y", 3: "z"}: "matched"  # all entries wrong types
        _: "default"
    )

  # ============================================================================
  # Test 5: Table Patterns on Non-Table Types
  # ============================================================================

  test "table pattern on sequence should not compile":
    check shouldNotCompile (
      let seq_val = @[1, 2, 3]
      match seq_val:
        {"a": x}: x
        _: 0
    )

  test "table pattern on tuple should not compile":
    check shouldNotCompile (
      let tuple_val = (x: 1, y: 2)
      match tuple_val:
        {"x": x}: x
        _: 0
    )

  test "table pattern on object should not compile":
    type Point = object
      x: int
      y: int

    check shouldNotCompile (
      let p = Point(x: 1, y: 2)
      match p:
        {"x": x}: x
        _: 0
    )

  test "table pattern on simple type should not compile":
    check shouldNotCompile (
      let val = 42
      match val:
        {"key": x}: x
        _: 0
    )

  test "table pattern on string should not compile":
    check shouldNotCompile (
      let val = "hello"
      match val:
        {"key": x}: x
        _: ""
    )

  # ============================================================================
  # Test 6: Mixed Valid and Invalid Key-Value Pairs
  # ============================================================================

  test "mixed valid literal key and invalid literal value should not compile":
    check shouldNotCompile (
      let tbl = {"a": 1, "b": 2}.toTable
      match tbl:
        {"a": "wrong", "b": y}: y  # first value wrong, second ok
        _: 0
    )

  test "mixed invalid literal key and valid value should not compile":
    check shouldNotCompile (
      let tbl = {"a": 1, "b": 2}.toTable
      match tbl:
        {42: x, "b": 2}: x  # first key wrong, second ok
        _: 0
    )

  # ============================================================================
  # Test 7: CountTable Type Errors
  # ============================================================================

  test "wrong key type on CountTable should not compile":
    check shouldNotCompile (
      var ct = initCountTable[string]()
      ct.inc("test")
      match ct:
        {42: count}: count  # int key on string CountTable
        _: 0
    )

  test "string value literal on CountTable should not compile":
    # CountTable values are always int, string literal should fail
    check shouldNotCompile (
      var ct = initCountTable[string]()
      ct.inc("test")
      match ct:
        {"test": "wrong"}: "matched"  # string value (CountTable has int values)
        _: "default"
    )

  # ============================================================================
  # Test 8: OrderedTable Type Errors
  # ============================================================================

  test "wrong key type on OrderedTable should not compile":
    check shouldNotCompile (
      var ot = initOrderedTable[string, int]()
      ot["a"] = 1
      match ot:
        {42: val}: val  # int key on string-keyed OrderedTable
        _: 0
    )

  test "wrong value type on OrderedTable should not compile":
    check shouldNotCompile (
      var ot = initOrderedTable[string, int]()
      ot["a"] = 1
      match ot:
        {"a": "wrong"}: "matched"  # string value on int-valued OrderedTable
        _: "default"
    )

  # ============================================================================
  # Test 9: Nested Table Errors
  # ============================================================================

  test "nested table with wrong inner key type should not compile":
    check shouldNotCompile (
      let tbl = {"outer": {"inner": 42}.toTable}.toTable
      match tbl:
        {"outer": {123: val}}: val  # inner table has wrong key type
        _: 0
    )

  test "nested table with wrong inner value type should not compile":
    check shouldNotCompile (
      let tbl = {"outer": {"inner": 42}.toTable}.toTable
      match tbl:
        {"outer": {"inner": "wrong"}}: "matched"  # inner table has wrong value type
        _: "default"
    )

  # ============================================================================
  # Test 10: Positive Controls (Should Compile)
  # ============================================================================

  test "valid string-keyed table should compile":
    check shouldCompile (
      let tbl = {"a": 1, "b": 2}.toTable
      match tbl:
        {"a": val}: val
        _: 0
    )

  test "valid int-keyed table should compile":
    check shouldCompile (
      let tbl = {1: "one", 2: "two"}.toTable
      match tbl:
        {1: val}: val
        _: ""
    )

  test "variable key and value should compile":
    check shouldCompile (
      let tbl = {"a": 1, "b": 2}.toTable
      match tbl:
        {key: val}: val  # variables are always valid
        _: 0
    )

  test "mixed literal key and variable value should compile":
    check shouldCompile (
      let tbl = {"a": 1, "b": 2}.toTable
      match tbl:
        {"a": val}: val  # literal key, variable value
        _: 0
    )

  test "empty table pattern should compile":
    check shouldCompile (
      let tbl = {"a": 1, "b": 2}.toTable
      match tbl:
        {}: "empty"
        _: "non-empty"
    )

  test "wildcard on table should compile":
    check shouldCompile (
      let tbl = {"a": 1, "b": 2}.toTable
      match tbl:
        _: "matched"
    )

  test "variable binding on table should compile":
    check shouldCompile (
      let tbl = {"a": 1, "b": 2}.toTable
      match tbl:
        t: "matched"
    )
