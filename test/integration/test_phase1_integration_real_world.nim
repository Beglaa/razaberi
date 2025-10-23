## Phase 1 Integration Tests - Real-World Scenarios
## Tests realistic use cases and data structures

import unittest
import tables
import options
import strutils
import ../../pattern_matching

suite "Phase 1 Integration - Real-World Scenarios":

  test "JSON-like data structure":
    type
      JsonKind = enum jNull, jBool, jInt, jString, jArray, jObject
      JsonNode = object
        case kind: JsonKind
        of jNull: discard
        of jBool: boolVal: bool
        of jInt: intVal: int
        of jString: strVal: string
        of jArray: arrayVal: seq[JsonNode]
        of jObject: objectVal: Table[string, JsonNode]

    let data = JsonNode(kind: jObject, objectVal: {
      "name": JsonNode(kind: jString, strVal: "Alice"),
      "age": JsonNode(kind: jInt, intVal: 30)
    }.toTable)

    let result = match data:
      JsonNode(kind: jObject, objectVal: {
        "name": JsonNode(kind: jString, strVal: n),
        "age": JsonNode(kind: jInt, intVal: a)
      }): n & ":" & $a
      _: "invalid"

    check result == "Alice:30"

  test "HTTP Request representation":
    type
      HttpMethod = enum GET, POST, PUT, DELETE
      HttpRequest = object
        meth: HttpMethod
        path: string
        headers: Table[string, string]
        body: Option[string]

    let req = HttpRequest(
      meth: POST,
      path: "/api/users",
      headers: {"Content-Type": "application/json", "Authorization": "Bearer token123"}.toTable,
      body: some("""{"name":"Alice"}""")
    )

    let result = match req:
      HttpRequest(meth: POST, path: p, headers: {"Content-Type": ct, "Authorization": auth}, body: Some(b)):
        "POST " & p & " " & ct & " " & b
      _: "invalid"

    check "POST /api/users" in result
    check "application/json" in result
    check """{"name":"Alice"}""" in result

  test "Configuration data structure":
    type
      LogLevel = enum Debug, Info, Warning, Error
      DatabaseConfig = object
        host: string
        port: int
        username: string
      ServerConfig = object
        port: int
        logLevel: LogLevel
        database: DatabaseConfig

    let config = ServerConfig(
      port: 8080,
      logLevel: Info,
      database: DatabaseConfig(
        host: "localhost",
        port: 5432,
        username: "admin"
      )
    )

    let result = match config:
      ServerConfig(
        port: p,
        logLevel: Info,
        database: DatabaseConfig(host: h, port: dbPort, username: u)
      ): "Server:" & $p & " DB:" & h & ":" & $dbPort & " User:" & u
      _: "invalid"

    check result == "Server:8080 DB:localhost:5432 User:admin"

  test "AST-like tree structure":
    type
      NodeKind = enum nkLiteral, nkBinary, nkUnary
      Node = ref object
        case kind: NodeKind
        of nkLiteral: value: int
        of nkBinary:
          left: Node
          op: string
          right: Node
        of nkUnary:
          unaryOp: string
          operand: Node

    let tree = Node(kind: nkBinary,
      left: Node(kind: nkLiteral, value: 10),
      op: "+",
      right: Node(kind: nkLiteral, value: 20)
    )

    let result = match tree:
      Node(kind: nkBinary,
           left: Node(kind: nkLiteral, value: a),
           op: "+",
           right: Node(kind: nkLiteral, value: b)): $a & "+" & $b
      _: "invalid"

    check result == "10+20"

  test "Event processing system":
    type
      EventKind = enum ekClick, ekKeyPress, ekScroll
      Event = object
        timestamp: int
        case kind: EventKind
        of ekClick:
          x, y: int
          button: string
        of ekKeyPress:
          key: char
          modifiers: seq[string]
        of ekScroll:
          deltaX, deltaY: int

    let e1 = Event(kind: ekClick, timestamp: 1000, x: 100, y: 200, button: "left")
    let e2 = Event(kind: ekKeyPress, timestamp: 2000, key: 'A', modifiers: @["ctrl", "shift"])
    let e3 = Event(kind: ekScroll, timestamp: 3000, deltaX: 10, deltaY: -5)

    let r1 = match e1:
      Event(kind: ekClick, timestamp: t, x: x, y: y, button: b):
        "Click@" & $t & ":" & $x & "," & $y & ":" & b
      _: "other"

    let r2 = match e2:
      Event(kind: ekKeyPress, timestamp: t, key: k, modifiers: [m1, m2]):
        "Key@" & $t & ":" & $k & ":" & m1 & "+" & m2
      _: "other"

    let r3 = match e3:
      Event(kind: ekScroll, timestamp: t, deltaX: dx, deltaY: dy):
        "Scroll@" & $t & ":" & $dx & "," & $dy
      _: "other"

    check r1 == "Click@1000:100,200:left"
    check r2 == "Key@2000:A:ctrl+shift"
    check r3 == "Scroll@3000:10,-5"

  test "Database query result":
    type
      User = object
        id: int
        name: string
        email: string
        age: int
      QueryResult = object
        success: bool
        data: seq[User]
        error: Option[string]

    let result1 = QueryResult(
      success: true,
      data: @[
        User(id: 1, name: "Alice", email: "alice@example.com", age: 30),
        User(id: 2, name: "Bob", email: "bob@example.com", age: 25)
      ],
      error: none(string)
    )

    let r1 = match result1:
      QueryResult(success: true, data: [User(name: n1, age: a1), User(name: n2, age: a2)], error: None()):
        n1 & ":" & $a1 & "|" & n2 & ":" & $a2
      _: "error"

    check r1 == "Alice:30|Bob:25"

  test "Compiler error representation":
    type
      ErrorLevel = enum elWarning, elError, elFatal
      SourceLocation = object
        file: string
        line: int
        column: int
      CompilerError = object
        level: ErrorLevel
        message: string
        location: SourceLocation
        suggestions: seq[string]

    let err = CompilerError(
      level: elError,
      message: "undefined variable",
      location: SourceLocation(file: "main.nim", line: 42, column: 10),
      suggestions: @["Did you mean 'myVar'?", "Check spelling"]
    )

    let result = match err:
      CompilerError(
        level: elError,
        message: msg,
        location: SourceLocation(file: f, line: l, column: c),
        suggestions: [s1, s2]
      ): "Error at " & f & ":" & $l & ":" & $c & " - " & msg & " (" & s1 & ")"
      _: "other"

    check result == "Error at main.nim:42:10 - undefined variable (Did you mean 'myVar'?)"

  test "State machine representation":
    type
      State = enum sIdle, sRunning, sPaused, sStopped
      Transition = object
        fromState: State
        toState: State
        event: string
      StateMachine = object
        currentState: State
        transitions: seq[Transition]

    let sm = StateMachine(
      currentState: sRunning,
      transitions: @[
        Transition(fromState: sIdle, toState: sRunning, event: "start"),
        Transition(fromState: sRunning, toState: sPaused, event: "pause")
      ]
    )

    let result = match sm:
      StateMachine(
        currentState: sRunning,
        transitions: [
          Transition(fromState: sIdle, toState: sRunning, event: e1),
          Transition(fromState: sRunning, toState: sPaused, event: e2)
        ]
      ): "Running: " & e1 & "->" & e2
      _: "other"

    check result == "Running: start->pause"

  test "Nested configuration with validation":
    type
      SecurityConfig = object
        enabled: bool
        level: int
      CacheConfig = object
        ttl: int
        maxSize: int
      AppConfig = object
        name: string
        version: (int, int, int)
        security: SecurityConfig
        cache: CacheConfig

    let config = AppConfig(
      name: "MyApp",
      version: (1, 2, 3),
      security: SecurityConfig(enabled: true, level: 5),
      cache: CacheConfig(ttl: 3600, maxSize: 1024)
    )

    # Explicit version: Guard applied to the whole pattern after extraction
    let result = match config:
      AppConfig(
        name: n,
        version: (major, minor, patch),
        security: SecurityConfig(enabled: e, level: l),
        cache: CacheConfig(ttl: t, maxSize: m)
      ) and e == true and l >= 5: n & " v" & $major & "." & $minor & "." & $patch & " (secure:" & $l & ")"
      _: "invalid config"

    check result == "MyApp v1.2.3 (secure:5)"

  test "Message queue item":
    type
      Priority = enum pLow, pNormal, pHigh, pUrgent
      Message = object
        id: string
        priority: Priority
        payload: Table[string, string]
        retryCount: int

    let msg = Message(
      id: "msg-123",
      priority: pHigh,
      payload: {"type": "notification", "user": "alice"}.toTable,
      retryCount: 0
    )

    let result = match msg:
      Message(
        id: msgId,
        priority: pHigh,
        payload: {"type": msgType, "user": username},
        retryCount: 0
      ): "High priority " & msgType & " for " & username & " (" & msgId & ")"
      _: "other"

    check result == "High priority notification for alice (msg-123)"