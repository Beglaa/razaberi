import unittest
import ../../pattern_matching
import json, tables

# Type aliases that test structural query approach
# These should ALL work after the fix
type
  Json = JsonNode  # Doesn't contain "JsonNode" substring
  MyData = JsonNode  # Doesn't contain "JsonNode" substring
  MyJsonNode = JsonNode  # Contains "JsonNode" substring (worked before too)
  StringMap = Table[string, string]  # Test Table alias
  MyTable = Table[string, string]  # Test Table alias

type
  User = object
    name: string
    id: int
    age: int
    city: string
    active: bool
    score: float
    tags: seq[string]

suite "Rest Pattern Type Alias Fix - BUG PM-3":
  test "rest pattern with 'Json' type alias - should work after fix":
    let tom = User(
      name: "Tom",
      id: 1,
      age: 30,
      city: "NYC",
      active: true,
      score: 9.5,
      tags: @["vip", "premium"]
    )

    # This should work now with structural queries
    let result = match tom:
      User(name: "Tom", **rest: Json):
        "Tom with " & $rest.len & " extra fields"
      _: "No match"

    check result == "Tom with 6 extra fields"

  test "rest pattern with 'MyData' type alias - should work after fix":
    let tom = User(
      name: "Tom",
      id: 1,
      age: 30,
      city: "NYC",
      active: true,
      score: 9.5,
      tags: @["vip", "premium"]
    )

    # This should work now with structural queries
    let result = match tom:
      User(name: "Tom", **rest: MyData):
        "Tom with " & $rest.len & " extra fields"
      _: "No match"

    check result == "Tom with 6 extra fields"

  test "rest pattern with 'MyJsonNode' type alias - should continue working":
    let tom = User(
      name: "Tom",
      id: 1,
      age: 30,
      city: "NYC",
      active: true,
      score: 9.5,
      tags: @["vip", "premium"]
    )

    # This worked before and should continue working
    let result = match tom:
      User(name: "Tom", **rest: MyJsonNode):
        "Tom with " & $rest.len & " extra fields"
      _: "No match"

    check result == "Tom with 6 extra fields"

  test "rest pattern with 'StringMap' Table alias - should work":
    let tom = User(
      name: "Tom",
      id: 1,
      age: 30,
      city: "NYC",
      active: true,
      score: 9.5,
      tags: @["vip", "premium"]
    )

    # Table alias should work with structural queries
    let result = match tom:
      User(name: "Tom", **rest: StringMap):
        "Tom with " & $rest.len & " extra fields"
      _: "No match"

    check result == "Tom with 6 extra fields"

  test "rest pattern with 'MyTable' Table alias - should work":
    let tom = User(
      name: "Tom",
      id: 1,
      age: 30,
      city: "NYC",
      active: true,
      score: 9.5,
      tags: @["vip", "premium"]
    )

    # Table alias should work with structural queries
    let result = match tom:
      User(name: "Tom", **rest: MyTable):
        "Tom with " & $rest.len & " extra fields"
      _: "No match"

    check result == "Tom with 6 extra fields"

  test "rest pattern - extract and access fields from Json alias":
    let tom = User(
      name: "Tom",
      id: 1,
      age: 30,
      city: "NYC",
      active: true,
      score: 9.5,
      tags: @["vip", "premium"]
    )

    # Should be able to access fields in JsonNode rest
    let result = match tom:
      User(name: "Tom", **rest: Json):
        let ageVal = rest["age"].getInt()
        let cityVal = rest["city"].getStr()
        $ageVal & "-" & cityVal
      _: "No match"

    check result == "30-NYC"

  test "rest pattern - extract and access fields from StringMap alias":
    let tom = User(
      name: "Tom",
      id: 1,
      age: 30,
      city: "NYC",
      active: true,
      score: 9.5,
      tags: @["vip", "premium"]
    )

    # Should be able to access fields in Table rest
    let result = match tom:
      User(name: "Tom", **rest: StringMap):
        let cityVal = rest["city"]
        cityVal
      _: "No match"

    check result == "NYC"

  test "rest pattern - multiple fields extracted with type alias":
    let tom = User(
      name: "Tom",
      id: 1,
      age: 30,
      city: "NYC",
      active: true,
      score: 9.5,
      tags: @["vip", "premium"]
    )

    # Extract specific fields and rest
    let result = match tom:
      User(name: "Tom", age: a, **rest: Json):
        $a & "-" & $rest.len
      _: "No match"

    check result == "30-5"  # age extracted, 5 remaining fields

  test "rest pattern - qualified JsonNode should work":
    let tom = User(
      name: "Tom",
      id: 1,
      age: 30,
      city: "NYC",
      active: true,
      score: 9.5,
      tags: @["vip", "premium"]
    )

    # Qualified names should work with structural queries
    let result = match tom:
      User(name: "Tom", **rest: json.JsonNode):
        "Tom with " & $rest.len & " extra fields"
      _: "No match"

    check result == "Tom with 6 extra fields"
