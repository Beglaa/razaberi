## Union Type Foundation Tests
## Tests for core union type generation, validation, and metadata integration
## Following TDD approach - tests written before implementation

import unittest
import options

# Import union type module
import ../../union_type

# Define union types at module level (outside test blocks)
# This is required because Nim macros with export markers don't work inside template scopes
type Result_Foundation = union(int, string)
type Response_Foundation = union(int, string)
type Value_Foundation = union(int, float, string)
type Data_Foundation = union(int, seq[int], Option[string])

suite "Union Type Foundation":

  test "each declaration creates unique type":
    # Nominal typing - same members, different types
    # Using module-level types

    # Should not compile - different types!
    check not compiles (
      var r: Result_Foundation
      var s: Response_Foundation
      r = s
    )

  test "same type name variables are compatible":
    # Using module-level type
    let r1 = Result_Foundation.init(42)
    let r2 = Result_Foundation.init("hello")

    var x = r1
    x = r2  # Should compile - both are Result_Foundation
    check true

  test "empty union causes compile error":
    check not compiles (
      type Empty = union()
    )

  test "single-type union causes compile error":
    check not compiles (
      type Single = union(int)
    )

  test "duplicate types cause compile error":
    check not compiles (
      type Dup = union(int, string, int)
    )

  test "valid two-type union compiles":
    # Already defined at module level
    check compiles (
      let r = Result_Foundation.init(42)
    )

  test "valid three-type union compiles":
    # Already defined at module level
    check compiles (
      let v = Value_Foundation.init(42)
    )

  test "generic types in union compile":
    # Already defined at module level
    check compiles (
      let d = Data_Foundation.init(42)
    )

suite "Union Type Metadata Integration":
  # Note: Metadata tests will be done in SUBTASK 03 when testing pattern matching
  # The analyzeConstructMetadata proc works at macro compile-time, not runtime

  test "union types work with variant object semantics":
    # Verify the generated union has proper variant object structure
    let r = Result_Foundation.init(42)

    # Discriminator field is accessible
    check r.kind is enum

    # Can construct with different types
    let r2 = Result_Foundation.init("hello")
    check r2.kind is enum

    # Different values have different discriminators
    check r.kind != r2.kind

suite "Union Type AST Generation":

  test "enum type generated with correct kind":
    let r = Result_Foundation.init(42)

    # Discriminator should be accessible
    check r.kind is enum

  test "variant object structure is correct":
    # Should be able to construct with discriminator
    check compiles (
      let r = Result_Foundation.init(42)
      discard r.kind
    )
