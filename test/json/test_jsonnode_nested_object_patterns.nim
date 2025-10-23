import unittest
import std/json
import std/tables
import ../../pattern_matching

suite "JsonNode Deep Nested Object Pattern Matching":

  # Category 1: Two-Level Nested Objects
  test "JsonNode two-level nested object":
    let data: JsonNode = parseJson("""
      {
        "user": {
          "name": "Alice",
          "age": 30
        }
      }
    """)

    let result = match data:
      {"user": {"name": name, "age": age}}:
        name.getStr() & " is " & $age.getInt() & " years old"
      _: "no match"
    check result == "Alice is 30 years old"

  # Category 2: Three-Level Deep Nesting
  test "JsonNode three-level deep nesting":
    let config: JsonNode = parseJson("""
      {
        "app": {
          "database": {
            "host": "localhost",
            "port": 5432,
            "credentials": {
              "username": "admin"
            }
          }
        }
      }
    """)

    let result = match config:
      {"app": {"database": {"host": host, "credentials": {"username": user}}}}:
        "Connecting to " & host.getStr() & " as " & user.getStr()
      _: "invalid config"
    check result == "Connecting to localhost as admin"

  # Category 3: Mixed Array-Object Nesting
  test "JsonNode mixed array-object nesting":
    let api: JsonNode = parseJson("""
      {
        "users": [
          {
            "name": "John",
            "profile": {
              "age": 25,
              "city": "NYC"
            }
          }
        ]
      }
    """)

    let result = match api:
      {"users": [{"name": name, "profile": {"age": age, "city": city}}]}:
        name.getStr() & " (" & $age.getInt() & ") from " & city.getStr()
      _: "invalid structure"
    check result == "John (25) from NYC"

  # Category 4: Nested Objects with **rest (FIXED!)
  test "JsonNode nested objects with rest capture":
    let data: JsonNode = parseJson("""
      {
        "user": {
          "id": 123,
          "name": "Bob",
          "email": "bob@test.com",
          "preferences": {
            "theme": "dark",
            "language": "en"
          }
        },
        "timestamp": "2024-01-01"
      }
    """)

    let result = match data:
      {"user": {"name": name, **userRest}, **rootRest}:
        "User " & name.getStr() & " has " & $userRest.len & " user fields and " & $rootRest.len & " root fields"
      _: "no match"
    check result == "User Bob has 3 user fields and 1 root fields"

  # Category 5: Optional Nested Fields
  test "JsonNode optional nested fields":
    let profiles = @[
      parseJson("""{"user": {"name": "Alice", "bio": {"age": 30}}}"""),
      parseJson("""{"user": {"name": "Bob"}}""")  # No bio
    ]

    var results: seq[string] = @[]
    for profile in profiles:
      let result = match profile:
        {"user": {"name": name, "bio": {"age": age}}}:
          name.getStr() & " (" & $age.getInt() & ")"
        {"user": {"name": name}}:
          name.getStr() & " (age unknown)"
        _: "invalid"
      results.add(result)

    check results == @["Alice (30)", "Bob (age unknown)"]

  # Category 6: Complex Nested Path Validation
  test "JsonNode complex nested path validation":
    let validData: JsonNode = parseJson("""
      {
        "response": {
          "data": {
            "items": [
              {
                "product": {
                  "details": {
                    "name": "Widget",
                    "price": 99.99
                  }
                }
              }
            ]
          }
        }
      }
    """)

    let result = match validData:
      {"response": {"data": {"items": [{"product": {"details": {"name": name, "price": price}}}]}}}:
        name.getStr() & " costs $" & $price.getFloat()
      _: "invalid structure"
    check result == "Widget costs $99.99"

  # Category 7: Nested Object Pattern Matching Selection
  test "JsonNode nested object pattern selection":
    let data: JsonNode = parseJson("""
      {
        "config": {
          "values": {
            "count": 42
          }
        }
      }
    """)

    let result = match data:
      {"config": {"settings": {"theme": theme}}}:
        "Found theme: " & theme.getStr()
      {"config": {"values": {"count": count}}}:
        "Found count: " & $count.getInt()
      _: "no valid nested object found"
    check result == "Found count: 42"

  # Category 8: Deep Nesting with Guards
  test "JsonNode deep nesting with guards":
    let order: JsonNode = parseJson("""
      {
        "order": {
          "customer": {
            "name": "Alice",
            "membership": {
              "level": "gold",
              "points": 1500
            }
          },
          "total": 250.0
        }
      }
    """)

    let result = match order:
      {"order": {"customer": {"membership": {"level": level, "points": points}}, "total": total}} and
        level.getStr() == "gold" and points.getInt() >= 1000 and total.getFloat() > 200:
        "Gold member discount applies"
      {"order": {"customer": customer, "total": total}}:
        "Regular pricing"
      _: "invalid order"
    check result == "Gold member discount applies"

  # Category 9: JsonNode Pattern Matching Alternative
  test "JsonNode pattern matching with alternatives":
    let userData: JsonNode = parseJson("""
      {
        "user": {
          "id": 123,
          "role": "admin"
        }
      }
    """)

    let result = match userData:
      {"user": {"name": name}}:
        "Found name: " & name.getStr()
      {"user": {"id": id, "role": role}}:
        "User ID: " & $id.getInt() & ", Role: " & role.getStr()
      _: "no user data"
    check result == "User ID: 123, Role: admin"

  # Category 10: Performance with Deep Structures
  test "JsonNode performance with deep structures":
    # Test with reasonable depth (5 levels) to ensure performance
    let deepData: JsonNode = parseJson("""
      {
        "a": {
          "b": {
            "c": {
              "d": {
                "e": {
                  "value": "deep_value"
                }
              }
            }
          }
        }
      }
    """)

    let result = match deepData:
      {"a": {"b": {"c": {"d": {"e": {"value": value}}}}}}:
        "Found deep value: " & value.getStr()
      _: "not found"
    check result == "Found deep value: deep_value"

  # TODO: Category 11: JsonNode Table Filtering (To be implemented separately)
  # This functionality requires implementing JsonNode table filtering integration
  # which will be addressed after basic nested object patterns are complete