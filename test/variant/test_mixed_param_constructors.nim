import unittest
import ../../variant_dsl
import ../../pattern_matching

## Tests for mixing zero-parameter and parameter constructors
## This is what the user specifically requested to verify

suite "Mixed Parameter Constructors - Runtime":

  test "match with zero-param first, then param constructors":
    variant Data:
      Empty()
      Single(value: int)
      Pair(a: int, b: int)

    # Test matching each variant
    let d1 = Data.Empty()
    let r1 = match d1:
      Data.Empty(): 0
      Data.Single(v): v
      Data.Pair(x, y): x + y

    let d2 = Data.Single(42)
    let r2 = match d2:
      Data.Empty(): 0
      Data.Single(v): v
      Data.Pair(x, y): x + y

    let d3 = Data.Pair(10, 20)
    let r3 = match d3:
      Data.Empty(): 0
      Data.Single(v): v
      Data.Pair(x, y): x + y

    check r1 == 0
    check r2 == 42
    check r3 == 30

  test "match with param constructors first, then zero-param":
    variant Data2:
      Single(value: int)
      Pair(a: int, b: int)
      Empty()

    let d1 = Data2.Single(42)
    let r1 = match d1:
      Data2.Single(v): v
      Data2.Pair(x, y): x + y
      Data2.Empty(): 0

    let d2 = Data2.Pair(10, 20)
    let r2 = match d2:
      Data2.Single(v): v
      Data2.Pair(x, y): x + y
      Data2.Empty(): 0

    let d3 = Data2.Empty()
    let r3 = match d3:
      Data2.Single(v): v
      Data2.Pair(x, y): x + y
      Data2.Empty(): 0

    check r1 == 42
    check r2 == 30
    check r3 == 0

suite "Mixed Parameter Constructors - Exhaustiveness":

  test "mixed constructors - all covered is exhaustive":
    variant Data3:
      Empty()
      Single(value: int)
      Pair(a: int, b: int)

    let d = Data3.Single(42)
    let result = match d:
      Data3.Empty(): 0
      Data3.Single(v): v
      Data3.Pair(x, y): x + y

    check result == 42

  test "mixed constructors - missing zero-param should not compile":
    variant Data4:
      Empty()
      Single(value: int)
      Pair(a: int, b: int)

    template shouldNotCompile(code: untyped): bool =
      not compiles(code)

    check shouldNotCompile (
      let d = Data4.Single(42)
      let result = match d:
        Data4.Single(v): v
        Data4.Pair(x, y): x + y
        # Empty missing!
    )

  test "mixed constructors - missing param constructor should not compile":
    variant Data5:
      Empty()
      Single(value: int)
      Pair(a: int, b: int)

    template shouldNotCompile(code: untyped): bool =
      not compiles(code)

    check shouldNotCompile (
      let d = Data5.Single(42)
      let result = match d:
        Data5.Empty(): 0
        Data5.Pair(x, y): x + y
        # Single missing!
    )
