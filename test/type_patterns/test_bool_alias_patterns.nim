## Test suite for bool type alias pattern matching
## Verifies PM-3 bug fix: bool aliases now work correctly with pattern matching
##
## Bug: String-based check `metadata.typeName != "bool"` failed for bool aliases
## Fix: Structural check `not isBoolType(metadata)` works for all bool aliases
##
## This test ensures that bool and its aliases behave identically in pattern matching

import unittest
import ../../pattern_matching

# Define bool type aliases
type Boolean = bool
type MyBool = bool
type Flag = bool

suite "Bool Alias Pattern Matching (PM-3 Bug Fix)":

  test "regular bool - literal patterns":
    let x: bool = true
    let result = match x:
      true: "matched true"
      false: "matched false"
    check result == "matched true"

    let y: bool = false
    let result2 = match y:
      true: "matched true"
      false: "matched false"
    check result2 == "matched false"

  test "Boolean alias - literal patterns":
    let x: Boolean = true
    let result = match x:
      true: "matched true"
      false: "matched false"
    check result == "matched true"

    let y: Boolean = false
    let result2 = match y:
      true: "matched true"
      false: "matched false"
    check result2 == "matched false"

  test "MyBool alias - literal patterns":
    let x: MyBool = true
    let result = match x:
      true: "matched true"
      false: "matched false"
    check result == "matched true"

  test "Flag alias - literal patterns":
    let x: Flag = false
    let result = match x:
      true: "matched true"
      false: "matched false"
    check result == "matched false"

  test "regular bool - variable binding with @":
    let x: bool = true
    let result = match x:
      _ @ v: $v
    check result == "true"

  test "Boolean alias - variable binding with @":
    # This was BROKEN before PM-3 fix
    # Would fail with: "Invalid enum value 'v'"
    let x: Boolean = false
    let result = match x:
      _ @ v: $v
    check result == "false"

  test "MyBool alias - variable binding with @":
    let x: MyBool = true
    let result = match x:
      _ @ v: $v
    check result == "true"

  test "regular bool - wildcard pattern":
    let x: bool = true
    let result = match x:
      _: "wildcard matched"
    check result == "wildcard matched"

  test "Boolean alias - wildcard pattern":
    let x: Boolean = false
    let result = match x:
      _: "wildcard matched"
    check result == "wildcard matched"

  test "regular bool - guards":
    let x: bool = true
    let result = match x:
      true and x: "true with guard"
      false: "false"
      _: "other"
    check result == "true with guard"

  test "Boolean alias - guards":
    let x: Boolean = false
    let result = match x:
      false and not x: "false with guard"
      true: "true"
      _: "other"
    check result == "false with guard"

  test "MyBool alias - guards with complex expressions":
    let x: MyBool = true
    let enabled = true
    let result = match x:
      true and enabled: "both true"
      true: "only x true"
      false: "x false"
    check result == "both true"

  test "regular bool - OR patterns":
    let x: bool = true
    let result = match x:
      true | false: "matched bool"
      _: "other"
    check result == "matched bool"

  test "Boolean alias - OR patterns":
    let x: Boolean = false
    let result = match x:
      true | false: "matched bool"
      _: "other"
    check result == "matched bool"

  test "regular bool - @ with literal":
    let x: bool = true
    let result = match x:
      true @ val: $val
      false @ val: "false: " & $val
    check result == "true"

  test "Boolean alias - @ with literal":
    let x: Boolean = false
    let result = match x:
      true @ val: $val
      false @ val: "false: " & $val
    check result == "false: false"

  test "Flag alias - mixed patterns":
    let x: Flag = true
    let result = match x:
      true @ val and val: "true and enabled"
      false: "disabled"
      _: "other"
    check result == "true and enabled"

  test "bool vs Boolean - behavioral equivalence":
    # Both bool and Boolean should behave identically
    let b: bool = true
    let bb: Boolean = true

    let r1 = match b:
      true: 1
      false: 0
    let r2 = match bb:
      true: 1
      false: 0

    check r1 == r2
    check r1 == 1

  test "exhaustiveness - bool and aliases":
    # Both should compile without exhaustiveness warnings
    let x: bool = true
    let y: Boolean = false

    let r1 = match x:
      true: "t"
      false: "f"

    let r2 = match y:
      true: "t"
      false: "f"

    check r1 == "t"
    check r2 == "f"

  test "nested bool aliases":
    type InnerFlag = bool
    type OuterFlag = InnerFlag

    let x: OuterFlag = true
    let result = match x:
      true: "outer true"
      false: "outer false"
    check result == "outer true"

  test "bool alias in object pattern":
    type Config = object
      enabled: Boolean
      debug: MyBool

    let cfg = Config(enabled: true, debug: false)

    let result = match cfg:
      Config(enabled: true, debug: false): "production"
      Config(enabled: true, debug: true): "debug"
      Config(enabled: false): "disabled"
      _: "other"

    check result == "production"

  test "bool alias in tuple pattern - with variable binding":
    let t: (Boolean, MyBool) = (true, false)

    let result = match t:
      (b1 @ _, b2 @ _): $b1 & "," & $b2
      _: "other"

    check result == "true,false"

