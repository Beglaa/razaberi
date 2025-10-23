import unittest
import ../../pattern_matching

suite "Spread Pattern Index Collision Bug":
  
  test "BUG: Elements after spread with defaults should handle negative indices correctly":
    # This test exposes the actualIndex >= spreadIndex bug in pattern_matching.nim:4224-4230
    # When sequence is shorter than expected, calculated indices can be negative
    # but the additional spreadIndex check prevents proper default value usage
    
    let shortSeq = @[1]
    
    # RUST SEMANTICS: Rightmost elements have priority over spread in beginning spreads
    # The pattern [*rest, a=10, b=20] should bind:
    # - rest = @[] (empty, rightmost elements get priority)
    # - a = 10 (default, sequence element reserved for rightmost)  
    # - b = 1 (gets sequence value due to rightmost priority)
    let result = match shortSeq:
      [*rest, a = 10, b = 20]: "rest: " & $rest.len & ", a: " & $a & ", b: " & $b
      _: "no match"
    
    check result == "rest: 0, a: 10, b: 1"
  
  test "BUG: Single element with spread and multiple defaults":
    # This targets the specific bug where actualIndex calculation goes negative
    let singleElement = @[42]
    
    # RUST SEMANTICS: Rightmost elements have priority over spread in beginning spreads
    # Pattern: [*beginning, x=1, y=2, z=3]
    # Expected: beginning=@[], x=1, y=2, z=42 (rightmost gets sequence value)
    let result = match singleElement:
      [*beginning, x = 1, y = 2, z = 3]: 
        "begin: " & $beginning & ", x: " & $x & ", y: " & $y & ", z: " & $z
      _: "no match"
    
    check result == "begin: @[], x: 1, y: 2, z: 42"
  
  test "BUG: Empty sequence with spread and defaults (extreme case)":
    # Extreme case: empty sequence with spread and defaults
    let emptySeq: seq[int] = @[]
    
    # This should work: spread gets empty sequence, all elements use defaults
    let result = match emptySeq:
      [*all, first = 100, second = 200]: "all: " & $all & ", first: " & $first & ", second: " & $second
      _: "no match"
    
    check result == "all: @[], first: 100, second: 200"
  
  test "CONTROL: Elements after spread without defaults (should work)":
    # Control test - elements after spread without defaults should work correctly
    let longSeq = @[1, 2, 3, 4, 5]
    
    let result = match longSeq:
      [*beginning, second_last, last]: "begin: " & $beginning & ", second_last: " & $second_last & ", last: " & $last
      _: "no match"
    
    check result == "begin: @[1, 2, 3], second_last: 4, last: 5"
  
  test "BUG: Spread in middle with defaults on both sides":
    # This tests the index collision bug from both directions
    let mediumSeq = @[10, 20]
    
    # Pattern: [first=1, *middle, last=999]
    # With seq @[10, 20]: first=10, middle=@[], last=20
    # But if we have shorter seq @[10]: first=10, middle=@[], last=999 (default)
    let result = match @[10]:
      [first = 1, *middle, last = 999]: "first: " & $first & ", middle: " & $middle & ", last: " & $last
      _: "no match"
    
    check result == "first: 10, middle: @[], last: 999"
  
  test "BUG: Multiple defaults after spread with edge case indices":
    # RUST SEMANTICS: Rightmost elements have priority over spread in beginning spreads
    let tinySeq = @[7]
    
    # Complex pattern with rightmost priority: d gets sequence value, others get defaults
    let result = match tinySeq:
      [*start, a = -1, b = -2, c = -3, d = -4]: 
        "start: " & $start & ", a: " & $a & ", b: " & $b & ", c: " & $c & ", d: " & $d
      _: "no match"
    
    check result == "start: @[], a: -1, b: -2, c: -3, d: 7"