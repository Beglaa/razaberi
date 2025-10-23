## Test for variant DSL - Cross-Module Export
##
## Tests that variants WITH the export marker (*) work correctly
## across module boundaries.

import unittest
import variant_export_lib

suite "Variant DSL - Cross-Module Export":

  test "exported variant type is accessible":
    # Should be able to construct exported variants
    let r1 = Result.Success("ok")
    let r2 = Result.Error("fail")

    check r1 is Result
    check r2 is Result

  test "exported variant kind field is accessible":
    let r1 = Result.Success("ok")
    let r2 = Result.Error("fail")

    # kind field should be exported and accessible
    check r1.kind == rkSuccess
    check r2.kind == rkError

  test "exported variant enum values are accessible":
    let s1 = Status.Ready()
    let s2 = Status.Running(50)
    let s3 = Status.Completed("done")
    let s4 = Status.Failed("error")

    # Enum values should be accessible for pattern matching
    check s1.kind == skReady
    check s2.kind == skRunning
    check s3.kind == skCompleted
    check s4.kind == skFailed

  test "exported variant fields are accessible":
    let r1 = Result.Success("success value")
    let r2 = Result.Error("error message")

    case r1.kind:
      of rkSuccess:
        # Field should be accessible
        check r1.value == "success value"
      of rkError:
        discard

    case r2.kind:
      of rkSuccess:
        discard
      of rkError:
        # Field should be accessible
        check r2.message == "error message"

  test "exported variant case statement works":
    let s = Status.Running(75)

    var matched = false
    case s.kind:
      of skReady:
        discard
      of skRunning:
        check s.progress == 75
        matched = true
      of skCompleted:
        discard
      of skFailed:
        discard

    check matched

  test "exported variant with multi-param constructor":
    let p1 = Point.Cartesian(3, 4)
    let p2 = Point.Polar(5.0, 0.93)

    # All fields should be accessible
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
        check p2.theta == 0.93

  test "exported variant enum type is accessible":
    # Enum type itself should be accessible
    var kind: ResultKind = rkSuccess
    check kind == rkSuccess

    kind = rkError
    check kind == rkError

  test "exported variant equality works cross-module":
    let r1 = Result.Success("test")
    let r2 = Result.Success("test")
    let r3 = Result.Success("different")
    let r4 = Result.Error("test")

    check r1 == r2
    check r1 != r3
    check r1 != r4

  test "exported variant type alias works":
    # Can use the exported type in function signatures
    proc processResult(r: Result): string =
      case r.kind:
        of rkSuccess: "Success: " & r.value
        of rkError: "Error: " & r.message

    let r1 = Result.Success("data")
    let r2 = Result.Error("problem")

    check processResult(r1) == "Success: data"
    check processResult(r2) == "Error: problem"

  test "exported variant in collections":
    # Can use exported variants in collections
    var results: seq[Result] = @[]
    results.add(Result.Success("one"))
    results.add(Result.Error("two"))
    results.add(Result.Success("three"))

    var successCount = 0
    for r in results:
      if r.kind == rkSuccess:
        successCount.inc

    check successCount == 2
    check results.len == 3
