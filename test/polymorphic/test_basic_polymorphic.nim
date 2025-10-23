import unittest
import ../../pattern_matching

# These tests should PASS with current implementation
# They verify basic polymorphic functionality that already works

suite "Basic Polymorphic Patterns - Currently Working":

  test "polymorphic as direct object field":
    type
      Animal = ref object of RootObj
        id: int
        age: int

      Dog = ref object of Animal
        name: string
        breed: string

      Cat = ref object of Animal
        name: string
        lives: int

      PetOwner = object
        pet: Animal
        ownerName: string

    let owner1 = PetOwner(
      pet: Dog(id: 1, age: 5, name: "Rex", breed: "German Shepherd"),
      ownerName: "Alice"
    )

    let result = match owner1:
      PetOwner(pet: Dog(name: n, breed: b), ownerName: o):
        o & " owns " & n & " (" & b & ")"
      PetOwner(pet: Cat(name: n, lives: l), ownerName: o):
        o & " owns " & n & " with " & $l & " lives"
      _:
        "Unknown pet"

    check result == "Alice owns Rex (German Shepherd)"

  test "polymorphic as direct tuple field":
    type
      Shape = ref object of RootObj
        id: int

      Circle = ref object of Shape
        radius: float

      Rectangle = ref object of Shape
        width: float
        height: float

    # IMPORTANT: Explicit type annotation required for polymorphism
    # Without explicit type, Nim infers tuple[shape: Circle, ...] which prevents polymorphic matching
    let data: tuple[shape: Shape, label: string] = (shape: Circle(id: 1, radius: 5.0), label: "circle1")

    let result = match data:
      (shape: Circle(radius: r), label: l):
        l & " has radius " & $r
      (shape: Rectangle(width: w, height: h), label: l):
        l & " has area " & $(w * h)
      _:
        "Unknown shape"

    check result == "circle1 has radius 5.0"

  test "simple field patterns within polymorphic types":
    type
      Vehicle = ref object of RootObj
        id: int

      Car = ref object of Vehicle
        model: string
        year: int

      Bike = ref object of Vehicle
        brand: string
        gears: int

      Garage = object
        vehicle: Vehicle

    let garage = Garage(vehicle: Car(id: 1, model: "Tesla", year: 2023))

    # Test literal matching in polymorphic field
    let result1 = match garage:
      Garage(vehicle: Car(model: "Tesla", year: y)):
        "Tesla from " & $y
      _:
        "Not a Tesla"

    check result1 == "Tesla from 2023"

    # Test variable binding in polymorphic field
    let result2 = match garage:
      Garage(vehicle: Car(model: m, year: y)) and y > 2020:
        "Modern " & m
      _:
        "Old or not a car"

    check result2 == "Modern Tesla"

  test "polymorphic with guards":
    type
      Employee = ref object of RootObj
        id: int
        baseSalary: float

      Manager = ref object of Employee
        teamSize: int
        bonus: float

      Developer = ref object of Employee
        language: string
        level: string

      Company = object
        employee: Employee

    let company1 = Company(employee: Manager(id: 1, baseSalary: 100000, teamSize: 10, bonus: 20000))
    let company2 = Company(employee: Developer(id: 2, baseSalary: 80000, language: "Nim", level: "Senior"))

    let result1 = match company1:
      Company(employee: Manager(teamSize: t, bonus: b)) and t > 5 and b > 10000:
        "Large team manager with good bonus"
      _:
        "Other"

    check result1 == "Large team manager with good bonus"

    let result2 = match company2:
      Company(employee: Developer(language: "Nim", level: l)) and l == "Senior":
        "Senior Nim developer"
      _:
        "Other"

    check result2 == "Senior Nim developer"

  test "tuple fields inside polymorphic types":
    type
      Entity = ref object of RootObj
        id: int

      Player = ref object of Entity
        name: string
        position: tuple[x: float, y: float]

      Enemy = ref object of Entity
        enemyType: string
        health: int

      Game = object
        entity: Entity

    let game = Game(entity: Player(id: 1, name: "Hero", position: (x: 10.0, y: 20.0)))

    let result = match game:
      Game(entity: Player(name: n, position: (x: xPos, y: yPos))):
        n & " at (" & $xPos & ", " & $yPos & ")"
      _:
        "Not a player"

    check result == "Hero at (10.0, 20.0)"