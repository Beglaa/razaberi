# Test type-based patterns (lines 174-192 from pm_use_cases.md)
import unittest
import ../../pattern_matching
import std/strutils

suite "Type-Based Patterns":

  test "String type patterns work":
    proc testString(s: string): string =
      match s:
        x is string: 
          if x.len == 0: "Empty string" 
          else: "String: " & x.toUpperAscii
    
    check testString("") == "Empty string"
    check testString("hello") == "String: HELLO"

  test "Integer type patterns work":
    proc testInt(i: int): string =
      match i:
        x is int: 
          if x > 0: "Positive integer: " & $x 
          else: "Non-positive integer: " & $x
    
    check testInt(42) == "Positive integer: 42"
    check testInt(-5) == "Non-positive integer: -5" 
    check testInt(0) == "Non-positive integer: 0"

  test "Boolean type patterns work":
    proc testBool(b: bool): string =
      match b:
        x is bool: 
          if x: "True value" 
          else: "False value"
    
    check testBool(true) == "True value"
    check testBool(false) == "False value"

  test "Float type patterns work":
    proc testFloat(f: float): string =
      match f:
        x is float: 
          if x > 0.0: "Positive float: " & $x 
          else: "Non-positive float: " & $x
    
    check testFloat(3.14) == "Positive float: 3.14"
    check testFloat(-2.5) == "Non-positive float: -2.5"

  test "Sequence type patterns work":
    proc testSeq(s: seq[int]): string =
      match s:
        x is seq[int]: 
          if x.len == 0: "Empty sequence" 
          else: "Non-empty sequence with " & $x.len & " items"
    
    check testSeq(@[]) == "Empty sequence"
    check testSeq(@[1, 2, 3]) == "Non-empty sequence with 3 items"

suite "Type Pattern Integration":
  
  test "Type patterns integrate with literals":
    proc testMixed(x: string): string =
      match x:
        "": "Empty literal"
        "hello": "Hello literal"
        s is string: "String: " & s
        _: "Impossible"
    
    check testMixed("") == "Empty literal"
    check testMixed("hello") == "Hello literal"
    check testMixed("world") == "String: world"

  test "Type-only patterns work":
    proc testTypeOnly(): string =
      let data: seq[int] = @[1, 2, 3]
      match data:
        _ is seq[int]: "It's a sequence"
        _: "Not a sequence"
    
    check testTypeOnly() == "It's a sequence"