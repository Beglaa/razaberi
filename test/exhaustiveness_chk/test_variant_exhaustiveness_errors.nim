import unittest
import std/options
import ../../pattern_matching
import ../helper/ccheck

# ============================================================================
# VARIANT OBJECT EXHAUSTIVENESS TESTING
# ============================================================================
# Purpose: Validate Rust-style exhaustiveness checking for variant objects
# Approach: Non-exhaustive variant patterns should cause compilation errors
# ============================================================================

# ============================================================================
# SUITE 1: Non-Exhaustive Patterns Should Fail Compilation
# ============================================================================

suite "Variant Exhaustiveness - Non-Exhaustive Patterns Should Fail Compilation":

  test "missing one discriminator value in 3-value variant should not compile":
    type
      ValueKind = enum kInt, kStr, kFloat
      Value = object
        case kind: ValueKind
        of kInt: intVal: int
        of kStr: strVal: string
        of kFloat: floatVal: float

    check shouldNotCompile (
      let x = Value(kind: kInt, intVal: 42)
      let result = match x:
        Value(kind: kInt, intVal: v): $v
        Value(kind: kStr, strVal: s): s
        # Missing: kFloat
    )

  test "missing two discriminator values should not compile":
    type
      StatusKind = enum skActive, skPending, skClosed
      Status = object
        case kind: StatusKind
        of skActive: activeTime: int
        of skPending: pendingReason: string
        of skClosed: closedDate: string

    check shouldNotCompile (
      let x = Status(kind: skActive, activeTime: 100)
      let result = match x:
        Status(kind: skActive, activeTime: t): $t
        # Missing: skPending, skClosed
    )

  test "empty match on variant should not compile":
    type
      SimpleKind = enum sA, sB
      Simple = object
        case kind: SimpleKind
        of sA: valA: int
        of sB: valB: string

    check shouldNotCompile (
      let x = Simple(kind: sA, valA: 42)
      let result = match x:
        discard  # No patterns at all
    )

  test "missing discriminator value with field patterns should not compile":
    type
      NodeKind = enum nkLeaf, nkBranch
      Node = object
        case kind: NodeKind
        of nkLeaf: value: int
        of nkBranch:
          left: int
          right: int

    check shouldNotCompile (
      let x = Node(kind: nkLeaf, value: 42)
      let result = match x:
        Node(kind: nkLeaf, value: v): $v
        # Missing: nkBranch
    )

# ============================================================================
# SUITE 2: Complete Coverage Should Compile
# ============================================================================

suite "Variant Exhaustiveness - Complete Coverage Should Compile":

  test "all discriminator values covered should compile":
    type
      ColorKind = enum ckRed, ckGreen, ckBlue
      Color = object
        case kind: ColorKind
        of ckRed: redVal: int
        of ckGreen: greenVal: int
        of ckBlue: blueVal: int

    check shouldCompile (
      let x = Color(kind: ckRed, redVal: 255)
      let result = match x:
        Color(kind: ckRed, redVal: r): $r
        Color(kind: ckGreen, greenVal: g): $g
        Color(kind: ckBlue, blueVal: b): $b
    )

  test "all values in different order should compile":
    type
      DayKind = enum dkMon, dkTue, dkWed
      Day = object
        case kind: DayKind
        of dkMon: monVal: int
        of dkTue: tueVal: int
        of dkWed: wedVal: int

    check shouldCompile (
      let x = Day(kind: dkMon, monVal: 1)
      let result = match x:
        Day(kind: dkWed, wedVal: w): $w
        Day(kind: dkMon, monVal: m): $m
        Day(kind: dkTue, tueVal: t): $t
    )

  test "2-value variant fully covered should compile":
    type
      BinaryKind = enum bkZero, bkOne
      Binary = object
        case kind: BinaryKind
        of bkZero: zeroVal: int
        of bkOne: oneVal: int

    check shouldCompile (
      let x = Binary(kind: bkZero, zeroVal: 0)
      let result = match x:
        Binary(kind: bkZero, zeroVal: z): $z
        Binary(kind: bkOne, oneVal: o): $o
    )

# ============================================================================
# SUITE 3: Wildcard Coverage
# ============================================================================

suite "Variant Exhaustiveness - Wildcard Coverage":

  test "wildcard makes incomplete pattern compile":
    type
      LetterKind = enum lkA, lkB, lkC
      Letter = object
        case kind: LetterKind
        of lkA: aVal: int
        of lkB: bVal: int
        of lkC: cVal: int

    check shouldCompile (
      let x = Letter(kind: lkA, aVal: 1)
      let result = match x:
        Letter(kind: lkA, aVal: a): $a
        _: "other"
    )

  test "wildcard with no explicit values should compile":
    type
      NumKind = enum nk1, nk2, nk3
      Num = object
        case kind: NumKind
        of nk1: v1: int
        of nk2: v2: int
        of nk3: v3: int

    check shouldCompile (
      let x = Num(kind: nk1, v1: 42)
      let result = match x:
        _: "any"
    )

  test "variable binding acts as wildcard":
    type
      TestKind = enum tkFoo, tkBar
      Test = object
        case kind: TestKind
        of tkFoo: fooVal: int
        of tkBar: barVal: int

    check shouldCompile (
      let x = Test(kind: tkFoo, fooVal: 42)
      let result = match x:
        Test(kind: tkFoo, fooVal: f): $f
        other: "bar"  # Variable binding catches remaining
    )

