import unittest
import macros

# Import the production variant DSL module
import ../../variant_dsl

suite "Complex Real-World Examples Tests":

  test "compiler AST representation":
    # Test comprehensive compiler AST using variant DSL
    # Token types for lexer
    variant Token:
      IntToken(intValue: int, intLine: int, intColumn: int)
      StringToken(stringValue: string, stringLine: int, stringColumn: int)
      IdentToken(identName: string, identLine: int, identColumn: int)
      OpToken(operator: string, opLine: int, opColumn: int)
      KeywordToken(keyword: string, keywordLine: int, keywordColumn: int)

    # Type system representation
    variant Type:
      IntType()
      StringType()
      BoolType()
      ArrayType(elementType: ref Type, size: int)
      FuncType(paramTypes: seq[Type], returnType: ref Type)
      CustomType(customName: string)

    # Expression AST
    variant Expr:
      LiteralExpr(token: Token)
      VarExpr(varName: string, varExprType: Type)
      BinaryExpr(binaryOperator: string, left: ref Expr, right: ref Expr, binaryExprType: Type)
      CallExpr(callee: ref Expr, args: seq[Expr], callExprType: Type)
      AssignExpr(target: string, assignValue: ref Expr)

    # Statement AST
    variant Stmt:
      ExprStmt(expression: Expr)
      VarDecl(declName: string, varType: Type, initializer: Expr)
      BlockStmt(statements: seq[Stmt])
      IfStmt(ifCondition: Expr, thenBranch: ref Stmt, elseBranch: ref Stmt)
      WhileStmt(whileCondition: Expr, body: ref Stmt)
      ReturnStmt(returnValue: Expr)

    # Test complex AST construction
    let intToken = Token.IntToken(42, 1, 10)
    let literalExpr = Expr.LiteralExpr(intToken)
    let varDecl = Stmt.VarDecl("x", Type.IntType(), literalExpr)

    # Verify complex structure
    check varDecl.kind == skVarDecl
    check varDecl.declName == "x"
    check varDecl.varType.kind == tkIntType
    check varDecl.initializer.kind == ekLiteralExpr
    check varDecl.initializer.token.kind == tkIntToken
    check varDecl.initializer.token.intValue == 42

  test "HTTP server framework":
    # Test complete HTTP server framework representation
    # HTTP method types
    variant HttpMethod:
      GET()
      POST()
      PUT()
      DELETE()
      PATCH()
      HEAD()
      OPTIONS()

    # Request body types
    variant RequestBody:
      EmptyBody()
      JsonBody(jsonData: string)
      FormBody(fields: seq[(string, string)])
      TextBody(content: string)
      BinaryBody(binaryData: seq[byte])

    # HTTP headers
    variant HeaderValue:
      StringHeader(stringValue: string)
      IntHeader(intValue: int)
      ListHeader(values: seq[string])

    # HTTP request (simplified for current implementation)
    variant HttpRequest:
      GetRequest(getPath: string)
      PostRequest(postBody: string)
      PutRequest(putData: string)

    # Response status
    variant HttpStatus:
      Ok()
      Created(location: string)
      BadRequest(message: string)
      Unauthorized(realm: string)
      NotFound(resource: string)
      InternalServerError(error: string)

    # Response body
    variant ResponseBody:
      JsonResponse(responseData: string, contentType: string)
      HtmlResponse(html: string)
      TextResponse(text: string)
      BinaryResponse(binaryResponseData: seq[byte], mimeType: string)
      RedirectResponse(url: string)

    # HTTP response
    variant HttpResponse:
      Response(
        status: HttpStatus,
        headers: seq[(string, HeaderValue)],
        responseBody: ResponseBody
      )

    # Test complex HTTP scenario
    let jsonBody = RequestBody.JsonBody("""{"username": "admin", "password": "secret"}""")
    let getRequest = HttpRequest.GetRequest("/api/login")

    let successResponse = HttpResponse.Response(
      HttpStatus.Ok(),
      @[("Content-Type", HeaderValue.StringHeader("application/json"))],
      ResponseBody.JsonResponse("""{"token": "abc123", "expires": 3600}""", "application/json")
    )

    # Verify complex HTTP structure
    check getRequest.kind == hkGetRequest
    check successResponse.status.kind == hkOk

  test "game engine entity-component system":
    # Test comprehensive game engine ECS using variants
    # Vector types
    variant Vector:
      Vector2D(x2: float, y2: float)
      Vector3D(x3: float, y3: float, z3: float)

    # Transform components
    variant Transform:
      AbsoluteTransform(absPosition: Vector, absRotation: float, absScale: Vector)
      RelativeTransform(parent: int, offset: Vector, relRotation: float, relScale: Vector)

    # Rendering components
    variant Renderer:
      SpriteRenderer(texturePath: string, layer: int, flipX: bool, flipY: bool)
      MeshRenderer(modelPath: string, materialPath: string, castShadows: bool)
      ParticleRenderer(particleCount: int, emissionRate: float, lifetime: float)
      UIRenderer(element: string, zIndex: int)

    # Physics components
    variant Physics:
      StaticBody(staticMass: float)
      DynamicBody(dynamicMass: float, velocity: Vector, acceleration: Vector)
      KinematicBody(kinematicVelocity: Vector)
      Trigger(bounds: Vector, triggerEvents: seq[string])

    # AI components
    variant AI:
      StateMachine(currentState: string, states: seq[(string, string)])
      BehaviorTree(rootNode: string, variables: seq[(string, int)])
      PathFinding(target: Vector, path: seq[Vector], speed: float)

    # Component union
    variant Component:
      TransformComponent(transform: Transform)
      RendererComponent(renderer: Renderer)
      PhysicsComponent(physics: Physics)
      AIComponent(ai: AI)
      ScriptComponent(scriptPath: string, scriptVariables: seq[(string, string)])

    # Entity types
    variant Entity:
      Player(
        playerId: int,
        playerName: string,
        health: int,
        playerComponents: seq[Component]
      )
      NPC(
        npcId: int,
        npcType: string,
        dialogues: seq[string],
        npcComponents: seq[Component]
      )
      Item(
        itemId: int,
        itemType: string,
        stackable: bool,
        itemComponent: Component
      )
      Environment(
        envId: int,
        environmentType: string,
        isStatic: bool,
        envComponents: seq[Component]
      )

    # Test complex game entity
    let playerTransform = Transform.AbsoluteTransform(
      Vector.Vector3D(100.0, 50.0, 0.0),
      0.0,
      Vector.Vector3D(1.0, 1.0, 1.0)
    )

    let playerRenderer = Renderer.SpriteRenderer("player_idle.png", 1, false, false)
    let playerPhysics = Physics.DynamicBody(
      75.0,
      Vector.Vector3D(0.0, 0.0, 0.0),
      Vector.Vector3D(0.0, -9.81, 0.0)
    )

    let player = Entity.Player(
      1,
      "Hero",
      100,
      @[
        Component.TransformComponent(playerTransform),
        Component.RendererComponent(playerRenderer),
        Component.PhysicsComponent(playerPhysics)
      ]
    )

    # Verify complex game structure
    check player.kind == ekPlayer
    check player.playerName == "Hero"
    check player.playerComponents.len == 3
    check player.playerComponents[0].transform.absPosition.x3 == 100.0

  test "JSON/XML document structure":
    # Test document parsing and representation
    # JSON value types
    variant JsonValue:
      JsonNull()
      JsonBool(boolValue: bool)
      JsonNumber(numberValue: float)
      JsonString(stringValue: string)
      JsonArray(items: seq[JsonValue])
      JsonObject(fields: seq[(string, JsonValue)])

    # XML attribute
    variant XmlAttribute:
      StringAttr(attrName: string, attrValue: string)
      BoolAttr(boolAttrName: string, boolAttrValue: bool)
      NumberAttr(numberAttrName: string, numberAttrValue: float)

    # XML node types
    variant XmlNode:
      TextNode(content: string)
      ElementNode(
        tagName: string,
        attributes: seq[XmlAttribute],
        children: seq[XmlNode]
      )
      CommentNode(comment: string)
      CDATANode(cdataData: string)

    # Document types
    variant Document:
      JsonDocument(jsonRoot: JsonValue, jsonEncoding: string)
      XmlDocument(xmlRoot: XmlNode, version: string, xmlEncoding: string)
      HtmlDocument(
        doctype: string,
        head: XmlNode,
        htmlBody: XmlNode,
        htmlEncoding: string
      )

    # Test complex JSON document
    let jsonUser = JsonValue.JsonObject(@[
      ("id", JsonValue.JsonNumber(1.0)),
      ("name", JsonValue.JsonString("Alice")),
      ("active", JsonValue.JsonBool(true)),
      ("scores", JsonValue.JsonArray(@[JsonValue.JsonNumber(85.0), JsonValue.JsonNumber(92.0), JsonValue.JsonNumber(78.0)]))
    ])

    let jsonDoc = Document.JsonDocument(jsonUser, "UTF-8")

    # Test complex XML document
    let xmlElement = XmlNode.ElementNode(
      "user",
      @[XmlAttribute.StringAttr("id", "1"), XmlAttribute.BoolAttr("active", true)],
      @[
        XmlNode.ElementNode("name", @[], @[XmlNode.TextNode("Alice")]),
        XmlNode.ElementNode("email", @[], @[XmlNode.TextNode("alice@example.com")])
      ]
    )

    let xmlDoc = Document.XmlDocument(xmlElement, "1.0", "UTF-8")

    # Verify document structures
    check jsonDoc.kind == dkJsonDocument
    check jsonDoc.jsonRoot.kind == jkJsonObject
    check xmlDoc.kind == dkXmlDocument
    check xmlDoc.xmlRoot.tagName == "user"

  test "database query builder":
    # Test SQL query builder using variants
    # SQL data types
    variant SqlType:
      IntegerType()
      StringType(maxLength: int)
      FloatType(precision: int)
      BooleanType()
      DateType()
      TimestampType()

    # SQL expressions
    variant SqlExpr:
      ColumnRef(tableName: string, columnName: string)
      Literal(literalValue: string, sqlType: SqlType)
      BinaryOp(sqlOperator: string, sqlLeft: ref SqlExpr, sqlRight: ref SqlExpr)
      FunctionCall(funcName: string, funcArgs: seq[SqlExpr])

    # WHERE conditions
    variant WhereCondition:
      Comparison(compOperator: string, compLeft: SqlExpr, compRight: SqlExpr)
      LogicalOp(logicalOperator: string, conditions: seq[WhereCondition])
      InCondition(inColumn: SqlExpr, inValues: seq[SqlExpr])
      LikeCondition(likeColumn: SqlExpr, pattern: string)
      IsNull(nullColumn: SqlExpr)

    # JOIN types
    variant JoinType:
      InnerJoin(innerTable: string, innerCondition: WhereCondition)
      LeftJoin(leftTable: string, leftCondition: WhereCondition)
      RightJoin(rightTable: string, rightCondition: WhereCondition)
      FullJoin(fullTable: string, fullCondition: WhereCondition)

    # SQL queries
    variant SqlQuery:
      SelectQuery(
        selectColumns: seq[SqlExpr],
        fromTable: string,
        joins: seq[JoinType],
        selectWhereClause: WhereCondition,
        groupBy: seq[SqlExpr],
        having: WhereCondition,
        orderBy: seq[(SqlExpr, string)],
        selectLimit: int
      )
      InsertQuery(
        insertTable: string,
        insertColumns: seq[string],
        insertValues: seq[seq[SqlExpr]]
      )
      UpdateQuery(
        updateTable: string,
        assignments: seq[(string, SqlExpr)],
        updateWhereClause: WhereCondition
      )
      DeleteQuery(
        deleteTable: string,
        deleteWhereClause: WhereCondition
      )

    # Test complex query construction
    let userNameCol = SqlExpr.ColumnRef("users", "name")
    let userAgeCol = SqlExpr.ColumnRef("users", "age")
    let ageLimit = SqlExpr.Literal("25", SqlType.IntegerType())

    let whereCondition = WhereCondition.Comparison(">=", userAgeCol, ageLimit)

    let selectQuery = SqlQuery.SelectQuery(
      @[userNameCol, userAgeCol],
      "users",
      @[],
      whereCondition,
      @[],
      whereCondition,  # Empty having clause
      @[(userNameCol, "ASC")],
      10
    )

    # Verify query structure
    check selectQuery.kind == skSelectQuery
    check selectQuery.fromTable == "users"
    check selectQuery.selectColumns.len == 2
    check selectQuery.selectLimit == 10

  test "configuration management system":
    # Test configuration and settings management
    # Configuration value types
    variant ConfigValue:
      StringConfig(stringConfigValue: string, stringRequired: bool)
      IntConfig(intConfigValue: int, intMin: int, intMax: int, intRequired: bool)
      FloatConfig(floatConfigValue: float, floatMin: float, floatMax: float, floatRequired: bool)
      BoolConfig(boolConfigValue: bool, boolRequired: bool)
      ArrayConfig(arrayValues: seq[ConfigValue], arrayRequired: bool)
      ObjectConfig(objectFields: seq[(string, ConfigValue)], objectRequired: bool)

    # Environment-specific configurations
    variant Environment:
      Development(
        devDebugMode: bool,
        devLogLevel: string,
        hotReload: bool
      )
      Staging(
        stagingDebugMode: bool,
        stagingLogLevel: string,
        testData: bool
      )
      Production(
        prodDebugMode: bool,
        prodLogLevel: string,
        monitoring: bool,
        caching: bool
      )

    # Configuration sections
    variant ConfigSection:
      DatabaseConfig(
        dbHost: string,
        dbPort: int,
        dbName: string,
        credentials: seq[(string, string)]
      )
      ServerConfig(
        serverPort: int,
        serverHost: string,
        ssl: bool,
        maxConnections: int
      )
      LoggingConfig(
        logLevel: string,
        logFormat: string,
        outputs: seq[string]
      )
      FeatureFlags(
        flags: seq[(string, bool)]
      )

    # Application configuration
    variant AppConfig:
      Config(
        environment: Environment,
        sections: seq[ConfigSection],
        version: string,
        lastModified: string
      )

    # Test complex configuration
    let dbConfig = ConfigSection.DatabaseConfig(
      "localhost",
      5432,
      "myapp_db",
      @[("username", "admin"), ("password", "secret")]
    )

    let serverConfig = ConfigSection.ServerConfig(8080, "0.0.0.0", true, 1000)
    let prodEnv = Environment.Production(false, "INFO", true, true)

    let appConfig = AppConfig.Config(
      prodEnv,
      @[dbConfig, serverConfig],
      "1.0.0",
      "2024-01-15T10:30:00Z"
    )

    # Verify configuration structure
    check appConfig.kind == akConfig
    check appConfig.version == "1.0.0"
    check appConfig.environment.kind == ekProduction
    check appConfig.sections.len == 2
