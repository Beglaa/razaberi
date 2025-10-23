import unittest
import ../../pattern_matching

suite "OR Pattern Variable Binding Conflict Detection Bug":
  test "should detect variable binding conflicts when OR patterns are nested in larger patterns":
    # BUG: The current variable binding conflict detection incorrectly skips ALL OR patterns,
    # missing cases where variables from OR patterns conflict with variables outside the OR pattern
    
    # This should cause a compile-time error because 'x' appears twice:
    # - Once in the OR pattern (x | y) 
    # - Once in the second tuple position
    # The variable 'x' would be bound in two different contexts, creating ambiguity
    
    when not compiles(
      block:
        let data = (1, 2)
        let result = match data:
          (x | y, x): "conflict"  # BUG: Should be compile error - x used twice!
          _: "no match"
    ):
      # This test should PASS - the code should NOT compile due to variable conflict
      check true
    else:
      # This test should FAIL - the bug allows conflicting variable bindings
      check false
      
  test "should detect variable binding conflicts in nested OR patterns with tuple destructuring":
    # Another edge case: nested tuple with OR pattern containing conflicting variable
    when not compiles(
      block:
        let data = ((1, 2), 3)
        let result = match data:
          ((x | y, z), x): "nested conflict"  # BUG: x appears in OR and tuple positions
          _: "no match"
    ):
      check true
    else:
      check false
      
  test "should detect variable binding conflicts in complex nested patterns with OR":
    # Even more complex case: deep nesting with OR patterns and conflicts
    when not compiles(
      block:
        let data = (1, (2, 3), 4)
        let result = match data:
          (a | b, (c, d), a): "deep conflict"  # BUG: 'a' in OR pattern and third position
          _: "no match"
    ):
      check true
    else:
      check false

  test "should allow valid OR patterns with same variable across alternatives":
    # This should be VALID - same variable used consistently across OR alternatives
    when compiles(
      block:
        let data = 5
        let result = match data:
          (1 @ x) | (2 @ x) | (3 @ x): "valid: " & $x  # VALID: same var across OR alternatives
          _: "no match"
    ):
      check true
    else:
      check false

  test "should detect conflicts between @ pattern variable and tuple element":
    # Edge case: @ pattern binding conflicts with other tuple elements
    when not compiles(
      block:
        let data = (1, 2, 3)
        let result = match data:
          (1 @ x, y, x): "@ conflict"  # BUG: x from @ pattern conflicts with third element
          _: "no match"  
    ):
      check true
    else:
      check false