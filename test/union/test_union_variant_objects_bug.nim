## Comprehensive test for union types with variant objects (case objects)
##
## BUG: Union types fail to compile when containing variant objects because
## the generated equality operator (`==`) uses default field comparison which
## triggers Nim's parallel fields iterator - not supported for case objects.
##
## Error: "parallel 'fields' iterator does not work for 'case' objects"
## Location: union_type.nim:974-978 (equality operator generation)
##
## Root Cause:
## - Generated code: `a.val0 == b.val0` where val0 is a variant object
## - Nim's default `==` for objects uses parallel `fields` iterator internally
## - Variant objects (case objects) don't support this iterator
##
## Current Workaround (used in this test):
## - All variant object types provide explicit `==` operators
## - This allows the test to compile and verify other functionality
##
## Expected Fix:
## - Union macro should generate variant-aware equality comparisons
## - Use `system.==` with proper handling for variant object types
## - Should work WITHOUT requiring user-defined `==` operators

import ../../union_type
import ../../pattern_matching
import std/unittest

# ==================== Test Types ====================

# Simple variant object
type
  NodeKind = enum nkInt, nkString, nkBool
  Node = object
    case kind: NodeKind
    of nkInt: intVal: int
    of nkString: strVal: string
    of nkBool: boolVal: bool

# Provide explicit equality for Node (workaround)
proc `==`(a, b: Node): bool =
  if a.kind != b.kind:
    return false
  case a.kind:
  of nkInt: a.intVal == b.intVal
  of nkString: a.strVal == b.strVal
  of nkBool: a.boolVal == b.boolVal

# Union with variant object - THIS IS THE BUG
type NodeUnion = union(Node, int, string)

# Nested variant objects
type
  ExprKind = enum ekLit, ekBin, ekUn
  Expr = object
    case kind: ExprKind
    of ekLit: litVal: int
    of ekBin:
      left: int
      right: int
      op: char
    of ekUn:
      operand: int

proc `==`(a, b: Expr): bool =
  if a.kind != b.kind:
    return false
  case a.kind:
  of ekLit: a.litVal == b.litVal
  of ekBin: a.left == b.left and a.right == b.right and a.op == b.op
  of ekUn: a.operand == b.operand

type ExprUnion = union(Expr, int)

# Multiple variant objects in same union
type
  Status = enum stPending, stActive
  State = object
    case status: Status
    of stPending: waitTime: int
    of stActive: taskId: int

proc `==`(a, b: State): bool =
  if a.status != b.status:
    return false
  case a.status:
  of stPending: a.waitTime == b.waitTime
  of stActive: a.taskId == b.taskId

type MultiVariantUnion = union(Node, State, int)

# Variant object with optional fields
type
  OptKind = enum okNone, okSome
  OptNode = object
    case kind: OptKind
    of okNone: discard
    of okSome: value: int

proc `==`(a, b: OptNode): bool =
  if a.kind != b.kind:
    return false
  case a.kind:
  of okNone: true
  of okSome: a.value == b.value

type OptUnion = union(OptNode, string)

# ==================== Comprehensive Tests ====================

