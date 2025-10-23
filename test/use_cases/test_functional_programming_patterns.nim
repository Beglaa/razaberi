# Test functional programming patterns (lines 357-372 from pm_use_cases.md)
import unittest
import ../../pattern_matching

# Test 1: List processing patterns with recursive head/tail destructuring (lines 357-364)
proc processFunctionalList(items: seq[int]): seq[int] =
  match items:
    []: @[]
    [head, *tail]:
      match head:
        x and x > 0: @[x * 2] & processFunctionalList(tail)
        _: processFunctionalList(tail)

# Test 2: Currying-like patterns - function factories (lines 366-372)
proc makeCalculator(operation: string): proc(x, y: int): int =
  match operation:
    "add": 
      proc(x, y: int): int = x + y
    "multiply": 
      proc(x, y: int): int = x * y  
    "power": 
      proc(x, y: int): int = x * x  # Simple square for demonstration
    _: 
      proc(x, y: int): int = 0

# Test 3: Functional map using pattern matching
proc functionalMap(items: seq[int], transform: proc(x: int): int): seq[int] =
  match items:
    []: @[]
    [head, *tail]: @[transform(head)] & functionalMap(tail, transform)

# Test 4: Functional filter using pattern matching
proc functionalFilter(items: seq[int], predicate: proc(x: int): bool): seq[int] =
  match items:
    []: @[]
    [head, *tail]:
      let rest = functionalFilter(tail, predicate)
      if predicate(head):
        @[head] & rest
      else:
        rest

# Test 5: Functional fold/reduce using pattern matching
proc functionalFold(items: seq[int], initial: int, operation: proc(acc, x: int): int): int =
  match items:
    []: initial
    [head, *tail]: functionalFold(tail, operation(initial, head), operation)

# Test 6: Pattern matching on function composition
proc composeOperations(op1, op2: string): proc(x: int): int =
  match (op1, op2):
    ("double", "increment"): 
      proc(x: int): int = (x * 2) + 1
    ("increment", "double"): 
      proc(x: int): int = (x + 1) * 2
    ("square", "increment"): 
      proc(x: int): int = (x * x) + 1
    ("increment", "square"): 
      proc(x: int): int = (x + 1) * (x + 1)
    _: 
      proc(x: int): int = x

# Test 7: Functional pipeline patterns
proc createPipeline(operations: seq[string]): proc(x: int): int =
  match operations:
    []: 
      proc(x: int): int = x
    ["double"]: 
      proc(x: int): int = x * 2
    ["increment"]: 
      proc(x: int): int = x + 1
    ["square"]: 
      proc(x: int): int = x * x
    [op, *rest]:
      let firstOp = createPipeline(@[op])
      let restOp = createPipeline(rest)
      proc(x: int): int = 
        restOp(firstOp(x))

# Test 8: Functional list operations with pattern matching
proc listSum(items: seq[int]): int =
  match items:
    []: 0
    [single]: single
    [a, b]: a + b
    [first, *rest]: first + listSum(rest)

proc listProduct(items: seq[int]): int =
  match items:
    []: 1
    [single]: single
    [a, b]: a * b
    [first, *rest]: first * listProduct(rest)

# Test 9: Functional pattern combinations
proc complexFunctionalProcessing(items: seq[int]): (seq[int], int, int) =
  let doubled = processFunctionalList(items)
  let filtered = functionalFilter(items, proc(x: int): bool = x > 0)
  let sum = functionalFold(items, 0, proc(acc, x: int): int = acc + x)
  (doubled, filtered.len, sum)

