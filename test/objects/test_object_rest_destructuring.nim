import unittest
import tables
import json
import times
import strutils  # For string contains
import ../../pattern_matching

# Comprehensive test suite for object **rest destructuring feature
# Uses test-driven development approach with comprehensive coverage

type
  User = object
    id: int
    name: string
    age: int
    city: string
    role: string
    salary: float
    active: bool

  ApiResponse = object
    status: int
    message: string
    data: string
    requestId: string

  Config = object
    host: string
    port: int
    debug: bool
    timeout: int  # simplified from Duration for testing
    ssl: bool
    logLevel: string

  # Nested objects for complex testing
  Address = object
    street: string
    city: string
    zipCode: string
    country: string

  Company = object
    name: string
    address: Address
    employees: int
    founded: int

  Employee = object
    id: int
    name: string
    email: string
    company: Company
    manager: string

suite "Object **rest Destructuring - Basic Support":

  let tom = User(
    id: 1,
    name: "Tom",
    age: 30,
    city: "Paris",
    role: "Developer",
    salary: 75000.0,
    active: true
  )

  let alice = User(
    id: 2,
    name: "Alice",
    age: 28,
    city: "Berlin",
    role: "Designer",
    salary: 68000.0,
    active: true
  )

  test "Basic **rest extraction":
    let result = match tom:
      User(name: "Tom", **rest):
        "Tom with " & $rest.len & " extra fields"
      _: "No match"

    check result == "Tom with 6 extra fields"

  test "Multiple field extraction with **rest":
    let result = match tom:
      User(name: "Tom", age: age, role: "Developer", **rest):
        "Tom is " & $age & " year old developer with " & $rest.len & " more fields"
      _: "No match"

    check result.contains("Tom is 30 year old developer with 4 more fields")

  test "All fields in **rest (no explicit extraction)":
    let result = match tom:
      User(**rest):
        "All " & $rest.len & " fields captured"
      _: "No match"

    check result == "All 7 fields captured"

  test "Empty **rest when all fields extracted":
    let result = match tom:
      User(id: 1, name: "Tom", age: 30, city: "Paris",
           role: "Developer", salary: 75000.0, active: true, **rest):
        "All fields extracted, rest has " & $rest.len & " fields"
      _: "No match"

    check result == "All fields extracted, rest has 0 fields"

  test "**rest field access and type preservation":
    let result = match tom:
      User(name: "Tom", **rest):
        # Test accessing rest fields as strings (object rest default)
        let ageFromRest = parseInt(rest["age"])
        let salaryFromRest = parseFloat(rest["salary"])
        let activeFromRest = parseBool(rest["active"])

        "Age: " & $ageFromRest & ", Salary: " & $salaryFromRest & ", Active: " & $activeFromRest
      _: "No match"

    check result == "Age: 30, Salary: 75000.0, Active: true"

  test "**rest with variable binding in matched fields":
    let result = match tom:
      User(name: userName, age: userAge, **rest):
        userName & " (" & $userAge & ") has " & $rest.len & " additional properties"
      _: "No match"

    check result == "Tom (30) has 5 additional properties"

  test "Configuration processing with complex types":
    let config = Config(
      host: "localhost",
      port: 8080,
      debug: true,
      timeout: 30,
      ssl: false,
      logLevel: "info"
    )

    let result = match config:
      Config(host: "localhost", port: port, **options):
        "Server " & $port & " with " & $options.len & " options"
      _: "Invalid config"

    check result == "Server 8080 with 4 options"

suite "Object **rest Destructuring - JsonNode Support":

  let tom = User(
    id: 1,
    name: "Tom",
    age: 30,
    city: "Paris",
    role: "Developer",
    salary: 75000.0,
    active: true
  )

  let apiResp = ApiResponse(
    status: 200,
    message: "Success",
    data: "{\"user\": \"tom\"}",
    requestId: "req-123"
  )

  test "Basic **rest extraction with JsonNode":
    let result = match tom:
      User(name: "Tom", **rest: JsonNode):
        "Tom with " & $rest.len & " extra fields in JSON"
      _: "No match"

    check result == "Tom with 6 extra fields in JSON"

  test "JsonNode **rest field access":
    let result = match tom:
      User(name: "Tom", **rest: JsonNode):
        # Test accessing JsonNode rest fields
        let ageFromRest = rest["age"].getInt()
        let cityFromRest = rest["city"].getStr()
        let activeFromRest = rest["active"].getBool()

        "Age: " & $ageFromRest & ", City: " & cityFromRest & ", Active: " & $activeFromRest
      _: "No match"

    check result == "Age: 30, City: Paris, Active: true"

  test "API response processing with JsonNode **rest":
    let result = match apiResp:
      ApiResponse(status: 200, **metadata: JsonNode):
        "Success with " & $metadata.len & " metadata fields"
      _: "Error response"

    check result == "Success with 3 metadata fields"

  test "JsonNode **rest serialization compatibility":
    let result = match tom:
      User(name: "Tom", **rest: JsonNode):
        # JsonNode can be easily serialized to string
        let jsonString = $rest
        "JSON ready: " & (if jsonString.len > 10: "yes" else: "no")
      _: "No match"

    check result == "JSON ready: yes"

  test "All fields in JsonNode **rest":
    let result = match tom:
      User(**rest: JsonNode):
        # Should contain all fields as JsonNode
        let hasName = rest.hasKey("name")
        let hasId = rest.hasKey("id")
        $hasName & "-" & $hasId
      _: "No match"

    check result == "true-true"

