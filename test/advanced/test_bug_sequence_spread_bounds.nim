import unittest
import ../../pattern_matching

suite "Critical Bug: Sequence Spread Pattern Off-by-One Error":
  test "spread pattern bounds calculation bug - elements after spread":
    # CRITICAL BUG DEMONSTRATION
    # Bug: Off-by-one error in bounds checking for elements after spread operator
    # Location: pattern_matching.nim line 4277 and 4309
    # The bug causes incorrect bounds checking when accessing elements after spread
    
    # This pattern should match but FAILS due to the bounds bug
    let data = @[1, 2, 3]  # Length = 3
    
    # Pattern: [*prefix, second_last, last]
    # Expected: prefix = @[1], second_last = 2, last = 3
    # Bug: Incorrect bounds calculation prevents matching
    var matched = false
    var prefix: seq[int]
    var second_last: int
    var last: int
    
    try:
      let result = match data:
        [*p, sl, l]: 
          matched = true
          prefix = p
          second_last = sl
          last = l
          "matched"
        _: "no match"
      
      # This assertion SHOULD pass but FAILS due to the bug
      check matched == true
      
      if matched:
        check prefix == @[1]
        check second_last == 2
        check last == 3
      else:
        check false # Pattern [*prefix, second_last, last] failed on @[1, 2, 3]. Expected: prefix=@[1], second_last=2, last=3
        
    except Exception as e:
      check false # Exception during pattern matching
  
  test "spread pattern bounds bug - minimum case":
    # Minimum reproduction case showing the exact off-by-one error
    let data = @[10, 20]  # Only 2 elements
    
    var matched = false
    var first: int
    var last: int
    
    let result = match data:
      [f, l]:  # Should match: first=10, last=20
        matched = true
        first = f
        last = l
        "simple match"
      [*empty, single_last]:  # This should also match but may fail
        "spread with single"
      _: "no match"
    
    # This basic pattern should work
    check matched == true
    check first == 10
    check last == 20
    
    # Now test the problematic spread pattern
    var spread_matched = false
    var empty_seq: seq[int]
    var single_value: int
    
    let spread_result = match data:
      [*es, sv]:
        spread_matched = true
        empty_seq = es
        single_value = sv
        "spread matched"
      _: "spread no match"
    
    # BUG: This should match with empty_seq=@[10], single_value=20
    # But fails due to incorrect bounds checking in offsetFromEnd calculation
    check spread_matched == true
    if spread_matched:
      check empty_seq == @[10]
      check single_value == 20
    else:
      check false # [*empty, last] pattern failed on @[10, 20]

  test "spread pattern bounds bug - edge case with three elements":
    # Edge case that reveals the specific off-by-one error
    let data = @[100, 200, 300]
    
    var matched = false
    var middle: seq[int]
    var last_two: (int, int)
    
    let result = match data:
      [*m, second, third]:
        matched = true
        middle = m
        last_two = (second, third)
        "pattern matched"
      _: "no match"
    
    # Expected: middle=@[100], second=200, third=300
    # Bug: offsetFromEnd calculation is wrong, causing bounds check failure
    check matched == true
    
    if matched:
      check middle == @[100]
      check last_two[0] == 200
      check last_two[1] == 300
    else:
      check false # [*middle, second, third] failed on @[100, 200, 300]. Root cause may be in collision detection logic

  test "spread pattern bounds bug - collision detection error":
    # Test the specific collision detection bug in line 4309
    let data = @[1, 2]  # Minimal case
    
    var matched = false
    var prefix: seq[int]
    var last_elem: int
    
    let result = match data:
      [*p, l]:
        matched = true  
        prefix = p
        last_elem = l
        "matched"
      _: "no match"
    
    # This SHOULD match with prefix=@[1], last_elem=2
    # BUG: Collision detection formula may be wrong:
    # Line 4309: actualScrutineeVar.len >= spreadIndex + elementsAfterSpread
    # For our case: 2 >= 0 + 1 = 2 >= 1 = true (correct)
    # But the overall logic might still fail
    
    check matched == true
    if matched:
      check prefix == @[1]
      check last_elem == 2
    else:
      check false # Even minimal [*prefix, last] fails on @[1, 2]. This confirms bounds checking bug in collision detection

  test "demonstrate working vs broken patterns":
    # Show which patterns work vs which are broken
    let data = @[1, 2, 3, 4, 5]
    
    # Pattern that should work (no spread)
    var simple_matched = false
    let simple_result = match data:
      [a, b, c, d, e]:
        simple_matched = true
        "all elements"
      _: "simple no match"
    
    check simple_matched == true
    
    # Pattern with spread at end (most likely to work)
    var end_spread_matched = false
    let end_result = match data:
      [first, *rest]:
        end_spread_matched = true
        "end spread"
      _: "end spread no match"
    
    check end_spread_matched == true
    
    # Pattern with spread in middle (most likely to be broken)
    var middle_spread_matched = false  
    let middle_result = match data:
      [first, *middle, last]:
        middle_spread_matched = true
        "middle spread"
      _: "middle spread no match"
    
    # This is where the bug is most likely to manifest
    if not middle_spread_matched:
      check false # Middle spread pattern [first, *middle, last] fails. Bug location: offsetFromEnd calculation or collision detection logic
      
    check middle_spread_matched == true