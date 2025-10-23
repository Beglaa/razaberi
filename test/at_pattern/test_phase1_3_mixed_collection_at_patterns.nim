import unittest
import std/tables
import std/sets
import std/deques
import ../../pattern_matching

suite "PHASE 1.3: Mixed Collection Types with @ Patterns in Tuple Contexts":
  # These are the missing test cases from FUTURE_ENHANCEMENTS.md
  # Testing mixed collection types with @ patterns in tuple contexts
  
  test "Table + sequence @ patterns in tuples - Basic":
    # Target: ({"key": value} @ table, [item1, item2] @ items) and table.len == items.len
    let testTable = {"key": "hello"}.toTable
    let testItems = ["item1", "item2"]
    let testData = (testTable, testItems)
    
    let result = match testData:
      ({"key": value} @ table, [item1, item2] @ items) and table.len == items.len :
        "Table-Seq match: value=" & value & ", items=" & $items & ", equal_len=" & $table.len
      ({"key": value} @ table, [item1, item2] @ items) :
        "Table-Seq match: value=" & value & ", items=" & $items & ", table_len=" & $table.len
      _ : "no match"
    
    # Should match the second pattern since table.len(1) != items.len(2)  
    check result == "Table-Seq match: value=hello, items=[\"item1\", \"item2\"], table_len=1"
  
  test "Table + sequence @ patterns - Equal lengths":
    # Test case where lengths are equal
    let testTable = {"key1": "hello", "key2": "world"}.toTable
    let testItems = ["item1", "item2"]
    let testData = (testTable, testItems)
    
    let result = match testData:
      ({"key1": value1, "key2": value2} @ table, [item1, item2] @ items) and table.len == items.len :
        "Equal lengths: " & value1 & "+" & value2 & " with " & $items
      ({"key1": value1, "key2": value2} @ table, [item1, item2] @ items) :
        "Not equal: table=" & $table.len & ", items=" & $items.len
      _ : "no match"
    
    check result == "Equal lengths: hello+world with [\"item1\", \"item2\"]"
  
  test "Set + sequence @ pattern combinations":
    # Target: ({Red, Blue} @ colors, [r, g, b] @ rgb) and colors.len == 2
    type Color = enum Red, Blue, Green
    
    let testColors = toHashSet([Red, Blue])
    let testRgb = [255, 0, 128]
    let testData = (testColors, testRgb)
    
    let result = match testData:
      ({Red, Blue} @ colors, [r, g, b] @ rgb) and colors.len == 2 :
        "Set-Seq match: colors=" & $colors.len & ", rgb=(" & $r & "," & $g & "," & $b & ")"
      ({Red, Blue} @ colors, [r, g, b] @ rgb) :
        "Set-Seq basic: colors=" & $colors.len & ", rgb=(" & $r & "," & $g & "," & $b & ")"
      _ : "no match"
    
    check result == "Set-Seq match: colors=2, rgb=(255,0,128)"
  
  test "Set + sequence @ pattern - Length mismatch":
    # Test case where set length doesn't match the guard condition
    type Color = enum Red, Blue, Green
    
    let testColors = toHashSet([Red, Blue, Green])  # length = 3, not 2
    let testRgb = [255, 0, 128]
    let testData = (testColors, testRgb)
    
    let result = match testData:
      ({Red, Blue, Green} @ colors, [r, g, b] @ rgb) and colors.len == 2 :
        "Should not match - length guard failed"
      ({Red, Blue, Green} @ colors, [r, g, b] @ rgb) :
        "Set-Seq basic: colors=" & $colors.len & ", rgb=(" & $r & "," & $g & "," & $b & ")"
      _ : "no match"
    
    check result == "Set-Seq basic: colors=3, rgb=(255,0,128)"
  
  test "Deque + array @ pattern mixing":
    # Target: (deque @ dq, [first, *rest] @ arr) and dq.len > 0
    var testDeque = initDeque[int]()
    testDeque.addLast(10)
    testDeque.addLast(20)
    
    let testArray = [1, 2, 3, 4, 5]
    let testData = (testDeque, testArray)
    
    let result = match testData:
      (deque @ dq, [first, *rest] @ arr) and dq.len > 0 :
        "Deque-Array match: dq_len=" & $dq.len & ", first=" & $first & ", rest_len=" & $rest.len
      (deque @ dq, [first, *rest] @ arr) :
        "Deque-Array basic: dq_len=" & $dq.len & ", first=" & $first
      _ : "no match"
    
    check result == "Deque-Array match: dq_len=2, first=1, rest_len=4"
  
  test "Deque + array @ pattern - Empty deque":
    # Test case where deque is empty (guard should fail)
    let testDeque = initDeque[int]()  # empty deque
    let testArray = [1, 2, 3]
    let testData = (testDeque, testArray)
    
    let result = match testData:
      (deque @ dq, [first, *rest] @ arr) and dq.len > 0 :
        "Should not match - empty deque"
      (deque @ dq, [first, *rest] @ arr) :
        "Deque-Array basic: dq_len=" & $dq.len & ", first=" & $first
      _ : "no match"
    
    check result == "Deque-Array basic: dq_len=0, first=1"
  
  test "Complex mixed collection @ patterns":
    # Test multiple different collection types in one tuple
    let testTable = {"a": 1, "b": 2}.toTable
    let testSet = toHashSet(["x", "y"])
    let testSeq = @[10, 20, 30]
    let testData = (testTable, testSet, testSeq)
    
    let result = match testData:
      ({"a": a, "b": b} @ table, {"x", "y"} @ strSet, [x, y, z] @ sequence) :
        "Complex match: a=" & $a & ", b=" & $b & ", set_size=" & $strSet.len & ", seq=(" & $x & "," & $y & "," & $z & ")"
      _ : "no match"
    
    check result == "Complex match: a=1, b=2, set_size=2, seq=(10,20,30)"
  
  test "Nested collection @ patterns in tuples":
    # Test nested collections with @ patterns
    let innerTable = {"inner": "value"}.toTable
    let outerData = (innerTable, ["a", "b"])
    let testData = (outerData, 42)
    
    let result = match testData:
      (({"inner": innerVal} @ innerTab, [x, y] @ arr) @ outerTuple, number) :
        "Nested match: inner=" & innerVal & ", arr=" & $arr & ", number=" & $number & ", tab_size=" & $innerTab.len
      _ : "no match"
    
    check result == "Nested match: inner=value, arr=[\"a\", \"b\"], number=42, tab_size=1"
  
  test "Mixed collection @ patterns with type constraints":
    # Test @ patterns with different collection types and type-based matching
    let testData = ({"key": 42}.toTable, @[1, 2, 3], toHashSet([10, 20]))
    
    let result = match testData:
      (table @ t, sequence @ s, numSet @ ns) and t.len > 0 and s.len >= 3 and ns.len == 2 :
        "Type-constrained match: table=" & $t.len & ", seq=" & $s.len & ", set=" & $ns.len
      (table @ t, sequence @ s, numSet @ ns) :
        "Basic type match: t=" & $t.len & ", s=" & $s.len & ", ns=" & $ns.len
      _ : "no match"
    
    check result == "Type-constrained match: table=1, seq=3, set=2"