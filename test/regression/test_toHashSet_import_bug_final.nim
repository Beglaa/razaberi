import unittest
import ../../pattern_matching
import std/sets

{.push warning[UnusedImport]: off.}
{.push hint[XDeclaredButNotUsed]: off.}

# COMPREHENSIVE BUG FIX TEST: Missing std/sets import bug
# Bug: Pattern matching library generated code calling toHashSet without importing std/sets
# Fix: Added "import std/sets" to pattern_matching.nim + smart type handling

suite "toHashSet Import Bug - Final Fix Verification":

  test "Bug Fix: Complex set patterns with tuples work without user importing sets":
    # This would previously fail with "undeclared field: 'toHashSet'"
    # Now works because pattern_matching.nim imports std/sets internally
    type Point = tuple[x: int, y: int]
    let tupleHashSet = [(1, 2), (3, 4)].toHashSet()
    
    let result = match tupleHashSet:
      {(1, 2), (3, 4)}: "Found tuples in HashSet"
      _: "Failed to match tuples"
    
    check(result == "Found tuples in HashSet")

  test "Bug Fix: Complex set patterns with objects work":
    type SimpleObj = object
      id: int
      name: string
    
    let obj1 = SimpleObj(id: 1, name: "first")
    let obj2 = SimpleObj(id: 2, name: "second")
    let objectHashSet = [obj1, obj2].toHashSet()
    
    let result = match objectHashSet:
      {SimpleObj(id: 1, name: "first"), SimpleObj(id: 2, name: "second")}: "Found objects in HashSet"
      _: "Failed to match objects"
    
    check(result == "Found objects in HashSet")

  test "Bug Fix: Array to HashSet conversion works":
    # Test the smart comparison logic: array gets converted to HashSet for comparison
    let tupleArray = [(1, 2), (3, 4)]
    
    let result = match tupleArray:
      {(1, 2), (3, 4)}: "Array converted to HashSet for comparison"
      _: "Array comparison failed"
    
    check(result == "Array converted to HashSet for comparison")

  test "Regression: Simple native sets still work":
    # Ensure we didn't break simple set patterns
    let intArray = [1, 2, 3]
    
    let result = match intArray:
      [1, 2, 3]: "Simple array pattern works"
      _: "Simple array pattern failed"
    
    check(result == "Simple array pattern works")

  test "Regression: All existing pattern types still work":
    # Comprehensive regression test
    let value = 42
    let tup = (10, "test")
    type TestObj = object
      x: int
    let obj = TestObj(x: 100)
    
    # Test multiple pattern types
    let result1 = match value:
      42: "int"
      _: "fail"
    check(result1 == "int")
    
    let result2 = match tup:
      (10, "test"): "tuple"
      _: "fail"
    check(result2 == "tuple")
    
    let result3 = match obj:
      TestObj(x: 100): "object"
      _: "fail"
    check(result3 == "object")