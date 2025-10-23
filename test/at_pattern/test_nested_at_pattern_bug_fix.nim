import unittest, strutils, options
import ../../pattern_matching

# ============================================================================
# BUG FIX: Nested @ Pattern Support Added  
# ============================================================================
# 
# **BUGS FIXED**:
# 1. Object constructor field @ patterns now work correctly
# 2. Call patterns in @ patterns now work correctly
# 
# **PREVIOUSLY FAILING**:
# 1. "Unsupported nested pattern in object constructor field: nnkInfix"
# 2. "Unsupported subpattern in @: nnkCall" 
# 
# **NOW WORKING**:
# 1. ComplexObj(nested: NestedObj(field: value) @ var): ...
# 2. Some(Some(value @ val)) @ outerOption: ...
# 
# **LOCATIONS**: 
# 1. Added nnkInfix case in object constructor field processing at line 10884
# 2. Added nnkCall case in main @ pattern processing at line 7247
#
# **IMPLEMENTATION**:
# 1. Object field @ patterns delegate to processNestedPattern for full support
# 2. Call @ patterns delegate to processNestedPattern for recursive handling
# 3. Both fixes provide complete pattern matching with proper variable binding
#
# **PERFORMANCE**: Zero runtime overhead - all patterns resolved at compile time
# **COMPATIBILITY**: No breaking changes to existing functionality
#
# ============================================================================

type
  NestedData = object
    level: int
    value: string
    
  ComplexObj = object
    id: int
    nested: NestedData
    items: seq[int]

suite "Nested @ Pattern Bug Fix Tests":
  
  test "BUG FIX 1: Object constructor field @ patterns now work":
    # This pattern was failing before the fix
    let data = ComplexObj(
      id: 123,
      nested: NestedData(level: 5, value: "test"),
      items: @[1, 2, 3]
    )
    
    # Test the previously failing nested @ pattern
    let result = match data:
      ComplexObj(id: 123, nested: NestedData(level: 5, value: val) @ nestedRef):
        "nested level: " & $nestedRef.level & ", value: " & val
      _: "no match"
    
    check result.contains("nested level: 5")
    check result.contains("value: test")
  
  test "BUG FIX 1: Compilation check for object field @ patterns":
    let data = ComplexObj(
      id: 456,
      nested: NestedData(level: 10, value: "working"),
      items: @[4, 5, 6]
    )
    
    # Verify this pattern now compiles successfully
    let compilesTest = compiles:
      match data:
        ComplexObj(id: 456, nested: NestedData(level: 10) @ captured): 
          "captured: " & $captured.value
        _: "no match"
    
    check compilesTest == true
  
  test "BUG FIX 2: Call patterns in @ patterns now work":
    # This pattern was failing before the fix
    let nested = some(some(42))
    
    # Test the previously failing call @ pattern  
    let result = match nested:
      Some(Some(value @ val)) @ outerOption:
        "value: " & $val & ", outer has value: " & $outerOption.isSome
      _: "no match"
    
    check result == "value: 42, outer has value: true"
  
  test "BUG FIX 2: Compilation check for call @ patterns":
    let testData = some("hello")
    
    # Verify this pattern now compiles successfully
    let compilesTest = compiles:
      match testData:
        Some(content @ captured) @ fullOption:
          "content: " & captured & ", full: " & $fullOption.isSome
        _: "no match"
    
    check compilesTest == true
  
  test "Combined nested @ patterns work correctly":
    type
      Container = object
        data: Option[ComplexObj]
    
    let container = Container(
      data: some(ComplexObj(
        id: 999,
        nested: NestedData(level: 3, value: "deep"),
        items: @[7, 8, 9]
      ))
    )
    
    # Test deeply nested @ patterns combining both fixes
    let result = match container:
      Container(data: Some(ComplexObj(id: 999, nested: data @ nestedData) @ obj) @ option):
        "found nested data level: " & $nestedData.level & " in object id: " & $obj.id
      _: "no match"
    
    check result.contains("found nested data level: 3")
    check result.contains("in object id: 999")
  
  test "Edge case: Simple sequence @ patterns":
    let sequence = @[1, 2, 3]
    
    # Test basic sequence @ patterns  
    let result = match sequence:
      [1, 2, 3] @ fullSeq:
        "matched sequence length: " & $fullSeq.len
      _: "no match"
    
    check result.contains("matched sequence length: 3")
  
  test "Regression check: Basic @ patterns still work":
    let data = 42
    
    # Ensure basic @ patterns weren't broken by the fix
    let result = match data:
      42 @ num: "number: " & $num
      _ @ any: "other: " & $any
    
    check result == "number: 42"
  
  test "Regression check: Simple object patterns still work":
    let person = ComplexObj(
      id: 1,
      nested: NestedData(level: 0, value: "simple"),
      items: @[]
    )
    
    # Ensure simple object patterns weren't broken
    let result = match person:
      ComplexObj(id: 1) @ obj: "found id 1, nested value: " & obj.nested.value
      _: "no match"
    
    check result == "found id 1, nested value: simple"