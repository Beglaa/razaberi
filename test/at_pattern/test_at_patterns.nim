import unittest
import tables
import options
import ../../pattern_matching

suite "@ Pattern Tests":
  test "should handle simple @ pattern with wildcard":
    let result1 = match "hello":
      _ @ value : "Got: " & value
    check(result1 == "Got: hello")
    
    let result2 = match 42:
      _ @ num : "Number: " & $num
    check(result2 == "Number: 42")

  test "should handle @ pattern with literal":
    let result1 = match 42:
      42 @ num : "Found: " & $num
      _ : "Not found"
    check(result1 == "Found: 42")
    
    let result2 = match "hello":
      "hello" @ greeting : "Greeting: " & greeting
      _ : "Not found"
    check(result2 == "Greeting: hello")

  test "should handle @ pattern with OR pattern":
    let result1 = match 42:
      1 | 2 | 42 @ num : "Number: " & $num
      _ : "Other"
    check(result1 == "Number: 42")
    
    let result2 = match "quit":
      "exit" | "quit" @ cmd : "Command: " & cmd
      _ : "Other"
    check(result2 == "Command: quit")

  test "should handle @ pattern with boolean":
    let result1 = match true:
      true @ flag : "Boolean: " & $flag
      _ : "Other"
    check(result1 == "Boolean: true")

  test "should handle @ pattern with guards":
    let result1 = match 20:
      (_ @ num) and num > 10 : "Big: " & $num
      _ @ num : "Small: " & $num
    check(result1 == "Big: 20")
    
    let result2 = match 5:
      (_ @ num) and num > 10 : "Big: " & $num
      _ @ num : "Small: " & $num
    check(result2 == "Small: 5")

  test "should handle mixed @ and regular patterns":
    let result1 = match "hello":
      "goodbye" : "Farewell"
      _ @ value : "Unknown: " & value
    check(result1 == "Unknown: hello")