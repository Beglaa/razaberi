## Test: Union types with variant objects work when custom == is provided
##
## This test demonstrates the SOLUTION to the variant object equality bug.
## By providing custom == operators for variant objects, unions work perfectly.
##
## This test should PASS (demonstrates the fix works)

import ../../union_type
import std/unittest

# ==================== Test Types with Custom Equality ====================

# Simple variant object with custom ==
type
  NodeKind = enum nkInt, nkString, nkBool
  Node = object
    case kind: NodeKind
    of nkInt: intVal: int
    of nkString: strVal: string
    of nkBool: boolVal: bool

# Custom equality operator (this makes union work)
proc `==`(a, b: Node): bool =
  if a.kind != b.kind:
    return false
  case a.kind:
  of nkInt: a.intVal == b.intVal
  of nkString: a.strVal == b.strVal
  of nkBool: a.boolVal == b.boolVal

# Union with variant object - works because == is defined
type NodeUnion = union(Node, int, string)

# Complex variant with multiple fields
type
  ExprKind = enum ekLit, ekBin, ekUn
  Expr = object
    case kind: ExprKind
    of ekLit: litVal: int
    of ekBin:
      left: int
      right: int
      op: char
    of ekUn: operand: int

proc `==`(a, b: Expr): bool =
  if a.kind != b.kind:
    return false
  case a.kind:
  of ekLit: a.litVal == b.litVal
  of ekBin: a.left == b.left and a.right == b.right and a.op == b.op
  of ekUn: a.operand == b.operand

type ExprUnion = union(Expr, string)

# ==================== Tests ====================

suite "Union with Variant Objects - Solution (Custom ==)":

  test "union with variant object compiles when == is defined":
    # This test passing proves the solution works
    let n1 = Node(kind: nkInt, intVal: 42)
    let u1 = NodeUnion.init(n1)
    check u1.holds(Node)

  test "equality works with custom == operator":
    let n1 = Node(kind: nkInt, intVal: 42)
    let n2 = Node(kind: nkInt, intVal: 42)

    let u1 = NodeUnion.init(n1)
    let u2 = NodeUnion.init(n2)

    # Same values should be equal
    check u1 == u2

  test "equality distinguishes different values":
    let n1 = Node(kind: nkInt, intVal: 42)
    let n2 = Node(kind: nkInt, intVal: 99)

    let u1 = NodeUnion.init(n1)
    let u2 = NodeUnion.init(n2)

    # Different values should not be equal
    check u1 != u2

  test "equality distinguishes different variants":
    let n1 = Node(kind: nkInt, intVal: 42)
    let n2 = Node(kind: nkString, strVal: "test")

    let u1 = NodeUnion.init(n1)
    let u2 = NodeUnion.init(n2)

    # Different discriminators should not be equal
    check u1 != u2

  test "complex variant with multiple fields":
    let e1 = Expr(kind: ekBin, left: 10, right: 20, op: '+')
    let e2 = Expr(kind: ekBin, left: 10, right: 20, op: '+')

    let u1 = ExprUnion.init(e1)
    let u2 = ExprUnion.init(e2)

    # Same complex values should be equal
    check u1 == u2

  test "string representation works":
    let n = Node(kind: nkString, strVal: "test")
    let u = NodeUnion.init(n)

    let str = $u
    check str.len > 0  # Should have some representation

  test "pattern matching works with variant objects":
    let n = Node(kind: nkBool, boolVal: true)
    let u = NodeUnion.init(n)

    # This demonstrates full integration
    check u.holds(Node)
    let extracted = u.get(Node)
    check extracted.kind == nkBool
    check extracted.boolVal == true

## Summary:
## This test proves that providing custom == operators for variant objects
## allows them to work perfectly in unions. The fix will guide users to
## implement these operators correctly.
