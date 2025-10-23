import unittest
import tables
import sequtils
import ../../pattern_matching

type
  User = object
    name: string
    age: int
    active: bool

suite "Table Structural Pattern Matching":

  test "Table structural matching checks specific keys":
    let userTable = {
      "user1": User(name: "Alice", age: 25, active: true),
      "user2": User(name: "Bob", age: 45, active: true),
      "user3": User(name: "Carol", age: 52, active: false)
    }.toTable

    # Structural matching checks if specific key meets condition
    let user2_is_senior = match userTable:
      {"user2": User(age > 39), **rest}: true
      _: false

    check user2_is_senior == true  # Bob (user2) is 45 > 39

    # To filter all users by age, use regular Nim operations
    let older_users = userTable.values.toSeq.filter(proc(u: User): bool = u.age > 39)
    check older_users.len == 2  # Bob and Carol

  test "Table structural matching with specific key access":
    let roleTable = {
      "admin": User(name: "Alice", age: 45, active: true),
      "user": User(name: "Bob", age: 25, active: true),
      "guest": User(name: "Carol", age: 52, active: false)
    }.toTable

    # Check if admin user is senior (structural check)
    let admin_is_senior = match roleTable:
      {"admin": User(age > 39), **rest}: true
      _: false

    check admin_is_senior == true  # Alice (admin) is 45 > 39

    # Verify the structural check found the right user
    check roleTable["admin"].name == "Alice"  # Direct access confirms