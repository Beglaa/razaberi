import unittest
import ../../pattern_matching

# ============================================================================
# CORE PATTERN: Compound Patterns (AND, OR, NOT)
# ============================================================================
# Test suite for compound function patterns according to new specification

# Test functions
proc add(a, b: int): int = a + b
proc concat(a, b: string): string = a & b
proc isPositive(x: int): bool = x > 0
proc nullary(): int = 42
proc unary(x: int): int = x * 2

suite "Core Pattern: Compound Patterns":

  test "AND pattern: arity and returns":
    var result = ""
    match add:
      arity(2) and returns(int): result = "binary int function"
      _: result = "not matching"
    check result == "binary int function"

  test "AND pattern: arity and behavior":
    var result = ""
    match add:
      arity(2) and behavior(it(2, 3) == 5): result = "binary addition"
      _: result = "not matching"
    check result == "binary addition"

  test "AND pattern: returns and behavior":
    var result = ""
    match isPositive:
      returns(bool) and behavior(it(5) == true): result = "bool predicate"
      _: result = "not matching"
    check result == "bool predicate"

  test "AND pattern: sync and arity":
    var result = ""
    match nullary:
      sync() and arity(0): result = "sync nullary"
      _: result = "not matching"
    check result == "sync nullary"

  test "OR pattern: arity alternatives":
    var result = ""
    match unary:
      arity(0) or arity(1): result = "nullary or unary"
      _: result = "not matching"
    check result == "nullary or unary"

  test "OR pattern: returns alternatives":
    var result = ""
    match add:
      returns(string) or returns(int): result = "string or int"
      _: result = "not matching"
    check result == "string or int"

  test "NOT pattern: not async means sync":
    var result = ""
    match add:
      not async(): result = "not async"
      _: result = "is async"
    check result == "not async"

  test "NOT pattern: not arity(0)":
    var result = ""
    match add:
      not arity(0): result = "has parameters"
      _: result = "no parameters"
    check result == "has parameters"

  test "Complex compound: (A and B) or C":
    var result = ""
    match add:
      (arity(2) and returns(int)) or arity(0): result = "matched"
      _: result = "not matched"
    check result == "matched"

  test "Complex compound: A and (B or C)":
    var result = ""
    match add:
      arity(2) and (returns(int) or returns(string)): result = "matched"
      _: result = "not matched"
    check result == "matched"

  test "Triple AND pattern":
    var result = ""
    match add:
      arity(2) and returns(int) and sync(): result = "triple match"
      _: result = "not matched"
    check result == "triple match"

  test "Triple OR pattern":
    var result = ""
    match concat:
      returns(int) or returns(bool) or returns(string): result = "one of three"
      _: result = "none"
    check result == "one of three"

  test "Mixed AND/OR pattern":
    var result = ""
    match add:
      (arity(1) and returns(string)) or (arity(2) and returns(int)): result = "complex match"
      _: result = "no match"
    check result == "complex match"

  test "NOT with AND pattern":
    var result = ""
    match add:
      not async() and arity(2): result = "sync binary"
      _: result = "no match"
    check result == "sync binary"

  test "NOT with OR pattern":
    var result = ""
    match add:
      not (arity(0) or arity(1)): result = "not nullary or unary"
      _: result = "is nullary or unary"
    check result == "not nullary or unary"
