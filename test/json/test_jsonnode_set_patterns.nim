import unittest
import sets
import strutils
import ../../pattern_matching
# Import json after pattern_matching to avoid kind ambiguity
from json import JsonNode, JsonNodeKind, JArray, JString, parseJson, getStr, getInt, newJArray, len, items, hasKey, `[]`, getOrDefault
from std/json import kind

# Helper functions for JSON array operations
proc jsonArrayContains(arr: JsonNode, value: string): bool =
  ## Check if JSON array contains a string value
  if arr.kind != JArray:
    return false
  for item in arr.items:
    if item.kind == JString and item.getStr() == value:
      return true
  return false

proc jsonArrayContains(arr: JsonNode, value: int): bool =
  ## Check if JSON array contains an integer value
  if arr.kind != JArray:
    return false
  for item in arr.items:
    if item.kind == json.JInt and item.getInt() == value:
      return true
  return false

proc jsonArraySubset(arr: JsonNode, subset: openArray[string]): bool =
  ## Check if all elements in subset exist in the JSON array
  if arr.kind != JArray:
    return false
  for value in subset:
    if not jsonArrayContains(arr, value):
      return false
  return true

proc jsonArraySubset(arr: JsonNode, subset: openArray[int]): bool =
  ## Check if all elements in subset exist in the JSON array
  if arr.kind != JArray:
    return false
  for value in subset:
    if not jsonArrayContains(arr, value):
      return false
  return true

