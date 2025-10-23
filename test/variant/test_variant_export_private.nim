## Test for variant DSL - Private Variants (no export marker)
##
## Tests that variants WITHOUT the export marker (*) work correctly
## inside test blocks and don't require top-level scope.

import unittest
import ../../variant_dsl

suite "Variant DSL - Private Variants":

  test "private variant works in test block":
    # Define variant without export marker - should work in test scope
    variant Result:
      Success(value: string)
      Error(message: string)

    let r1 = Result.Success("ok")
    let r2 = Result.Error("fail")

    check r1.kind == rkSuccess
    check r2.kind == rkError

  test "private variant fields are accessible":
    variant Status:
      Ready()
      Running(progress: int)
      Done(output: string)

    let s1 = Status.Ready()
    let s2 = Status.Running(50)
    let s3 = Status.Done("complete")

    check s1.kind == skReady
    check s2.kind == skRunning
    check s2.progress == 50
    check s3.kind == skDone
    check s3.output == "complete"

  test "private variant with case statement":
    variant Option:
      Some(val: int)
      None()

    let opt = Option.Some(42)

    var matched = false
    case opt.kind:
      of okSome:
        check opt.val == 42
        matched = true
      of okNone:
        discard

    check matched

  test "private variant with multi-param constructor":
    variant Point:
      Cartesian(x: int, y: int)
      Polar(r: float, theta: float)

    let p1 = Point.Cartesian(3, 4)
    let p2 = Point.Polar(5.0, 0.93)

    case p1.kind:
      of pkCartesian:
        check p1.x == 3
        check p1.y == 4
      of pkPolar:
        discard

    case p2.kind:
      of pkCartesian:
        discard
      of pkPolar:
        check p2.r == 5.0

  test "private variant equality":
    variant Color:
      Red()
      Green()
      Blue()
      RGB(r: int, g: int, b: int)

    let c1 = Color.Red()
    let c2 = Color.Red()
    let c3 = Color.Green()
    let c4 = Color.RGB(255, 0, 0)
    let c5 = Color.RGB(255, 0, 0)

    check c1 == c2
    check c1 != c3
    check c4 == c5
    check c1 != c4
