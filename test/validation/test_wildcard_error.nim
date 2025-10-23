import ../../pattern_matching
import unittest

# This test should fail at compile time with error:
# "Wildcard pattern must be the last pattern. Patterns after wildcard will never match"

suite "Pattern matching compile-time validation":
  
  # Helper template to test compilation failures
  template shouldNotCompile(code: untyped): bool =
    not compiles(code)

  # Helper template to test compilation success
  template shouldCompile(code: untyped): bool =
    compiles(code)
  
  test "wildcard followed by literal should not compile":
    # Test that invalid wildcard placement fails to compile
    check not shouldCompile (
      let result = match 42:
        1: "one"
        _: "wildcard"
        2: "two"  # This should cause compile error
    )


  # This test should fail at compile time with error:
  # "Wildcard @ pattern must be the last pattern. Patterns after wildcard will never match"

  test "Wildcard @ pattern must be the last pattern. Patterns after wildcard will never match":
    check shouldNotCompile (
      let result = match 42:
        1: "one"
        _ @ x: "wildcard: " & $x
        2: "two"  # This should cause compile error
    )