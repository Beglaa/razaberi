import unittest
import std/json
import sequtils
import ../../pattern_matching

suite "JsonNode Basic Sequence Patterns":

  # Category 1: Basic Element Matching
  test "JsonNode array literal matching":
    let jsonArr: JsonNode = parseJson("[1, 2, 3]")
    let result = match jsonArr:
      [1, 2, 3]: "exact match"
      _: "no match"
    check result == "exact match"

  test "JsonNode array string literal matching":
    let jsonArr: JsonNode = parseJson("""["hello", "world"]""")
    let result = match jsonArr:
      ["hello", "world"]: "string match"
      _: "no match"
    check result == "string match"

  # Category 2: Variable Binding
  test "JsonNode array variable binding":
    let jsonArr: JsonNode = parseJson("[10, 20, 30]")
    let result = match jsonArr:
      [first, second, third]: first.getInt() + second.getInt() + third.getInt()
      _: 0
    check result == 60

  test "JsonNode array single variable binding":
    let jsonArr: JsonNode = parseJson("[999]")
    let result = match jsonArr:
      [single]: single.getInt()
      _: 0
    check result == 999

  # Category 3: Spread Patterns
  test "JsonNode array spread patterns - head and tail":
    let jsonArr: JsonNode = parseJson("[1, 2, 3, 4, 5]")
    let result = match jsonArr:
      [first, *middle, last]:
        "head=" & $first.getInt() & " tail=" & $last.getInt() & " middle=" & $middle.len
      _: "no match"
    check result == "head=1 tail=5 middle=3"

  test "JsonNode array spread all elements":
    let jsonArr: JsonNode = parseJson("[7, 8, 9]")
    let result = match jsonArr:
      [*all]: all.len
      _: 0
    check result == 3

  # Category 4: Empty Array
  test "JsonNode empty array":
    let jsonArr: JsonNode = parseJson("[]")
    let result = match jsonArr:
      []: "empty"
      _: "not empty"
    check result == "empty"

  # Category 5: Mixed Type Arrays
  test "JsonNode mixed type array":
    let jsonArr: JsonNode = parseJson("""[1, "hello", true, 3.14]""")
    let result = match jsonArr:
      [num, str, flag, floatt]:
        $num.getInt() & "_" & str.getStr() & "_" & $flag.getBool() & "_" & $floatt.getFloat()
      _: "no match"
    check result == "1_hello_true_3.14"

  # Category 6: JsonNode Array Filtering
  test "JsonNode structural matching checks first element only":
    let jsonArr: JsonNode = parseJson("""[1, "hello", 2, "world", true, 3]""")
    let first_is_string = match jsonArr:
      [JsonNode(kind == JString), *rest]: true
      _: false
    check first_is_string == false  # First element (1) is not a string

    # To filter all strings, use regular Nim filter on the array
    let all_strings = jsonArr.elems.toSeq.filter(proc(x: JsonNode): bool = x.kind == JString)
    check all_strings.len == 2

  test "JsonNode structural matching with numeric conditions":
    let numbers: JsonNode = parseJson("[1, 15, 3, 25, 8, 30]")
    let first_is_large = match numbers:
      [JsonNode(getInt() > 10), *rest]: true
      _: false
    check first_is_large == false  # First element (1) is not > 10

    # To filter large numbers, use regular Nim filter
    let large_numbers = numbers.elems.toSeq.filter(proc(x: JsonNode): bool = x.getInt() > 10)
    check large_numbers.len == 3