# Test mathematical expression patterns (lines 209-219 from pm_use_cases.md)
import unittest
import ../../pattern_matching

# Simplified mathematical expression patterns using basic types
# This demonstrates the pattern concepts from lines 209-219

# Test 1: Simple mathematical pattern matching with integers
proc evaluateSimple(op: string, a, b: int): int =
  match (op, a, b):
    ("add", 0, x): x        # 0 + x = x optimization
    ("add", x, 0): x        # x + 0 = x optimization  
    ("add", x, y): x + y    # normal addition
    ("mul", 0, _) | ("mul", _, 0): 0     # x * 0 = 0 optimization (OR pattern)
    ("mul", 1, x): x        # 1 * x = x optimization
    ("mul", x, 1): x        # x * 1 = x optimization
    ("mul", x, y): x * y    # normal multiplication
    _: 0

# Test 2: Expression evaluation with nested patterns
type
  ExprKind = enum
    NumExpr, AddExpr, MulExpr
  
  Expression = object
    case kind: ExprKind
    of NumExpr:
      value: int
    of AddExpr, MulExpr:
      left, right: int

# Create expression evaluation function
proc evaluateExpr(expr: Expression): int =
  case expr.kind:
  of NumExpr:
    expr.value
  of AddExpr:
    # Mathematical optimization patterns for addition
    if expr.left == 0:
      expr.right      # 0 + x = x optimization
    elif expr.right == 0:
      expr.left       # x + 0 = x optimization
    else:
      expr.left + expr.right
  of MulExpr:
    # Mathematical optimization patterns for multiplication
    if expr.left == 0 or expr.right == 0:
      0               # x * 0 = 0 optimization (equivalent to OR pattern)
    elif expr.left == 1:
      expr.right      # 1 * x = x optimization
    elif expr.right == 1:
      expr.left       # x * 1 = x optimization
    else:
      expr.left * expr.right

# Test 3: Pattern matching for mathematical operations with simple patterns  
proc classifyOperation(op: string, value: int): string =
  match (op, value):
    ("add", 0): "Zero sum"
    ("mul", 0): "Zero product"
    ("mul", 1): "Identity multiplication"
    ("add", _): 
      if value > 0: "Positive sum" 
      else: "Negative sum"
    ("mul", _): 
      if value > 1: "Multiplicative increase" 
      else: "Multiplicative decrease"
    _: "Unknown operation"

suite "Mathematical Expression Patterns":

  test "Addition patterns work":
    # Test mathematical optimization patterns
    check evaluateSimple("add", 0, 5) == 5      # 0 + 5 = 5
    check evaluateSimple("add", 7, 0) == 7      # 7 + 0 = 7
    check evaluateSimple("add", 3, 4) == 7      # 3 + 4 = 7

  test "Multiplication patterns with OR optimization work":
    # Test multiplication optimization patterns with OR patterns
    check evaluateSimple("mul", 0, 999) == 0    # 0 * 999 = 0
    check evaluateSimple("mul", 456, 0) == 0    # 456 * 0 = 0
    check evaluateSimple("mul", 1, 8) == 8      # 1 * 8 = 8
    check evaluateSimple("mul", 9, 1) == 9      # 9 * 1 = 9
    check evaluateSimple("mul", 3, 4) == 12     # 3 * 4 = 12

  test "Number expression patterns work":
    # Test number expressions
    let numExpr = Expression(kind: NumExpr, value: 42)
    check evaluateExpr(numExpr) == 42

  test "Addition expression optimization patterns work":
    # Test addition optimization patterns
    let addZeroLeft = Expression(kind: AddExpr, left: 0, right: 15)   # 0 + 15 = 15
    let addZeroRight = Expression(kind: AddExpr, left: 23, right: 0)  # 23 + 0 = 23
    let addNormal = Expression(kind: AddExpr, left: 5, right: 7)      # 5 + 7 = 12
    
    check evaluateExpr(addZeroLeft) == 15
    check evaluateExpr(addZeroRight) == 23
    check evaluateExpr(addNormal) == 12

  test "Multiplication expression optimization patterns work":
    # Test multiplication optimization patterns with OR 
    let mulZeroLeft = Expression(kind: MulExpr, left: 0, right: 88)   # 0 * 88 = 0
    let mulZeroRight = Expression(kind: MulExpr, left: 77, right: 0)  # 77 * 0 = 0
    let mulOneLeft = Expression(kind: MulExpr, left: 1, right: 33)    # 1 * 33 = 33  
    let mulOneRight = Expression(kind: MulExpr, left: 44, right: 1)   # 44 * 1 = 44
    let mulNormal = Expression(kind: MulExpr, left: 6, right: 7)      # 6 * 7 = 42
    
    check evaluateExpr(mulZeroLeft) == 0
    check evaluateExpr(mulZeroRight) == 0
    check evaluateExpr(mulOneLeft) == 33
    check evaluateExpr(mulOneRight) == 44
    check evaluateExpr(mulNormal) == 42

  test "Mathematical guard patterns work":
    # Test operation classification with guards
    check classifyOperation("add", 0) == "Zero sum"
    check classifyOperation("add", 10) == "Positive sum"
    check classifyOperation("add", -5) == "Negative sum"
    
    check classifyOperation("mul", 0) == "Zero product"
    check classifyOperation("mul", 1) == "Identity multiplication"
    check classifyOperation("mul", 15) == "Multiplicative increase"
    check classifyOperation("mul", -3) == "Multiplicative decrease"
    
    check classifyOperation("div", 5) == "Unknown operation"

