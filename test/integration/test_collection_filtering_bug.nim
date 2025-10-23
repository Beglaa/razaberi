import unittest
import ../../pattern_matching
import sequtils  # For filter function

# Test for NEW structural pattern matching behavior (filtering removed)
# This demonstrates how structural pattern matching works differently from filtering

type
  User = object
    name: string
    age: int
    active: bool

  Employee = object
    name: string
    role: string
    salary: int

suite "Structural Pattern Matching - No More Filtering":

  test "structural matching extracts first element, not all matching elements":
    let users = @[
      User(name: "Alice", age: 25, active: true),
      User(name: "Bob", age: 45, active: true),
      User(name: "Carol", age: 52, active: false),
      User(name: "Dave", age: 30, active: true),
      User(name: "Eve", age: 41, active: true)
    ]

    # Structural pattern matching: check if FIRST user is older than 39
    let first_is_senior = match users:
      [User(age > 39), *rest]: true  # Matches if first user is over 39
      _: false

    # Expected: false (Alice is 25, not over 39)
    check first_is_senior == false

    # To get all seniors, use regular Nim filter:
    let all_seniors = users.filter(proc(u: User): bool = u.age > 39)
    check all_seniors.len == 3  # Bob, Carol, Eve

  test "structural matching with multiple conditions checks first element":
    let users = @[
      User(name: "Alice", age: 25, active: true),
      User(name: "Bob", age: 45, active: true),
      User(name: "Carol", age: 52, active: false),
      User(name: "Dave", age: 30, active: true),
      User(name: "Eve", age: 41, active: true)
    ]

    # Check if first user matches multiple conditions
    let first_is_active_senior = match users:
      [User(age > 30, active: true), *rest]: true
      _: false

    # Expected: false (Alice is 25, not over 30)
    check first_is_active_senior == false

    # To filter with multiple conditions, use regular Nim:
    let active_seniors = users.filter(proc(u: User): bool = u.age > 30 and u.active)
    check active_seniors.len == 2  # Bob, Eve (Dave is exactly 30, not > 30)

  test "structural matching with exact value matches first element":
    let employees = @[
      Employee(name: "Alice", role: "Developer", salary: 75000),
      Employee(name: "Bob", role: "Manager", salary: 95000),
      Employee(name: "Carol", role: "Developer", salary: 85000),
      Employee(name: "Dave", role: "Admin", salary: 65000)
    ]

    # Check if first employee is a Developer
    let first_is_developer = match employees:
      [Employee(role: "Developer"), *rest]: true
      _: false

    # Expected: true (Alice is a Developer)
    check first_is_developer == true

    # Extract first developer's name
    let first_dev_name = match employees:
      [Employee(role: "Developer"), *rest]: employees[0].name
      _: "None"

    check first_dev_name == "Alice"

    # To get all developers, use regular Nim filter:
    let all_developers = employees.filter(proc(e: Employee): bool = e.role == "Developer")
    check all_developers.len == 2  # Alice, Carol

  test "pattern matching on empty sequences":
    let empty_users: seq[User] = @[]

    # Pattern match on empty sequence
    let result = match empty_users:
      []: "empty"
      [single]: "one user"
      [first, *rest]: "multiple users"

    check result == "empty"