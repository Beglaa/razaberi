import unittest
import ../../pattern_matching

# ============================================================================
# ENUM SET TYPE MISMATCH BUG - CRITICAL COMPILATION ERROR
# ============================================================================
# BUG DESCRIPTION:
# When matching a single enum value against a set pattern, the pattern matching
# macro generates invalid code that tries to compare `enum` with `set[enum]`
# using `==` instead of the correct `in` operator.
#
# ERROR: "type mismatch: Expression: value == {EnumA, EnumB, EnumC}"
# LOCATION: Generated code in pattern matching macro
# ROOT CAUSE: Set patterns assume the scrutinee is a set, but when scrutinee
#             is a single enum value, comparison should use `in` not `==`
# 
# IMPACT: CRITICAL - Pattern matching fails to compile when matching single
#         enum values against set patterns
#
# This test should FAIL to compile until the bug is fixed.

suite "Enum Set Type Mismatch Bug - CRITICAL COMPILATION ERROR":

  type Status = enum
    Active, Pending, Inactive

  test "BUG: Single enum value matched against set pattern fails compilation":
    # This should compile but currently fails with type mismatch error
    let status = Active
    
    # SHOULD WORK: Check if single enum value is in the set
    # ACTUALLY: Generates `status == {Active, Pending}` which is invalid
    let result = match status:
      {Active, Pending}:     # Set pattern
        "operational"
      {Inactive}:            # Set pattern
        "down"
      _:
        "unknown"
    
    check result == "operational"

  test "BUG: Single enum value with complex set patterns":
    # More comprehensive test of the bug
    type Priority = enum
      Low = 1, Medium = 2, High = 3, Critical = 4
    
    let currentPriority = High
    
    # All these set patterns should work but fail due to type mismatch
    let result = match currentPriority:
      {Low, Medium}:          # Low priority group
        "routine"
      {High, Critical}:       # High priority group  
        "urgent"
      _:
        "unknown"
    
    check result == "urgent"

  test "BUG: Mixed single values and set patterns":
    # Test mixing single value patterns with set patterns
    type Color = enum
      Red, Green, Blue, Yellow
    
    let color = Red
    
    let result = match color:
      Red:                    # Single value pattern (should work)
        "primary_red"
      {Green, Blue}:          # Set pattern (fails due to bug)
        "cool_colors"
      {Yellow}:               # Single-element set pattern (fails due to bug)
        "warm_yellow"
      _:
        "other"
    
    check result == "primary_red"

# DEMONSTRATION: What the generated code should look like
# 
# Instead of:
#   if status == {Active, Pending}: ...
# 
# Should generate:
#   if status in {Active, Pending}: ...
# 
# OR handle single-element sets as direct comparison:
#   if status == Active or status == Pending: ...

# ============================================================================
# WORKLOG ENTRY FOR BUG
# ============================================================================
# ## Enum Set Type Mismatch Bug - Code Generation Error
# **Timestamp:** 2025-08-26
# **Issue:** Pattern matching generates invalid comparisons when matching single
#            enum values against set patterns, using `==` instead of `in`
# **Location:** Set pattern code generation in pattern matching macro
# **Error:** "type mismatch: Expression: value == {EnumA, EnumB, EnumC}"  
# **Root Cause:** Set pattern logic assumes scrutinee is a set type, but when
#                 scrutinee is single enum value, needs `in` operator
# **Impact:** CRITICAL - Compilation failure for enum vs set pattern matching
# **Test File:** test_enum_set_type_mismatch_bug.nim  
# **Status:** Discovered - needs code generation fix for enum/set type compatibility