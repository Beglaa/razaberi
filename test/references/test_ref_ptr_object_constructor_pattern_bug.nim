import unittest
import ../../pattern_matching

{.push warning[UnusedImport]: off.}
{.push hint[XDeclaredButNotUsed]: off.}

# ============================================================================
# RUST-LIKE AUTO-DEREFERENCING: Ref/Ptr Object Constructor Patterns
# ============================================================================
#
# PATTERN MATCHING CAPABILITIES (According to spec in rewrite/ref_ptr_research.md):
# This library supports automatic dereferencing for ref/ptr types:
#
# 1️⃣ **AUTOMATIC DEREFERENCING** (Content Matching):
#    match someRef:
#      TestObj(value: 42): "matches by content"           # ✅ Auto-dereferences!
#      TestObj(name: n): "binds field value"              # ✅ Variable binding
#      TestObj(field: pattern): "nested patterns"         # ✅ Deep destructuring
#
# 2️⃣ **NIL PATTERN SUPPORT**:
#    match someRef:
#      nil: "nil reference"                              # ✅ Nil check
#      User(role: "Admin"): "admin by content"           # ✅ Content match
#
# 3️⃣ **VARIABLE BINDING**:
#    match someRef:
#      x:                                                 # ✅ Binds the ref/ptr itself
#        echo "Got reference: ", x.repr
#
# 🦀 **RUST-LIKE MATCH ERGONOMICS**:
# Just like Rust, ref/ptr types are transparent for pattern matching.
# Users write patterns the same way regardless of T, ref T, or ptr T.
#
# 🎯 **REAL-WORLD USAGE**:
# ```nim
# let dbUser: ref User = getUserFromDatabase()
# match dbUser:
#   nil: "user not found"                              # Nil check
#   User(active: false): "inactive user"               # Content: auto-deref
#   User(role: r, name: n): "user " & n                # Content: destructuring
# ```
#
# **TECHNICAL IMPLEMENTATION**:
# - Automatic dereferencing: Transparent `ref T` → `T` for object patterns
# - Nil-safe dereferencing: Automatic nil checks before dereferencing
# - Intelligent field access: Auto `scrutinee[].field` for ref/ptr types
# - Zero runtime overhead: All resolved at compile-time

