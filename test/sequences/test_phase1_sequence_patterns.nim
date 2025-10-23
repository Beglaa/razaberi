## Phase 1: Subtask 6 - Sequence/Array Pattern Validation Tests
##
## Tests for structural validation of sequence and array patterns using metadata.
## Tests both compile-time validation (array size) and runtime behavior.

import unittest
import ../../pattern_matching
import ../helper/ccheck

suite "Phase 1: Sequence/Array Pattern Validation":

  # ========================================================================
  # Array Pattern Tests - Size Validation
  # ========================================================================

  test "Valid array pattern - exact size match":
    let arr: array[3, int] = [1, 2, 3]
    let result = match arr:
      [a, b, c]: $a & "," & $b & "," & $c
      _: "no match"
    check result == "1,2,3"

  test "Valid array pattern - single element array":
    let arr: array[1, int] = [42]
    let result = match arr:
      [x]: $x
      _: "no match"
    check result == "42"

  test "Valid array pattern - with spread operator":
    let arr: array[5, int] = [1, 2, 3, 4, 5]
    let result = match arr:
      [first, *middle, last]: $first & "..." & $last
      _: "no match"
    check result == "1...5"

  test "Array pattern with size mismatch - does not compile":
    # Array has 3 elements, pattern expects only 2
    # Compile-time validation enforces exact size match for arrays
    # (This was changed from runtime to compile-time validation)
    check shouldNotCompile (
      let arr: array[3, int] = [1, 2, 3]
      match arr:
        [a, b]: $a & $b  # Compile error - size mismatch
        _: "no match"
    )

  test "Array pattern - exact match required (no defaults for arrays)":
    # Arrays are fixed-size, so patterns must match exactly
    # Defaults only make sense for variable-length collections like sequences
    let arr: array[3, int] = [1, 2, 3]
    let result = match arr:
      [a, b, c]: $a & "," & $b & "," & $c
      _: "no match"
    check result == "1,2,3"

  # ========================================================================
  # Sequence Pattern Tests - Variable Length Allowed
  # ========================================================================

  test "Valid sequence pattern - variable length":
    let seq = @[1, 2, 3, 4, 5]
    let result = match seq:
      [first, *rest]: $first
      _: "no match"
    check result == "1"

  test "Valid sequence pattern - exact match":
    let seq = @[10, 20, 30]
    let result = match seq:
      [a, b, c]: $a & "," & $b & "," & $c
      _: "no match"
    check result == "10,20,30"

  test "Valid sequence pattern - empty sequence":
    let seq: seq[int] = @[]
    let result = match seq:
      []: "empty"
      _: "not empty"
    check result == "empty"

  test "Sequence pattern - spread captures all":
    let seq = @[1, 2, 3, 4, 5, 6]
    let result = match seq:
      [*all]: $all.len
      _: "no match"
    check result == "6"

  test "Sequence pattern - middle spread":
    let seq = @[1, 2, 3, 4, 5]
    let result = match seq:
      [first, *middle, last]: $first & "..." & $last & " (middle: " & $middle.len & ")"
      _: "no match"
    check result == "1...5 (middle: 3)"

  # ========================================================================
  # Mixed Type Tests
  # ========================================================================

  test "Array of strings - exact match":
    let arr: array[2, string] = ["hello", "world"]
    let result = match arr:
      ["hello", "world"]: "exact match"
      [a, b]: a & " " & b
      _: "no match"
    check result == "exact match"

  test "Sequence of booleans":
    let seq = @[true, false, true]
    let result = match seq:
      [a, b, c]: $a & "," & $b & "," & $c
      _: "no match"
    check result == "true,false,true"

  # ========================================================================
  # Edge Cases
  # ========================================================================

  test "Large array - exact size validation":
    let arr: array[10, int] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    let result = match arr:
      [a, b, c, d, e, f, g, h, i, j]: $j
      _: "no match"
    check result == "10"

  test "Array pattern with wildcard":
    let arr: array[3, int] = [1, 2, 3]
    let result = match arr:
      [_, _, x]: $x
      _: "no match"
    check result == "3"

  test "Nested sequence pattern":
    let seq = @[@[1, 2], @[3, 4], @[5, 6]]
    let result = match seq:
      [[a, b], *rest]: $a & "," & $b
      _: "no match"
    check result == "1,2"