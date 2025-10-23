import unittest
import ../../pattern_matching

{.push warning[UnusedImport]: off.}
{.push hint[XDeclaredButNotUsed]: off.}

# BUG FIX TEST: Multiple spread operators in sequence patterns
# This test demonstrates and verifies the fix for the multiple spread bug
# The bug: Multiple spreads like [*a, b, *c] produce incorrect/ambiguous results

suite "Multiple Spread Pattern Bug Fix":

  test "Multiple spreads should be rejected with clear error":
    # Multiple spread patterns are ambiguous and should be rejected during compilation
    # Pattern [*start, middle, *tail] is ambiguous - where to split between spreads?
    
    let testSeq = @[1, 2, 3, 4, 5]
    
    # This should now be rejected with a clear error message during compilation
    # The test will fail to compile if the bug is fixed properly
    when not compiles(
      block:
        let result = match testSeq:
          [*start, middle, *tail]: "Multiple spreads should not compile"
          _: "Failed"
    ):
      # Good - the pattern is correctly rejected  
      check true
      # Multiple spread pattern correctly rejected during compilation
    else:
      # Bug still present - multiple spreads are incorrectly allowed
      let result = match testSeq:
        [*start, middle, *tail]: 
          # BUG: Multiple spreads still allowed - pattern should be rejected
          "Multiple spreads incorrectly allowed"
        _: "Failed"
      check false, "BUG: Multiple spread patterns should be rejected but are still allowed"

  test "Multiple spreads with more elements should be rejected":
    let testSeq = @[10, 20, 30, 40, 50, 60]
    
    # Pattern [*a, b, c, *d] should also be rejected as ambiguous
    when not compiles(
      block:
        let result = match testSeq:
          [*a, b, c, *d]: "Multiple spreads should not compile"
          _: "Failed"
    ):
      check true
      # Complex multiple spread pattern correctly rejected
    else:
      let result = match testSeq:
        [*a, b, c, *d]:
          # BUG: Complex multiple spreads still allowed - pattern should be rejected
          "Multiple spreads incorrectly allowed"
        _: "Failed"
      check false, "BUG: Complex multiple spread patterns should be rejected"

  test "Single spread patterns should still work correctly":
    # Single spread patterns are unambiguous and should continue working
    let testSeq = @[1, 2, 3, 4, 5]
    
    let result1 = match testSeq:
      [first, *middle, last]: "first=" & $first & " middle=" & $middle.len & " last=" & $last  
      _: "Failed"
    
    check result1 == "first=1 middle=3 last=5"
    
    let result2 = match testSeq:
      [*start, last]: "start=" & $start.len & " last=" & $last
      _: "Failed"
      
    check result2 == "start=4 last=5"
    
    let result3 = match testSeq:
      [first, *rest]: "first=" & $first & " rest=" & $rest.len  
      _: "Failed"
      
    check result3 == "first=1 rest=4"

  test "Empty spreads should work correctly":
    let emptySeq: seq[int] = @[]
    let singleSeq = @[42]
    
    let result1 = match emptySeq:
      [*all]: "all=" & $all.len
      _: "Failed"
    check result1 == "all=0"
    
    let result2 = match singleSeq:
      [*start, last]: "start=" & $start.len & " last=" & $last
      _: "Failed"  
    check result2 == "start=0 last=42"