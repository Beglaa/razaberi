import unittest
import ../../pattern_matching
import std/tables
import std/sets
import std/lists
import std/deques

{.push warning[UnusedImport]: off.}
{.push hint[XDeclaredButNotUsed]: off.}

# GOLD: Critical bug test that must never be removed or disabled
# This test verifies that empty collection patterns work correctly for ALL supported collection types
# Empty patterns tested:
#   - {} for: Table, OrderedTable, CountTable, HashSet
#   - [] for: seq, array, Deque
#   - [empty()] for: SinglyLinkedList, DoublyLinkedList, SinglyLinkedRing, DoublyLinkedRing
#   - () for: tuples

suite "Empty Collection Patterns (Critical)":
  
  test "empty table pattern {} should match empty Table":
    let emptyTable = initTable[string, int]()
    
    let result = match emptyTable:
      {} : "matched empty table"
    
    check result == "matched empty table"

  test "empty table pattern {} should NOT match non-empty Table":
    let nonEmptyTable = {"key": 42}.toTable()
    
    let result = match nonEmptyTable:
      {} : "matched empty table"
      _ : "not matched"
    
    check result == "not matched"
  
  test "empty sequence pattern [] should match empty seq":
    let emptySeq: seq[int] = @[]
    
    let result = match emptySeq:
      [] : "matched empty seq"
    
    check result == "matched empty seq"

  test "empty sequence pattern [] should NOT match non-empty seq":
    let nonEmptySeq = @[1, 2, 3]
    
    let result = match nonEmptySeq:
      [] : "matched empty seq"
      _ : "not matched"
    
    check result == "not matched"

  test "empty tuple pattern () should match empty tuple":
    let emptyTuple = ()
    
    let result = match emptyTuple:
      () : "matched empty tuple"
    
    check result == "matched empty tuple"

  test "empty set pattern {} should match empty HashSet":
    let emptySet = initHashSet[int]()
    
    let result = match emptySet:
      {} : "matched empty set"
    
    check result == "matched empty set"

  test "nested empty patterns should work":
    var emptySeqInt: seq[int] = @[]
    let tableWithEmptySeq = {"key": emptySeqInt}.toTable()

    let result = match tableWithEmptySeq:
      {"key": []} : "matched nested empty"
      _ : "not matched"

    check result == "matched nested empty"

  test "empty OrderedTable pattern {} should match empty OrderedTable":
    let emptyOrderedTable = initOrderedTable[string, int]()

    let result = match emptyOrderedTable:
      {} : "matched empty ordered table"

    check result == "matched empty ordered table"

  test "empty OrderedTable pattern {} should NOT match non-empty OrderedTable":
    let nonEmptyOrderedTable = {"key": 42}.toOrderedTable()

    let result = match nonEmptyOrderedTable:
      {} : "matched empty ordered table"
      _ : "not matched"

    check result == "not matched"

  test "empty array pattern [] should match zero-length array":
    let emptyArray: array[0, int] = []

    let result = match emptyArray:
      [] : "matched empty array"

    check result == "matched empty array"

  test "empty DoublyLinkedList pattern [empty()] should match empty list":
    var emptyDList = initDoublyLinkedList[string]()

    let result = match emptyDList:
      [empty()] : "matched empty doubly linked list"
      _ : "not matched"

    check result == "matched empty doubly linked list"

  test "empty DoublyLinkedRing pattern [empty()] should match empty ring":
    var emptyDRing = initDoublyLinkedRing[int]()

    let result = match emptyDRing:
      [empty()] : "matched empty doubly linked ring"
      _ : "not matched"

    check result == "matched empty doubly linked ring"

  test "empty Deque pattern [] should match empty Deque":
    let emptyDeque = initDeque[string]()

    let result = match emptyDeque:
      [] : "matched empty deque"

    check result == "matched empty deque"

  test "empty Deque pattern [] should NOT match non-empty Deque":
    let nonEmptyDeque = [1, 2, 3].toDeque()

    let result = match nonEmptyDeque:
      [] : "matched empty deque"
      _ : "not matched"

    check result == "not matched"

  test "empty CountTable pattern {} should match empty CountTable":
    let emptyCountTable = initCountTable[string]()

    let result = match emptyCountTable:
      {} : "matched empty count table"

    check result == "matched empty count table"

  test "empty CountTable pattern {} should NOT match non-empty CountTable":
    let nonEmptyCountTable = toCountTable(["apple", "banana", "apple"])

    let result = match nonEmptyCountTable:
      {} : "matched empty count table"
      _ : "not matched"

    check result == "not matched"

  test "empty SinglyLinkedList pattern [empty()] should match empty list":
    var emptySList = initSinglyLinkedList[int]()

    let result = match emptySList:
      [empty()] : "matched empty singly linked list"
      _ : "not matched"

    check result == "matched empty singly linked list"

  test "empty SinglyLinkedRing pattern [empty()] should match empty ring":
    var emptySRing = initSinglyLinkedRing[string]()

    let result = match emptySRing:
      [empty()] : "matched empty singly linked ring"
      _ : "not matched"

    check result == "matched empty singly linked ring"

# Test to verify that non-empty collections work fine
suite "Non-Empty Pattern Verification":
  
  test "verify that non-empty collections work fine":
    # Verify that the bug only affects empty collections
    let nonEmptyTable = {"key": 42}.toTable()
    let nonEmptySeq = @[1]
    let nonEmptyTuple = (1,)
    
    # These should work fine
    let result1 = match nonEmptyTable:
      {"key": 42} : "matched"
      _ : "not matched"
    check result1 == "matched"
    
    let result2 = match nonEmptySeq:
      [1] : "matched"
      _ : "not matched" 
    check result2 == "matched"
    
    let result3 = match nonEmptyTuple:
      (1,) : "matched"
      _ : "not matched"
    check result3 == "matched"