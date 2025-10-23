import unittest
import ../../pattern_matching
import std/tables

suite "Dual Syntax Default Patterns":
  
  test "sequence defaults: both syntaxes work":
    let coords = @[10, 20]
    
    # Traditional syntax
    let result1 = match coords:
      [x, y, z = 0] : "Traditional: (" & $x & ", " & $y & ", " & $z & ")"
      _ : "No match"
    
    # Parentheses syntax (consistent with tables)
    let result2 = match coords:
      [x, y, (z = 0)] : "Parentheses: (" & $x & ", " & $y & ", " & $z & ")"
      _ : "No match"
    
    check result1 == "Traditional: (10, 20, 0)"
    check result2 == "Parentheses: (10, 20, 0)"
  
  test "mixed syntax in same pattern":
    let data = @[1, 2]
    let result = match data:
      [a, b = 5, (c = 10), d = 15] : $a & "," & $b & "," & $c & "," & $d
      _ : "No match"
    
    check result == "1,2,10,15"
  
  test "empty sequence with both syntaxes":
    let empty: seq[int] = @[]
    
    # All traditional syntax
    let result1 = match empty:
      [x = 1, y = 2, z = 3] : "Traditional: " & $x & "," & $y & "," & $z
      _ : "No match"
    
    # All parentheses syntax
    let result2 = match empty:
      [(x = 1), (y = 2), (z = 3)] : "Parentheses: " & $x & "," & $y & "," & $z
      _ : "No match"
    
    # Mixed syntax
    let result3 = match empty:
      [x = 1, (y = 2), z = 3] : "Mixed: " & $x & "," & $y & "," & $z
      _ : "No match"
    
    check result1 == "Traditional: 1,2,3"
    check result2 == "Parentheses: 1,2,3"
    check result3 == "Mixed: 1,2,3"

  test "parentheses syntax with guards":
    let values = @[5]
    let result = match values:
      [(x = 1), (y = 10)] and x > 3 :
        "Guard passed: " & $x & ", " & $y
      [(x = 1), (y = 20)] :
        "Guard failed: " & $x & ", " & $y  
      _ : "No match"
    
    check result == "Guard passed: 5, 10"

  test "table vs sequence syntax consistency":
    let coords = @[10, 20]
    let config = {"host": "localhost"}.toTable
    
    # Both use (value = default) syntax consistently!
    let seqResult = match coords:
      [x, y, (z = 0)] : "Seq: " & $x & "," & $y & "," & $z
      _ : "No match"
    
    let tableResult = match config:
      {"host": (host = "127.0.0.1"), "port": (port = "8080")} : 
        "Table: " & host & ":" & port
      _ : "No match"
    
    check seqResult == "Seq: 10,20,0"
    check tableResult == "Table: localhost:8080"

  test "complex mixed pattern with both syntaxes":
    let complex = @[1]
    let result = match complex:
      [first, second = 2, (third = 3), fourth = 4, (fifth = 5)] :
        "Complex: " & $first & "-" & $second & "-" & $third & "-" & $fourth & "-" & $fifth
      _ : "No match"
    
    check result == "Complex: 1-2-3-4-5"

  test "spread patterns with defaults":
    let nums = @[1, 2]
    let result = match nums:
      [first, *middle, (last = 99)] : 
        "First: " & $first & ", Middle: " & $middle.len & ", Last: " & $last
      _ : "No match"
    
    check result == "First: 1, Middle: 0, Last: 2"

  test "literal matching with parentheses defaults":
    let data = @[42, 10]
    let result = match data:
      [42, second, (third = 100)] : 
        "Matched 42 with " & $second & " and " & $third
      _ : "No match"
    
    check result == "Matched 42 with 10 and 100"