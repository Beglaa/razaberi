import unittest
import std/json
import ../../pattern_matching

suite "JsonNode OR Pattern Matching":

  # Category 1: Simple JsonNode Literal OR Patterns (basic test)
  test "JsonNode simple literal OR patterns":
    # Start with the simplest case - this should work if JsonNode OR patterns work
    let str1: JsonNode = parseJson("\"hello\"")
    let str2: JsonNode = parseJson("\"world\"")
    let str3: JsonNode = parseJson("\"other\"")

    # This is the basic OR pattern test - using string literals for JsonNode
    let result1 = match str1:
      "hello" | "world": "greeting"
      _: "other"
    check result1 == "greeting"

    let result2 = match str2:
      "hello" | "world": "greeting"
      _: "other"
    check result2 == "greeting"

    let result3 = match str3:
      "hello" | "world": "greeting"
      _: "other"
    check result3 == "other"

  # Category 2: JsonNode Object OR Patterns
  test "JsonNode object OR patterns":
    let success1: JsonNode = parseJson("""{"status": 200, "message": "OK"}""")
    let success2: JsonNode = parseJson("""{"status": 201, "message": "Created"}""")
    let error: JsonNode = parseJson("""{"status": 404, "message": "Not Found"}""")

    for (response, expected) in [(success1, "success"), (success2, "success"), (error, "not success")]:
      let result = match response:
        {"status": 200} | {"status": 201} | {"status": 202}: "success"
        _: "not success"
      check result == expected

  # Category 3: Mixed Structure OR Patterns
  test "JsonNode mixed structure OR patterns":
    let userObj: JsonNode = parseJson("""{"type": "user"}""")
    let userArray: JsonNode = parseJson("""["user"]""")
    let adminObj: JsonNode = parseJson("""{"type": "admin"}""")

    for (data, expected) in [(userObj, "user"), (userArray, "user"), (adminObj, "admin")]:
      let result = match data:
        {"type": "user"} | ["user"]: "user"
        {"type": "admin"}: "admin"
        _: "unknown"
      check result == expected

  # Category 4: JsonNode Array OR Patterns
  test "JsonNode array OR patterns":
    let coords2D: JsonNode = parseJson("[10, 20]")
    let coords3D_zero: JsonNode = parseJson("[10, 20, 0]")
    let coords3D: JsonNode = parseJson("[10, 20, 30]")
    let invalid: JsonNode = parseJson("[10]")

    for (coords, expected) in [(coords2D, "2D"), (coords3D_zero, "2D"), (coords3D, "3D"), (invalid, "invalid")]:
      let result = match coords:
        [10, 20] | [10, 20, 0]: "2D"  # Treat 3D with z=0 as 2D
        [10, 20, 30]: "3D"
        _: "invalid"
      check result == expected

  # Category 5: Complex JsonNode OR Patterns
  test "JsonNode complex OR patterns":
    let apiSuccess: JsonNode = parseJson("""{"result": "success"}""")
    let apiError: JsonNode = parseJson("""{"error": "failed"}""")
    let legacySuccess: JsonNode = parseJson("""{"status": "ok"}""")

    for (response, expected) in [(apiSuccess, "new success"), (apiError, "error"), (legacySuccess, "legacy success")]:
      let result = match response:
        {"result": "success"} | {"data": "success"}: "new success"
        {"error": "failed"}: "error"
        {"status": "ok"}: "legacy success"
        _: "unknown format"
      check result == expected

  # Category 6: JsonNode Value Type OR Patterns
  test "JsonNode value type OR patterns":
    let stringVal: JsonNode = parseJson("\"42\"")
    let intVal: JsonNode = parseJson("42")
    let boolVal: JsonNode = parseJson("true")

    for (value, expected) in [(stringVal, 42), (intVal, 42), (boolVal, 1)]:
      let result = match value:
        x and x.kind == JString and x.getStr() == "42": 42
        x and x.kind == JInt: x.getInt()
        x and x.kind == JBool: (if x.getBool(): 1 else: 0)
        _: -1
      check result == expected

  # Category 7: Optimized JsonNode OR Patterns
  test "JsonNode optimized OR patterns":
    let validCodes = @[200, 201, 202, 204]
    let invalidCodes = @[400, 404, 500]

    for code in validCodes:
      let response: JsonNode = parseJson("""{"code": """ & $code & """}""")
      let result = match response:
        {"code": 200} | {"code": 201} | {"code": 202} | {"code": 204}: "success"
        _: "error"
      check result == "success"

    for code in invalidCodes:
      let response: JsonNode = parseJson("""{"code": """ & $code & """}""")
      let result = match response:
        {"code": 200} | {"code": 201} | {"code": 202} | {"code": 204}: "success"
        _: "error"
      check result == "error"

  # Category 8: Simple JsonNode OR Key Patterns
  test "JsonNode simple key OR patterns":
    let config1: JsonNode = parseJson("""{"host": "localhost"}""")
    let config2: JsonNode = parseJson("""{"server": "localhost"}""")

    for (config, expected) in [(config1, "localhost config"), (config2, "localhost config")]:
      let result = match config:
        {"host": "localhost"} | {"server": "localhost"}: "localhost config"
        _: "unknown config"
      check result == expected

  # Category 9: JsonNode OR Different Key Patterns
  test "JsonNode OR different key patterns":
    let userData: JsonNode = parseJson("""{"user_name": "Alice"}""")
    let profileData: JsonNode = parseJson("""{"profile_name": "Bob"}""")

    for (data, expected) in [(userData, "user data"), (profileData, "profile data")]:
      let result = match data:
        {"user_name": "Alice"} | {"user_name": "Bob"}: "user data"
        {"profile_name": "Alice"} | {"profile_name": "Bob"}: "profile data"
        _: "no match"
      check result == expected

  # Category 10: Performance JsonNode OR Patterns
  test "JsonNode OR pattern performance":
    let testData: JsonNode = parseJson("""{"category": "electronics"}""")

    # Test with many alternatives - should be optimized
    let result = match testData:
      {"category": "electronics"} | {"category": "computers"} |
      {"category": "phones"} | {"category": "tablets"} |
      {"category": "accessories"} | {"category": "gaming"}:
        "tech category"
      _: "no category"

    check result == "tech category"