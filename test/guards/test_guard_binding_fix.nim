# Test to reproduce and fix the critical guard pattern binding issue
import unittest
import ../../pattern_matching
import ../helper/ccheck

# Test the specific guard pattern issue: ("loading", "progress", v) and v >= 100
proc handleComplexState(state: string, action: string, value: int): string =
  match (state, action, value):
    ("loading", "progress", v) and v >= 100: 
      "Loading complete: " & $v
    ("loading", "progress", v) and v >= 50: 
      "Loading halfway: " & $v
    ("loading", "progress", v): 
      "Still loading: " & $v
    ("ready", "start", _): 
      "Starting process"
    ("running", "stop", _): 
      "Process stopped"
    ("error", "reset", _): 
      "Reset to initial state"
    _: 
      "Unknown state transition"

# Test another guard binding pattern with tuples
proc testTupleGuardBinding(data: (string, int)): string =
  match data:
    (name, value) and value > 100:
      "High value: " & name & " = " & $value
    (name, value) and value > 0:
      "Positive value: " & name & " = " & $value  
    (name, value):
      "Zero or negative: " & name & " = " & $value

# Test guard binding with simple values
proc testSimpleGuardBinding(x: int): string =
  match x:
    v and v > 100: "Very high: " & $v
    v and v > 0: "Positive: " & $v  
    v and v == 0: "Zero: " & $v
    v: "Negative: " & $v

# Test guard binding with simple values
proc testSimpleGuardBinding_implicit(x: int): string =
  match x:
    v > 100: "Very high: " & $v
    v > 0: "Positive: " & $v  
    v == 0: "Zero: " & $v
    v: "Negative: " & $v

# Test implicit guard binding with simple values
proc testSimpleGuardBinding_implicit_2(x: int): string =
  match x:
    v != 100: "Not 100: " & $v
    v: "Number is 100"

# Test guard binding with string patterns
proc testStringGuardBinding(text: string): string =
  match text:
    s and s.len > 10: "Long string: " & s
    s and s.len > 0: "Short string: " & s
    s: "Empty string: " & s

suite "Guard Pattern Binding (CRITICAL)":

  test "Complex state guard binding works":
    # Test the critical guard pattern case
    check handleComplexState("loading", "progress", 100) == "Loading complete: 100"
    check handleComplexState("loading", "progress", 75) == "Loading halfway: 75"
    check handleComplexState("loading", "progress", 25) == "Still loading: 25"
    
    # Test other state transitions
    check handleComplexState("ready", "start", 0) == "Starting process"
    check handleComplexState("running", "stop", 0) == "Process stopped"
    check handleComplexState("error", "reset", 0) == "Reset to initial state"
    check handleComplexState("unknown", "action", 0) == "Unknown state transition"

  test "Tuple guard binding works":
    # Test tuple guard binding
    check testTupleGuardBinding(("score", 150)) == "High value: score = 150"
    check testTupleGuardBinding(("points", 50)) == "Positive value: points = 50"
    check testTupleGuardBinding(("balance", -10)) == "Zero or negative: balance = -10"
    check testTupleGuardBinding(("count", 0)) == "Zero or negative: count = 0"

  test "Simple guard binding works":
    # Test simple guard binding
    check testSimpleGuardBinding(150) == "Very high: 150"
    check testSimpleGuardBinding(50) == "Positive: 50"
    check testSimpleGuardBinding(0) == "Zero: 0"
    check testSimpleGuardBinding(-10) == "Negative: -10"

  test "Implicit guard binding works":
    check shouldCompile(testSimpleGuardBinding_implicit(5))
    check testSimpleGuardBinding_implicit(5) == "Positive: 5"
    check testSimpleGuardBinding_implicit_2(5) == "Not 100: 5"

  test "String guard binding works":
    # Test string guard binding
    check testStringGuardBinding("This is a very long string") == "Long string: This is a very long string"
    check testStringGuardBinding("Short") == "Short string: Short"
    check testStringGuardBinding("") == "Empty string: "

