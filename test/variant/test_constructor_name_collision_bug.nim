## FIXED: Constructor Name Collision in Variant DSL ✅
##
## Previously, when multiple variant types used the same constructor names,
## the generated constructor procs collided. This has been FIXED using UFCS syntax.
##
## Solution: Constructors now use typedesc parameter for UFCS:
## - Old (collision): proc Ready(): Status
## - New (no collision): proc Ready(_: typedesc[Status]): Status
## - Usage: Status.Ready() instead of Ready()
##
## This test verifies the fix works correctly.

import unittest
import ../../variant_dsl
import ../../pattern_matching

suite "Constructor Name Collision - FIXED Tests":

  test "FIX VERIFIED 1: zero-parameter constructors with same name work":
    # Previously: proc Ready(): Status collided with proc Ready(): State
    # Now: Type prefix disambiguates via UFCS

    variant Status:
      Ready()

    variant State:
      Ready()  # ✅ FIXED: No collision with UFCS syntax!

    let status = Status.Ready()
    let state = State.Ready()

    check status is Status
    check state is State
    check status.kind == skReady
    check state.kind == skReady

  test "FIX VERIFIED 2: single-parameter constructors with identical signature":
    # Both variants can now have Value(x: int) without collision

    variant TypeA:
      Value(x: int)

    variant TypeB:
      Value(x: int)  # ✅ FIXED: Type.Value(x) syntax prevents collision!

    let a = TypeA.Value(42)
    let b = TypeB.Value(100)

    check a is TypeA
    check a.x == 42
    check b is TypeB
    check b.x == 100

  test "FIX VERIFIED 3: multi-parameter constructors with same signature":
    # Multi-parameter constructors with identical signatures now work

    variant Point2D:
      Cartesian(x: float, y: float)

    variant Vector2D:
      Cartesian(x: float, y: float)  # ✅ FIXED: No collision!

    let point = Point2D.Cartesian(1.0, 2.0)
    let vector = Vector2D.Cartesian(3.0, 4.0)

    check point is Point2D
    check point.x == 1.0
    check vector is Vector2D
    check vector.x == 3.0

  test "FIX VERIFIED 4: real-world composability - HTTP status example":
    # Independent types can now use logical constructor names

    variant ApiResponse:
      Success()

    variant DatabaseState:
      Success()  # ✅ FIXED: Composability restored!

    let api = ApiResponse.Success()
    let db = DatabaseState.Success()

    check api is ApiResponse
    check db is DatabaseState

  test "FIX VERIFIED 5: library composability enabled":
    # Independent modules can now use the same logical names

    variant Color:
      Named()

    variant Shape:
      Named()  # ✅ FIXED: Modular design now possible!

    let color = Color.Named()
    let shape = Shape.Named()

    check color is Color
    check shape is Shape

  test "UFCS syntax with different parameter types":
    # UFCS works perfectly with type overloading
    variant IntWrapper:
      Value(x: int)

    variant StringWrapper:
      Value(s: string)

    let intVal = IntWrapper.Value(42)
    let strVal = StringWrapper.Value("hello")

    check intVal is IntWrapper
    check intVal.x == 42
    check strVal is StringWrapper
    check strVal.s == "hello"

  test "pattern matching with UFCS constructors":
    # Pattern matching works seamlessly with UFCS syntax

    variant Result:
      Ok(value: int)
      Error(msg: string)

    let success = Result.Ok(42)
    let failure = Result.Error("failed")

    let successResult = match success:
      Result.Ok(v): v * 2
      Result.Error(_): 0

    let failureResult = match failure:
      Result.Ok(_): -1
      Result.Error(msg): msg.len

    check successResult == 84
    check failureResult == 6

  test "exhaustiveness checking with UFCS patterns":
    # Exhaustiveness checking works with UFCS syntax

    variant Status:
      Active()
      Inactive()
      Pending()

    let s = Status.Active()

    # Compiler should accept this as exhaustive
    let result = match s:
      Status.Active(): "active"
      Status.Inactive(): "inactive"
      Status.Pending(): "pending"

    check result == "active"

  test "mixed zero and multi-param constructors with UFCS":
    # UFCS works for both zero-param and multi-param constructors

    variant Node:
      Empty()
      Leaf(value: int)
      Branch(left: int, right: int)

    let empty = Node.Empty()
    let leaf = Node.Leaf(42)
    let branch = Node.Branch(1, 2)

    check empty.kind == nkEmpty
    check leaf.kind == nkLeaf
    check leaf.value == 42
    check branch.kind == nkBranch
    check branch.left == 1
    check branch.right == 2
