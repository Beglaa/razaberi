import unittest
import json
import strutils
import ../../pattern_matching

# Comprehensive test suite for JsonNode @ pattern matching (value binding)
# Tests all JsonNode @ pattern functionality as specified in Task 06

suite "JsonNode @ Pattern Matching (Value Binding)":

  test "JsonNode basic value @ patterns":
    let jsonStr: JsonNode = parseJson("\"hello\"")
    let jsonInt: JsonNode = parseJson("42")
    let jsonFloat: JsonNode = parseJson("3.14")
    let jsonBool: JsonNode = parseJson("true")

    let strResult = match jsonStr:
      "hello" @ value: "Matched: " & value.getStr()
      _: "no match"
    check strResult == "Matched: hello"

    let intResult = match jsonInt:
      42 @ num: "Number: " & $num.getInt()
      _: "no match"
    check intResult == "Number: 42"

    let floatResult = match jsonFloat:
      3.14 @ pi: "Pi: " & $pi.getFloat()
      _: "no match"
    check floatResult == "Pi: 3.14"

    let boolResult = match jsonBool:
      true @ flag: "Boolean: " & $flag.getBool()
      _: "no match"
    check boolResult == "Boolean: true"

  test "JsonNode object @ patterns":
    let user: JsonNode = parseJson("""{"name": "Alice", "age": 30}""")

    let result = match user:
      {"name": "Alice", "age": age} @ userObj:
        "User " & userObj["name"].getStr() & " is " & $age.getInt() & " years old"
      _: "no match"
    check result == "User Alice is 30 years old"

  test "JsonNode array @ patterns":
    let coords: JsonNode = parseJson("[10, 20, 30]")

    let result = match coords:
      [x, y, z] @ point:
        "3D point " & $point & " with x=" & $x.getInt()
      _: "no match"
    check result.contains("3D point") and result.contains("x=10")

  test "JsonNode nested @ patterns":
    let apiResponse: JsonNode = parseJson("""
      {
        "status": 200,
        "data": {
          "users": [
            {"name": "Alice", "id": 1},
            {"name": "Bob", "id": 2}
          ]
        },
        "meta": {"count": 2}
      }
    """)

    let result = match apiResponse:
      {"status": 200, "data": {"users": users} @ userData, "meta": meta} @ response:
        "Success: " & $users.len & " users, response size: " & $response.len & " fields"
      _: "no match"
    check result == "Success: 2 users, response size: 3 fields"

  test "JsonNode @ patterns with guards":
    let scoreData: JsonNode = parseJson("""{"student": "Alice", "score": 95, "subject": "Math"}""")

    let result = match scoreData:
      {"score": score} @ record and score.getInt() >= 90:
        "Excellent: " & record["student"].getStr() & " scored " & $score.getInt()
      {"score": score} @ record and score.getInt() >= 70:
        "Good: " & record["student"].getStr() & " scored " & $score.getInt()
      {"score": score} @ record:
        "Needs improvement: " & record["student"].getStr() & " scored " & $score.getInt()
      _: "no score data"
    check result == "Excellent: Alice scored 95"

  test "JsonNode complex nested @ patterns":
    let config: JsonNode = parseJson("""
      {
        "app": {
          "name": "MyApp",
          "database": {
            "host": "localhost",
            "port": 5432,
            "credentials": {
              "username": "admin",
              "password": "secret"
            }
          }
        }
      }
    """)

    let result = match config:
      {"app": {"database": {"credentials": creds} @ dbConfig} @ appSection} @ fullConfig:
        let appName = fullConfig["app"]["name"].getStr()
        let dbHost = dbConfig["host"].getStr()
        let username = creds["username"].getStr()
        appName & " connects to " & dbHost & " as " & username
      _: "invalid config"
    check result == "MyApp connects to localhost as admin"

  test "JsonNode @ patterns with mixed types":
    let mixedData: JsonNode = parseJson("""
      {
        "id": 123,
        "name": "Product",
        "tags": ["electronics", "mobile"],
        "specs": {
          "weight": 0.5,
          "color": "black"
        }
      }
    """)

    let result = match mixedData:
      {"id": id, "tags": tags @ tagList, "specs": specs} @ product:
        let productName = product["name"].getStr()
        let tagCount = tagList.len
        let weight = specs["weight"].getFloat()
        productName & " has " & $tagCount & " tags, weighs " & $weight & "kg"
      _: "no match"
    check result == "Product has 2 tags, weighs 0.5kg"

  test "JsonNode @ pattern variable scoping":
    let data: JsonNode = parseJson("""{"outer": {"inner": {"value": 42}}}""")

    let result = match data:
      {"outer": {"inner": inner} @ innerObj} @ outerObj:
        # All variables should be in scope
        let innerValue = inner["value"].getInt()
        let hasInner = outerObj["outer"].hasKey("inner")
        let hasInnerKey = innerObj.hasKey("inner")  # innerObj contains the "inner" key, not "value"
        $innerValue & "-" & $hasInner & "-" & $hasInnerKey
      _: "no match"
    check result == "42-true-true"

  test "JsonNode @ patterns with OR combinations":
    let apiResponse1: JsonNode = parseJson("""{"result": {"data": "success"}}""")
    let apiResponse2: JsonNode = parseJson("""{"data": {"result": "success"}}""")

    for (response, expected) in [(apiResponse1, "result.data"), (apiResponse2, "data.result")]:
      let result = match response:
        {"result": {"data": data}} @ resp: "result.data"
        {"data": {"result": data}} @ resp: "data.result"
        _: "no match"
      check result == expected

  test "JsonNode @ pattern performance":
    let largeData: JsonNode = parseJson("""
      {
        "items": [1,2,3,4,5,6,7,8,9,10],
        "metadata": {
          "count": 10,
          "processed": true,
          "timestamp": "2024-01-01"
        }
      }
    """)

    let result = match largeData:
      {"items": items, "metadata": meta} @ response:
        # Should efficiently bind without copying
        "Items: " & $items.len & ", Metadata keys: " & $meta.len
      _: "no match"
    check result == "Items: 10, Metadata keys: 3"

  test "JsonNode @ patterns with null values":
    let nullData: JsonNode = parseJson("""{"name": "Test", "value": null}""")

    let result = match nullData:
      {"name": name, "value": value} @ record:
        let nameStr = name.getStr()
        let isNull = value.kind == JNull
        nameStr & " has null value: " & $isNull
      _: "no match"
    check result == "Test has null value: true"

  test "JsonNode @ patterns with wildcard":
    let userData: JsonNode = parseJson("""{"id": 1, "name": "Alice", "active": true}""")

    let result = match userData:
      {"id": _, "name": name} @ user:
        "User " & name.getStr() & " found in record: " & $user.hasKey("active")
      _: "no match"
    check result == "User Alice found in record: true"

  test "JsonNode @ patterns with rest capture":
    let settings: JsonNode = parseJson("""{"debug": true, "ssl": false, "port": 8080, "host": "localhost"}""")

    let result = match settings:
      {"debug": debug, **rest} @ config:
        let debugStr = $debug.getBool()
        let restCount = rest.len
        "Debug: " & debugStr & ", remaining settings: " & $restCount
      _: "no match"
    check result == "Debug: true, remaining settings: 3"

  test "JsonNode @ patterns with array destructuring":
    let coordinates: JsonNode = parseJson("""[1, 2, 3, 4, 5]""")

    let result = match coordinates:
      [first, second, *rest] @ coords:
        let firstVal = first.getInt()
        let secondVal = second.getInt()
        let remainingCount = rest.len
        "Point (" & $firstVal & "," & $secondVal & ") with " & $remainingCount & " more dimensions"
      _: "no match"
    check result == "Point (1,2) with 3 more dimensions"

  test "JsonNode @ patterns with type checking guards":
    let mixedArray: JsonNode = parseJson("""[42, "hello", true, 3.14]""")

    let result = match mixedArray:
      [intVal, strVal, boolVal, floatVal] @ values and
        intVal.kind == JInt and strVal.kind == JString and
        boolVal.kind == JBool and floatVal.kind == JFloat:
        "Mixed array with " & $values.len & " typed elements"
      _: "type mismatch"
    check result == "Mixed array with 4 typed elements"

  test "JsonNode @ patterns error cases":
    let emptyObj: JsonNode = parseJson("""{}""")
    let emptyArray: JsonNode = parseJson("""[]""")

    let objResult = match emptyObj:
      {"required": value} @ obj: "found"
      {} @ empty: "empty object"
      _: "no match"
    check objResult == "empty object"

    let arrayResult = match emptyArray:
      [first, *rest] @ arr: "has elements"
      [] @ empty: "empty array"
      _: "no match"
    check arrayResult == "empty array"