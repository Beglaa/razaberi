## Compile-Time Exhaustiveness Validation for Enum Types
## This test suite validates that non-exhaustive enum patterns cause compilation errors (Rust-style)
## All tests use shouldNotCompile/shouldCompile templates to verify compile-time behavior

import unittest
import std/options
import ../../pattern_matching
import ../helper/ccheck

# ============================================================================
# SUITE 1: Non-Exhaustive Enum Patterns Should NOT Compile
# ============================================================================

suite "Enum Exhaustiveness - Non-Exhaustive Patterns Should Fail Compilation":

  test "missing one enum value in 3-value enum should not compile":
    type Color = enum
      red, green, blue

    check shouldNotCompile (
      let x = red
      let result = match x:
        red: "red"
        green: "green"
        # Missing: blue
    )

  test "missing two enum values should not compile":
    type Color = enum
      red, green, blue

    check shouldNotCompile (
      let x = red
      let result = match x:
        red: "red"
        # Missing: green, blue
    )

  test "missing enum values in 4-value enum should not compile":
    type Status = enum
      active, inactive, pending, archived

    check shouldNotCompile (
      let x = active
      let result = match x:
        active: "active"
        inactive: "inactive"
        # Missing: pending, archived
    )

  test "missing enum values in 7-value enum should not compile":
    type Day = enum
      monday, tuesday, wednesday, thursday, friday, saturday, sunday

    check shouldNotCompile (
      let x = monday
      let result = match x:
        monday: "monday"
        tuesday: "tuesday"
        # Missing: wednesday, thursday, friday, saturday, sunday
    )

  test "empty match on enum should not compile":
    type Color = enum
      red, green, blue

    check shouldNotCompile (
      let x = red
      let result = match x:
        # No patterns at all
        discard
    )

# ============================================================================
# SUITE 2: Exhaustive Enum Patterns Should Compile Successfully
# ============================================================================

suite "Enum Exhaustiveness - Complete Coverage Should Compile":

  test "all enum values covered in 3-value enum should compile":
    type Color = enum
      red, green, blue

    check shouldCompile (
      let x = red
      let result = match x:
        red: "red"
        green: "green"
        blue: "blue"
    )

  test "all enum values covered in 4-value enum should compile":
    type Status = enum
      active, inactive, pending, archived

    check shouldCompile (
      let x = active
      let result = match x:
        active: "active"
        inactive: "inactive"
        pending: "pending"
        archived: "archived"
    )

  test "all enum values covered in 7-value enum should compile":
    type Day = enum
      monday, tuesday, wednesday, thursday, friday, saturday, sunday

    check shouldCompile (
      let x = monday
      let result = match x:
        monday: "day 1"
        tuesday: "day 2"
        wednesday: "day 3"
        thursday: "day 4"
        friday: "day 5"
        saturday: "day 6"
        sunday: "day 7"
    )

  test "single-value enum with one pattern should compile":
    type Single = enum
      only

    check shouldCompile (
      let x = only
      let result = match x:
        only: "only value"
    )

# ============================================================================
# SUITE 3: Wildcard Makes Pattern Exhaustive
# ============================================================================

suite "Enum Exhaustiveness - Wildcard Coverage":

  test "partial coverage with wildcard should compile":
    type Color = enum
      red, green, blue

    check shouldCompile (
      let x = red
      let result = match x:
        red: "red"
        _: "other color"
    )

  test "no explicit coverage with wildcard only should compile":
    type Color = enum
      red, green, blue

    check shouldCompile (
      let x = red
      let result = match x:
        _: "any color"
    )

  test "wildcard at end after some patterns should compile":
    type Status = enum
      active, inactive, pending, archived

    check shouldCompile (
      let x = active
      let result = match x:
        active: "active"
        inactive: "inactive"
        _: "other status"
    )

  test "unguarded @ pattern binding acts as wildcard should compile":
    type Color = enum
      red, green, blue

    check shouldCompile (
      let x = red
      let result = match x:
        red: "red"
        _ @ other: "color: " & $other  # Use @ pattern for variable binding
    )

# ============================================================================
# SUITE 4: OR Pattern Exhaustiveness
# ============================================================================

suite "Enum Exhaustiveness - OR Patterns":

  test "complete coverage via OR patterns should compile":
    type Day = enum
      monday, tuesday, wednesday, thursday, friday, saturday, sunday

    check shouldCompile (
      let x = monday
      let result = match x:
        saturday | sunday: "weekend"
        monday | tuesday | wednesday | thursday | friday: "weekday"
    )

  test "incomplete OR patterns should not compile":
    type Day = enum
      monday, tuesday, wednesday, thursday, friday, saturday, sunday

    check shouldNotCompile (
      let x = monday
      let result = match x:
        saturday | sunday: "weekend"
        monday | tuesday: "start of week"
        # Missing: wednesday, thursday, friday
    )

  test "OR patterns with gaps should not compile":
    type Color = enum
      red, green, blue, yellow

    check shouldNotCompile (
      let x = red
      let result = match x:
        red | green: "warm"
        blue: "cool"
        # Missing: yellow
    )

  test "chained OR patterns covering all values should compile":
    type Grade = enum
      A, B, C, D, F

    check shouldCompile (
      let x = A
      let result = match x:
        A | B: "pass"
        C | D | F: "review needed"
    )

