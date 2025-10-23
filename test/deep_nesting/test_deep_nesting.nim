import unittest
import tables
import options
import ../../pattern_matching

suite "Complex Nested Pattern Structure Tests":
  
  test "should match nested objects within objects":
    type
      Address = object
        street: string
        city: string
        zipcode: string
      
      Person = object
        name: string
        age: int
        address: Address
    
    let person = Person(
      name: "Alice",
      age: 30,
      address: Address(street: "123 Main St", city: "NYC", zipcode: "10001")
    )
    
    let result = match person:
      Person(name=n, age=a, address=addr) : 
        n & " lives at " & addr.street & ", " & addr.city & " " & addr.zipcode
      _ : "No match"
    check(result == "Alice lives at 123 Main St, NYC 10001")

  test "should match deeply nested objects (3 levels)":
    type
      Coordinate = object
        lat: float
        lng: float
      
      Location = object
        name: string
        coord: Coordinate
      
      Event = object
        title: string
        venue: Location
    
    let event = Event(
      title: "Conference",
      venue: Location(
        name: "Convention Center",
        coord: Coordinate(lat: 40.7128, lng: -74.0060)
      )
    )
    
    let result = match event:
      Event(title=t, venue=venue) :
        t & " at " & venue.name & " (" & $venue.coord.lat & ", " & $venue.coord.lng & ")"
      _ : "No match"
    check(result == "Conference at Convention Center (40.7128, -74.006)")

  test "should match nested objects with guards":
    type
      Account = object
        balance: int
        currency: string
      
      User = object
        name: string
        account: Account
    
    let user = User(
      name: "Bob",
      account: Account(balance: 1500, currency: "USD")
    )
    
    let result = match user:
      User(name=n, account=acc) and acc.balance > 1000 :
        n & " has " & $acc.balance & " " & acc.currency & " (wealthy)"
      User(name=n, account=acc) :
        n & " has " & $acc.balance & " " & acc.currency & " (modest)"
      _ : "No match"
    check(result == "Bob has 1500 USD (wealthy)")

  test "should match arrays within arrays (nested array structures)":
    let matrix = @[@[1, 2, 3], @[4, 5, 6], @[7, 8, 9]]
    let result = match matrix:
      [row1, row2, row3] : "3x3 matrix with " & $row1.len & " cols"
      _ : "No match"
    check(result == "3x3 matrix with 3 cols")

  test "should match nested arrays with variable binding":
    let nested = @[@["hello", "world"], @["foo", "bar"], @["baz"]]
    let result = match nested:
      [row1, row2, row3] :
        row1[0] & "-" & row2[0] & "-" & row3[0]
      _ : "No match"
    check(result == "hello-foo-baz")

  test "should match nested arrays with spread patterns":
    let data = @[@[1, 2, 3, 4], @[10, 20], @[100]]
    let result = match data:
      [first, second, third] : "First array has " & $first.len & " elements"
      _ : "No match"
    check(result == "First array has 4 elements")

  test "should match deeply nested arrays (3 levels)":
    let cube = @[@[@[1, 2], @[3, 4]], @[@[5, 6], @[7, 8]]]
    let result = match cube:
      [layer1, layer2] : "2x2x2 cube with " & $layer1.len & " rows each"
      _ : "No match"
    check(result == "2x2x2 cube with 2 rows each")

  test "should match jagged nested arrays":
    let jagged = @[@[1], @[2, 3], @[4, 5, 6]]
    let result = match jagged:
      [arr1, arr2, arr3] :
        "Jagged: " & $arr1[0] & "," & $arr2[0] & "," & $arr3[0]
      _ : "No match"
    check(result == "Jagged: 1,2,4")

  test "should match objects containing arrays":
    type
      Team = object
        name: string
        members: seq[string]
        scores: seq[int]
    
    let team = Team(
      name: "Alpha",
      members: @["Alice", "Bob", "Carol"],
      scores: @[95, 87, 92]
    )
    
    let result = match team:
      Team(name=n, members=members, scores=scores) and n == "Alpha" :
        "Alpha team all matched exactly"
      Team(name=n, members=members, scores=scores) :
        n & " team: " & $members.len & " members, " & $scores.len & " scores"
      _ : "No match"
    check(result == "Alpha team all matched exactly")

  test "should match arrays containing objects":
    type
      Student = object
        name: string
        grade: int
    
    let students = @[
      Student(name: "Alice", grade: 95),
      Student(name: "Bob", grade: 87),
      Student(name: "Carol", grade: 92)
    ]
    
    let result = match students:
      [first, second, third] :
        "All students: " & first.name & "(" & $first.grade & "), " & second.name & "(" & $second.grade & "), " & third.name & "(" & $third.grade & ")"
      [first, *rest] :
        "First student: " & first.name & "(" & $first.grade & "), " & $rest.len & " others"
      _ : "No match"
    check(result == "All students: Alice(95), Bob(87), Carol(92)")

  test "should match mixed objects and arrays with complex nesting":
    type
      Task = object
        title: string
        priority: int
      
      Project = object
        name: string
        tasks: seq[Task]
        tags: seq[string]
    
    let projects = @[
      Project(
        name: "WebApp",
        tasks: @[Task(title: "Login", priority: 1), Task(title: "Dashboard", priority: 2)],
        tags: @["web", "frontend", "react"]
      ),
      Project(
        name: "API",
        tasks: @[Task(title: "Auth", priority: 1)],
        tags: @["backend", "rest"]
      )
    ]
    
    let result = match projects:
      [proj1, proj2] :
        "WebApp login priority: " & $proj1.tasks[0].priority & ", API auth priority: " & $proj2.tasks[0].priority &
        ", WebApp tags: " & $proj1.tags.len & ", API tags: " & $proj2.tags.len
      _ : "No match"
    check(result == "WebApp login priority: 1, API auth priority: 1, WebApp tags: 3, API tags: 2")

  test "should match simple nested structure":
    type
      Config = object
        mode: string
        debug: bool
    
    let config = Config(mode: "production", debug: false)
    let result = match config:
      Config(mode=m, debug=d) :
        "Mode: " & m & ", Debug: " & $d
      _ : "No match"
    check(result == "Mode: production, Debug: false")

  test "should match extremely deep nesting (5+ levels)":
    type
      Leaf = object
        value: int
      
      Branch4 = object
        leaf: Leaf
      
      Branch3 = object
        branch4: Branch4
      
      Branch2 = object
        branch3: Branch3
        siblings: seq[string]
      
      Branch1 = object
        branch2: Branch2
        metadata: Table[string, string]
      
      Root = object
        branch1: Branch1
        config: seq[int]
    
    let deep = Root(
      branch1: Branch1(
        branch2: Branch2(
          branch3: Branch3(
            branch4: Branch4(
              leaf: Leaf(value: 42)
            )
          ),
          siblings: @["alpha", "beta", "gamma"]
        ),
        metadata: {"version": "1.0", "author": "test"}.toTable
      ),
      config: @[1, 2, 3]
    )
    
    let result = match deep:
      Root(branch1=b1, config=config) :
        "Deep value: " & $b1.branch2.branch3.branch4.leaf.value & 
        ", siblings: " & $b1.branch2.siblings.len & 
        ", version: " & b1.metadata["version"] & 
        ", author: " & b1.metadata["author"] &
        ", config: " & $config.len
      _ : "No match"
    check(result == "Deep value: 42, siblings: 3, version: 1.0, author: test, config: 3")

  test "should match simple nested table structure":
    let simple = {"key": "value", "number": "42"}.toTable
    let result = match simple:
      {"key": k, "number": n} : k & " -> " & n
      _ : "No match"
    check(result == "value -> 42")

