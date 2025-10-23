import unittest
import tables
import options
import ../../pattern_matching

suite "Advanced Sequence Pattern Tests":
  test "should handle spread at beginning [*initial, last]":
    let items = @[1, 2, 3, 4, 5]
    let result = match items:
      [*initial, last] : "Initial: " & $initial.len & ", Last: " & $last
      _ : "No match"
    check(result == "Initial: 4, Last: 5")

  test "should handle spread in middle [first, *middle, last]":
    let items = @["a", "b", "c", "d", "e"]
    let result = match items:
      [first, *middle, last] : "First: " & first & ", Middle: " & $middle.len & ", Last: " & last
      _ : "No match"
    check(result == "First: a, Middle: 3, Last: e")

  test "should handle multiple elements after spread":
    let items = @[1, 2, 3, 4, 5, 6]
    let result = match items:
      [first, *middle, second_last, last] : 
        "First: " & $first & ", Middle: " & $middle.len & ", SecondLast: " & $second_last & ", Last: " & $last
      _ : "No match"
    check(result == "First: 1, Middle: 3, SecondLast: 5, Last: 6")

  test "should handle literal prefix with spread [1,2,*rest]":
    let items = @[1, 2, 3, 4, 5, 6]
    let result = match items:
      [1, 2, *rest] : "Found [1,2] prefix, rest: " & $rest
      _ : "No match"
    check(result == "Found [1,2] prefix, rest: @[3, 4, 5, 6]")

  test "should handle spread with minimum length requirements":
    let short_list = @[1, 2]
    let result1 = match short_list:
      [a, b] : "Exact two elements"
      [first, *middle, last] : "Matched"
      _ : "No match"
    check(result1 == "Exact two elements")
    
    let exact_min = @[1, 2, 3]
    let result2 = match exact_min:
      [first, *middle, last] : "First: " & $first & ", Middle: " & $middle.len & ", Last: " & $last
      _ : "No match"
    check(result2 == "First: 1, Middle: 1, Last: 3")

  test "should handle empty middle spread":
    let items = @["start", "end"]
    let result = match items:
      [first, *middle, last] : "Middle empty: " & $(middle.len == 0)
      _ : "No match"
    check(result == "Middle empty: true")

  test "should handle spread at beginning with multiple after elements":
    let items = @[10, 20, 30, 40, 50]
    let result = match items:
      [*initial, third_last, second_last, last] : 
        "Initial: " & $initial.len & ", ThirdLast: " & $third_last & ", SecondLast: " & $second_last & ", Last: " & $last
      _ : "No match"
    check(result == "Initial: 2, ThirdLast: 30, SecondLast: 40, Last: 50")

  test "should handle Python-style pattern [_, _, *_] for at least 2 elements":
    # Test with exactly 2 elements
    let two_items = @[1, 2]
    let result1 = match two_items:
      [_, _, *_] : "Has at least 2 elements"
      _ : "Less than 2 elements"
    check(result1 == "Has at least 2 elements")
    
    # Test with more than 2 elements  
    let many_items = @[1, 2, 3, 4, 5]
    let result2 = match many_items:
      [_, _, *_] : "Has at least 2 elements"
      _ : "Less than 2 elements"
    check(result2 == "Has at least 2 elements")
    
    # Test with less than 2 elements
    let one_item = @[42]
    let result3 = match one_item:
      [_, _, *_] : "Has at least 2 elements"
      _ : "Less than 2 elements"
    check(result3 == "Less than 2 elements")
    
    # Test with empty list
    let empty: seq[int] = @[]
    let result4 = match empty:
      [_, _, *_] : "Has at least 2 elements"
      _ : "Less than 2 elements"
    check(result4 == "Less than 2 elements")

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

