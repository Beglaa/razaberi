import unittest
import tables
import sequtils
import ../../pattern_matching

# Test types for OrderedTable
type
  User = object
    name: string
    age: int
    active: bool

suite "OrderedTable Structural Pattern Matching":

  test "OrderedTable demonstrates filtering removal":
    let userTable = {
      "user1": User(name: "Alice", age: 25, active: true),
      "user2": User(name: "Bob", age: 45, active: true),
      "user3": User(name: "Carol", age: 52, active: false)
    }.toOrderedTable

    # OrderedTable pattern matching now works structurally only
    # Complex filtering behavior has been removed

    # Check specific key structurally
    let user2_is_senior = match userTable:
      {"user2": User(age > 39), **rest}: true
      _: false

    check user2_is_senior == true  # Bob (user2) is 45 > 39

    # For filtering all users by age, use regular Nim operations
    let older_users = userTable.values.toSeq.filter(proc(u: User): bool = u.age > 39)
    check older_users.len == 2  # Bob and Carol

  test "OrderedTable maintains insertion order":
    let orderedUsers = {
      "first": User(name: "Alice", age: 25, active: true),
      "second": User(name: "Bob", age: 45, active: true),
      "third": User(name: "Carol", age: 52, active: false)
    }.toOrderedTable

    # OrderedTable preserves insertion order
    let userSeq = orderedUsers.values.toSeq
    check userSeq[0].name == "Alice"
    check userSeq[1].name == "Bob"
    check userSeq[2].name == "Carol"

    # Structural pattern matching works with specific keys
    let first_is_young = match orderedUsers:
      {"first": User(age < 30), **rest}: true
      _: false

    check first_is_young == true  # Alice is 25 < 30