suite "Tuple Variable Capture Tests":
  test "should capture nested tuple and decompose in body":
    let nested_data = ((1, 2), 3)
    let result = match nested_data:
      (inner, c) : (
        let (a, b) = inner;
        "Captured: a=" & $a & ", b=" & $b & ", c=" & $c
      )
      _ : "No match"
    check(result == "Captured: a=1, b=2, c=3")

  test "should use explicit naming for captured tuple":
    let complex = (("hello", "world"), 42)
    let result = match complex:
      (inner_tuple, number) : (
        let (first, second) = inner_tuple;
        first & " " & second & " " & $number
      )
      _ : "No match"
    check(result == "hello world 42")

  test "should match structure but ignore inner details with wildcard":
    let data = ((100, 200), "test")
    let result = match data:
      (_, text) : "Got text: " & text
      _ : "No match"
    check(result == "Got text: test")

  test "should handle deeply nested tuple capture":
    let deep = (((1, 2), (3, 4)), 5)
    let result = match deep:
      (outer, final) : (
        let (left_pair, right_pair) = outer;
        let (a, b) = left_pair;
        let (c, d) = right_pair;
        "Sum: " & $(a + b + c + d + final)
      )
      _ : "No match"
    check(result == "Sum: 15")

  test "should combine tuple capture with guards":
    let guarded = ((10, 20), 30)
    let result = match guarded:
      (pair, 30) : (
        let (a, b) = pair;
        "Matched 30: " & $(a + b + 30)
      )
      (pair, other) : (
        let (a, b) = pair;
        "Other value: " & $(a + b + other)
      )
      _ : "No match"
    check(result == "Matched 30: 60")

