import unittest
import ../../pattern_matching
import std/tables
import std/options

# Test suite for Default Value Patterns feature
# Tests table, sequence, and class pattern destructuring with default values

suite "Default Value Patterns":

  test "Basic table patterns":
    # Basic table matching without defaults
    let config1 = {"host": "localhost", "port": "8080"}.toTable
    let result1 = match config1:
      {"host": host, "port": port} : "Host: " & host & ", Port: " & port
      _ : "No match"
    
    check result1 == "Host: localhost, Port: 8080"
  
  test "Table patterns with fallback":
    # Table with optional fields using multiple patterns
    let config2 = {"debug": "true", "timeout": "30"}.toTable
    let result2 = match config2:
      {"debug": debug, "timeout": timeout, "retries": retries} :
        "Debug: " & debug & ", Timeout: " & timeout & ", Retries: " & retries
      {"debug": debug, "timeout": timeout} :
        "Debug: " & debug & ", Timeout: " & timeout & ", Retries: default(3)"
      {"debug": debug} :
        "Debug: " & debug & ", Timeout: default(30), Retries: default(3)"
      _ : "No match"
    
    check result2 == "Debug: true, Timeout: 30, Retries: default(3)"

  test "Basic sequence defaults":
    # Basic sequence with default for missing elements
    let coords1 = @[10, 20]
    let result1 = match coords1:
      [x, y, z = 0] : "Position: (" & $x & ", " & $y & ", " & $z & ")"
      _ : "No match"
    
    check result1 == "Position: (10, 20, 0)"
  
  test "Multiple sequence defaults":
    # Multiple defaults at end
    let coords2 = @[5]
    let result2 = match coords2:
      [x, y = 10, z = 15] : "Point: (" & $x & ", " & $y & ", " & $z & ")"
      _ : "No match"
    
    check result2 == "Point: (5, 10, 15)"
  
  test "Sequence defaults ignored when elements present":
    # All elements present (no defaults used)
    let values1 = @[1, 2, 3]
    let result3 = match values1:
      [first, second, third = 99] :
        "Values: " & $first & ", " & $second & ", " & $third
      _ : "No match"
    
    check result3 == "Values: 1, 2, 3"

  test "Basic class patterns":
    type
      User = object
        name: string
        email: Option[string]
        age: Option[int]
        verified: Option[bool]
    
    # Basic object pattern matching
    let user1 = User(name: "Alice", email: some("alice@test.com"), age: some(30), verified: some(true))
    let result1 = match user1:
      User(name=n, email=e, age=a, verified=v) :
        "Name: " & n & ", Email: " & $e & ", Age: " & $a & ", Verified: " & $v
      _ : "No match"
    
    check result1 == "Name: Alice, Email: some(\"alice@test.com\"), Age: some(30), Verified: some(true)"
  
  test "Class patterns with None values":
    type
      User = object
        name: string
        email: Option[string]
        age: Option[int]
        verified: Option[bool]
    
    # Pattern with None values
    let user2 = User(name: "Bob", email: none(string), age: none(int), verified: none(bool))
    let result2 = match user2:
      User(name=n, email=e, age=a, verified=v) :
        "Name: " & n & ", Email: " & $e & ", Age: " & $a & ", Verified: " & $v
      _ : "No match"
    
    check result2 == "Name: Bob, Email: none(string), Age: none(int), Verified: none(bool)"

  test "Configuration processing with consistent = defaults":
    let serverConfig = {
      "host": "localhost",
      "database_type": "postgresql"
    }.toTable
    
    let result = match serverConfig:
      {"host": (host = "127.0.0.1"), "database_type": (dbType = "sqlite"), "port": (port = "5432")} :
        "Server: " & host & ":" & port & " DB: " & dbType
      _ : "Invalid config"
    
    check result == "Server: localhost:5432 DB: postgresql"

  test "Empty table with consistent = defaults":
    # Empty table handling with new = defaults syntax
    let empty = initTable[string, string]()
    let result1 = match empty:
      {"key1": (k1 = "default1"), "key2": (k2 = "default2")} :
        "K1: " & k1 & ", K2: " & k2
      _ : "No match"
    
    check result1 == "K1: default1, K2: default2"
    
    # Also test the old fallthrough behavior still works
    let result2 = match empty:
      {"key1": k1, "key2": k2} :
        "Without defaults: K1: " & k1 & ", K2: " & k2
      _ : "Empty table - no match without defaults"
    
    check result2 == "Empty table - no match without defaults"
  
  test "Short sequence with multiple defaults":
    # Sequence shorter than pattern with defaults
    let short = @[42]
    let result2 = match short:
      [a, b = 10, c = 20, d = 30] :
        "Values: " & $a & ", " & $b & ", " & $c & ", " & $d
      _ : "No match"
    
    check result2 == "Values: 42, 10, 20, 30"

  test "Empty sequence with all defaults":
    # Test with empty sequence and all defaults
    let empty: seq[int] = @[]
    let result1 = match empty:
      [x = 1, y = 2] : "Both defaults: " & $x & "," & $y
      _ : "No match"
    
    check result1 == "Both defaults: 1,2"
  
  test "Mixed pattern with partial defaults":
    # Test mixed pattern
    let oneElem = @[99]
    let result2 = match oneElem:
      [x = 1, y = 2] : "Mixed: " & $x & "," & $y
      _ : "No match"
    
    check result2 == "Mixed: 99,2"

  test "Sequence defaults with guards (guard passes)":
    # Test guard passes
    let values1 = @[5]
    let result1 = match values1:
      [x, y = 10] and x > 3 :
        "X is big: " & $x & ", Y defaulted: " & $y
      [x, y = 20] :
        "X is small: " & $x & ", Y defaulted: " & $y  
      _ : "No match"
    
    check result1 == "X is big: 5, Y defaulted: 10"
  
  test "Sequence defaults with guards (guard fails)":
    # Test guard fails
    let values2 = @[2]
    let result2 = match values2:
      [x, y = 10] and x > 3 :
        "X is big: " & $x & ", Y defaulted: " & $y
      [x, y = 20] :
        "X is small: " & $x & ", Y defaulted: " & $y  
      _ : "No match"
    
    check result2 == "X is small: 2, Y defaulted: 20"

