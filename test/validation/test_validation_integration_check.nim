import unittest
import tables
import ../../pattern_matching

suite "Validation Integration Check - No False Positives":
  test "sequence pattern - valid patterns should compile":
    let numbers = @[1, 2, 3, 4, 5]

    # Basic sequence pattern
    let result1 = match numbers:
      [a, b, c, d, e]: (a, b, c, d, e)
      _: (0, 0, 0, 0, 0)
    check result1 == (1, 2, 3, 4, 5)

    # Spread pattern
    let result2 = match numbers:
      [first, *rest]: (first, rest)
      _: (0, @[])
    check result2[0] == 1
    check result2[1] == @[2, 3, 4, 5]

    # Middle spread
    let result3 = match numbers:
      [a, *middle, z]: (a, middle, z)
      _: (0, @[], 0)
    check result3[0] == 1
    check result3[1] == @[2, 3, 4]
    check result3[2] == 5

    # Default values
    let short = @[1]
    let result4 = match short:
      [x, y = 10, z = 20]: (x, y, z)
      _: (0, 0, 0)
    check result4 == (1, 10, 20)

  test "table pattern - valid patterns should compile":
    let config = {"port": "8080", "host": "localhost"}.toTable

    # Basic table pattern
    let result1 = match config:
      {"port": p, "host": h}: (p, h)
      _: ("", "")
    check result1 == ("8080", "localhost")

    # Rest capture
    let result2 = match config:
      {"port": p, **rest}: (p, rest)
      _: ("", initTable[string, string]())
    check result2[0] == "8080"
    check result2[1].hasKey("host")

  test "set pattern - valid patterns should compile":
    type Color = enum
      Red, Green, Blue

    let colors = {Red, Blue}

    # Set equality pattern
    let result1 = match colors:
      {Red, Blue}: "match"
      _: "no match"
    check result1 == "match"

    # Variable binding
    let result2 = match colors:
      captured: captured
      _: {}
    check result2 == {Red, Blue}

  test "nested patterns - valid complex patterns should compile":
    type Person = object
      name: string
      age: int

    let data = @[
      Person(name: "Alice", age: 30),
      Person(name: "Bob", age: 25)
    ]

    # Nested sequence with object destructuring
    let result = match data:
      [Person(name: n1, age: a1), Person(name: n2, age: a2)]: (n1, a1, n2, a2)
      _: ("", 0, "", 0)
    check result == ("Alice", 30, "Bob", 25)

  test "edge cases - empty collections should compile":
    let emptySeq: seq[int] = @[]
    let result1 = match emptySeq:
      []: "empty"
      _: "not empty"
    check result1 == "empty"

    let emptyTable = initTable[string, string]()
    let result2 = match emptyTable:
      {}: "empty"
      _: "not empty"
    check result2 == "empty"

    type Color = enum Red, Green, Blue
    let emptySet: set[Color] = {}
    let result3 = match emptySet:
      {}: "empty"
      _: "not empty"
    check result3 == "empty"

  test "guards with collections - should compile":
    let numbers = @[1, 2, 3]

    let result = match numbers:
      [a, b, c] and a > 0: "positive first"
      _: "other"
    check result == "positive first"

  test "OR patterns with collections - should compile":
    let numbers = @[1, 2, 3]

    let result = match numbers:
      [1, 2, 3] | [3, 2, 1]: "match"
      _: "no match"
    check result == "match"
