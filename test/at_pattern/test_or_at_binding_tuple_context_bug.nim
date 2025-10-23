import unittest
include ../../pattern_matching

# BUG DISCOVERED: "Unsupported OR pattern alternative in @ binding"
# 
# Location: pattern_matching.nim:5867 in processTupleLayer function
# 
# Bug Description:
# OR patterns with @ bindings inside tuple contexts fail with "Unsupported OR pattern alternative in @ binding".
# The processTupleLayer function doesn't properly handle OR patterns with @ bindings when they appear
# as elements within tuple patterns.
#
# Expected Behavior:
# OR patterns with @ bindings should work the same way inside tuples as they do outside tuples.
# The @ binding should capture whichever alternative from the OR pattern actually matched.
#
# Impact:
# This limits the expressiveness of pattern matching in tuple contexts, forcing users to write
# more verbose pattern arms instead of using concise OR patterns with @ bindings.

suite "BUG: OR Pattern @ Binding in Tuple Context":
  
  test "BUG REPRODUCTION: OR pattern with @ binding inside tuple pattern fails":
    let data = (@[1, 2], "hello")
    
    # This SHOULD work: Match either [1,2] or [3,4] and bind the matched array to matched_seq
    # But currently fails with "Unsupported OR pattern alternative in @ binding"
    let result = match data:
      (([1, 2] | [3, 4]) @ matched_seq, ("hello" | "world")):
        "Matched seq: " & $matched_seq & " with length " & $matched_seq.len
      _:
        "No match"
    
    # Expected: Should match [1,2] and return "Matched seq: @[1, 2] with length 2"
    check result == "Matched seq: @[1, 2] with length 2"

  test "BUG AMPLIFICATION: Multiple OR @ bindings in same tuple":
    let data = (@[1, 2], @[5, 6], "test")
    
    # This should demonstrate the bug affects multiple @ bindings in the same tuple
    let result = match data:
      (([1, 2] | [3, 4]) @ first_seq, ([5, 6] | [7, 8]) @ second_seq, ("test" | "demo")):
        "First: " & $first_seq.len & ", Second: " & $second_seq.len
      _:
        "No match"
    
    check result == "First: 2, Second: 2"

  test "BUG WITH NESTED STRUCTURES: OR @ binding with object patterns in tuples":
    type
      Point = object
        x, y: int
    
    let data = (Point(x: 1, y: 2), "label")
    
    # Testing OR @ binding with object constructor patterns inside tuples
    let result = match data:
      ((Point(x: 1, y: 2) | Point(x: 3, y: 4)) @ point, ("label" | "tag")):
        "Point: (" & $point.x & "," & $point.y & ")"
      _:
        "No match"
    
    check result == "Point: (1,2)"

  test "CONTROL: OR pattern with @ binding OUTSIDE tuple works (should pass)":
    let data = @[1, 2]
    
    # This should work fine - OR @ binding outside tuple context
    let result = match data:
      ([1, 2] | [3, 4]) @ matched_seq:
        "Matched seq: " & $matched_seq & " with length " & $matched_seq.len
      _:
        "No match"
    
    check result == "Matched seq: @[1, 2] with length 2"

  test "CONTROL: OR pattern WITHOUT @ binding inside tuple works (should pass)":
    let data = (@[1, 2], "hello")
    
    # This should work - OR pattern without @ binding inside tuple
    let result = match data:
      ([1, 2] | [3, 4], "hello" | "world"):
        "Matched tuple pattern"
      _:
        "No match"
    
    check result == "Matched tuple pattern"

  test "CONTROL: Regular @ binding (non-OR) inside tuple works (should pass)":
    let data = (@[1, 2], "hello")
    
    # This should work - regular @ binding (no OR) inside tuple
    let result = match data:
      ([1, 2] @ matched_seq, "hello"):
        "Matched seq: " & $matched_seq & " with length " & $matched_seq.len
      _:
        "No match"
    
    check result == "Matched seq: @[1, 2] with length 2"

  test "BUG VARIANT: OR @ binding in deeply nested tuple":
    let data = ((1, (@[10, 20], "inner")), "outer")
    
    # Testing the bug in more complex nested tuple structures
    let result = match data:
      ((val, (([10, 20] | [30, 40]) @ inner_seq, "inner")), "outer"):
        "Val: " & $val & ", Inner: " & $inner_seq & ", Length: " & $inner_seq.len
      _:
        "No match"
    
    check result == "Val: 1, Inner: @[10, 20], Length: 2"