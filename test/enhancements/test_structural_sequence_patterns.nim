import unittest
import sequtils
import ../../pattern_matching

type
  User = object
    name: string
    age: int
    active: bool

  Product = object
    name: string
    price: float
    category: string

suite "Structural Sequence Pattern Matching":

  test "first element structural matching with guard conditions":
    let users = @[
      User(name: "Alice", age: 25, active: true),
      User(name: "Bob", age: 45, active: true),
      User(name: "Carol", age: 52, active: false)
    ]

    # Check if first user is senior (age > 39)
    let first_is_senior = match users:
      [User(age > 39), *rest]: true
      _: false

    check first_is_senior == false  # Alice (25) is not > 39

    # Check if first user is active
    let first_is_active = match users:
      [User(active: true), *rest]: true
      _: false

    check first_is_active == true  # Alice is active

  test "first element extraction with multiple conditions":
    let products = @[
      Product(name: "Laptop", price: 999.99, category: "Electronics"),
      Product(name: "Book", price: 19.99, category: "Education"),
      Product(name: "Phone", price: 599.99, category: "Electronics")
    ]

    # Check if first product is expensive electronics
    let first_is_expensive_electronics = match products:
      [Product(price > 500.0, category: "Electronics"), *rest]: true
      _: false

    check first_is_expensive_electronics == true  # Laptop matches

    # Extract first product name if it's electronics
    let first_electronics_name = match products:
      [Product(category: "Electronics"), *rest]: products[0].name
      _: "none"

    check first_electronics_name == "Laptop"

  test "structural matching vs filtering comparison":
    let numbers = @[1, 15, 3, 25, 8, 30]

    # Structural: check if first number is > 10
    let first_is_large = match numbers:
      [x] and x > 10: true
      [x, *rest] and x > 10: true
      _: false

    check first_is_large == false  # First number (1) is not > 10

    # To get all large numbers, use regular Nim filter (not pattern matching)
    let all_large = numbers.filter(proc(x: int): bool = x > 10)
    check all_large == @[15, 25, 30]

  test "empty and single element sequences":
    let empty_seq: seq[User] = @[]
    let single_user = @[User(name: "Alice", age: 25, active: true)]

    # Match empty sequence
    let empty_result = match empty_seq:
      []: "empty"
      [single]: "one user"
      [first, *rest]: "multiple users"

    check empty_result == "empty"

    # Match single element
    let single_result = match single_user:
      []: "empty"
      [User(age > 20)]: "young adult"
      [single]: "one user"
      [first, *rest]: "multiple users"

    check single_result == "young adult"

  test "destructuring with structural guards":
    let users = @[
      User(name: "Alice", age: 25, active: true),
      User(name: "Bob", age: 45, active: true),
      User(name: "Carol", age: 52, active: false)
    ]

    # Extract first and second users if first is young
    let (first_name, second_name) = match users:
      [User(age < 30), second, *rest]: (users[0].name, second.name)
      _: ("", "")

    check first_name == "Alice"
    check second_name == "Bob"

    # Try to match senior first user (should fail)
    let senior_first_result = match users:
      [User(age > 40), *rest]: "senior first"
      _: "not senior first"

    check senior_first_result == "not senior first"

  test "exact length matching":
    let trio = @[
      User(name: "Alice", age: 25, active: true),
      User(name: "Bob", age: 45, active: true),
      User(name: "Carol", age: 52, active: false)
    ]

    # Match exactly 3 users
    let is_trio = match trio:
      [_, _, _]: true
      _: false

    check is_trio == true

    # Match exactly 3 users with conditions on first
    let trio_with_young_first = match trio:
      [User(age < 30), _, _]: true
      _: false

    check trio_with_young_first == true