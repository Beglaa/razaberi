import unittest
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

suite "Array Structural Pattern Matching":

  test "Array structural matching with first element condition":
    let userArray: array[5, User] = [
      User(name: "Alice", age: 25, active: true),
      User(name: "Bob", age: 45, active: true),
      User(name: "Carol", age: 52, active: false),
      User(name: "Dave", age: 30, active: true),
      User(name: "Eve", age: 41, active: true)
    ]

    # Test structural matching - checks if FIRST user has age > 39
    let first_is_senior = match userArray:
      [User(age > 39), *rest]: true  # Alice (25) does NOT match age > 39
      _: false

    check first_is_senior == false  # Alice is 25, not > 39

    # To get all users with age > 39, use regular Nim filter (not pattern matching)
    let older_users = userArray.toSeq.filter(proc(u: User): bool = u.age > 39)
    check older_users.len == 3
    check older_users[0].name == "Bob"
    check older_users[1].name == "Carol"
    check older_users[2].name == "Eve"

  test "Array structural matching with exact value":
    let employeeArray: array[4, Employee] = [
      Employee(name: "Alice", role: "Developer", salary: 75000),
      Employee(name: "Bob", role: "Manager", salary: 95000),
      Employee(name: "Carol", role: "Developer", salary: 85000),
      Employee(name: "Dave", role: "Admin", salary: 65000)
    ]

    # Test structural matching - checks if FIRST employee is a developer
    let first_is_developer = match employeeArray:
      [Employee(role: "Developer"), *rest]: true
      _: false

    check first_is_developer == true  # Alice is a Developer

    # To get all developers, use regular Nim filter (not pattern matching)
    let developers = employeeArray.toSeq.filter(proc(e: Employee): bool = e.role == "Developer")
    check developers.len == 2
    check developers[0].name == "Alice"
    check developers[1].name == "Carol"

  test "Array structural matching with multiple conditions":
    let userArray: array[3, User] = [
      User(name: "Bob", age: 45, active: true),
      User(name: "Carol", age: 52, active: false),
      User(name: "Eve", age: 41, active: true)
    ]

    # Test structural matching - checks if FIRST user meets multiple conditions
    let first_is_active_senior = match userArray:
      [User(age > 40, active: true), *rest]: true
      _: false

    check first_is_active_senior == true  # Bob is 45 and active

    # To get all active seniors, use regular Nim filter (not pattern matching)
    let active_seniors = userArray.toSeq.filter(proc(u: User): bool = u.age > 40 and u.active)
    check active_seniors.len == 2  # Bob and Eve

  test "Array structural vs sequence type behavior":
    let userArray: array[2, User] = [
      User(name: "Alice", age: 25, active: true),
      User(name: "Bob", age: 45, active: true)
    ]

    # Structural matching checks first element structure
    let first_is_active = match userArray:
      [User(active: true), *rest]: true
      _: false

    check first_is_active == true  # Alice is active

    # Structural matching works for field access
    check userArray[0].name == "Alice"  # Direct field access works
    check userArray[0].active == true   # Active field confirmed