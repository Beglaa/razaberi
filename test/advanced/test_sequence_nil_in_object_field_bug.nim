## Test: Sequence Nil Literal in Object Field Pattern Bug
##
## BUG DISCOVERED: The pattern matching library fails when matching sequences 
## that contain nil literals inside object constructor field patterns.
##
## ERROR: "Unsupported sequence element: nnkNilLit" at pattern_matching.nim:11404
##
## ROOT CAUSE: The sequence pattern processing within object constructor fields 
## is missing nnkNilLit support for nil literal elements in sequences.
##
## IMPACT: Patterns like Container(items: [first, nil, last]) fail compilation
## when they should successfully match sequences containing nil refs.

import unittest
import ../../pattern_matching

type
  RefNode = ref object
    data: int
  
  Container = object
    items: seq[RefNode]
    count: int

suite "Sequence Nil Literal in Object Field Bug":
  
  test "sequence with nil in object field pattern - FAILS with nnkNilLit error":
    ## This test demonstrates the bug: nil literals in sequence patterns within object fields
    let node1 = RefNode(data: 10)
    let nilRef: RefNode = nil  
    let node2 = RefNode(data: 20)
    
    let container = Container(
      items: @[node1, nilRef, node2],
      count: 3
    )
    
    var matched = false
    var first: RefNode
    var last: RefNode
    
    # This pattern SHOULD work but currently fails with "Unsupported sequence element: nnkNilLit"
    let result = match container:
      Container(items: [first_item, nil, last_item], count: 3):
        matched = true
        first = first_item
        last = last_item
        "matched_with_nil"
      _: "no_match"
    
    # Once bug is fixed, these assertions should pass
    check matched == true
    check first != nil
    check first.data == 10
    check last != nil  
    check last.data == 20
    check result == "matched_with_nil"

  test "control - sequence without nil in object field works":
    ## Control test to ensure the bug is specific to nil literals in sequences
    let node1 = RefNode(data: 100)
    let node2 = RefNode(data: 200)
    
    let container = Container(
      items: @[node1, node2],
      count: 2  
    )
    
    var matched = false
    var first: RefNode
    var second: RefNode
    
    let result = match container:
      Container(items: [f, s], count: 2):
        matched = true
        first = f
        second = s
        "control_match"
      _: "no_match"
    
    # This should work fine (no nil involved)
    check matched == true
    check first != nil
    check first.data == 100
    check second != nil
    check second.data == 200
    check result == "control_match"