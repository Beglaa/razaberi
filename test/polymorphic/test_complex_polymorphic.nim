import unittest
import tables
import ../../pattern_matching

# These tests currently FAIL but should work after implementation
# They test complex polymorphic patterns

suite "Complex Polymorphic Patterns - To Implement":

  test "polymorphic with OR patterns":
    type
      Vehicle = ref object of RootObj
        speed: int

      Car = ref object of Vehicle
        model: string
        doors: int

      Bike = ref object of Vehicle
        brand: string
        gears: int

      Truck = ref object of Vehicle
        capacity: int

    let v1: Vehicle = Car(speed: 120, model: "Tesla", doors: 4)
    let v2: Vehicle = Bike(speed: 30, brand: "Trek", gears: 21)
    let v3: Vehicle = Truck(speed: 80, capacity: 5000)

    # Should support OR patterns with polymorphic types
    # Fixed: Separate patterns since they bind different variables
    let result1 = match v1:
      Car(model: m, doors: d):
        "Car: " & m & " with " & $d & " doors"
      Bike(brand: b, gears: g):
        "Bike: " & b & " with " & $g & " gears"
      Truck(capacity: c):
        "Truck with capacity: " & $c
      _:
        "Unknown"

    check result1 == "Car: Tesla with 4 doors"

    # Fixed: Use same variable name for both alternatives
    let result2 = match v2:
      Car(model: name) | Bike(brand: name):
        "Vehicle: " & name
      _:
        "Unknown"

    # Verify result2 identifies the bike correctly
    check result2 == "Vehicle: Trek"

  test "polymorphic with @ patterns":
    type
      Animal = ref object of RootObj
        age: int

      Dog = ref object of Animal
        name: string

      Cat = ref object of Animal
        nickname: string

    let pet: Animal = Dog(age: 5, name: "Rex")

    # Should support @ patterns with polymorphic types
    let result = match pet:
      Dog(name: n, age: a) @ d:
        "Dog " & n & " is " & $a & " years old, captured as: " & $(d != nil)
      Cat(nickname: n) @ c:
        "Cat " & n
      _:
        "Unknown"

    check result == "Dog Rex is 5 years old, captured as: true"

  test "polymorphic with complex guards":
    type
      Employee = ref object of RootObj
        id: int
        salary: float

      Manager = ref object of Employee
        teamSize: int
        bonus: float

      Developer = ref object of Employee
        language: string
        yearsExp: int

    let emp: Employee = Manager(id: 1, salary: 100000, teamSize: 10, bonus: 20000)

    # Should support complex guards with polymorphic patterns
    let result = match emp:
      Manager(salary: s, teamSize: t, bonus: b) and s > 90000 and t >= 10 and b > s * 0.15:
        "Senior manager with large team and good bonus"
      Developer(language: l, yearsExp: y) and l == "Nim" and y > 5:
        "Senior Nim developer"
      _:
        "Other employee"

    check result == "Senior manager with large team and good bonus"

  test "polymorphic with implicit guards":
    type
      Product = ref object of RootObj
        price: float

      Book = ref object of Product
        title: string
        pages: int

      Electronics = ref object of Product
        brand: string
        warranty: int

    let items = @[
      Book(price: 29.99, title: "Nim Guide", pages: 300),
      Electronics(price: 999.99, brand: "Apple", warranty: 12)
    ]

    # Should support implicit guards with polymorphic patterns
    let result = match items:
      [Book(price < 30, pages > 200), Electronics(warranty >= 12)]:
        "Affordable book and good warranty"
      _:
        "Other combination"

    check result == "Affordable book and good warranty"

  test "polymorphic with spread in sequences":
    type
      Task = ref object of RootObj
        id: int

      UrgentTask = ref object of Task
        priority: int

      RegularTask = ref object of Task
        description: string

    let t1: Task = UrgentTask(id: 1, priority: 1)
    let t2: Task = RegularTask(id: 2, description: "Do something")
    let t3: Task = UrgentTask(id: 3, priority: 2)
    let tasks: seq[Task] = @[t1, t2, t3]

    # Should support spread with polymorphic elements
    let result = match tasks:
      [UrgentTask(priority: 1), *middle, UrgentTask(priority: p)]:
        "Urgent at start and end, last priority: " & $p
      _:
        "Other pattern"

    check result == "Urgent at start and end, last priority: 2"

  test "polymorphic with default values":
    type
      Config = ref object of RootObj
        version: int

      AppConfig = ref object of Config
        appName: string
        port: int

      DBConfig = ref object of Config
        host: string
        dbPort: int

    var configs = initTable[string, Config]()
    configs["app"] = AppConfig(version: 1, appName: "MyApp", port: 8080)
    # Note: "db" key might not exist

    # Should support default patterns with polymorphic types
    let result = match configs:
      {"app": AppConfig(port: p), "db": (db = DBConfig(version: 1, host: "localhost", dbPort: 5432))}:
        "App port: " & $p & ", DB host: " & db.DBConfig.host
      _:
        "No match"

    check result == "App port: 8080, DB host: localhost"

  test "polymorphic pattern in nested collections":
    type
      Node = ref object of RootObj
        value: int

      Leaf = ref object of Node
        data: string

      Branch = ref object of Node
        left: Node
        right: Node

    let tree = Branch(
      value: 1,
      left: Leaf(value: 2, data: "L"),
      right: Branch(
        value: 3,
        left: Leaf(value: 4, data: "RL"),
        right: Leaf(value: 5, data: "RR")
      )
    )

    # Should handle recursive polymorphic patterns
    let result = match tree:
      Branch(
        value: v1,
        left: Leaf(data: leftData),
        right: Branch(
          left: Leaf(data: rlData),
          right: Leaf(data: rrData)
        )
      ):
        leftData & " -> (" & rlData & ", " & rrData & ")"
      _:
        "Other tree structure"

    check result == "L -> (RL, RR)"

  test "polymorphic with multiple inheritance levels":
    type
      Base = ref object of RootObj
        id: int

      Intermediate = ref object of Base
        level: int

      Derived = ref object of Intermediate
        name: string

      VeryDerived = ref object of Derived
        extra: string

    let obj: Base = VeryDerived(id: 1, level: 2, name: "test", extra: "data")

    # Should handle multiple levels of inheritance
    let result = match obj:
      VeryDerived(name: n, extra: e):
        "Very derived: " & n & " + " & e
      Derived(name: n):
        "Derived: " & n
      Intermediate(level: l):
        "Intermediate: " & $l
      _:
        "Base"

    check result == "Very derived: test + data"