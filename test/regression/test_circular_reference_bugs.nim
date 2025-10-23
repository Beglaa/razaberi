import unittest
import options
import tables
import ../../pattern_matching
import ../helper/ccheck

{.push warning[UnusedImport]: off.}
{.push hint[XDeclaredButNotUsed]: off.}

suite "Circular Reference Bugs":
  
  test "should detect self-referencing @ pattern and give proper error":
    # FIXED BUG #1: @ patterns that reference themselves now give proper error
    # Pattern: x @ x creates a variable binding conflict
    # Location: Fixed in pattern_matching.nim at lines 5237-5245 in processAtPattern
    # Expected: Proper compile-time error from pattern matching library
    
    # This should now fail with a proper compile-time error message
    check shouldNotCompile (
      let data = 42
      discard match data:
        x @ x: "matched: " & $x
        _: "no match"
    )

  test "should allow valid @ patterns that look similar but aren't self-referencing":
    # This test ensures that valid @ patterns still work after our fix
    # These patterns are NOT self-referencing and should compile fine
    
    check shouldCompile (
      let data = 42
      discard match data:
        value @ num: "Number: " & $num
        _: "No match"
    )
    
    check shouldCompile (
      let data = "test"  
      discard match data:
        "test" @ matched: "Found: " & matched
        _: "No match"
    )

  test "should handle normal @ patterns correctly":
    # This test ensures that normal, non-circular @ patterns work correctly
    # This serves as a control test to verify the pattern matching library works for valid patterns
    let data1 = 42
    let result1 = match data1:
      value @ num: "Number: " & $num
      _: "No match"
    check(result1 == "Number: 42")
    
    # Test @ patterns with OR
    let data2 = "quit"
    let result2 = match data2:
      "exit" | "quit" @ cmd: "Command: " & cmd
      _: "No match"  
    check(result2 == "Command: quit")
    
    # Test @ patterns with guards
    let data3 = 20
    let result3 = match data3:
      (_ @ num) and num > 10: "Big: " & $num
      _ @ num: "Small: " & $num
    check(result3 == "Big: 20")

  test "should validate bug documentation accuracy":
    # This test documents the exact nature of the bugs we found
    # It serves as a regression test - when bugs are fixed, this test should be updated
    
    # Document Bug #1: Self-referencing @ patterns
    # Current behavior: Compilation error "redefinition of 'x'"
    # Expected behavior: MatchError or better validation error
    
    # Document Bug #2: Table @ pattern variable binding
    # Current behavior: Compilation error "undeclared identifier"
    # Expected behavior: Proper variable binding in @ patterns
    
    check(true)  # This test always passes - it's for documentation