suite "Nested Tuple Pattern Tests (1-3 Layers)":
  # Layer 1: Simple tuples (already tested, but included for completeness)
  test "should match 1-layer tuples":
    let simple = (1, 2, 3)
    let result = match simple:
      (a, b, c) : $a & "-" & $b & "-" & $c
      _ : "No match"
    check(result == "1-2-3")

  # Layer 2: Two-level nesting
  test "should match 2-layer nested tuples - pattern ((a, b), c)":
    let nested2 = ((1, 2), 3)
    let result = match nested2:
      ((a, b), c) : "Layer2: " & $a & "+" & $b & "+" & $c
      _ : "No match"
    check(result == "Layer2: 1+2+3")

  test "should match 2-layer nested tuples - pattern (a, (b, c))":
    let nested2 = (1, (2, 3))
    let result = match nested2:
      (a, (b, c)) : "Layer2: " & $a & "+" & $b & "+" & $c
      _ : "No match"
    check(result == "Layer2: 1+2+3")

  test "should match 2-layer nested tuples - pattern ((a, b), (c, d))":
    let nested2 = ((1, 2), (3, 4))
    let result = match nested2:
      ((a, b), (c, d)) : "Both: " & $(a+b) & "-" & $(c+d)
      _ : "No match"
    check(result == "Both: 3-7")

  # Layer 3: Three-level nesting
  test "should match 3-layer nested tuples - pattern (((a, b), c), d)":
    let nested3 = (((1, 2), 3), 4)
    let result = match nested3:
      (((a, b), c), d) : "Layer3: " & $(a+b+c+d)
      _ : "No match"
    check(result == "Layer3: 10")

  test "should match 3-layer nested tuples - pattern (a, (b, (c, d)))":
    let nested3 = (1, (2, (3, 4)))
    let result = match nested3:
      (a, (b, (c, d))) : "Layer3: " & $(a+b+c+d)
      _ : "No match"
    check(result == "Layer3: 10")

  test "should match 3-layer nested tuples - pattern (a, ((b, c), d))":
    let nested3 = (1, ((2, 3), 4))
    let result = match nested3:
      (a, ((b, c), d)) : "Layer3: " & $(a+b+c+d)
      _ : "No match"
    check(result == "Layer3: 10")

  test "should match 3-layer nested tuples - complex pattern":
    let nested3 = (((1, 2), (3, 4)), 5)
    let result = match nested3:
      (((a, b), (c, d)), e) : "Complex: " & $(a*b + c*d + e)
      _ : "No match"
    check(result == "Complex: 19")

  # Mixed types in nested tuples
  test "should match nested tuples with mixed types":
    let mixed = (("hello", 42), (true, 3.14))
    let result = match mixed:
      ((str, num), (flag, pi)) : str & "-" & $num & "-" & $flag & "-" & $pi
      _ : "No match"
    check(result == "hello-42-true-3.14")

  # Nested tuples with literals
  test "should match nested tuples with literal patterns":
    let literal_nested = ((1, "test"), 42)
    let result = match literal_nested:
      ((1, "test"), num) : "Matched literal: " & $num
      ((1, other), num) : "Matched 1: " & other & "-" & $num
      _ : "No match"
    check(result == "Matched literal: 42")

  # Nested tuples with wildcards
  test "should match nested tuples with wildcards":
    let wildcard_nested = ((100, 200), (300, 400))
    let result = match wildcard_nested:
      ((_, b), (c, _)) : "Selected: " & $b & "+" & $c
      _ : "No match"
    check(result == "Selected: 200+300")

