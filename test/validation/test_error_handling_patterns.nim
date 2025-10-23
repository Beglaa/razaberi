# Test error handling patterns (lines 337-351 from pm_use_cases.md)
import unittest
import ../../pattern_matching
import options, strutils

# Simple Result type for error handling demonstrations
type
  ResultKind = enum
    Success, Failure
  
  SimpleResult = object
    case kind: ResultKind
    of Success:
      value: int
    of Failure:
      error: string

# Test 1: Basic error handling with pattern matching on result types
proc processResult(res: SimpleResult): string =
  case res.kind:
  of Success:
    let val = res.value
    if val > 0:
      "Success: positive value " & $val
    elif val == 0:
      "Success: zero value"
    else:
      "Success: negative value " & $val
  of Failure:
    "Error: " & res.error

# Test 2: Exception-like handling with tuple patterns (lines 344-351)
proc safeDivide(a, b: float): (bool, float, string) =
  match (a, b):
    (_, 0.0): 
      (false, 0.0, "Division by zero")
    (0.0, _): 
      (true, 0.0, "")
    (x, y): 
      (true, x / y, "")

# Test 3: Option type error handling with pattern matching
proc processOption(opt: Option[int]): string =
  match opt.isSome:
    true:
      let value = opt.get()
      if value > 0:
        "Positive value: " & $value
      elif value == 0:
        "Zero value"
      else:
        "Negative value: " & $value
    false:
      "No value"

# Test 4: Error handling with status codes
proc handleStatusCode(code: int, message: string): string =
  match code:
    200: "Success: " & message
    404: "Not found: " & message
    500: "Server error: " & message
    c and c >= 400: 
      if c < 500:
        "Client error " & $c & ": " & message
      else:
        "Server error " & $c & ": " & message
    _: "Unknown status " & $code & ": " & message

# Test 5: Error propagation with nested conditions
proc processData(data: (string, int)): (bool, string) =
  match data:
    ("", _): 
      (false, "Empty string not allowed")
    (_, n) and n < 0: 
      (false, "Negative numbers not allowed")
    (s, 0): 
      (false, "Zero value with string: " & s)
    (s, n) and s.len > 10: 
      (false, "String too long")
    (s, n): 
      (true, "Valid data: " & s & " = " & $n)

# Test 6: Error handling with type checking patterns
proc safeStringToInt(s: string): (bool, int, string) =
  match s:
    "": (false, 0, "Empty string")
    str: 
      try:
        let num = parseInt(str)
        (true, num, "")
      except:
        (false, 0, "Invalid number format")

# Test 7: Validation patterns with guards
proc validateInput(input: (string, string, int)): string =
  match input:
    ("", _, _): 
      "Error: Name cannot be empty"
    (_, "", _): 
      "Error: Email cannot be empty"
    (name, email, age) and age < 0: 
      "Error: Age cannot be negative"
    (name, email, age) and age > 150: 
      "Error: Age too high"
    (name, email, _) and not ("@" in email): 
      "Error: Invalid email format"
    (name, email, age): 
      "Valid: " & name & " (" & email & "), age " & $age

# Test 8: Error boundary patterns
proc handleError(errorCode: int, context: string): string =
  match (errorCode, context):
    (0, _): "No error"
    (c, "network") and c in [1, 2, 3]: "Network error " & $c
    (c, "database") and c in [10, 11, 12]: "Database error " & $c
    (c, "validation") and c in [100, 101, 102]: "Validation error " & $c
    (c, ctx): "Unknown error " & $c & " in " & ctx

suite "Error Handling Patterns":

  test "Basic error handling works":
    let successResult = SimpleResult(kind: Success, value: 42)
    let failureResult = SimpleResult(kind: Failure, error: "Something went wrong")
    let zeroResult = SimpleResult(kind: Success, value: 0)
    let negativeResult = SimpleResult(kind: Success, value: -5)
    
    check processResult(successResult) == "Success: positive value 42"
    check processResult(failureResult) == "Error: Something went wrong"
    check processResult(zeroResult) == "Success: zero value"
    check processResult(negativeResult) == "Success: negative value -5"

  test "Exception-like handling works":
    # Test division by zero
    let (success1, result1, error1) = safeDivide(10.0, 0.0)
    check not success1
    check error1 == "Division by zero"
    
    # Test zero dividend
    let (success2, result2, error2) = safeDivide(0.0, 5.0)
    check success2
    check result2 == 0.0
    check error2 == ""
    
    # Test normal division
    let (success3, result3, error3) = safeDivide(10.0, 2.0)
    check success3
    check result3 == 5.0
    check error3 == ""

  test "Option type error handling works":
    check processOption(some(5)) == "Positive value: 5"
    check processOption(some(0)) == "Zero value"
    check processOption(some(-3)) == "Negative value: -3"
    check processOption(none(int)) == "No value"

  test "Status code error handling works":
    check handleStatusCode(200, "OK") == "Success: OK"
    check handleStatusCode(404, "Page not found") == "Not found: Page not found"
    check handleStatusCode(500, "Internal error") == "Server error: Internal error"
    check handleStatusCode(403, "Forbidden") == "Client error 403: Forbidden"
    check handleStatusCode(502, "Bad gateway") == "Server error 502: Bad gateway"
    check handleStatusCode(999, "Unknown") == "Server error 999: Unknown"

  test "Error propagation works":
    # Test valid data
    check processData(("hello", 5)) == (true, "Valid data: hello = 5")
    
    # Test error cases
    check processData(("", 5)) == (false, "Empty string not allowed")
    check processData(("hello", -1)) == (false, "Negative numbers not allowed")
    check processData(("test", 0)) == (false, "Zero value with string: test")
    check processData(("verylongstring", 5)) == (false, "String too long")

  test "Safe string to int conversion works":
    # Test valid conversions
    let (success1, val1, err1) = safeStringToInt("42")
    check success1 and val1 == 42 and err1 == ""
    
    let (success2, val2, err2) = safeStringToInt("-10")
    check success2 and val2 == -10 and err2 == ""
    
    # Test error cases
    let (success3, val3, err3) = safeStringToInt("")
    check not success3 and err3 == "Empty string"
    
    let (success4, val4, err4) = safeStringToInt("abc")
    check not success4 and err4 == "Invalid number format"

  test "Input validation works":
    # Test valid input
    check validateInput(("John", "john@example.com", 25)) == "Valid: John (john@example.com), age 25"
    
    # Test validation errors
    check validateInput(("", "john@example.com", 25)) == "Error: Name cannot be empty"
    check validateInput(("John", "", 25)) == "Error: Email cannot be empty"
    check validateInput(("John", "john@example.com", -5)) == "Error: Age cannot be negative"
    check validateInput(("John", "john@example.com", 200)) == "Error: Age too high"
    check validateInput(("John", "invalid-email", 25)) == "Error: Invalid email format"

  test "Error boundary patterns work":
    check handleError(0, "any") == "No error"
    check handleError(1, "network") == "Network error 1"
    check handleError(10, "database") == "Database error 10"
    check handleError(100, "validation") == "Validation error 100"
    check handleError(999, "unknown") == "Unknown error 999 in unknown"