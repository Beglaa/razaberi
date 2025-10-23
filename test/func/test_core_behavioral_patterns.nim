import unittest
import ../../pattern_matching

# ============================================================================
# CORE PATTERN: behavior(test) - Behavioral Testing
# ============================================================================
# Test suite for behavioral pattern matching according to new specification

# Test functions with different behaviors
proc add(a, b: int): int = a + b
proc multiply(a, b: int): int = a * b
proc square(x: int): int = x * x
proc isEven(n: int): bool = n mod 2 == 0
proc alwaysTrue(): bool = true
proc identity(x: int): int = x
proc constant42(): int = 42
proc stringLen(s: string): int = s.len

suite "Core Pattern: behavior(test)":

  test "behavior pattern with simple arithmetic works":
    var result = ""
    match add:
      behavior(it(2, 3) == 5): result = "addition"
      _: result = "not addition"
    check result == "addition"

  test "behavior pattern with multiplication works":
    var result = ""
    match multiply:
      behavior(it(3, 4) == 12): result = "multiplication"
      _: result = "not multiplication"
    check result == "multiplication"

  test "behavior pattern with single argument works":
    var result = ""
    match square:
      behavior(it(5) == 25): result = "square function"
      _: result = "not square"
    check result == "square function"

  test "behavior pattern with boolean return works":
    var result = ""
    match isEven:
      behavior(it(4) == true): result = "even checker"
      _: result = "not even checker"
    check result == "even checker"

  test "behavior pattern with no arguments works":
    var result = ""
    match alwaysTrue:
      behavior(it() == true): result = "always true"
      _: result = "not always true"
    check result == "always true"

  test "behavior pattern with identity function works":
    var result = ""
    match identity:
      behavior(it(42) == 42): result = "identity"
      _: result = "not identity"
    check result == "identity"

  test "behavior pattern with constant function works":
    var result = ""
    match constant42:
      behavior(it() == 42): result = "constant 42"
      _: result = "not constant 42"
    check result == "constant 42"

  test "behavior pattern with string input works":
    var result = ""
    match stringLen:
      behavior(it("test") == 4): result = "string length"
      _: result = "not string length"
    check result == "string length"

  test "behavior pattern with complex condition works":
    var result = ""
    match add:
      behavior(it(1, 1) == 2 and it(0, 5) == 5): result = "proper addition"
      _: result = "not proper addition"
    check result == "proper addition"

  test "behavior pattern with wrong expectation falls through":
    var result = ""
    match add:
      behavior(it(2, 3) == 6): result = "wrong"
      behavior(it(2, 3) == 5): result = "correct"
      _: result = "no match"
    check result == "correct"

  test "behavior pattern with multiple tests":
    var result = ""
    match isEven:
      behavior(it(2) == true and it(3) == false): result = "even/odd checker"
      _: result = "not checker"
    check result == "even/odd checker"

  test "behavior pattern exception handling":
    # Function that might throw
    proc divBy(x: int): int =
      if x == 0:
        raise newException(DivByZeroDefect, "division by zero")
      return 10 div x

    var result = ""
    match divBy:
      behavior(it(0) == 0): result = "matched zero"  # Should catch exception
      behavior(it(2) == 5): result = "matched non-zero"
      _: result = "no match"
    check result == "matched non-zero"
