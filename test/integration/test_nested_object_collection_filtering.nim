import unittest
import std/lists
import std/deques
import std/tables
import sequtils
import ../../pattern_matching

# Test types for nested object patterns
type
  Address = object
    street: string
    city: string
    zipcode: string
    country: string

  Contact = object
    email: string
    phone: string

  User = object
    name: string
    age: int
    address: Address
    contact: Contact
    active: bool

suite "Nested Object Structural Pattern Matching":

  test "Nested object filtering functionality has been removed":
    let users = @[
      User(
        name: "Alice",
        age: 25,
        address: Address(street: "123 Main St", city: "Boston", zipcode: "02101", country: "USA"),
        contact: Contact(email: "alice@example.com", phone: "555-1234"),
        active: true
      ),
      User(
        name: "Bob",
        age: 45,
        address: Address(street: "456 Oak Ave", city: "Seattle", zipcode: "98101", country: "USA"),
        contact: Contact(email: "bob@example.com", phone: "555-5678"),
        active: true
      )
    ]

    # Structural: check if first user is from Boston
    let first_is_from_boston = match users:
      [User(address: Address(city: "Boston")), *rest]: true
      _: false

    check first_is_from_boston == true  # Alice is from Boston

    # For filtering by nested fields, use regular Nim operations
    let boston_users = users.filter(proc(u: User): bool = u.address.city == "Boston")
    check boston_users.len == 1
    check boston_users[0].name == "Alice"

  test "Nested object structural matching works correctly":
    let user = User(
      name: "Carol",
      age: 35,
      address: Address(street: "789 Pine St", city: "Portland", zipcode: "97201", country: "USA"),
      contact: Contact(email: "carol@example.com", phone: "555-9999"),
      active: true
    )

    # Structural matching on nested objects
    let is_from_portland = match user:
      User(address: Address(city: "Portland")): true
      _: false

    check is_from_portland == true

    # Extract nested field values
    let city = match user:
      User(address: Address(city=user_city)): user_city
      _: "unknown"

    check city == "Portland"