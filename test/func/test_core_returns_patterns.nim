import unittest
import ../../pattern_matching

# ============================================================================
# CORE PATTERN: returns(Type) - Return Type Matching
# ============================================================================
# Test suite for return type pattern matching according to new specification

# Test functions with different return types
proc returnsInt(): int = 42
proc returnsString(): string = "hello"
proc returnsBool(): bool = true
proc returnsFloat(): float = 3.14
proc returnsVoid() = discard
proc returnsSeq(): seq[int] = @[1, 2, 3]

suite "Core Pattern: returns(Type)":

  test "returns(int) matches integer-returning functions":
    var result = ""
    match returnsInt:
      returns(int): result = "returns int"
      _: result = "not int"
    check result == "returns int"

  test "returns(string) matches string-returning functions":
    var result = ""
    match returnsString:
      returns(string): result = "returns string"
      _: result = "not string"
    check result == "returns string"

  test "returns(bool) matches boolean-returning functions":
    var result = ""
    match returnsBool:
      returns(bool): result = "returns bool"
      _: result = "not bool"
    check result == "returns bool"

  test "returns(float) matches float-returning functions":
    var result = ""
    match returnsFloat:
      returns(float): result = "returns float"
      _: result = "not float"
    check result == "returns float"

  test "returns patterns with fallthrough work":
    var result = ""
    match returnsString:
      returns(int): result = "int"
      returns(string): result = "string"
      returns(bool): result = "bool"
      _: result = "other"
    check result == "string"

  test "returns patterns with multiple arms work":
    var result = ""
    match returnsBool:
      returns(int): result = "int"
      returns(string): result = "string"
      returns(bool): result = "bool"
      _: result = "other"
    check result == "bool"

  test "non-matching return type falls through to wildcard":
    var result = ""
    match returnsFloat:
      returns(int): result = "int"
      returns(string): result = "string"
      returns(bool): result = "bool"
      _: result = "other"
    check result == "other"

  test "returns patterns are exclusive (first match wins)":
    var result = ""
    match returnsInt:
      returns(int): result = "first match"
      returns(int): result = "second match"
      _: result = "no match"
    check result == "first match"

  test "returns patterns with complex types work":
    var result = ""
    match returnsSeq:
      returns(seq[int]): result = "seq of int"
      _: result = "not seq"
    check result == "seq of int"
