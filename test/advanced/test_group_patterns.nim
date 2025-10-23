import unittest
import tables
import options
import ../../pattern_matching

suite "Group Pattern Tests":
  test "should handle simple parentheses grouping":
    let result1 = match "N":
      ("N" | "S") : "Vertical"
      ("W" | "E") : "Horizontal"
      _ : "Unknown"
    check(result1 == "Vertical")

  test "should handle nested OR grouping with @":
    let result1 = match "N":
      ("N" | "S") | ("W" | "E") @ hemisphere : "Direction: " & hemisphere
      _ : "Unknown"
    check(result1 == "Direction: N")
    
    let result2 = match 42:
      ((1 | 2) | (40 | 41 | 42)) @ num : "Found: " & $num
      _ : "Not found"
    check(result2 == "Found: 42")

  test "should handle complex nested grouping":
    let result1 = match 1:
      ((1 | 2) | (3 | 4)) : "Group 1"
      ((5 | 6) | (7 | 8)) : "Group 2"
      _ : "Other"
    check(result1 == "Group 1")
    
    let result2 = match 6:
      ((1 | 2) | (3 | 4)) : "Group 1"
      ((5 | 6) | (7 | 8)) : "Group 2"
      _ : "Other"
    check(result2 == "Group 2")

  test "should handle grouped patterns with literals":
    let result1 = match 100:
      (42) : "Specific number"
      (100) @ num : "Century: " & $num
      _ : "Other"
    check(result1 == "Century: 100")