# ============================================================================
# SUITE 4: Discriminator-Only Patterns (Implicit Syntax)
# ============================================================================

suite "Variant Exhaustiveness - Discriminator-Only Patterns":

  test "implicit variant syntax with all values should compile":
    type
      ModeKind = enum mkRead, mkWrite
      Mode = object
        case kind: ModeKind
        of mkRead: readBuf: int
        of mkWrite: writeBuf: int

    # Note: Testing with explicit kind field patterns
    # Implicit syntax like Mode(ReadBuf(x)) tested elsewhere
    check shouldCompile (
      let x = Mode(kind: mkRead, readBuf: 100)
      let result = match x:
        Mode(kind: mkRead): "read"
        Mode(kind: mkWrite): "write"
    )

  test "implicit variant syntax missing value should not compile":
    type
      TypeKind = enum tkInt, tkString, tkFloat
      Type = object
        case kind: TypeKind
        of tkInt: intData: int
        of tkString: strData: string
        of tkFloat: floatData: float

    check shouldNotCompile (
      let x = Type(kind: tkInt, intData: 42)
      let result = match x:
        Type(kind: tkInt): "int"
        Type(kind: tkString): "string"
        # Missing: tkFloat
    )

# ============================================================================
# SUITE 5: OR Patterns with Variants
# ============================================================================

suite "Variant Exhaustiveness - OR Patterns":

  test "all discriminator values covered with separate arms should compile":
    type
      SizeKind = enum skSmall, skMedium, skLarge
      Size = object
        case kind: SizeKind
        of skSmall: sVal: int
        of skMedium: mVal: int
        of skLarge: lVal: int

    check shouldCompile (
      let x = Size(kind: skSmall, sVal: 1)
      let result = match x:
        Size(kind: skSmall, sVal: _): "small"
        Size(kind: skMedium, mVal: _): "medium"
        Size(kind: skLarge, lVal: _): "large"
    )

  test "OR pattern with gaps should not compile":
    type
      TrafficKind = enum tkRed, tkYellow, tkGreen
      Traffic = object
        case kind: TrafficKind
        of tkRed: redTime: int
        of tkYellow: yellowTime: int
        of tkGreen: greenTime: int

    check shouldNotCompile (
      let x = Traffic(kind: tkRed, redTime: 30)
      let result = match x:
        Traffic(kind: tkRed) | Traffic(kind: tkGreen): "stop or go"
        # Missing: tkYellow
    )

# ============================================================================
# SUITE 6: Guards Don't Affect Variant Exhaustiveness
# ============================================================================

suite "Variant Exhaustiveness - Guards":

  test "guards on variant values don't provide exhaustiveness":
    type
      RangeKind = enum rkLow, rkHigh
      Range = object
        case kind: RangeKind
        of rkLow: lowVal: int
        of rkHigh: highVal: int

    check shouldNotCompile (
      let x = Range(kind: rkLow, lowVal: 5)
      let result = match x:
        Range(kind: rkLow, lowVal: v) and v < 10: "low"
        Range(kind: rkLow, lowVal: v) and v >= 10: "low-high"
        # Missing: rkHigh (guards on rkLow don't help)
    )

  test "all discriminator values with guards should compile":
    type
      StateKind = enum stOn, stOff
      State = object
        case kind: StateKind
        of stOn: onValue: int
        of stOff: offValue: int

    check shouldCompile (
      let x = State(kind: stOn, onValue: 100)
      let result = match x:
        State(kind: stOn, onValue: v) and v > 50: "high on"
        State(kind: stOn, onValue: v): "low on"
        State(kind: stOff): "off"
    )

# ============================================================================
# SUITE 7: Nested Variant Objects
# ============================================================================

suite "Variant Exhaustiveness - Nested Variants":

  test "nested variant requires outer exhaustiveness":
    type
      InnerKind = enum ikA, ikB
      Inner = object
        case kind: InnerKind
        of ikA: aVal: int
        of ikB: bVal: int

      OuterKind = enum okX, okY
      Outer = object
        case kind: OuterKind
        of okX: xInner: Inner
        of okY: yVal: int

    check shouldNotCompile (
      let inner = Inner(kind: ikA, aVal: 1)
      let outer = Outer(kind: okX, xInner: inner)
      let result = match outer:
        Outer(kind: okX): "x"
        # Missing: okY
    )

# ============================================================================
# SUITE 8: Runtime Behavior Validation
# ============================================================================

suite "Variant Exhaustiveness - Runtime Behavior Validation":

  test "exhaustive variant pattern executes correctly":
    type
      OpKind = enum opAdd, opSub
      Op = object
        case kind: OpKind
        of opAdd: addVal: int
        of opSub: subVal: int

    let x = Op(kind: opAdd, addVal: 10)
    let result = match x:
      Op(kind: opAdd, addVal: v): v + 100
      Op(kind: opSub, subVal: v): v - 100

    check result == 110

  test "variant with wildcard executes correctly":
    type
      FlagKind = enum fkOn, fkOff, fkUnknown
      Flag = object
        case kind: FlagKind
        of fkOn: onData: int
        of fkOff: offData: int
        of fkUnknown: unknownData: int

    let x = Flag(kind: fkUnknown, unknownData: 99)
    let result = match x:
      Flag(kind: fkOn, onData: v): v
      _: -1

    check result == -1

# ============================================================================
# Test Summary
# ============================================================================

