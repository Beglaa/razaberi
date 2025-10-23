import unittest
import strutils
import ../../pattern_matching

suite "Enum with attached values - Variable binding":

  # Test 1: Simple enum - bind with @ pattern
  test "bind simple enum value with @ pattern":
    type Color = enum
      red, green, blue

    let myColor = red

    # Use @ pattern to bind the enum value to 'c'
    let result = match myColor:
      red @ c: $c  # @ pattern binding - captures the enum value
      _: "no match"

    check result == "red"

  # Test 2: Enum with @ pattern to destructure tuple values
  test "destructure enum tuple with @ pattern":
    type Status = enum
      active = (0, "Active Status"),
      inactive = (1, "Inactive Status"),
      pending = (2, "Pending Status")

    let status = active

    # Try to use @ pattern to bind and destructure
    let result = match status:
      active @ x: "ord=" & $ord(x) & ", name=" & $x
      inactive @ x: "ord=" & $ord(x) & ", name=" & $x
      _: "no match"

    check result.contains("Active Status")

  # Test 2b: Bind with @ pattern and access properties
  test "bind enum with @ pattern and access ordinal and string":
    type Status = enum
      active = (0, "Active Status"),
      inactive = (1, "Inactive Status"),
      pending = (2, "Pending Status")

    let status = active

    # Bind the enum value with @ pattern and access properties
    let result = match status:
      _ @ s: "ord=" & $ord(s) & ", str=" & $s

    check result.len > 0

  # Test 3: Use @ pattern as a catch-all after specific matches
  test "@ pattern as catch-all after specific enum matches":
    type Priority = enum
      high, medium, low, critical

    let p = low

    let result = match p:
      critical: "CRITICAL!"
      high: "HIGH!"
      _ @ other: $other  # @ pattern with wildcard for everything else

    check result == "low"

  # Test 4: Enum ordinal access through @ pattern
  test "access enum ordinal through @ pattern":
    type Level = enum
      beginner = 1, intermediate = 5, expert = 10

    let level = intermediate

    let result = match level:
      _ @ lvl: ord(lvl)  # @ pattern to bind any enum value

    check result == 5

  # Test 5: @ pattern with OR pattern and catch-all
  test "@ pattern with OR pattern and catch-all":
    type Direction = enum
      north, south, east, west

    let dir = east

    let result = match dir:
      north | south: "vertical"
      _ @ e: "horizontal: " & $e  # @ pattern for remaining cases

    check result == "horizontal: east"

  # Test 6: Use @ pattern to capture and process enum with guard
  test "capture enum with @ pattern and guard":
    type Animal = enum
      dog, cat, bird, fish

    let animal = bird

    let result = match animal:
      dog: "woof"
      cat: "meow"
      bird @ a and ord(a) > 1: "other: " & $a  # @ pattern with guard on specific value
      fish @ a and ord(a) > 1: "fish: " & $a
      _: "unknown"

    check result == "other: bird"
