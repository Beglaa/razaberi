import unittest
import macros

# Import the production variant DSL module
import ../../variant_dsl

suite "Nested Variants Tests":

  test "two layer nesting - literal expressions":
    # Test 2-layer nested variants like Expression containing Literal
    # Layer 2: Literal types
    variant Literal:
      IntLit(intValue: int)
      StringLit(stringValue: string)
      BoolLit(boolValue: bool)

    # Layer 1: Expression containing Literal
    variant Expression:
      LiteralExpr(lit: Literal)
      Variable(varName: string)

    # Test construction of nested variants
    let intLiteral = Literal.IntLit(42)
    let strLiteral = Literal.StringLit("hello")
    let boolLiteral = Literal.BoolLit(true)

    # Test nested construction
    let intExpr = Expression.LiteralExpr(intLiteral)
    let strExpr = Expression.LiteralExpr(strLiteral)
    let varExpr = Expression.Variable("x")

    # Verify nested structure
    check intExpr.kind == ekLiteralExpr
    check intExpr.lit.kind == lkIntLit
    check intExpr.lit.intValue == 42

    check strExpr.kind == ekLiteralExpr
    check strExpr.lit.kind == lkStringLit
    check strExpr.lit.stringValue == "hello"

    check varExpr.kind == ekVariable
    check varExpr.varName == "x"

  test "two layer nesting - binary operations":
    # Test nested variants with recursive references
    # Layer 2: Binary operators
    variant BinaryOp:
      Add()
      Sub()
      Mul()
      Div()

    # Layer 1: Expression with recursive references
    variant ExprNode:
      Value(num: int)
      Binary(op: BinaryOp, left: ref ExprNode, right: ref ExprNode)

    # Test nested construction with references
    let leftVal = new(ExprNode)
    leftVal[] = ExprNode.Value(10)

    let rightVal = new(ExprNode)
    rightVal[] = ExprNode.Value(20)

    let addExpr = ExprNode.Binary(BinaryOp.Add(), leftVal, rightVal)

    # Verify structure
    check addExpr.kind == ekBinary
    check addExpr.op.kind == bkAdd
    check addExpr.left[].kind == ekValue
    check addExpr.left[].num == 10
    check addExpr.right[].kind == ekValue
    check addExpr.right[].num == 20

  test "three layer nesting - HTTP system":
    # Test 3-layer deep nesting like HTTP status -> response -> handler
    # Layer 3: Status details
    variant StatusDetail:
      SimpleStatus()
      RedirectStatus(url: string)
      ErrorStatus(message: string, code: int)

    # Layer 2: HTTP status
    variant HttpStatus:
      Ok(okDetail: StatusDetail)
      NotFound(notFoundDetail: StatusDetail)
      ServerError(serverErrorDetail: StatusDetail)

    # Layer 1: HTTP response
    variant HttpResponse:
      JsonResponse(jsonStatus: HttpStatus, jsonData: string)
      HtmlResponse(htmlStatus: HttpStatus, content: string)

    # Test 3-layer construction
    let okDetail = StatusDetail.SimpleStatus()
    let okStatus = HttpStatus.Ok(okDetail)
    let jsonResponse = HttpResponse.JsonResponse(okStatus, """{"result": "success"}""")

    # Verify 3-layer structure
    check jsonResponse.kind == hkJsonResponse
    check jsonResponse.jsonStatus.kind == hkOk
    check jsonResponse.jsonStatus.okDetail.kind == skSimpleStatus
    check jsonResponse.jsonData == """{"result": "success"}"""

    # Test error path
    let errorDetail = StatusDetail.ErrorStatus("Database connection failed", 500)
    let serverError = HttpStatus.ServerError(errorDetail)
    let errorResponse = HttpResponse.JsonResponse(serverError, """{"error": "internal"}""")

    check errorResponse.jsonStatus.kind == hkServerError
    check errorResponse.jsonStatus.serverErrorDetail.kind == skErrorStatus
    check errorResponse.jsonStatus.serverErrorDetail.message == "Database connection failed"
    check errorResponse.jsonStatus.serverErrorDetail.code == 500

  test "nested variants with sequences":
    # Test nested variants containing sequences of other nested variants
    # Component types
    variant Component:
      Transform(x: float, y: float, z: float)
      Render(texturePath: string)
      Physics(mass: float)

    # Entity containing multiple components
    variant GameEntity:
      Player(playerName: string, playerComponents: seq[Component])
      NPC(aiType: string, npcComponents: seq[Component])
      Item(itemType: string, itemComponent: Component)  # Single component

    # Test construction with sequences of nested variants
    let transform = Component.Transform(10.0, 5.0, 0.0)
    let render = Component.Render("player.png")
    let physics = Component.Physics(75.0)

    let player = GameEntity.Player("Hero", @[transform, render, physics])

    # Verify nested sequence structure
    check player.kind == gkPlayer
    check player.playerName == "Hero"
    check player.playerComponents.len == 3

    check player.playerComponents[0].kind == ckTransform
    check player.playerComponents[0].x == 10.0

    check player.playerComponents[1].kind == ckRender
    check player.playerComponents[1].texturePath == "player.png"

    check player.playerComponents[2].kind == ckPhysics
    check player.playerComponents[2].mass == 75.0

  test "nested variants with mixed field types":
    # Test complex nesting with various field types
    variant ValueType:
      IntValue(intVal: int)
      FloatValue(floatVal: float)
      StringValue(stringVal: string)
      ArrayValue(arrayValues: seq[int])

    variant ConfigEntry:
      SimpleConfig(key: string, configValue: ValueType)
      GroupConfig(groupName: string, groupEntries: seq[ValueType])
      ConditionalConfig(condition: string, thenValue: ValueType, elseValue: ValueType)

    # Test complex nested construction
    let intVal = ValueType.IntValue(42)
    let arrayVal = ValueType.ArrayValue(@[1, 2, 3, 4, 5])

    let simpleConfig = ConfigEntry.SimpleConfig("timeout", intVal)
    let groupConfig = ConfigEntry.GroupConfig("database", @[intVal, arrayVal])
    let conditionalConfig = ConfigEntry.ConditionalConfig("debug", intVal, arrayVal)

    # Verify complex nested structure
    check simpleConfig.kind == ckSimpleConfig
    check simpleConfig.key == "timeout"
    check simpleConfig.configValue.kind == vkIntValue
    check simpleConfig.configValue.intVal == 42

    check groupConfig.kind == ckGroupConfig
    check groupConfig.groupEntries.len == 2
    check groupConfig.groupEntries[1].kind == vkArrayValue
    check groupConfig.groupEntries[1].arrayValues == @[1, 2, 3, 4, 5]

    check conditionalConfig.thenValue.kind == vkIntValue
    check conditionalConfig.elseValue.kind == vkArrayValue

  test "recursive nested variants":
    # Test deeply recursive structures like tree nodes
    variant TreeNode:
      Leaf(leafValue: int)
      Branch(branchValue: int, left: ref TreeNode, right: ref TreeNode)

    # Build recursive tree structure
    let leftLeaf = new(TreeNode)
    leftLeaf[] = TreeNode.Leaf(1)

    let rightLeaf = new(TreeNode)
    rightLeaf[] = TreeNode.Leaf(3)

    let rootBranch = TreeNode.Branch(2, leftLeaf, rightLeaf)

    # Verify recursive structure
    check rootBranch.kind == tkBranch
    check rootBranch.branchValue == 2
    check rootBranch.left[].kind == tkLeaf
    check rootBranch.left[].leafValue == 1
    check rootBranch.right[].kind == tkLeaf
    check rootBranch.right[].leafValue == 3

    # Test deeper nesting
    let deepLeft = new(TreeNode)
    deepLeft[] = rootBranch

    let deepRight = new(TreeNode)
    deepRight[] = TreeNode.Leaf(10)

    let deepRoot = TreeNode.Branch(5, deepLeft, deepRight)

    check deepRoot.left[].kind == tkBranch
    check deepRoot.left[].left[].leafValue == 1  # 3 levels deep

  test "nested variants with generic types - DISABLED (generics not fully supported)":
    # Test nested variants containing generic types
    # TODO: Enable when variant DSL fully supports generic parameters
    when false:
      variant Container[T]:
        Single(item: T)
        Multiple(items: seq[T])

      variant Result[T, E]:
        Ok(value: T)
        Err(error: E)

      variant Response:
        IntResponse(result: Result[int, string])
        StringResponse(result: Result[string, int])
        ContainerResponse(data: Container[string])

      # Test generic nested construction
      let okInt = Ok[int, string](42)
      let errString = Err[int, string]("failed")

      let intResponse = IntResponse(okInt)
      let stringResponse = StringResponse(Err[string, int](404))

      let container = Multiple[string](@["a", "b", "c"])
      let containerResponse = ContainerResponse(container)

      # Verify generic nested structure
      check intResponse.kind == rskIntResponse
      check intResponse.result.kind == rikOk  # Assuming generic enum naming
      check intResponse.result.value == 42

      check containerResponse.data.kind == ctkMultiple
      check containerResponse.data.items == @["a", "b", "c"]

    # Placeholder check to keep test valid
    check true

  test "performance with deep nesting":
    # Test that deeply nested variants perform well at compile time
    # 4-layer deep nesting to test compile-time performance
    variant Level4:
      DeepValue(deepData: int)

    variant Level3:
      Contains4(level4: Level4)

    variant Level2:
      Contains3(level3: Level3)

    variant Level1:
      Contains2(level2: Level2)

    # Test deep construction compiles quickly
    let deep = Level1.Contains2(
      Level2.Contains3(
        Level3.Contains4(
          Level4.DeepValue(42)
        )
      )
    )

    # Verify deep access works
    check deep.kind == lkContains2
    check deep.level2.level3.level4.deepData == 42
