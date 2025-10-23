import unittest
import ../../variant_dsl
import ../../pattern_matching

## Comprehensive exhaustiveness tests for variant DSL
## Tests both positive (should compile) and negative (should not compile) cases

suite "Variant DSL Exhaustiveness - Positive Cases (Should Compile)":

  test "two-constructor variant with both patterns is exhaustive":
    variant TwoValue:
      First(x: int)
      Second(y: string)

    let v = TwoValue.First(42)
    let result = match v:
      TwoValue.First(a): a
      TwoValue.Second(b): b.len

    check result == 42

  test "three-constructor variant with all patterns is exhaustive":
    variant ThreeValue:
      IntV(x: int)
      StrV(s: string)
      BoolV(b: bool)

    let v = ThreeValue.IntV(10)
    let result = match v:
      ThreeValue.IntV(n): n * 2
      ThreeValue.StrV(s): s.len
      ThreeValue.BoolV(b): (if b: 1 else: 0)

    check result == 20

  test "variant with wildcard is exhaustive":
    variant Color:
      Red()
      Green()
      Blue()

    let c = Color.Red()
    let result = match c:
      Color.Red(): "red"
      _: "other"

    check result == "red"

  test "variant with catch-all variable is exhaustive":
    variant Status:
      Pending()
      Active()
      Done()

    let s = Status.Pending()
    let result = match s:
      Status.Pending(): 1
      other: 2

    check result == 1

  test "zero-parameter constructors all covered is exhaustive":
    variant Signal:
      Start()
      Stop()
      Pause()
      Resume()

    let sig = Signal.Start()
    let result = match sig:
      Signal.Start(): "start"
      Signal.Stop(): "stop"
      Signal.Pause(): "pause"
      Signal.Resume(): "resume"

    check result == "start"

  test "mixed parameter constructors all covered is exhaustive":
    variant Data:
      Single(value: int)
      Pair(a: int, b: int)
      Triple(x: int, y: int, z: int)

    let d = Data.Single(42)
    let result = match d:
      Data.Single(v): v
      Data.Pair(x, y): x + y
      Data.Triple(x, y, z): x + y + z

    check result == 42

  test "multiple patterns covering all cases is exhaustive":
    variant Level:
      Low()
      Medium()
      High()

    let lvl = Level.Low()
    let result = match lvl:
      Level.Low(): "low"
      Level.Medium(): "medium"
      Level.High(): "high"

    check result == "low"

suite "Variant DSL Exhaustiveness - Negative Cases (Should Not Compile)":

  template shouldNotCompile(code: untyped): bool =
    not compiles(code)

  test "missing one constructor should not compile":
    variant TwoValue:
      First(x: int)
      Second(y: string)

    check shouldNotCompile (
      let v = TwoValue.First(42)
      let result = match v:
        TwoValue.First(a): a
        # Second missing!
    )

  test "missing two constructors should not compile":
    variant ThreeValue:
      IntV(x: int)
      StrV(s: string)
      BoolV(b: bool)

    check shouldNotCompile (
      let v = ThreeValue.IntV(10)
      let result = match v:
        ThreeValue.IntV(n): n
        # StrV and BoolV missing!
    )

  test "zero-parameter variant missing one should not compile":
    variant Color:
      Red()
      Green()
      Blue()

    check shouldNotCompile (
      let c = Color.Red()
      let result = match c:
        Color.Red(): "red"
        Color.Green(): "green"
        # Blue missing!
    )

  test "zero-parameter variant missing two should not compile":
    variant Status:
      Pending()
      Active()
      Done()

    check shouldNotCompile (
      let s = Status.Pending()
      let result = match s:
        Status.Pending(): 1
        # Active and Done missing!
    )

  test "mixed constructors missing one should not compile":
    variant Data3:
      Single(value: int)
      Pair(a: int, b: int)
      Triple(x: int, y: int, z: int)

    check shouldNotCompile (
      let d = Data3.Single(42)
      let result = match d:
        Data3.Pair(x, y): x + y
        Data3.Triple(x, y, z): x + y + z
        # Single missing!
    )

  test "mixed constructors missing param variant should not compile":
    variant Data2:
      Empty()
      Single(value: int)
      Pair(a: int, b: int)

    check shouldNotCompile (
      let d = Data2.Single(42)
      let result = match d:
        Data2.Empty(): 0
        Data2.Pair(x, y): x + y
        # Single missing!
    )

  test "three-constructor variant missing middle should not compile":
    variant Level:
      Low()
      Medium()
      High()

    check shouldNotCompile (
      let lvl = Level.Low()
      let result = match lvl:
        Level.Low(): "low"
        Level.High(): "high"
        # Medium missing!
    )

  test "four-constructor variant missing one should not compile":
    variant Direction:
      North()
      South()
      East()
      West()

    check shouldNotCompile (
      let d = Direction.North()
      let result = match d:
        Direction.North(): 0
        Direction.South(): 1
        Direction.East(): 2
        # West missing!
    )

suite "Variant DSL Exhaustiveness - Edge Cases":

  test "single constructor variant is exhaustive":
    variant SingleValue:
      Only(x: int)

    let v = SingleValue.Only(42)
    let result = match v:
      SingleValue.Only(n): n

    check result == 42

  test "single zero-param constructor is exhaustive":
    variant Unit:
      Empty()

    let u = Unit.Empty()
    let result = match u:
      Unit.Empty(): 1

    check result == 1
