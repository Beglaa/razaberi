import unittest
import ../../pattern_matching

suite "Traditional Variant Object Exhaustiveness Checking":

  test "two-variant exhaustiveness check - complete coverage":
    # Traditional Nim variant with two constructors
    type
      SimpleKind = enum skInt, skString
      SimpleVariant = object
        case kind: SimpleKind
        of skInt: intValue: int
        of skString: stringValue: string

    let intVal = SimpleVariant(kind: skInt, intValue: 42)
    let strVal = SimpleVariant(kind: skString, stringValue: "hello")

    # Both constructors covered - should be exhaustive (no warning)
    let result1 = match intVal:
      SimpleVariant(kind: skInt, intValue: x): x
      SimpleVariant(kind: skString, stringValue: s): s.len

    let result2 = match strVal:
      SimpleVariant(kind: skInt, intValue: x): x
      SimpleVariant(kind: skString, stringValue: s): s.len

    check result1 == 42
    check result2 == 5

  test "three-variant exhaustiveness check - complete coverage":
    # Traditional variant with three constructors
    type
      StatusKind = enum stActive, stInactive, stPending
      Status = object
        case kind: StatusKind
        of stActive: activeTime: int
        of stInactive: reason: string
        of stPending: waitTime: int

    let active = Status(kind: stActive, activeTime: 100)
    let inactive = Status(kind: stInactive, reason: "user logout")
    let pending = Status(kind: stPending, waitTime: 30)

    # All three constructors covered - should be exhaustive
    let r1 = match active:
      Status(kind: stActive, activeTime: t): "active:" & $t
      Status(kind: stInactive, reason: r): "inactive:" & r
      Status(kind: stPending, waitTime: w): "pending:" & $w

    let r2 = match inactive:
      Status(kind: stActive, activeTime: t): "active:" & $t
      Status(kind: stInactive, reason: r): "inactive:" & r
      Status(kind: stPending, waitTime: w): "pending:" & $w

    let r3 = match pending:
      Status(kind: stActive, activeTime: t): "active:" & $t
      Status(kind: stInactive, reason: r): "inactive:" & r
      Status(kind: stPending, waitTime: w): "pending:" & $w

    check r1 == "active:100"
    check r2 == "inactive:user logout"
    check r3 == "pending:30"

  test "variant exhaustiveness with OR patterns":
    # Test that OR patterns are correctly recognized in exhaustiveness checking
    type
      ColorKind = enum ckRed, ckGreen, ckBlue
      Color = object
        case kind: ColorKind
        of ckRed: redValue: int
        of ckGreen: greenValue: int
        of ckBlue: blueValue: int

    let red = Color(kind: ckRed, redValue: 255)
    let green = Color(kind: ckGreen, greenValue: 128)
    let blue = Color(kind: ckBlue, blueValue: 64)

    # Using OR pattern for discriminator-only matching - should still be exhaustive
    let r1 = match red:
      Color(kind: ckRed) | Color(kind: ckGreen): "warm color"
      Color(kind: ckBlue): "cool color"

    let r2 = match green:
      Color(kind: ckRed) | Color(kind: ckGreen): "warm color"
      Color(kind: ckBlue): "cool color"

    let r3 = match blue:
      Color(kind: ckRed) | Color(kind: ckGreen): "warm color"
      Color(kind: ckBlue): "cool color"

    check r1 == "warm color"
    check r2 == "warm color"
    check r3 == "cool color"

  test "variant exhaustiveness with wildcard":
    # Wildcard should make any pattern exhaustive
    type
      ResultKind = enum rkOk, rkError, rkPending
      Result = object
        case kind: ResultKind
        of rkOk: value: int
        of rkError: errorMsg: string
        of rkPending: waitTime: int

    let ok = Result(kind: rkOk, value: 42)
    let err = Result(kind: rkError, errorMsg: "failed")
    let pending = Result(kind: rkPending, waitTime: 10)

    # Only one constructor + wildcard - should be exhaustive
    let r1 = match ok:
      Result(kind: rkOk, value: v): v
      _: 0

    let r2 = match err:
      Result(kind: rkOk, value: v): v
      _: 0

    let r3 = match pending:
      Result(kind: rkOk, value: v): v
      _: 0

    check r1 == 42
    check r2 == 0
    check r3 == 0

  test "variant exhaustiveness with guards - should not affect coverage":
    # Guards should not affect exhaustiveness checking
    type
      NumberKind = enum nkSmall, nkLarge
      Number = object
        case kind: NumberKind
        of nkSmall: smallVal: int
        of nkLarge: largeVal: int

    let small = Number(kind: nkSmall, smallVal: 5)
    let large = Number(kind: nkLarge, largeVal: 1000)

    # Both constructors covered with guards - should still be exhaustive
    let r1 = match small:
      Number(kind: nkSmall, smallVal: x) and x < 10: "very small"
      Number(kind: nkSmall, smallVal: x): "small"
      Number(kind: nkLarge, largeVal: y): "large"

    let r2 = match large:
      Number(kind: nkSmall, smallVal: x) and x < 10: "very small"
      Number(kind: nkSmall, smallVal: x): "small"
      Number(kind: nkLarge, largeVal: y): "large"

    check r1 == "very small"
    check r2 == "large"

  test "mixed DSL and traditional variant exhaustiveness":
    # Ensure traditional variant exhaustiveness works alongside DSL variants
    type
      TraditionalKind = enum tkInt, tkString
      Traditional = object
        case kind: TraditionalKind
        of tkInt: intVal: int
        of tkString: strVal: string

    let trad = Traditional(kind: tkInt, intVal: 99)

    # Traditional variant - should be exhaustive
    let result = match trad:
      Traditional(kind: tkInt, intVal: i): i
      Traditional(kind: tkString, strVal: s): s.len

    check result == 99
