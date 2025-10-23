import unittest
import std/options
import ../../pattern_matching

# CRITICAL BUG: Option template safety inconsistency
# 
# BUG DESCRIPTION: 
# optionGet template (lines 32-37) lacks nil safety check that optionIsSome/optionIsNone have
# 
# Current templates:
# - optionIsSome: checks `x != nil` before `x[].isSome` (SAFE)
# - optionIsNone: checks `x != nil` before `x[].isNone` (SAFE) 
# - optionGet: directly calls `x[].get` without nil check (UNSAFE!)
#
# This creates a safety hole where optionGet can segfault on nil refs

suite "CRITICAL BUG: Option template safety inconsistency":
  
  test "optionGet template lacks nil safety check":
    # Create nil ref to expose the safety inconsistency
    var nilRefOption: ref Option[int] = nil
    
    # These work because they have nil checks:
    check optionIsSome(nilRefOption) == false  # Safe: checks x != nil first
    check optionIsNone(nilRefOption) == false  # Safe: checks x != nil first
    
    # After fix: optionGet now safely handles nil refs
    expect(FieldDefect):
      discard optionGet(nilRefOption)  # Now safe: raises FieldDefect instead of segfault
    
    # The bug is now fixed - optionGet matches safety pattern of other Option helpers
    discard "FIXED: optionGet template now has consistent nil safety"
    
  test "pattern matching bypasses direct optionGet crash but shows inconsistency":
    # Pattern matching uses the templates internally but doesn't directly expose the crash
    var nilRefOption: ref Option[int] = nil
    
    # The pattern matching should handle this gracefully
    let result = match nilRefOption:
      Some(x): x
      _: -1
      
    # This works because optionIsSome returns false for nil ref, 
    # so Some(x) pattern fails and wildcard matches
    check result == -1
    
    # But the inconsistency exists in the template definitions
    # optionGet should have the same nil safety as optionIsSome/optionIsNone