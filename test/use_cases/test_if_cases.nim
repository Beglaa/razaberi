import unittest
import ../../pattern_matching
import ../helper/ccheck
import options
import tables

suite "If-cases test suite":
  setup:
    type
      Person = tuple[name: string, middleName: string, age: int]
      Coordinates = tuple[x: int, y: int]
      Point = object
        x, y: int
      User = object
        name: string
        age: int
        email: string
      Color = enum
        Red, Green, Blue

suite "someTo macro tests":
    test "basic some case with immutable binding":
      var opt = some(42)
      if opt.someTo(x):
        check x == 42
        check typeof(x) is int
      else:
        fail()
    
    test "basic some case with mutable binding":
      var opt = some(42)
      if opt.someTo(var y):
        check y == 42
        y = 100
        check y == 100
      else:
        fail()
    
    test "none case - early exit":
      var opt = none[int]()
      if opt.someTo(z):
        fail()
      else:
        # z doesn't exist here - no variable was created
        check true
    
    test "none case with var - early exit":
      var opt = none[int]()
      if opt.someTo(var w):
        fail()
      else:
        # w doesn't exist here - no variable was created
        check true
    
    test "single evaluation - no side effects":
      var callCount = 0
      proc getOption(): Option[int] =
        inc callCount
        return some(123)
      
      if getOption().someTo(val):
        check val == 123
        check callCount == 1  # Called only once!
      else:
        fail()

suite "enhanced someTo with guards":
    test "someTo with value guard":
      var opt = some(42)
      if opt.someTo(x and x > 10):
        check x == 42
        check x > 10
      else:
        fail()
    
    test "someTo with range guard":
      var opt = some(25)
      if opt.someTo(x and x in 10..50):
        check x == 25
        check x >= 10 and x <= 50
      else:
        fail()
    
    test "someTo with type guard":
      var opt = some(100)
      if opt.someTo(x is int):
        check x == 100
        check typeof(x) is int
      else:
        fail()
    
    test "someTo with set membership guard":
      var opt = some(5)
      if opt.someTo(x in [1, 5, 10]):
        check x == 5
      else:
        fail()
    
    test "someTo with complex guard expression":
      var opt = some(15)
      if opt.someTo(x > 10 and x < 20):
        check x == 15
        check x > 10 and x < 20
      else:
        fail()

    test "someTo with range comparison":
      var opt = some(15)
      if opt.someTo(10 < x < 20):
        check x == 15
        check x > 10 and x < 20
      else:
        fail()
    
    test "someTo guard fails - early exit":
      var opt = some(5)
      if opt.someTo(x > 10):
        fail()  # Should not reach here
      else:
        check true  # x is not created when guard fails

