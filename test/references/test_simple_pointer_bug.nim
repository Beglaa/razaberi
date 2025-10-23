import unittest
import ../../pattern_matching

{.push warning[UnusedImport]: off.}
{.push hint[XDeclaredButNotUsed]: off.}

# ============================================================================
# BUG: Pattern Matching Fails with Pointer Types (nnkPtrTy)
# ============================================================================
#
# BUG DESCRIPTION: 
# Pattern matching macro encounters "Invalid node kind nnkPtrTy" error
# when processing pointer type patterns, indicating missing nnkPtrTy handling
#
# IMPACT: Pattern matching with any pointer types fails compilation
# SOLUTION NEEDED: Add nnkPtrTy case to pattern matching macro

suite "Simple Pointer Pattern Bug":

  test "BUG: Basic nil pointer pattern fails":
    # This should work but causes compilation error
    let nilPtr: ptr int = nil
    
    let result = match nilPtr:
      nil: "got nil"
      _: "not nil"
    
    check result == "got nil"

  test "Baseline: Reference types work for comparison":
    # Control test - ref types should work
    let nilRef: ref int = nil
    
    let result = match nilRef:
      nil: "got nil ref"
      _: "not nil ref"
    
    check result == "got nil ref"