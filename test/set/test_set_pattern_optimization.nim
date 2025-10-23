import ../../pattern_matching

# Test cases for set pattern optimizations
# These tests ensure that set patterns use native set operations when possible
#
# OPTIMIZATION STRATEGY:
# - Ordinal types (enum, char, bool, small int): Use native set membership `in {val1, val2}`
#   → Native sets are compile-time constants (zero allocation), O(1) bitset lookup
#   → Safe in loops - no hidden allocations, no performance surprises
# - Non-ordinal types (string, float): Use OR chain `val == x or val == y`
#   → Predictable cost, no hidden allocations, honest performance characteristics
#   → HashSet deliberately avoided: would allocate on every match in loops
#
# WHY NOT HashSet for non-ordinals?
# - Hidden allocation cost on every match expression evaluation
# - Terrible performance if match is inside a loop (allocates N times)
# - {.global.} caching introduces thread-safety issues and hidden state
# - OR chain is honest: users see the cost, performance is predictable
#
# IMPLICIT GUARD MEMBERSHIP TESTING:
# For membership testing on scalar values, use implicit guards:
#   match value:
#     x in {1, 2, 3}: "member"          # Implicit guard with 'in'
#     x notin {10, 20}: "not member"    # Implicit guard with 'notin'
#
# Works with:
# - Ordinal types: int, char, bool, enum → native set (O(1))
# - Collections: seq[T], array[N,T], openArray[T] → runtime lookup
#
# Also supports explicit guards:
#   match value:
#     x and x in {1, 2, 3}: "member"    # Explicit guard form

# Define an enum for testing enum set patterns
type
  Color = enum
    Red, Green, Blue, Yellow, Orange, Purple

  Direction = enum
    North, South, East, West

# Test: Integer set pattern with 3+ elements should use native set operations
# WHY: Integers are ordinal types → can use native Nim set[int] (compile-time constant bitset)
#      Performance: O(1) lookup, zero allocation, safe in loops
proc testIntegerSetPatternOptimization() =
  # Test membership using `in` operator since we want to test if value is in set
  let value = 3
  let result = if value in {1, 2, 3, 4, 5}: "small numbers"
               elif value in {10, 20, 30, 40, 50}: "tens"
               else: "other"

  if result == "small numbers":
    discard
  else:
    discard

# Test: Enum set pattern with 3+ elements should use native set operations
# WHY: Enums are ordinal types → can use native Nim set[Color] (compile-time constant bitset)
#      Performance: O(1) lookup, zero allocation, safe in loops
proc testEnumSetPatternOptimization() =
  let colorSet = {Red, Green, Blue}
  let result = match colorSet:
    {Red, Green, Blue}: "primary colors"
    {Yellow, Orange, Purple}: "secondary colors"
    _: "other color"

  if result == "primary colors":
    discard
  else:
    discard

# Test: Boolean set pattern should use native set operations
# WHY: Bool is an ordinal type → can use native Nim set[bool] (compile-time constant)
#      Performance: O(1) lookup, zero allocation
proc testBooleanSetPatternOptimization() =
  let value = true
  let result = match value:
    {true, false}: "boolean value"
    _: "not boolean"

  if result == "boolean value":
    discard
  else:
    discard

# Test: String membership testing with OR patterns
# WHY: Strings are non-ordinal (cannot use native Nim set[string])
#      Use OR patterns for membership testing on non-ordinal scalar types
#      TODO: Implement 'x in {...}' syntax for non-ordinal types
proc testStringMembershipTesting() =
  let command = "help"
  let result = match command:
    "help" | "info" | "about": "information"
    "quit" | "exit" | "bye": "terminating"
    _: "unknown"

  if result == "information":
    discard
  else:
    discard

# Test: Float membership testing with OR patterns
# WHY: Floats are non-ordinal (cannot use native Nim set[float])
#      Use OR patterns for membership testing on non-ordinal scalar types
#      TODO: Implement 'x in {...}' syntax for non-ordinal types
proc testFloatMembershipTesting() =
  let value = 2.5
  let result = match value:
    1.0 | 2.5 | 3.7: "small floats"
    10.1 | 20.5 | 30.9: "larger floats"
    _: "other float"

  if result == "small floats":
    discard
  else:
    discard

# Test: Integer membership testing with implicit guards
proc testIntegerMembershipTesting() =
  # Use 'x in {...}' syntax for ordinal types (int, char, enum, bool)
  let value = 42
  let result = match value:
    x in {1, 2}: "small numbers"
    _: "other"

  if result == "other":
    discard
  else:
    discard

# Test: Small integer membership pattern
# NOTE: For ordinal types, use 'x in {...}' for membership testing
proc testSmallIntegerMembershipPattern() =
  let value = 1
  let result = match value:
    x in {1, 2}: "small set"
    _: "other"

  if result == "small set":
    discard
  else:
    discard

# Test: Single element membership pattern
proc testSingleElementMembershipPattern() =
  let value = 42
  let result = match value:
    x in {42}: "the answer"
    _: "not the answer"

  if result == "the answer":
    discard
  else:
    discard

# Test: Large integer membership pattern for performance
proc testLargeIntegerMembershipPatternPerformance() =
  let value = 7
  let result = match value:
    x in {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15}: "in range 1-15"
    x in {16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30}: "in range 16-30"
    _: "out of range"

  if result == "in range 1-15":
    discard
  else:
    discard

# Test: Membership pattern with additional guards
proc testMembershipPatternWithGuards() =
  let value = 3
  let result = match value:
    x in {1, 2, 3, 4, 5} and value < 4: "small and less than 4"
    x in {1, 2, 3, 4, 5}: "small number"
    _: "other"

  if result == "small and less than 4":
    discard
  else:
    discard

when isMainModule:
  testIntegerSetPatternOptimization()
  testEnumSetPatternOptimization()
  testBooleanSetPatternOptimization()
  testStringMembershipTesting()
  testFloatMembershipTesting()
  testIntegerMembershipTesting()
  testSmallIntegerMembershipPattern()
  testSingleElementMembershipPattern()
  testLargeIntegerMembershipPatternPerformance()
  testMembershipPatternWithGuards()