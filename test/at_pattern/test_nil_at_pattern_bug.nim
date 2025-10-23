import unittest
import std/strutils
import std/tables
import ../../pattern_matching

{.push warning[UnusedImport]: off.}
{.push hint[XDeclaredButNotUsed]: off.}

# ============================================================================
# CRITICAL BUG: nil @ variable patterns fail to compile
# ============================================================================
#
# BUG DESCRIPTION:
# @ patterns with nil literals (nil @ variable) cause compilation failures.
# The @ pattern processing code handles all literal types (nnkIntLit, nnkStrLit, etc.)
# but missing nnkNilLit case in the @ pattern handler around line 3789.
#
# ERROR: "Unsupported @ sub-pattern" or similar compilation error
# LOCATION: @ pattern processing in pattern_matching.nim around line 3789
# IMPACT: HIGH - nil @ patterns are common for optional values and nullable references
# ROOT CAUSE: Missing nnkNilLit case in @ pattern literal handling
# SOLUTION: Add nnkNilLit to the @ pattern literal case statement

suite "Nil @ Pattern Bug - Missing nnkNilLit in @ patterns":

  test "BUG: Basic nil @ variable pattern should work":
    # Test basic nil @ pattern binding

    type OptionalInt = ref int
    let value: OptionalInt = nil

    let result = match value:
      nil @ capturedNil: "nil value captured as: " & $capturedNil.repr
      _ @ nonNil: "non-nil value: " & $nonNil.repr

    check result.startsWith("nil value captured")

  test "BUG: nil @ variable in OR patterns should work":
    # Test nil @ in actual OR pattern combinations

    let value: ref string = nil

    # Test with OR pattern: nil @ x matches nil and binds to x
    let result = match value:
      (nil @ nullRef) | (_ @ nullRef):
        # Both alternatives should bind to nullRef
        if nullRef == nil:
          "nil matched via OR: " & $nullRef.repr
        else:
          "non-nil matched via OR"
      _: "no match"

    check result.contains("nil matched via OR")

    # Test 2: nil in second alternative of OR
    var value2: ref int
    new(value2)
    value2[] = 42

    let result2 = match value2:
      (nil @ val) | (_ @ val):
        if val == nil:
          "got nil"
        else:
          "got non-nil: " & $val[]
      _: "no match"

    check result2 == "got non-nil: 42"

  test "BUG: nil @ variable in nested object patterns should work":
    # Test nil @ in object destructuring with @ binding

    type LinkedNode = ref object
      value: int
      next: LinkedNode

    let node = LinkedNode(value: 42, next: nil)

    # Test with nil @ in nested position
    let result = match node:
      LinkedNode(value: val, next: nil @ nextNode):
        "Node with value " & $val & " and nil next captured: " & $nextNode.repr
      LinkedNode(value: val, next: _ @ nextNode):
        "Node with value " & $val & " and some next"
      _: "no match"

    check result.contains("Node with value 42 and nil next captured")
    check result.contains("nil")

    # Test 2: Verify binding works correctly
    let nilCheck = match node:
      LinkedNode(next: nil @ n):
        n == nil  # Should be true
      _:
        false
    check nilCheck == true

  test "BUG: nil @ variable with simple guards should work":
    # Test nil @ patterns with actual guard conditions

    type Container = object
      data: ref int
      flag: bool

    let cont1 = Container(data: nil, flag: true)

    # Test with guard: nil @ captured AND guard condition
    let result = match cont1:
      Container(data: nil @ captured, flag: true):
        "nil data with true flag: " & $captured.repr
      Container(data: nil @ captured, flag: false):
        "nil data with false flag: " & $captured.repr
      _: "no match"

    check result.contains("nil data with true flag")

    # Test 2: Guard with explicit condition check
    let value: ref int = nil
    let result2 = match value:
      nil @ v:
        # Use the captured nil in a condition
        if v == nil:
          "captured nil correctly"
        else:
          "should not happen"
      _: "no match"

    check result2 == "captured nil correctly"

  test "BUG: multiple nil @ patterns should work":
    # Test multiple nil @ bindings in tuple/sequence patterns

    let values = (cast[ref int](nil), cast[ref string](nil), cast[ref bool](nil))

    let result = match values:
      (nil @ first, nil @ second, nil @ third):
        "All nil: " & $first.repr & ", " & $second.repr & ", " & $third.repr
      _: "not all nil"

    check result.startsWith("All nil:")
    check result.contains("nil")

    # Test 2: Verify all bindings are actually nil
    let allNilCheck = match values:
      (nil @ a, nil @ b, nil @ c):
        a == nil and b == nil and c == nil
      _:
        false
    check allNilCheck == true

  test "BUG: nil @ in sequence patterns should work":
    # Test nil @ in sequence destructuring

    let sequence = @[cast[ref int](nil), cast[ref int](nil)]

    let result = match sequence:
      [nil @ first, nil @ second]:
        # Verify both are captured and nil
        if first == nil and second == nil:
          "Both elements nil"
        else:
          "error in capture"
      [nil @ onlyFirst, _]: "First nil, second not"
      [_, nil @ onlySecond]: "Second nil, first not"
      _: "neither nil or different pattern"

    check result == "Both elements nil"

    # Test 2: Mixed nil and non-nil
    var seq2 = @[cast[ref int](nil), cast[ref int](nil)]
    new(seq2[1])
    seq2[1][] = 99

    let result2 = match seq2:
      [nil @ first, nil @ second]: "both nil"
      [nil @ first, _ @ second]:
        "first nil: " & $first.repr & ", second: " & $second[]
      _: "other"

    check result2.contains("first nil")
    check result2.contains("second: 99")

  test "BUG: nil @ in table patterns should work":
    # Test nil @ in table value patterns

    let config = {"cache": cast[ref string](nil), "db": cast[ref string](nil)}.toTable

    let result = match config:
      {"cache": nil @ cacheRef, "db": nil @ dbRef}:
        # Verify both are captured and nil
        if cacheRef == nil and dbRef == nil:
          "Both nil configs captured"
        else:
          "error in capture"
      _: "different pattern"

    check result == "Both nil configs captured"

    # Test 2: Table with one nil value
    let config2 = {"enabled": cast[ref bool](nil)}.toTable
    let result2 = match config2:
      {"enabled": nil @ flag}:
        "disabled (nil flag): " & $flag.repr
      _: "enabled"

    check result2.contains("disabled")

  test "BUG: grouped nil @ patterns (parentheses) should work":
    # Test nil @ inside parentheses groups

    let value: ref string = nil

    let result = match value:
      (nil @ grouped): "Grouped nil pattern: " & $grouped.repr
      _: "not matched"

    check result.startsWith("Grouped nil pattern")
    check result.contains("nil")

  test "BUG: nil @ in complex nested structures":
    # Test nil @ in deeply nested patterns

    type NestedData = object
      items: seq[ref int]
      config: Table[string, ref string]

    let data = NestedData(
      items: @[cast[ref int](nil), cast[ref int](nil)],
      config: {"key": cast[ref string](nil)}.toTable
    )

    let result = match data:
      NestedData(
        items: [nil @ item1, nil @ item2],
        config: {"key": nil @ confVal}
      ):
        # All three should be captured as nil
        if item1 == nil and item2 == nil and confVal == nil:
          "All nested nils captured correctly"
        else:
          "capture error"
      _: "no match"

    check result == "All nested nils captured correctly"

  test "BUG: nil @ with OR patterns in nested contexts":
    # Test nil @ combined with OR in nested structures

    type Result = object
      data: ref int
      error: ref string

    let res1 = Result(data: nil, error: cast[ref string](nil))

    let msg = match res1:
      Result(data: nil @ d, error: nil @ e):
        "Both nil: data=" & $d.repr & ", error=" & $e.repr
      Result(data: (nil @ d) | (_ @ d), error: _):
        "Data present or nil"
      _: "other"

    check msg.contains("Both nil")

  # BASELINE TESTS: These should work to verify the framework
  test "Baseline: nil literal patterns work (control test)":
    # Control test - nil patterns without @ should work
    let value: ref int = nil

    let result = match value:
      nil: "nil matched"
      _: "nil not matched"

    check result == "nil matched"

  test "Baseline: other @ patterns work (control test)":
    # Control test - other @ patterns should work
    let value = 42

    let result = match value:
      42 @ captured: "captured: " & $captured
      _ @ other: "other: " & $other

    check result == "captured: 42"

  test "Baseline: nil without @ in objects works (control test)":
    # Control test - nil patterns in objects without @ should work
    type Node = ref object
      next: Node

    let node = Node(next: nil)

    let result = match node:
      Node(next: nil): "nil next field"
      _: "not nil next"

    check result == "nil next field"

# EXPECTED BEHAVIOR:
# 1. Current: Compilation fails with "Unsupported @ sub-pattern" for nil @ patterns
# 2. After fix: nil @ variable should work like other literal @ patterns (42 @ x, "str" @ s)
# 3. The @ pattern case statement around line 3789 needs nnkNilLit added to the literal cases