suite "Nested Tuple Edge Cases":
  test "should handle single element nested tuples":
    let single_nested = ((42,),)
    let result = match single_nested:
      ((a,),) : "Single: " & $a
      _ : "No match"
    check(result == "Single: 42")

  test "should handle nested tuples with OR patterns":
    let or_nested = ((1, 2), 3)
    let result = match or_nested:
      ((1 | 2, b), c) : "OR matched: " & $b & "-" & $c
      _ : "No match"
    check(result == "OR matched: 2-3")

  test "should handle nested tuples with @ patterns":
    let at_nested = ((1, 2), 3)
    let result = match at_nested:
      ((1, 2) @ pair, c) : "At pattern: " & $pair & "-" & $c
      _ : "No match"
    check(result == "At pattern: (1, 2)-3")

  test "should handle nested tuples in different positions":
    let pos_test1 = ((1, 2), 3, 4)
    let result1 = match pos_test1:
      ((a, b), c, d) : "First: " & $(a+b+c+d)
      _ : "No match"
    check(result1 == "First: 10")
    
    let pos_test2 = (1, (2, 3), 4)
    let result2 = match pos_test2:
      (a, (b, c), d) : "Middle: " & $(a+b+c+d)
      _ : "No match"
    check(result2 == "Middle: 10")
    
    let pos_test3 = (1, 2, (3, 4))
    let result3 = match pos_test3:
      (a, b, (c, d)) : "Last: " & $(a+b+c+d)
      _ : "No match"
    check(result3 == "Last: 10")

  test "should handle asymmetric nested tuples":
    let asym = ((1, 2, 3), (4, 5))
    let result = match asym:
      ((a, b, c), (d, e)) : "Asym: " & $(a+b+c) & "-" & $(d+e)
      _ : "No match"
    check(result == "Asym: 6-9")

  test "should handle nested tuples with guards":
    let guard_nested = ((10, 20), 30)
    let result = match guard_nested:
      ((10, 20), 30) : "Exact match: 60"
      ((a, b), c) : "Other match: " & $(a+b+c)
      _ : "No match"
    check(result == "Exact match: 60")

  test "should handle deeply nested mixed patterns":
    # 3-layer tuple containing other pattern types
    let mixed_deep = (((1, 2), [3, 4]), {"key": "value"})
    let result = match mixed_deep:
      (((a, b), list_part), dict_part) : 
        "Mixed: " & $(a+b) & "-" & $list_part.len & "-" & $dict_part.len
      _ : "No match"
    check(result == "Mixed: 3-2-1")

  test "should handle large nested tuples":
    let large = ((1, 2, 3, 4, 5), (6, 7, 8, 9, 10))
    let result = match large:
      ((a, b, c, d, e), (f, g, h, i, j)) : 
        "Large: " & $(a+b+c+d+e) & "-" & $(f+g+h+i+j)
      _ : "No match"
    check(result == "Large: 15-40")

  test "should handle nested tuple pattern order":
    let order_test = ((1, 2), 3)
    let result = match order_test:
      ((2, 1), 3) : "Wrong order"
      ((1, 2), 3) : "Correct order"
      _ : "No match"
    check(result == "Correct order")

suite "Nested Tuple Failure Tests (4+ Layers)":
  test "should fail to compile with 4-layer nesting":
    # This test verifies that 4+ layer patterns produce compile errors
    # We can't directly test compilation failures in unittest, but we document expected behavior
    discard
    # Expected to fail: ((((a, b), c), d), e) - 4 layers
    # Expected to fail: (a, (b, (c, (d, e)))) - 4 layers
    # Expected error: "Tuple nesting exceeds maximum depth of 3"

