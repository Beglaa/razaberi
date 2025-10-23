import std/unittest
import std/tables
import ../../pattern_matching

# Test specifically for the spread operator with defaults negative index fix
# This tests the bug that was causing "value out of range: -1" runtime errors
# when using spread patterns with defaults on empty or short sequences

suite "Spread Operator Negative Index Fix":
  
  test "empty sequence with spread and defaults should not cause negative index":
    # This would have failed before the fix with "value out of range: -1"
    let empty = newSeq[int]()
    let result = match empty:
      [first, *middle, (last = 99)]:
        "First: " & $first & ", Middle: " & $middle.len & ", Last: " & $last
      _: 
        "Empty or single element"
    
    check result == "Empty or single element"
  
  test "single element sequence with spread and defaults should work correctly":
    let single = @[42]
    let result = match single:
      [first, *middle, (last = 99)]:
        "First: " & $first & ", Middle: " & $middle.len & ", Last: " & $last
      _:
        "Single element: " & $single[0]
    
    check result == "First: 42, Middle: 0, Last: 99"
  
  test "two element sequence with spread and defaults should work correctly":
    let two = @[1, 2]
    let result = match two:
      [first, *middle, (last = 99)]:
        "First: " & $first & ", Middle: " & $middle.len & ", Last: " & $last
      _:
        "Other"
    
    check result == "First: 1, Middle: 0, Last: 2"
  
  test "three element sequence with spread and defaults should use actual value":
    let three = @[1, 2, 3]
    let result = match three:
      [first, *middle, (last = 99)]:
        "First: " & $first & ", Middle: " & $middle.len & ", Last: " & $last
      _:
        "Other"
    
    check result == "First: 1, Middle: 1, Last: 3"
  
  test "spread with multiple defaults should handle empty sequence":
    let empty = newSeq[int]()
    let result = match empty:
      [*middle, (second_last = 88), (last = 99)]:
        "Middle: " & $middle.len & ", Second last: " & $second_last & ", Last: " & $last
      _:
        "Empty sequence"
    
    check result == "Middle: 0, Second last: 88, Last: 99"
  
  # BUG: Rightmost element priority should match Rust behavior
  # Rust behavior: [rest @ .., last] with [42] -> rest=[], last=42 (rightmost gets sequence value)
  # Current Nim: Middle: 1, Second last: 88, Last: 99 (left-to-right priority, spread takes element)
  # Expected Nim: Middle: 0, Second last: 88, Last: 42 (rightmost priority, last gets sequence value)
  # This test ensures compatibility with Rust slice pattern semantics
  test "spread with multiple defaults should handle single element":
      let single = @[42]
      let result = match single:
        [*middle, (second_last = 88), (last = 99)]:
          "Middle: " & $middle.len & ", Second last: " & $second_last & ", Last: " & $last
        _:
          "Single element"
      
      check result == "Middle: 0, Second last: 88, Last: 42"
  
  test "literal patterns with spread and defaults should not cause negative index":
    let empty = newSeq[int]()
    let result = match empty:
      [1, *middle, (last = 99)]:
        "Found pattern"
      _:
        "No match"
    
    check result == "No match"
    
  test "literal comparison with defaults should handle empty sequence correctly":
    let empty = newSeq[int]()
    let result = match empty:
      [*middle, 42]:
        "Found 42 at end"
      [*middle, (last = 42)]:
        "Default 42 at end, middle length: " & $middle.len
      _:
        "No match"
    
    check result == "Default 42 at end, middle length: 0"