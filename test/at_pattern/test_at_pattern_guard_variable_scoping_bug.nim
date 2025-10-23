import std/unittest
import std/options
import std/tables
import ../../pattern_matching

suite "BUG: @ Pattern Guard Variable Scoping":
  ## This test suite identifies a critical bug in the pattern matching library:
  ## When using @ patterns with guards that reference variables bound inside the
  ## @ pattern, the library incorrectly tries to extract those inner variables
  ## as direct @ pattern aliases, causing "Invalid variable name in @ pattern with guard" errors.
  ##
  ## BUG DESCRIPTION:
  ## Pattern: Some([head, *tail]) @ opt and head > 0
  ## Error: "Invalid variable name in @ pattern with guard"
  ## Root Cause: flattenNestedAndPattern function doesn't understand that 'head'
  ## is bound inside the Some([head, *tail]) pattern, not as a direct alias.
  ##
  ## EXPECTED BEHAVIOR:
  ## The guard expression 'head > 0' should be evaluated after the variables
  ## 'head' and 'tail' are bound from the destructuring of the Option content.

  test "FIXED: @ pattern with guard referencing inner sequence variables":
    ## This test now PASSES - the bug has been fixed!
    ## Pattern matches Some containing a sequence, binds the sequence to 'opt',
    ## and uses guard 'head > 0' where 'head' is bound from sequence destructuring
    let data = some(@[5, 10, 15])

    let result = match data:
      Some([head, *tail]) @ opt and head > 0: "matched with positive head"
      _: "no match"

    check result == "matched with positive head"

  test "FIXED: @ pattern with guard referencing inner table variables":
    ## This bug has been fixed! Table destructuring in @ patterns with guards now works
    let data = some({"value": 42}.toTable)

    let result = match data:
      Some({"value": val}) @ opt and val > 30: "matched with high value"
      _: "no match"

    check result == "matched with high value"

  test "FIXED: @ pattern with guard referencing inner tuple variables":
    ## This bug has been fixed! Tuple destructuring in @ patterns with guards now works
    let data = some((100, "test"))

    let result = match data:
      Some((num, text)) @ opt and num > 50: "matched with high number"
      _: "no match"

    check result == "matched with high number"

  test "FIXED: @ pattern with guard referencing inner object variables":
    ## This bug has been fixed! Object destructuring in @ patterns with guards now works
    type Person = object
      name: string
      age: int

    let data = some(Person(name: "Alice", age: 30))

    let result = match data:
      Some(Person(name: person_name, age: person_age)) @ opt and person_age >= 18: "adult"
      _: "not adult"

    check result == "adult"

  test "CONTROL: @ pattern with guard on @ variable works correctly":
    ## This should work - the guard references the @ alias variable 'opt', not inner variables
    let data = some(@[5, 10, 15])

    let result = match data:
      Some([head, *tail]) @ opt and opt.isSome: "matched with opt guard"
      _: "no match"

    check result == "matched with opt guard"

  test "CONTROL: @ pattern without guard works correctly":
    ## This should work - no guard, just @ binding
    let data = some(@[5, 10, 15])

    let result = match data:
      Some([head, *tail]) @ opt: "matched"
      _: "no match"

    check result == "matched"

  test "CONTROL: pattern with guard but no @ binding works correctly":
    ## This should work - guard references variables but no @ binding involved
    let data = some(@[5, 10, 15])

    let result = match data:
      Some([head, *tail]) and head > 0: "matched with positive head"
      _: "no match"

    check result == "matched with positive head"

  test "CONTROL: complex guard without @ pattern works correctly":
    ## This should work - complex guard expressions without @ patterns
    let data = @[1, 2, 3, 4, 5]

    let result = match data:
      [first, second, *rest] and first > 0 and second < 5: "matched"
      _: "no match"

    check result == "matched"