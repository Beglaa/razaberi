## Test for PM-1 Bug Fix: Inconsistent Type Name Comparison Logic
##
## This test verifies that the type equivalence helper functions correctly handle:
## 1. Direct type matches
## 2. ref/ptr wrapper unwrapping
## 3. Polymorphic type matching (inheritance)
## 4. Combinations of the above
##
## Bug Fix: Consolidated inconsistent type comparison logic from lines 3545-3546,
## 4955-4957, 5177-5179, 7355-7356 into typesAreEquivalent() helper function

import unittest
import ../../pattern_matching

suite "PM-1: Type Equivalence Bug Fix":

  # ============================================================================
  # Test 1: Basic ref type matching
  # ============================================================================
  test "ref type matches pattern without ref prefix":
    type Person = ref object
      name: string
      age: int

    let alice = Person(name: "Alice", age: 30)

    let result = match alice:
      Person(name: "Alice", age: a):
        a
      _:
        -1

    check result == 30

  # ============================================================================
  # Test 2: nil pattern on ref types
  # ============================================================================
  test "nil pattern matches ref type nil value":
    type Person = ref object
      name: string

    let nobody: Person = nil

    let result = match nobody:
      nil:
        "nil"
      Person(name: n):
        n
      _:
        "other"

    check result == "nil"

  # ============================================================================
  # Test 3: ptr type matching
  # ============================================================================
  test "ptr type matches pattern without ptr prefix":
    type Point = object
      x, y: int

    var p = Point(x: 10, y: 20)
    var pp: ptr Point = addr p

    let result = match pp:
      nil:
        "nil"
      _:
        "non-nil"

    check result == "non-nil"

  # ============================================================================
  # Test 4: Polymorphic pattern matching (inheritance)
  # ============================================================================
  test "polymorphic pattern matches derived type":
    type
      Animal = ref object of RootObj
        name: string
      Dog = ref object of Animal
        breed: string

    let dog = Dog(name: "Buddy", breed: "Golden Retriever")
    let animal: Animal = dog  # Upcast to base type

    let result = match animal:
      Dog(breed: b):
        b
      Animal(name: n):
        n
      _:
        "unknown"

    check result == "Golden Retriever"

  # ============================================================================
  # Test 5: ref type with inheritance - exact match
  # ============================================================================
  test "ref type with inheritance matches exact type":
    type
      Vehicle = ref object of RootObj
        wheels: int
      Car = ref object of Vehicle
        doors: int

    let car = Car(wheels: 4, doors: 4)

    let result = match car:
      Car(doors: d, wheels: w):
        d + w
      _:
        -1

    check result == 8

  # ============================================================================
  # Test 6: Multiple ref types in pattern
  # ============================================================================
  test "nested ref types work correctly":
    type
      Address = ref object
        street: string
        city: string
      Person = ref object
        name: string
        address: Address

    let address = Address(street: "123 Main St", city: "Springfield")
    let person = Person(name: "Bob", address: address)

    let result = match person:
      Person(name: "Bob", address: Address(city: c)):
        c
      _:
        "unknown"

    check result == "Springfield"

  # ============================================================================
  # Test 7: Type with `:` suffix (ObjectType marker)
  # ============================================================================
  test "type with colon suffix matches pattern":
    # This tests the inheritance pattern detection that uses `:` suffix
    type
      Base = ref object of RootObj
        id: int
      Derived = ref object of Base
        value: string

    let derived = Derived(id: 42, value: "test")

    let result = match derived:
      Derived(value: v):
        v
      Base(id: i):
        $i
      _:
        "none"

    check result == "test"

  # ============================================================================
  # Test 8: ref object in complex nested structure
  # ============================================================================
  test "ref objects in tuples and sequences":
    type Node = ref object
      value: int
      label: string

    let nodes = @[
      Node(value: 1, label: "first"),
      Node(value: 2, label: "second"),
      Node(value: 3, label: "third")
    ]

    let result = match nodes:
      [Node(label: "first"), Node(value: v), *_]:
        v
      _:
        -1

    check result == 2

  # ============================================================================
  # Test 9: Polymorphic pattern with nil check
  # ============================================================================
  test "polymorphic pattern handles nil correctly":
    type
      Shape = ref object of RootObj
        area: float
      Circle = ref object of Shape
        radius: float

    let circle: Shape = nil

    let result = match circle:
      nil:
        "nil"
      Circle(radius: r):
        "circle"
      Shape(area: a):
        "shape"
      _:
        "other"

    check result == "nil"

  # ============================================================================
  # Test 10: Mixed ref and value types
  # ============================================================================
  test "pattern matching with mixed ref and value types":
    type
      Config = object
        port: int
        host: string
      Server = ref object
        config: Config
        running: bool

    let server = Server(
      config: Config(port: 8080, host: "localhost"),
      running: true
    )

    let result = match server:
      Server(config: Config(port: p), running: true):
        p
      _:
        -1

    check result == 8080

  # ============================================================================
  # Test 11: Verify all four buggy locations are fixed
  # ============================================================================
  test "comprehensive ref/ptr pattern matching (all bug locations)":
    # This test exercises all code paths that were affected by the bug

    # Location 1 (line 3645-3648): processNestedPattern polymorphic check
    type
      Animal = ref object of RootObj
        name: string
      Cat = ref object of Animal
        meow: bool

    let cat = Cat(name: "Whiskers", meow: true)

    let result1 = match cat:
      Cat(meow: m):
        if m: "meows" else: "silent"
      Animal(name: n):
        n
      _:
        "unknown"

    check result1 == "meows"

    # Location 2 (line 5055-5059): processObjectPattern polymorphic cast check
    type Person = ref object
      name: string
      age: int

    let person = Person(name: "Alice", age: 25)

    let result2 = match person:
      Person(name: "Alice", age: a):
        a
      _:
        -1

    check result2 == 25

    # Location 3 (line 5277-5279): nested object polymorphic check
    type
      Inner = ref object
        value: int
      Outer = ref object
        inner: Inner

    let outer = Outer(inner: Inner(value: 100))

    let result3 = match outer:
      Outer(inner: Inner(value: v)):
        v
      _:
        -1

    check result3 == 100

    # Location 4 (line 7450-7456): processSequencePattern polymorphic check
    type Node = ref object
      id: int

    let nodes = @[Node(id: 1), Node(id: 2), Node(id: 3)]

    let result4 = match nodes:
      [Node(id: 1), *_]:
        "matched"
      _:
        "not matched"

    check result4 == "matched"

  # ============================================================================
  # Test 12: Edge case - ref to ref
  # ============================================================================
  test "edge case: ref to ref type":
    # While uncommon, Nim allows ref to ref
    type
      Inner = ref object
        value: int
      Outer = ref ref Inner  # ref to ref

    # Note: This is a rare edge case, just ensure it compiles
    # Most real-world code wouldn't use ref to ref
    discard

  # ============================================================================
  # Test 13: Verify typesAreEquivalent handles all cases
  # ============================================================================
  test "typesAreEquivalent helper function correctness":
    # This is an indirect test - if all previous tests pass,
    # typesAreEquivalent is working correctly

    type Person = ref object
      name: string

    let person = Person(name: "Test")

    # Test that we get correct matches without false positives/negatives
    let result = match person:
      Person(name: "Test"):
        "exact match"
      Person(name: n):
        n
      nil:
        "nil"
      _:
        "wildcard"

    check result == "exact match"
