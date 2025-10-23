import unittest
import tables
import options
import ../../pattern_matching

suite "Basic Pattern Matching Tests":

  test "should match integer literals":
    let result = match 42:
      10 : "ten"
      42 : "forty-two"
      _  : "other"
    check(result == "forty-two")

  test "should match string literals":
    let result = match "nim":
      "rust" : "crab"
      "nim"  : "crown"
      _      : "unknown"
    check(result == "crown")

  test "should match boolean literals":
    let result = match true:
      false : "is false"
      true  : "is true"
    check(result == "is true")

  test "should use wildcard for unmatched cases":
    let result = match 100:
      1 : "one"
      2 : "two"
      _ : "something else"
    check(result == "something else")
    
  test "should bind value to a variable":
    let result = match 123:
      42 : -1
      y  : y
    check(result == 123)

  test "should handle mixed patterns correctly":
    let result = match "test":
      "hello" : "greeting"
      s       : "bound: " & s
    check(result == "bound: test")
  
  test "should handle variable hygiene":
    let result = match 10:
      x : x
    let finalResult = match 20:
      x : x + result
    check(finalResult == 30)

  test "should handle guards with capture variable":
    let commands = ["help", "exit"]
    let result = match "help":
      cmd and cmd in commands : "known"
      _ : "unknown"
    check(result == "known")

    let result2 = match "other":
      cmd and cmd in commands : "known"
      _ : "unknown"
    check(result2 == "unknown")

  test "should handle tuple patterns":
    let t = (1, "hello")
    let result = match t:
      (1, "world") : "no"
      (x, y) : "yes: " & $x & ", " & y
    check(result == "yes: " & $t[0] & ", " & t[1])

suite "Character Pattern Tests":
  test "should match single character literals":
    let ch = 'A'
    let result = match ch:
      'A' : "found A"
      'B' : "found B"
      _ : "other char"
    check(result == "found A")

  test "should match character ranges in guards":
    let digit = '5'
    let result = match digit:
      c and c in '0'..'9' : "digit: " & $c
      c and c in 'A'..'Z' : "uppercase"
      _ : "other"
    check(result == "digit: 5")

  test "should match lowercase character ranges":
    let letter = 'm'
    let result = match letter:
      c and c in 'a'..'z' : "lowercase: " & $c
      c and c in 'A'..'Z' : "uppercase: " & $c
      _ : "not letter"
    check(result == "lowercase: m")

  test "should match uppercase character ranges":
    let letter = 'Q'
    let result = match letter:
      c and c in 'a'..'z' : "lowercase: " & $c
      c and c in 'A'..'Z' : "uppercase: " & $c
      _ : "not letter"
    check(result == "uppercase: Q")

suite "Float Pattern Tests":
  test "should match float literals exactly":
    let val = 3.14
    let result = match val:
      3.14 : "pi"
      2.71 : "e"
      _ : "other"
    check(result == "pi")

  test "should use float guards with ranges":
    let temp = 36.7
    let result = match temp:
      t and (t >= 36.0 and t <= 37.5) : "normal body temp"
      t and t > 37.5 : "fever"
      _ : "hypothermia"
    check(result == "normal body temp")

  test "should handle float comparison guards":
    let price = 19.99
    let result = match price:
      p and p < 10.0 : "cheap"
      p and (p >= 10.0 and p < 50.0) : "moderate"
      p and p >= 50.0 : "expensive"
      _ : "invalid"
    check(result == "moderate")

suite "Unicode and Special Character Tests":
  test "should handle Unicode characters in patterns":
    let unicode_str = "café"
    let result = match unicode_str:
      "café" : "coffee in French"
      _ : "not coffee"
    check(result == "coffee in French")

  test "should handle emoji patterns":
    let emoji = "👋"
    let result = match emoji:
      "👋" : "waving hand"
      "😀" : "grinning face"
      _ : "other emoji"
    check(result == "waving hand")

  test "should handle mixed Unicode strings":
    let mixed = "Hello 世界"
    let result = match mixed:
      "Hello 世界" : "mixed script greeting"
      s and s.len > 5 : "long string"
      _ : "other"
    check(result == "mixed script greeting")

  test "should handle special ASCII character literals":
    let special_char = '@'
    let result = match special_char:
      '@' : "at symbol"
      '#' : "hash symbol"
      _ : "other symbol"
    check(result == "at symbol")