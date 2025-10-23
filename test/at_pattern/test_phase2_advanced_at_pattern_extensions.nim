import unittest
import std/strutils
import ../../pattern_matching

suite "PHASE 2: Advanced @ Pattern Syntax Extensions - IMPLEMENTED":
  # These are the advanced features from FUTURE_ENHANCEMENTS.md Phase 2
  # Testing nested @ patterns within @ patterns and complex @ pattern chains
  
  test "Nested @ patterns within @ patterns - Sequence context":
    # Target: [(person @ p and p.name @ name)] @ people (simplified to sequence context)
    # Testing nested @ patterns within sequence @ patterns
    let testData = [[2, 3]]
    
    let result = match testData:
      [[(1|2) @ inner, y] @ outer] @ complete :
        "complete: " & $complete.len & ", outer: " & $outer.len & ", inner: " & $inner & ", y: " & $y
      _ : "no match"
    
    check result == "complete: 1, outer: 2, inner: 2, y: 3"
  
  test "Recursive @ pattern binding - Triple nesting":
    # Target: [[(1|2) @ inner] @ outer] @ complete
    # Testing deeply nested sequence @ patterns
    let testData = [[[1]]]
    
    let result = match testData:
      [[[(1|2) @ inner] @ outer] @ complete] :
        "triple nest: complete=" & $complete.len & ", outer=" & $outer.len & ", inner=" & $inner
      _ : "no match"
    
    check result == "triple nest: complete=1, outer=1, inner=1"
  
  test "Multi-level @ pattern chains - Complex nesting":
    # Testing @ patterns at multiple nesting levels
    let testData = ([[15, 20]], 42)
    
    let result = match testData:
      ([[data @ d, other] @ wrapper] @ container, extra) :
        "container: " & $container.len & ", wrapper: " & $wrapper.len & ", data: " & $d & ", other: " & $other & ", extra: " & $extra
      _ : "no match"
    
    check result == "container: 1, wrapper: 2, data: 15, other: 20, extra: 42"
  
  test "@ patterns with OR alternatives - Simplified version":
    # Testing OR patterns with @ bindings in sequence contexts
    let testData = [[1, 2]]
    
    let result = match testData:
      [[(1|2) @ num, other] @ row] @ all_data :
        "all_data: " & $all_data.len & ", row: " & $row.len & ", num: " & $num & ", other: " & $other
      _ : "no match"
    
    check result == "all_data: 1, row: 2, num: 1, other: 2"
  
  test "Deep @ pattern nesting with mixed collection types":
    # Test @ patterns at multiple levels with different data types
    let testData = ([["hello"]], [42])
    
    let result = match testData:
      ([[str] @ strings] @ string_container, [num] @ numbers) :
        "strings: " & $string_container.len & "/" & $strings.len & ", str: " & str & ", numbers: " & $numbers & ", num: " & $num
      _ : "no match"
    
    check result == "strings: 1/1, str: hello, numbers: [42], num: 42"
  
  test "Nested @ patterns with guards - Cross-referencing variables":
    # Test @ patterns with cross-referencing guards
    let testData = [[5], [10]]
    
    let result = match testData:
      ([a @ first] @ arr1, [b @ second] @ arr2) and first < second :
        "ordered: " & $first & " < " & $second & ", arr1: " & $arr1 & ", arr2: " & $arr2
      ([a @ first] @ arr1, [b @ second] @ arr2) :
        "basic: first=" & $first & ", second=" & $second
      _ : "no match"
    
    check result == "ordered: 5 < 10, arr1: [5], arr2: [10]"
  
  test "Complex @ pattern combinations with multiple levels":
    # Test multiple @ patterns at different nesting levels
    let testData = (([1, 2], [3, 4]), [5, 6])
    
    let result = match testData:
      (([a, b] @ first_pair, [c, d] @ second_pair) @ tuple_data, [e, f] @ final_pair) :
        "tuple: " & $tuple_data & ", first: " & $first_pair & "(" & $a & "," & $b & "), second: " & $second_pair & "(" & $c & "," & $d & "), final: " & $final_pair & "(" & $e & "," & $f & ")"
      _ : "no match"
    
    check result == "tuple: ([1, 2], [3, 4]), first: [1, 2](1,2), second: [3, 4](3,4), final: [5, 6](5,6)"
  
  test "Nested @ patterns with wildcard and literal mixing":
    # Test @ patterns with wildcards and literals in nested contexts
    let testData = [[42, 99], [100, 200]]
    
    let result = match testData:
      [[42 @ num, other] @ first_group, [_ @ wildcard, _] @ second_group] @ all_groups :
        "all: " & $all_groups.len & ", first: " & $first_group & "(num=" & $num & ", other=" & $other & "), second: " & $second_group & "(wildcard=" & $wildcard & ")"
      _ : "no match"
    
    check result == "all: 2, first: [42, 99](num=42, other=99), second: [100, 200](wildcard=100)"
  
  test "Advanced @ pattern syntax - Sequence in tuple @ patterns":
    # Test @ patterns with sequences inside tuple patterns
    let testData = ([1, 2, 3], "metadata")
    
    let result = match testData:
      ([first, *rest] @ sequence, metadata @ meta) and sequence.len > 2 :
        "sequence: " & $sequence & "(first=" & $first & ", rest=" & $rest & "), meta: " & meta
      ([first, *rest] @ sequence, metadata @ meta) :
        "basic: seq=" & $sequence & ", meta=" & meta
      _ : "no match"
    
    check result == "sequence: [1, 2, 3](first=1, rest=@[2, 3]), meta: metadata"
  
  test "Complex nested @ patterns - Maximum depth test":
    # Test @ patterns at extreme nesting depth
    let testData = [[[[42]]]]
    
    let result = match testData:
      [[[[(num @ value)] @ level3] @ level2] @ level1] @ level0 :
        "depth 4: l0=" & $level0.len & ", l1=" & $level1.len & ", l2=" & $level2.len & ", l3=" & $level3.len & ", value=" & $value
      _ : "no match"
    
    check result == "depth 4: l0=1, l1=1, l2=1, l3=1, value=42"