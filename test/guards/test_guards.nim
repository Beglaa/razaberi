import unittest
import tables
import options
import ../../pattern_matching
import ../helper/ccheck

suite "OR Guard Tests":
  test "should support 'or' as pattern-guard separator with literals":
    let value = 5
    let result1 = match value:
      10 or value > 3 : "match"
      _ : "no match"
    check(result1 == "match")
    
    let result2 = match value:
      10 or value > 10 : "match"
      _ : "no match"
    check(result2 == "no match")

  test "should support 'or' guards with boolean patterns":
    let value = false
    let result = match value:
      true or value == false : "found boolean"
      _ : "not found"
    check(result == "found boolean")

  test "should support 'or' guards with string patterns":
    let cmd = "help"
    let result = match cmd:
      "exit" or cmd.len < 5 : "short or exit"
      _ : "other"
    check(result == "short or exit")

  test "should combine 'and' and 'or' guards in same match":
    let num = 8
    let result1 = match num:
      10 and num > 5 : "and match"  # won't match: 8 != 10
      5 or num < 10 : "or match"    # will match: 8 < 10  
      _ : "no match"
    check(result1 == "or match")

  test "should handle complex guard expressions with 'or'":
    let val = 15
    let result = match val:
      20 or (val > 10 and val < 20) : "in range"
      _ : "out of range"
    check(result == "in range")

suite "Range Guard Tests":
  test "should support range syntax x in 1..10":
    let value = 5
    let result = match value:
      x and x in 1..10 : "in range"
      _ : "out of range"
    check(result == "in range")
    
    let value2 = 15
    let result2 = match value2:
      x and x in 1..10 : "in range"
      _ : "out of range"
    check(result2 == "out of range")

  test "should support set syntax x in [1, 5, 10]":
    let value = 5
    let result = match value:
      x and x in [1, 5, 10] : "in set"
      _ : "not in set"
    check(result == "in set")
    
    let value2 = 7
    let result2 = match value2:
      x and x in [1, 5, 10] : "in set"
      _ : "not in set"
    check(result2 == "not in set")

  test "should handle empty set (always false)":
    let value = 5
    let result = match value:
      x and x in [] : "impossible"
      _ : "expected"
    check(result == "expected")

  test "should handle single element set":
    let value = 42
    let result = match value:
      x and x in [42] : "found"
      _ : "not found"
    check(result == "found")

  test "should support ranges with OR guards":
    let value = 15
    let result = match value:
      10 or value in 11..20 : "match"
      _ : "no match"
    check(result == "match")

  test "should support string ranges":
    let char = 'm'
    let result = match char:
      c and c in 'a'..'z' : "lowercase"
      _ : "other"
    check(result == "lowercase")

suite "Native Nim Guard Tests":
  test "should support native x.isSome for Option types":
    let opt = some(42)
    let result = match opt:
      x and x.isSome : "has value"
      _ : "no value"
    check(result == "has value")

  test "should support native x.isNone for Option types":
    let opt: Option[int] = none(int)
    let result = match opt:
      x and x.isNone : "no value"
      _ : "has value"  
    check(result == "no value")

  test "should work with native 'is' type checking":
    let value = "test"
    let result = match value:
      x and x is string : "found string"
      _ : "not string"
    check(result == "found string")

  test "Should work with string(x) too":
    let value = "test"
    let result = match value:
      string(x) : "found string"
      _ : "not string"
    check(result == "found string")
    
    let intValue = 42
    let intResult = match intValue:
      x and x is int : "found int"  
      _ : "not int"
    check(intResult == "found int")

  test "should combine native type checks with other guards":
    let opt = some("hello")
    let result = match opt:
      x and (x.isSome and x.get().len > 3) : "long string in Some"
      x and x.isSome : "short string in Some"  
      _ : "None"
    check(result == "long string in Some")

  test "should work with native type checking and ranges":
    let value = 5
    let result = match value:
      x and (x is int and x in 1..10) : "int in range"
      x and x is int : "int out of range"
      _ : "not int"
    check(result == "int in range")

  test "should support complex type checking":
    let floatValue = 3.14
    let result = match floatValue:
      x and x is float : "found float"
      _ : "not float"
    check(result == "found float")

