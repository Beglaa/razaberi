## Test suite for union type enum name collision detection
## Tests that helpful error messages are shown when enum name collisions occur

import unittest
import ../../union_type

suite "Union Type Enum Collision Detection":

  test "seq[int] and Seq[int] collision is detected":
    ## This test verifies that a collision between seq[int] and Seq[int]
    ## produces a helpful compile-time error message

    type
      Seq[T] = object  # Custom generic type with capital S
        data: seq[T]
        len: int

    # This should NOT compile - collision between seq[int] and Seq[int]
    check not compiles(
      type MyUnion = union(seq[int], Seq[int])
    )

  # NOTE: We can't test the successful workaround inline because union
  # requires module-level declarations. See the module-level test below.

  test "option[T] and Option[T] collision is detected":
    ## Test collision detection for generic types with different capitalization

    type
      option[T] = object  # lowercase 'o'
        hasValue: bool
        value: T

    # This should NOT compile - collision
    check not compiles(
      type MyUnion = union(option[string], Option[string])
    )

  # NOTE: Positive tests (successful unions) require module-level declarations

  test "three types with collision is detected":
    ## Test that we catch collisions even with more than 2 types

    type
      Seq[T] = object
        data: seq[T]

    # The collision should be detected between seq[int] and Seq[int]
    # even though there's a third type in the union
    check not compiles(
      type MyUnion = union(seq[int], string, Seq[int])
    )

  test "collision with complex generic types":
    ## Test collision detection with nested generics

    type
      Table[K, V] = object  # Custom Table with capital T
        data: seq[tuple[k: K, v: V]]

    # Should detect collision between table and Table
    check not compiles(
      type MyUnion = union(table[string, int], Table[string, int])
    )

  test "multiple collisions are detected":
    ## Test that the first collision is reported

    type
      Seq[T] = object
        data: seq[T]
      Option[T] = object
        hasValue: bool

    # Should detect the first collision (seq vs Seq)
    check not compiles(
      type MyUnion = union(seq[int], Seq[int], option[string], Option[string])
    )

  # NOTE: Positive tests (successful unions) require module-level declarations
  # See module-level tests below the suite

# ===== Module-Level Tests for Successful Unions =====

# Test 1: Workaround with different type name
type
  MySeq[T] = object  # Different name - not "Seq"
    data: seq[T]
    len: int

type TestUnion1 = union(seq[int], MySeq[int])

# Test 2: No collision for distinct types
type TestUnion2 = union(seq[int], seq[string], Option[int], Option[string])

# Test 3: ref types don't cause false collisions
type TestUnion3 = union(seq[int], ref seq[int])

# Test 4: ptr types don't cause false collisions
type TestUnion4 = union(int, ptr int)

# Verify these work at runtime
suite "Union Type Collision - Positive Tests":
  test "workaround with different type name succeeds":
    let val1 = TestUnion1.init(@[1, 2, 3])
    let val2 = TestUnion1.init(MySeq[int](data: @[4, 5, 6], len: 3))

    check val1.holds(seq[int])
    check val2.holds(MySeq[int])

  test "no collision for distinct types":
    let val1 = TestUnion2.init(@[1, 2, 3])
    let val2 = TestUnion2.init(@["a", "b"])
    let val3 = TestUnion2.init(some(42))
    let val4 = TestUnion2.init(some("hello"))

    check val1.holds(seq[int])
    check val2.holds(seq[string])
    check val3.holds(Option[int])
    check val4.holds(Option[string])

  test "ref types don't cause false collisions":
    let val1 = TestUnion3.init(@[1, 2, 3])
    var refSeq = new seq[int]
    refSeq[] = @[4, 5, 6]
    let val2 = TestUnion3.init(refSeq)

    check val1.holds(seq[int])
    check val2.holds(ref seq[int])

  test "ptr types don't cause false collisions":
    let val1 = TestUnion4.init(42)
    var x = 100
    let val2 = TestUnion4.init(addr x)

    check val1.holds(int)
    check val2.holds(ptr int)
