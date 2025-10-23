import unittest
import ../../pattern_matching

# SPREAD OPERATOR WITH EMPTY SEQUENCES BUG TEST
# This test identifies a potential bug when combining spread operators with empty sequences
# and default values in complex patterns

suite "Spread Operator Empty Sequence Edge Cases":
  test "should handle empty sequences with spread operators correctly":
    # Test case 1: Empty sequence with middle spread
    let empty: seq[int] = @[]
    
    let result1 = match empty:
      [first, *middle, last] : "has first and last"
      [] : "captured all (empty)"
      _ : "no match"
    
    # Expected: should match [] pattern since empty sequence cannot have first and last
    check result1 == "captured all (empty)"
    
    # Test case 2: Single element with spread expecting more
    let single = @[42]
    
    let result2 = match single:
      [first, second, *rest] : "has at least two"  # Needs at least 2 elements
      [first, *rest] : "has at least one"          # Needs at least 1 element  
      _ : "no match"
      
    check result2 == "has at least one"
    
    # Test case 3: Two elements with middle spread  
    let pair = @[1, 2]
    
    let result3 = match pair:
      [first, *middle, last] : "first=" & $first & " last=" & $last # Middle should be empty
      _ : "no match"
      
    check result3 == "first=1 last=2"

  test "should handle spread operators with default values edge case":
    # Test case: Spread with defaults when sequence is shorter than expected
    let short = @[10]
    
    # This might expose a bug: what happens when spread captures empty slice
    # and we have default values for elements that don't exist?
    let result = match short:
      [first = 0, *middle, last = 99] : 
        "first=" & $first & " middle=" & $middle.len & " last=" & $last
      _ : "no match"
    
    # Expected behavior: first=10, middle empty, last=99 (default)
    # But this might reveal a bug if the pattern matching doesn't handle
    # the interaction between spread operators and default values correctly
    check result == "first=10 middle=0 last=99"

  test "should handle nested empty sequences with spreads":
    # Complex nested pattern with empty sequences and spreads
    type Container = object
      data: seq[seq[int]]
      
    let container = Container(data: @[@[], @[1], @[]])
    
    let result = match container:
      Container(data: [[], [*content], []]) : "pattern with empty and spread: " & $content
      Container(data: data) : "fallback: " & $data.len & " sequences"
      _ : "no match"
    
    check result == "pattern with empty and spread: @[1]"

  test "should handle edge case with multiple empty sequences and spreads":
    # Edge case: what if we have complex spread patterns with multiple empty parts?
    let mixed = @[1, 2, 3, 4, 5]
    
    # Pattern that should match but might have edge case bugs
    let result = match mixed:
      [a, *empty_start] and empty_start.len == 0 : "impossible - empty_start can't be empty"
      [a, b, *middle, d, e] and middle.len == 1 : "middle=" & $middle[0]  
      [*all] : "fallback all=" & $all.len
      _ : "no match"
    
    check result == "middle=3"

  test "should handle spread operator boundary conditions":
    # Test spread operators at sequence boundaries
    let nums = @[1, 2, 3]
    
    # Edge case: spread at very beginning with minimum required elements
    let result1 = match nums:
      [*start, last] and start.len >= 2 : "start=" & $start & " last=" & $last
      _ : "no match"
    
    check result1 == "start=@[1, 2] last=3"
    
    # Edge case: spread at very end with minimum required elements  
    let result2 = match nums:
      [first, *tail] and tail.len >= 2 : "first=" & $first & " tail=" & $tail
      _ : "no match"
      
    check result2 == "first=1 tail=@[2, 3]"
    
    # Edge case: what if we require more elements than available?
    let result3 = match nums:
      [a, b, c, d, *rest] : "has at least 4 elements"  # nums only has 3
      [a, b, c, *rest] : "has exactly 3 elements: rest=" & $rest.len
      _ : "no match"
      
    check result3 == "has exactly 3 elements: rest=0"