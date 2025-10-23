## Test suite for adaptive Levenshtein distance threshold in error suggestions
## Tests PV-3 bug fix: Adaptive threshold for field/enum name suggestions
##
## The adaptive threshold formula: max(name.len div 3, 2)
## - Short names (2-6 chars): threshold = 2 (conservative)
## - Medium names (7-12 chars): threshold = 3-4 (balanced)
## - Long names (13+ chars): scales to ~33% of length (generous)
##
## NOTE: This test file verifies that the fix doesn't break existing functionality.
## Actual error message testing requires manual verification or compiler plugin.

import unittest
import ../../pattern_matching

suite "Adaptive Levenshtein Threshold - Regression Tests":

  test "short field names - valid patterns still work":
    # Verifies that adaptive threshold doesn't break valid patterns
    type User = object
      id: int
      ab: string

    let u = User(id: 42, ab: "test")

    let result = match u:
      User(id: x, ab: y): (x, y)
      _: (0, "")

    check result == (42, "test")

  test "medium field names - correct field access works":
    type Person = object
      firstName: string
      lastName: string
      age: int

    let p = Person(firstName: "Alice", lastName: "Smith", age: 30)

    let result = match p:
      Person(firstName: fname, lastName: lname, age: a): (fname, lname, a)
      _: ("", "", 0)

    check result == ("Alice", "Smith", 30)

  test "long field names - pattern matching works correctly":
    type Config = object
      extraordinarilyLongFieldName: string
      anotherVeryLongFieldName: int

    let c = Config(extraordinarilyLongFieldName: "value", anotherVeryLongFieldName: 42)

    let result = match c:
      Config(extraordinarilyLongFieldName: x, anotherVeryLongFieldName: y): (x, y)
      _: ("", 0)

    check result == ("value", 42)

  test "enum patterns - valid enum values work":
    type Status = enum
      statusPending
      statusApproved
      statusRejected

    let s = statusPending

    let result = match s:
      statusPending: "pending"
      statusApproved: "approved"
      statusRejected: "rejected"
      _: "unknown"

    check result == "pending"

  test "enum patterns - all valid values accessible":
    type ShortEnum = enum
      seA, seB, seC

    let e = seB

    let result = match e:
      seA: "A"
      seB: "B"
      seC: "C"

    check result == "B"

  test "mixed field lengths - all patterns work":
    type Mixed = object
      x: int            # 1 char
      name: string      # 4 chars
      description: string  # 11 chars
      veryLongFieldNameForTestingPurposes: int  # 39 chars

    let m = Mixed(
      x: 1,
      name: "test",
      description: "desc",
      veryLongFieldNameForTestingPurposes: 42
    )

    let result = match m:
      Mixed(x: a, name: b, description: c, veryLongFieldNameForTestingPurposes: d):
        (a, b, c, d)
      _: (0, "", "", 0)

    check result == (1, "test", "desc", 42)

  test "nested objects - field access works at all levels":
    type Inner = object
      shortField: int
      aVeryLongFieldNameInNestedObject: string

    type Outer = object
      id: int
      nested: Inner

    let o = Outer(
      id: 1,
      nested: Inner(shortField: 42, aVeryLongFieldNameInNestedObject: "nested")
    )

    let result = match o:
      Outer(id: i, nested: Inner(shortField: s, aVeryLongFieldNameInNestedObject: l)):
        (i, s, l)
      _: (0, 0, "")

    check result == (1, 42, "nested")

suite "Adaptive Threshold - Edge Cases":

  test "single character field names work correctly":
    type Point = object
      x: int
      y: int

    let p = Point(x: 10, y: 20)

    let result = match p:
      Point(x: a, y: b): (a, b)
      _: (0, 0)

    check result == (10, 20)

  test "extremely long field names - pattern matching works":
    type ExtremeLengths = object
      thisIsAnExtremelyLongFieldNameThatIsUsedForTestingAdaptiveThresholdBehaviorWithVeryLongNames: string

    let e = ExtremeLengths(
      thisIsAnExtremelyLongFieldNameThatIsUsedForTestingAdaptiveThresholdBehaviorWithVeryLongNames: "test"
    )

    let result = match e:
      ExtremeLengths(thisIsAnExtremelyLongFieldNameThatIsUsedForTestingAdaptiveThresholdBehaviorWithVeryLongNames: x):
        x
      _: ""

    check result == "test"

  test "wildcard pattern works with all field name lengths":
    type Various = object
      a: int
      medium: string
      veryLongFieldName: int

    let v = Various(a: 1, medium: "m", veryLongFieldName: 42)

    let result = match v:
      Various(a: _, medium: m, veryLongFieldName: _): m
      _: ""

    check result == "m"

suite "Documentation - Expected Suggestion Behavior":
  # These tests document the expected behavior without actually triggering compile errors
  # Manual verification required for actual suggestion messages

  test "documentation: short field threshold behavior":
    # For field "id" (2 chars): threshold = max(2 div 3, 2) = 2
    # - Typo "ix" (distance 1): SHOULD suggest "id"
    # - Typo "xyz" (distance 3): should NOT suggest "id" (unrelated)

    type User = object
      id: int

    let u = User(id: 42)

    # Valid pattern should work
    let result = match u:
      User(id: x): x
      _: 0

    check result == 42

  test "documentation: medium field threshold behavior":
    # For field "firstName" (9 chars): threshold = max(9 div 3, 2) = 3
    # - Typo "firstNmae" (distance 2): SHOULD suggest "firstName"
    # - Typo "firstn" (distance 3): SHOULD suggest "firstName" (at boundary)
    # - Typo "fname" (distance 5): should NOT suggest "firstName" (too different)

    type Person = object
      firstName: string

    let p = Person(firstName: "Alice")

    # Valid pattern should work
    let result = match p:
      Person(firstName: name): name
      _: ""

    check result == "Alice"

  test "documentation: long field threshold behavior":
    # For field "extraordinarilyLongFieldName" (28 chars): threshold = max(28 div 3, 2) = 9
    # - Typo "extraordinarilyLongFildName" (distance 2): SHOULD suggest (2 < 9)
    # - Typo "extraLongFieldName" (distance 11): should NOT suggest (11 > 9)

    type Config = object
      extraordinarilyLongFieldName: string

    let c = Config(extraordinarilyLongFieldName: "value")

    # Valid pattern should work
    let result = match c:
      Config(extraordinarilyLongFieldName: x): x
      _: ""

    check result == "value"

  test "documentation: enum threshold behavior":
    # For enum "statusPending" (13 chars): threshold = max(13 div 3, 2) = 4
    # - Typo "statusPendig" (distance 1): SHOULD suggest "statusPending"
    # - Typo "pending" (distance 7): should NOT suggest "statusPending" (too different)

    type Status = enum
      statusPending
      statusApproved

    let s = statusPending

    # Valid pattern should work
    let result = match s:
      statusPending: "pending"
      _: "other"

    check result == "pending"

# Manual verification test file - uncomment to test error messages
# when false:
#   test "MANUAL: verify short field error message":
#     type User = object
#       id: int
#
#     let u = User(id: 42)
#
#     # Uncomment to see error message (should suggest "id"):
#     # let _ = match u:
#     #   User(ix: x): x
#     #   _: 0
#
#     check true

when isMainModule:
  echo "Testing adaptive Levenshtein distance threshold (PV-3 fix)"
  echo "These tests verify that the fix doesn't break existing functionality"
  echo "For error message verification, see comments in test file"
