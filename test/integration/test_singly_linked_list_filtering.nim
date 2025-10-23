import unittest
import std/lists
import sequtils
import ../../pattern_matching

# Test types for SinglyLinkedList
type
  User = object
    name: string
    age: int
    active: bool

suite "SinglyLinkedList Structural Pattern Matching":

  test "SinglyLinkedList demonstrates filtering removal":
    var users = initSinglyLinkedList[User]()
    users.add(User(name: "Alice", age: 25, active: true))
    users.add(User(name: "Bob", age: 45, active: true))
    users.add(User(name: "Carol", age: 52, active: false))

    # SinglyLinkedList pattern matching now works structurally only
    # Complex filtering behavior has been removed

    # For filtering lists, convert to sequence and use regular Nim operations
    let userSeq = users.toSeq
    let older_users = userSeq.filter(proc(u: User): bool = u.age > 39)
    check older_users.len == 2  # Bob and Carol

    # Verify original list unchanged
    check users.toSeq.len == 3

  test "SinglyLinkedList structural behavior":
    var users = initSinglyLinkedList[User]()
    users.add(User(name: "Alice", age: 25, active: true))
    users.add(User(name: "Bob", age: 45, active: true))

    # SinglyLinkedList maintains its own semantics
    check users.toSeq[0].name == "Alice"
    check users.toSeq[1].name == "Bob"

    # For complex pattern matching on linked structures,
    # convert to sequences first
    let userSeq = users.toSeq
    let active_users = userSeq.filter(proc(u: User): bool = u.active)
    check active_users.len == 2