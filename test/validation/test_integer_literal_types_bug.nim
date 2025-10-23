import unittest
import ../../pattern_matching

{.push warning[UnusedImport]: off.}
{.push hint[XDeclaredButNotUsed]: off.}

# BUG DISCOVERED: Pattern matching fails with typed integer literal patterns
# The match macro doesn't handle nnkInt64Lit, nnkInt32Lit, nnkInt16Lit, nnkInt8Lit node types properly
# This causes compilation failures when matching against typed integer values

suite "Integer Literal Type Bug":

  test "BUG: int64 literal patterns should work but currently fail":
    # This test currently fails with compilation error:
    # "Unsupported pattern type 'nnkInt64Lit' for scrutinee of type 'int64'"
    let value: int64 = 1000000000000'i64
    
    let result = match value:
      1000000000000'i64: "int64 literal matched"
      _: "int64 literal not matched"
    
    check result == "int64 literal matched"

  test "BUG: int32 literal patterns should work but currently fail":
    # This should also fail with "Unsupported pattern type 'nnkInt32Lit'"
    let value: int32 = 1000000'i32
    
    let result = match value:
      1000000'i32: "int32 literal matched"
      _: "int32 literal not matched"
    
    check result == "int32 literal matched"

  test "BUG: int16 literal patterns should work but currently fail":
    # This should also fail with "Unsupported pattern type 'nnkInt16Lit'"
    let value: int16 = 30000'i16
    
    let result = match value:
      30000'i16: "int16 literal matched"
      _: "int16 literal not matched"
    
    check result == "int16 literal matched"

  test "BUG: int8 literal patterns should work but currently fail":
    # This should also fail with "Unsupported pattern type 'nnkInt8Lit'"
    let value: int8 = 100'i8
    
    let result = match value:
      100'i8: "int8 literal matched"
      _: "int8 literal not matched"
    
    check result == "int8 literal matched"

  test "BUG: uint64 literal patterns should work but currently fail":
    let value: uint64 = 1000000000000'u64
    
    let result = match value:
      1000000000000'u64: "uint64 literal matched"
      _: "uint64 literal not matched"
    
    check result == "uint64 literal matched"

  test "BUG: uint32 literal patterns should work but currently fail":
    let value: uint32 = 1000000'u32
    
    let result = match value:
      1000000'u32: "uint32 literal matched"
      _: "uint32 literal not matched"
    
    check result == "uint32 literal matched"

  test "BUG: uint16 literal patterns should work but currently fail":
    let value: uint16 = 60000'u16
    
    let result = match value:
      60000'u16: "uint16 literal matched"
      _: "uint16 literal not matched"
    
    check result == "uint16 literal matched"

  test "BUG: uint8 literal patterns should work but currently fail":
    let value: uint8 = 200'u8
    
    let result = match value:
      200'u8: "uint8 literal matched"
      _: "uint8 literal not matched"
    
    check result == "uint8 literal matched"

  test "BUG: Typed integer literals in OR patterns should work":
    let value: int64 = 1000'i64
    
    let result = match value:
      500'i64 | 1000'i64 | 2000'i64: "OR with typed int64 matched"
      _: "OR with typed int64 failed"
    
    check result == "OR with typed int64 matched"

  test "BUG: Typed integer literals in object patterns should work":
    type BigNumber = object
      value: int64
    
    let bigNum = BigNumber(value: 9999999999'i64)
    
    let result = match bigNum:
      BigNumber(value: 9999999999'i64): "Nested typed int64 matched"
      _: "Nested typed int64 failed"
    
    check result == "Nested typed int64 matched"

  # BASELINE TESTS: These should work to verify the test framework is valid
  test "Baseline: Regular int literals work (control test)":
    let value = 42
    
    let result = match value:
      42: "Regular int matched"
      _: "Regular int not matched"
    
    check result == "Regular int matched"

  test "Baseline: Regular int in object patterns work (control test)":
    type SimpleNumber = object
      value: int
    
    let num = SimpleNumber(value: 42)
    
    let result = match num:
      SimpleNumber(value: 42): "Simple nested int matched"
      _: "Simple nested int failed"
    
    check result == "Simple nested int matched"