suite "Functional Programming Patterns":

  test "List processing patterns work":
    # Test empty list
    check processFunctionalList(@[]) == newSeq[int](0)
    
    # Test list with positive numbers
    check processFunctionalList(@[1, 2, 3]) == @[2, 4, 6]
    
    # Test list with mixed numbers (negatives filtered out)
    check processFunctionalList(@[1, -1, 2, -2, 3]) == @[2, 4, 6]
    
    # Test list with all negatives
    check processFunctionalList(@[-1, -2, -3]) == newSeq[int](0)
    
    # Test list with zeros and positives
    check processFunctionalList(@[0, 1, 0, 2, 0]) == @[2, 4]

  test "Currying-like patterns work":
    # Test calculator creation
    let adder = makeCalculator("add")
    let multiplier = makeCalculator("multiply")
    let powerFunc = makeCalculator("power")
    let defaultFunc = makeCalculator("unknown")
    
    # Test addition
    check adder(3, 4) == 7
    check adder(10, 5) == 15
    
    # Test multiplication
    check multiplier(3, 4) == 12
    check multiplier(7, 6) == 42
    
    # Test power (square in this case)
    check powerFunc(5, 3) == 25  # 5 * 5 = 25, demonstrates pattern concept
    
    # Test default case
    check defaultFunc(10, 20) == 0

  test "Functional map works":
    let double = proc(x: int): int = x * 2
    let square = proc(x: int): int = x * x
    
    # Test mapping with doubling
    check functionalMap(@[1, 2, 3, 4], double) == @[2, 4, 6, 8]
    
    # Test mapping with squaring
    check functionalMap(@[1, 2, 3], square) == @[1, 4, 9]
    
    # Test empty list
    check functionalMap(@[], double) == newSeq[int](0)

  test "Functional filter works":
    let isPositive = proc(x: int): bool = x > 0
    let isEven = proc(x: int): bool = x mod 2 == 0
    
    # Test filtering positive numbers
    check functionalFilter(@[1, -2, 3, -4, 5], isPositive) == @[1, 3, 5]
    
    # Test filtering even numbers
    check functionalFilter(@[1, 2, 3, 4, 5, 6], isEven) == @[2, 4, 6]
    
    # Test empty result
    check functionalFilter(@[-1, -2, -3], isPositive) == newSeq[int](0)
    
    # Test empty input
    check functionalFilter(@[], isPositive) == newSeq[int](0)

  test "Functional fold works":
    let add = proc(acc, x: int): int = acc + x
    let multiply = proc(acc, x: int): int = acc * x
    
    # Test sum with fold
    check functionalFold(@[1, 2, 3, 4], 0, add) == 10
    
    # Test product with fold
    check functionalFold(@[1, 2, 3, 4], 1, multiply) == 24
    
    # Test empty list
    check functionalFold(@[], 42, add) == 42
    
    # Test single element
    check functionalFold(@[5], 10, add) == 15

  test "Function composition patterns work":
    # Test different composition orders
    let doubleIncrement = composeOperations("double", "increment")
    let incrementDouble = composeOperations("increment", "double")
    let squareIncrement = composeOperations("square", "increment")
    let incrementSquare = composeOperations("increment", "square")
    let unknown = composeOperations("unknown", "operation")
    
    # Test double then increment: (x * 2) + 1
    check doubleIncrement(3) == 7  # (3 * 2) + 1 = 7
    
    # Test increment then double: (x + 1) * 2
    check incrementDouble(3) == 8  # (3 + 1) * 2 = 8
    
    # Test square then increment: (x * x) + 1
    check squareIncrement(3) == 10  # (3 * 3) + 1 = 10
    
    # Test increment then square: (x + 1) * (x + 1)
    check incrementSquare(3) == 16  # (3 + 1) * (3 + 1) = 16
    
    # Test unknown operation
    check unknown(5) == 5

  test "Functional pipeline patterns work":
    # Test empty pipeline
    let identity = createPipeline(@[])
    check identity(5) == 5
    
    # Test single operations
    let doubleOp = createPipeline(@["double"])
    let incrementOp = createPipeline(@["increment"])
    let squareOp = createPipeline(@["square"])
    
    check doubleOp(3) == 6
    check incrementOp(3) == 4
    check squareOp(3) == 9
    
    # Test complex pipelines
    let doubleThenIncrement = createPipeline(@["double", "increment"])
    let incrementThenSquare = createPipeline(@["increment", "square"])
    
    check doubleThenIncrement(3) == 7  # (3 * 2) + 1 = 7
    check incrementThenSquare(3) == 16  # (3 + 1) ^ 2 = 16

  test "List operations with pattern matching work":
    # Test sum operations
    check listSum(@[]) == 0
    check listSum(@[5]) == 5
    check listSum(@[3, 4]) == 7
    check listSum(@[1, 2, 3, 4]) == 10
    
    # Test product operations
    check listProduct(@[]) == 1
    check listProduct(@[5]) == 5
    check listProduct(@[3, 4]) == 12
    check listProduct(@[1, 2, 3, 4]) == 24

  test "Complex functional processing works":
    # Test complex combination of functional patterns
    let (doubled, filteredCount, sum) = complexFunctionalProcessing(@[1, -2, 3, -4, 5])
    
    # Doubled: positive numbers doubled
    check doubled == @[2, 6, 10]
    
    # Filtered count: count of positive numbers
    check filteredCount == 3
    
    # Sum: sum of all numbers
    check sum == 3  # 1 + (-2) + 3 + (-4) + 5 = 3
    
    # Test empty input
    let (emptyDoubled, emptyCount, emptySum) = complexFunctionalProcessing(@[])
    check emptyDoubled == newSeq[int](0)
    check emptyCount == 0
    check emptySum == 0

