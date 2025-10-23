import unittest
import tables
import ../../pattern_matching

{.push hint[XDeclaredButNotUsed]: off.}

suite "Advanced Pattern Matching Tests":
  
  test "should match table/dict patterns":
    let data = {"name": "Alice", "age": "25"}.toTable
    let result = match data:
      {"name": name, "age": age} : "Person: " & name & ", age: " & age
      _ : "unknown"
    check(result == "Person: Alice, age: 25")

  test "should match nested table patterns (simplified)":
    let data = {"user": {"name": "Bob", "id": "123"}.toTable}.toTable
    let result = match data:
      {"user": userinfo} : "Got user data with " & $userinfo.len & " fields"
      _ : "no match"
    check(result == "Got user data with 2 fields")

  test "should handle table with literal matching":
    let config = {"debug": "true", "port": "8080"}.toTable
    let result = match config:
      {"debug": "true", "port": port} : "Debug enabled, port: " & port
      {"debug": "false", "port": port} : "Debug disabled, port: " & port
      _ : "invalid config"
    check(result == "Debug enabled, port: 8080")

  test "should match list/seq patterns":
    let items = @["hello", "world", "nim"]
    let result = match items:
      ["hello", "world", "nim"] : "exact match"
      _ : "no match"
    check(result == "exact match")

  test "should handle list patterns with literals":
    let numbers = @[1, 2, 3]
    let result = match numbers:
      [1, 2, 3] : "exact match"
      [1, 2] : "partial match"
      _ : "no match"
    check(result == "exact match")

  test "should handle empty list patterns":
    let empty: seq[int] = @[]
    let result = match empty:
      [] : "empty list"
      _ : "not empty"
    check(result == "empty list")

  test "should handle type constraints":
    let value: int = 42
    let result = match value:
      x and x is int : "Integer: " & $x
      _ : "not an integer"
    check(result == "Integer: 42")

  test "should handle string type constraints":
    let text: string = "hello"
    let result = match text:
      s and s is string : "String: " & s
      _ : "not a string"
    check(result == "String: hello")

  test "should handle complex nested patterns (simplified)":
    let headers = {"content-type": "application/json"}.toTable
    let request = {"method": "POST", "headers": "json"}.toTable
    let data = {"request": request}.toTable
    
    let result = match data:
      {"request": requestInfo} : "Got request with " & $requestInfo.len & " fields"
      _ : "no match"
    check(result == "Got request with 2 fields")

  test "should handle table patterns with guards":
    let user = {"name": "Alice", "age": "25"}.toTable
    let result = match user:
      {"name": name, "age": age} and name.len > 3 : "Long name: " & name
      {"name": name, "age": age} : "Short name: " & name
      _ : "no match"
    check(result == "Long name: Alice")

  test "should handle simple list destructuring":
    let scores = @[95, 87, 92]
    let result = match scores:
      [95, 87, 92] : "exact scores match"
      _ : "no match"
    check(result == "exact scores match")

  test "should handle **rest capture in tables":
    let data = {"name": "Alice", "age": "25", "city": "NYC", "country": "USA"}.toTable
    let result = match data:
      {"name": name, "age": age, **rest} : 
        "Person: " & name & " (" & age & "), Extra: " & $rest.len & " fields"
      _ : "No match"
    check(result == "Person: Alice (25), Extra: 2 fields")

  test "should handle **rest with single matched key":
    let config = {"debug": "true", "timeout": "30", "retries": "3"}.toTable
    let result = match config:
      {"debug": debug_mode, **other_settings} : 
        "Debug: " & debug_mode & ", Other settings: " & $other_settings.len
      _ : "No match"
    check(result == "Debug: true, Other settings: 2")

  test "should handle **rest with no remaining keys":
    let simple = {"x": "10", "y": "20"}.toTable
    let result = match simple:
      {"x": x_val, "y": y_val, **rest} : 
        "Coords: (" & x_val & ", " & y_val & "), Rest empty: " & $(rest.len == 0)
      _ : "No match"
    check(result == "Coords: (10, 20), Rest empty: true")

  test "should handle **rest with wildcard patterns":
    let data = {"key1": "val1", "key2": "val2", "key3": "val3"}.toTable
    let result = match data:
      {"key1": _, **remaining} : "Found key1, remaining: " & $remaining.len
      _ : "No match"
    check(result == "Found key1, remaining: 2")