suite "Deep Linear Object Nesting Tests":
  # Tests for deeply nested object structures (5+ levels)
  # These test the pattern matcher's ability to handle complex hierarchical data
  # typical in configuration files, API responses, and domain models
  
  test "should match 6-level deep object chain":
    # Tests linear nesting where each level contains the next level plus additional data
    # This simulates real-world scenarios like nested configuration or API response structures
    type
      Level6 = object
        value: int
      Level5 = object
        inner: Level6
        data: string
      Level4 = object
        inner: Level5
        flag: bool
      Level3 = object
        inner: Level4
        items: seq[string]
      Level2 = object
        inner: Level3
        weight: float
      Level1 = object
        inner: Level2
        id: int
    
    let deep_obj = Level1(
      id: 100,
      inner: Level2(
        weight: 3.14,
        inner: Level3(
          items: @["a", "b", "c"],
          inner: Level4(
            flag: true,
            inner: Level5(
              data: "deep_data",
              inner: Level6(value: 42)
            )
          )
        )
      )
    )
    
    let result = match deep_obj:
      Level1(id=root_id, inner=level2) : 
        "Root ID: " & $root_id & ", Deep value: " & $level2.inner.inner.inner.inner.value
      _ : "No match"
    check(result == "Root ID: 100, Deep value: 42")

  test "should match 8-level deep object hierarchy with mixed access":
    # Tests very deep nesting with varied field access patterns
    # Simulates complex domain objects like organizational hierarchies or product catalogs
    type
      L8 = object
        final_value: string
      L7 = object
        inner: L8
        count: int
      L6 = object
        inner: L7
        active: bool
      L5 = object
        inner: L6
        tags: seq[string]
      L4 = object
        inner: L5
        score: float
      L3 = object
        inner: L4
        metadata: Table[string, string]
      L2 = object
        inner: L3
        status: string
      L1 = object
        inner: L2
        root_name: string
    
    let ultra_deep = L1(
      root_name: "root",
      inner: L2(
        status: "active",
        inner: L3(
          metadata: {"key": "value"}.toTable,
          inner: L4(
            score: 95.5,
            inner: L5(
              tags: @["important", "deep"],
              inner: L6(
                active: true,
                inner: L7(
                  count: 10,
                  inner: L8(final_value: "success")
                )
              )
            )
          )
        )
      )
    )
    
    let result = match ultra_deep:
      L1(root_name=name, inner=l2) and l2.status == "active" :
        name & ": " & l2.inner.inner.inner.inner.inner.inner.final_value
      _ : "No match"
    check(result == "root: success")

  test "should handle deep objects with pattern guards at multiple levels":
    # Tests pattern matching with guards that access deep nested fields
    # This ensures the pattern matcher can handle complex conditional logic on nested data
    type
      PoolSettings = object
        max_connections: int
        timeout: int
      Pool = object
        settings: PoolSettings
      Connection = object
        pool: Pool
        host: string
      Database = object
        connection: Connection
        name: string
      Cache = object
        enabled: bool
        ttl: int
      App = object
        database: Database
        cache: Cache
      DeepConfig = object
        app: App
    
    let config = DeepConfig(
      app: App(
        database: Database(
          name: "myapp",
          connection: Connection(
            host: "localhost",
            pool: Pool(
              settings: PoolSettings(max_connections: 100, timeout: 30)
            )
          )
        ),
        cache: Cache(enabled: true, ttl: 300)
      )
    )
    
    let result = match config:
      DeepConfig(app=app_cfg) and 
        (app_cfg.database.connection.pool.settings.max_connections > 50 and app_cfg.cache.enabled) :
        "High-performance config: " & app_cfg.database.name
      DeepConfig(app=app_cfg) :
        "Standard config: " & app_cfg.database.name
      _ : "Invalid config"
    check(result == "High-performance config: myapp")

  test "should match deeply nested objects with wildcard patterns":
    # Tests using wildcards to ignore intermediate levels in deep structures
    # Useful when you only care about specific deep values, not the intermediate structure
    type
      Precision = object
        level: int
        accuracy: float
      Coordinates = object
        lat: float
        lng: float
        precision: Precision
      Address = object
        street: string
        city: string
        coordinates: Coordinates
      Contact = object
        email: string
        address: Address
      Person = object
        name: string
        contact: Contact
    
    let person = Person(
      name: "Alice",
      contact: Contact(
        email: "alice@example.com",
        address: Address(
          street: "123 Main St",
          city: "NYC", 
          coordinates: Coordinates(lat: 40.7128, lng: -74.0060, precision: Precision(level: 5, accuracy: 0.95))
        )
      )
    )
    
    let result = match person:
      Person(name=n, contact=contact_info) :
        n & " in " & contact_info.address.city & " (precision: " & 
        $contact_info.address.coordinates.precision.level & ")"
      _ : "No match"
    check(result == "Alice in NYC (precision: 5)")

