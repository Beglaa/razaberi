import unittest
import json
import ../../pattern_matching

# Test suite for JSON pattern matching with implicit type detection
# Automatic JSON support when JsonNode types are used

suite "JSON Pattern Matching - Implicit Type Detection":

    test "Basic JsonNode scrutinee detection":
      let apiData: JsonNode = parseJson("""{"name": "Tom", "age": 30, "city": "Paris"}""")

      let result = match apiData:
        {"name": "Tom", **rest}:  # Should automatically detect JsonNode and create JsonNode rest
          "Tom with " & $rest.len & " extra fields"
        _: "No match"

      check result == "Tom with 2 extra fields"

    test "JsonNode **rest field access":
      let userData: JsonNode = parseJson("""{"id": 1, "name": "Alice", "role": "Designer", "active": true}""")

      let result = match userData:
        {"name": "Alice", **rest}:
          let roleFromRest = rest["role"].getStr()
          let activeFromRest = rest["active"].getBool()
          "Alice is " & roleFromRest & ", active: " & $activeFromRest
        _: "No match"

      check result == "Alice is Designer, active: true"

    test "JsonNode all fields in **rest":
      let simpleData: JsonNode = parseJson("""{"x": 10, "y": 20, "z": 30}""")

      let result = match simpleData:
        {"x": _, "y": _, "z": _, **rest}:  # All fields captured explicitly, rest should be empty
          "Captured " & $rest.len & " fields"
        _: "No match"

      check result == "Captured 0 fields"

    test "JsonNode **rest captures remaining fields":
      let moreData: JsonNode = parseJson("""{"name": "Test", "id": 123, "active": true, "score": 95.5}""")

      let result = match moreData:
        {"name": _, **rest}:  # name captured, rest should have remaining fields
          "Captured " & $rest.len & " fields"
        _: "No match"

      check result == "Captured 3 fields"

    test "JsonNode mixed extraction with specific fields":
      let configData: JsonNode = parseJson("""{"host": "localhost", "port": 8080, "debug": true, "ssl": false}""")

      let result = match configData:
        {"host": "localhost", "port": port, **options}:
          "Server " & $port.getInt() & " with " & $options.len & " options"
        _: "Invalid config"

      check result == "Server 8080 with 2 options"

    test "JsonNode **rest with nested objects":
      let nestedData: JsonNode = parseJson("""
        {
          "user": "John",
          "profile": {"age": 30, "city": "NYC"},
          "settings": {"theme": "dark", "lang": "en"},
          "lastLogin": "2024-01-01"
        }
      """)

      let result = match nestedData:
        {"user": userName, **metadata}:
          userName.getStr() & " has " & $metadata.len & " metadata fields"
        _: "No match"

      check result == "John has 3 metadata fields"

    test "JsonNode **rest serialization readiness":
      let apiResponse: JsonNode = parseJson("""{"status": 200, "message": "Success", "timestamp": "2024-01-01T10:00:00Z"}""")

      let result = match apiResponse:
        {"status": 200, **responseData}:
          # JsonNode rest is already JSON-ready
          let jsonString = $responseData
          "Response ready for forwarding: " & (if jsonString.len > 10: "yes" else: "no")
        _: "Error response"

      check result == "Response ready for forwarding: yes"

    test "JsonNode array handling in **rest":
      let dataWithArray: JsonNode = parseJson("""{"name": "Project", "tags": ["web", "api"], "created": "2024-01-01"}""")

      let result = match dataWithArray:
        {"name": "Project", **extra}:
          # Should handle arrays in rest
          let hasTags = extra.hasKey("tags")
          let hasCreated = extra.hasKey("created")
          $hasTags & "-" & $hasCreated
        _: "No match"

      check result == "true-true"

    test "JsonNode empty **rest when all fields extracted":
      let smallData: JsonNode = parseJson("""{"id": 123, "name": "Test"}""")

      let result = match smallData:
        {"id": id, "name": name, **rest}:
          "ID: " & $id.getInt() & ", Name: " & name.getStr() & ", Rest: " & $rest.len
        _: "No match"

      check result == "ID: 123, Name: Test, Rest: 0"

    test "JsonNode **rest with guard conditions":
      let userData: JsonNode = parseJson("""{"age": 25, "name": "Bob", "score": 95, "active": true}""")

      let result = match userData:
        {"age": age, **rest} and age.getInt() >= 18: 
          "Adult with " & $rest.len & " additional properties"
        {"age": age, **rest} and age.getInt() < 18:
          "Minor with " & $rest.len & " additional properties"
        _: "No age data"

      check result == "Adult with 3 additional properties"

    test "JsonNode **rest performance with JSON":
      # Test performance with larger JSON objects
      let largeData: JsonNode = parseJson("""{"id": 1, "name": "Alice", "age": 30, "city": "NYC", "country": "USA", "job": "Engineer", "salary": 75000, "active": true, "email": "alice@example.com", "phone": "+1234567890"}""")

      let result = match largeData:
        {"name": name, "age": age, **rest}:
          "Found " & name.getStr() & " age " & $age.getInt() & " with " & $rest.len & " other fields"
        _: "No match"

      check result == "Found Alice age 30 with 8 other fields"

