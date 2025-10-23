import unittest
import sets
import sequtils
import ../../pattern_matching

type
  User = object
    name: string
    age: int
    active: bool
  
  Employee = object
    name: string
    role: string
    salary: int

suite "Set Structural Pattern Matching":

  test "Set patterns demonstrate structural behavior (no filtering)":
    # Set patterns now work structurally, not for filtering
    type Color = enum
      Red, Green, Blue, Yellow

    # Simple ordinal value sets work
    let singleColorSet = [Red].toHashSet

    let matches_red = match singleColorSet:
      {Red}: true
      _: false

    check matches_red == true  # Single element set contains Red

  test "Demonstrates that object filtering was removed - use sequences instead":
    let users = @[
      User(name: "Alice", age: 25, active: true),
      User(name: "Bob", age: 45, active: true),
      User(name: "Carol", age: 52, active: false)
    ]

    # Structural matching checks first element, not filtering
    let first_is_senior = match users:
      [User(age > 39), *rest]: true
      _: false

    check first_is_senior == false  # Alice (25) is not > 39

    # For filtering users by conditions, use regular Nim operations
    let older_users = users.filter(proc(u: User): bool = u.age > 39)
    check older_users.len == 2  # Bob and Carol

    # HashSets can only pattern match on ordinal types (enums, integers)
    # For complex filtering on objects, use sequences with regular Nim operations

  test "Sets no longer support complex pattern filtering":
    # Sets in pattern matching are now purely structural
    # No more object filtering through set patterns
    # For complex filtering operations, use regular Nim with sequences

    type Priority = enum
      Low, Medium, High, Critical

    let priorityList = @[Low, High, Critical, Medium]

    # Use regular Nim operations for filtering instead of pattern matching
    let highPriorities = priorityList.filter(proc(p: Priority): bool = p in {High, Critical})
    check highPriorities.len == 2

    # Pattern matching on sets is limited to structural membership checks
    let containsHigh = High in [Low, High, Critical].toHashSet
    check containsHigh == true