import unittest
include ../../pattern_matching

# BUG DISCOVERED: "Unsupported infix operator in nested pattern: and"
# This bug occurs when using @ patterns with guards in deeply nested object constructors
# The error occurs in the processNestedPattern function when handling infix operators in nested contexts

type
  Inner = object
    value: int
    name: string
  
  Middle = object
    inner: Inner
    count: int
  
  Outer = object
    middle: Middle
    id: string

suite "BUG: Nested @ Pattern with Guards - Missing nnkInfix Support":
  
  test "@ pattern with 'and' guard in nested object constructor - FAILS with nnkInfix error":
    let data = Outer(
      middle: Middle(
        inner: Inner(value: 42, name: "test"),
        count: 3
      ),
      id: "outer1"
    )
    
    # This pattern should work but currently fails with "Unsupported infix operator in nested pattern: and"
    # The bug is that @ patterns with guards are not properly handled in nested object constructors
    let result = match data:
      Outer(
        middle: Middle(
          inner: Inner(value: v, name: n) @ inner_obj and inner_obj.value > 40,
          count: c
        )
      ):
        (v, n, c, inner_obj.value)
      _:
        (0, "", 0, 0)
    
    # Expected: should extract values and verify the guard condition
    check result == (42, "test", 3, 42)
  
  test "minimal reproduction of the @ pattern guard bug":
    let data = Outer(
      middle: Middle(
        inner: Inner(value: 100, name: "minimal"),
        count: 1
      ),
      id: "test"
    )
    
    # Minimal case that triggers the bug: @ pattern with 'and' guard in nested context
    let result = match data:
      Outer(middle: Middle(inner: Inner(value: val, name: nm) @ obj and obj.value == 100)):
        (val, nm, obj.value)
      _:
        (0, "", 0)
    
    check result == (100, "minimal", 100)
  
  test "@ pattern guard in single-level object constructor - control test":
    let inner = Inner(value: 50, name: "control")
    
    # This should work fine (single level, no nesting)
    let result = match inner:
      Inner(value: v, name: n) @ obj and obj.value > 25:
        (v, n, obj.value)
      _:
        (0, "", 0)
    
    check result == (50, "control", 50)
  
  test "@ pattern without guard in nested object constructor - control test":
    let data = Outer(
      middle: Middle(
        inner: Inner(value: 75, name: "no_guard"),
        count: 2
      ),
      id: "test2"
    )
    
    # This should work (no guard, just @ pattern)
    let result = match data:
      Outer(middle: Middle(inner: Inner(value: val, name: nm) @ obj)):
        (val, nm, obj.value)
      _:
        (0, "", 0)
    
    check result == (75, "no_guard", 75)