suite "JsonNode Set Pattern Matching":

  test "JsonNode basic set membership":
    let tags: JsonNode = parseJson("""["web", "api", "json", "nim"]""")

    let result1 = match tags:
      JsonNode(kind == JArray) @ jArr and jsonArrayContains(jArr,"api"): "has api tag"
      #arr is JsonNode and arr.kind == JArray and jsonArrayContains(arr, "api"): "has api tag"
      _: "no api tag"
    check result1 == "has api tag"

    let result2 = match tags:
      arr is JsonNode and arr.kind == JArray and jsonArrayContains(arr, "python"): "has python tag"
      _: "no python tag"
    check result2 == "no python tag"

  test "JsonNode set pattern matching":
    let technologies: JsonNode = parseJson("""["nim", "rust", "go", "python"]""")

    let result = match technologies:
      techs is JsonNode and techs.kind == JArray and jsonArraySubset(techs, ["nim", "rust"]): "has systems languages"
      techs is JsonNode and techs.kind == JArray and jsonArraySubset(techs, ["python", "javascript"]): "has scripting languages"
      _: "other mix"
    check result == "has systems languages"

  test "JsonNode multi-value set tests":
    let features: JsonNode = parseJson("""["async", "memory-safe", "fast", "cross-platform"]""")

    # Test various combinations
    let systemsLanguage = match features:
      f is JsonNode and f.kind == JArray and jsonArraySubset(f, ["memory-safe", "fast"]): true
      _: false
    check systemsLanguage == true

    let webLanguage = match features:
      f is JsonNode and f.kind == JArray and jsonArraySubset(f, ["dom", "browser"]): true
      _: false
    check webLanguage == false

  test "JsonNode set with numeric values":
    let scores: JsonNode = parseJson("[85, 90, 95, 88, 92]")

    let result = match scores:
      s is JsonNode and s.kind == JArray and jsonArraySubset(s, [90, 95]): "has excellent scores"
      s is JsonNode and s.kind == JArray and jsonArraySubset(s, [85, 88]): "has good scores"
      _: "other scores"
    check result == "has excellent scores"

  test "JsonNode mixed type set patterns":
    let mixedData: JsonNode = parseJson("""["active", 42, true, "premium"]""")

    # Note: This is conceptually challenging - mixed types in sets
    # Focus on same-type comparisons for now
    let result = match mixedData:
      data is JsonNode and data.kind == JArray and jsonArrayContains(data, "premium") and jsonArrayContains(data, "active"): "premium active"
      data is JsonNode and data.kind == JArray and jsonArrayContains(data, "active"): "just active"
      _: "other"
    check result == "premium active"

  test "JsonNode empty set patterns":
    let emptyArray: JsonNode = parseJson("[]")
    let singleItem: JsonNode = parseJson("""["only"]""")

    let emptyResult = match emptyArray:
      arr is JsonNode and arr.kind == JArray and arr.len == 0: "empty set"
      _: "not empty"
    check emptyResult == "empty set"

    let singleResult = match singleItem:
      arr is JsonNode and arr.kind == JArray and jsonArraySubset(arr, ["only"]): "has only"
      _: "not only"
    check singleResult == "has only"

  test "JsonNode set operations with guards":
    let tags: JsonNode = parseJson("""["web", "api", "backend", "database", "json"]""")

    let result = match tags:
      t is JsonNode and t.kind == JArray and jsonArraySubset(t, ["web", "api"]) and t.len >= 4: "full stack web"
      t is JsonNode and t.kind == JArray and jsonArraySubset(t, ["database"]) and t.len >= 3: "backend focused"
      t is JsonNode and t.kind == JArray and t.len >= 2: "has multiple tags"
      _: "minimal tags"
    check result == "full stack web"

  test "JsonNode set pattern performance":
    let largeTags: JsonNode = parseJson("""[""" &
      """"tag1", "tag2", "tag3", "tag4", "tag5", """ &
      """"tag6", "tag7", "tag8", "tag9", "tag10", """ &
      """"web", "api", "json", "database", "backend"""" &
      """]""")

    # Should efficiently find subset without scanning entire array multiple times
    let result = match largeTags:
      tags is JsonNode and tags.kind == JArray and jsonArraySubset(tags, ["web", "api", "database"]): "web app stack"
      tags is JsonNode and tags.kind == JArray and jsonArraySubset(tags, ["api", "json"]): "api focused"
      _: "other"
    check result == "web app stack"

  test "JsonNode nested object set patterns":
    let userProfiles: JsonNode = parseJson("""
      [
        {"name": "Alice", "skills": ["nim", "rust", "python"]},
        {"name": "Bob", "skills": ["javascript", "typescript", "node"]}
      ]
    """)

    var systemsProgrammers: seq[string] = @[]
    for profile in userProfiles:
      # Use a simpler approach without guards in object destructuring
      let result = match profile:
        {"name": name, "skills": skills}:
          if skills.kind == JArray and jsonArraySubset(skills, ["nim", "rust"]):
            name.getStr()
          else:
            ""
        _: ""
      if result != "":
        systemsProgrammers.add(result)

    check systemsProgrammers == @["Alice"]

  test "JsonNode set pattern combinations":
    let apiEndpoints: JsonNode = parseJson("""
      {
        "methods": ["GET", "POST", "PUT", "DELETE"],
        "auth": ["bearer", "api-key"],
        "formats": ["json", "xml"]
      }
    """)

    let result = match apiEndpoints:
      {"methods": methods, "auth": auth, "formats": formats}:
        if methods.kind == JArray and auth.kind == JArray and formats.kind == JArray and
           jsonArraySubset(methods, ["GET", "POST"]) and
           jsonArraySubset(auth, ["bearer"]) and
           jsonArraySubset(formats, ["json"]):
          "REST API with JSON and Bearer auth"
        else:
          "partial match"
      {"methods": methods}:
        if methods.kind == JArray and jsonArraySubset(methods, ["GET"]):
          "Read-only API"
        else:
          "no GET"
      _: "Unknown API type"
    check result == "REST API with JSON and Bearer auth"

  test "JsonNode structural matching checks first element only":
    let jsonArray: JsonNode = parseJson("""["api", 42, "web", true, "auth", 3.14]""")
    let first_is_string = match jsonArray:
      [JsonNode(kind == JString), *rest]: true
      _: false
    check first_is_string == true  # First element ("api") is a string

    # To filter all strings, use regular Nim iteration
    var strings: seq[string] = @[]
    for item in jsonArray:
      if item.kind == JString:
        strings.add(item.getStr())
    check strings.len == 3
    check "api" in strings and "web" in strings and "auth" in strings

  test "JsonNode structural matching with complex conditions":
    let endpoints: JsonNode = parseJson("""["api_user", "web_login", "api_auth", "mobile_app", "api_data"]""")
    let first_is_api = match endpoints:
      [JsonNode(getStr().startsWith("api")), *rest]: true
      _: false
    check first_is_api == true  # First element ("api_user") starts with "api"

    # To filter api endpoints, use regular Nim iteration
    var api_endpoints: seq[string] = @[]
    for item in endpoints:
      if item.kind == JString and item.getStr().startsWith("api"):
        api_endpoints.add(item.getStr())
    check api_endpoints.len == 3
    check "api_user" in api_endpoints and "api_auth" in api_endpoints and "api_data" in api_endpoints

  test "JsonNode structural matching with membership conditions":
    let categories: JsonNode = parseJson("""["web", "mobile", "api", "desktop", "auth"]""")
    let first_is_core = match categories:
      [JsonNode(getStr() in ["web", "api", "auth"]), *rest]: true
      _: false
    check first_is_core == true  # First element ("web") is in the core category

    # To filter core categories, use regular Nim iteration
    var core_categories: seq[string] = @[]
    for item in categories:
      if item.kind == JString and item.getStr() in ["web", "api", "auth"]:
        core_categories.add(item.getStr())
    check core_categories.len == 3
    check "web" in core_categories
    check "api" in core_categories
    check "auth" in core_categories