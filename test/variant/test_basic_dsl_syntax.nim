import unittest
import macros

# Import the production variant DSL module
import ../../variant_dsl

suite "Basic DSL Syntax Tests":

  test "single field constructor generation":
    # Test that basic single-parameter constructor works
    variant SimpleNode:
      IntValue(value: int)

    # Test generated type exists
    check compiles(SimpleNode)
    check compiles(SimpleNodeKind)

    # Test constructor exists and works (UFCS syntax)
    let node = SimpleNode.IntValue(42)
    check node.kind == skIntValue
    check node.value == 42

    # Test generated code structure
    check compiles(node.kind)
    check node is SimpleNode

  test "zero field constructor generation":
    # Test constructors with no parameters
    variant StatusNode:
      Empty()
      Ready()

    let empty = StatusNode.Empty()
    let ready = StatusNode.Ready()

    check empty.kind == skEmpty
    check ready.kind == skReady
    check empty is StatusNode
    check ready is StatusNode

  test "multi field constructor generation":
    # Note: Current implementation supports single-parameter only
    # This test is disabled until multi-parameter support is added
    when true:  # Multi-parameter support not yet implemented
      variant BinaryNode:
        Add(left: int, right: int)
        Concat(str1: string, str2: string)

      let add = BinaryNode.Add(10, 20)
      let concat = BinaryNode.Concat("hello", "world")

      check add.kind == bkAdd
      check add.left == 10
      check add.right == 20

      check concat.kind == bkConcat
      check concat.str1 == "hello"
      check concat.str2 == "world"

  test "mixed constructor types":
    # Test variant with mix of zero and single-parameter constructors
    variant MixedNode:
      Empty()                              # Zero parameters
      Value(data: string)                  # Single parameter
      Number(count: int)                   # Single parameter different type

    let empty = MixedNode.Empty()
    let value = MixedNode.Value("test")
    let number = MixedNode.Number(42)

    # Test zero parameter constructor
    check empty.kind == mkEmpty
    check empty is MixedNode

    # Test single parameter constructors
    check value.kind == mkValue
    check value.data == "test"

    check number.kind == mkNumber
    check number.count == 42

  test "constructor proc signatures":
    # Test that generated constructor procs have correct signatures
    when true:  # Will enable when macro is implemented
      variant TestNode:
        IntNode(value: int)
        StringNode(text: string)

      # Test proc signatures exist and are callable
      check compiles(TestNode.IntNode(42))
      check compiles(TestNode.StringNode("test"))

      # Test return types
      let intNode = TestNode.IntNode(42)
      let strNode = TestNode.StringNode("test")

      check intNode is TestNode
      check strNode is TestNode

      # Test these are actual procs, not just object constructors
      check compiles(IntNode)    # Proc symbol should exist
      check compiles(StringNode) # Proc symbol should exist


  test "generated object structure":
    # Test that generated case objects have proper structure
    when true:  # Will enable when macro is implemented
      variant StructureTest:
        IntCase(value: int)
        StringCase(text: string)

      let intCase = StructureTest.IntCase(42)
      let stringCase = StructureTest.StringCase("test")

      # Test field access works
      check intCase.value == 42
      check stringCase.text == "test"

  test "type safety validation":
    # Test that type safety is enforced
    when true:  # Will enable when macro is implemented
      variant TypeSafetyTest:
        IntValue(value: int)
        StringValue(text: string)

      # Test correct types compile
      check compiles(TypeSafetyTest.IntValue(42))
      check compiles(TypeSafetyTest.StringValue("test"))

      # Test incorrect types don't compile
      check not compiles(TypeSafetyTest.IntValue("string"))      # Wrong type for int parameter
      check not compiles(TypeSafetyTest.StringValue(42))         # Wrong type for string parameter
      check not compiles(TypeSafetyTest.IntValue())              # Missing required parameter
      check not compiles(TypeSafetyTest.StringValue())          # Missing required parameter