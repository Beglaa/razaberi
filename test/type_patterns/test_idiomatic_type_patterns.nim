import std/unittest
import ../../pattern_matching
import tables
import ../helper/ccheck

suite "Idiomatic Type Pattern Tests":
  test "should support compile-time 'is' type checking in tuples":
    # Basic compile-time type checking with 'is' operator
    let data: (int, string) = (42, "hello")
    let result = match data:
      (x is int, y is string): "int: " & $x & ", string: " & y
      _: "type mismatch"
    check(result == "int: 42, string: hello")

    let aaa: auto = "aa"
    let result1 = match aaa:
      number is int:
        "Integer: " & $number
      flag is bool: 
        "Boolean: " & $flag
      text is string:
        "String: " & text
      f is float:
        "Float: " & $f
      c is char:
        "Char: " & $c
      t is (int, string):
        "Tuple[int, string]"
      s is seq[int]:
        "Seq[int]"
      t is Table[string, int]:
        "Table[string, int]"
      o is ref object:
        "Ref object"
      _:
        "Unknown type"
    check(result1 == "String: aa")

    # Mixed types with 'is' checking
    let mixedData: (float, char, bool) = (3.14, 'A', true)
    let result2 = match mixedData:
      (pi is float, ch is char, flag is bool): 
        "float: " & $pi & ", char: " & ch & ", bool: " & $flag
      _: "type mismatch"
    check(result2 == "float: 3.14, char: A, bool: true")

  test "should support runtime 'of' inheritance checking in tuples":
    # Object inheritance hierarchy for testing
    type 
      Animal = ref object of RootObj
        name: string
      Dog = ref object of Animal  
        breed: string
      Cat = ref object of Animal
        indoor: bool
      Bird = ref object of Animal
        canFly: bool
        
    let myDog = Dog(name: "Buddy", breed: "Golden Retriever")
    let myCat = Cat(name: "Whiskers", indoor: true)
    let myBird = Bird(name: "Tweety", canFly: true)
    
    # Test specific type matching
    let pets: (Dog, Cat) = (myDog, myCat)
    let result1 = match pets:
      (dog of Dog, cat of Cat): 
        "Dog: " & dog.name & " (" & dog.breed & "), Cat: " & cat.name & " (indoor: " & $cat.indoor & ")"
      _: "not pets"
    check(result1 == "Dog: Buddy (Golden Retriever), Cat: Whiskers (indoor: true)")
    
    # Test base type polymorphism
    let animals: (Animal, Animal) = (myDog, myBird)  
    let result2 = match animals:
      (dog of Dog, bird of Bird): 
        "Specific: " & dog.breed & ", " & bird.name & " flies: " & $bird.canFly
      (a1 of Animal, a2 of Animal): 
        "General: " & a1.name & ", " & a2.name
      _: "not animals"
    check(result2 == "Specific: Golden Retriever, Tweety flies: true")

  test "should handle type patterns with wildcards":
    let data: (int, string, float) = (42, "test", 3.14)
    let result = match data:
      (x is int, _ is string, z is float): "int: " & $x & ", float: " & $z
      _: "no match"
    check(result == "int: 42, float: 3.14")

  test "should combine type patterns with nested tuples":
    let nested: ((int, string), (float, bool)) = ((42, "hello"), (3.14, true))
    let result = match nested:
      ((x is int, y is string), (z is float, w is bool)): 
        $x & "," & y & "," & $z & "," & $w
      _: "no match"
    check(result == "42,hello,3.14,true")

  test "should work with type patterns in simple matching":
    type
      Animal = ref object of RootObj
        name: string  
      Dog = ref object of Animal
      Cat = ref object of Animal
        
    let myDog = Dog(name: "Rex")
    let myCat = Cat(name: "Felix")
    
    # Test individual type patterns (OR patterns with 'of' not yet supported in main match)  
    let pet1: Animal = myDog
    let result1 = match pet1:
      dog of Dog: "Dog: " & dog.name
      cat of Cat: "Cat: " & cat.name
      _: "not a pet"
    check(result1 == "Dog: Rex")
    
    let pet2: Animal = myCat  
    let result2 = match pet2:
      dog of Dog: "Dog: " & dog.name
      cat of Cat: "Cat: " & cat.name
      _: "not a pet" 
    check(result2 == "Cat: Felix")

  test "should handle complex inheritance hierarchies":
    type
      Vehicle = ref object of RootObj
        wheels: int
      Car = ref object of Vehicle
        doors: int  
      Truck = ref object of Vehicle
        payload: int
      SportsCar = ref object of Car
        topSpeed: int
        
    let myCar = SportsCar(wheels: 4, doors: 2, topSpeed: 250)
    let myTruck = Truck(wheels: 6, payload: 5000)
    
    let vehicles: (Vehicle, Vehicle) = (myCar, myTruck)
    let result = match vehicles:
      (sports of SportsCar, truck of Truck):
        "Sports car: " & $sports.topSpeed & "mph, Truck: " & $truck.payload & "kg"
      (car of Car, truck of Truck):
        "Regular car with " & $car.doors & " doors, Truck: " & $truck.payload & "kg"  
      _: "unknown vehicles"
    check(result == "Sports car: 250mph, Truck: 5000kg")


  
