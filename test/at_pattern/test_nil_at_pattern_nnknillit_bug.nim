import unittest
import std/strutils
import ../../pattern_matching

# BUG REPRODUCTION TEST: Nil @ Pattern Bug - Missing nnkNilLit Support
#
# BUG DESCRIPTION:
# @ patterns with nil literals (nil @ variable) fail to compile with:
# "Error: Unsupported @ sub-pattern in nested tuple: nnkNilLit"
#
# EXPECTED BEHAVIOR:
# The pattern `nil @ capturedNil` should work like other literal @ patterns
# (e.g., `42 @ num`, `"hello" @ str`) and bind the nil value to the variable.
#
# ACTUAL BEHAVIOR:
# Compilation fails because the @ pattern processing code doesn't handle
# nnkNilLit AST nodes in the case statement for supported literal types.
#
# TECHNICAL DETAILS:
# - Bug location: pattern_matching.nim line 5774 in processTupleLayer
# - The @ pattern case statement handles nnkIntLit, nnkStrLit, etc.
# - Missing nnkNilLit case in the @ pattern literal handling
# - This prevents using @ patterns with nil values (common for optionals)

suite "Nil @ Pattern Bug - Missing nnkNilLit Support":
  test "nil @ variable pattern - minimal bug reproduction":
    # This test SHOULD PASS but currently FAILS due to the nnkNilLit bug
    # BUG: `nil @ capturedNil` fails because nnkNilLit is not handled in @ patterns
    
    let value: ref int = nil
    
    # BUG REPRODUCTION: This fails with "Unsupported @ sub-pattern in nested tuple: nnkNilLit"
    # The `nil @ capturedNil` pattern should work like other literal @ patterns
    let result = match value:
      nil @ capturedNil: "nil value captured"
      _ @ nonNil: "non-nil value"
    
    # Expected: Should match nil and return "nil value captured"
    check result == "nil value captured"

  test "nil @ in tuple patterns - compound bug case":
    # Test nil @ patterns in tuple contexts (where the error actually occurs)
    let values = (cast[ref int](nil), 42)
    
    # BUG: This also fails due to the same nnkNilLit issue in tuple processing
    let result = match values:
      (nil @ first, _ @ second): "first is nil, second is " & $second
      _: "no match"
    
    # Expected: Should match and return "first is nil, second is 42"
    check result == "first is nil, second is 42"

  test "nil @ in sequence patterns - sequence context bug":
    # Test nil @ patterns in sequence contexts
    let sequence = @[cast[ref int](nil)]
    
    # BUG: Sequence patterns with nil @ should also work
    let result = match sequence:
      [nil @ nullRef]: "sequence contains nil: " & $nullRef.repr
      _: "no nil found"
    
    # Expected: Should match and capture the nil value
    check result.startsWith("sequence contains nil:")

  # CONTROL TESTS: Verify other patterns work correctly
  test "nil literal without @ works (control test)":
    # Control test: nil patterns without @ should work fine
    let value: ref int = nil
    
    let result = match value:
      nil: "nil matched"
      _: "nil not matched"
    
    check result == "nil matched"
    
  test "other @ patterns work (control test)":
    # Control test: other literal @ patterns should work fine
    let value = 42
    
    let result = match value:
      42 @ captured: "captured: " & $captured
      _: "no match"
    
    check result == "captured: 42"