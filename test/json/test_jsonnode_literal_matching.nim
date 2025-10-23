import unittest
import std/json
import ../../pattern_matching

suite "JsonNode Literal Pattern Matching Tests":

  test "JsonNode basic literal matching":
    let jsonStr: JsonNode = parseJson("\"hello\"")
    let jsonInt: JsonNode = parseJson("42")
    let jsonFloat: JsonNode = parseJson("3.14")
    let jsonBool: JsonNode = parseJson("true")

    let strResult = match jsonStr:
      "hello": true
      _: false
    check strResult == true

    let intResult = match jsonInt:
      42: true
      _: false
    check intResult == true

    let floatResult = match jsonFloat:
      3.14: true
      _: false
    check floatResult == true

    let boolResult = match jsonBool:
      true: true
      _: false
    check boolResult == true

  test "JsonNode null literal matching":
    let jsonNull: JsonNode = parseJson("null")
    let regularNull: ptr string = nil

    let jsonResult = match jsonNull:
      nil: "is null"
      _: "not null"
    check jsonResult == "is null"

    let regularResult = match regularNull:
      nil: "is nil"
      _: "not nil"
    check regularResult == "is nil"

  test "JsonNode literal type mismatches":
    let jsonStr: JsonNode = parseJson("\"42\"")  # String "42"
    let jsonInt: JsonNode = parseJson("42")        # Integer 42

    # String "42" should not match integer 42
    let strResult = match jsonStr:
      42: "matched as int"
      "42": "matched as string"
      _: "no match"
    check strResult == "matched as string"

    # Integer 42 should not match string "42"
    let intResult = match jsonInt:
      "42": "matched as string"
      42: "matched as int"
      _: "no match"
    check intResult == "matched as int"

  test "JsonNode literal arrays (basic array type check)":
    let jsonArray: JsonNode = parseJson("""[1, "hello", true, null]""")

    # Basic array type verification - full array literal patterns are a separate task
    let result = match jsonArray.kind:
      JArray: "is array"
      _: "not array"
    check result == "is array"

    # Verify array access works
    let firstElement = match jsonArray[0]:
      1: "first is one"
      _: "other"
    check firstElement == "first is one"

  test "JsonNode literal objects":
    let jsonObj: JsonNode = parseJson("""{"name": "Alice", "age": 30, "active": true}""")

    let result = match jsonObj:
      {"name": "Alice", "age": 30, "active": true}: "exact match"
      {"name": "Alice", "age": 30}: "partial match"
      {"name": "Alice"}: "name only"
      _: "no match"
    check result == "exact match"

  test "JsonNode literal range comparisons (basic literal matching)":
    let numbers = @[
      parseJson("5"),
      parseJson("15"),
      parseJson("25"),
      parseJson("35")
    ]

    var results: seq[string] = @[]
    for num in numbers:
      # Basic literal matching - guard expressions with JsonNode are a separate task
      let result = match num:
        5: "exactly five"
        15: "exactly fifteen"
        25: "exactly twenty-five"
        35: "exactly thirty-five"
        _: "other"
      results.add(result)

    check results == @["exactly five", "exactly fifteen", "exactly twenty-five", "exactly thirty-five"]

  test "JsonNode boolean literal patterns":
    let booleans = @[
      parseJson("true"),
      parseJson("false"),
      parseJson("null"),
      parseJson("1"),
      parseJson("0")
    ]

    var results: seq[string] = @[]
    for value in booleans:
      let result = match value:
        true: "true"
        false: "false"
        nil: "null"
        1: "numeric_one"
        0: "numeric_zero"
        _: "other"
      results.add(result)

    check results == @["true", "false", "null", "numeric_one", "numeric_zero"]

  test "JsonNode string literal patterns":
    let strings = @[
      parseJson("\"hello\""),
      parseJson("\"world\""),
      parseJson("\"42\""),
      parseJson("\"true\""),
      parseJson("\"null\"")
    ]

    var results: seq[string] = @[]
    for str in strings:
      let result = match str:
        "hello": "greeting"
        "world": "location"
        "42": "string_number"
        "true": "string_boolean"
        "null": "string_null"
        _: "other_string"
      results.add(result)

    check results == @["greeting", "location", "string_number", "string_boolean", "string_null"]

  test "Mixed JsonNode and regular literal patterns":
    # Test JsonNode matching
    let jsonValue = parseJson("42")
    let jsonResult = match jsonValue:
      42: "matched_42"
      _: "no_match"

    # Test regular int matching
    let regularValue = 42
    let regularResult = match regularValue:
      42: "matched_42"
      _: "no_match"

    check jsonResult == "matched_42"
    check regularResult == "matched_42"

  test "JsonNode complex literal nesting":
    let complexData: JsonNode = parseJson("""
      {
        "status": 200,
        "data": {
          "items": [
            {"id": 1, "name": "First", "active": true},
            {"id": 2, "name": "Second", "active": false}
          ]
        }
      }
    """)

    let result = match complexData:
      {"status": 200, "data": {"items": [{"id": 1, "name": "First", "active": true}, _]}}:
        "found first item active"
      {"status": 200, "data": {"items": items}}:
        "found items: " & $items.len
      {"status": 200}:
        "success status"
      _: "no match"

    check result == "found first item active"

  test "JsonNode negative number literals":
    let negativeNumbers = @[
      parseJson("-42"),
      parseJson("-3.14"),
      parseJson("0"),
      parseJson("42")
    ]

    var results: seq[string] = @[]
    for num in negativeNumbers:
      let result = match num:
        -42: "negative int"
        -3.14: "negative float"
        0: "zero"
        42: "positive int"
        _: "other"
      results.add(result)

    check results == @["negative int", "negative float", "zero", "positive int"]

  test "JsonNode large number literals":
    let largeNumbers = @[
      parseJson("999999999"),
      parseJson("1000000000"),
      parseJson("9223372036854775807")  # max int64
    ]

    var results: seq[string] = @[]
    for num in largeNumbers:
      let result = match num:
        999999999: "almost billion"
        1000000000: "exactly billion"
        9223372036854775807: "max int64"
        _: "other large number"
      results.add(result)

    check results == @["almost billion", "exactly billion", "max int64"]

  test "JsonNode float precision literals":
    let floats = @[
      parseJson("3.14159"),
      parseJson("2.71828"),
      parseJson("1.41421")
    ]

    var results: seq[string] = @[]
    for f in floats:
      let result = match f:
        3.14159: "pi"
        2.71828: "e"
        1.41421: "sqrt2"
        _: "other float"
      results.add(result)

    check results == @["pi", "e", "sqrt2"]

  test "JsonNode empty string and whitespace literals":
    let specialStrings = @[
      parseJson("\"\""),        # empty string
      parseJson("\" \""),       # space
      parseJson("\"\\t\""),     # tab
      parseJson("\"\\n\""),     # newline
    ]

    var results: seq[string] = @[]
    for str in specialStrings:
      let result = match str:
        "": "empty"
        " ": "space"
        "\t": "tab"
        "\n": "newline"
        _: "other special"
      results.add(result)

    check results == @["empty", "space", "tab", "newline"]