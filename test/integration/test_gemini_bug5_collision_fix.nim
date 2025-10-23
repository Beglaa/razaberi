import unittest
import ../../pattern_matching

suite "Bug #5 FIXED: Semantic Ambiguity in Spread Patterns - Collision Detection":

  test "true collision pattern correctly fails - both variables need sequence access":
    # TRUE collision: both variables have NO defaults and MUST access sequence
    let data = @[100]

    let result = match data:
      [a, *b, c]:  # Both a and c need sequence elements -> collision with single element
        "COLLISION: a=" & $a & ", c=" & $c & ", b has " & $b.len & " items"
      [single]:
        "CORRECT: single element: " & $single
      _:
        "no match"

    # True collision is detected and pattern fails, falling through to [single] arm
    check result == "CORRECT: single element: 100"

  test "mixed defaults work correctly - no collision when one has default":
    let data = @[42]

    let result = match data:
      [first, *middle, last=99]:  # first needs sequence, last can use default -> no collision
        "NO COLLISION: first=" & $first & ", middle=" & $middle.len & ", last=" & $last
      [single]:
        "single: " & $single
      _:
        "no match"

    # Should work because last has default fallback
    check result == "NO COLLISION: first=42, middle=0, last=99"

  test "collision detection allows sufficient elements":
    # When there are enough elements, no collision occurs
    let data = @[1, 2, 3]

    let result = match data:
      [first=10, *middle, last=20]:  # 3 elements: first=1, middle=@[2], last=3 (no collision)
        "WORKS: first=" & $first & ", last=" & $last & ", middle=" & $middle.len
      [single]:
        "single: " & $single
      _:
        "no match"

    # Should work fine with sufficient elements
    check result == "WORKS: first=1, last=3, middle=1"

  test "all defaults work correctly with spread":
    let data = @[5, 6]

    let result = match data:
      [a=1, b=2, *rest, c=3, d=4]:  # All have defaults -> should work
        "DEFAULTS: a=" & $a & ", b=" & $b & ", rest=" & $rest.len & ", c=" & $c & ", d=" & $d
      [first, second]:
        "two elements: " & $first & ", " & $second
      _:
        "no match"

    # Should work with defaults: a,b from sequence, c,d from defaults
    check result == "DEFAULTS: a=5, b=6, rest=0, c=3, d=4"

  test "spread at beginning - no collision with defaults":
    let data = @[99]

    let result = match data:
      [*initial, last=77]:  # No collision: initial gets empty, last could use default but gets actual value
        "NO COLLISION: initial=" & $initial.len & ", last=" & $last
      [single]:
        "SINGLE: " & $single
      _:
        "no match"

    # This should work because there's no collision (last doesn't compete with initial for same index)
    check result == "NO COLLISION: initial=0, last=99"

  test "multiple suffix defaults work correctly":
    let data = @[1, 2]

    let result = match data:
      [prefix=0, *middle, second_last=88, last=99]:  # All have defaults -> should work
        "DEFAULTS: prefix=" & $prefix & ", middle=" & $middle.len & ", second_last=" & $second_last & ", last=" & $last
      [first, second]:
        "fallback: " & $first & ", " & $second
      _:
        "no match"

    # Should work: prefix from sequence, middle empty, second_last/last use defaults
    check result == "DEFAULTS: prefix=1, middle=0, second_last=88, last=99"

  test "no spread patterns work normally":
    let data = @[10, 20]

    # Patterns without spread should work exactly as before
    let result = match data:
      [first=1, second=2]:  # Should match and bind: first=10, second=20
        "WORKS: " & $first & ", " & $second
      [single]:
        "single"
      _:
        "no match"

    check result == "WORKS: 10, 20"

  test "sufficient elements with complex spread pattern":
    let data = @[1, 2, 3, 4, 5]

    # Complex pattern that should work with sufficient elements
    let result = match data:
      [first=0, second=0, *middle, second_last=0, last=0]:  # 5 elements is sufficient
        "COMPLEX: first=" & $first & ", second=" & $second & ", middle=" & $middle.len & ", second_last=" & $second_last & ", last=" & $last
      _:
        "no match"

    check result == "COMPLEX: first=1, second=2, middle=1, second_last=4, last=5"

when isMainModule:
  # This test validates that Bug #5 from gemini.md is properly fixed
  # by implementing collision detection that prevents ambiguous spread patterns
  discard