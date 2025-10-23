## Comprehensive Negative Tests for ref/ptr Pattern Errors
##
## This test suite validates that the pattern matching library correctly
## rejects invalid patterns for ref and ptr types at compile time.
##
## All tests in this file use the shouldNotCompile template to verify that
## invalid pattern combinations produce compile-time errors with helpful messages.
##
## Categories tested:
## 1. Wrong underlying type patterns - Object patterns on ref int/string
## 2. Type mismatches through ref - Sequence pattern on ref object
## 3. Type mismatches through ptr - Tuple pattern on ptr object
## 4. Nested ref errors - ref ref Type patterns
## 5. ref/ptr with wrong collection patterns
## 6. ref/ptr with wrong object field access
## 7. Mixed ref/ptr type confusions
## 8. ref/ptr Option with wrong inner type patterns
## 9. ref/ptr with variant object field access violations
## 10. Edge cases: nil patterns, deep nesting, complex generics

import unittest
import tables
import sets
import options
import ../../pattern_matching

suite "Negative Tests: ref/ptr Pattern Errors":

  # Template for compile-time validation
  template shouldNotCompile(code: untyped): bool =
    not compiles(code)

  # ============================================================================
  # Category 1: Wrong Underlying Type Patterns (Object patterns on primitives)
  # ============================================================================

  test "object pattern on ref int should not compile":
    # WHY: int is a primitive type, not an object with fields
    # Pattern validation should detect that Point(x, y) requires object type
    check shouldNotCompile (
      block:
        var x: ref int
        new(x)
        x[] = 42
        match x:
          Point(a, b): a + b  # Error: int doesn't have fields x, y
          _: 0
    )

  test "object pattern on ref string should not compile":
    # WHY: string is a primitive type without named fields
    # Even though strings are sequences of chars, they don't support object patterns
    check shouldNotCompile (
      block:
        var s: ref string
        new(s)
        s[] = "hello"
        match s:
          Person(name, age): name  # Error: string is not an object
          _: ""
    )

  test "object pattern on ref float should not compile":
    # WHY: float is a simple numeric type without structure
    # Object constructor patterns require structured types
    check shouldNotCompile (
      block:
        var f: ref float
        new(f)
        f[] = 3.14
        match f:
          Point(x, y): x  # Error: float has no fields
          _: 0.0
    )

  test "nested object pattern on ref int should not compile":
    # WHY: Deep object patterns require nested object structure
    # ref int is just a reference to a primitive
    check shouldNotCompile (
      block:
        var n: ref int
        new(n)
        n[] = 100
        match n:
          Outer(inner=Inner(value=v)): v  # Error: int is not structured
          _: 0
    )

  # ============================================================================
  # Category 2: Type Mismatches Through ref (Collection patterns on objects)
  # ============================================================================

  test "sequence pattern on ref object should not compile":
    # WHY: Objects have named fields, sequences have indexed elements
    # Pattern [a, b, c] expects seq-like type, not object
    check shouldNotCompile (
      block:
        type Point = object
          x, y: int
        var p: ref Point
        new(p)
        p[] = Point(x: 10, y: 20)
        match p:
          [a, b]: a + b  # Error: Point is not a sequence
          _: 0
    )

  test "sequence pattern with spread on ref object should not compile":
    # WHY: Spread operators (*middle) only work with collection types
    # Objects cannot be destructured as sequences
    check shouldNotCompile (
      block:
        type Person = object
          name: string
          age: int
          city: string
        var person: ref Person
        new(person)
        person[] = Person(name: "Alice", age: 30, city: "NYC")
        match person:
          [first, *rest]: first  # Error: Person is not a sequence
          _: ""
    )

  test "table pattern on ref object should not compile":
    # WHY: Object field access uses dot notation, not key-value lookup
    # Dictionary patterns require Table/mapping types
    check shouldNotCompile (
      block:
        type Config = object
          port: int
          host: string
        var cfg: ref Config
        new(cfg)
        cfg[] = Config(port: 8080, host: "localhost")
        match cfg:
          {"port": p, "host": h}: p  # Error: Config is not a Table
          _: 0
    )

  test "set pattern on ref object should not compile":
    # WHY: Objects are structured types, sets contain unordered elements
    # Set patterns require set[T] or HashSet[T]
    check shouldNotCompile (
      block:
        type Status = object
          active: bool
          code: int
        var status: ref Status
        new(status)
        status[] = Status(active: true, code: 200)
        match status:
          {true, 200}: 1  # Error: Status is not a set
          _: 0
    )

  # ============================================================================
  # Category 3: Type Mismatches Through ptr (Tuple patterns on objects)
  # ============================================================================

  test "tuple pattern on ptr object should not compile":
    # WHY: ptr preserves underlying type structure
    # ptr Point is still an object, not a tuple
    check shouldNotCompile (
      block:
        type Point = object
          x, y: int
        var p: ptr Point = cast[ptr Point](alloc0(sizeof(Point)))
        p.x = 5
        p.y = 10
        match p:
          (a, b): a + b  # Error: Point has named fields, not positional
          _: 0
    )

  test "nested tuple pattern on ptr object should not compile":
    # WHY: Deep tuple destructuring requires tuple types at all levels
    # Objects cannot be treated as tuples even through ptr
    check shouldNotCompile (
      block:
        type
          Inner = object
            value: int
          Outer = object
            inner: Inner
        var outer: ptr Outer = cast[ptr Outer](alloc0(sizeof(Outer)))
        outer.inner.value = 42
        match outer:
          ((v,),): v  # Error: Outer is not a nested tuple
          _: 0
    )

  test "sequence pattern on ptr object should not compile":
    # WHY: ptr doesn't change the underlying type category
    # ptr object is still an object, not a sequence
    check shouldNotCompile (
      block:
        type Record = object
          id: int
          name: string
        var rec: ptr Record = cast[ptr Record](alloc0(sizeof(Record)))
        rec.id = 1
        rec.name = "test"
        match rec:
          [id, name]: id  # Error: Record is not a sequence
          _: 0
    )

  # ============================================================================
  # Category 4: Nested ref Errors (ref ref Type patterns)
  # ============================================================================

  test "double ref with wrong pattern should not compile":
    # WHY: ref ref int is still ultimately wrapping an int
    # Object patterns require structured types at the core
    check shouldNotCompile (
      block:
        var x: ref ref int
        new(x)
        new(x[])
        x[][] = 42
        match x:
          Point(a, b): a + b  # Error: int doesn't have fields
          _: 0
    )

  test "ref ref object with sequence pattern should not compile":
    # WHY: Even through double indirection, object structure is preserved
    # Sequence patterns are still invalid
    check shouldNotCompile (
      block:
        type Point = object
          x, y: int
        var p: ref ref Point
        new(p)
        new(p[])
        p[][].x = 10
        p[][].y = 20
        match p:
          [a, b]: a + b  # Error: Point is not a sequence
          _: 0
    )

  test "mixed ref ptr with wrong pattern should not compile":
    # WHY: ref and ptr can be mixed, but underlying type matters
    # Object patterns on primitive types fail at any indirection level
    check shouldNotCompile (
      block:
        var x: ref int
        new(x)
        x[] = 100
        var p: ptr (ref int) = addr x
        match p:
          Container(value=v): v  # Error: ref int doesn't have 'value' field
          _: 0
    )

  # ============================================================================
  # Category 5: ref/ptr with Wrong Collection Patterns
  # ============================================================================

  test "ref seq with object pattern should not compile":
    # WHY: ref seq[T] is a sequence, not an object
    # Object constructor patterns don't apply to sequences
    check shouldNotCompile (
      block:
        var s: ref seq[int]
        new(s)
        s[] = @[1, 2, 3]
        match s:
          Point(x, y): x + y  # Error: seq[int] is not Point
          _: 0
    )

  test "ptr array with table pattern should not compile":
    # WHY: Arrays are indexed collections, not key-value mappings
    # Table patterns require Table[K, V] types
    check shouldNotCompile (
      block:
        type IntArray = array[3, int]
        var arr: ptr IntArray = cast[ptr IntArray](alloc0(sizeof(IntArray)))
        arr[0] = 1
        arr[1] = 2
        arr[2] = 3
        match arr:
          {"a": x, "b": y}: x + y  # Error: array is not a Table
          _: 0
    )

  test "ref Table with sequence pattern should not compile":
    # WHY: Tables are key-value mappings, not indexed sequences
    # Sequence patterns expect ordinal indexing
    check shouldNotCompile (
      block:
        var t: ref Table[string, int]
        new(t)
        t[] = {"a": 1, "b": 2}.toTable
        match t:
          [first, second]: first  # Error: Table is not a sequence
          _: 0
    )

  test "ptr set with sequence pattern should not compile":
    # WHY: Sets are unordered collections, sequences are ordered
    # Pattern [a, b, c] implies ordering that sets don't have
    check shouldNotCompile (
      block:
        var s: ptr HashSet[int] = cast[ptr HashSet[int]](alloc0(sizeof(HashSet[int])))
        match s:
          [a, b, c]: a + b + c  # Error: set is not a sequence
          _: 0
    )

  # ============================================================================
  # Category 6: ref/ptr with Wrong Object Field Access
  # ============================================================================

  test "ref object with nonexistent field should not compile":
    # WHY: Pattern validation should catch typos and wrong field names
    # Point has x, y but pattern asks for z
    check shouldNotCompile (
      block:
        type Point = object
          x, y: int
        var p: ref Point
        new(p)
        p[] = Point(x: 10, y: 20)
        match p:
          Point(z=zval): zval  # Error: Point has no field 'z'
          _: 0
    )

  test "ref object with field type mismatch should not compile":
    # WHY: Nested patterns must match field types structurally
    # If field is int, can't use object pattern on it
    check shouldNotCompile (
      block:
        type Container = object
          value: int
          name: string
        var c: ref Container
        new(c)
        c[] = Container(value: 42, name: "test")
        match c:
          Container(value=Point(x, y)): x + y  # Error: value is int, not Point
          _: 0
    )

  test "ptr object with multiple nonexistent fields should not compile":
    # WHY: All fields in pattern must exist in type
    # Should report all missing fields in error message
    check shouldNotCompile (
      block:
        type Person = object
          name: string
          age: int
        var p: ptr Person = cast[ptr Person](alloc0(sizeof(Person)))
        p.name = "Alice"
        p.age = 30
        match p:
          Person(name=n, age=a, city=c, country=co): n  # Error: city, country don't exist
          _: ""
    )

  test "ref nested object with wrong inner field should not compile":
    # WHY: Deep field validation should work through ref indirection
    # Inner object structure must match pattern
    check shouldNotCompile (
      block:
        type
          Inner = object
            value: int
          Outer = object
            inner: Inner
            count: int
        var outer: ref Outer
        new(outer)
        outer[] = Outer(inner: Inner(value: 42), count: 10)
        match outer:
          Outer(inner=Inner(wrong=w)): w  # Error: Inner has 'value', not 'wrong'
          _: 0
    )

  # ============================================================================
  # Category 7: Mixed ref/ptr Type Confusions
  # ============================================================================

  test "ref int with ref object pattern should not compile":
    # WHY: Can't pattern match ref int as if it were ref object
    # Type compatibility checks must see through ref wrapper
    check shouldNotCompile (
      block:
        var x: ref int
        new(x)
        x[] = 42
        match x:
          Point(x=a, y=b): a + b  # Error: ref int is not ref Point
          _: 0
    )

  test "ptr string with ptr object pattern should not compile":
    # WHY: string is not an object type
    # ptr doesn't make string into a structured type
    check shouldNotCompile (
      block:
        var s: ptr string = cast[ptr string](alloc0(sizeof(string)))
        s[] = "test"
        match s:
          Config(host, port): host  # Error: string is not Config
          _: ""
    )

  test "ref seq with ref Table pattern should not compile":
    # WHY: seq and Table are different collection categories
    # ref doesn't change the underlying collection type
    check shouldNotCompile (
      block:
        var s: ref seq[int]
        new(s)
        s[] = @[1, 2, 3]
        match s:
          {"key": value}: value  # Error: seq is not Table
          _: 0
    )

  # ============================================================================
  # Category 8: ref/ptr Option with Wrong Inner Type Patterns
  # ============================================================================

  test "ref Option[int] with object pattern should not compile":
    # WHY: Option[int] wraps int, not an object
    # Some(Point(x, y)) would require Option[Point]
    check shouldNotCompile (
      block:
        var opt: ref Option[int]
        new(opt)
        opt[] = some(42)
        match opt:
          Some(Point(x, y)): x + y  # Error: inner type is int, not Point
          _: 0
    )

  test "ptr Option[string] with sequence pattern should not compile":
    # WHY: Option[string] contains string, not a sequence
    # Some([a, b, c]) would require Option[seq[T]]
    check shouldNotCompile (
      block:
        var opt: ptr Option[string] = cast[ptr Option[string]](alloc0(sizeof(Option[string])))
        opt[] = some("hello")
        match opt:
          Some([a, b, c]): a  # Error: inner type is string, not seq
          _: ""
    )

  test "ref Option[Point] with wrong field access should not compile":
    # WHY: Even through ref and Option, field names must match
    # Point has x, y but pattern asks for z
    check shouldNotCompile (
      block:
        type Point = object
          x, y: int
        var opt: ref Option[Point]
        new(opt)
        opt[] = some(Point(x: 10, y: 20))
        match opt:
          Some(Point(z=zval)): zval  # Error: Point has no field 'z'
          _: 0
    )

  # ============================================================================
  # Category 9: ref/ptr with Variant Object Field Access Violations
  # ============================================================================

  test "ref variant object with wrong branch field should not compile":
    # WHY: Variant object fields are branch-specific
    # Can't access strVal when kind is vkInt
    check shouldNotCompile (
      block:
        type
          ValueKind = enum
            vkInt, vkStr
          Value = object
            case kind: ValueKind
            of vkInt:
              intVal: int
            of vkStr:
              strVal: string
        var v: ref Value
        new(v)
        v[] = Value(kind: vkInt, intVal: 42)
        match v:
          Value(kind=vkInt, strVal=s): s  # Error: strVal not in vkInt branch
          _: ""
    )

  test "ptr variant object with nonexistent branch field should not compile":
    # WHY: All fields must exist in their respective branches
    # Pattern validation should check discriminator-field compatibility
    check shouldNotCompile (
      block:
        type
          NodeKind = enum
            nkLeaf, nkBranch
          Node = object
            case kind: NodeKind
            of nkLeaf:
              value: int
            of nkBranch:
              left, right: int
        var n: ptr Node = cast[ptr Node](alloc0(sizeof(Node)))
        n.kind = nkLeaf
        n.value = 42
        match n:
          Node(kind=nkLeaf, left=l): l  # Error: left not in nkLeaf branch
          _: 0
    )

  # ============================================================================
  # Category 10: Edge Cases
  # ============================================================================

  test "deeply nested ref with wrong leaf type should not compile":
    # WHY: Pattern validation must work through arbitrary nesting
    # Leaf type mismatch should be caught even at depth 5+
    check shouldNotCompile (
      block:
        type
          L1 = object
            l2: ref L2
          L2 = object
            l3: ref L3
          L3 = object
            value: int
        var root: ref L1
        new(root)
        new(root.l2)
        new(root.l2.l3)
        root.l2.l3.value = 42
        match root:
          L1(l2=L2(l3=L3(value=Point(x, y)))): x + y  # Error: value is int, not Point
          _: 0
    )

  test "ref generic type with wrong parameter pattern should not compile":
    # WHY: Generic type parameters must match at all levels
    # ref seq[int] cannot match seq[string] patterns
    check shouldNotCompile (
      block:
        var s: ref seq[int]
        new(s)
        s[] = @[1, 2, 3]
        match s:
          [a, b] and [str1, str2]: str1.len + str2.len  # Error: elements are int, not string
          _: 0
    )

  test "ptr union type with wrong branch should not compile":
    # WHY: Union types are variant objects under the hood
    # Wrong branch patterns should be caught
    # Note: This test requires union_type.nim support
    check shouldNotCompile (
      block:
        # Simplified union simulation using variant object
        type
          UnionKind = enum
            ukInt, ukStr
          Union = object
            case kind: UnionKind
            of ukInt:
              intVal: int
            of ukStr:
              strVal: string
        var u: ptr Union = cast[ptr Union](alloc0(sizeof(Union)))
        u.kind = ukInt
        u.intVal = 42
        match u:
          Union(kind=ukInt, strVal=s): s  # Error: strVal not in ukInt branch
          _: ""
    )

  test "ref with cycle should not compile with wrong pattern":
    # WHY: Circular references don't change type structure
    # Pattern must still match the actual type
    check shouldNotCompile (
      block:
        type Node = ref object
          value: int
          next: Node
        var n: Node
        new(n)
        n.value = 42
        n.next = n  # Circular reference
        match n:
          [x, y, z]: x + y + z  # Error: Node is object, not sequence
          _: 0
    )

  test "ptr to ref with multiple indirection errors should not compile":
    # WHY: Validation must work through complex indirection chains
    # Type mismatches should be caught regardless of wrapper depth
    check shouldNotCompile (
      block:
        var x: ref int
        new(x)
        x[] = 42
        var p: ptr (ref int) = addr x
        var pp: ptr (ptr (ref int)) = addr p
        match pp:
          Container(Point(x, y)): x + y  # Error: multiple type mismatches
          _: 0
    )

  test "ref object with sequence field and wrong destructuring should not compile":
    # WHY: Field patterns must match field types exactly
    # If field is seq[int], can't use object pattern
    check shouldNotCompile (
      block:
        type Container = object
          items: seq[int]
          name: string
        var c: ref Container
        new(c)
        c[] = Container(items: @[1, 2, 3], name: "test")
        match c:
          Container(items=Point(x, y)): x + y  # Error: items is seq, not Point
          _: 0
    )