suite "Ref/Ptr Pattern Matching: Auto-Dereferencing (Per Specification)":

  test "BUG: Pointer object constructor pattern fails while direct object works":
    type TestObj = object
      value: int
      name: string
    
    # Create identical data in different forms
    var directObj = TestObj(value: 42, name: "test")
    var heapObj = TestObj(value: 42, name: "test")  
    let objPtr: ptr TestObj = addr(heapObj)
    
    # Direct object pattern - should work (control test)
    let directResult = match directObj:
      TestObj(value: 42, name: "test"): "direct match"
      TestObj(value: 42): "direct partial match"
      _: "direct no match"
    
    # Pointer object pattern - should work but currently fails
    let ptrResult = match objPtr:
      nil: "nil pointer"
      TestObj(value: 42, name: "test"): "ptr exact match"
      TestObj(value: 42): "ptr partial match" 
      _: "ptr no match"
    
    # This test documents the bug - direct works, pointer fails
    check directResult == "direct match"
    check ptrResult == "ptr exact match"

  test "BUG: Reference object constructor pattern fails while direct object works":
    type TestObj = object
      value: int
      name: string
    
    # Create identical data in different forms  
    var directObj = TestObj(value: 100, name: "hello")
    let objRef = new TestObj
    objRef.value = 100
    objRef.name = "hello"
    
    # Direct object pattern - should work (control test)
    let directResult = match directObj:
      TestObj(value: 100, name: "hello"): "direct match"
      TestObj(value: 100): "direct partial match"
      _: "direct no match"
    
    # Reference object pattern - should work but currently fails  
    let refResult = match objRef:
      nil: "nil reference"
      TestObj(value: 100, name: "hello"): "ref exact match"
      TestObj(value: 100): "ref partial match"
      _: "ref no match"
    
    # This test documents the bug - direct works, reference fails
    check directResult == "direct match"
    check refResult == "ref exact match"

  test "BUG: Variable binding in ref/ptr object patterns fails":
    type TestObj = object
      value: int
      name: string
    
    var obj = TestObj(value: 200, name: "binding")
    let objPtr: ptr TestObj = addr(obj)
    let objRef = new TestObj
    objRef.value = 200  
    objRef.name = "binding"
    
    # Test variable binding with direct object (control)
    var directValue: int = -1
    var directName: string = ""
    let directResult = match obj:
      TestObj(value: v, name: n): 
        directValue = v
        directName = n
        "direct bound"
      _: "direct unbound"
    
    # Test variable binding with pointer (should work but likely fails)
    var ptrValue: int = -1
    var ptrName: string = ""
    let ptrResult = match objPtr:
      nil: "nil ptr"
      TestObj(value: v, name: n):
        ptrValue = v
        ptrName = n
        "ptr bound" 
      _: "ptr unbound"
    
    # Test variable binding with reference (should work but likely fails)
    var refValue: int = -1
    var refName: string = ""
    let refResult = match objRef:
      nil: "nil ref"
      TestObj(value: v, name: n):
        refValue = v
        refName = n
        "ref bound"
      _: "ref unbound"
    
    # Verify control test works
    check directResult == "direct bound"
    check directValue == 200
    check directName == "binding"
    
    # Document the bug - variable binding should work for ref/ptr
    check ptrResult == "ptr bound"
    if ptrResult == "ptr bound":
      check ptrValue == 200
      check ptrName == "binding"

    check refResult == "ref bound"
    if refResult == "ref bound":
      check refValue == 200
      check refName == "binding"

  test "BUG: Nested ref/ptr object patterns fail":
    type
      Inner = object
        x: int
      Outer = object  
        inner: Inner
        value: int
    
    var directOuter = Outer(inner: Inner(x: 50), value: 25)
    var heapOuter = Outer(inner: Inner(x: 50), value: 25)
    let outerPtr: ptr Outer = addr(heapOuter)
    let outerRef = new Outer
    outerRef.inner = Inner(x: 50)
    outerRef.value = 25
    
    # Direct nested pattern (control)
    let directResult = match directOuter:
      Outer(inner: Inner(x: 50), value: 25): "direct nested match"
      _: "direct nested no match"
    
    # Pointer nested pattern (should work but likely fails)
    let ptrResult = match outerPtr:
      nil: "nil ptr"
      Outer(inner: Inner(x: 50), value: 25): "ptr nested match"
      _: "ptr nested no match"
    
    # Reference nested pattern (should work but likely fails)  
    let refResult = match outerRef:
      nil: "nil ref"
      Outer(inner: Inner(x: 50), value: 25): "ref nested match"
      _: "ref nested no match"
    
    check directResult == "direct nested match"
    check ptrResult == "ptr nested match"
    check refResult == "ref nested match"

  test "SPECIFICATION COMPLIANT: Auto-Dereferencing and Pattern Matching":
    # This test follows the specification in rewrite/ref_ptr_research.md
    # Testing: automatic dereferencing, nil patterns, variable binding, wildcards

    type User = object
      name: string
      role: string
      active: bool

    # Create test data
    var user1 = User(name: "Alice", role: "Admin", active: true)
    var user2 = User(name: "Bob", role: "User", active: false)

    let adminRef: ref User = new User
    adminRef[] = user1

    let userRef: ref User = new User
    userRef[] = user2

    let nilRef: ref User = nil

    # Test 1: Automatic dereferencing for content matching
    let contentResult1 = match adminRef:
      nil: "nil user"
      User(role: "Admin", active: true): "admin user by content"   # ✅ Auto-dereferences!
      User(role: "User"): "regular user by content"
      _: "unknown user content"
    check contentResult1 == "admin user by content"

    let contentResult2 = match userRef:
      nil: "nil user"
      User(active: false, name: name): "inactive user: " & name   # ✅ Variable binding in fields!
      User(role: "Admin"): "admin by content"
      _: "other user content"
    check contentResult2 == "inactive user: Bob"

    # Test 2: nil pattern matching
    let nilResult = match nilRef:
      nil: "reference is nil"
      User(name: n): "user named: " & n
      _: "unknown"
    check nilResult == "reference is nil"

    # Test 3: Variable binding (binds the ref itself)
    var boundRef: ref User
    let bindResult = match adminRef:
      nil:
        boundRef = nil
        "was nil"
      x:
        boundRef = x  # Binds the whole ref
        "bound reference"
    check bindResult == "bound reference"
    check boundRef == adminRef
    check boundRef[].name == "Alice"

    # Test 4: Wildcard pattern
    let wildcardResult = match userRef:
      nil: "nil"
      User(role: "Admin"): "admin"
      _: "anything else"  # Matches any non-nil, non-admin
    check wildcardResult == "anything else"

    # Test 5: Multiple ref types in single match expression
    let multiResult = match adminRef:
      nil: "no user found"
      User(role: "User"): "regular user by content"
      User(role: "Admin", name: n): "admin by content: " & n  # ✅ Content matching with binding
      _: "no match"
    check multiResult == "admin by content: Alice"

    # Test 6: Deep pattern matching through ref
    type
      Address = object
        city: string
      Person = object
        name: string
        address: Address

    let personRef = new Person
    personRef[] = Person(name: "Charlie", address: Address(city: "NYC"))

    let deepResult = match personRef:
      nil: "nil person"
      Person(name: n, address: Address(city: "NYC")): n & " from NYC"
      Person(name: n): n & " from somewhere else"
      _: "unknown"
    check deepResult == "Charlie from NYC"