suite "Head/Tail Array Destructuring Tests":
  
  test "should match head and tail destructuring pattern":
    let numbers = @[1, 2, 3, 4, 5]
    let result = match numbers:
      [head, *tail] : "Head: " & $head & ", Tail: " & $tail
      [] : "Empty list"
      _ : "No match"
    check(result == "Head: 1, Tail: @[2, 3, 4, 5]")

  test "should match multiple head elements with tail":
    let items = @["a", "b", "c", "d", "e"]
    let result = match items:
      [first, second, *rest] : "First: " & first & ", Second: " & second & ", Rest: " & $rest.len
      [single] : "Single item"
      [] : "Empty"
      _ : "No match"
    check(result == "First: a, Second: b, Rest: 3")

  test "should handle head/tail with single element":
    let single = @[42]
    let result = match single:
      [head, *tail] : "Head: " & $head & ", Tail empty: " & $(tail.len == 0)
      [] : "Empty list"
      _ : "No match"
    check(result == "Head: 42, Tail empty: true")

  test "should handle head/tail with empty list":
    let empty: seq[int] = @[]
    let result = match empty:
      [head, *tail] : "Not empty"
      [] : "Empty list"
      _ : "No match"
    check(result == "Empty list")

  test "should combine head/tail with literal matching":
    let data = @[10, 20, 30, 40]
    let result = match data:
      [10, *tail] : "Starts with 10, tail: " & $tail
      _ : "Other"
    check(result == "Starts with 10, tail: @[20, 30, 40]")
    
    let big_data = @[60, 70, 80]
    let result2 = match big_data:
      [10, *tail] : "Starts with 10, tail: " & $tail
      [head, *tail] : "Start with " & $head & ", tail: " & $tail
      _ : "Other"
    check(result2 == "Start with 60, tail: @[70, 80]")

  test "should handle nested head/tail destructuring":
    let matrix = @[@[1, 2, 3], @[4, 5], @[6]]
    let result = match matrix:
      [first_row, *other_rows] : 
        "First row: " & $first_row & ", Other rows: " & $other_rows.len
      [] : "No rows"
      _ : "No match"
    check(result == "First row: @[1, 2, 3], Other rows: 2")

  test "should handle head/tail with guards":
    let scores = @[95, 87, 92, 78, 89]
    let result = match scores:
      [best, *rest] : "Score: " & $best & ", others: " & $rest.len
      [] : "No scores"
      _ : "No match"
    check(result == "Score: 95, others: 4")

  test "should handle complex head/tail patterns":
    let mixed = @[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    let result = match mixed:
      [a, b, c, *rest] : 
        "Three head elements: " & $a & "," & $b & "," & $c & ", rest: " & $rest.len
      [a, b, *rest] : "Two head elements"
      [single] : "Single element"
      [] : "Empty"
      _ : "No match"
    check(result == "Three head elements: 1,2,3, rest: 7")

  test "should match traditional head/tail pattern (first and rest)":
    let sequence = @["start", "middle", "end"]
    let result = match sequence:
      ["start", "middle", "end"] : "Perfect sequence"
      ["start", *tail] : "Starts right, tail: " & $tail.len
      [head, *tail] : "Other sequence"
      _ : "No match"
    check(result == "Perfect sequence")

  test "should handle last element extraction":
    let data = @[10, 20, 30, 40, 50]
    let result = match data:
      [*init, last] : "Init: " & $init.len & " elements, Last: " & $last
      [] : "Empty"
      _ : "No match"  
    check(result == "Init: 4 elements, Last: 50")

  test "should handle both head and tail extraction":
    let values = @[100, 200, 300, 400, 500, 600]
    let result = match values:
      [first, *middle, last] : 
        "First: " & $first & ", Middle: " & $middle.len & ", Last: " & $last
      [first, last] : "Just two elements"
      _ : "Other pattern"
    check(result == "First: 100, Middle: 4, Last: 600")

  test "should handle simple tuple patterns":
    let simple = (1, 2, 3, 4)
    let result = match simple:
      (a, b, c, d) : a + b + c + d
      _ : 0
    check(result == 10)
  
  test "should handle large lists with spread":
    let big_list = @[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    let result = match big_list:
      [first, *middle, last] : first + last + middle.len
    check(result == 19) # 1 + 10 + 8

suite "Performance and Edge Case Tests":
  test "should handle large OR chains":
    let result = match 25:
      1|2|3|4|5|6|7|8|9|10 : "low"
      11|12|13|14|15|16|17|18|19|20 : "mid"
      21|22|23|24|25|26|27|28|29|30 : "high"
      _ : "out of range"
    check(result == "high")
  
  test "should handle simple tuple patterns":
    let simple = (1, 2, 3, 4)
    let result = match simple:
      (a, b, c, d) : a + b + c + d
      _ : 0
    check(result == 10)
  
  test "should handle large lists with spread":
    let big_list = @[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    let result = match big_list:
      [first, *middle, last] : first + last + middle.len
    check(result == 19) # 1 + 10 + 8