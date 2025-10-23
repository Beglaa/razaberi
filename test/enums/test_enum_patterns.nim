import unittest
import tables
import options
import ../../pattern_matching

suite "Enum OR Pattern Tests":
  # Tests for OR patterns with enum types
  
  test "should support OR patterns for enums":
    type Color = enum
      red, green, blue, yellow
    
    let color = red
    let result = match color:
      red | green : "warm"
      blue | yellow : "cool"
      _ : "unknown"
    
    check(result == "warm")

  test "should handle OR patterns with guards":
    type Status = enum
      active, inactive, pending, archived
    
    let status = pending
    let result = match status:
      (active | inactive) and status == active : "running"
      pending | archived : "waiting"
      _ : "other"
    
    check(result == "waiting")