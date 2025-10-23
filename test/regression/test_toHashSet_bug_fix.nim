import unittest
import ../../pattern_matching
import std/sets

{.push warning[UnusedImport]: off.}
{.push hint[XDeclaredButNotUsed]: off.}

# Testing that pattern matching works even when complex set operations are needed

# BUG FIX: toHashSet import missing bug
# Previously failed with "undeclared field: 'toHashSet'" when user didn't import std/sets
# Fixed by adding "import std/sets" to pattern_matching.nim

suite "toHashSet Import Bug Fix":

  test "Bug Fix: Pattern matching works without explicit sets import":
    # This previously failed with "undeclared field: 'toHashSet'"
    # Now works because pattern_matching.nim imports std/sets
    
    let data = [1, 2, 3]
    
    let result = match data:
      [1, 2, 3]: "Array pattern works"
      _: "Array pattern failed"
    
    check(result == "Array pattern works")

  test "Bug Fix: Complex set patterns with tuples work":
    # This specifically tests the code path that calls toHashSet
    # with complex types (tuples)
    
    type Point = tuple[x: int, y: int]
    let tupleSet = [(1, 2), (3, 4)].toHashSet()
    
    let result = match tupleSet:
      {(1, 2), (3, 4)}: "Found expected tuples"
      _: "Tuple pattern failed"
    
    check(result == "Found expected tuples")

  test "Bug Fix: Complex set patterns with objects work":
    
    type SimpleObj = object
      id: int
      name: string
    
    let obj1 = SimpleObj(id: 1, name: "first")
    let obj2 = SimpleObj(id: 2, name: "second")
    let objectSet = [obj1, obj2].toHashSet()
    
    let result = match objectSet:
      {SimpleObj(id: 1, name: "first"), SimpleObj(id: 2, name: "second")}: "Found expected objects"
      _: "Object pattern failed"
    
    check(result == "Found expected objects")

  test "Baseline: Simple patterns still work":
    let value = 42
    
    let result = match value:
      42: "Simple pattern works"
      _: "Simple pattern failed"
    
    check(result == "Simple pattern works")