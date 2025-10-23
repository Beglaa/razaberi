import unittest, json
import ../../pattern_matching

suite "JsonNode Array Pattern Matching":

  test "JsonNode static array matching":
    let coords: JsonNode = parseJson("[10, 20, 30]")
    let result = match coords:
      [x, y, z]: "3D point: " & $x.getInt() & "," & $y.getInt() & "," & $z.getInt()
      _: "invalid"
    check result == "3D point: 10,20,30"

  test "JsonNode 2D coordinate matching":
    let point: JsonNode = parseJson("[5, 15]")
    let result = match point:
      [0, 0]: "origin"
      [x, y] and x.getInt() > 0 and y.getInt() > 0: "quadrant 1"
      [x, y]: "other quadrant"
      _: "not an array"
    check result == "quadrant 1"

  test "JsonNode RGB color patterns":
    let color: JsonNode = parseJson("[255, 0, 128]")
    let result = match color:
      [255, 0, 0]: "red"
      [0, 255, 0]: "green"
      [0, 0, 255]: "blue"
      [r, g, b]: "custom color: " & $r.getInt() & "," & $g.getInt() & "," & $b.getInt()
      _: "not a 3-element array"
    check result == "custom color: 255,0,128"

  test "JsonNode exact length validation":
    let shortArray: JsonNode = parseJson("[1, 2]")
    let longArray: JsonNode = parseJson("[1, 2, 3, 4]")

    let shortResult = match shortArray:
      [a, b, c]: "three elements"
      [a, b]: "two elements"
      _: "other"
    check shortResult == "two elements"

    let longResult = match longArray:
      [a, b, c]: "three elements"
      [a, b]: "two elements"
      _: "other"
    check longResult == "other"  # Should not match shorter patterns

  test "JsonNode mixed type array patterns":
    let mixed: JsonNode = parseJson("""[42, "test", true]""")
    let result = match mixed:
      [num, str, flag]:
        $num.getInt() & "_" & str.getStr() & "_" & $flag.getBool()
      _: "no match"
    check result == "42_test_true"

  test "JsonNode nested array patterns":
    let matrix: JsonNode = parseJson("[[1, 2], [3, 4], [5, 6]]")
    let result = match matrix:
      [[a, b], [c, d], [e, f]]: a.getInt() + f.getInt()  # Sum of corners
      _: 0
    check result == 7  # 1 + 6

  test "JsonNode array variable binding":
    let data: JsonNode = parseJson("[100, 200]")
    let result = match data:
      [first, second]:
        let sum = first.getInt() + second.getInt()
        "sum: " & $sum
      _: "invalid"
    check result == "sum: 300"

  test "JsonNode array edge cases":
    let empty: JsonNode = parseJson("[]")
    let emptyResult = match empty:
      []: "empty array"
      _: "not empty"
    check emptyResult == "empty array"

    let single: JsonNode = parseJson("[42]")
    let singleResult = match single:
      [value]: "single: " & $value.getInt()
      _: "not single"
    check singleResult == "single: 42"

  test "JsonNode array type mismatch":
    let notArray: JsonNode = parseJson("""{"x": 1, "y": 2}""")
    let result = match notArray:
      [x, y]: "is array"
      _: "not array"
    check result == "not array"

  test "JsonNode array with null elements":
    let withNull: JsonNode = parseJson("[1, null, 3]")
    let result = match withNull:
      [a, null, c]: a.getInt() + c.getInt()
      _: 0
    check result == 4

  test "JsonNode array literal matching":
    let testArray: JsonNode = parseJson("[1, 2, 3]")
    let result = match testArray:
      [1, 2, 3]: "exact match"
      [x, y, z]: "variable match"
      _: "no match"
    check result == "exact match"

  test "JsonNode array with string elements":
    let stringArray: JsonNode = parseJson("""["hello", "world"]""")
    let result = match stringArray:
      ["hello", "world"]: "greeting"
      [first, second]: first.getStr() & " " & second.getStr()
      _: "no match"
    check result == "greeting"