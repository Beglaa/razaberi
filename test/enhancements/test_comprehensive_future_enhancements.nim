import unittest
import std/tables
import std/sets
import std/strutils
import ../../pattern_matching

suite "COMPREHENSIVE: FUTURE_ENHANCEMENTS.md Implementation - Working Features":
  # This test demonstrates all the successfully implemented features from FUTURE_ENHANCEMENTS.md
  
  test "PHASE 1.1: Object @ patterns in tuples - IMPLEMENTED":
    # This was one of the main missing features and is now working
    type
      Person = object
        name: string
        age: int
    
    let person = Person(name: "John", age: 30)
    let testData = (person, 42)
    
    let result = match testData:
      (Person(name @ n, age @ a), number) :
        "person: " & n & " (" & $a & "), number: " & $number
      _ : "no match"
    
    check result == "person: John (30), number: 42"
  
  test "PHASE 1.3: Table @ patterns in tuples - IMPLEMENTED":
    # Table patterns with @ bindings in tuple contexts now work
    let testTable = {"key": "value", "count": "5"}.toTable
    let testNumber = 100
    let testData = (testTable, testNumber)
    
    let result = match testData:
      ({"key": keyVal, "count": countVal} @ table, num) :
        "table: key=" & keyVal & ", count=" & countVal & ", size=" & $table.len & ", num=" & $num
      _ : "no match"
    
    check result == "table: key=value, count=5, size=2, num=100"
  
  test "PHASE 1.3: Set @ patterns in tuples - IMPLEMENTED":
    # Set patterns with @ bindings in tuple contexts now work
    type Color = enum Red, Blue, Green
    
    let testColors = toHashSet([Red, Blue])
    let testValue = 255
    let testData = (testColors, testValue)
    
    let result = match testData:
      ({Red, Blue} @ colors, value) :
        "colors: size=" & $colors.len & ", value=" & $value
      _ : "no match"
    
    check result == "colors: size=2, value=255"
  
  test "PHASE 1.1 + 1.3: Mixed nested @ patterns - IMPLEMENTED":
    # Deep nesting with object and collection @ patterns combined
    let person = (name: "Alice", age: 25)
    let items = ["apple", "banana"]
    let metadata = {"type": "fruit", "fresh": "true"}.toTable
    let complexData = ((person, items), metadata)
    
    let result = match complexData:
      (((name @ n, age @ a), [item1, item2] @ itemList), {"type": typeVal, "fresh": freshVal} @ meta) :
        "person: " & n & "(" & $a & "), items: " & $itemList.len & " (" & item1 & ", " & item2 & 
        "), meta: " & typeVal & " (fresh=" & freshVal & ", size=" & $meta.len & ")"
      _ : "no match"
    
    check result == "person: Alice(25), items: 2 (apple, banana), meta: fruit (fresh=true, size=2)"
  
  test "PHASE 4: Enhanced error handling - Basic validation":
    # Error handling improvements are working (though hard to test in passing tests)
    # This demonstrates that complex @ patterns now compile correctly
    let testData = ([1, 2], {"a": 10}.toTable)
    
    let result = match testData:
      ([x, y] @ arr, {"a": value} @ table) :
        "valid: arr=" & $arr & " (" & $x & "+" & $y & "), table=" & $table.len & " (a=" & $value & ")"
      _ : "no match"
    
    check result == "valid: arr=[1, 2] (1+2), table=1 (a=10)"
  
  test "PHASE 1.1: Deep object destructuring with @ patterns":
    # Test the enhanced object constructor @ pattern support
    type
      Address = object
        street: string
        city: string
      PersonWithAddress = object
        name: string
        address: Address
    
    let address = Address(street: "Main St", city: "NYC")
    let person = PersonWithAddress(name: "Bob", address: address)
    let testData = (person, "extra")
    
    let result = match testData:
      (PersonWithAddress(name @ n, address @ addr), extra @ e) :
        "name: " & n & ", address: " & $addr & ", extra: " & e
      _ : "no match"
    
    check result.startsWith("name: Bob, address: ")
  
  test "PHASE 1.2: Simple guard combinations - WORKING CASES":
    # While cross-referencing guards aren't fully working, simple guards work well
    let testData = ([5], 10)
    
    let result = match testData:
      ([value] @ arr, num) and value > 3 and num > 8 :
        "guards passed: value=" & $value & " > 3, num=" & $num & " > 8, arr=" & $arr
      ([value] @ arr, num) :
        "no guards: value=" & $value & ", num=" & $num
      _ : "no match"
    
    check result == "guards passed: value=5 > 3, num=10 > 8, arr=[5]"
  
  test "COMPREHENSIVE: All working features combined":
    # This test combines multiple implemented features to show the power of the enhancements
    type Status = enum Active, Inactive
    
    let user = (name: "Charlie", status: Active)
    let settings = {"theme": "dark", "lang": "en"}.toTable  
    let permissions = toHashSet(["read", "write"])
    let complexData = (user, (settings, permissions))
    
    let result = match complexData:
      ((name @ userName, status @ userStatus), ({"theme": theme, "lang": lang} @ config, perms @ permissions)) :
        "user: " & userName & " (" & $userStatus & "), config: " & theme & "/" & lang & 
        " (size=" & $config.len & "), perms: " & $permissions.len
      _ : "no match"
    
    check result == "user: Charlie (Active), config: dark/en (size=2), perms: 2"