import unittest
import ../../pattern_matching

{.push warning[UnusedImport]: off.}
{.push hint[XDeclaredButNotUsed]: off.}

# ============================================================================
# BUG: Pattern Matching Missing Support for Pointer Types (nnkPtrTy)
# ============================================================================
#
# BUG DESCRIPTION: 
# Pattern matching library handles ref types (nnkRefTy) but completely lacks
# support for ptr types (nnkPtrTy). The main pattern processing case statement
# at pattern_matching.nim:11881-11887 has no "of nnkPtrTy:" case handler.
#
# CURRENT STATE:
# - nnkRefTy: ✅ Handled with nil checks and nested pattern processing
# - nnkPtrTy: ❌ Missing - falls through to error case
#
# EXPECTED BEHAVIOR:
# Pointer patterns should work similar to ref patterns:
# - Basic nil check: ptr int -> scrutinee != nil
# - Type safety: pointer dereferencing with proper bounds checking
# - Nested patterns: ptr (Type(field: value)) -> recursive processing
#
# IMPACT: Any pattern matching on ptr types fails with "Invalid node kind" error
# SOLUTION NEEDED: Add nnkPtrTy case to main pattern processing switch statement

suite "Pointer Type Pattern Bug - Missing nnkPtrTy Support":

  test "BUG: Basic pointer nil pattern fails - no nnkPtrTy handler":
    # This should work but causes compilation error due to missing nnkPtrTy case
    let nilPtr: ptr int = nil
    
    # This should compile and work, but will fail due to missing nnkPtrTy support
    let result = match nilPtr:
      nil: "got nil pointer"
      _: "not nil pointer"
    
    check result == "got nil pointer"
  
  test "BUG: Non-nil pointer pattern fails - no nnkPtrTy handler":
    var value: int = 42
    let valuePtr: ptr int = addr(value)
    
    # This should work but will fail due to missing nnkPtrTy support
    let result = match valuePtr:
      nil: "nil"
      _: "not nil"
    
    check result == "not nil"

  test "BUG: Pointer type with object pattern fails - no nnkPtrTy handler":
    type TestObj = object
      value: int
      name: string
    
    var obj = TestObj(value: 42, name: "test")
    let objPtr: ptr TestObj = addr(obj)
    
    # This complex pointer pattern should work but will fail
    let result = match objPtr:
      nil: "nil object"
      _: "has object"
    
    check result == "has object"

  test "Control: ref types work (showing the difference)":
    # Control test showing that ref types work fine
    let nilRef: ref int = nil
    let result = match nilRef:
      nil: "got nil ref"
      _: "not nil ref"
    check result == "got nil ref"

  test "BUG: Dereferenced pointer value pattern fails - no nnkPtrTy handler":
    var value: int = 100
    let valuePtr: ptr int = addr(value)
    
    # This should ideally work: match the dereferenced value
    let result = match valuePtr[]:  # Dereference the pointer
      100: "found 100"
      _: "other value"
    
    check result == "found 100"

  test "BUG: Pointer comparison patterns fail - no nnkPtrTy handler":
    var value1: int = 42
    var value2: int = 84
    let ptr1: ptr int = addr(value1)
    let ptr2: ptr int = addr(value2)
    
    # This should work - comparing pointer values
    let result = match ptr1:
      nil: "nil pointer"
      _: "some pointer"
    
    check result == "some pointer"