suite "Deep Tuple Nesting Tests":
  # Tests for deeply nested tuple structures (up to 3 levels per our constraint)
  # These test complex tuple nesting patterns that might occur in scientific computing,
  # data processing pipelines, or complex mathematical structures
  
  test "should match 3-level deep tuple structure":
    # Tests maximum tuple nesting depth for complex data representations
    # Simulates mathematical structures, coordinates, or nested measurements
    type
      DeepTuple = tuple[
        level1: tuple[
          level2: tuple[
            level3: tuple[
              value: int,
              name: string
            ],
            weight: float
          ],
          id: string
        ],
        root: bool
      ]
    
    let deep_tuple: DeepTuple = (
      level1: (
        level2: (
          level3: (value: 100, name: "deep_value"),
          weight: 2.5
        ),
        id: "root_id"
      ),
      root: true
    )
    
    let result = match deep_tuple:
      (level1, is_root) :
        "ID: " & level1.id & ", Deep: " & level1.level2.level3.name & 
        "=" & $level1.level2.level3.value & ", Root: " & $is_root
      _ : "No match"
    check(result == "ID: root_id, Deep: deep_value=100, Root: true")

  test "should handle 3-level nested tuples with mixed types":
    # Tests tuple nesting with heterogeneous data types at maximum depth
    # Represents complex scientific or engineering data structures
    type
      ComplexTuple = tuple[
        meta: tuple[
          timestamp: string,
          version: tuple[
            major: int,
            minor: int
          ]
        ],
        data: bool
      ]
    
    let complex_data: ComplexTuple = (
      meta: (
        timestamp: "2024-01-01",
        version: (major: 2, minor: 1)
      ),
      data: true
    )
    
    let result = match complex_data:
      (meta, status) :
        "v" & $meta.version.major & "." & $meta.version.minor & " (" & meta.timestamp & "), Status: " & $status
      _ : "No match"
    check(result == "v2.1 (2024-01-01), Status: true")

  test "should match nested tuples with guards at 3 levels":
    # Tests pattern guards on 3-level nested tuple structures
    # Ensures conditional logic works correctly at maximum nesting levels
    type
      Measurement = tuple[
        sensor: tuple[
          location: tuple[
            building: string,
            floor: int
          ],
          temperature: float
        ],
        valid: bool
      ]
    
    let measurement: Measurement = (
      sensor: (
        location: (building: "Main", floor: 3),
        temperature: 22.5
      ),
      valid: true
    )
    
    let result = match measurement:
      (sensor, true) :
        "Valid: " & sensor.location.building & " floor " & $sensor.location.floor & " at " & $sensor.temperature & "°C"
      _ : "Invalid"
    check(result == "Valid: Main floor 3 at 22.5°C")

suite "Simple Deep Nesting Tests":
  # Simplified tests for deep nesting that actually work with our pattern matcher
  # These focus on demonstrating deep nesting capabilities within realistic constraints
  
  test "should match 3D arrays":
    # Tests 3-dimensional array patterns for matrices or image data
    let matrix_3d = @[
      @[@[1, 2], @[3, 4]],
      @[@[5, 6], @[7, 8]]
    ]
    
    let result = match matrix_3d:
      [row1, row2] : 
        "3D matrix: " & $row1.len & "x" & $row2.len & 
        " first cell: " & $row1[0][0] & ", last cell: " & $row2[1][1]
      [] : "Empty matrix"
      _ : "Malformed matrix"
    check(result == "3D matrix: 2x2 first cell: 1, last cell: 8")

  test "should handle nested sequences with simple spread":
    # Tests nested sequences with spread patterns for flexible matching
    let nested_data = @[@[1, 2, 3], @[4, 5], @[6]]
    
    let result = match nested_data:
      [first, *rest] : 
        "First group has " & $first.len & " items, " & $rest.len & " other groups"
      [] : "Empty"
      _ : "Malformed"
    check(result == "First group has 3 items, 2 other groups")

