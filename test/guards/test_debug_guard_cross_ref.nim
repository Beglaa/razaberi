import unittest
import ../../pattern_matching

suite "Debug Complex Guard Cross-References":
  
  test "Simple bracket @ pattern with guard":
    # Test the simplest case: [(1|2) @ first] and first > 1
    let testData = ([2], 10)
    
    let result = match testData:
      ([(1|2) @ first] and first > 1, number) :
        "matched with guard: first=" & $first & ", number=" & $number
      ([(1|2) @ first], number) :
        "matched without guard: first=" & $first & ", number=" & $number
      _ : "no match"
    
    check result == "matched with guard: first=2, number=10"
  
  test "Simple bracket @ pattern no guard":
    # Verify that simple bracket @ pattern works
    let testData = ([2], 10)
    
    let result = match testData:
      ([value] @ arr, number) :
        "simple match: arr=" & $arr & ", value=" & $value & ", number=" & $number
      _ : "no match"
    
    check result == "simple match: arr=[2], value=2, number=10"
    
  test "Cross-reference without complex guards":
    # Test simple cross-reference between @ patterns
    let testData = ([5], [10])
    
    let result = match testData:
      ([a] @ first, [b] @ second) and a < b :
        "cross-ref match: " & $a & " < " & $b
      ([a] @ first, [b] @ second) :
        "basic match: " & $a & ", " & $b
      _ : "no match"
    
    check result == "cross-ref match: 5 < 10"