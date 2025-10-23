import unittest
import ../../variant_dsl
import ../../pattern_matching

## Comprehensive tests for zero-parameter variant constructors
## These tests verify both exhaustiveness checking and runtime behavior

suite "Zero-Parameter Constructors - Runtime Behavior":

  test "matching zero-param constructor works":
    variant Status:
      Active()
      Inactive()

    let s = Status.Active()
    let result = match s:
      Status.Active(): "active"
      Status.Inactive(): "inactive"

    check result == "active"

  test "all zero-param constructors can be matched":
    variant Color:
      Red()
      Green()
      Blue()

    let r = Color.Red()
    let g = Color.Green()
    let b = Color.Blue()

    let r_result = match r:
      Color.Red(): 1
      Color.Green(): 2
      Color.Blue(): 3

    let g_result = match g:
      Color.Red(): 1
      Color.Green(): 2
      Color.Blue(): 3

    let b_result = match b:
      Color.Red(): 1
      Color.Green(): 2
      Color.Blue(): 3

    check r_result == 1
    check g_result == 2
    check b_result == 3

suite "Zero-Parameter Constructors - Exhaustiveness":

  test "missing zero-param constructor is caught":
    variant Status:
      Pending()
      Active()
      Complete()

    template shouldNotCompile(code: untyped): bool =
      not compiles(code)

    check shouldNotCompile (
      let s = Status.Pending()
      let result = match s:
        Status.Pending(): 1
        Status.Active(): 2
        # Complete missing!
    )

  test "all zero-param constructors covered compiles":
    variant Status:
      Pending()
      Active()
      Complete()

    let s = Status.Pending()
    let result = match s:
      Status.Pending(): 1
      Status.Active(): 2
      Status.Complete(): 3

    check result == 1