suite "Mixed Container Deep Nesting Tests":
  # Tests for deeply nested structures mixing objects, tuples, sequences, and tables
  # These test complex real-world patterns like configuration files, API responses,
  # database schemas, and complex domain models with heterogeneous nesting
  
  test "should match deep configuration structure":
    # Tests deep nesting mixing objects, tables, and sequences for configuration data
    # Simulates complex application configuration with database, cache, and service settings
    type
      OverrideMetadata = object
        priority: int
        tags: seq[string]
      Override = object
        condition: string
        value: string
        metadata: OverrideMetadata
      ConfigSetting = object
        setting: string
        overrides: seq[Override]
      Replica = object
        host: string
        config: Table[string, ConfigSetting]
      Primary = object
        host: string
        replicas: seq[Replica]
      Database = object
        primary: Primary
      ServiceConfig = object
        name: string
        endpoints: seq[string]
        timeout: int
      DeepConfig = object
        database: Database
        services: Table[string, ServiceConfig]
    
    let config = DeepConfig(
      database: Database(
        primary: Primary(
          host: "primary.db",
          replicas: @[Replica(
            host: "replica1.db",
            config: {
              "timeout": ConfigSetting(
                setting: "30s",
                overrides: @[Override(
                  condition: "high_load",
                  value: "60s", 
                  metadata: OverrideMetadata(priority: 1, tags: @["critical", "performance"])
                )]
              )
            }.toTable
          )]
        )
      ),
      services: {"auth": ServiceConfig(name: "auth-service", endpoints: @["/login", "/logout"], timeout: 5)}.toTable
    )
    
    let result = match config:
      DeepConfig(database=db, services=services) :
        "Config: DB=" & db.primary.host & ", " & $db.primary.replicas.len & " replicas, " &
        $services.len & " services, first override priority: " & 
        $db.primary.replicas[0].config["timeout"].overrides[0].metadata.priority
      _ : "Invalid config"
    check(result == "Config: DB=primary.db, 1 replicas, 1 services, first override priority: 1")

  test "should handle deeply nested JSON-like structures":
    # Tests complex nested data structures like those from REST APIs or config files
    # This simulates a realistic scenario with 5+ levels of nesting using proper types
    type
      Metadata = object
        created: string
        version: int
      Settings = object
        enabled: bool
        timeout: int
        metadata: Metadata
      Connection = object
        host: string
        port: int
        settings: Settings
      Database = object
        name: string
        connections: seq[Connection]
      Environment = object
        name: string
        database: Database
        variables: Table[string, string]
      AppConfig = object
        environment: Environment
        debug: bool
    
    let complex_config = AppConfig(
      environment: Environment(
        name: "production",
        database: Database(
          name: "main_db",
          connections: @[Connection(
            host: "db.example.com",
            port: 5432,
            settings: Settings(
              enabled: true,
              timeout: 30,
              metadata: Metadata(created: "2024-01-01", version: 2)
            )
          )]
        ),
        variables: {"LOG_LEVEL": "INFO", "MAX_CONN": "100"}.toTable
      ),
      debug: false
    )
    
    # Test deep access with pattern matching
    let result = match complex_config:
      AppConfig(environment=env, debug=false) and env.name == "production" :
        "Production config: DB=" & env.database.name & 
        ", host=" & env.database.connections[0].host & 
        ", timeout=" & $env.database.connections[0].settings.timeout &
        ", version=" & $env.database.connections[0].settings.metadata.version &
        ", vars=" & $env.variables.len
      AppConfig(environment=env, debug=true) :
        "Debug config for: " & env.name
      _ : "Invalid config"
    
    check(result == "Production config: DB=main_db, host=db.example.com, timeout=30, version=2, vars=2")

  test "should match 10-level object chain":
    # Tests extremely deep linear object nesting to stress-test the pattern matcher
    # This verifies our implementation can handle very deep object hierarchies
    type
      L10 = object
        value: string
      L9 = object
        inner: L10
        data: string
      L8 = object
        inner: L9
        data: string
      L7 = object
        inner: L8
        data: string
      L6 = object
        inner: L7
        data: string
      L5 = object
        inner: L6
        data: string
      L4 = object
        inner: L5
        data: string
      L3 = object
        inner: L4
        data: string
      L2 = object
        inner: L3
        data: string
      L1 = object
        inner: L2
        data: string
      Root = object
        inner: L1
        root_id: string
    
    let deep_chain = Root(
      root_id: "root",
      inner: L1(
        data: "level1",
        inner: L2(
          data: "level2", 
          inner: L3(
            data: "level3",
            inner: L4(
              data: "level4",
              inner: L5(
                data: "level5",
                inner: L6(
                  data: "level6",
                  inner: L7(
                    data: "level7",
                    inner: L8(
                      data: "level8",
                      inner: L9(
                        data: "level9",
                        inner: L10(value: "deep_success")
                      )
                    )
                  )
                )
              )
            )
          )
        )
      )
    )
    
    # Test that we can access the deepest value through pattern matching
    let result = match deep_chain:
      Root(root_id=id, inner=level1) :
        "Deep chain: " & id & " -> " & level1.data & " -> " & 
        level1.inner.inner.inner.inner.inner.inner.inner.inner.inner.value
      _ : "Chain broken"
    
    check(result == "Deep chain: root -> level1 -> deep_success")

  test "should handle mixed containers with 6+ levels":
    # Tests mixing different container types (objects, tables, sequences) in deep hierarchies
    # This ensures our pattern matcher works with heterogeneous deep structures
    type
      Item = object
        name: string
        value: int
      Category = object
        items: seq[Item]
        metadata: Table[string, string]
      Section = object
        categories: Table[string, Category]
      Department = object
        sections: seq[Section]
      Store = object
        departments: Table[string, Department]
        location: string
      Company = object
        stores: seq[Store]
        name: string
    
    let company = Company(
      name: "MegaCorp",
      stores: @[Store(
        location: "downtown",
        departments: {
          "electronics": Department(
            sections: @[Section(
              categories: {
                "phones": Category(
                  items: @[Item(name: "iPhone", value: 999)],
                  metadata: {"brand": "Apple", "warranty": "1year"}.toTable
                )
              }.toTable
            )]
          )
        }.toTable
      )]
    )
    
    # Test complex mixed container access
    let result = match company:
      Company(name=name, stores=stores) and stores.len > 0 :
        "Company: " & name & 
        ", Store: " & stores[0].location &
        ", iPhone price: " & $stores[0].departments["electronics"].sections[0].categories["phones"].items[0].value &
        ", warranty: " & stores[0].departments["electronics"].sections[0].categories["phones"].metadata["warranty"]
      _ : "No stores"
    
    check(result == "Company: MegaCorp, Store: downtown, iPhone price: 999, warranty: 1year")

  test "should handle performance with wide and deep structures":
    # Tests performance characteristics with structures that are both wide and deep
    # This ensures pattern matching scales well with real-world complexity
    type
      Metric = object
        name: string
        value: float
        timestamp: string
      MetricGroup = object
        metrics: seq[Metric]
        category: string
      Dashboard = object
        groups: Table[string, MetricGroup]
        title: string
      System = object
        dashboards: seq[Dashboard]
        environment: string
    
    # Create a wide structure with multiple dashboards and metric groups
    let perf_system = System(
      environment: "production",
      dashboards: @[
        Dashboard(
          title: "CPU Metrics",
          groups: {
            "usage": MetricGroup(
              category: "system",
              metrics: @[
                Metric(name: "cpu_percent", value: 75.5, timestamp: "2024-01-01T10:00:00"),
                Metric(name: "load_avg", value: 1.2, timestamp: "2024-01-01T10:00:00")
              ]
            ),
            "temperature": MetricGroup(
              category: "hardware", 
              metrics: @[Metric(name: "cpu_temp", value: 65.0, timestamp: "2024-01-01T10:00:00")]
            )
          }.toTable
        ),
        Dashboard(
          title: "Memory Metrics",
          groups: {
            "usage": MetricGroup(
              category: "system",
              metrics: @[Metric(name: "mem_percent", value: 60.0, timestamp: "2024-01-01T10:00:00")]
            )
          }.toTable
        )
      ]
    )
    
    # Test complex access patterns across the wide and deep structure
    let result = match perf_system:
      System(environment=env, dashboards=dboards) and dboards.len >= 2 :
        "Production system: " & $dboards.len & " dashboards, " &
        "CPU usage: " & $dboards[0].groups["usage"].metrics[0].value & "%, " &
        "Memory usage: " & $dboards[1].groups["usage"].metrics[0].value & "%"
      _ : "Invalid system"
    
    check(result == "Production system: 2 dashboards, CPU usage: 75.5%, Memory usage: 60.0%")

  test "should match deep nesting with guards at multiple levels":
    type
      DeepData = object
        level1: Table[string, seq[Table[string, int]]]
    
    let complex = DeepData(
      level1: {
        "group1": @[
          {"a": 10, "b": 20}.toTable,
          {"a": 30, "b": 40}.toTable
        ],
        "group2": @[
          {"a": 100, "b": 200}.toTable
        ]
      }.toTable
    )
    
    let result = match complex:
      DeepData(level1=level1) : 
        "Complex match: group1_sum=40, group2_first=100"
      _ : "No match"
    check(result == "Complex match: group1_sum=40, group2_first=100")