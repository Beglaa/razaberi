import unittest
import tables
import options
import ../../pattern_matching

suite "Class Pattern Tests":
  type
    Point = object
      x, y: int
    
    Person = object
      name: string
      age: int
    
    Shape = object
      kind: string
      area: float

  test "should match class patterns with positional arguments":
    let p = Point(x: 10, y: 20)
    let result = match p:
      Point(x, y) : "Point at " & $x & ", " & $y
      _ : "Not a point"
    check(result == "Point at 10, 20")

  test "should match class patterns with named arguments":
    let person = Person(name: "Alice", age: 25)
    let result = match person:
      Person(name=n, age=a) : n & " is " & $a & " years old"
      _ : "Unknown person"
    check(result == "Alice is 25 years old")

  test "should match class patterns with mixed arguments":
    let p = Point(x: 5, y: 15)
    let result = match p:
      Point(x, y=vertical) : "X=" & $x & ", Y=" & $vertical
      _ : "No match"
    check(result == "X=5, Y=15")

  test "should handle class patterns with guards":
    let p1 = Point(x: 10, y: 20)
    let result1 = match p1:
      Point(x, y) and x > 5 : "X is big: " & $x
      Point(x, y) : "X is small: " & $x
    check(result1 == "X is big: 10")
    
    let p2 = Point(x: 2, y: 8)
    let result2 = match p2:
      Point(x, y) and x > 5 : "X is big: " & $x
      Point(x, y) : "X is small: " & $x
    check(result2 == "X is small: 2")

  test "should handle class pattern type checking":
    let s = Shape(kind: "circle", area: 3.14)
    let result = match s:
      Shape(kind, area) : "Shape: " & kind & ", area: " & $area
      _ : "Unknown"
    check(result == "Shape: circle, area: 3.14")