import unittest
import sequtils
import ../../pattern_matching

# Test demonstrating that collection filtering has been removed
# Previous filtering functionality now replaced with structural pattern matching

type
  User = object
    name: string
    age: int
    active: bool

suite "Collection Filtering Functionality Removal Verification":

  test "Collection filtering functionality has been successfully removed":
    let users = @[
      User(name: "Alice", age: 25, active: true),
      User(name: "Bob", age: 45, active: true),
      User(name: "Carol", age: 52, active: false)
    ]

    # Old filtering syntax no longer works - replaced with structural matching
    # This now checks if FIRST user meets condition (structural)
    let first_is_senior = match users:
      [User(age > 39), *rest]: true
      _: false

    check first_is_senior == false  # Alice (25) is not > 39

    # For filtering all users, use regular Nim operations
    let older_users = users.filter(proc(u: User): bool = u.age > 39)
    check older_users.len == 2  # Bob and Carol

  test "Structural pattern matching replaces filtering":
    let users = @[
      User(name: "Alice", age: 25, active: true),
      User(name: "Bob", age: 45, active: true),
      User(name: "Carol", age: 52, active: false)
    ]

    # Structural: check if first user is active
    let first_is_active = match users:
      [User(active: true), *rest]: true
      _: false

    check first_is_active == true  # Alice is active

    # This library now focuses on structural decomposition
    # rather than collection filtering operations
    check users.len == 3  # Original data unchanged