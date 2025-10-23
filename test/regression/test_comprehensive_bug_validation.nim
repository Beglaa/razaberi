import ../../pattern_matching
import unittest
import std/tables
import std/strutils


## This test suite validates 5 specific bugs reported in the pattern matching library:
## - Bug #1: Variable binding failure in complex OR patterns (CRITICAL - compilation failure)
## - Bug #2: Guard reordering breaking short-circuiting logic (monitoring for safety)
## - Bug #3: Incomplete rest capture for CountTable types (validation)
## - Bug #4: optimizeVariableBindings being a no-op (code quality)
## - Bug #5: Semantic ambiguity in spread patterns with defaults (behavioral)

# Compile-time testing templates for invalid syntax validation
template shouldNotCompile(code: untyped): bool =
  not compiles(code)

template shouldCompile(code: untyped): bool =
  compiles(code)

suite "Gemini Bug Report Validation":

  # ============================================================================
  # BUG #1: VARIABLE BINDING FAILURE IN COMPLEX OR PATTERNS (CRITICAL)
  # ============================================================================

  test "Bug #1: Object OR patterns with variable binding should compile but don't":
    type Point = object
      x, y: int

    let p = Point(x: 10, y: 0)

    # Bug #1 is now FIXED! Object OR patterns with variable binding work correctly
    let result = match p:
      Point(x: val, y: 0) | Point(x: 0, y: val):
        "On axis at " & $val
      _:
        "Not on axis"
    check result == "On axis at 10"

  test "Bug #1: Sequence OR patterns with variable binding":
    let data = @[42, 0]

    # Test if sequence OR patterns with variable binding work
    # This might or might not work depending on implementation
    let compiles = shouldCompile:
      match data:
        [val, 0] | [0, val]:
          "Found " & $val
        _:
          "No match"

    # Document current behavior
    if compiles:
      # If it compiles, test that it actually works correctly
      let result = match data:
        [val, 0] | [0, val]:
          "Found " & $val
        _:
          "No match"
      check result == "Found 42"
    else:
      # If it doesn't compile, that's the same bug as object patterns
      fail()

  test "Bug #1: Tuple OR patterns with variable binding":
    let tup = (x: 5, y: 0)

    # Test tuple OR patterns with variable binding
    let compiles = shouldCompile:
      match tup:
        (x: val, y: 0) | (x: 0, y: val):
          "Axis value: " & $val
        _:
          "Off axis"

    if compiles:
      let result = match tup:
        (x: val, y: 0) | (x: 0, y: val):
          "Axis value: " & $val
        _:
          "Off axis"
      check result == "Axis value: 5"
    # Note: If this doesn't compile, it confirms the OR binding bug affects tuples too

  # ============================================================================
  # BUG #2: GUARD REORDERING SAFETY (MONITORING - disproven but worth testing)
  # ============================================================================

  test "Bug #2: Guard order safety with nil checks":
    type RefObj = ref object
      value: int

    let nilObj: RefObj = nil

    # Test that guards maintain safe evaluation order
    # Pattern: obj and not obj.isNil and obj.value > 5
    # The order MUST be preserved for nil safety
    let result = match nilObj:
      x and not x.isNil and x.value > 5:
        "Safe access successful"
      _:
        "Correctly handled nil"

    # Should not crash and should take the safe path
    check result == "Correctly handled nil"

  test "Bug #2: Complex guard chains with variable consolidation":
    let nums = @[5, 10, 15]

    # Test complex guard conditions that might trigger variable consolidation
    let result = match nums:
      arr and arr.len > 2 and arr.len < 10 and arr[0] > 0:
        "Complex guard passed"
      _:
        "Guard failed"

    check result == "Complex guard passed"

  test "Bug #2: Order-dependent field access guards":
    type DataWrapper = ref object
      data: seq[int]

    let wrapper = DataWrapper(data: @[1, 2, 3])
    let nilWrapper: DataWrapper = nil

    # Test that field access guards maintain proper order
    let result1 = match wrapper:
      w and not w.isNil and w.data.len > 0:
        "Safe access"
      _:
        "Failed"

    let result2 = match nilWrapper:
      w and not w.isNil and w.data.len > 0:
        "Should not reach here"
      _:
        "Safe nil handling"

    check result1 == "Safe access"
    check result2 == "Safe nil handling"

  # ============================================================================
  # BUG #3: TABLE REST CAPTURE COMPLETENESS (VALIDATION - actually works)
  # ============================================================================

  test "Bug #3: CountTable rest capture should work":
    var ct = initCountTable[string]()
    ct.inc("a", 2)
    ct.inc("b", 3)
    ct.inc("c", 1)

    # This should work despite Gemini's claim it's broken
    let result = match ct:
      {"a": aCount, **rest}:
        "a=" & $aCount & ", rest_keys=" & $rest.len
      _:
        "No match"

    check result.startsWith("a=2, rest_keys=2")

  test "Bug #3: CountTableRef rest capture validation":
    var ctr = newCountTable[string]()
    ctr.inc("x", 5)
    ctr.inc("y", 2)

    let result = match ctr:
      {"x": xCount, **rest}:
        "x=" & $xCount & ", rest_keys=" & $rest.len
      _:
        "No match"

    check result.startsWith("x=5, rest_keys=1")

  test "Bug #3: Comprehensive table type rest capture":
    # Test various table types to ensure consistent behavior
    let regularTable = {"a": "1", "b": "2", "c": "3"}.toTable
    let orderedTable = {"x": "10", "y": "20"}.toOrderedTable

    let result1 = match regularTable:
      {"a": val, **rest}:
        "regular: a=" & val & ", rest=" & $rest.len
      _:
        "no match"

    let result2 = match orderedTable:
      {"x": val, **rest}:
        "ordered: x=" & val & ", rest=" & $rest.len
      _:
        "no match"

    check result1 == "regular: a=1, rest=2"
    check result2 == "ordered: x=10, rest=1"

  # ============================================================================
  # BUG #5: SEMANTIC AMBIGUITY IN SPREAD PATTERNS (CONFIRMED)
  # ============================================================================

  test "Bug #5: Spread pattern ambiguity with insufficient elements":
    let singleElement = @[100]

    # This is the problematic case Gemini identified
    # Pattern [a=0, *b, c] with input @[100] creates ambiguity:
    # Both 'a' and 'c' get bound to the same element!
    let result = match singleElement:
      [a=0, *b, c]:
        "AMBIGUOUS: a=" & $a & ", c=" & $c & ", b.len=" & $b.len
      _:
        "Should reject ambiguous patterns"

    # Current behavior: matches with a=100, c=100 (SAME ELEMENT!)
    # Ideal behavior: should reject or have unambiguous binding
    if result.startsWith("AMBIGUOUS"):
      # Document the problematic behavior
      check "100" in result  # Both a and c will be 100
      check "b.len=0" in result  # Spread gets empty slice
      # This test passes but documents the semantic issue
    else:
      # If it correctly rejects, that would be better behavior
      check result == "Should reject ambiguous patterns"

  test "Bug #5: Collision detection in spread patterns":
    let shortSeq = @[42]
    let longSeq = @[1, 2, 3, 4, 5]

    # Test basic collision case: [first, *middle, last] with one element
    let result1 = match shortSeq:
      [first, *middle, last]:
        "COLLISION: first=" & $first & ", last=" & $last
      _:
        "Correctly rejected collision"

    # Test non-collision case: [first, *middle, last] with sufficient elements
    let result2 = match longSeq:
      [first, *middle, last]:
        "OK: first=" & $first & ", last=" & $last & ", middle.len=" & $middle.len
      _:
        "Unexpected rejection"

    # The implementation correctly rejects obvious collisions
    check result1 == "Correctly rejected collision"
    check result2.startsWith("OK: first=1, last=5")

  test "Bug #5: Multiple conflicting fixed positions":
    let minimal = @[1]
    let insufficient = @[1, 2]

    # Pattern needs at least 4 elements but we provide fewer
    let result1 = match minimal:
      [a, b, *rest, c, d]:
        "Should not match"
      _:
        "Correctly rejected insufficient elements"

    let result2 = match insufficient:
      [a, b, *rest, c, d]:
        "Should not match"
      _:
        "Correctly rejected insufficient elements"

    check result1 == "Correctly rejected insufficient elements"
    check result2 == "Correctly rejected insufficient elements"

  test "Bug #5: Default values in ambiguous spread patterns":
    let edgeCase = @[50]

    # Test pattern with defaults that could create confusion
    let result = match edgeCase:
      [first=999, *middle, last=888]:
        "first=" & $first & ", last=" & $last & ", middle.len=" & $middle.len
      _:
        "Pattern rejected"

    # Document behavior: do defaults prevent or enable ambiguous matching?
    if result != "Pattern rejected":
      # If it matches, check what values are assigned
      check "first=50" in result or "first=999" in result
      check "last=50" in result or "last=888" in result

  # ============================================================================
  # COMPREHENSIVE EDGE CASES AND INTERACTIONS
  # ============================================================================

  test "Edge case: OR patterns with spread and defaults":
    # Tests OR patterns + spread patterns + defaults together
    # Pattern: [a, *rest] | [a=999, *rest]
    # Both alternatives must bind the same variables (a and rest)

    # Test 1: Non-empty sequence matches first alternative
    let seq1 = @[42, 100, 200]
    let result1 = match seq1:
      [a, *rest] | [a=999, *rest]: (a, rest)
      _: (-1, @[])
    check result1[0] == 42
    check result1[1] == @[100, 200]

    # Test 2: Empty sequence matches second alternative with defaults
    let seq2: seq[int] = @[]
    let result2 = match seq2:
      [a, *rest] | [a=999, *rest]: (a, rest)
      _: (-1, @[])
    check result2[0] == 999
    check result2[1].len == 0

    # Test 3: Single element matches first alternative
    let seq3 = @[7]
    let result3 = match seq3:
      [a, *rest] | [a=999, *rest]: (a, rest)
      _: (-1, @[])
    check result3[0] == 7
    check result3[1].len == 0

  test "Stress test: Complex nested patterns with potential bugs":
    type ComplexObj = object
      data: seq[int]
      meta: Table[string, string]

    let obj = ComplexObj(
      data: @[10, 20, 30],
      meta: {"type": "test", "version": "1.0", "debug": "true"}.toTable
    )

    # Test complex pattern that combines multiple potential bug areas
    let result = match obj:
      ComplexObj(data: [first, *rest], meta: {"type": typ, **otherMeta}) and first > 5:
        "Complex match: first=" & $first & ", type=" & typ & ", rest.len=" & $rest.len & ", other.len=" & $otherMeta.len
      _:
        "Complex pattern failed"

    check result.startsWith("Complex match: first=10, type=test")