suite "Missing Operator Tests":
  test "should support 'not' logical operator":
    let value = false
    let result1 = match value:
      x and not x : "not false (true)"
      x and x : "is true"
      _ : "other"
    check(result1 == "not false (true)")
    
    let value2 = true
    let result2 = match value2:
      x and not x : "not true (false)"
      x and x : "is true"
      _ : "other"
    check(result2 == "is true")

  test "should support 'not' with complex expressions":
    let num = 5
    let result = match num:
      x and not (x > 10) : "not greater than 10"
      x and x > 10 : "greater than 10"
      _ : "other"
    check(result == "not greater than 10")

  test "should support '!=' inequality operator":
    let value = 5
    let result1 = match value:
      x and x != 10 : "not ten"
      10 : "is ten"
      _ : "other"
    check(result1 == "not ten")
    
    let value2 = 10
    let result2 = match value2:
      x and x != 10 : "not ten"
      10 : "is ten"
      _ : "other"
    check(result2 == "is ten")

  test "should support '!=' with strings":
    let text = "hello"
    let result = match text:
      s and s != "world" : "not world: " & s
      "world" : "is world"
      _ : "other"
    check(result == "not world: hello")

  test "should support '<=' less than or equal operator":
    let value = 10
    let result1 = match value:
      x and x <= 10 : "ten or less"
      x and x > 10 : "greater than ten"
      _ : "other"
    check(result1 == "ten or less")
    
    let value2 = 5
    let result2 = match value2:
      x and x <= 10 : "ten or less"
      x and x > 10 : "greater than ten"
      _ : "other"
    check(result2 == "ten or less")
    
    let value3 = 15
    let result3 = match value3:
      x and x <= 10 : "ten or less"
      x and x > 10 : "greater than ten"
      _ : "other"
    check(result3 == "greater than ten")

  test "should support '>=' greater than or equal operator":
    let value = 10
    let result1 = match value:
      x and x >= 10 : "ten or more"
      x and x < 10 : "less than ten"
      _ : "other"
    check(result1 == "ten or more")
    
    let value2 = 15
    let result2 = match value2:
      x and x >= 10 : "ten or more"
      x and x < 10 : "less than ten"
      _ : "other"
    check(result2 == "ten or more")
    
    let value3 = 5
    let result3 = match value3:
      x and x >= 10 : "ten or more"
      x and x < 10 : "less than ten"
      _ : "other"
    check(result3 == "less than ten")

  test "should combine multiple comparison operators":
    let age = 25
    let result = match age:
      x and (x >= 18 and x <= 65) : "working age"
      x and x < 18 : "minor"
      x and x > 65 : "retirement age"
      _ : "other"
    check(result == "working age")

  test "should combine 'not' with other operators":
    let score = 85
    let result = match score:
      x and (not (x < 60) and x != 100) : "passing grade"
      x and x < 60 : "failing grade"
      100 : "perfect score"
      _ : "other"
    check(result == "passing grade")

suite "Advanced Guard Expression Tests":
  test "should handle string length and character guards":
    let text = "test"
    let result = match text:
      s and s.len > 3 : "long enough string"
      _ : "short string"
    check(result == "long enough string")

  test "should handle character range guards":
    let letter = 'A'
    let result = match letter:
      c and c in 'A'..'Z' : "uppercase letter"
      c and c in 'a'..'z' : "lowercase letter"
      _ : "not a letter"
    check(result == "uppercase letter")

  test "should handle numeric range guards":
    let score = 85
    let result = match score:
      x and x >= 90 : "A grade"
      x and x >= 80 : "B grade"
      x and x >= 70 : "C grade"
      _ : "below C"
    check(result == "B grade")

  test "should handle string membership guards":
    let email = "test@example.com"
    let result = match email:
      addr and '@' in addr : "contains at symbol"
      _ : "no at symbol"
    check(result == "contains at symbol")

  test "should handle sequence length guards":
    let numbers = @[1, 2, 3, 4, 5, 6]
    let result = match numbers:
      nums and nums.len > 5 : "long sequence"
      nums and nums.len > 3 : "medium sequence"
      _ : "short sequence"
    check(result == "long sequence")

  test "should handle array indexing guards":
    let data = @[10, 20, 30]
    let result = match data:
      arr and arr[0] == 10 : "starts with 10"
      _ : "other start"
    check(result == "starts with 10")

  test "should handle modulo operations in guards":
    let number = 144
    let result = match number:
      x and x mod 12 == 0 : "divisible by 12"
      x and x mod 6 == 0 : "divisible by 6"
      _ : "other number"
    check(result == "divisible by 12")

  test "Explicit syntax":
    let temperature, humidity = 31
    let r = match (temperature, humidity):
      # Hot temperatures - ignore humidity
      (t, _) and t > 30:
        "Hot"
      
      # Freezing temperatures - ignore humidity
      (t, _) and t < 0:
        "Freezing"
      
      # High humidity - ignore temperature
      (_, h) and h > 80:
        "Humid"

      # Everything else
      _:
        "Normal"
    check r == "Hot"