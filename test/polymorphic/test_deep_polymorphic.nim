import unittest
import tables
import ../../pattern_matching

# These tests currently FAIL but should work after implementation
# They test deep nesting with polymorphic patterns

suite "Deep Nested Polymorphic Patterns - To Implement":

  test "object -> object -> polymorphic":
    type
      Base = ref object of RootObj
        id: int

      Derived = ref object of Base
        value: string

      Inner = object
        item: Base

      Outer = object
        inner: Inner

    let data = Outer(inner: Inner(item: Derived(id: 1, value: "deep")))

    # Should handle multiple object nesting levels
    let result = match data:
      Outer(inner: Inner(item: Derived(id: i, value: v))):
        "Deep: " & v & " with id " & $i
      _:
        "Failed"

    check result == "Deep: deep with id 1"

  test "tuple -> object -> polymorphic":
    # This currently works, but let's ensure it continues to work
    type
      Animal = ref object of RootObj
        age: int

      Dog = ref object of Animal
        name: string

      Container = object
        pet: Animal

    let data = (box: Container(pet: Dog(age: 5, name: "Rex")), label: "test")

    let result = match data:
      (box: Container(pet: Dog(name: n)), label: l):
        n & " in " & l
      _:
        "Failed"

    check result == "Rex in test"

  test "object -> tuple -> polymorphic":
    type
      Shape = ref object of RootObj
        id: int

      Circle = ref object of Shape
        radius: float

      Wrapper = object
        data: tuple[shape: Shape, count: int]

    let data = Wrapper(data: (shape: Circle(id: 1, radius: 5.0), count: 3))

    # Should handle object -> tuple -> polymorphic
    let result = match data:
      Wrapper(data: (shape: Circle(radius: r), count: c)):
        "Circle r=" & $r & " count=" & $c
      _:
        "Failed"

    check result == "Circle r=5.0 count=3"

  test "sequence -> object -> polymorphic":
    type
      Base = ref object of RootObj
        id: int

      Derived = ref object of Base
        name: string

      Container = object
        item: Base

    let containers = @[
      Container(item: Derived(id: 1, name: "first")),
      Container(item: Derived(id: 2, name: "second"))
    ]

    # Should handle sequence of objects with polymorphic fields
    let result = match containers:
      [Container(item: Derived(name: n1)), Container(item: Derived(name: n2))]:
        n1 & " and " & n2
      _:
        "Failed"

    check result == "first and second"

  test "table -> object -> polymorphic":
    type
      Vehicle = ref object of RootObj
        speed: int

      Car = ref object of Vehicle
        model: string

      Garage = object
        vehicle: Vehicle

    var garages = initTable[string, Garage]()
    garages["g1"] = Garage(vehicle: Car(speed: 120, model: "Tesla"))
    garages["g2"] = Garage(vehicle: Car(speed: 100, model: "Toyota"))

    # Should handle table values containing objects with polymorphic fields
    let result = match garages:
      {"g1": Garage(vehicle: Car(model: m1)), "g2": Garage(vehicle: Car(model: m2))}:
        m1 & " and " & m2
      _:
        "Failed"

    check result == "Tesla and Toyota"

  test "arbitrary depth nesting":
    type
      Base = ref object of RootObj
        value: int

      Derived = ref object of Base
        data: string

      L5 = object
        item: Base

      L4 = object
        l5: L5

      L3 = object
        l4: L4

      L2 = tuple[l3: L3, count: int]

      L1 = object
        l2: L2

    let data = L1(
      l2: (
        l3: L3(
          l4: L4(
            l5: L5(
              item: Derived(value: 42, data: "deep_value")
            )
          )
        ),
        count: 99
      )
    )

    # Should handle arbitrary depth with polymorphism at the bottom
    let result = match data:
      L1(l2: (l3: L3(l4: L4(l5: L5(item: Derived(value: v, data: d)))), count: c)):
        "Value: " & $v & ", Data: " & d & ", Count: " & $c
      _:
        "Failed"

    check result == "Value: 42, Data: deep_value, Count: 99"

  test "complex nested pattern inside polymorphic type":
    type
      Base = ref object of RootObj
        id: int

      Inner = object
        value: int
        name: string

      Derived = ref object of Base
        nested: Inner

      Container = object
        item: Base

    let data = Container(item: Derived(id: 1, nested: Inner(value: 99, name: "test")))

    # Should handle nested object patterns inside polymorphic types
    let result = match data:
      Container(item: Derived(id: i, nested: Inner(value: v, name: n))):
        "ID: " & $i & ", Value: " & $v & ", Name: " & n
      _:
        "Failed"

    check result == "ID: 1, Value: 99, Name: test"

  test "mixed collection nesting with polymorphism":
    type
      Item = ref object of RootObj
        id: int

      Product = ref object of Item
        name: string

      Box = object
        items: seq[Item]

    var storage = initTable[string, Box]()
    storage["box1"] = Box(items: @[
      Item(Product(id: 1, name: "Apple")),
      Item(Product(id: 2, name: "Banana"))
    ])

    # Should handle table -> object -> sequence -> polymorphic
    let result = match storage:
      {"box1": Box(items: [Product(name: n1), Product(name: n2)])}:
        n1 & " and " & n2
      _:
        "Failed"

    check result == "Apple and Banana"