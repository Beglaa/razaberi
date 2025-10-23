import unittest
import json
import ../../pattern_matching

# Test suite for JsonNode type pattern matching
# Task 03: JsonNode type-based pattern matching using `is` patterns and JsonNodeKind detection

suite "JsonNode Type Pattern Matching":

  test "JsonNode basic type detection":
    let jsonObj: JsonNode = parseJson("""{"name": "Alice"}""")
    let regularObj = "not json"

    let jsonResult = match jsonObj:
      #JsonNode: "is JsonNode"
      x is JsonNode: "is JsonNode"
      _: "not JsonNode"
    check jsonResult == "is JsonNode"

    let regularResult = match regularObj:
      x is JsonNode: "is JsonNode"
      _: "not JsonNode"
    check regularResult == "not JsonNode"

  test "JsonNode kind-specific patterns":
    let jsonObj: JsonNode = parseJson("""{"key": "value"}""")
    let jsonArr: JsonNode = parseJson("""[1, 2, 3]""")
    let jsonStr: JsonNode = parseJson(""""hello"""")
    let jsonNum: JsonNode = parseJson("42")

    let objResult = match jsonObj:
      JsonNode(kind == JObject): "object"
      #x is JsonNode and x.kind == JObject: "object"
      x is JsonNode and x.kind == JArray: "array"
      x is JsonNode: "other json"
      _: "not json"
    check objResult == "object"

    let arrResult = match jsonArr:
      x is JsonNode and x.kind == JObject: "object"
      x is JsonNode and x.kind == JArray: "array"
      x is JsonNode: "other json"
      _: "not json"
    check arrResult == "array"

  test "JsonNode value type patterns":
    let jsonInt: JsonNode = parseJson("123")
    let jsonStr: JsonNode = parseJson(""""test"""")
    let jsonBool: JsonNode = parseJson("true")

    let intResult = match jsonInt:
      x is JsonNode and x.kind == JInt: "integer: " & $x.getInt()
      x is JsonNode and x.kind == JString: "string: " & x.getStr()
      x is JsonNode and x.kind == JBool: "boolean: " & $x.getBool()
      _: "unknown"
    check intResult == "integer: 123"

    let strResult = match jsonStr:
      x is JsonNode and x.kind == JInt: "integer: " & $x.getInt()
      x is JsonNode and x.kind == JString: "string: " & x.getStr()
      x is JsonNode and x.kind == JBool: "boolean: " & $x.getBool()
      _: "unknown"
    check strResult == "string: test"

  test "JsonNode compound type and structure patterns":
    let jsonObj: JsonNode = parseJson("""{"users": [{"name": "Alice"}, {"name": "Bob"}]}""")

    let result = match jsonObj:
      x is JsonNode and x.kind == JObject and x.hasKey("users"):
        let users = x["users"]
        if users.kind == JArray and users.len > 0:
          "object with " & $users.len & " users"
        else:
          "object with empty users"
      x is JsonNode and x.kind == JObject: "object without users"
      x is JsonNode: "other json type"
      _: "not json"
    check result == "object with 2 users"

  test "JsonNode null and empty type patterns":
    let jsonNull: JsonNode = parseJson("null")
    let jsonEmpty: JsonNode = parseJson("{}")

    let nullResult = match jsonNull:
      x is JsonNode and x.kind == JNull: "null value"
      x is JsonNode and x.kind == JObject: "object"
      x is JsonNode: "other json"
      _: "not json"
    check nullResult == "null value"

    let emptyResult = match jsonEmpty:
      x is JsonNode and x.kind == JObject and x.len == 0: "empty object"
      x is JsonNode and x.kind == JObject: "non-empty object"
      _: "not object"
    check emptyResult == "empty object"

  test "JsonNode type patterns with binding":
    let data: JsonNode = parseJson("""{"score": 95}""")

    let result = match data:
      obj is JsonNode and obj.kind == JObject:
        if obj.hasKey("score"):
          let score = obj["score"].getInt()
          if score >= 90: "A grade"
          elif score >= 80: "B grade"
          else: "lower grade"
        else:
          "no score"
      _: "not an object"
    check result == "A grade"

  test "JsonNode mixed type validation":
    let mixedData = @[
      parseJson("42"),
      parseJson(""""hello""""),
      parseJson("true"),
      parseJson("null")
    ]

    var types: seq[string] = @[]
    for item in mixedData:
      let typeStr = match item:
        x is JsonNode and x.kind == JInt: "int"
        x is JsonNode and x.kind == JString: "string"
        x is JsonNode and x.kind == JBool: "bool"
        x is JsonNode and x.kind == JNull: "null"
        _: "unknown"
      types.add(typeStr)

    check types == @["int", "string", "bool", "null"]

  test "JsonNode nested type patterns":
    let nested: JsonNode = parseJson("""{"data": {"users": [{"active": true}]}}""")

    let result = match nested:
      root is JsonNode and root.kind == JObject and root.hasKey("data"):
        let data = root["data"]
        match data:
          data is JsonNode and data.kind == JObject and data.hasKey("users"):
            let users = data["users"]
            if users.kind == JArray and users.len > 0:
              "nested structure valid"
            else:
              "nested structure empty"
          _: "invalid data structure"
      _: "invalid root structure"
    check result == "nested structure valid"

  test "JsonNode type pattern performance":
    let data: JsonNode = parseJson("""{"items": [1,2,3,4,5]}""")

    # Should be efficient - no unnecessary type conversions
    let result = match data:
      x is JsonNode and x.kind == JObject:
        "object with " & $x.len & " keys"
      x is JsonNode and x.kind == JArray:
        "array with " & $x.len & " elements"
      x is JsonNode: "other json type"
      _: "not json"
    check result == "object with 1 keys"

  test "JsonNode complex type pattern combinations":
    let complexData: JsonNode = parseJson("""
    {
      "api": {
        "version": "1.0",
        "endpoints": ["users", "posts", "comments"],
        "config": {
          "rate_limit": 100,
          "auth_required": true
        }
      }
    }
    """)

    let result = match complexData:
      root is JsonNode and root.kind == JObject and root.hasKey("api"):
        let api = root["api"]
        if api.kind == JObject and api.hasKey("version") and api.hasKey("endpoints"):
          let version = api["version"]
          let endpoints = api["endpoints"]
          if version.kind == JString and endpoints.kind == JArray:
            "API v" & version.getStr() & " with " & $endpoints.len & " endpoints"
          else:
            "invalid API structure"
        else:
          "incomplete API"
      x is JsonNode: "not API structure"
      _: "not json"
    check result == "API v1.0 with 3 endpoints"

  test "JsonNode float and number type patterns":
    let jsonFloat: JsonNode = parseJson("3.14")
    let jsonNegative: JsonNode = parseJson("-42")

    let floatResult = match jsonFloat:
      x is JsonNode and x.kind == JFloat: "float: " & $x.getFloat()
      x is JsonNode and x.kind == JInt: "int: " & $x.getInt()
      _: "unknown number"
    check floatResult == "float: 3.14"

    let negativeResult = match jsonNegative:
      x is JsonNode and x.kind == JFloat: "float: " & $x.getFloat()
      x is JsonNode and x.kind == JInt: "int: " & $x.getInt()
      _: "unknown number"
    check negativeResult == "int: -42"