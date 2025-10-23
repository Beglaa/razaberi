## Pattern Validation Module Tests - Working Version
##
## Focused test suite for pattern_validation.nim with macro-wrapped tests

import unittest
import macros
import strutils
import ../../pattern_validation
import ../../construct_metadata

# ============================================================================
# Test Suite: Pattern Kind Inference (Macro-Wrapped)
# ============================================================================

suite "Pattern Validation - Pattern Kind Inference":

  test "inferPatternKind works in macros":
    macro testInference(): untyped =
      # All AST operations must be inside macro
      let intPattern = newLit(42)
      let strPattern = newLit("hello")
      let wildcardPattern = ident("_")
      let varPattern = ident("x")

      doAssert inferPatternKind(intPattern) == pkLiteral, "Int should be literal"
      doAssert inferPatternKind(strPattern) == pkLiteral, "String should be literal"
      doAssert inferPatternKind(wildcardPattern) == pkWildcard, "_ should be wildcard"
      doAssert inferPatternKind(varPattern) == pkVariable, "x should be variable"

      result = newLit(true)

    check testInference()

  test "inferPatternKind - complex patterns":
    macro testComplexPatterns(): untyped =
      # Object pattern
      let objectPattern = newTree(nnkCall,
        ident("Person"),
        ident("name")
      )
      doAssert inferPatternKind(objectPattern) == pkObject

      # Tuple pattern
      let tuplePattern = newTree(nnkTupleConstr,
        ident("x"),
        ident("y")
      )
      doAssert inferPatternKind(tuplePattern) == pkTuple

      # Sequence pattern
      let seqPattern = newTree(nnkBracket,
        ident("a"),
        ident("b")
      )
      doAssert inferPatternKind(seqPattern) == pkSequence

      result = newLit(true)

    check testComplexPatterns()

# ============================================================================
# Test Suite: Object Pattern Validation
# ============================================================================

suite "Pattern Validation - Object Patterns":

  test "validateObjectPattern - valid fields":
    type Person = object
      name: string
      age: int

    macro testValidation(val: Person): untyped =
      let personType = val.getTypeInst()
      let personMeta = analyzeConstructMetadata(personType)

      let validPattern = newTree(nnkCall,
        ident("Person"),
        ident("name"),
        ident("age")
      )

      let validationResult = validateObjectPattern(validPattern, personMeta)
      doAssert validationResult.isValid == true, "Expected valid pattern"
      doAssert validationResult.errorMessage == "", "Expected empty error message"

      result = newLit(true)

    let val = Person(name: "Alice", age: 30)
    check testValidation(val)

  test "validateObjectPattern - invalid field":
    type Person = object
      name: string
      age: int

    macro testValidation(val: Person): untyped =
      let personType = val.getTypeInst()
      let personMeta = analyzeConstructMetadata(personType)

      let invalidPattern = newTree(nnkCall,
        ident("Person"),
        ident("email")  # Doesn't exist!
      )

      let validationResult = validateObjectPattern(invalidPattern, personMeta)
      doAssert validationResult.isValid == false, "Expected invalid pattern"
      doAssert "email" in validationResult.errorMessage, "Error should mention 'email'"

      result = newLit(true)

    let val = Person(name: "Bob", age: 25)
    check testValidation(val)

# ============================================================================
# Test Suite: Tuple Pattern Validation
# ============================================================================