suite "New Use Cases from NewUseCases.md":
  
  test "should handle **rest capture in tables":
    let data = {"name": "Alice", "age": "25", "city": "NYC", "country": "USA"}.toTable
    let result = match data:
      {"name": name, "age": age, **rest} : 
        "Person: " & name & " (" & age & "), Extra: " & $rest.len & " fields"
      _ : "No match"
    check(result == "Person: Alice (25), Extra: 2 fields")

  test "should handle **rest with single matched key":
    let config = {"debug": "true", "timeout": "30", "retries": "3"}.toTable
    let result = match config:
      {"debug": debug_mode, **other_settings} : 
        "Debug: " & debug_mode & ", Other settings: " & $other_settings.len
      _ : "No match"
    check(result == "Debug: true, Other settings: 2")

  test "should handle **rest with no remaining keys":
    let simple = {"x": "10", "y": "20"}.toTable
    let result = match simple:
      {"x": x_val, "y": y_val, **rest} : 
        "Coords: (" & x_val & ", " & y_val & "), Rest empty: " & $(rest.len == 0)
      _ : "No match"
    check(result == "Coords: (10, 20), Rest empty: true")

  test "should handle **rest with wildcard patterns":
    let data = {"key1": "val1", "key2": "val2", "key3": "val3"}.toTable
    let result = match data:
      {"key1": _, **remaining} : "Found key1, remaining: " & $remaining.len
      _ : "No match"
    check(result == "Found key1, remaining: 2")

  test "should handle sequence patterns with literal elements and spread":
    let commands = @["git", "commit", "-m", "fix: resolve issue", "--verbose"]
    let result = match commands:
      ["git", "commit", "-m", message, *flags] : 
        "Commit: " & message & ", Flags: " & $flags.len
      ["git", "push", *args] : "Push with args: " & $args.len
      _ : "Unknown command"
    check(result == "Commit: fix: resolve issue, Flags: 1")

  test "should handle alternating patterns in sequences":
    let pairs = @[1, 2, 3, 4, 5, 6]
    let result = match pairs:
      [a, b, c, d, e, f] and pairs.len == 6 : "Six elements"
      [*_] and pairs.len mod 2 == 0 : "Even number of elements"
      _ : "Other"
    check(result == "Six elements")

suite "Empty Container Edge Cases":
  test "should handle empty table patterns":
    let empty_table = initTable[string, string]()
    let result = match empty_table:
      table and table.len == 0 : "empty table"
      _ : "not empty"
    check(result == "empty table")

  test "should handle empty sequence with head/tail":
    let empty: seq[int] = @[]
    let result = match empty:
      [] : "empty sequence"
      [head, *tail] : "has head"
      _ : "other"
    check(result == "empty sequence")

  test "should handle empty table vs non-empty":
    let non_empty = {"key": "value"}.toTable
    let result1 = match non_empty:
      table and table.len == 0 : "empty"
      _ : "has content"
    check(result1 == "has content")
    
    let empty = initTable[string, string]()
    let result2 = match empty:
      table and table.len == 0 : "empty"
      _ : "has content"
    check(result2 == "empty")

  test "should handle minimum length sequence patterns":
    let too_short = @[1]
    let result1 = match too_short:
      [a, b] : "two elements"
      [a] : "one element"
      [] : "empty"
      _ : "other"
    check(result1 == "one element")
    
    let just_right = @[1, 2]
    let result2 = match just_right:
      [a, b] : "two elements"
      [a] : "one element"
      [] : "empty"
      _ : "other"
    check(result2 == "two elements")

  test "should handle edge case with spread requiring minimum elements":
    let minimal = @[1, 2, 3]
    let result = match minimal:
      [first, *middle, last] : "First: " & $first & ", Middle: " & $middle.len & ", Last: " & $last
      [a, b] : "just two"
      _ : "other"
    check(result == "First: 1, Middle: 1, Last: 3")