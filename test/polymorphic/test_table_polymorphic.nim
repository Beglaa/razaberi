import unittest
import tables
import ../../pattern_matching

# These tests currently FAIL but should work after implementation
# They test polymorphic patterns in tables

suite "Table Polymorphic Patterns - To Implement":

  test "simple table with polymorphic value":
    type
      Base = ref object of RootObj
        id: int

      Derived = ref object of Base
        name: string

    var tbl = initTable[string, Base]()
    tbl["key1"] = Derived(id: 1, name: "first")

    # Should match Derived value in table
    let result = match tbl:
      {"key1": Derived(id: i, name: n)}:
        "Found: " & n & " with id " & $i
      _:
        "Not found"

    check result == "Found: first with id 1"

  test "table with multiple polymorphic values":
    type
      Shape = ref object of RootObj
        id: int

      Circle = ref object of Shape
        radius: float

      Square = ref object of Shape
        side: float

    var shapes = initTable[string, Shape]()
    shapes["c1"] = Circle(id: 1, radius: 5.0)
    shapes["s1"] = Square(id: 2, side: 10.0)

    # Should match specific derived types in table
    let result = match shapes:
      {"c1": Circle(radius: r), "s1": Square(side: s)}:
        "Circle area: " & $(3.14 * r * r) & ", Square area: " & $(s * s)
      _:
        "Unknown shapes"

    check result == "Circle area: 78.5, Square area: 100.0"

  test "table with polymorphic and rest pattern":
    type
      Item = ref object of RootObj
        value: int

      Product = ref object of Item
        name: string
        price: float

      Service = ref object of Item
        serviceName: string
        hours: int

    var items = initTable[string, Item]()
    items["p1"] = Product(value: 100, name: "Book", price: 19.99)
    items["s1"] = Service(value: 200, serviceName: "Consulting", hours: 2)
    items["p2"] = Product(value: 300, name: "Pen", price: 2.99)

    # Should match specific item and capture rest
    let result = match items:
      {"p1": Product(name: n, price: p), **rest}:
        n & " costs " & $p & ", rest count: " & $rest.len
      _:
        "No match"

    check result == "Book costs 19.99, rest count: 2"

  test "ordered table with polymorphic values":
    type
      Vehicle = ref object of RootObj
        speed: int

      Car = ref object of Vehicle
        model: string

      Bike = ref object of Vehicle
        brand: string

    var vehicles = initOrderedTable[string, Vehicle]()
    vehicles["v1"] = Car(speed: 120, model: "Tesla")
    vehicles["v2"] = Bike(speed: 30, brand: "Trek")

    # Should work with OrderedTable too
    let result = match vehicles:
      {"v1": Car(model: m), "v2": Bike(brand: b)}:
        m & " and " & b
      _:
        "Unknown"

    check result == "Tesla and Trek"

  test "nested table with polymorphic values":
    type
      Animal = ref object of RootObj
        age: int

      Dog = ref object of Animal
        name: string

      Cat = ref object of Animal
        nickname: string

    var innerTable1 = initTable[string, Animal]()
    innerTable1["pet"] = Dog(age: 5, name: "Rex")

    var innerTable2 = initTable[string, Animal]()
    innerTable2["pet"] = Cat(age: 3, nickname: "Whiskers")

    var outer = initTable[string, Table[string, Animal]]()
    outer["alice"] = innerTable1
    outer["bob"] = innerTable2

    # Should match nested tables with polymorphic values
    let result = match outer:
      {"alice": {"pet": Dog(name: d)}, "bob": {"pet": Cat(nickname: c)}}:
        "Alice has " & d & ", Bob has " & c
      _:
        "Unknown pets"

    check result == "Alice has Rex, Bob has Whiskers"

  test "table with polymorphic values and guards":
    type
      Employee = ref object of RootObj
        salary: float

      Manager = ref object of Employee
        teamSize: int

      Developer = ref object of Employee
        language: string

    var employees = initTable[string, Employee]()
    employees["m1"] = Manager(salary: 100000, teamSize: 10)
    employees["d1"] = Developer(salary: 80000, language: "Nim")

    # Should match with guards on polymorphic fields
    let result = match employees:
      {"m1": Manager(salary: s, teamSize: t), "d1": Developer(language: l)} and t > 5 and s > 90000:
        "Large team manager and " & l & " developer"
      _:
        "Other configuration"

    check result == "Large team manager and Nim developer"