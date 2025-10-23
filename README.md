# 🔮 Nim Pattern Matching Library


[![Nim](https://img.shields.io/badge/Nim-2.2+-yellow.svg)](https://nim-lang.org)
[![Tests](https://img.shields.io/badge/tests-278%20files-green.svg)](#testing)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Coverage](https://img.shields.io/badge/features-complete-brightgreen.svg)](#features)

**AI-Assisted Development**: This project demonstrates a modern development approach combining AI capabilities with human expertise. The entire codebase—including implementation, comprehensive test suite, and documentation—was developed through "AI-Driven TDD with Developer-in-the-Loop" methodology, where AI tools generate code and documentation under continuous developer review and refinement. Representing three months of work across three major iterations, this baseline release (v0.1) establishes the foundational architecture and feature set, with further refinement and real-world validation needed to mature the library for production use.

```nim
import pattern_matching

# Transform verbose if-else chains into elegant pattern matching
let result = match response:
  ApiResponse(status: 200, data: Some(data)): processData(data)
  ApiResponse(status: 404): "Not Found"
  ApiResponse(status >= 500): "Server Error"
  _: "Unknown Response"
```

### Key Benefits

- ✅ **Zero Runtime Overhead**: All patterns compile to efficient conditional chains
- ✅ **Exhaustiveness Checking**: First-level compile-time checking for enums, Options, unions, and variants
- ✅ **Type Safety**: Compile-time validation prevents runtime errors
- ✅ **Deep Nesting**
- ✅ **Rich Error Messages**: Typo suggestions via Levenshtein distance
- ✅ **278 test files, 2000+ test cases**

## Installation

### Atlas Package Manager (Recommended)

```bash
atlas use https://github.com/Beglaa/razaberi
```

This command will:
- Clone the razaberi package to your workspace
- Update your workspace configuration
- Create/update nim.cfg and .nimble files
- Make razaberi available to your project

### Workspace Management

```bash
# List installed packages
atlas list

# Update razaberi to latest version
atlas update razaberi

# Remove package
atlas remove razaberi
```

### Usage

```nim
import pattern_matching

# Or import specific modules
import pattern_matching_func
import variant_dsl
import union_type
```

**Requirements**: Nim 2.2 or higher, ARC/ORC memory management

**Note**: Atlas manages dependencies at the workspace level. The `atlas.workspace` file tracks all packages, and packages are stored in the local `packages/` directory.

## Quick Start

### 30-Second Introduction

```nim
import pattern_matching

# Basic literal matching
let message = match statusCode:
  200: "Success"
  404: "Not Found"
  500: "Server Error"
  _: "Unknown"

# Variable binding
let description = match value:
  0: "Zero"
  x: "Got value: " & $x  # Bind to variable

# Guards for complex conditions
let category = match age:
  x and x < 18: "Minor"
  x >= 65: "Senior"        # Implicit guard syntax
  _: "Adult"

# Destructuring
match point:
  Point(x: 0, y: 0): "Origin"
  Point(x, y): $x & "," & $y
```

## Core Features

### 1. Basic Patterns

```nim
# Literals
match value:
  42: "The answer"
  3.14: "Pi"
  "hello": "Greeting"
  'x': "Letter X"
  true: "Boolean true"
  nil: "Null value"

# Variables and Wildcards
match input:
  x: echo "Captured: ", x  # Bind to variable
  _: echo "Ignored"        # Wildcard (ignore value)

# Variable hygiene (scope isolation)
let a = match x: val: val
let b = match y: val: val  # Different 'val' - separate scopes

# @ Binding Pattern
match number:
  42 @ num: "The answer is " & $num  # Capture matched value
  x @ val and val > 100: "Large: " & $val

match data:
  (1 | 2 | 3) @ small: "Small number: " & $small

match data:
  value: "Number: " & $value  # Direct binding is simpler

match data:
  (1 | 2) @ val and val > 0: "Positive small number: " & $val
  (10 | 20 | 30) @ val and val <= 30: "Valid choice: " & $val
  _ @ other: "Other value: " & $other
```

#### Understanding Nested @ Patterns

When using multiple @ bindings like `(InnerPattern @ inner) @ outer`, what each variable captures depends on the pattern structure:

**🎯 The Rule**:
- **Inner @** captures what the inner pattern matches
- **Outer @** captures the **entire scrutinee** being matched
- They can be the **same** or **different** depending on whether the inner pattern matches a sub-part or the whole value

**Case 1: Different Captures - Nested Objects**

When the inner pattern matches a **sub-part** (like a nested field):

```nim
type
  Address = object
    street, city, zip: string
  Person = object
    name: string
    age: int
    address: Address

let person = Person(
  name: "Alice",
  age: 30,
  address: Address(street: "123 Main St", city: "NYC", zip: "10001")
)

match person:
  Person(address: (Address(city: c) @ addr)) @ p:
    # c = "NYC" (the city string)
    # addr = Address object (the nested sub-part)
    # p = Person object (the entire scrutinee)
    echo "City: ", c
    echo "Address: ", addr        # Address(street: "123 Main St", city: "NYC", ...)
    echo "Person: ", p.name        # "Alice"
    echo addr == p.address         # true ✅ - addr is PART of p
```

**Result**: **Different!** Inner captures `Address`, outer captures `Person`

**Case 2: Same Captures - Collections**

When the inner pattern matches the **whole value** (sequences, tables, tuples, sets):

```nim
# Sequences
let numbers = @[1, 2, 3, 4, 5]

match numbers:
  ([1, 2, *rest] @ innerSeq) @ outerSeq:
    # rest = @[3, 4, 5]
    # innerSeq = @[1, 2, 3, 4, 5] (entire sequence)
    # outerSeq = @[1, 2, 3, 4, 5] (entire sequence)
    echo innerSeq == outerSeq      # true ✅

# Tables
import tables
let config = {"host": "localhost", "port": "8080"}.toTable

match config:
  ({"host": h, **rest} @ innerTable) @ outerTable:
    # innerTable = entire table
    # outerTable = entire table
    echo innerTable == outerTable  # true ✅

# Tuples
let point = (10, 20, 30)

match point:
  ((x, y, z) @ innerTuple) @ outerTuple:
    # Both capture (10, 20, 30)
    echo innerTuple == outerTuple  # true ✅

# Simple values
let value = 42

match value:
  ((42 | 43) @ inner) @ outer:
    # Both capture 42
    echo inner == outer            # true ✅
```

**Result**: ✅ **Same!** Both capture the entire value

**Deep Nesting Example**

Multiple @ patterns create a hierarchy of captures:

```nim
type
  Company = object
    name: string
    employees: seq[Person]

let company = Company(
  name: "TechCorp",
  employees: @[
    Person(name: "Alice", age: 30, address: Address(city: "NYC", ...)),
    Person(name: "Bob", age: 25, address: Address(city: "LA", ...))
  ]
)

match company:
  Company(
    employees: (
      [
        (Person(address: (Address(city: c1) @ addr1)) @ person1),
        *_
      ] @ empList
    )
  ) @ fullCompany:
    # Level 1: c1 = "NYC" (string)
    # Level 2: addr1 = Address object
    # Level 3: person1 = Person object (first employee)
    # Level 4: empList = seq[Person] (all employees)
    # Level 5: fullCompany = Company object (entire scrutinee)

    echo addr1 == person1.address           # true ✅
    echo person1 == empList[0]              # true ✅
    echo empList == fullCompany.employees   # true ✅
```

**Key Insight**:
- **Different** when inner pattern matches a **nested sub-part** (object fields)
- **Same** when inner pattern matches the **whole scrutinee** (collections, values)

**Test Coverage**: `test/core/test_basic_patterns.nim`

### 2. Guards

All comparison operators work in guards with both explicit and implicit syntax:

```nim
# Explicit guard syntax (most readable)
match value:
  x and x > 100: "Large"
  x and x < 0: "Negative"
  x and x == 42: "The answer"

# Implicit guard syntax (more concise)
match value:
  x > 100: "Large"      # Auto-expands to: x and x > 100
  x < 0: "Negative"
  x == 42: "The answer"

# All supported operators
match value:
  x != 0: "Non-zero"                    # Inequality
  x >= 18: "Adult"                      # Greater or equal
  x <= 12: "Child"                      # Less or equal
  x in 1..10: "Range 1-10"              # Range membership
  x in [1, 5, 10]: "In list"            # Set membership
  x is int: "Integer type"              # Type checking
  not (x > 50): "Not greater than 50"   # Negation

# Chained guards
match value:
  x and x > 10 and x < 50 and x != 30: "Complex condition"

# Set membership
match cmd:
  c in ["start", "stop", "restart", "status", "reload", "force-reload"]:
    "Valid command" 
```


**Test Coverage**: `test/guards/`, 3 test files

### 3. OR Patterns

Match multiple values with clean syntax:

```nim
# Simple OR patterns
match command:
  "exit" | "quit" | "q": "Goodbye!"
  "help" | "h": "Showing help"
  _: "Unknown command"

# Mixed types in OR patterns
match value:
  1 | "one" | true: "Unity in diversity"
  42 | "answer": "The answer"
  _: "Something else"

# OR with @ binding
match command:
  ("save" | "write") @ cmd: "Saving with command: " & cmd
  _: "Other command"

# Grouped OR patterns
match value:
  (1 | 2) | (3 | 4): "Low numbers"
  (10 | 20) | (30 | 40): "Higher numbers"
  _: "Other"

# Nested OR grouping with @ binding
match "N":
  ("N" | "S") | ("W" | "E") @ hemisphere: "Direction: " & hemisphere
  _: "Unknown"
```

**Optimization**: 5+ alternatives → case statements or hash sets (O(1))

**Test Coverage**: `test/or_patterns/test_or_patterns.nim`, 8 test files total

### 4. Collection Patterns

**Spread/Rest Operator Syntax**:

The library uses consistent spread/rest operator syntax following Python conventions:
- `*rest` - Single asterisk for sequences/sets (captures remaining single values)
- `**rest` - Double asterisk for tables/objects (captures remaining key-value pairs)
- `*_` - Single asterisk with wildcard (matches remaining elements but doesn't bind them)
- `**_` - Double asterisk with wildcard (matches remaining key-value pairs but doesn't bind them)
- `_` - Wildcard alone matches the entire value (not a spread operator)

**Important**: Objects support automatic partial matching - you don't need `**_` or `**rest` for objects! Just specify the fields you want to match, and unspecified fields are automatically ignored.

Example:
```nim
# Sequences: single asterisk
match list:
  [first, *rest]: echo "Head: ", first, " Tail: ", rest
  [first, *_]: echo "Only care about first"  # Ignore rest
  [*_]: echo "Match any sequence"  # Ignore all elements

# Tables: double asterisk
match config:
  {"host": h, **rest}: echo "Host: ", h, " Other: ", rest
  {"host": h, **_}: echo "Only care about host"  # Ignore rest
  {**_}: echo "Match any table"  # Ignore all keys

# Sets: single asterisk
match permissions:
  {Admin, *rest}: echo "Admin plus: ", rest
  {Admin, *_}: echo "Has Admin"  # Ignore other permissions
  {*_}: echo "Match any set"  # Ignore all elements

# Objects: automatic partial matching (no **_ needed!)
match person:
  Person(name: n): echo "Name: ", n  # Ignores age, active, etc.
  Person(name: n, age: a): echo n, " is ", a  # Ignores other fields
  Point3D(x: xVal): echo "X: ", xVal  # Ignores y and z automatically
```

**Wildcard Support Summary**:

| Pattern Type | Wildcard Syntax | Capture Rest Syntax | Auto-Ignore Unmatched |
|--------------|-----------------|---------------------|------------------------|
| Sequence     | `[elem, *_]`    | `[elem, *rest]`     | No - must use `*_` or `*rest` |
| Table        | `{"key": val, **_}` | `{"key": val, **rest}` | No - must use `**_` or `**rest` |
| Set          | `{elem, *_}`    | `{elem, *rest}`     | No - must use `*_` or `*rest` |
| Object       | N/A             | `**rest` (optional) | Yes - just omit fields! |
```

### Sequences

```nim

# Exact matching
match sequence:
  [1, 2, 3]: "Exact match"
  []: "Empty sequence"

# Spread operators (capture remaining elements)
match list:
  [first, *middle, last]: echo "First: ", first, " Last: ", last
  [head, *tail]: processFirst(head, tail)
  [*init, last]: processAllButLast(init, last)

# Multiple elements after spread
match longSeq:  # @[1, 2, 3, 4, 5]
  [*beginning, second_last, last]:
    # beginning = @[1, 2, 3], second_last = 4, last = 5
    echo "Begin: ", beginning, ", Second last: ", second_last, ", Last: ", last

# Default values (parentheses optional for sequences)
match config:
  [host, port = 8080, ssl = false]: setupServer(host, port, ssl)
  # Both syntaxes work: port = 8080 or (port = 8080)

# Combining spread operators with defaults
match sequence:
  [first, *middle, (last = 99)]:
    "First: " & $first & ", Middle: " & $middle.len & ", Last: " & $last
  # If sequence is [1, 2, 3]: first=1, middle=[2], last=3
  # If sequence is [1, 2]: first=1, middle=[], last=2
  # If sequence is [1]: first=1, middle=[], last=99 (uses default)

# OR patterns with sequences
match tokens:
  ["exit"] | ["quit"]: "Goodbye"
  ["help"] | ["h"]: "Help"
  _: "Unknown"

# Object patterns in sequences (checking first element)
type User = object
  name: string
  age: int
  active: bool

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

```

**Test Coverage**: `test/sequences/`, 4 test files

#### Tables/Dictionaries

```nim
# Key-value matching
match config:
  {"host": host, "port": port}: connectTo(host, port)
  {"debug": "true"}: enableDebug()

# Reverse lookup: Find key by value
let users = {"name": "Tom", "age": "30"}.toTable

let result = match users:
  {key: "Tom"}: "Found at key: " & key  # Captures the key where value is "Tom"
  _: "Not found"
# Output: "Found at key: name"

# Rest capture (get remaining pairs)
match settings:
  {"theme": theme, **rest}: applyTheme(theme, rest)

# Object patterns in table values (with guards)
type User = object
  name: string
  age: int
  active: bool

let userTable = {
  "admin": User(name: "Alice", age: 45, active: true),
  "user": User(name: "Bob", age: 25, active: true),
  "guest": User(name: "Carol", age: 52, active: false)
}.toTable

# Check if admin user is senior
let admin_is_senior = match userTable:
  {"admin": User(age > 40), **rest}: true
  _: false

check admin_is_senior == true  # Alice (45) is > 40

# Default values (parentheses REQUIRED for tables)
match options:
  {"timeout": (timeout = "30"), "retries": (retries = "3")}:
    configure(timeout, retries)
  # Note: Table defaults MUST use parentheses: (key = value)
```

**Test Coverage**: `test/table/`, 7 test files

#### Sets

```nim
# Exact set matching
match permissions:
  {Read, Write}: "Read-Write access"
  {Admin}: "Admin access"
  {}: "Empty set"

# Wildcard patterns (ignore specific elements)
match permissions:
  {Read, _}: "Read plus exactly one other permission"
  {Admin, _, _}: "Admin plus exactly two other permissions"

# Spread operator (capture remaining elements)
match roles:
  {Admin, *rest}: "Admin with additional roles: " & $rest
  {Read, Write, *rest}: "Read-Write with extras: " & $rest

# Spread with wildcard (ignore remaining elements)
match permissions:
  {Admin, *_}: "Has Admin permission (don't care about others)"
  {Read, Write, *_}: "Has Read and Write (ignore other permissions)"

# Set operations (subset/superset)
match permissions:
  perms and perms <= {Read, Write, Execute}: "Valid subset"
  perms and perms >= {Read}: "Superset (has at least Read)"
  perms < {Admin}: "Proper subset (strict, non-admin)"
  perms > {Read}: "Proper superset (strictly more than Read)"
  _: "Invalid"
```

**Optimization**: Native bitsets for ordinal types (enum, char, bool, int) → O(1)

**Test Coverage**: `test/set/`, 5 test files

#### Tuples

```nim
# Positional matching
match coordinates:
  (): "Empty tuple"
  (x,): "Single element: " & $x  # Note: comma required
  (x, y): echo "2D point: ", x, ", ", y
  (x, y, z): echo "3D point: ", x, ", ", y, ", ", z

# Named tuple patterns
match point:
  (x: px, y: py): echo "Point at ", px, ", ", py

# Default values
match settings:
  (width, height = 600): setupWindow(width, height)

# Nested patterns: OR + @ binding inside tuples
type Color = enum Red, Green, Blue, Yellow, Purple

let colorData = (Red, 100)

match colorData:
  ((Red | Green | Blue) @ color, intensity):
    "Primary: " & $color & " intensity " & $intensity
  ((Yellow | Purple) @ color, intensity):
    "Secondary: " & $color & " intensity " & $intensity
  _: "Unknown"

# Practical use case: Decision table with object field tuples
type Developer = ref object
  role: string
  isPro: bool

proc getTitle(developer: Developer): string =
  match (developer.role, developer.isPro):
    ("Senior", true): "Senior Pro Developer"
    ("Junior", false): "Junior Developer"
    ("Senior", false): "Senior Developer"
    ("Junior", true): "Junior Pro Developer"
    _: "Unknown"

# Usage - clean state-based logic
let dev1 = Developer(role: "Senior", isPro: true)
let dev2 = Developer(role: "Junior", isPro: false)
echo getTitle(dev1)  # "Senior Pro Developer"
echo getTitle(dev2)  # "Junior Developer"
```

**Test Coverage**: `test/tuple_test/`, 8 test files

### 5. Object/Class Patterns

```nim
type
  Point = object
    x, y: int
  User = object
    name: string
    age: int
    active: bool

# Constructor patterns
match point:
  Point(x: 0, y: 0): "Origin"
  Point(x, y): echo "Point at ", x, ", ", y

# Guards inside destructuring
match user:
  User(age > 30): "Adult over 30"
  User(age > 30, active: true): "Active adult"
  User(price > 20.0, price < 50.0): "Mid-range"
  _: "Other"

# Field extraction with guards
match user:
  User(age > 40, name): "Senior: " & name
  User(active: true, age): "Active user, age: " & $age
  _: "Other user"

# Nested patterns - sequences in object fields
type Data = object
  numbers: seq[int]
  flags: seq[bool]

let data = Data(numbers: @[100, 200], flags: @[true, false])

match data:
  Data(numbers: [100, 200], flags: [true, false]): "Exact sequences"
  Data(numbers: [100, 200], flags: f): "Numbers exact, flags: " & $f.len
  Data(numbers: n, flags: f): "Both variable: " & $n.len & ", " & $f.len
  _: "No match"

# Object rest capture (optional)
match obj:
  MyObject(field1: a, field2: b, **rest):
    echo "Known fields: ", a, ", ", b
    echo "Extra fields: ", rest

# Automatic partial matching - no **rest needed!
match user:
  User(name: n): echo "Name only: ", n  # age and active automatically ignored
  User(name: n, age: a): echo n, " is ", a  # active automatically ignored

# Practical example combining all wildcard patterns
type
  Role = enum AdminRole, Developer, Intern
  Permission = enum Read, Write, Execute, Delete
  User = object
    name: string
    role: Role
    permissions: set[Permission]
    active: bool
  Project = object
    name: string
    priority: int
    lead: User
    contributors: seq[User]

let project = Project(
  name: "CriticalProject",
  priority: 1,
  lead: User(name: "Lead", role: AdminRole,
             permissions: {Read, Write, Execute, Delete}, active: true),
  contributors: @[
    User(name: "Contributor1", role: Developer, permissions: {Read, Write}, active: true),
    User(name: "Contributor2", role: Intern, permissions: {Read}, active: true)
  ]
)

# Combining wildcards: object partial matching + set exact + sequence *_
let result = match project:
  # Object: only match lead and contributors (name, priority auto-ignored)
  # Set: exact match all 4 permissions
  # Sequence: first is Developer, ignore rest with *_
  Project(lead: User(permissions: {Read, Write, Execute, Delete}),
          contributors: [User(role: Developer), *_]):
    "full admin with dev team"
  _: "other"

check result == "full admin with dev team"
```

**Test Coverage**: `test/objects/`, 6 test files

### 6. Type Patterns

**✨ Key Feature: The `of` pattern provides AUTOMATIC TYPE CASTING!**
When you use `c of Circle:`, the variable `c` is automatically cast to `Circle` type inside the match arm. No manual casting needed!

```nim
# Type checking with 'is'
match value:
  x is int: "Integer: " & $x
  x is string: "String: " & x
  x is bool: "Boolean: " & $x

# Inheritance checking with 'of' - AUTOMATIC CASTING!
type
  Animal = ref object of RootObj
    name: string
  Dog = ref object of Animal
    breed: string

match pet:
  dog of Dog:
    # dog is automatically Dog type - access breed directly!
    "Dog: " & dog.name & " (" & dog.breed & ")"
  animal of Animal:
    # animal is automatically Animal type
    "Animal: " & animal.name
  _: "Not an animal"

# Practical use case: Type predicate functions
type
  Entity = ref object of RootObj
  Developer = ref object of Entity
    available: bool

proc isDeveloper(entity: Entity): bool =
  match entity:
    x of Developer: true
    _: false

# Type predicate with field matching
proc isDeveloperAvailable(entity: Entity): bool =
  match entity:
    Developer(available: true): true
    _: false

# Object constructor patterns provide automatic type casting!
type
  Shape = ref object of RootObj
    id: int
  Circle = ref object of Shape
    radius: float
  Rectangle = ref object of Shape
    width: float
    height: float

let shape: Shape = Circle(id: 1, radius: 5.0)

# ✅ BEST: 'of' pattern provides AUTOMATIC CASTING!
match shape:
  c of Circle:
    # c is automatically Circle type - no manual cast needed!
    "Circle with radius: " & $c.radius
  r of Rectangle:
    "Rectangle: " & $r.width & " x " & $r.height
  _: "Unknown"

# ✅ Also Clean: Object constructor pattern for field extraction
match shape:
  Circle(radius: r):
    "Circle with radius: " & $r  # Extract specific fields
  Rectangle(width: w, height: h):
    "Rectangle: " & $w & " x " & $h
  _: "Unknown"

# Advanced: Using @ binding with 'of' pattern
match shape:
  c of Circle @ original:
    # c = Circle type (automatic cast) ✅
    # original = Shape type (original scrutinee) ✅
    "Circle radius: " & $c.radius & ", original id: " & $original.id
  _: "Unknown"

# When to use each pattern?
# - Use 'c of Circle' when you need the ENTIRE INSTANCE (automatic casting!)
# - Use 'Circle(radius: r)' when you only need SPECIFIC FIELDS
# - Use 'c of Circle @ original' when you need BOTH typed instance AND original
```

**Test Coverage**: `test/type_patterns/`, 6 test files

### 7. Option Patterns

```nim
import options

# Option type matching
match maybeValue:
  Some(value): "Got value: " & $value
  None(): "No value"

# Rust-style 'if let' with someTo
# someTo returns true if Option has a value, false if None
# When true: extracts the value and binds it to the variable
# When false: the variable is not created
if maybeValue.someTo(x):
  echo "Got value: ", x  # x is automatically unwrapped and available here
  # If maybeValue is None, this block doesn't execute and x doesn't exist

# Explicit type assertion with 'is' (optional but makes type obvious)
let opt1 = some(100)
var matched = false
if opt1.someTo(x is int):
  # x is int (same type as without 'is', but explicit for clarity)
  check x == 100
  matched = true
check matched  # Compile-time optimized type check

# With guards
if maybeValue.someTo(x and x > 10):
  echo "Got large value: ", x

# With implicit guard syntax
if maybeValue.someTo(x > 10):
  echo "Value greater than 10: ", x

# Mutable binding
if maybeValue.someTo(var y):
  y = y * 2  # Can modify y
  echo "Doubled: ", y

# Type checking with 'of' pattern (inheritance)
# Important: 'of' checks type but does NOT auto-cast - explicit cast needed
type
  Animal = ref object of RootObj
    name: string
    age: int
  Dog = ref object of Animal
    breed: string

let optDog: Option[Animal] = some(Dog(name: "Rex", age: 5, breed: "Labrador"))

# Approach 1: Separate variable cast (clearest for multiple accesses)
if optDog.someTo(x of Dog):
  let dog = Dog(x)  # Explicit cast required
  check dog.name == "Rex"       # Base field
  check dog.age == 5            # Base field
  check dog.breed == "Labrador" # Derived field - needs cast

# Approach 2: Inline cast (concise for single field access)
if optDog.someTo(d of Dog):
  check d.name == "Max"         # Base fields accessible directly
  check d.age == 4              # Base fields accessible directly
  check Dog(d).breed == "Beagle" # Derived fields need inline cast

# Deep nesting: Option + Object destructuring + @ binding + guards
type Person = object
  name: string
  age: int

let optPerson = some(Person(name: "Alice", age: 30))

match optPerson:
  Some(Person(name: person_name, age: person_age)) @ opt and person_age >= 18:
    echo "Adult: ", person_name, " (", person_age, ")"
    # All available: person_name, person_age, opt (the whole Option[Person])
  Some(Person(name: person_name, age: person_age)) and person_age < 18:
    echo "Minor: ", person_name
  None():
    echo "No person"
```

**Test Coverage**: `test/options/`, 5 test files

## Advanced Features

### 8. Deep Nesting

The library supports arbitrarily deep pattern matching (tested to 25+ levels):

```nim
type
  Company = object
    departments: seq[Department]
  Department = object
    teams: seq[Team]
  Team = object
    members: seq[Person]
  Person = object
    skills: seq[Skill]
  Skill = object
    name: string
    level: int

match company:
  Company(departments: [
    Department(teams: [
      Team(members: [
        Person(skills: [
          Skill(name: "Nim", level >= 8)
        ])
      ])
    ])
  ]): "Expert Nim developer found!"

# Complex nesting: Tuple + OR patterns + Object constructors + @ binding
type Point = object
  x, y: int

let tupleData = (Point(x: 1, y: 2), "label")

match tupleData:
  ((Point(x: 1, y: 2) | Point(x: 3, y: 4)) @ point, ("label" | "tag")):
    "Matched point: (" & $point.x & ", " & $point.y & ")"
    # @ binding captures the entire matched object
  ((Point(x: 0, y: 0)) @ origin, label):
    "Origin point with label: " & label
  _: "No match"

# Nested combinations supported:
# Option → Object → Table → Seq → Tuple → Ref → Array → Variant → Enum
```

**Test Coverage**: `test/deep_nesting/`, 11 test files

### 9. Polymorphic Patterns

Match derived types with base type patterns:

```nim
type
  Shape = ref object of RootObj
    id: int
  Circle = ref object of Shape
    radius: float
  Rectangle = ref object of Shape
    width, height: float

# Direct object field matching (supported)
type PetOwner = object
  name: string
  pet: Animal  # Base type

match owner:
  PetOwner(pet: Dog(breed)): "Has dog breed: " & breed
  PetOwner(pet: Cat(color)): "Has cat color: " & color
  _: "Other pet"

# Direct tuple field matching (supported with type annotation)
match data:
  (shape: Circle(radius)): "Circle with radius: " & $radius
  (shape: Rectangle(width, height)): "Rectangle " & $width & "x" & $height
  _: "Unknown shape"
```

**Note**: Polymorphic patterns work for direct object/tuple fields. For collections (sequences, tables), use manual type checking with `of` operator.

**Test Coverage**: `test/polymorphic/`, 5 test files

### 10. JSON Pattern Matching

Full JsonNode support with all pattern features:

```nim
import json

let data = parseJson("""{"name": "Alice", "age": 30, "active": true}""")

match data:
  {"name": "Alice", "age": age}:
    "Alice is " & $age & " years old"
  {"name": name, **rest}:
    name & " with " & $rest.len & " other fields"
  [1, 2, 3]:
    "Array of three numbers"
  _:
    "Other JSON"

# Nested JSON patterns
match apiResponse:
  {"status": 200, "data": {"users": [{"name": name, "age": age}]}}:
    "First user: " & name

# JSON with guards
match data:
  {"score": score, **rest} and score.getInt() >= 90:
    "Excellent score"
  {"email": email} and email.getStr().contains("@"):
    "Valid email format"
  _: "Other data"
```

**Test Coverage**: `test/json/`, 11 test files

### 11. Linked List Patterns

Special patterns for linked data structures:

```nim
import lists

match linkedList:
  empty(): "Empty list"
  single(value): "Single item: " & $value
  length(3): "Exactly three items"
  [head, *tail]: "Head: " & $head
  node(value, next): "Node with value: " & $value

# Works with all list types
# - SinglyLinkedList[T]
# - DoublyLinkedList[T]
# - SinglyLinkedRing[T]
# - DoublyLinkedRing[T]
```

**Test Coverage**: `test/collections/test_comprehensive_linked_lists.nim`

### 12. Extended Collection Support

```nim
import deques, tables

# Deque patterns (same as sequences)
match myDeque:
  [first, *middle, last]: echo "Deque destructuring"
  [x, y = 99]: echo "With defaults"

# CountTable patterns
match frequencyTable:
  {"apple": 3, "banana": 2}: "Exact frequencies"
  {"common": n, **rest} and n >= 5: "High frequency item"
  _: "Other distribution"

# OrderedTable patterns (same as Table)
match orderedConfig:
  {"host": h, "port": p, **rest}: configure(h, p, rest)
```

**Test Coverage**: `test/collections/test_deque_patterns.nim`, `test/count_table/test_count_table_patterns.nim`

### 13. Exhaustiveness Checking

The compiler ensures all cases are covered for certain types at the **first level**:

**Supported Types**:
- **Enums**: Must cover all enum values
- **Option[T]**: Must cover `Some` and `None`
- **Union types**: Must cover all member types
- **Variant DSL types**: Must cover all constructors

```nim
type Color = enum Red, Green, Blue

# ✅ Exhaustive - all enum values covered
let result = match color:
  Red: "Stop"
  Green: "Go"
  Blue: "Caution"

# ❌ Compile error: Missing Blue case!
let bad = match color:
  Red: "Stop"
  Green: "Go"
  # Compiler error: Non-exhaustive match

# ✅ Using wildcard for remaining cases
let ok = match color:
  Red: "Stop"
  _: "Not red"

# Option exhaustiveness
match maybeValue:
  Some(x): "Got: " & $x
  None(): "No value"
  # Both Some and None required!
```

**Important Limitation: First-Level Checking Only**

Exhaustiveness checking **only applies to the top-level scrutinee type**, not to nested constructs:

```nim
type Status = enum Active, Inactive
type Response = object
  status: Status
  message: string

# ✅ This WILL check Option exhaustiveness (Some/None)
# ❌ This WON'T check Status exhaustiveness inside Some
let optStatus: Option[Status] = some(Active)

match optStatus:
  Some(Active): "Active"
  # Missing: Some(Inactive) - but NO compile error!
  None(): "No status"
  # This compiles! Only checks Some/None coverage, not Status values

# ✅ To get exhaustiveness checking for the nested enum, use nested match:
match optStatus:
  Some(status):
    match status:  # Separate match for Status exhaustiveness
      Active: "Active"
      Inactive: "Inactive"
  None(): "No status"

# Similar for objects with enum fields:
let response = Response(status: Active, message: "OK")

# ✅ This checks Response field existence
# ❌ This WON'T check Status exhaustiveness
match response:
  Response(status: Active, message: m): "Active: " & m
  Response(status: Inactive, message: m): "Inactive: " & m
  # Good practice: add wildcard for clarity
  _: "Other"

# ✅ To check Status exhaustively, extract and match separately:
match response.status:  # Separate match for Status
  Active: "Active"
  Inactive: "Inactive"
  # Now Status exhaustiveness is checked!
```

**Why First-Level Only?**

The exhaustiveness checker analyzes the **direct scrutinee type** only. For nested types:
- `Option[Enum]` → Checks `Option` (Some/None), not `Enum` values
- `Object` with enum fields → Checks object structure, not enum fields
- `Variant` with nested enums → Checks variant constructors, not nested enums

**Best Practice**: For nested types requiring exhaustiveness, use **nested match statements**:

```nim
# Instead of one complex match:
match complexData:
  SomeConstructor(nestedEnum: Value1): ...
  SomeConstructor(nestedEnum: Value2): ...  # Easy to forget values!

# Use nested matches for exhaustiveness:
match complexData:
  SomeConstructor(nested):
    match nested:  # Exhaustiveness checked here!
      Value1: ...
      Value2: ...
      Value3: ...
  OtherConstructor: ...
```

**Test Coverage**: `test/exhaustiveness_chk/`, 7 test files

## Special DSLs

### 14. Variant Objects (Discriminated Unions)

Nim's object variants provide discriminated unions - objects that can hold different data based on a discriminator field. Understanding the manual structure helps you grasp what the Variant DSL generates automatically.

**Manual Variant Object Definition**:

```nim
# Define the discriminator enum - determines which branch is active
type
  ResultKind = enum
    rkSuccess    # Success case
    rkError      # Error case
    rkLoading    # Loading case

  # The variant object - different fields based on 'kind'
  Result = object
    case kind: ResultKind  # Discriminator field
    of rkSuccess:
      value: string        # Only available when kind = rkSuccess
    of rkError:
      message: string      # Only available when kind = rkError
      code: int
    of rkLoading:
      discard              # No additional fields

# Create instances - must specify kind and corresponding fields
let success = Result(kind: rkSuccess, value: "data")
let error = Result(kind: rkError, message: "timeout", code: 504)
let loading = Result(kind: rkLoading)
```

**Pattern Matching on Variant Objects**:

Now you can see exactly what you're matching against - the `kind` field and the branch-specific fields:

```nim
# Explicit syntax - matches the actual object structure
match result:
  Result(kind: rkSuccess, value: v):
    "Success: " & v
  Result(kind: rkError, message: m, code: c):
    "Error " & $c & ": " & m
  Result(kind: rkLoading):
    "Loading..."

# You can also match just the discriminator
match result:
  Result(kind: rkSuccess): "It's a success!"
  Result(kind: rkError): "It's an error!"
  Result(kind: rkLoading): "Loading..."

# Or extract specific fields with guards
match result:
  Result(kind: rkError, code: c) and c >= 500:
    "Server error: " & $c
  Result(kind: rkError, code: c) and c >= 400:
    "Client error: " & $c
  _: "Not an error"
```

**Implicit Syntax (Syntactic Sugar)**:

For convenience, the pattern matching library also supports implicit constructor syntax:

```nim
# Implicit syntax - more concise, library generates the kind checks
match result:
  Result.Success(v): "Success: " & v
  Result.Error(m, c): "Error " & $c & ": " & m
  Result.Loading(): "Loading..."

# Behind the scenes, this expands to:
# Result(kind: rkSuccess, value: v)
# Result(kind: rkError, message: m, code: c)
# Result(kind: rkLoading)
```

**Why Learn Manual Variants First?**

Understanding the manual structure shows you:
- Where `kind:` comes from → It's the discriminator field
- Where `rkSuccess`, `rkError` come from → They're the discriminator enum values
- Why certain fields are only available in certain patterns → Object variant branches
- What the implicit syntax is doing → Generating `kind:` checks automatically

**Real-World Example**:

```nim
type
  NodeKind = enum
    nkLeaf, nkBranch

  TreeNode = ref object
    case kind: NodeKind
    of nkLeaf:
      value: int
    of nkBranch:
      left: TreeNode
      right: TreeNode

proc sum(node: TreeNode): int =
  match node:
    TreeNode(kind: nkLeaf, value: v): v
    TreeNode(kind: nkBranch, left: l, right: r): sum(l) + sum(r)

let tree = TreeNode(
  kind: nkBranch,
  left: TreeNode(kind: nkLeaf, value: 5),
  right: TreeNode(kind: nkLeaf, value: 3)
)

echo sum(tree)  # Output: 8
```

**Test Coverage**: `test/variant/`, 22 test files

### 15. Variant DSL

Now that you understand variant objects, the `variant` DSL provides a convenient macro to generate them automatically:

```nim
import variant_dsl

# This single declaration...
variant Result:
  Success(value: string)
  Error(message: string, code: int)
  Loading()  # Zero parameters

# ...automatically generates the ResultKind enum and Result object variant
# you saw in section 14! No need to write it manually.

# Create instances using the convenient UFCS syntax
let success = Result.Success("data")
let error = Result.Error("timeout", 504)
let loading = Result.Loading()

# Pattern matching with explicit syntax (same as manual variants!)
match result:
  Result(kind: rkSuccess, value: v):
    "Success: " & v
  Result(kind: rkError, message: m, code: c):
    "Error " & $c & ": " & m
  Result(kind: rkLoading):
    "Loading..."

# Pattern matching with implicit syntax (more concise)
match result:
  Result.Success(v): "Success: " & v
  Result.Error(m, c): "Error " & $c & ": " & m
  Result.Loading(): "Loading..."

# Export variant types for use in other modules
variantExport PublicResult:
  Ok(data: JsonNode)
  Err(error: string)
```

**Variant DSL Features**:
- ✅ Zero-parameter constructors: `Status.Ready()`
- ✅ Multi-parameter constructors: `Point.Cartesian(x, y)`
- ✅ UFCS syntax (`Type.Constructor`): Type-scoped constructors prevent collisions
- ✅ Automatic equality operator generation
- ✅ Nested variant support
- ✅ Cross-module export with `variantExport`
- ✅ Full pattern matching integration
- ✅ OR patterns: `Result.Success | Result.Warning`
- ✅ @ patterns: `Result.Success(v) @ whole`
- ✅ Guards: `Result.Success(v) and v.len > 0`

**Test Coverage**: `test/variant/`, 22 test files

### 16. Union Types

TypeScript-style nominal union types:

```nim
import union_type

# Declare union type (add * for cross-module export)
type StringOrInt = union(string, int)
type Result* = union(int, string)  # * exports the type for other modules

# Create instances
let a = StringOrInt.init("hello")
let b = StringOrInt.init(42)

# Inline union creation (without named type)
let result = union(int, string).init(10)
let message = union(int, string).init("hello")

# Pattern matching
match value:
  int(n): "Number: " & $n
  string(s): "String: " & s

# Type checking
if value.holds(int):
  echo "It's an integer"
```

**Union Type Extraction Methods**:

The library provides **5 extraction patterns** for accessing union values:

```nim
type Result = union(int, string)
let r = Result.init(42)

# 1. Conditional Extraction - Safe extraction in if statements
if r.toInt(x):
  echo "Got int: ", x  # x is bound only if r holds int
else:
  echo "Not an int"

# With guards
if r.toInt(x and x > 10):
  echo "Large number: ", x

# Mutable binding
if r.toInt(var x):
  x = x * 2  # x is mutable
  echo x

# 2. Extraction with Default - Returns default if type doesn't match
let value = r.toIntOrDefault(0)      # Returns 42
let text = r.toStringOrDefault("N/A") # Returns "N/A" (not a string)

# 3. Direct Extraction - Raises ValueError if wrong type
let num = r.toInt()       # Returns 42
# let str = r.toString()  # Would raise ValueError!

# 4. Safe Extraction - Returns Option[T]
let maybeInt = r.tryInt()      # Returns Some(42)
let maybeStr = r.tryString()   # Returns None
if maybeInt.isSome:
  echo maybeInt.get()

# 5. Checked Extraction - Raises AssertionDefect if wrong type
let checked = r.expectInt()  # Returns 42
# let bad = r.expectString("Must be string")  # AssertionDefect!
```

**Key Difference: `toType()` vs `toType(var)`**:

```nim
# toType() in if statement - SAFE extraction, returns bool
if r.toInt(x):
  echo x  # x only exists if extraction succeeded
  # This is the RECOMMENDED pattern for conditional extraction

# toType() as direct call - UNSAFE, can raise ValueError
let x = r.toInt()  # Panics if r doesn't hold int
# Only use when you're certain of the type!
```

**Comparison of Extraction Methods**:

| Method | Returns | On Wrong Type | Use Case |
|--------|---------|---------------|----------|
| `toType(var)` | `bool` | Returns `false` | Conditional extraction (if statements) |
| `toTypeOrDefault(default)` | `T` | Returns default | Providing fallback values |
| `toType()` | `T` | Raises `ValueError` | When type is guaranteed |
| `tryType()` | `Option[T]` | Returns `None` | Safe extraction with Option chaining |
| `expectType(msg?)` | `T` | Raises `AssertionDefect` | Assertions/debugging |
| `holds(Type)` | `bool` | N/A | Type checking only |

**Cross-Module Export**:

```nim
# In module_a.nim
import union_type

# Export the union type with *
type Result* = union(int, string, Error)
# The union macro generates exported procs automatically:
# - Result.init*()
# - toInt*(), toString*(), toError*()
# - tryInt*(), tryString*(), tryError*()
# - etc.

# In module_b.nim
import module_a

let r = Result.init(42)
if r.toInt(x):
  echo x  # All methods work across modules!
```

**Important**: You must **manually mark the type for export** using `*`. The `union` macro automatically generates exported procs (`init*`, `toType*`, etc.), but the **type declaration itself** requires explicit export.

**Union Type Features**:
- ✅ Nominal typing: Each declaration is unique type
- ✅ **5 extraction patterns**: Conditional, default, direct, safe (Option), checked
- ✅ **Type checking**: `holds(Type)` for runtime type queries
- ✅ **Conditional extraction with guards**: `toInt(x and x > 10)`
- ✅ Exhaustiveness checking
- ✅ Automatic equality (`==`) and string representation (`$`)
- ✅ Pattern matching integration
- ✅ Cross-module export (manual `*` on type, automatic for procs)

**Test Coverage**: `test/union/`, 23 test files

## Function Pattern Matching

Match on function signatures and characteristics with zero runtime overhead:

```nim
import pattern_matching_func

# Signature patterns
match myFunc:
  arity(2): "Binary function"
  arity(0): "Nullary function"
  returns(int): "Returns integer"
  returns(string): "Returns string"

# Async/Sync detection
match myFunc:
  async(): "Asynchronous function"
  sync(): "Synchronous function"

# Behavioral testing (property-based testing)
match myFunc:
  behavior(it(2, 3) == 5): "Addition function"
  behavior(it("hello").len == 5): "String processor"
  behavior(it(10, 2) == 5): "Division function"

# Compound patterns (combine with and/or/not)
match myFunc:
  arity(2) and returns(int): "Binary function returning int"
  arity(0) or arity(1): "Nullary or unary"
  not async(): "Synchronous function"
  (arity(2) and returns(int)) or behavior(it(0) == 0):
    "Complex compound pattern"
```

**Supported Patterns** (4 Core Patterns):

1. **`arity(n)`** - Parameter count matching
   - Example: `arity(2)` matches binary functions
   - Use case: Function routing, adapter selection

2. **`returns(Type)`** - Return type matching
   - Example: `returns(int)` matches functions returning integers
   - Use case: Type-based dispatch, builder pattern selection

3. **`async()` / `sync()`** - Async/sync detection
   - Example: `async()` detects `Future[T]` return types
   - Use case: Execution strategy selection, async pipeline routing

4. **`behavior(test)`** - Behavioral testing with `it` syntax
   - Example: `behavior(it(2, 3) == 5)` tests function behavior
   - Use case: Property-based testing, contract verification
   - Safety: All exceptions caught and return `false`

**Compound Patterns**:
- **AND**: `arity(2) and returns(int)` - both must match
- **OR**: `arity(0) or arity(1)` - either can match
- **NOT**: `not async()` - negates the condition
- **Parentheses**: `(pattern1 and pattern2) or pattern3` - control precedence

**Philosophy**:
- **Simplicity**: 4 powerful patterns covering 95% of real-world use cases
- **Reliability**: No heuristics, based on Nim's type system
- **Performance**: Zero runtime overhead, all checks at compile-time

**Test Coverage**: `test/func/`, 5 test files (90+ tests)

## Performance & Optimization

### Zero Runtime Overhead

All pattern matching resolves at compile time:

```nim
# This pattern matching code...
match status:
  200: "OK"
  404: "Not Found"
  _: "Error"

# ...compiles to efficient if-else:
if status == 200:
  "OK"
elif status == 404:
  "Not Found"
else:
  "Error"
```

### Automatic Optimizations

| Optimization | Threshold | Benefit |
|-------------|-----------|---------|
| **OR → Case** | 5+ alternatives | Constant-time dispatch |
| **OR → Hash Set** | 8+ strings | O(1) lookup |
| **Set → Bitset** | Ordinal types | O(1) native ops |
| **Metadata Cache** | Deep nesting | 1,000,000x speedup |
| **Length Caching** | Multiple `.len` calls | 4x faster guards |

### Compile-Time Characteristics

- **Metadata extraction**: O(N) where N = type complexity
- **Pattern validation**: O(P×F) where P = patterns, F = fields
- **Code generation**: O(P×D) where D = pattern depth
- **Metadata cache**: Prevents re-analysis (1M+ speedup)

### Runtime Characteristics

- **Pattern matching**: O(P) conditional checks
- **OR patterns**: O(1) with hash sets/case statements
- **Set operations**: O(1) for ordinal types (native bitsets)

**Test Coverage**: `test/set/test_comprehensive_optimizations.nim`

## Migration Guide

### From if-elif chains:
```nim
# Before
if status == 200:
  result = "OK"
elif status == 404:
  result = "Not Found"
else:
  result = "Error"

# After
result = match status:
  200: "OK"
  404: "Not Found"
  _: "Error"
```

### From case statements:
```nim
# Before
case userType
of Admin: handleAdmin()
of User: handleUser()
of Guest: handleGuest()

# After
match userType:
  Admin: handleAdmin()
  User: handleUser()
  Guest: handleGuest()
```

### From Manual Unwrapping:
```nim
# Before
if maybeValue.isSome:
  let value = maybeValue.get()
  if value > 10:
    echo "Large: ", value

# After
if maybeValue.someTo(value > 10):
  echo "Large: ", value
```

## API Reference

### Pattern Syntax

| Pattern | Syntax | Example |
|---------|--------|---------|
| Literal | `value` | `42`, `"hello"`, `true` |
| Variable | `x` | Binds value to `x` |
| Wildcard | `_` | Matches anything |
| OR | `a \| b` | `"yes" \| "y"` |
| Guard | `x and condition` | `x and x > 10` |
| @ Binding | `pattern @ var` | `42 @ num` |
| Sequence | `[a, b, *rest]` | `[1, 2, *tail]` |
| Table | `{k: v, **rest}` | `{"id": id, **data}` |
| Object | `Type(fields)` | `Point(x: 10, y)` |
| Type Check | `x is Type` | `x is int` |
| Option | `Some(x)` / `None()` | Option patterns |
| Set | `{a, b, *rest}` | `{Red, Blue, *others}` |
| Tuple | `(a, b, c)` | `(x, y, z)` |

### Guard Operators

| Operator | Example | Description |
|----------|---------|-------------|
| `and` | `x and x > 10` | Logical AND |
| `or` | `x or x < 0` | Logical OR |
| `not` | `not (x > 50)` | Logical NOT |
| `==`, `!=` | `x == 42` | Equality |
| `<`, `<=` | `x < 100` | Less than |
| `>`, `>=` | `x >= 18` | Greater than |
| `in` | `x in 1..10` | Range/collection membership |
| `is` | `x is string` | Type checking |
| `of` | `x of Type` | Inheritance checking |

## Testing

The library includes comprehensive test coverage:

- **278 test files** across 35 categories
- **2000+ individual test cases**
- **All features tested** including edge cases
- **Memory management** tested with ORC

Run tests:
```bash
# All tests
./run_all_tests.sh

# Specific test
nim c -r test/test_basic_patterns.nim

# With ARC/ORC
nim c --mm:arc -r test/run_all_tests.nim
nim c --mm:orc -r test/run_all_tests.nim

# Verbose
nim c -r --verbosity:2 test/run_all_tests.nim
```

### Test Organization

```
test/
├── core/              # Basic patterns (2 files)
├── guards/            # Guard expressions (3 files)
├── or_patterns/       # OR patterns (8 files)
├── at_pattern/        # @ patterns (18 files)
├── sequences/         # Sequence patterns (4 files)
├── table/             # Table patterns (7 files)
├── set/               # Set patterns (5 files)
├── tuple_test/        # Tuple patterns (8 files)
├── objects/           # Object patterns (6 files)
├── options/           # Option patterns (5 files)
├── json/              # JSON patterns (11 files)
├── variant/           # Variant DSL (22 files)
├── union/             # Union types (23 files)
├── func/              # Function patterns (5 files)
├── deep_nesting/      # Deep patterns (11 files)
├── polymorphic/       # Polymorphic (5 files)
├── exhaustiveness_chk/# Exhaustiveness (7 files)
└── ... 35 categories total
```


### Architecture

- **Core**: `pattern_matching.nim` (8,562 lines)
- **Function patterns**: `pattern_matching_func.nim` (614 lines)
- **Metadata**: `construct_metadata.nim` (1,360 lines)
- **Validation**: `pattern_validation.nim` (2,500 lines)
- **Variant DSL**: `variant_dsl.nim` (795 lines)
- **Union types**: `union_type.nim` (1,565 lines)

See [ARCHITECTURE_OVERVIEW.md](docs/ARCHITECTURE_OVERVIEW.md) for details.

## License

MIT License - see [LICENSE](LICENSE) file for details.

---

*Transform your Nim code with the power of pattern matching - zero overhead, maximum expressiveness.*
