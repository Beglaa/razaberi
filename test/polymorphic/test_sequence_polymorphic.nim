import unittest
import ../../pattern_matching

# These tests currently FAIL but should work after implementation
# They test polymorphic patterns in sequences

suite "Sequence Polymorphic Patterns - To Implement":

  test "simple sequence with single polymorphic element":
    type
      Base = ref object of RootObj
        id: int

      Derived = ref object of Base
        name: string

    let derived: Base = Derived(id: 1, name: "test")
    let items: seq[Base] = @[derived]

    # This should match Derived in a sequence
    let result = match items:
      [Derived(id: i, name: n)]:
        "Found: " & n & " with id " & $i
      _:
        "Not found"

    check result == "Found: test with id 1"

  test "sequence with multiple polymorphic elements":
    type
      Animal = ref object of RootObj
        id: int

      Dog = ref object of Animal
        name: string
        breed: string

      Cat = ref object of Animal
        name: string
        lives: int

    let dog: Animal = Dog(id: 1, name: "Rex", breed: "Labrador")
    let cat: Animal = Cat(id: 2, name: "Whiskers", lives: 9)
    let animals: seq[Animal] = @[dog, cat]

    # Should match specific derived types in sequence
    let result = match animals:
      [Dog(name: d, breed: b), Cat(name: c, lives: l)]:
        d & " is a " & b & ", " & c & " has " & $l & " lives"
      _:
        "Pattern failed"

    check result == "Rex is a Labrador, Whiskers has 9 lives"

  test "sequence with spread and polymorphic":
    type
      Item = ref object of RootObj
        id: int

      Product = ref object of Item
        name: string
        price: float

      Service = ref object of Item
        name: string
        duration: int

    let p1: Item = Product(id: 1, name: "Book", price: 19.99)
    let s1: Item = Service(id: 2, name: "Consultation", duration: 60)
    let p2: Item = Product(id: 3, name: "Pen", price: 2.99)
    let items: seq[Item] = @[p1, s1, p2]

    # Should match first Product, then rest
    let result = match items:
      [Product(name: firstProduct), *rest]:
        "First product: " & firstProduct & ", rest count: " & $rest.len
      _:
        "No products"

    check result == "First product: Book, rest count: 2"

  test "array with polymorphic elements":
    type
      Shape = ref object of RootObj
        id: int

      Circle = ref object of Shape
        radius: float

      Square = ref object of Shape
        side: float

    let c: Shape = Circle(id: 1, radius: 5.0)
    let s: Shape = Square(id: 2, side: 10.0)
    let shapes: array[2, Shape] = [c, s]

    # Should match specific shapes in array
    let result = match shapes:
      [Circle(radius: r), Square(side: s)]:
        "Circle area: " & $(3.14 * r * r) & ", Square area: " & $(s * s)
      _:
        "Unknown shapes"

    check result == "Circle area: 78.5, Square area: 100.0"

  test "nested sequence with polymorphic":
    type
      Node = ref object of RootObj
        value: int

      Leaf = ref object of Node
        data: string

      Branch = ref object of Node
        left: Node
        right: Node

    let leaf1: Node = Leaf(value: 1, data: "A")
    let leaf2: Node = Leaf(value: 2, data: "B")
    let nodes: seq[seq[Node]] = @[@[leaf1], @[leaf2]]

    # Should match nested sequences with polymorphic
    let result = match nodes:
      [[Leaf(data: d1)], [Leaf(data: d2)]]:
        d1 & " and " & d2
      _:
        "Not leaves"

    check result == "A and B"

  test "sequence pattern with guards on polymorphic":
    type
      Vehicle = ref object of RootObj
        speed: int

      Car = ref object of Vehicle
        model: string

      Bike = ref object of Vehicle
        brand: string

    let car: Vehicle = Car(speed: 120, model: "Tesla")
    let bike: Vehicle = Bike(speed: 30, brand: "Trek")
    let vehicles: seq[Vehicle] = @[car, bike]

    # Should match with guards on polymorphic fields
    let result = match vehicles:
      [Car(speed: s1, model: m), Bike(speed: s2, brand: b)] and s1 > 100 and s2 < 50:
        "Fast " & m & " and slow " & b
      _:
        "Different speeds"

    check result == "Fast Tesla and slow Trek"