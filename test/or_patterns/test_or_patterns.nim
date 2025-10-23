import unittest
import tables
import options
import ../../pattern_matching

suite "OR Pattern Tests":
  test "should handle simple OR patterns with string literals":
    let cmd1 = "exit"
    let result1 = match cmd1:
      "exit" | "quit" : "Should exit"
      _ : "Continue"
    check(result1 == "Should exit")
    
    let cmd2 = "quit"
    let result2 = match cmd2:
      "exit" | "quit" : "Should exit" 
      _ : "Continue"
    check(result2 == "Should exit")
    
    let cmd3 = "help"
    let result3 = match cmd3:
      "exit" | "quit" : "Should exit"
      _ : "Continue"
    check(result3 == "Continue")

  test "should handle OR patterns with integer literals":
    let num1 = 42
    let result1 = match num1:
      1 | 2 | 42 : "Found number"
      _ : "Other number"
    check(result1 == "Found number")
    
    let num2 = 2
    let result2 = match num2:
      1 | 2 | 42 : "Found number"
      _ : "Other number"
    check(result2 == "Found number")
    
    let num3 = 99
    let result3 = match num3:
      1 | 2 | 42 : "Found number"
      _ : "Other number"
    check(result3 == "Other number")

  test "should handle OR patterns with boolean literals":
    let flag1 = true
    let result1 = match flag1:
      true | false : "Boolean value"
      _ : "Not boolean"
    check(result1 == "Boolean value")

  test "should handle OR patterns with mixed types":
    let mixed1: string = "hello"
    let result1 = match mixed1:
      "hello" | "world" : "Greeting"
      _ : "Other"
    check(result1 == "Greeting")

  test "should handle OR patterns with guards":
    let num1 = 20  # Changed to 20 so it matches the OR pattern
    let result1 = match num1:
      10 | 20 and num1 > 12 : "Big number"
      10 | 20 : "Small number"
      _ : "Other"
    check(result1 == "Big number")
    
    let num2 = 10
    let result2 = match num2:
      10 | 20 and num2 > 12 : "Big number"
      10 | 20 : "Small number"
      _ : "Other"
    check(result2 == "Small number")

  test "should handle nested OR patterns (complex chains)":
    let value = "c"
    let result = match value:
      "a" | "b" | "c" | "d" : "Letter found"
      _ : "Not found"
    check(result == "Letter found")

  test "should handle large OR chains":
    let result = match 25:
      1|2|3|4|5|6|7|8|9|10 : "low"
      11|12|13|14|15|16|17|18|19|20 : "mid"
      21|22|23|24|25|26|27|28|29|30 : "high"
      _ : "out of range"
    check(result == "high")

suite "Complex Nested OR Pattern Tests":
  test "should handle deeply nested OR patterns with groups":
    let val = "c"
    let result = match val:
      ("a" | "b") | ("c" | "d") : "group 1"
      ("e" | "f") | ("g" | "h") : "group 2"
      _ : "other"
    check(result == "group 1")

  test "should handle nested OR with mixed parentheses":
    let num = 42
    let result = match num:
      (10 | 20) | (30 | 40) : "first group"
      (41 | 42) | (43 | 44) : "second group"
      _ : "no match"
    check(result == "second group")

  test "should handle complex OR precedence":
    let value = "test2"
    let result = match value:
      ("test1" | "test2") | ("test3" | "test4") : "test group"
      "other1" | "other2" : "other group"
      _ : "no match"
    check(result == "test group")

suite "Mixed Type OR Pattern Tests":
  test "should handle OR with float types":
    let mixed_float: float = 42.0
    let result = match mixed_float:
      42.0 | 43.0 | 44.0 : "found float in range"
      _ : "other float"
    check(result == "found float in range")

  test "should handle OR with different numeric precision":
    let precise = 3.14159
    let result = match precise:
      3.14 | 3.141 | 3.1416 : "approximation"
      3.14159 : "precise pi"
      _ : "other"
    check(result == "precise pi")

  test "should handle OR with character types":
    let grade = 'B'
    let result = match grade:
      'A' | 'B' | 'C' : "passing grade"
      'D' | 'F' : "failing grade"
      _ : "invalid grade"
    check(result == "passing grade")

suite "Performance OR Chain Tests":
  test "should handle very large OR chains efficiently":
    let target = 75
    let result = match target:
      1|2|3|4|5|6|7|8|9|10|11|12|13|14|15|16|17|18|19|20|
      21|22|23|24|25|26|27|28|29|30|31|32|33|34|35|36|37|38|39|40|
      41|42|43|44|45|46|47|48|49|50|51|52|53|54|55|56|57|58|59|60|
      61|62|63|64|65|66|67|68|69|70|71|72|73|74|75 : "in large range"
      _ : "out of range"
    check(result == "in large range")

  test "should handle OR chains with string literals":
    let command = "compile"
    let result = match command:
      "build"|"compile"|"make"|"construct"|"create"|"generate"|
      "produce"|"assemble"|"synthesize"|"fabricate" : "build command"
      "test"|"check"|"verify"|"validate"|"examine"|"assess" : "test command"
      _ : "other command"
    check(result == "build command")

  test "should handle mixed large OR patterns with guards":
    let score = 85
    let result = match score:
      90|91|92|93|94|95|96|97|98|99|100 : "A grade"
      80|81|82|83|84|85|86|87|88|89 and score >= 80 : "B grade"
      70|71|72|73|74|75|76|77|78|79 : "C grade"
      _ : "below C"
    check(result == "B grade")