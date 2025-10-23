import unittest
import std/sets
import std/tables
import ../../pattern_matching

{.push warning[UnusedImport]: off.}
{.push hint[XDeclaredButNotUsed]: off.}

# FAILING TESTS: These demonstrate real bugs that need to be fixed
# DO NOT comment out or disable these tests - they must remain as failing tests
# until the underlying bugs are fixed in the pattern matching implementation
suite "Discovered Pattern Matching Bugs":

  test "Bug #1: Set patterns should support tuple elements":
    # BUG: Fails with "Unsupported element in set pattern: nnkTupleConstr"
    type Point = tuple[x: int, y: int]
    let tupleSet = [(1, 2), (3, 4)].toHashSet
    
    let result = match tupleSet:
      {(1, 2), (3, 4)}: "Found expected tuples"
      _: "Tuple set match failed"
    
    check(result == "Found expected tuples")

  test "Bug #1b: Set patterns should support object elements":
    # BUG: Likely fails with similar error for objects in sets
    type SimpleObj = object
      id: int
      name: string
    
    let obj1 = SimpleObj(id: 1, name: "first")
    let obj2 = SimpleObj(id: 2, name: "second")
    let objectSet = [obj1, obj2].toHashSet
    
    let result = match objectSet:
      {SimpleObj(id: 1, name: "first"), SimpleObj(id: 2, name: "second")}: "Found expected objects"
      _: "Object set match failed"
    
    check(result == "Found expected objects")


  test "Bug #3: Nested patterns should support nil literal patterns":
    # BUG: Fails with "Unsupported nested pattern type: nnkNilLit"
    type ListNode = ref object
      value: string
      next: ListNode
    
    let leaf = ListNode(value: "leaf", next: nil)
    
    let result = match leaf[]:
      ListNode(value: val, next: nil): "Leaf node: " & val
      _: "Nil pattern failed"
    
    check(result == "Leaf node: leaf")

  test "Bug #3b: Complex recursive patterns with nil":
    # BUG: Fails when nil appears in complex recursive patterns
    type TreeNode = ref object
      value: int
      left: TreeNode
      right: TreeNode
    
    let tree = TreeNode(
      value: 1,
      left: TreeNode(value: 2, left: nil, right: nil),
      right: nil
    )
    
    let result = match tree[]:
      TreeNode(value: rootVal, left: TreeNode(value: leftVal, left: nil, right: nil), right: nil):
        "Tree: root=" & $rootVal & " left=" & $leftVal
      _: "Complex nil pattern failed"
    
    check(result == "Tree: root=1 left=2")

  # BASELINE TESTS: These should work to ensure the test framework is valid
  test "Baseline: Empty sets work":
    let emptySet = initHashSet[int]()
    
    let result = match emptySet:
      {}: "Empty set matched"
      _: "Empty set failed"
    
    check(result == "Empty set matched")

  test "Baseline: Simple OR patterns work":
    let value = 42
    
    let result = match value:
      10 | 20 | 42: "Found expected value"
      _: "Simple OR failed"
    
    check(result == "Found expected value")

  test "Baseline: Simple nested patterns work":
    type SimpleContainer = object
      value: int
    
    let container = SimpleContainer(value: 42)
    
    let result = match container:
      SimpleContainer(value: 42): "Simple nested worked"
      _: "Simple nested failed"
    
    check(result == "Simple nested worked")