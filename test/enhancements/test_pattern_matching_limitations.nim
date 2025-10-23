import unittest
import std/sets
import std/tables
import ../../pattern_matching

{.push warning[UnusedImport]: off.}
{.push hint[XDeclaredButNotUsed]: off.}

# Test suite documenting current pattern matching limitations/bugs
# These tests demonstrate what should work but currently doesn't
suite "Pattern Matching Limitations":

  test "Limitation: Set patterns with simple elements work":
    # BASELINE: Simple set patterns should work
    let simpleSet = {1, 2, 3}
    
    let result = match simpleSet:
      {1, 2, 3}: "Simple set matched"
      _: "Simple set failed"
    
    check(result == "Simple set matched")

  test "Limitation: OR patterns with simple values work":
    # BASELINE: Simple OR patterns should work  
    let value = 42
    
    let result = match value:
      10 | 20 | 42: "Simple OR matched"
      _: "Simple OR failed"
    
    check(result == "Simple OR matched")

  test "Limitation: Nested patterns with non-nil values work":
    # BASELINE: Simple nested patterns should work
    type Container = object
      value: int
    
    let container = Container(value: 42)
    
    let result = match container:
      Container(value: 42): "Simple nested matched"
      _: "Simple nested failed"
    
    check(result == "Simple nested matched")

  test "Working example: Basic table patterns":
    # BASELINE: Basic table patterns should work
    var table = initTable[string, int]()
    table["key"] = 42
    
    let result = match table:
      {"key": value}: "Table matched: " & $value
      _: "Table failed"
    
    check(result == "Table matched: 42")

  test "Working example: Basic sequence patterns": 
    # BASELINE: Basic sequence patterns should work
    let seq1 = @[1, 2, 3]
    
    let result = match seq1:
      [1, 2, 3]: "Sequence matched"
      _: "Sequence failed"
    
    check(result == "Sequence matched")

  test "FIXED: Bug #2 - OR patterns with object constructors work":
    # This was previously failing but is now FIXED
    type
      Person = object
        name: string
        age: int
      Company = object
        name: string
        employees: int
    
    let person = Person(name: "John", age: 30)
    let company = Company(name: "John", employees: 50)
    
    # Test person matches
    let result1 = match person:
      Person(name: "John") | Company(name: "John"): "John entity matched"
      _: "No John entity found"
    
    check(result1 == "John entity matched")
    
    # Test company matches  
    let result2 = match company:
      Person(name: "John") | Company(name: "John"): "John entity matched"  
      _: "No John entity found"
    
    check(result2 == "John entity matched")

  test "CONFIRMED WORKING: Bug #3 - Nested patterns with nil literals work":
    # This was never actually broken - nil literal patterns work fine
    type
      ListNode = ref object
        value: int
        next: ListNode
    
    let leafNode = ListNode(value: 42, next: nil)
    let chainNode = ListNode(value: 10, next: leafNode)
    
    # Test leaf node (next: nil)
    let result1 = match leafNode:
      ListNode(value: val, next: nil): "Leaf node with value: " & $val
      _: "Not a leaf node"
    
    check(result1 == "Leaf node with value: 42")
    
    # Test non-leaf node  
    let result2 = match chainNode:
      ListNode(value: val, next: nil): "Leaf node with value: " & $val
      _: "Not a leaf node"
    
    check(result2 == "Not a leaf node")
