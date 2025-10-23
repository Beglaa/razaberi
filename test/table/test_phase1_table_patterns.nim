## Phase 1: Subtask 7 - Table Pattern Validation Tests
##
## Tests for structural validation of table patterns using metadata.
## Tests compile-time validation and runtime behavior.

import unittest
import tables
import ../../pattern_matching

suite "Phase 1: Table Pattern Validation":

  # ========================================================================
  # Basic Table Pattern Tests
  # ========================================================================

  test "Valid table pattern - exact key match":
    let data = {"name": "Alice", "age": "30"}.toTable
    let result = match data:
      {"name": n, "age": a}: n & ":" & a
      _: "no match"
    check result == "Alice:30"

  test "Valid table pattern - single key":
    let data = {"status": "ok"}.toTable
    let result = match data:
      {"status": s}: s
      _: "no match"
    check result == "ok"

  test "Valid table pattern - with rest capture":
    let data = {"name": "Bob", "age": "25", "city": "NYC"}.toTable
    let result = match data:
      {"name": n, **rest}: n & " (+" & $rest.len & " more)"
      _: "no match"
    check result == "Bob (+2 more)"

  test "Table pattern - partial key match":
    let data = {"a": "1", "b": "2", "c": "3"}.toTable
    let result = match data:
      {"a": x, "b": y}: x & "," & y
      _: "no match"
    check result == "1,2"

  # ========================================================================
  # Table Pattern with Defaults
  # ========================================================================

  test "Table pattern with default value - key present":
    let data = {"debug": "true"}.toTable
    let result = match data:
      {"debug": (d = "false")}: d
      _: "no match"
    check result == "true"

  test "Table pattern with default value - key missing":
    let data = {"other": "value"}.toTable
    let result = match data:
      {"debug": (d = "false"), **rest}: d
      _: "no match"
    check result == "false"

  test "Table pattern with multiple defaults":
    let data = {"name": "Alice"}.toTable
    let result = match data:
      {"name": n, "debug": (d = "false"), "ssl": (s = "disabled")}: n & "," & d & "," & s
      _: "no match"
    check result == "Alice,false,disabled"

  # ========================================================================
  # Invalid Table Pattern Tests
  # ========================================================================

  test "Table pattern on non-table type should not compile":
    let x = 42

    # This should fail at compile time - using table pattern on int
    when not compiles (
      let result = match x:
        {"key": value}: value  # Table pattern on int!
        _: "no match"
    ):
      check true  # Expected to not compile
    else:
      check false  # Should not compile

  test "Table pattern on string should not compile":
    let s = "hello world"

    # This should fail at compile time
    when not compiles (
      let result = match s:
        {"key": value}: value  # Table pattern on string!
        _: "no match"
    ):
      check true  # Expected to not compile
    else:
      check false  # Should not compile

  test "Table pattern on array should not compile":
    let arr = [1, 2, 3]

    # This should fail at compile time
    when not compiles (
      let result = match arr:
        {"key": value}: value  # Table pattern on array!
        _: "no match"
    ):
      check true  # Expected to not compile
    else:
      check false  # Should not compile

  # ========================================================================
  # Different Table Types
  # ========================================================================

  test "OrderedTable pattern":
    var data = initOrderedTable[string, string]()
    data["first"] = "1"
    data["second"] = "2"

    let result = match data:
      {"first": f, "second": s}: f & "," & s
      _: "no match"
    check result == "1,2"

  test "CountTable pattern":
    var data = initCountTable[string]()
    data.inc("apple", 3)
    data.inc("banana", 2)

    let result = match data:
      {"apple": a}: $a
      _: "no match"
    check result == "3"

  # ========================================================================
  # Empty and Edge Cases
  # ========================================================================

  test "Empty table pattern":
    let data = initTable[string, string]()
    let result = match data:
      {}: "empty"
      _: "not empty"
    check result == "empty"

  test "Table with empty string keys":
    let data = {"": "empty_key", "normal": "value"}.toTable
    let result = match data:
      {"": e, "normal": n}: e & "|" & n
      _: "no match"
    check result == "empty_key|value"

  test "Table with numeric string keys":
    let data = {"1": "one", "2": "two"}.toTable
    let result = match data:
      {"1": a, "2": b}: a & "," & b
      _: "no match"
    check result == "one,two"

  # ========================================================================
  # Complex Table Patterns
  # ========================================================================

  test "Nested table access":
    # Note: This tests basic table pattern, not nested patterns yet
    let data = {"outer": "value1", "inner": "value2"}.toTable
    let result = match data:
      {"outer": o, "inner": i}: o & ":" & i
      _: "no match"
    check result == "value1:value2"

  test "Table pattern with guards":
    let data = {"age": "35", "name": "Charlie"}.toTable
    let result = match data:
      {"age": age, "name": n} and age == "35": n
      {"age": age, "name": n}: "not 35"
      _: "no match"
    check result == "Charlie"

  test "Multiple table patterns with fallback":
    let data = {"status": "active"}.toTable
    let result = match data:
      {"error": e}: "error: " & e
      {"status": s}: "status: " & s
      _: "unknown"
    check result == "status: active"