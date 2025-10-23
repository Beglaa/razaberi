import unittest
import std/strutils
import ../../pattern_matching

{.push warning[UnusedImport]: off.}
{.push hint[XDeclaredButNotUsed]: off.}

# ============================================================================
# BASIC NIL @ PATTERN BUG TEST - Focus on core functionality
# ============================================================================

suite "Basic Nil @ Pattern Bug Tests":

  test "CORE: Basic nil @ variable pattern works":
    # The main bug fix - basic nil @ pattern
    
    type OptionalInt = ref int
    let value: OptionalInt = nil
    
    # This should work after the fix
    let result = match value:
      nil @ capturedNil: "nil captured"
      _ @ nonNil: "non-nil value"
    
    check result == "nil captured"

  test "CORE: nil @ variable captures the value correctly":
    # Test that the captured variable actually contains nil
    
    let value: ref string = nil
    var captured: ref string
    
    let result = match value:
      nil @ cap: 
        captured = cap
        "captured nil"
      _: "not nil"
    
    check result == "captured nil"
    check captured == nil

  test "CORE: nil @ works with different ref types":
    # Test nil @ with various reference types
    
    let intRef: ref int = nil
    let strRef: ref string = nil
    
    let intResult = match intRef:
      nil @ cap: "int nil captured"
      _: "int not nil"
      
    let strResult = match strRef:
      nil @ cap: "str nil captured" 
      _: "str not nil"
    
    check intResult == "int nil captured"
    check strResult == "str nil captured"

  test "BASELINE: Regular nil patterns work (control)":
    # Control test - regular nil patterns should work
    
    let value: ref int = nil
    
    let result = match value:
      nil: "nil matched"
      _: "not nil"
    
    check result == "nil matched"

  test "BASELINE: Other @ patterns work (control)":
    # Control test - other @ patterns should work
    
    let value = 42
    
    let result = match value:
      42 @ captured: "captured: " & $captured
      _ @ other: "other: " & $other
    
    check result == "captured: 42"