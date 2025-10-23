import unittest
import ../../pattern_matching

suite "Simple Default Patterns Tests":
  
  test "sequence defaults":
    let coords = @[10, 20]
    let result = match coords:
      [x, y, z = 0] : "Position: (" & $x & ", " & $y & ", " & $z & ")"
      _ : "No match"
    
    check result == "Position: (10, 20, 0)"