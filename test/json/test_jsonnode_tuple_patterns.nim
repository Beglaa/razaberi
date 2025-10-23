import unittest
import std/json
import ../../pattern_matching

suite "JsonNode Tuple Pattern Tests":

  # Category 1: Basic JsonNode Positional Tuples
  test "JsonNode basic positional tuples":
    let coords: JsonNode = parseJson("[10, 20, 30]")

    let result = match coords:
      (x, y, z): "3D point: " & $x.getInt() & "," & $y.getInt() & "," & $z.getInt()
      _: "not a 3D point"
    check result == "3D point: 10,20,30"

  test "JsonNode two element positional tuple":
    let point: JsonNode = parseJson("[100, 200]")

    let result = match point:
      (x, y): "2D point: " & $x.getInt() & "," & $y.getInt()
      _: "not a 2D point"
    check result == "2D point: 100,200"

  # Category 2: JsonNode Named Tuples from Objects
  test "JsonNode named tuples from objects":
    let person: JsonNode = parseJson("""{"name": "Alice", "age": 30, "city": "NYC"}""")

    let result = match person:
      (name: n, age: a, city: c):
        n.getStr() & " is " & $a.getInt() & " years old from " & c.getStr()
      _: "not a complete person record"
    check result == "Alice is 30 years old from NYC"

  test "JsonNode named tuple shorthand":
    let config: JsonNode = parseJson("""{"host": "localhost", "port": 8080, "debug": true}""")

    let result = match config:
      (host, port, debug):  # Shorthand for host: host, port: port, debug: debug
        "Server at " & host.getStr() & ":" & $port.getInt() & " (debug=" & $debug.getBool() & ")"
      _: "invalid config"
    check result == "Server at localhost:8080 (debug=true)"

  # Category 3: Mixed Type JsonNode Tuples
  test "JsonNode mixed type tuples":
    let record: JsonNode = parseJson("""["Product", 99.99, true, 5]""")

    let result = match record:
      (name, price, available, stock):
        let nameStr = name.getStr()
        let priceFloat = price.getFloat()
        let availableBool = available.getBool()
        let stockInt = stock.getInt()
        nameStr & " costs $" & $priceFloat & ", available: " & $availableBool & ", stock: " & $stockInt
      _: "invalid record"
    check result == "Product costs $99.99, available: true, stock: 5"

  test "JsonNode string and number tuple":
    let data: JsonNode = parseJson("""["Hello", 42]""")

    let result = match data:
      (greeting, number): greeting.getStr() & " number " & $number.getInt()
      _: "no match"
    check result == "Hello number 42"

  # Category 4: Nested JsonNode Tuples
  test "JsonNode nested tuples":
    let matrix: JsonNode = parseJson("[[1, 2], [3, 4]]")

    let result = match matrix:
      ((a, b), (c, d)):
        "Matrix: [" & $a.getInt() & "," & $b.getInt() & "] [" & $c.getInt() & "," & $d.getInt() & "]"
      _: "not a 2x2 matrix"
    check result == "Matrix: [1,2] [3,4]"

  test "JsonNode triple nested tuples":
    let data: JsonNode = parseJson("[[[1, 2], [3, 4]], [[5, 6], [7, 8]]]")

    let result = match data:
      (((a, b), (c, d)), ((e, f), (g, h))):
        "Deep: " & $a.getInt() & "," & $b.getInt() & "," & $c.getInt() & "," & $d.getInt() &
        "," & $e.getInt() & "," & $f.getInt() & "," & $g.getInt() & "," & $h.getInt()
      _: "not deep matrix"
    check result == "Deep: 1,2,3,4,5,6,7,8"

  # Category 5: JsonNode Tuple Length Validation
  test "JsonNode tuple length validation":
    let shortArray: JsonNode = parseJson("[1, 2]")
    let longArray: JsonNode = parseJson("[1, 2, 3, 4]")

    let shortResult = match shortArray:
      (a, b, c): "three elements"
      (a, b): "two elements"
      _: "other"
    check shortResult == "two elements"

    let longResult = match longArray:
      (a, b, c): "three elements"
      (a, b, c, d): "four elements"
      _: "other"
    check longResult == "four elements"

  test "JsonNode tuple exact length matching":
    let exactThree: JsonNode = parseJson("[10, 20, 30]")

    let result = match exactThree:
      (a, b): "two elements"
      (a, b, c): "three elements: " & $a.getInt() & "," & $b.getInt() & "," & $c.getInt()
      (a, b, c, d): "four elements"
      _: "other count"
    check result == "three elements: 10,20,30"

  # Category 6: JsonNode Empty and Single Tuples
  test "JsonNode empty and single tuples":
    let empty: JsonNode = parseJson("[]")
    let single: JsonNode = parseJson("[42]")

    let emptyResult = match empty:
      (): "empty tuple"
      _: "not empty"
    check emptyResult == "empty tuple"

    let singleResult = match single:
      (value,): "single tuple: " & $value.getInt()  # Note the comma for single tuple
      _: "not single"
    check singleResult == "single tuple: 42"

  test "JsonNode single element various types":
    let stringTuple: JsonNode = parseJson("""["solo"]""")
    let numberTuple: JsonNode = parseJson("[123]")
    let boolTuple: JsonNode = parseJson("[true]")

    let stringResult = match stringTuple:
      (s,): "string: " & s.getStr()
      _: "not string tuple"
    check stringResult == "string: solo"

    let numberResult = match numberTuple:
      (n,): "number: " & $n.getInt()
      _: "not number tuple"
    check numberResult == "number: 123"

    let boolResult = match boolTuple:
      (b,): "bool: " & $b.getBool()
      _: "not bool tuple"
    check boolResult == "bool: true"

  # Category 7: JsonNode Tuple with Guards
  test "JsonNode tuple with guards":
    let scores: JsonNode = parseJson("[85, 90, 78]")

    let result = match scores:
      (math, science, english) and math.getInt() >= 80 and science.getInt() >= 80:
        "Strong in STEM: Math=" & $math.getInt() & ", Science=" & $science.getInt()
      (math, science, english) and english.getInt() >= 80:
        "Strong in English: " & $english.getInt()
      _: "needs improvement"
    check result == "Strong in STEM: Math=85, Science=90"

  test "JsonNode named tuple with guards":
    let student: JsonNode = parseJson("""{"name": "Bob", "grade": 95, "subject": "Math"}""")

    let result = match student:
      (name: n, grade: g, subject: s) and g.getInt() >= 90:
        n.getStr() & " excels in " & s.getStr() & " with " & $g.getInt()
      (name: n, grade: g, subject: s):
        n.getStr() & " got " & $g.getInt() & " in " & s.getStr()
      _: "invalid student"
    check result == "Bob excels in Math with 95"

  # Category 8: JsonNode Tuple Pattern with Wildcards
  test "JsonNode tuple patterns with wildcards":
    let data: JsonNode = parseJson("""["important", "ignore", "also_important"]""")

    let result = match data:
      (first, _, third):  # Middle element ignored
        first.getStr() & " and " & third.getStr()
      _: "wrong structure"
    check result == "important and also_important"

  test "JsonNode named tuple with wildcard":
    let config: JsonNode = parseJson("""{"app": "MyApp", "internal": "ignore", "version": "1.0"}""")

    let result = match config:
      (app: a, internal: _, version: v):
        a.getStr() & " version " & v.getStr()
      _: "invalid config"
    check result == "MyApp version 1.0"

  # Category 9: Complex JsonNode Tuple Nesting
  test "JsonNode complex tuple nesting":
    let complexData: JsonNode = parseJson("""
      [
        ["Alice", 30],
        {"role": "developer", "team": "backend"},
        [85, 90, 88]
      ]
    """)

    let result = match complexData:
      ((name, age), (role: r, team: t), (score1, score2, score3)):
        let avgScore = (score1.getInt() + score2.getInt() + score3.getInt()) div 3
        name.getStr() & " (" & $age.getInt() & ") is a " &
        r.getStr() & " on " & t.getStr() & " team, avg score: " & $avgScore
      _: "invalid complex structure"
    check result == "Alice (30) is a developer on backend team, avg score: 87"

  test "JsonNode deeply nested mixed structures":
    let deepData: JsonNode = parseJson("""
      [
        {"user": {"name": "John", "id": 123}},
        ["task1", "task2", "task3"],
        {"stats": [100, 200, 300]}
      ]
    """)

    let result = match deepData:
      ((user: (name: n, id: i)), (task1, task2, task3), (stats: [s1, s2, s3])):
        n.getStr() & " (ID:" & $i.getInt() & ") has tasks and stats sum=" &
        $(s1.getInt() + s2.getInt() + s3.getInt())
      _: "complex structure mismatch"
    check result == "John (ID:123) has tasks and stats sum=600"

  # Category 10: JsonNode Tuple Collection Syntax Integration
  test "JsonNode tuple syntax compatibility with existing patterns":
    let coordinates: JsonNode = parseJson("[[1, 2], [3, 4], [5, 6]]")

    # Should work with same syntax as existing tuple patterns
    let result = match coordinates:
      [(x1, y1), (x2, y2), (x3, y3)]:
        # Demonstrates consistent syntax with regular tuples
        "Points: (" & $x1.getInt() & "," & $y1.getInt() & "), " &
        "(" & $x2.getInt() & "," & $y2.getInt() & "), " &
        "(" & $x3.getInt() & "," & $y3.getInt() & ")"
      _: "invalid coordinates"
    check result == "Points: (1,2), (3,4), (5,6)"

  test "JsonNode named tuple compatibility with table patterns":
    let config: JsonNode = parseJson("""{"server": "localhost", "port": 8080, "ssl": true}""")

    # Should work seamlessly with object destructuring syntax
    let result = match config:
      (server: host, port: p, ssl: secure):
        "Server at " & host.getStr() & ":" & $p.getInt() & " (SSL: " & $secure.getBool() & ")"
      _: "invalid config"
    check result == "Server at localhost:8080 (SSL: true)"

  test "JsonNode tuple integration with existing collection filtering":
    let dataPoints: JsonNode = parseJson("[[10, 20], [30, 40], [50, 60]]")

    # Combines tuple destructuring with collection patterns
    var sum = 0
    for point in dataPoints:
      let tupleResult = match point:
        (x, y): x.getInt() + y.getInt()
        _: 0
      sum += tupleResult
    check sum == 210  # (10+20) + (30+40) + (50+60) = 30 + 70 + 110 = 210

  # Category 11: JsonNode Type Validation in Tuples
  test "JsonNode tuple with type mismatches":
    let mixedArray: JsonNode = parseJson("""[1, "hello", null]""")

    let result = match mixedArray:
      (num, str, nullVal):
        "Mixed: " & $num.getInt() & ", " & str.getStr() & ", null=" & $(nullVal.kind == JNull)
      _: "type mismatch"
    check result == "Mixed: 1, hello, null=true"

  test "JsonNode object with missing fields":
    let partialObject: JsonNode = parseJson("""{"name": "Alice", "age": 25}""")

    let result = match partialObject:
      (name: n, age: a, city: c):  # city field missing
        "Full: " & n.getStr() & ", " & $a.getInt() & ", " & c.getStr()
      (name: n, age: a):
        "Partial: " & n.getStr() & ", " & $a.getInt()
      _: "no match"
    # This should fail to match the first pattern and succeed with the second
    check result == "Partial: Alice, 25"

  # Category 12: Edge Cases and Error Handling
  test "JsonNode wrong type for tuple pattern":
    let notAnArray: JsonNode = parseJson("42")

    let result = match notAnArray:
      (x, y): "matched tuple"
      n: "matched single value: " & $n.getInt()
      _: "no match"
    check result == "matched single value: 42"

  test "JsonNode null handling in tuples":
    let arrayWithNull: JsonNode = parseJson("[1, null, 3]")

    let result = match arrayWithNull:
      (a, b, c):
        "Values: " & $a.getInt() & ", " & $(b.kind == JNull) & ", " & $c.getInt()
      _: "no match"
    check result == "Values: 1, true, 3"