suite "Pattern Validation - Tuple Patterns":

  test "validateTuplePattern - correct count":
    type Tuple3 = (int, string, float)

    macro testValidation(val: Tuple3): untyped =
      let tupleType = val.getTypeInst()
      let tupleMeta = analyzeConstructMetadata(tupleType)

      let validPattern = newTree(nnkTupleConstr,
        ident("a"),
        ident("b"),
        ident("c")
      )

      let validationResult = validateTuplePattern(validPattern, tupleMeta)
      doAssert validationResult.isValid == true

      result = newLit(true)

    let val: Tuple3 = (42, "hello", 3.14)
    check testValidation(val)

  test "validateTuplePattern - wrong count":
    type Tuple3 = (int, string, float)

    macro testValidation(val: Tuple3): untyped =
      let tupleType = val.getTypeInst()
      let tupleMeta = analyzeConstructMetadata(tupleType)

      let invalidPattern = newTree(nnkTupleConstr,
        ident("a"),
        ident("b")  # Only 2 elements, should be 3!
      )

      let validationResult = validateTuplePattern(invalidPattern, tupleMeta)
      doAssert validationResult.isValid == false
      doAssert "2" in validationResult.errorMessage
      doAssert "3" in validationResult.errorMessage

      result = newLit(true)

    let val: Tuple3 = (99, "world", 2.71)
    check testValidation(val)

# ============================================================================
# Test Suite: Array Pattern Validation
# ============================================================================

suite "Pattern Validation - Array Patterns":

  test "validateSequencePattern - array size match":
    type Array5 = array[5, int]

    macro testValidation(val: Array5): untyped =
      let arrayType = val.getTypeInst()
      let arrayMeta = analyzeConstructMetadata(arrayType)

      let validPattern = newTree(nnkBracket,
        newLit(1), newLit(2), newLit(3), newLit(4), newLit(5)
      )

      let validationResult = validateSequencePattern(validPattern, arrayMeta)
      doAssert validationResult.isValid == true

      result = newLit(true)

    let val: Array5 = [1, 2, 3, 4, 5]
    check testValidation(val)

  test "validateSequencePattern - array size mismatch":
    type Array5 = array[5, int]

    macro testValidation(val: Array5): untyped =
      let arrayType = val.getTypeInst()
      let arrayMeta = analyzeConstructMetadata(arrayType)

      let invalidPattern = newTree(nnkBracket,
        newLit(1), newLit(2), newLit(3)  # Only 3, should be 5!
      )

      let validationResult = validateSequencePattern(invalidPattern, arrayMeta)
      doAssert validationResult.isValid == false
      doAssert "3" in validationResult.errorMessage
      doAssert "5" in validationResult.errorMessage

      result = newLit(true)

    let val: Array5 = [10, 20, 30, 40, 50]
    check testValidation(val)

# ============================================================================
# Test Suite: Main Validation Entry Point
# ============================================================================

suite "Pattern Validation - Main Entry Point":

  test "validatePatternStructure - object on object":
    type Person = object
      name: string

    macro testValidation(val: Person): untyped =
      let personType = val.getTypeInst()
      let meta = analyzeConstructMetadata(personType)

      let pattern = newTree(nnkCall,
        ident("Person"),
        ident("name")
      )

      let validationResult = validatePatternStructure(pattern, meta)
      doAssert validationResult.isValid == true

      result = newLit(true)

    let val = Person(name: "Eve")
    check testValidation(val)

  test "validatePatternStructure - wrong pattern type":
    type Person = object
      name: string

    macro testValidation(val: Person): untyped =
      let personType = val.getTypeInst()
      let meta = analyzeConstructMetadata(personType)

      let wrongPattern = newTree(nnkTupleConstr,
        ident("name")
      )

      let validationResult = validatePatternStructure(wrongPattern, meta)
      doAssert validationResult.isValid == false
      doAssert "incompatible" in validationResult.errorMessage

      result = newLit(true)

    let val = Person(name: "Frank")
    check testValidation(val)

  test "validatePatternStructure - variable and wildcard":
    type Person = object
      name: string

    macro testValidation(val: Person): untyped =
      let personType = val.getTypeInst()
      let meta = analyzeConstructMetadata(personType)

      let varPattern = ident("x")
      let validationResult1 = validatePatternStructure(varPattern, meta)
      doAssert validationResult1.isValid == true

      let wildcardPattern = ident("_")
      let validationResult2 = validatePatternStructure(wildcardPattern, meta)
      doAssert validationResult2.isValid == true

      result = newLit(true)

    let val = Person(name: "Grace")
    check testValidation(val)