suite "JSON Pattern Matching - API Use Cases":

    test "Webhook payload processing":
      # Test realistic webhook JSON processing
      let webhook: JsonNode = parseJson("""{"event": "user.created", "timestamp": 1640995200, "data": {"user_id": 12345, "email": "user@example.com"}, "source": "api", "version": "1.0"}""")

      let result = match webhook:
        {"event": event, "data": data, **metadata}:
          event.getStr() & " with " & $metadata.len & " metadata fields"
        _: "Unknown webhook format"

      check result == "user.created with 3 metadata fields"

    test "Configuration API response":
      # Test config API JSON with nested structure
      let config: JsonNode = parseJson("""{
        "database": {"host": "localhost", "port": 5432},
        "redis": {"host": "redis.example.com", "port": 6379},
        "debug": true,
        "environment": "production"
      }""")

      let result = match config:
        {"environment": env, "debug": debug, **services}:
          env.getStr() & " mode, debug=" & $debug.getBool() & ", " & $services.len & " services"
        _: "Invalid config"

      check result == "production mode, debug=true, 2 services"

    test "GraphQL-like response processing":
      # Test GraphQL-style nested JSON response
      let response: JsonNode = parseJson("""{
        "data": {
          "user": {"id": "123", "name": "Bob", "posts": [1, 2, 3]}
        },
        "errors": null,
        "extensions": {"tracing": {"version": 1}}
      }""")

      let result = match response:
        {"data": data, **meta}:
          "GraphQL response with data and " & $meta.len & " meta fields"
        _: "Invalid GraphQL response"

      check result == "GraphQL response with data and 2 meta fields"

    test "Microservice communication":
      # Test microservice message format
      let message: JsonNode = parseJson("""{
        "service": "user-service",
        "operation": "get_profile",
        "payload": {"user_id": 456},
        "correlation_id": "abc-123",
        "timestamp": 1640995200
      }""")

      let result = match message:
        {"service": service, "operation": op, **context}:
          service.getStr() & ":" & op.getStr() & " (" & $context.len & " context fields)"
        _: "Invalid message format"

      check result == "user-service:get_profile (3 context fields)"

suite "JSON Pattern Matching - Error Handling":

    test "Malformed JSON object handling":
      # Test handling of edge cases in JSON pattern matching
      let emptyObj: JsonNode = parseJson("{}")
      let singleField: JsonNode = parseJson("{\"key\": \"value\"}")

      let result1 = match emptyObj:
        emptyObj and emptyObj.len == 0: "Empty object with 0 fields"
        _: "No match"

      let result2 = match singleField:
        {"key": value, **rest}: "Found key with " & $rest.len & " other fields"
        _: "No match"

      check result1 == "Empty object with 0 fields"
      check result2 == "Found key with 0 other fields"

    test "JsonNode type safety in **rest access":
      # Test type-safe access to **rest JsonNode fields
      let data: JsonNode = parseJson("{\"name\": \"Alice\", \"age\": 30, \"active\": true}")

      let result = match data:
        {"name": name, **rest}:
          # Verify rest contains the expected fields with proper types
          if rest.hasKey("age") and rest.hasKey("active"):
            "Rest contains age and active fields"
          else:
            "Missing expected fields in rest"
        _: "No match"

      check result == "Rest contains age and active fields"

# Compile-time feature detection tests
suite "JSON Pattern Matching - Infrastructure":

  test "JSON infrastructure availability":
    # Test that JSON pattern matching infrastructure works correctly
    let simple: JsonNode = parseJson("{\"test\": \"value\"}")

    let result = match simple:
      {"test": value, **rest}:
        "JSON infrastructure working: " & value.getStr() & ", rest=" & $rest.len
      _: "JSON infrastructure failed"

    check result == "JSON infrastructure working: value, rest=0"