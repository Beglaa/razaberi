import unittest
import options
import ../../pattern_matching
import ../helper/ccheck

{.push warning[UnusedImport]: off.}
{.push hint[XDeclaredButNotUsed]: off.}

suite "Variable Binding Conflicts Bug":
  # BUG DISCOVERED: Variable binding conflicts in complex tuple patterns
  # The pattern matching library allows variable name conflicts that should be caught at compile time
  # 
  # IMPACT: This can cause:
  # 1. Compilation errors with cryptic messages about variable redefinition
  # 2. Unexpected runtime behavior if the same variable is bound multiple times
  # 3. Pattern matching logic becomes ambiguous about which binding takes precedence
  #
  # SPECIFIC CASES TESTED:
  # - Same variable name in multiple positions within tuple patterns
  # - Nested tuple patterns with variable conflicts at different levels  
  # - Variable conflicts that cross pattern boundaries in complex structures
  
  test "BUG: duplicate variable names in same tuple pattern should be rejected":
    # CRITICAL BUG: Pattern (Some(x), Some(x)) should fail compilation
    # Current behavior: Compiles successfully (BUG)
    # Expected behavior: Compile-time error about duplicate variable binding
    # 
    # Pattern analysis: Variable 'x' appears twice in the same pattern scope
    # This creates ambiguity about which value 'x' should contain
    
    check shouldNotCompile (
      let data = (some(42), some(84))
      discard match data:
        (Some(x), Some(x)): "both same: " & $x  # BUG: 'x' used twice
        _: "no match"
    )

  test "BUG: nested variable conflicts should be caught":
    # CRITICAL BUG: Variable 'x' appears at different nesting levels  
    # Current behavior: Compiles successfully (BUG)
    # Expected behavior: Compile-time error about variable scope conflict
    #
    # Pattern structure:
    # - 'x' first bound at level 2: Some(x) 
    # - 'x' rebound at level 1: Some(x)  
    # This creates nested scope conflicts
    
    check shouldNotCompile (
      let data = ((some(42), some(84)), some(126))  
      discard match data:
        ((Some(x), Some(y)), Some(x)): "nested conflict: " & $x  # BUG: 'x' conflict
        _: "no match"
    )

  test "BUG: triple variable conflicts should be detected":
    # EXTREME CASE: Variable 'val' appears three times in same pattern
    # Current behavior: Likely compiles (BUG)  
    # Expected behavior: Compile-time error with clear message
    #
    # This tests the pattern validation logic's ability to detect
    # multiple occurrences of the same variable across complex structures
    
    check shouldNotCompile (
      let data = (some(1), some(2), some(3))
      discard match data:
        (Some(val), Some(val), Some(val)): "all: " & $val  # BUG: 'val' used 3x
        _: "no match"
    )

  test "BUG: variable conflicts in mixed pattern structures":
    # COMPLEX BUG: Same variable in different positions within nested structures
    # Tests variable scope tracking across complex nested pattern combinations
    # Current behavior: Should be caught as conflict (2 different uses of same variable)
    # Expected behavior: Compile-time error about variable binding conflicts
    
    check shouldNotCompile (
      let data = (some(42), (some(84), some(126)))
      discard match data:
        (Some(value), (Some(value), Some(other))): "conflict: " & $value  # BUG: 'value' used twice
        _: "no match"
    )

  test "CONTROL: valid patterns with different variables should work":
    # CONTROL TEST: Ensures our bug fix doesn't break valid patterns
    # These patterns should continue to work after bug is fixed
    # Different variable names in similar structures
    
    check shouldCompile (
      let data = (some(42), some(84))
      discard match data:
        (Some(x), Some(y)): "different: " & $x & ", " & $y
        _: "no match"
    )

  test "CONTROL: valid nested patterns should work":
    # CONTROL TEST: Valid nested patterns with proper variable scoping
    # This ensures the fix doesn't break legitimate nested patterns
    
    check shouldCompile (
      let data = ((some(42), some(84)), some(126))
      discard match data:
        ((Some(a), Some(b)), Some(c)): "nested: " & $a & ", " & $b & ", " & $c
        _: "no match"
    )

  test "INTEGRATION: verify bug fix prevents variable conflicts":
    # INTEGRATION TEST: Confirms the bug fix properly detects variable conflicts
    # This test verifies that previously buggy patterns now fail compilation
    
    # FIXED: These patterns should now fail compilation with clear error messages
    # Previously these would compile and cause runtime issues or cryptic errors
    check shouldNotCompile (
      let data = (some(42), some(84))
      discard match data:
        (Some(x), Some(x)): "conflict resolved"  # BUG FIXED: Now catches conflict
        _: "no match"
    )