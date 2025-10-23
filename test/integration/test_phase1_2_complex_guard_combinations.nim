import unittest
import std/strutils
import ../../pattern_matching

suite "PHASE 1.2: Complex Guard Combinations with Cross-Referencing @ Patterns":
  # These are the missing test cases from FUTURE_ENHANCEMENTS.md
  # Testing complex guard combinations with cross-referencing @ patterns

  
  test "String manipulation with @ pattern guards":
    # Target: (["hello"] @ greet, [x] @ name) and greet[0].startsWith("h") and name[0].len > 3
    let testData = (["hello"], ["world"]) 
    
    let result = match testData:
      ([greetStr] @ greet, [nameStr] @ name) and greet[0].startsWith("h") and name[0].len > 3 :
        "String match: " & greet[0] & " -> " & name[0]
      ([greetStr] @ greet, [nameStr] @ name) :
        "Basic match: " & greet[0] & " -> " & name[0]
      _ : "no match"
    
    check result == "String match: hello -> world"
  
  test "String manipulation guards - Partial match":
    # Test where only first condition matches
    let testData = (["hello"], ["hi"])
    
    let result = match testData:
      ([greetStr] @ greet, [nameStr] @ name) and greet[0].startsWith("h") and name[0].len > 3 :
        "Full string match"
      ([greetStr] @ greet, [nameStr] @ name) and greet[0].startsWith("h") :
        "Partial string match: " & greet[0] & " (name too short: " & name[0] & ")"
      ([greetStr] @ greet, [nameStr] @ name) :
        "Basic match: " & greet[0] & " -> " & name[0]
      _ : "no match"
    
    check result == "Partial string match: hello (name too short: hi)"