# ============================================================================
# SUITE 5: Guard Patterns Don't Affect Exhaustiveness
# ============================================================================

suite "Enum Exhaustiveness - Guards":

  test "all enum values with guards still exhaustive should compile":
    type Size = enum
      small, medium, large, xlarge

    check shouldCompile (
      let x = small
      let result = match x:
        small: "S"
        medium: "M"
        large: "L"
        xlarge and x == xlarge: "XL"  # Guard doesn't affect exhaustiveness
    )

  test "missing enum values despite guards should not compile":
    type Color = enum
      red, green, blue

    check shouldNotCompile (
      let x = red
      let result = match x:
        red and x == red: "definitely red"
        green: "green"
        # Missing: blue (guard on red doesn't count as full coverage)
    )

  test "guards on same enum value don't provide exhaustiveness":
    type Priority = enum
      low, medium, high

    check shouldNotCompile (
      let x = low
      let result = match x:
        low and true: "low priority"
        low and false: "also low"
        # Missing: medium, high
    )

# ============================================================================
# SUITE 6: Set Pattern Exhaustiveness
# ============================================================================

suite "Enum Exhaustiveness - Set Patterns":

  test "complete set coverage should compile":
    type Day = enum
      Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, Sunday

    check shouldCompile (
      let days = {Monday, Tuesday}
      let result = match days:
        {Monday, Tuesday, Wednesday, Thursday, Friday}: "weekday set"
        {Saturday, Sunday}: "weekend set"
        {}: "empty set"
        _: "mixed set"
    )

  test "missing set combinations with wildcard should compile":
    type Color = enum
      Red, Green, Blue

    check shouldCompile (
      let colors = {Red, Green}
      let result = match colors:
        {Red, Green}: "warm colors"
        _: "other combinations"
    )

# ============================================================================
# SUITE 7: @ Binding Pattern Exhaustiveness
# ============================================================================

suite "Enum Exhaustiveness - @ Binding Patterns":

  test "complete coverage with @ binding should compile":
    type Mode = enum
      read, write, append

    check shouldCompile (
      let x = read
      let result = match x:
        read @ m: "read mode: " & $m
        write @ m: "write mode: " & $m
        append @ m: "append mode: " & $m
    )

  test "incomplete @ binding patterns should not compile":
    type Mode = enum
      read, write, append

    check shouldNotCompile (
      let x = read
      let result = match x:
        read @ m: "read: " & $m
        write @ m: "write: " & $m
        # Missing: append
    )

  test "@ binding with OR pattern exhaustiveness should compile":
    type Status = enum
      running, stopped, paused

    check shouldCompile (
      let x = running
      let result = match x:
        (running | stopped) @ s: "active states: " & $s
        paused @ s: "paused: " & $s
    )

# ============================================================================
# SUITE 8: Boolean Enum Exhaustiveness
# ============================================================================

suite "Enum Exhaustiveness - Boolean (Enum with false/true)":

  test "complete boolean coverage should compile":
    check shouldCompile (
      let x = true
      let result = match x:
        true: "yes"
        false: "no"
    )

  test "missing false should not compile":
    check shouldNotCompile (
      let x = true
      let result = match x:
        true: "yes"
        # Missing: false
    )

  test "missing true should not compile":
    check shouldNotCompile (
      let x = false
      let result = match x:
        false: "no"
        # Missing: true
    )

  test "boolean with wildcard should compile":
    check shouldCompile (
      let x = true
      let result = match x:
        true: "yes"
        _: "not true"
    )

  test "boolean OR pattern should compile":
    check shouldCompile (
      let x = true
      let result = match x:
        true | false: "boolean value"
    )

# ============================================================================
# SUITE 9: Type Pattern Exhaustiveness
# ============================================================================

suite "Enum Exhaustiveness - Type Patterns":

  test "type pattern 'x is bool' should be exhaustive":
    check shouldCompile (
      let x = true
      let result = match x:
        b is bool: "boolean: " & $b
    )

  test "type pattern 'bool(x)' should be exhaustive":
    check shouldCompile (
      let x = true
      let result = match x:
        bool(b): "boolean: " & $b
    )

# ============================================================================
# SUITE 10: Runtime Behavior of Exhaustive Patterns
# ============================================================================

suite "Enum Exhaustiveness - Runtime Behavior Validation":

  test "exhaustive pattern should execute correctly at runtime":
    type Color = enum
      red, green, blue

    let x = green
    let result = match x:
      red: "red"
      green: "green"
      blue: "blue"

    check result == "green"

  test "OR pattern exhaustiveness works at runtime":
    type Day = enum
      monday, tuesday, wednesday, thursday, friday, saturday, sunday

    let weekend = saturday
    let result = match weekend:
      saturday | sunday: "weekend"
      monday | tuesday | wednesday | thursday | friday: "weekday"

    check result == "weekend"

  test "@ binding exhaustive pattern works at runtime":
    type Mode = enum
      read, write, append

    let m = write
    let result = match m:
      read @ mode: "read: " & $mode
      write @ mode: "write: " & $mode
      append @ mode: "append: " & $mode

    check result == "write: write"

# ============================================================================
# TEST EXECUTION
# ============================================================================

when isMainModule:
  discard
