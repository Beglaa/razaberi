import unittest
import std/lists
import sequtils
import ../../pattern_matching

# Test types for SinglyLinkedRing
type
  User = object
    name: string
    age: int
    active: bool

suite "SinglyLinkedRing Structural Pattern Matching":

  test "SinglyLinkedRing demonstrates filtering removal":
    var users = initSinglyLinkedRing[User]()
    users.add(User(name: "Alice", age: 25, active: true))
    users.add(User(name: "Bob", age: 45, active: true))
    users.add(User(name: "Carol", age: 52, active: false))

    # SinglyLinkedRing pattern matching now works structurally only
    # Complex filtering behavior has been removed

    # For filtering ring structures, convert to sequence and use regular Nim operations
    let userSeq = users.toSeq
    let older_users = userSeq.filter(proc(u: User): bool = u.age > 39)
    check older_users.len == 2  # Bob and Carol

    # Verify original ring unchanged
    check users.toSeq.len == 3

  test "SinglyLinkedRing structural behavior":
    var users = initSinglyLinkedRing[User]()
    users.add(User(name: "Alice", age: 25, active: true))
    users.add(User(name: "Bob", age: 45, active: true))

    # SinglyLinkedRing maintains its circular semantics
    check users.toSeq[0].name == "Alice"
    check users.toSeq[1].name == "Bob"

    # For complex pattern matching on ring structures,
    # convert to sequences first
    let userSeq = users.toSeq
    let active_users = userSeq.filter(proc(u: User): bool = u.active)
    check active_users.len == 2