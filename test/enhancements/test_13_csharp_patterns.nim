import ../../pattern_matching
import std/[unittest, options, tables]

## This test file demonstrates all 13 C# pattern matching patterns
## using proper Nim syntax in the pattern matching library

suite "13 C# Pattern Matching Patterns - Nim Implementation":

  # ============================================================================
  # 1. TYPE PATTERN - Check actual type of object
  # ============================================================================
  test "1. Type Pattern - Check if object is of specific type":
    type
      Entity = ref object of RootObj

      Developer = ref object of Entity
        available: bool

    proc isDeveloper(entity: Entity): bool =
      match entity:
        x of Developer: true
        _: false

    check isDeveloper(Entity()) == false
    check isDeveloper(Developer(available: true)) == true

  # ============================================================================
  # 2. DECLARATION PATTERN - Type check + property access
  # ============================================================================
  test "2. Declaration Pattern - Type check and access properties":
    type
      Entity = ref object of RootObj

      Developer = ref object of Entity
        available: bool

    proc isDeveloperAvailable(entity: Entity): bool =
      match entity:
        dev of Developer:
          Developer(dev).available
        _:
          false

    check isDeveloperAvailable(Entity()) == false
    check isDeveloperAvailable(Developer(available: false)) == false
    check isDeveloperAvailable(Developer(available: true)) == true

  test "2. Declaration Pattern - Simplified with object destructuring":
    type
      Entity = ref object of RootObj

      Developer = ref object of Entity
        available: bool

    proc isDeveloperAvailable(dev: Entity): bool =
      match dev:
        Developer(available: true): true
        _: false

    check isDeveloperAvailable(Developer(available: false)) == false
    check isDeveloperAvailable(Developer(available: true)) == true

  # ============================================================================
  # 3. NULL CONSTANT PATTERN - Check for nil
  # ============================================================================
  test "3. Null Constant Pattern - Check if reference is nil":
    type Entity = ref object of RootObj

    var entity: Entity = nil

    let result1 = match entity:
      e and e.isNil: "is nil"
      _: "not nil"

    check result1 == "is nil"

    entity = Entity()
    let result2 = match entity:
      e and e.isNil: "is nil"
      _: "not nil"

    check result2 == "not nil"

  # ============================================================================
  # 4. NEGATED NULL CONSTANT PATTERN - Check for not nil
  # ============================================================================
  test "4. Negated Null Constant Pattern - Check if reference is not nil":
    type Entity = ref object of RootObj

    var entity: Entity = Entity()

    let result1 = match entity:
      e and not e.isNil: "not nil"
      _: "is nil"

    check result1 == "not nil"

    entity = nil
    let result2 = match entity:
      e and not e.isNil: "not nil"
      _: "is nil"

    check result2 == "is nil"

  # ============================================================================
  # 5. CONSTANT PATTERN - Match expression to constant value
  # ============================================================================
  test "5. Constant Pattern - Match to constant values":
    proc getDisplayValue(val: int): string =
      match val:
        1: "One"
        2: "Two"
        3: "Three"
        _: "Other"

    check getDisplayValue(1) == "One"
    check getDisplayValue(2) == "Two"
    check getDisplayValue(3) == "Three"
    check getDisplayValue(99) == "Other"

  # ============================================================================
  # 6. LIST PATTERN - Match collection against sequential items
  # ============================================================================
  test "6. List Pattern - Compare sequences":
    proc compare(): bool =
      let characters = @['t', 'e', 's', 't']

      match characters:
        ['t', 'e', 's', 't']: true
        _: false

    check compare() == true

  test "6. List Pattern - Extract first element with conditions":
    proc getFirstElement(): Option[int] =
      let numbers = @[1, 2, 3]

      match numbers:
        [first, _, third] and third > 0: some(first)
        _: none(int)

    check getFirstElement() == some(1)

  test "6. List Pattern - Wildcard for ignored elements":
    proc getFirstAndThird(): (int, int) =
      let numbers = @[10, 20, 30]

      match numbers:
        [first, _, third]: (first, third)
        _: (0, 0)

    check getFirstAndThird() == (10, 30)

  # ============================================================================
  # 7. LOGICAL PATTERN - Combine patterns with not, and, or
  # ============================================================================
  test "7. Logical Pattern - Use and for range checking":
    proc isPercentageValid(percentage: int): bool =
      match percentage:
        p and p >= 0 and p <= 100: true
        _: false

    check isPercentageValid(-1) == false
    check isPercentageValid(0) == true
    check isPercentageValid(50) == true
    check isPercentageValid(100) == true
    check isPercentageValid(101) == false

  test "7. Logical Pattern - Use or for multiple conditions":
    proc isExitCommand(cmd: string): bool =
      match cmd:
        "exit" | "quit" | "q": true
        _: false

    check isExitCommand("exit") == true
    check isExitCommand("quit") == true
    check isExitCommand("q") == true
    check isExitCommand("help") == false

  # ============================================================================
  # 8. PROPERTY PATTERN - Match object properties
  # ============================================================================
  test "8. Property Pattern - Match object with specific properties":
    type
      Developer = ref object
        profile: string
        location: string
        salary: float

    proc isApplicableForTheProject(developer: Developer): bool =
      match developer:
        Developer(profile: ".NET", location: "Europe", salary: s) and s < 3000:
          true
        _:
          false

    let dev1 = Developer(profile: ".NET", location: "Europe", salary: 2500)
    let dev2 = Developer(profile: ".NET", location: "Europe", salary: 3500)
    let dev3 = Developer(profile: "Java", location: "Europe", salary: 2500)

    check isApplicableForTheProject(dev1) == true
    check isApplicableForTheProject(dev2) == false
    check isApplicableForTheProject(dev3) == false

  # ============================================================================
  # 9. EXTENDED PROPERTY PATTERN - Match nested properties
  # ============================================================================
  test "9. Extended Property Pattern - Access nested properties":
    type
      Address = ref object
        country: string

      Person = ref object
        address: Address

    proc isCountryNotApplicable(person: Person): bool =
      match person:
        Person(address: Address(country: "N/A")): true
        _: false

    let person1 = Person(address: Address(country: "N/A"))
    let person2 = Person(address: Address(country: "USA"))

    check isCountryNotApplicable(person1) == true
    check isCountryNotApplicable(person2) == false

  # ============================================================================
  # 10. TUPLE PATTERN - Match multiple properties in tuple
  # ============================================================================
  test "10. Tuple Pattern - Match multiple properties together":
    type
      Developer = ref object
        role: string
        isPro: bool

    proc getTitle(developer: Developer): string =
      match (developer.role, developer.isPro):
        ("Senior", true): "Senior Pro Developer"
        ("Junior", false): "Junior Developer"
        ("Senior", false): "Senior Developer"
        ("Junior", true): "Junior Pro Developer"
        _: "Unknown"

    let dev1 = Developer(role: "Senior", isPro: true)
    let dev2 = Developer(role: "Junior", isPro: false)
    let dev3 = Developer(role: "Senior", isPro: false)

    check getTitle(dev1) == "Senior Pro Developer"
    check getTitle(dev2) == "Junior Developer"
    check getTitle(dev3) == "Senior Developer"

  # ============================================================================
  # 11. RELATIONAL PATTERN - Use <, >, <=, >= operators
  # ============================================================================
  test "11. Relational Pattern - Use comparison operators":
    proc getDisplayValueForPrice(price: float): string =
      match price:
        p and p <= 100: "Cheap" #explicit
        p > 100 and p < 1000: "Regular price" # Implicit without `p and `
        p >= 1000 and p < 3000: "Expensive"
        p >= 3000 and p < 10000: "Too expensive"
        _: "Wrong price"

    check getDisplayValueForPrice(50.0) == "Cheap"
    check getDisplayValueForPrice(500.0) == "Regular price"
    check getDisplayValueForPrice(2000.0) == "Expensive"
    check getDisplayValueForPrice(5000.0) == "Too expensive"
    check getDisplayValueForPrice(15000.0) == "Wrong price"

  # ============================================================================
  # 12. PARENTHESIZED PATTERN - Group logical expressions
  # ============================================================================
  test "12. Parenthesized Pattern - Control execution order":
    proc getDisplayValueForPrice(price: float): string =
      match price:
        p and (p <= 100 or (p >= 150 and p < 180)): "Cheap"
        p > 100 and p < 1000: "Regular price"
        p >= 1000 and p < 3000: "Expensive"
        _: "Other"

    check getDisplayValueForPrice(50.0) == "Cheap"
    check getDisplayValueForPrice(160.0) == "Cheap"
    check getDisplayValueForPrice(120.0) == "Regular price"
    check getDisplayValueForPrice(2000.0) == "Expensive"

  test "12. Parenthesized Pattern - OR groups":
    proc checkValue(x: int): string =
      match x:
        v and ((v >= 1 and v <= 10) or (v >= 20 and v <= 30)): "in range"
        _: "out of range"

    check checkValue(5) == "in range"
    check checkValue(25) == "in range"
    check checkValue(15) == "out of range"

  # ============================================================================
  # 13. DISCARD PATTERN - Wildcard match
  # ============================================================================
  test "13. Discard Pattern - Default case with underscore":
    proc classify(x: int): string =
      match x:
        1: "one"
        2: "two"
        _: "other"

    check classify(1) == "one"
    check classify(2) == "two"
    check classify(999) == "other"

  test "13. Discard Pattern - Ignore elements in destructuring":
    proc getFirstAndLast(): (int, int) =
      let numbers = @[1, 2, 3, 4, 5]

      match numbers:
        [first, _, _, _, last]: (first, last)
        _: (0, 0)

    check getFirstAndLast() == (1, 5)

  test "13. Discard Pattern - Ignore in tuple":
    proc getSecond(): int =
      let pair = (10, 20)

      match pair:
        (_, second): second
        _: 0

    check getSecond() == 20

  # ============================================================================
  # BONUS: Combined complex patterns showing library power
  # ============================================================================
  test "BONUS: Combined Pattern - Multiple C# patterns together":
    type
      Entity = ref object of RootObj
        id: int

      Developer = ref object of Entity
        profile: string
        location: string
        salary: float
        role: string
        isPro: bool
        available: bool

    proc evaluateDeveloper(entity: Entity): string =
      match entity:
        e and e.isNil:
          "No developer"
        e of Developer:
          # Once we know it's a Developer, we can safely cast and access fields
          let dev = Developer(e)
          if dev.profile == ".NET" and dev.location == "Europe" and dev.salary < 2000:
            "Budget .NET Developer"
          elif dev.role == "Senior" and dev.isPro and (dev.profile == ".NET" or dev.profile == "Rust"):
            "Elite Senior Developer"
          elif dev.available and dev.salary >= 5000:
            "Expensive Available Developer"
          else:
            "Some developer"
        _:
          "Not a developer"

    let dev1 = Developer(id: 1, profile: ".NET", location: "Europe", salary: 1500)
    let dev2 = Developer(id: 2, profile: ".NET", role: "Senior", isPro: true)
    let dev3 = Developer(id: 3, available: true, salary: 6000)
    let dev4 = Developer(id: 4, profile: "Java")

    check evaluateDeveloper(dev1) == "Budget .NET Developer"
    check evaluateDeveloper(dev2) == "Elite Senior Developer"
    check evaluateDeveloper(dev3) == "Expensive Available Developer"
    check evaluateDeveloper(dev4) == "Some developer"
    check evaluateDeveloper(Entity(id: 0)) == "Not a developer"
    check evaluateDeveloper(nil) == "No developer"

  # ============================================================================
  # BONUS: Demonstrating unique Nim advantages
  # ============================================================================
  test "BONUS: Nim Advantage - Implicit guards (cleaner than C#/Rust)":
    type
      Shape = ref object of RootObj
        id: int

      Circle = ref object of Shape
        radius: float

      Rectangle = ref object of Shape
        width: float
        height: float

    let shape: Shape = Circle(id: 1, radius: 5.0)

    # Nim's implicit guard syntax is cleaner than C#/Rust!
    let result = match shape:
      c of Circle:
        "Circle with radius: " & $Circle(c).radius
      r of Rectangle:
        "Rectangle: " & $Rectangle(r).width & " x " & $Rectangle(r).height
      _:
        "Unknown shape"

    check result == "Circle with radius: 5.0"

  test "BONUS: Variable Guards - C# doesn't support runtime variable matching":
    # C# limitation: Only compile-time constants in patterns
    # Nim advantage: Can use runtime variables in guards!

    let expected_key = "port"  # Runtime variable
    let config = {"port": "8080", "host": "localhost"}.toTable

    let result = match config:
      {key: val} and key == expected_key: val
      _: "not found"

    check result == "8080"
