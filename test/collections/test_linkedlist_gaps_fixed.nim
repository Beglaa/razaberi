## Test file to verify all 5 LinkedList gaps are fixed
##
## GAP-1: Variable binding returns zeros - FIXED
## GAP-2: Wildcards extract zero - FIXED
## GAP-3: Spread at beginning fails - FIXED
## GAP-4: Spread in middle fails - FIXED
## GAP-5: Default values fail - FIXED

import std/lists
import std/sequtils
import unittest
import ../../pattern_matching

suite "GAP-1 and GAP-2: Variable Binding Returns Actual Values (Not Zeros)":

  test "GAP-1: [a, b, c] extracts actual values, not zeros":
    var list: SinglyLinkedList[int]
    list.add(10)
    list.add(20)
    list.add(30)

    let result = match list:
      [a, b, c]: (a, b, c)
      _: (0, 0, 0)

    check result[0] == 10  # Was failing: a == 0
    check result[1] == 20  # Was failing: b == 0
    check result[2] == 30  # Was failing: c == 0

  test "GAP-2: [_, x, _] extracts middle element, not zero":
    var list: SinglyLinkedList[int]
    list.add(10)
    list.add(20)
    list.add(30)

    let result = match list:
      [_, x, _]: x
      _: 0

    check result == 20  # Was failing: x == 0

suite "GAP-3: Spread at Beginning [*init, last]":

  test "Spread at beginning with SinglyLinkedList":
    var list: SinglyLinkedList[int]
    list.add(10)
    list.add(20)
    list.add(30)
    list.add(40)

    let result = match list:
      [*init, last]:
        # Convert init to seq to check length and contents
        var initSeq: seq[int] = @[]
        for item in init.items:
          initSeq.add(item)
        (initSeq, last)
      _: (@[], 0)

    check result[1] == 40
    check result[0] == @[10, 20, 30]

  test "Spread at beginning with DoublyLinkedList":
    var list: DoublyLinkedList[int]
    list.add(1)
    list.add(2)
    list.add(3)
    list.add(4)
    list.add(5)

    let result = match list:
      [*init, last]:
        var count = 0
        for _ in init.items:
          count += 1
        (count, last)
      _: (0, 0)

    check result[0] == 4  # init has 4 elements
    check result[1] == 5  # last is 5

suite "GAP-4: Spread in Middle [first, *middle, last]":

  test "Spread in middle with SinglyLinkedList":
    var list: SinglyLinkedList[int]
    list.add(1)
    list.add(2)
    list.add(3)
    list.add(4)
    list.add(5)

    let result = match list:
      [first, *middle, last]:
        var middleSeq: seq[int] = @[]
        for item in middle.items:
          middleSeq.add(item)
        (first, middleSeq, last)
      _: (0, @[], 0)

    check result[0] == 1
    check result[1] == @[2, 3, 4]
    check result[2] == 5

  test "Spread in middle with DoublyLinkedList":
    var list: DoublyLinkedList[int]
    list.add(10)
    list.add(20)
    list.add(30)
    list.add(40)
    list.add(50)
    list.add(60)

    let result = match list:
      [first, *middle, last]:
        var middleSeq: seq[int] = @[]
        for item in middle.items:
          middleSeq.add(item)
        (first, middleSeq, last)
      _: (0, @[], 0)

    check result[0] == 10
    check result[1] == @[20, 30, 40, 50]
    check result[2] == 60

suite "GAP-5: Default Values [x, y = 10]":

  test "Default values with SinglyLinkedList":
    var shortList: SinglyLinkedList[int]
    shortList.add(100)

    let result = match shortList:
      [x, y = 10]: (x, y)
      _: (0, 0)

    check result[0] == 100  # Actual value
    check result[1] == 10   # Default value

  test "Default values with DoublyLinkedList":
    var shortList: DoublyLinkedList[int]
    shortList.add(5)

    let result = match shortList:
      [x, y = 20, z = 30]: (x, y, z)
      _: (0, 0, 0)

    check result[0] == 5   # Actual value
    check result[1] == 20  # Default value
    check result[2] == 30  # Default value

  test "Partial defaults with SinglyLinkedList":
    var list: SinglyLinkedList[int]
    list.add(1)
    list.add(2)

    let result = match list:
      [a, b, c = 99]: (a, b, c)
      _: (0, 0, 0)

    check result[0] == 1
    check result[1] == 2
    check result[2] == 99  # Default

suite "Combined Patterns - Spread + Defaults":

  test "Spread at end with defaults":
    var list: SinglyLinkedList[int]
    list.add(1)

    let result = match list:
      [first, second = 10, *rest]:
        var restSeq: seq[int] = @[]
        for item in rest.items:
          restSeq.add(item)
        (first, second, restSeq)
      _: (0, 0, newSeq[int]())

    check result[0] == 1
    check result[1] == 10  # Default
    check result[2].len == 0  # Empty spread

suite "All LinkedList Types Work Identically":

  test "All four LinkedList types support spread at beginning":
    var singly: SinglyLinkedList[int]
    var doubly: DoublyLinkedList[int]
    var singlyRing: SinglyLinkedRing[int]
    var doublyRing: DoublyLinkedRing[int]

    for i in 1..4:
      singly.add(i)
      doubly.add(i)
      singlyRing.add(i)
      doublyRing.add(i)

    let r1 = match singly:
      [*init, last]: last
      _: 0

    let r2 = match doubly:
      [*init, last]: last
      _: 0

    let r3 = match singlyRing:
      [*init, last]: last
      _: 0

    let r4 = match doublyRing:
      [*init, last]: last
      _: 0

    let results = @[r1, r2, r3, r4]
    for result in results:
      check result == 4
