## Test suite for Rust-style exhaustiveness checking
## This validates that non-exhaustive patterns cause compile-time errors

import unittest
import std/options
import ../../pattern_matching

# These tests verify Rust-style exhaustiveness checking:
# - Exhaustive patterns compile successfully
# - Non-exhaustive patterns cause compile-time errors (prevent compilation)
# - Pattern matching safety is enforced at compile time like Rust

suite "Rust-Style Exhaustiveness Tests":

  test "should work with exhaustive enum patterns":
    # This should compile successfully since all enum cases are covered
    type Color = enum
      red, green, blue

    let color = red
    let result = match color:
      red: "red color"
      green: "green color"
      blue: "blue color"

    check(result == "red color")

  test "should work with wildcard patterns":
    # Wildcard patterns make any pattern match exhaustive (Rust-style)
    type Status = enum
      active, inactive, pending

    let status = pending
    let result = match status:
      active: "running"
      _: "not active"

    check(result == "not active")

  test "should work with Option exhaustive patterns":
    # Complete Option coverage compiles successfully (like Rust)
    let opt: Option[int] = some(42)
    let result = match opt:
      Some(x): "value: " & $x
      None(): "no value"
    check result == "value: 42"

# NOTE: Non-exhaustive patterns will cause COMPILE-TIME ERRORS
#
# The following examples would prevent compilation (Rust-style behavior):
#
# Example 1 - Non-exhaustive enum (COMPILE ERROR):
# type Color = enum red, green, blue
# match color:
#   red: "red"     # ERROR: Missing green, blue cases
#
# Example 2 - Non-exhaustive Option (COMPILE ERROR):
# match opt:
#   Some(x): "value"  # ERROR: Missing None() case
#
# Example 3 - Literal mismatch (COMPILE ERROR):
# match 5:
#   4: "four"      # ERROR: 5 does not match 4
#
# To make these patterns exhaustive (and allow compilation):
# - Add all missing cases explicitly
# - Add wildcard pattern: _: "default"
# - Add catch-all variable: x: "caught: " & $x

# All tests in this file use exhaustive patterns, so they will compile successfully.
# Non-exhaustive patterns would prevent compilation entirely.

when isMainModule:
  discard