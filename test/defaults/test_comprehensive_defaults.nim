import unittest
import ../../pattern_matching
import std/tables

suite "Comprehensive Default Patterns":

  test "Basic sequence default":
    # Basic sequence default
    let coords1 = @[10, 20]
    let result1 = match coords1:
      [x, y, z = 0] : $x & "," & $y & "," & $z
      _ : "no match"
    
    check result1 == "10,20,0"
  
  test "Multiple sequence defaults":
    # Multiple defaults
    let coords2 = @[5]
    let result2 = match coords2:
      [x, y = 10, z = 15] : $x & "," & $y & "," & $z
      _ : "no match"
    
    check result2 == "5,10,15"
  
  test "Defaults ignored when elements present":
    # All elements present (no defaults used)
    let coords3 = @[1, 2, 3]
    let result3 = match coords3:
      [x, y, z = 99] : $x & "," & $y & "," & $z
      _ : "no match"
    
    check result3 == "1,2,3"

  test "Table defaults with consistent = syntax":
    # Use consistent = syntax for table defaults (same as sequences)
    let config = {"debug": "true", "timeout": "30"}.toTable
    let result = match config:
      {"debug": (debug = "false"), "timeout": (timeout = "60"), "ssl": (ssl = "disabled")} : 
        "Config: debug=" & debug & ", timeout=" & timeout & ", ssl=" & ssl
      _ : "no match"
    
    check result == "Config: debug=true, timeout=30, ssl=disabled"

  test "Literal with defaults":
    # Sequence with literal matching and defaults
    let data1 = @[1]
    let result1 = match data1:
      [1, extra = 42] : "One with extra: " & $extra
      [x, y = 100] : "Other: " & $x & "," & $y
      _ : "no match"
    
    check result1 == "One with extra: 42"
  
  test "All defaults with empty sequence":
    # Empty sequence with all defaults
    let empty: seq[int] = @[]
    let result2 = match empty:
      [x = 1, y = 2, z = 3] : $x & "," & $y & "," & $z
      _ : "no match"
    
    check result2 == "1,2,3"

  test "Longer sequence with defaults":
    # Sequence longer than pattern with defaults
    let numbers = @[1, 2, 3, 4, 5]
    let result = match numbers:
      [x, y = 99] : "First two: " & $x & "," & $y
      _ : "no match"
    
    check result == "First two: 1,2"

