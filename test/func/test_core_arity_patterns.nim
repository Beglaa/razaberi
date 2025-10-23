import unittest
import ../../pattern_matching

# ============================================================================
# CORE PATTERN: arity(n) - Parameter Count Matching
# ============================================================================
# Test suite for arity pattern matching according to new specification

# Test functions with different arities
proc nullary(): string = "no params"
proc unary(x: int): int = x * 2
proc binary(a, b: int): int = a + b
proc ternary(x, y, z: int): int = x + y + z
proc quaternary(a, b, c, d: int): int = a + b + c + d
proc manyParams(a, b, c, d, e, f: int): int = a + b + c + d + e + f

suite "Core Pattern: arity(n)":

  test "arity(0) matches nullary functions":
    var result = ""
    match nullary:
      arity(0): result = "nullary"
      _: result = "not nullary"
    check result == "nullary"

  test "arity(1) matches unary functions":
    var result = ""
    match unary:
      arity(1): result = "unary"
      _: result = "not unary"
    check result == "unary"

  test "arity(2) matches binary functions":
    var result = ""
    match binary:
      arity(2): result = "binary"
      _: result = "not binary"
    check result == "binary"

  test "arity(3) matches ternary functions":
    var result = ""
    match ternary:
      arity(3): result = "ternary"
      _: result = "not ternary"
    check result == "ternary"

  test "arity(4) matches quaternary functions":
    var result = ""
    match quaternary:
      arity(4): result = "quaternary"
      _: result = "not quaternary"
    check result == "quaternary"

  test "arity(6) matches functions with many parameters":
    var result = ""
    match manyParams:
      arity(6): result = "six params"
      _: result = "not six params"
    check result == "six params"

  test "arity patterns with fallthrough work":
    var result = ""
    match binary:
      arity(0): result = "zero"
      arity(1): result = "one"
      arity(2): result = "two"
      _: result = "many"
    check result == "two"

  test "arity patterns with multiple arms work":
    var result = ""
    match ternary:
      arity(2): result = "binary"
      arity(3): result = "ternary"
      arity(4): result = "quaternary"
      _: result = "other"
    check result == "ternary"

  test "non-matching arity falls through to wildcard":
    var result = ""
    match manyParams:
      arity(0): result = "zero"
      arity(1): result = "one"
      arity(2): result = "two"
      _: result = "other"
    check result == "other"

  test "arity patterns are exclusive (first match wins)":
    var result = ""
    match binary:
      arity(2): result = "first match"
      arity(2): result = "second match"
      _: result = "no match"
    check result == "first match"