suite "Union Types with Variant Objects - Bug Tests":

  test "basic construction with variant objects":
    let n1 = Node(kind: nkInt, intVal: 42)
    let n2 = Node(kind: nkString, strVal: "hello")

    let u1 = NodeUnion.init(n1)
    let u2 = NodeUnion.init(n2)
    let u3 = NodeUnion.init(99)

    check u1.holds(Node)
    check u2.holds(Node)
    check u3.holds(int)

  test "type checking with variant objects":
    let node = Node(kind: nkBool, boolVal: true)
    let u = NodeUnion.init(node)

    check u.holds(Node)
    check not u.holds(int)
    check not u.holds(string)

  test "value extraction with variant objects":
    let node = Node(kind: nkInt, intVal: 123)
    let u = NodeUnion.init(node)

    let extracted = u.get(Node)
    check extracted.kind == nkInt
    check extracted.intVal == 123

  test "equality comparison with variant objects":
    let n1 = Node(kind: nkInt, intVal: 42)
    let n2 = Node(kind: nkInt, intVal: 42)
    let n3 = Node(kind: nkInt, intVal: 99)
    let n4 = Node(kind: nkString, strVal: "test")

    let u1 = NodeUnion.init(n1)
    let u2 = NodeUnion.init(n2)
    let u3 = NodeUnion.init(n3)
    let u4 = NodeUnion.init(n4)

    # Same variant, same value
    check u1 == u2
    # Same variant, different value
    check u1 != u3
    # Different variant
    check u1 != u4

  test "equality with different union types":
    let node = Node(kind: nkInt, intVal: 42)
    let u1 = NodeUnion.init(node)
    let u2 = NodeUnion.init(100)

    check u1 != u2  # Different types in union

  test "string representation with variant objects":
    let node = Node(kind: nkInt, intVal: 42)
    let u = NodeUnion.init(node)

    let str = $u
    # Should contain some representation of the node
    check str.len > 0

  test "pattern matching with variant objects - type-based syntax":
    let node = Node(kind: nkString, strVal: "pattern")
    let u = NodeUnion.init(node)

    let result = match u:
      Node(n): "got node with kind: " & $n.kind
      int(i): "got int: " & $i
      string(s): "got string: " & s

    check result == "got node with kind: nkString"

  test "pattern matching with variant objects - discriminator syntax":
    let node = Node(kind: nkBool, boolVal: true)
    let u = NodeUnion.init(node)

    let result = match u:
      NodeUnion(kind: ukNode, val0: n): "node"
      NodeUnion(kind: ukInt, val1: i): "int"
      NodeUnion(kind: ukString, val2: s): "string"

    check result == "node"

  test "nested variant objects in unions":
    let expr = Expr(kind: ekBin, left: 10, right: 20, op: '+')
    let u = ExprUnion.init(expr)

    check u.holds(Expr)
    let extracted = u.get(Expr)
    check extracted.kind == ekBin
    check extracted.left == 10
    check extracted.right == 20

  test "multiple variant objects in same union":
    let node = Node(kind: nkInt, intVal: 42)
    let state = State(status: stActive, taskId: 99)

    let u1 = MultiVariantUnion.init(node)
    let u2 = MultiVariantUnion.init(state)
    let u3 = MultiVariantUnion.init(123)

    check u1.holds(Node)
    check u2.holds(State)
    check u3.holds(int)

    check u1 != u2
    check u2 != u3

  test "extraction methods with variant objects":
    let node = Node(kind: nkString, strVal: "test")
    let u = NodeUnion.init(node)

    # Conditional extraction
    if u.toNode(n):
      check n.kind == nkString
      check n.strVal == "test"
    else:
      fail()

  test "tryGet with variant objects":
    let node = Node(kind: nkInt, intVal: 999)
    let u = NodeUnion.init(node)

    let maybeNode = u.tryGet(Node)
    check maybeNode.isSome
    check maybeNode.get().intVal == 999

    let maybeInt = u.tryGet(int)
    check maybeInt.isNone

  test "variant objects with nil fields (edge case)":
    # Test that variant objects with optional fields work
    let opt1 = OptNode(kind: okNone)
    let opt2 = OptNode(kind: okSome, value: 42)

    let u1 = OptUnion.init(opt1)
    let u2 = OptUnion.init(opt2)

    check u1.holds(OptNode)
    check u2.holds(OptNode)
    check u1 != u2

  test "equality edge cases with variant objects":
    # Test self-equality
    let node = Node(kind: nkInt, intVal: 42)
    let u = NodeUnion.init(node)
    check u == u

    # Test with multiple constructions of same value
    let u1 = NodeUnion.init(Node(kind: nkInt, intVal: 100))
    let u2 = NodeUnion.init(Node(kind: nkInt, intVal: 100))
    check u1 == u2

## Summary:
## - Tests cover construction, type checking, extraction, equality, pattern matching
## - Tests use different variant object types (simple, nested, multiple)
## - Tests verify both type-based and discriminator-based pattern matching
## - Tests check edge cases (nil fields, self-equality, same values)
##
## This test file will FAIL to compile until the equality operator bug is fixed.