suite "Object **rest Destructuring - Advanced Features":

  let tom = User(
    id: 1,
    name: "Tom",
    age: 30,
    city: "Paris",
    role: "Developer",
    salary: 75000.0,
    active: true
  )

  let company = Company(
    name: "TechCorp",
    address: Address(
      street: "123 Tech St",
      city: "San Francisco",
      zipCode: "94105",
      country: "USA"
    ),
    employees: 500,
    founded: 2010
  )

  let employee = Employee(
    id: 1,
    name: "John Doe",
    email: "john@techcorp.com",
    company: company,
    manager: "Jane Smith"
  )

  test "Nested object **rest extraction":
    let result = match employee:
      Employee(name: "John Doe", email: email, **rest):
        email & " has " & $rest.len & " additional properties"
      _: "No match"

    # NEW IMPLEMENTATION: Captures ALL fields using metadata structural query
    # Employee has fields: id(int), name(string), email(string), company(Company object), manager(string)
    # Extracted: name, email
    # Rest captures: id, company, manager = 3 fields
    # Complex objects like Company are stringified using $ operator
    check result == "john@techcorp.com has 3 additional properties"  # Improved behavior

  test "**rest with guard conditions":
    let result = match tom:
      User(age: 30, **rest):
        "User age 30 with " & $rest.len & " properties"
      User(name: "Tom", **rest):
        "User Tom with " & $rest.len & " properties"
      _: "No match"

    check result == "User age 30 with 6 properties"

  test "**rest with specific patterns":
    let result = match tom:
      User(role: "Developer", name: name, **rest):
        name & " is technical with " & $rest.len & " more fields"
      User(role: "Designer", name: name, **rest):
        name & " is creative with " & $rest.len & " more fields"
      _: "No match"

    check result == "Tom is technical with 5 more fields"

  test "Default **rest type (should be Table[string, string])":
    let result = match tom:
      User(name: "Tom", **rest):  # No type specified, should default to Table[string, string]
        "Default rest with " & $rest.len & " fields"
      _: "No match"

    check result == "Default rest with 6 fields"

suite "Object **rest Destructuring - Edge Cases and Error Handling":

  let tom = User(
    id: 1,
    name: "Tom",
    age: 30,
    city: "Paris",
    role: "Developer",
    salary: 75000.0,
    active: true
  )

  let emptyUser = User()  # All default values

  test "**rest with empty/default object":
    let result = match emptyUser:
      User(**rest):
        "Empty user with " & $rest.len & " fields"
      _: "No match"

    check result == "Empty user with 7 fields"

  test "Invalid **rest type annotation error":
    # This should be caught at compile time
    # User(**rest: string) should not compile
    template shouldNotCompile(code: untyped): bool =
      not compiles(code)

    check shouldNotCompile (
      let result = match tom:
        User(**rest: string):
          "should fail"
        _: "no"
    )

    check shouldNotCompile (
      let result = match tom:
        User(**rest: int):
          "should fail"
        _: "no"
    )

    check shouldNotCompile (
      let result = match tom:
        User(**rest: seq[string]):
          "should fail"
        _: "no"
    )

  test "Duplicate **rest annotations error":
    # This should be caught at compile time
    # User(**rest1, **rest2: JsonNode) should not compile
    template shouldNotCompile(code: untyped): bool =
      not compiles(code)

    check shouldNotCompile (
      let result = match tom:
        User(**rest1, **rest2):
          "should fail"
        _: "no"
    )

    check shouldNotCompile (
      let result = match tom:
        User(name: "Tom", **rest1, **rest2: JsonNode):
          "should fail"
        _: "no"
    )

  test "**rest performance with large objects":
    # Test that **rest extraction doesn't cause performance issues
    let iterations = 1000
    var count = 0

    for i in 0..<iterations:
      let result = match tom:
        User(name: "Tom", **rest):
          rest.len
        _: 0

      count += result

    check count == iterations * 6  # 6 fields in rest per iteration

suite "Object **rest Destructuring - Real World Use Cases":

  let tom = User(
    id: 1,
    name: "Tom",
    age: 30,
    city: "Paris",
    role: "Developer",
    salary: 75000.0,
    active: true
  )

  test "Database record processing":
    # Simulate database record with mixed field extraction
    let result = match tom:
      User(id: userId, name: userName, **metadata):
        "UPDATE users SET metadata = " & $metadata.len & " WHERE id = " & $userId
      _: "Invalid user"

    check result.contains("WHERE id = 1")

  test "API endpoint parameter extraction":
    # Simulate API request processing with JSON metadata
    let result = match tom:
      User(name: userName, **apiData: JsonNode):
        # Ready for JSON response
        "User " & userName & " with API data: " & (if apiData.len > 0: "yes" else: "no")
      _: "Invalid request"

    check result == "User Tom with API data: yes"

  test "Configuration merging scenario":
    let config = Config(
      host: "localhost",
      port: 8080,
      debug: true,
      timeout: 30,
      ssl: false,
      logLevel: "info"
    )

    let result = match config:
      Config(host: serverHost, port: serverPort, **settings):
        # Settings can be merged with defaults
        serverHost & ":" & $serverPort & " with " & $settings.len & " settings"
      _: "Invalid config"

    check result == "localhost:8080 with 4 settings"

  test "Form data processing with validation":
    # Simulate web form processing
    let result = match tom:
      User(name: "Tom", **formData: JsonNode):
        "Valid form for Tom with " & $formData.len & " extra fields"
      User(**formData: JsonNode):
        "Missing required fields, but got " & $formData.len & " fields"
      _: "Invalid form"

    # Note: this test assumes email field exists or test needs adjustment
    let expectedPattern = "extra fields"
    check result.contains(expectedPattern)
