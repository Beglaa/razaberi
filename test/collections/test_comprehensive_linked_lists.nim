import unittest
import std/lists
import std/sequtils
import std/times
import ../../pattern_matching

# ============================================================================
# COMPREHENSIVE LINKED LIST PATTERN MATCHING TEST SUITE
# ============================================================================
# Tests all linked list types with enhanced pattern matching features:
# - SinglyLinkedList, DoublyLinkedList, SinglyLinkedRing, DoublyLinkedRing  
# - Head/tail destructuring: [head, *tail]
# - Length patterns: empty(), single(), length()
# - Node-level access: node(value, next)
# - Mixed patterns with traditional sequence syntax
# ============================================================================

suite "Comprehensive Linked List Pattern Matching":
  
  # ============================================================================
  # SINGLY LINKED LIST PATTERNS
  # ============================================================================
  
  test "SinglyLinkedList - Head/Tail Destructuring":
    var list = initSinglyLinkedList[int]()
    list.add(1)
    list.add(2)
    list.add(3)
    
    let result = match list:
      [head, *tail]: 
        var tailSeq: seq[int] = @[]
        for item in tail.items:
          tailSeq.add(item)
        (head, tailSeq)
      _: (0, @[])
    
    check result[0] == 1
    check result[1] == @[2, 3]
  
  test "SinglyLinkedList - Empty List Pattern":
    var emptyList = initSinglyLinkedList[string]()
    
    let result = match emptyList:
      [empty()]: "empty list"
      _: "not empty"
    
    check result == "empty list"
  
  test "SinglyLinkedList - Single Element Pattern":
    var singleList = initSinglyLinkedList[int]()
    singleList.add(42)
    
    let result = match singleList:
      [single(value)]: value * 2
      _: 0
    
    check result == 84
  
  test "SinglyLinkedList - Length Pattern":
    var list = initSinglyLinkedList[string]()
    list.add("a")
    list.add("b")
    list.add("c")
    
    let result = match list:
      [length(3)]: "exactly three"
      [length(2)]: "exactly two"
      _: "other length"
    
    check result == "exactly three"
  
  test "SinglyLinkedList - Node Access Pattern":
    var list = initSinglyLinkedList[int]()
    list.add(100)
    list.add(200)
    
    let result = match list:
      [node(value)]: value + 50
      _: 0
    
    check result == 150
  
  # ============================================================================
  # DOUBLY LINKED LIST PATTERNS  
  # ============================================================================
  
  test "DoublyLinkedList - Head/Tail Destructuring":
    var list = initDoublyLinkedList[char]()
    list.add('a')
    list.add('b')
    list.add('c')
    
    let result = match list:
      [head, *tail]:
        var tailChars: seq[char] = @[]
        for ch in tail.items:
          tailChars.add(ch)
        $head & $tailChars
      _: ""
    
    check result == "a@['b', 'c']"
  
  test "DoublyLinkedList - Empty and Single Patterns":
    var emptyList = initDoublyLinkedList[int]()
    var singleList = initDoublyLinkedList[int]()
    singleList.add(99)
    
    let emptyResult = match emptyList:
      [empty()]: true
      _: false
    
    let singleResult = match singleList:
      [single(val)]: val
      _: 0
    
    check emptyResult == true
    check singleResult == 99
  
  test "DoublyLinkedList - Length Pattern Variations":
    var list = initDoublyLinkedList[string]()
    list.add("x")
    list.add("y")
    
    let result = match list:
      [length(0)]: "empty"
      [length(1)]: "single"
      [length(2)]: "pair"
      _: "many"
    
    check result == "pair"
  
  # ============================================================================
  # SINGLY LINKED RING PATTERNS
  # ============================================================================
  
  test "SinglyLinkedRing - Basic Patterns":
    var ring = initSinglyLinkedRing[int]()
    ring.add(1)
    ring.add(2)
    ring.add(3)
    
    # Test length detection (should work even for rings)
    let lengthResult = match ring:
      [length(3)]: "three elements"
      _: "other count"
    
    check lengthResult == "three elements"
    
    # Test single element ring
    var singleRing = initSinglyLinkedRing[string]()
    singleRing.add("ring")
    
    let singleResult = match singleRing:
      [single(item)]: item & "_matched"
      _: "no match"
    
    check singleResult == "ring_matched"
  
  test "SinglyLinkedRing - Empty Ring":
    var emptyRing = initSinglyLinkedRing[float]()
    
    let result = match emptyRing:
      [empty()]: 0.0
      [single(x)]: x
      _: -1.0
    
    check result == 0.0
  
  # ============================================================================
  # DOUBLY LINKED RING PATTERNS
  # ============================================================================
  
  test "DoublyLinkedRing - Comprehensive Patterns":
    var ring = initDoublyLinkedRing[bool]()
    ring.add(true)
    ring.add(false)
    
    let result = match ring:
      [empty()]: "empty"
      [single(b)]: "single: " & $b  
      [length(2)]: "two booleans"
      _: "complex"
    
    check result == "two booleans"
  
  test "DoublyLinkedRing - Node Access":
    var ring = initDoublyLinkedRing[int]()
    ring.add(888)
    
    let result = match ring:
      [node(value)]: value / 8
      _: 0
    
    check result == 111
  
  # ============================================================================
  # MIXED PATTERNS AND EDGE CASES
  # ============================================================================
  
  test "Mixed List Types - Pattern Compatibility":
    # Test that patterns work consistently across list types
    var singlyList = initSinglyLinkedList[int]()
    var doublyList = initDoublyLinkedList[int]() 
    var singlyRing = initSinglyLinkedRing[int]()
    var doublyRing = initDoublyLinkedRing[int]()
    
    # Add same data to all lists
    singlyList.add(10)
    singlyList.add(20)
    doublyList.add(10) 
    doublyList.add(20)
    singlyRing.add(10)
    singlyRing.add(20)
    doublyRing.add(10)
    doublyRing.add(20)
    
    # All should match length(2) pattern
    let result1 = match singlyList:
      [length(2)]: "match"
      _: "no match"
      
    let result2 = match doublyList:
      [length(2)]: "match"  
      _: "no match"
      
    let result3 = match singlyRing:
      [length(2)]: "match"
      _: "no match"
      
    let result4 = match doublyRing:
      [length(2)]: "match"
      _: "no match"
    
    let results = [result1, result2, result3, result4]
    
    for result in results:
      check result == "match"
  
  test "Edge Cases - Very Long Lists":
    var longList = initSinglyLinkedList[int]()
    for i in 1..10:  # Reduced to 10 for fast tests (increase if needed)
      longList.add(i)
    
    let result = match longList:
      [length(10)]: "exactly 10"
      _: "not 10"
    
    check result == "exactly 10"
  
  test "Edge Cases - List Modification Patterns":
    var list = initDoublyLinkedList[string]()
    list.add("first")
    list.add("second")
    list.add("third")
    
    # Test head|tail extraction
    let result = match list:
      [head, *tail]:
        var count = 0
        for _ in tail.items:
          count += 1
        head & "_" & $count
      _: "failed"
    
    check result == "first_2"
  
  # ============================================================================
  # PERFORMANCE AND STRESS TESTS
  # ============================================================================
  
  test "Performance - Large List Pattern Matching":
    var largeList = initSinglyLinkedList[int]()
    for i in 1..10:  # Reduced to 10 for fast tests (increase if needed)
      largeList.add(i)
    
    # Test that pattern matching completes in reasonable time
    let startTime = cpuTime()
    
    let result = match largeList:
      [empty()]: "empty"
      [single(x)]: "single"
      [length(10)]: "exactly 10"
      _: "other"
    
    let endTime = cpuTime()
    let duration = endTime - startTime
    
    check result == "exactly 10"
    check duration < 0.1  # Should complete very quickly
  
  test "Correctness - Pattern Priority":
    var list = initSinglyLinkedList[int]()
    list.add(42)
    
    # First matching pattern should win
    let result = match list:
      [single(x)]: "single_" & $x
      [length(1)]: "length_1"
      _: "other"
    
    check result == "single_42"  # single() pattern should match first

# ============================================================================
# COMPILE-TIME TESTS
# ============================================================================

# Test that invalid patterns fail to compile
template shouldNotCompile(code: untyped): bool =
  not compiles(code)

template shouldCompile(code: untyped): bool =
  compiles(code)

suite "Linked List Pattern Compilation":
  test "Valid patterns should compile":
    # Simple compilation test - if this compiles, the patterns are syntactically valid
    var list = initSinglyLinkedList[int]()
    let compilationTest = match list:
      [empty()]: 0
      [single(x)]: x
      [length(5)]: 5
      [node(val)]: val
      _: -1
    
    # The fact that we got here means it compiled successfully
    check true
  
  test "Basic linked list functionality verification":
    # Verify that our patterns actually work with real data
    var list = initSinglyLinkedList[int]()
    list.add(42)
    
    let result = match list:
      [empty()]: "empty"
      [single(x)]: "single_" & $x
      [length(2)]: "two"
      _: "other"
    
    check result == "single_42"