import unittest
import ../../pattern_matching

## Tests for OR patterns with implicit guards (val and val > X) | (val and val < Y)
##
## This tests the fix for the bug where OR patterns containing guards like:
##   (val and val > 100) | (val and val < 50)
## were incorrectly generating code that matched everything.
##
## Root cause: processOrPattern wasn't extracting guards from alternatives
## Fix: Extract guards using flattenNestedAndPattern and substitute variables

suite "OR Patterns with Implicit Guards":

  # ============================================================================
  # BASIC TESTS - Core functionality
  # ============================================================================

  test "Basic: OR pattern with guards - match first alternative":
    let value = 150
    let result = match value:
      (val and val > 100) | (val and val < 50):
        "matched: " & $val
      _:
        "no match"
    check result == "matched: 150"

  test "Basic: OR pattern with guards - match second alternative":
    let value = 30
    let result = match value:
      (val and val > 100) | (val and val < 50):
        "matched: " & $val
      _:
        "no match"
    check result == "matched: 30"

  test "Basic: OR pattern with guards - no match":
    let value = 75
    let result = match value:
      (val and val > 100) | (val and val < 50):
        "matched: " & $val
      _:
        "no match"
    check result == "no match"

  # ============================================================================
  # EDGE CASES - Boundary testing
  # ============================================================================

  test "Edge case: Boundary value exactly at first threshold":
    let value = 100
    let result = match value:
      (val and val > 100) | (val and val < 50):
        "matched"
      _:
        "no match"
    check result == "no match"  # 100 is not > 100

  test "Edge case: Boundary value exactly at second threshold":
    let value = 50
    let result = match value:
      (val and val > 100) | (val and val < 50):
        "matched"
      _:
        "no match"
    check result == "no match"  # 50 is not < 50

  test "Edge case: Just above first threshold":
    let value = 101
    let result = match value:
      (val and val > 100) | (val and val < 50):
        "matched: " & $val
      _:
        "no match"
    check result == "matched: 101"

  test "Edge case: Just below second threshold":
    let value = 49
    let result = match value:
      (val and val > 100) | (val and val < 50):
        "matched: " & $val
      _:
        "no match"
    check result == "matched: 49"

  # ============================================================================
  # OPERATOR VARIATIONS - Different comparison operators
  # ============================================================================

  test "Operator: >= and <=":
    let value = 100
    let result = match value:
      (val and val >= 100) | (val and val <= 10):
        "matched: " & $val
      _:
        "no match"
    check result == "matched: 100"

  test "Operator: < and >":
    let value = 0
    let result = match value:
      (val and val < 10) | (val and val > 90):
        "matched: " & $val
      _:
        "no match"
    check result == "matched: 0"

  test "Operator: == comparisons in OR":
    let value = 42
    let result = match value:
      (val and val == 42) | (val and val == 100):
        "matched: " & $val
      _:
        "no match"
    check result == "matched: 42"

  test "Operator: != comparisons in OR":
    let value = 50
    let result = match value:
      (val and val != 42) | (val and val == 0):
        "matched: " & $val
      _:
        "no match"
    check result == "matched: 50"

  # ============================================================================
  # MULTIPLE ALTERNATIVES - More than 2 OR branches
  # ============================================================================

  test "Three alternatives with guards":
    let value1 = 5
    let result1 = match value1:
      (val and val < 10) | (val and val > 90) | (val and val == 50):
        "matched: " & $val
      _:
        "no match"
    check result1 == "matched: 5"

    let value2 = 95
    let result2 = match value2:
      (val and val < 10) | (val and val > 90) | (val and val == 50):
        "matched: " & $val
      _:
        "no match"
    check result2 == "matched: 95"

    let value3 = 50
    let result3 = match value3:
      (val and val < 10) | (val and val > 90) | (val and val == 50):
        "matched: " & $val
      _:
        "no match"
    check result3 == "matched: 50"

  test "Four alternatives with different guards":
    let value = 1
    let result = match value:
      (val and val == 1) | (val and val == 10) | (val and val == 100) | (val and val == 1000):
        "matched: " & $val
      _:
        "no match"
    check result == "matched: 1"

  # ============================================================================
  # CHAINED GUARDS - Multiple conditions in single alternative
  # ============================================================================

  test "Chained guards: Multiple AND conditions":
    let value = 75
    let result = match value:
      (val and val > 50 and val < 80) | (val and val > 200):
        "matched: " & $val
      _:
        "no match"
    check result == "matched: 75"

  test "Chained guards: Complex conditions":
    let value = 42
    let result = match value:
      (val and val > 10 and val < 50 and val != 30) | (val and val == 100):
        "matched: " & $val
      _:
        "no match"
    check result == "matched: 42"

  # ============================================================================
  # TYPE VARIATIONS - Different data types
  # ============================================================================

  test "Float values with guards":
    let value = 3.14
    let result = match value:
      (val and val > 3.0) | (val and val < 1.0):
        "matched: " & $val
      _:
        "no match"
    check result == "matched: 3.14"

  test "Negative numbers":
    let value = -50
    let result = match value:
      (val and val < -40) | (val and val > 40):
        "matched: " & $val
      _:
        "no match"
    check result == "matched: -50"

  test "String length comparisons":
    let text = "hello"
    let result = match text:
      (val and val.len > 10) | (val and val.len < 10):
        "matched length: " & $val.len
      _:
        "no match"
    check result == "matched length: 5"

  # ============================================================================
  # REAL-WORLD USE CASES
  # ============================================================================

  test "Real-world: Temperature range classification":
    proc classifyTemp(temp: int): string =
      match temp:
        (t and t < 0) | (t and t > 100):
          "extreme"
        (t and t < 15) | (t and t > 30):
          "uncomfortable"
        _:
          "comfortable"

    check classifyTemp(-5) == "extreme"
    check classifyTemp(105) == "extreme"
    check classifyTemp(5) == "uncomfortable"
    check classifyTemp(35) == "uncomfortable"
    check classifyTemp(20) == "comfortable"

  test "Real-world: HTTP status code classification":
    proc classifyStatus(code: int): string =
      match code:
        (c and c >= 200 and c < 300) | (c and c == 304):
          "success"
        (c and c >= 400 and c < 500) | (c and c >= 500):
          "error"
        _:
          "other"

    check classifyStatus(200) == "success"
    check classifyStatus(304) == "success"
    check classifyStatus(404) == "error"
    check classifyStatus(500) == "error"
    check classifyStatus(304) == "success"

  test "Real-world: Age group classification":
    proc classifyAge(age: int): string =
      match age:
        (a and a < 13) | (a and a > 65):
          "special rate"
        a and a >= 13 and a <= 17:
          "teen"
        _:
          "adult"

    check classifyAge(10) == "special rate"
    check classifyAge(70) == "special rate"
    check classifyAge(15) == "teen"
    check classifyAge(30) == "adult"

  # ============================================================================
  # MIXED WITH OTHER PATTERNS
  # ============================================================================

  test "Mixed: OR guards with wildcard":
    let value = 150
    let result = match value:
      (val and val > 100) | (val and val < 50):
        "in range: " & $val
      _:
        "middle range"
    check result == "in range: 150"

  test "Mixed: Multiple match arms with guards":
    let value = 25
    let result = match value:
      val and val < 10:
        "very small"
      (val and val > 10 and val < 50) | (val and val > 100):
        "in range"
      _:
        "other"
    check result == "in range"

  # ============================================================================
  # REGRESSION TESTS - Ensure fix doesn't break existing functionality
  # ============================================================================

  test "Regression: Simple OR without guards still works":
    let value = 42
    let result = match value:
      10 | 20 | 42:
        "matched"
      _:
        "no match"
    check result == "matched"

  test "Regression: Variable binding without OR still works":
    let value = 150
    let result = match value:
      val and val > 100:
        "large: " & $val
      _:
        "small"
    check result == "large: 150"

  test "Regression: Guard without parentheses works":
    let value = 150
    let result = match value:
      val and val > 100:
        "matched: " & $val
      _:
        "no match"
    check result == "matched: 150"
