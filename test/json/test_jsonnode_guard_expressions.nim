import unittest
import std/json
import std/strutils
import ../../pattern_matching

suite "JsonNode Guard Expressions":

  test "JsonNode basic value guards":
    let scores = @[
      parseJson("85"),
      parseJson("95"),
      parseJson("75")
    ]

    var results: seq[string] = @[]
    for score in scores:
      let result = match score:
        x is JsonNode and x.kind == JInt and x.getInt() >= 90: "A grade"
        x is JsonNode and x.kind == JInt and x.getInt() >= 80: "B grade"
        x is JsonNode and x.kind == JInt: "C grade"
        _: "Invalid score"
      results.add(result)

    check results == @["B grade", "A grade", "C grade"]

  test "JsonNode object structure guards":
    let users = @[
      parseJson("""{"name": "Alice", "age": 30, "email": "alice@test.com"}"""),
      parseJson("""{"name": "Bob", "age": 25}"""),
      parseJson("""{"username": "Charlie"}""")
    ]

    var results: seq[string] = @[]
    for user in users:
      let result = match user:
        #{"name": name, "age": age, "email": email}: "Complete profile: " & name.getStr()
        obj is JsonNode and obj.kind == JObject and obj.hasKey("name") and obj.hasKey("email"):
          "Complete profile: " & obj["name"].getStr()
        obj is JsonNode and obj.kind == JObject and obj.hasKey("name"):
          "Basic profile: " & obj["name"].getStr()
        obj is JsonNode and obj.kind == JObject and obj.hasKey("username"):
          "Legacy profile: " & obj["username"].getStr()
        _: "Invalid user"
      results.add(result)

    check results == @["Complete profile: Alice", "Basic profile: Bob", "Legacy profile: Charlie"]

  test "JsonNode array structure guards":
    let datasets = @[
      parseJson("[]"),
      parseJson("[1, 2, 3]"),
      parseJson("[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]")
    ]

    var results: seq[string] = @[]
    for dataset in datasets:
      let result = match dataset:
        arr is JsonNode and arr.kind == JArray and arr.len == 0: "empty"
        arr is JsonNode and arr.kind == JArray and arr.len <= 5: "small"
        arr is JsonNode and arr.kind == JArray and arr.len > 5: "large"
        _: "not array"
      results.add(result)

    check results == @["empty", "small", "large"]

  test "JsonNode pattern with field guards":
    let products = @[
      parseJson("""{"name": "Laptop", "price": 1200, "category": "electronics"}"""),
      parseJson("""{"name": "Book", "price": 25, "category": "education"}"""),
      parseJson("""{"name": "Phone", "price": 800, "category": "electronics"}""")
    ]

    var expensiveElectronics: seq[string] = @[]
    for product in products:
      let result = match product:
        {"category": "electronics", "price": price} and price.getInt() > 1000:
          product["name"].getStr()
        _: ""
      if result != "":
        expensiveElectronics.add(result)

    check expensiveElectronics == @["Laptop"]

  test "JsonNode complex guard expressions":
    let apiResponses = @[
      parseJson("""{"status": 200, "data": {"items": [1,2,3]}, "meta": {"count": 3}}"""),
      parseJson("""{"status": 200, "data": {"items": []}, "meta": {"count": 0}}"""),
      parseJson("""{"status": 404, "error": "Not found"}""")
    ]

    var results: seq[string] = @[]
    for response in apiResponses:
      let result = match response:
        obj is JsonNode and obj.kind == JObject and obj["status"].getInt() == 200 and
        obj.hasKey("data") and obj["data"]["items"].len > 0:
          "Success with " & $obj["data"]["items"].len & " items"
        obj is JsonNode and obj.kind == JObject and obj["status"].getInt() == 200:
          "Success with no items"
        obj is JsonNode and obj.kind == JObject and obj["status"].getInt() >= 400:
          "Error: " & (if obj.hasKey("error"): obj["error"].getStr() else: "Unknown error")
        _: "Invalid response"
      results.add(result)

    check results == @["Success with 3 items", "Success with no items", "Error: Not found"]

  test "JsonNode range guards":
    let temperatures = @[
      parseJson("-10"),
      parseJson("25"),
      parseJson("35"),
      parseJson("50")
    ]

    var classifications: seq[string] = @[]
    for temp in temperatures:
      let result = match temp:
        t is JsonNode and t.kind == JInt and t.getInt() < 0: "freezing"
        t is JsonNode and t.kind == JInt and t.getInt() >= 0 and t.getInt() < 30: "cool"
        t is JsonNode and t.kind == JInt and t.getInt() >= 30 and t.getInt() < 40: "warm"
        t is JsonNode and t.kind == JInt and t.getInt() >= 40: "hot"
        _: "invalid"
      classifications.add(result)

    check classifications == @["freezing", "cool", "warm", "hot"]

  test "JsonNode string pattern guards":
    let emails = @[
      parseJson(""""user@example.com""""),
      parseJson(""""admin@company.org""""),
      parseJson(""""invalid-email""""),
      parseJson(""""test@domain.co.uk"""")
    ]

    var emailTypes: seq[string] = @[]
    for email in emails:
      let result = match email:
        e is JsonNode and e.kind == JString and e.getStr().contains("@") and e.getStr().endsWith(".com"):
          "standard"
        e is JsonNode and e.kind == JString and e.getStr().contains("@") and e.getStr().endsWith(".org"):
          "organization"
        e is JsonNode and e.kind == JString and e.getStr().contains("@") and e.getStr().contains("."):
          "other_domain"
        e is JsonNode and e.kind == JString:
          "invalid"
        _: "not_string"
      emailTypes.add(result)

    check emailTypes == @["standard", "organization", "invalid", "other_domain"]

  test "JsonNode nested object guards":
    let configs = @[
      parseJson("""{"app": {"database": {"host": "localhost", "port": 5432}}}"""),
      parseJson("""{"app": {"database": {"host": "remote.db.com", "port": 3306}}}"""),
      parseJson("""{"app": {"cache": {"redis": true}}}""")
    ]

    var dbTypes: seq[string] = @[]
    for config in configs:
      let result = match config:
        cfg is JsonNode and cfg.hasKey("app") and cfg["app"].hasKey("database") and
        cfg["app"]["database"]["port"].getInt() == 5432:
          "postgresql"
        cfg is JsonNode and cfg.hasKey("app") and cfg["app"].hasKey("database") and
        cfg["app"]["database"]["port"].getInt() == 3306:
          "mysql"
        cfg is JsonNode and cfg.hasKey("app") and cfg["app"].hasKey("cache"):
          "cache_only"
        _: "unknown"
      dbTypes.add(result)

    check dbTypes == @["postgresql", "mysql", "cache_only"]

  test "JsonNode guards with variable binding":
    let userProfiles = @[
      parseJson("""{"name": "Alice", "age": 25, "score": 95}"""),
      parseJson("""{"name": "Bob", "age": 35, "score": 78}"""),
      parseJson("""{"name": "Charlie", "age": 28, "score": 88}""")
    ]

    var qualifiedUsers: seq[string] = @[]
    for profile in userProfiles:
      let result = match profile:
        {"name": name, "age": age, "score": score} and
        age.getInt() <= 30 and score.getInt() >= 85:
          name.getStr() & " (young achiever)"
        {"name": name, "age": age, "score": score} and
        age.getInt() > 30 and score.getInt() >= 85:
          name.getStr() & " (experienced achiever)"
        {"name": name}: name.getStr() & " (standard)"
        _: "unknown"

      if result.contains("achiever"):
        qualifiedUsers.add(result)

    check qualifiedUsers == @["Alice (young achiever)", "Charlie (young achiever)"]

  test "JsonNode guard performance optimization":
    let largeDatasets = @[
      parseJson("""{"type": "small", "data": [1,2,3]}"""),
      parseJson("""{"type": "medium", "data": [1,2,3,4,5]}"""),
      parseJson("""{"type": "large", "data": [1,2,3,4,5,6,7,8,9,10]}""")
    ]

    # Guards should be evaluated efficiently without unnecessary JsonNode operations
    var sizes: seq[string] = @[]
    for dataset in largeDatasets:
      let result = match dataset:
        obj is JsonNode and obj.hasKey("type") and obj.hasKey("data") and
        obj["data"].len < 5: "small"
        obj is JsonNode and obj.hasKey("type") and obj.hasKey("data") and
        obj["data"].len < 10: "medium"
        obj is JsonNode and obj.hasKey("type") and obj.hasKey("data"):
          "large"
        _: "unknown"
      sizes.add(result)

    check sizes == @["small", "medium", "large"]