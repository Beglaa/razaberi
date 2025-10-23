import unittest
import sequtils  # For filter function
import ../../pattern_matching

type
  User = object
    name: string
    age: int
    active: bool

  Point = object
    x: float
    y: float

  Rectangle = object
    topLeft: Point
    width: float
    height: float

  Product = object
    name: string
    price: float
    category: string
    inStock: bool

suite "Structural Object Pattern Matching":

  test "simple object guard patterns":
    let user = User(name: "Alice", age: 25, active: true)

    # Test age guards
    let is_young = match user:
      User(age < 30): true
      _: false

    check is_young == true

    let is_senior = match user:
      User(age > 40): true
      _: false

    check is_senior == false

    # Test boolean field guards
    let is_active = match user:
      User(active: true): true
      _: false

    check is_active == true

  test "multiple field guards with AND logic":
    let product = Product(name: "Laptop", price: 999.99, category: "Electronics", inStock: true)

    # Test multiple conditions
    let is_expensive_electronics = match product:
      Product(price > 500.0, category: "Electronics"): true
      _: false

    check is_expensive_electronics == true

    let is_cheap_available_book = match product:
      Product(price < 50.0, category: "Books", inStock: true): true
      _: false

    check is_cheap_available_book == false  # Wrong category and price

  test "field extraction with guards":
    let user = User(name: "Bob", age: 45, active: true)

    # Extract name if user is senior
    let senior_name = match user:
      User(age > 40, name): name
      _: "not senior"

    check senior_name == "Bob"

    # Extract age if user is active
    let active_user_age = match user:
      User(active: true, age): age
      _: 0

    check active_user_age == 45

  test "nested object patterns":
    let rect = Rectangle(
      topLeft: Point(x: 10.0, y: 20.0),
      width: 100.0,
      height: 50.0
    )

    # Match nested structure with guards
    let has_positive_coords = match rect:
      Rectangle(topLeft: Point(x > 0.0, y > 0.0)): true
      _: false

    check has_positive_coords == true

    # Extract nested values with guards
    let (x_coord, area) = match rect:
      Rectangle(topLeft: Point(x), width, height) and width * height > 1000.0: (x, width * height)
      _: (0.0, 0.0)

    check x_coord == 10.0
    check area == 5000.0  # 100 * 50

  test "exact value matching vs guard patterns":
    let user1 = User(name: "Alice", age: 25, active: true)
    let user2 = User(name: "Bob", age: 25, active: false)

    # Exact value matching
    let alice_exact = match user1:
      User(name: "Alice", age: 25, active: true): true
      _: false

    check alice_exact == true

    let bob_exact = match user2:
      User(name: "Alice", age: 25, active: true): true
      _: false

    check bob_exact == false  # Wrong name and activity

    # Guard pattern matching
    let has_age_25 = match user2:
      User(age: 25): true
      _: false

    check has_age_25 == true  # Bob also has age 25

  test "complex guard expressions":
    let products = @[
      Product(name: "Book", price: 19.99, category: "Education", inStock: true),
      Product(name: "Laptop", price: 999.99, category: "Electronics", inStock: false),
      Product(name: "Pen", price: 2.99, category: "Office", inStock: true)
    ]

    # Test complex guards on sequence elements
    let first_is_cheap_available = match products:
      [Product(price < 20.0, inStock: true), *rest]: true
      _: false

    check first_is_cheap_available == true  # Book matches

    let first_is_expensive_unavailable = match products:
      [Product(price > 500.0, inStock: false), *rest]: true
      _: false

    check first_is_expensive_unavailable == false  # Book doesn't match

  test "guard patterns vs regular boolean expressions":
    let user = User(name: "Charlie", age: 35, active: true)

    # Guard pattern in object
    let middle_aged_active = match user:
      User(age > 30, age < 50, active: true): true
      _: false

    check middle_aged_active == true

    # This demonstrates that guards check field values, not arbitrary expressions
    let name_length_check = match user:
      User(name) and name.len > 5: true  # name.len is evaluated after extraction
      _: false

    check name_length_check == true  # "Charlie" has 7 characters

  test "structural matching prevents filtering behavior":
    let users = @[
      User(name: "Alice", age: 25, active: true),
      User(name: "Bob", age: 45, active: true),
      User(name: "Carol", age: 52, active: false)
    ]

    # This should NOT filter all senior users (old filtering behavior)
    # Instead, it should check if the FIRST user is senior
    let result = match users:
      [User(age > 40), *rest]: "first is senior"
      [User(age <= 40), *rest]: "first is not senior"
      _: "empty"

    check result == "first is not senior"  # Alice (25) is not > 40

    # To actually get senior users, use regular Nim filter
    let seniors = users.filter(proc(u: User): bool = u.age > 40)
    check seniors.len == 2  # Bob and Carol
    check seniors[0].name == "Bob"
    check seniors[1].name == "Carol"