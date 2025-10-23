import unittest
import deques
import sequtils
import ../../pattern_matching

# Test types for deque filtering
type 
  User = object
    name: string
    age: int
    active: bool
  
  Employee = object
    name: string
    role: string
    salary: int
    active: bool

suite "Deque Structural Pattern Matching":

  test "deque structural matching checks first element":
    let users = [
      User(name: "Alice", age: 25, active: true),
      User(name: "Bob", age: 45, active: true),
      User(name: "Carol", age: 52, active: false),
      User(name: "Dave", age: 30, active: true),
      User(name: "Eve", age: 41, active: true)
    ].toDeque

    # Structural matching checks if FIRST user has age > 39
    let first_is_senior = match users:
      [User(age > 39), *rest]: true
      _: false

    check first_is_senior == false  # Alice (25) is not > 39

    # For filtering all users by age, use regular Nim operations
    let older_users = users.toSeq.filter(proc(u: User): bool = u.age > 39)
    check older_users.len == 3
    check older_users[0].name == "Bob"
    check older_users[1].name == "Carol"
    check older_users[2].name == "Eve"
  
  test "deque structural matching with multiple conditions":
    let users = [
      User(name: "Alice", age: 25, active: true),
      User(name: "Bob", age: 45, active: true),
      User(name: "Carol", age: 52, active: false),
      User(name: "Dave", age: 30, active: true),
      User(name: "Eve", age: 41, active: true)
    ].toDeque

    # Structural matching checks if FIRST user meets multiple conditions
    let first_is_active_senior = match users:
      [User(age > 30, active: true), *rest]: true
      _: false

    check first_is_active_senior == false  # Alice (25, true) doesn't meet age > 30

    # For filtering with multiple conditions, use regular Nim operations
    let active_seniors = users.toSeq.filter(proc(u: User): bool = u.age > 30 and u.active)
    check active_seniors.len == 2  # Bob and Eve

  test "deque demonstrates structural vs filtering behavior":
    let employees = [
      Employee(name: "John", role: "Developer", salary: 80000, active: true),
      Employee(name: "Jane", role: "Manager", salary: 95000, active: true),
      Employee(name: "Bob", role: "Developer", salary: 75000, active: true),
      Employee(name: "Alice", role: "Designer", salary: 70000, active: false)
    ].toDeque

    # Structural: check if first employee is a developer
    let first_is_developer = match employees:
      [Employee(role: "Developer"), *rest]: true
      _: false

    check first_is_developer == true  # John is a Developer

    # For finding all developers, use regular Nim filter
    let developers = employees.toSeq.filter(proc(e: Employee): bool = e.role == "Developer")
    check developers.len == 2
    check developers[0].name == "John"
    check developers[1].name == "Bob"

  test "deque structural pattern matching preserves type information":
    let users = [
      User(name: "Alice", age: 25, active: true),
      User(name: "Bob", age: 45, active: false),
      User(name: "Carol", age: 30, active: true)
    ].toDeque

    # Structural: check if first user is active
    let first_is_active = match users:
      [User(active: true), *rest]: true
      _: false

    check first_is_active == true  # Alice is active

    # The deque itself remains unchanged and maintains type
    check users is Deque[User]
    check users.len == 3