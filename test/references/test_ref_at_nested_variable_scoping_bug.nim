import unittest
import ../../pattern_matching

{.push warning[UnusedImport]: off.}
{.push hint[XDeclaredButNotUsed]: off.}

# ============================================================================
# BUG: Variable Scoping in Nested @ Patterns with Ref Types
# ============================================================================
#
# BUG DESCRIPTION:
# When using @ patterns with ref types in nested object destructuring,
# variables extracted from the inner pattern are not properly scoped
# and become "undeclared identifier" errors in the body expression.
# 
# ERROR: "undeclared identifier: 'd'" 
# LOCATION: Nested @ pattern variable binding in ref object patterns
#
# CURRENT STATE:
# - Simple @ patterns work: Node(value: v) @ ref -> v is accessible  
# - BUT BROKEN: Outer(inner: Inner(data: d) @ innerRef) -> d is not accessible
#
# EXPECTED BEHAVIOR:
# All variables extracted from patterns in @ expressions should be 
# available in the body, regardless of nesting depth or ref types.
#
# IMPACT:
# Complex nested @ patterns with ref types fail compilation, limiting
# the expressiveness of pattern matching for object destructuring.

suite "Ref @ Pattern Nested Variable Scoping Bug":

  test "BUG: Nested @ pattern variables not scoped correctly":
    type 
      Inner = ref object
        data: string
      Outer = ref object
        inner: Inner
    
    let obj = Outer(inner: Inner(data: "test"))
    
    # This should work but currently fails with "undeclared identifier: d"
    let result = match obj:
      Outer(inner: Inner(data: d) @ innerRef): 
        "found data: " & d  # Variable 'd' should be accessible here
      _: "no match"
    
    check result == "found data: test"

  test "Control: Simple @ pattern works fine":
    type Node = ref object
      value: int
    
    let node = Node(value: 42)
    
    # This works - simple @ pattern variable scoping
    let result = match node:
      Node(value: v) @ nodeRef: "value: " & $v
      _: "no match"
    
    check result == "value: 42"

  test "BUG: Multiple nested variables in @ pattern":
    type
      Data = ref object
        x: int
        y: string
      Container = ref object
        data: Data
        label: string
    
    let container = Container(
      data: Data(x: 10, y: "hello"),
      label: "main"
    )
    
    # Both 'x', 'y', and 'label' should be accessible
    let result = match container:
      Container(data: Data(x: x, y: y) @ dataRef, label: label) @ containerRef:
        "x: " & $x & ", y: " & y & ", label: " & label
      _: "no match"
    
    check result == "x: 10, y: hello, label: main"

  test "Control: Non-ref nested patterns work":
    type
      Inner = object  # Not ref
        data: string
      Outer = object  # Not ref  
        inner: Inner
    
    let obj = Outer(inner: Inner(data: "direct"))
    
    # Test if the issue is ref-specific
    let result = match obj:
      Outer(inner: Inner(data: d)): "data: " & d
      _: "no match"
    
    check result == "data: direct"