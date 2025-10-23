import unittest
import std/options
import ../../variant_dsl
import ../../pattern_matching

##[
Variant Type Patterns Tests - Option[T] Integration
====================================================

Tests comprehensive Option[T] type pattern matching with variant objects.
This file verifies that Option types work correctly as variant fields,
including Some/None patterns, nested Options, and complex combinations.

Test Coverage:
- Basic Option[T] fields with Some/None patterns
- Nested Option types (Option[seq[T]], Option[Option[T]])
- Multiple Option fields in same variant branch
- Option patterns with guards
- Complex nested Option structures
- Option with OR patterns
- Exhaustiveness checking with Option fields
]##

suite "Variant Type Patterns - Option[T] Integration":

  test "basic Option[int] field - Some pattern":
    # Test basic Option field matching with Some pattern
    variant UserStatus:
      Active(userId: int, loginCount: Option[int])
      Inactive()

    let activeUser = UserStatus.Active(42, some(10))
    let activeNoCount = UserStatus.Active(42, none(int))

    # Pattern match with Some
    let result1 = match activeUser:
      UserStatus.Active(id, Some(count)): id + count
      UserStatus.Active(id, None()): id
      UserStatus.Inactive(): 0

    check result1 == 52  # 42 + 10

    # Pattern match with None
    let result2 = match activeNoCount:
      UserStatus.Active(id, Some(count)): id + count
      UserStatus.Active(id, None()): id
      UserStatus.Inactive(): 0

    check result2 == 42

  test "basic Option[string] field - None pattern":
    # Test None pattern matching with Option field
    variant Response:
      Success(code: int, message: Option[string])
      Error(errorCode: int)

    let successWithMsg = Response.Success(200, some("OK"))
    let successNoMsg = Response.Success(200, none(string))

    # Pattern match checking None explicitly
    let result1 = match successWithMsg:
      Response.Success(_, None()): "No message"
      Response.Success(c, Some(msg)): msg
      Response.Error(_): "Error"

    check result1 == "OK"

    let result2 = match successNoMsg:
      Response.Success(_, None()): "No message"
      Response.Success(c, Some(msg)): msg
      Response.Error(_): "Error"

    check result2 == "No message"

  test "multiple Option fields in same variant":
    # Test variant with multiple Option fields
    variant Config:
      Database(host: string, port: Option[int], ssl: Option[bool])
      Cache(size: int)

    let dbFull = Config.Database("localhost", some(5432), some(true))
    let dbPartial = Config.Database("localhost", some(5432), none(bool))
    let dbMinimal = Config.Database("localhost", none(int), none(bool))

    # Pattern match with all Some
    let result1 = match dbFull:
      Config.Database(h, Some(p), Some(s)): h & ":" & $p & " SSL:" & $s
      Config.Database(h, Some(p), None()): h & ":" & $p & " no SSL"
      Config.Database(h, None(), _): h & " default port"
      Config.Cache(s): "Cache size: " & $s

    check result1 == "localhost:5432 SSL:true"

    # Pattern match with partial Some
    let result2 = match dbPartial:
      Config.Database(h, Some(p), Some(s)): h & ":" & $p & " SSL:" & $s
      Config.Database(h, Some(p), None()): h & ":" & $p & " no SSL"
      Config.Database(h, None(), _): h & " default port"
      Config.Cache(s): "Cache size: " & $s

    check result2 == "localhost:5432 no SSL"

    # Pattern match with all None
    let result3 = match dbMinimal:
      Config.Database(h, Some(p), Some(s)): h & ":" & $p & " SSL:" & $s
      Config.Database(h, Some(p), None()): h & ":" & $p & " no SSL"
      Config.Database(h, None(), _): h & " default port"
      Config.Cache(s): "Cache size: " & $s

    check result3 == "localhost default port"

  test "nested Option types - Option[seq[int]]":
    # Test nested Option with sequence type
    variant DataPacket:
      WithData(id: int, values: Option[seq[int]])
      Empty()

    let packetWithData = DataPacket.WithData(1, some(@[10, 20, 30]))
    let packetNoData = DataPacket.WithData(2, none(seq[int]))

    # Pattern match nested Option[seq[int]]
    let result1 = match packetWithData:
      DataPacket.WithData(id, Some(vals)): id * vals.len
      DataPacket.WithData(id, None()): id
      DataPacket.Empty(): 0

    check result1 == 3  # 1 * 3

    let result2 = match packetNoData:
      DataPacket.WithData(id, Some(vals)): id * vals.len
      DataPacket.WithData(id, None()): id
      DataPacket.Empty(): 0

    check result2 == 2

  test "Option with guards - value comparison":
    # Test Option patterns combined with guard expressions
    variant Measurement:
      Temperature(tempValue: Option[int], unit: string)
      Pressure(pressureValue: float)

    let tempHigh = Measurement.Temperature(some(100), "C")
    let tempLow = Measurement.Temperature(some(10), "C")
    let tempNone = Measurement.Temperature(none(int), "C")

    # Guard on Option value
    let result1 = match tempHigh:
      Measurement.Temperature(Some(v), u) and v > 50: "Hot: " & $v & u
      Measurement.Temperature(Some(v), u): "Normal: " & $v & u
      Measurement.Temperature(None(), u): "No reading"
      Measurement.Pressure(p): "Pressure: " & $p

    check result1 == "Hot: 100C"

    let result2 = match tempLow:
      Measurement.Temperature(Some(v), u) and v > 50: "Hot: " & $v & u
      Measurement.Temperature(Some(v), u): "Normal: " & $v & u
      Measurement.Temperature(None(), u): "No reading"
      Measurement.Pressure(p): "Pressure: " & $p

    check result2 == "Normal: 10C"

    let result3 = match tempNone:
      Measurement.Temperature(Some(v), u) and v > 50: "Hot: " & $v & u
      Measurement.Temperature(Some(v), u): "Normal: " & $v & u
      Measurement.Temperature(None(), u): "No reading"
      Measurement.Pressure(p): "Pressure: " & $p

    check result3 == "No reading"

  test "Option with guards - range checking":
    # Test Option patterns with range guards
    variant Score:
      PlayerScore(name: string, points: Option[int])
      TeamScore(teamName: string, total: int)

    let highScore = Score.PlayerScore("Alice", some(95))
    let mediumScore = Score.PlayerScore("Bob", some(75))
    let lowScore = Score.PlayerScore("Charlie", some(45))
    let noScore = Score.PlayerScore("Dave", none(int))

    # Range guard on Option value
    let result1 = match highScore:
      Score.PlayerScore(n, Some(p)) and p >= 90: n & " - Excellent"
      Score.PlayerScore(n, Some(p)) and p >= 70: n & " - Good"
      Score.PlayerScore(n, Some(p)): n & " - Pass"
      Score.PlayerScore(n, None()): n & " - No score"
      Score.TeamScore(t, total): t

    check result1 == "Alice - Excellent"

    let result2 = match mediumScore:
      Score.PlayerScore(n, Some(p)) and p >= 90: n & " - Excellent"
      Score.PlayerScore(n, Some(p)) and p >= 70: n & " - Good"
      Score.PlayerScore(n, Some(p)): n & " - Pass"
      Score.PlayerScore(n, None()): n & " - No score"
      Score.TeamScore(t, total): t

    check result2 == "Bob - Good"

    let result3 = match lowScore:
      Score.PlayerScore(n, Some(p)) and p >= 90: n & " - Excellent"
      Score.PlayerScore(n, Some(p)) and p >= 70: n & " - Good"
      Score.PlayerScore(n, Some(p)): n & " - Pass"
      Score.PlayerScore(n, None()): n & " - No score"
      Score.TeamScore(t, total): t

    check result3 == "Charlie - Pass"

  test "complex nested Option structures":
    # Test deeply nested Option types in variants
    variant NestedData:
      Level1(id: int, level2: Option[seq[string]])
      Level2(name: string, level3: Option[Option[int]])

    let nested1 = NestedData.Level1(1, some(@["a", "b", "c"]))
    let nested2 = NestedData.Level1(2, none(seq[string]))
    let nested3 = NestedData.Level2("test", some(some(42)))
    let nested4 = NestedData.Level2("test", some(none(int)))
    let nested5 = NestedData.Level2("test", none(Option[int]))

    # Pattern match nested Option[seq[string]]
    let result1 = match nested1:
      NestedData.Level1(i, Some(items)): i + items.len
      NestedData.Level1(i, None()): i
      NestedData.Level2(n, _): n.len

    check result1 == 4  # 1 + 3

    let result2 = match nested2:
      NestedData.Level1(i, Some(items)): i + items.len
      NestedData.Level1(i, None()): i
      NestedData.Level2(n, _): n.len

    check result2 == 2

    # Pattern match nested Option[Option[int]]
    let result3 = match nested3:
      NestedData.Level1(i, _): i
      NestedData.Level2(n, Some(inner)):
        match inner:
          Some(v): v
          None(): 0
      NestedData.Level2(n, None()): -1

    check result3 == 42

    let result4 = match nested4:
      NestedData.Level1(i, _): i
      NestedData.Level2(n, Some(inner)):
        match inner:
          Some(v): v
          None(): 0
      NestedData.Level2(n, None()): -1

    check result4 == 0

    let result5 = match nested5:
      NestedData.Level1(i, _): i
      NestedData.Level2(n, Some(inner)):
        match inner:
          Some(v): v
          None(): 0
      NestedData.Level2(n, None()): -1

    check result5 == -1

  test "Option with OR patterns - Some | None":
    # Test OR patterns combining Some and None
    variant OptionalData:
      WithOption(optValue: Option[int])
      WithoutOption(reqValue: int)

    let withSome = OptionalData.WithOption(some(42))
    let withNone = OptionalData.WithOption(none(int))
    let without = OptionalData.WithoutOption(100)

    # OR pattern: Some | None (discriminator-only check)
    let result1 = match withSome:
      OptionalData.WithOption(Some(_) | None()): "Has optional data"
      OptionalData.WithoutOption(_): "Has required data"

    check result1 == "Has optional data"

    let result2 = match withNone:
      OptionalData.WithOption(Some(_) | None()): "Has optional data"
      OptionalData.WithoutOption(_): "Has required data"

    check result2 == "Has optional data"

  test "Option with wildcard patterns":
    # Test Option patterns with wildcards
    variant Event:
      UserEvent(userId: int, metadata: Option[string])
      SystemEvent(level: int)

    let userWithMeta = Event.UserEvent(1, some("login"))
    let userNoMeta = Event.UserEvent(2, none(string))

    # Wildcard in Some pattern
    let result1 = match userWithMeta:
      Event.UserEvent(id, Some(_)): "User " & $id & " has metadata"
      Event.UserEvent(id, None()): "User " & $id & " no metadata"
      Event.SystemEvent(_): "System event"

    check result1 == "User 1 has metadata"

    # Wildcard for entire Option field
    let result2 = match userNoMeta:
      Event.UserEvent(id, _): "User event: " & $id
      Event.SystemEvent(lvl): "System event: " & $lvl

    check result2 == "User event: 2"

  test "Option field exhaustiveness patterns":
    # Test exhaustive matching of Option fields
    variant Result:
      Success(value: int, details: Option[string])
      Failure(error: string)

    let success = Result.Success(200, some("All good"))
    let successNoDetails = Result.Success(200, none(string))

    # Exhaustive Option patterns - all cases covered
    let result1 = match success:
      Result.Success(v, Some(d)): "Success: " & $v & " - " & d
      Result.Success(v, None()): "Success: " & $v
      Result.Failure(e): "Failure: " & e

    check result1 == "Success: 200 - All good"

    let result2 = match successNoDetails:
      Result.Success(v, Some(d)): "Success: " & $v & " - " & d
      Result.Success(v, None()): "Success: " & $v
      Result.Failure(e): "Failure: " & e

    check result2 == "Success: 200"

  test "Option[bool] special case":
    # Test Option with boolean type
    variant Feature:
      Enabled(featureName: string, verified: Option[bool])
      Disabled(disabledName: string)

    let verifiedFeature = Feature.Enabled("auth", some(true))
    let unverifiedFeature = Feature.Enabled("beta", some(false))
    let unknownFeature = Feature.Enabled("experimental", none(bool))

    # Pattern match Option[bool]
    let result1 = match verifiedFeature:
      Feature.Enabled(n, Some(v)) and v: n & " verified"
      Feature.Enabled(n, Some(v)): n & " not verified"
      Feature.Enabled(n, None()): n & " unknown"
      Feature.Disabled(n): n & " disabled"

    check result1 == "auth verified"

    let result2 = match unverifiedFeature:
      Feature.Enabled(n, Some(v)) and v: n & " verified"
      Feature.Enabled(n, Some(v)): n & " not verified"
      Feature.Enabled(n, None()): n & " unknown"
      Feature.Disabled(n): n & " disabled"

    check result2 == "beta not verified"

    let result3 = match unknownFeature:
      Feature.Enabled(n, Some(v)) and v: n & " verified"
      Feature.Enabled(n, Some(v)): n & " not verified"
      Feature.Enabled(n, None()): n & " unknown"
      Feature.Disabled(n): n & " disabled"

    check result3 == "experimental unknown"

  test "Option with @ pattern binding":
    # Test Option patterns with @ binding
    variant Container:
      Full(capacity: int, current: Option[int])
      Empty()

    let fullContainer = Container.Full(100, some(75))
    let unknownContainer = Container.Full(100, none(int))

    # @ pattern with Option
    let result1 = match fullContainer:
      Container.Full(cap, Some(cur) @ level): cap - cur
      Container.Full(cap, None()): cap
      Container.Empty(): 0

    check result1 == 25  # 100 - 75

    # Entire Option bound to variable (simplified - direct pattern matching)
    let result2 = match fullContainer:
      Container.Full(cap, Some(cur)): cap - cur
      Container.Full(cap, None()): cap
      Container.Empty(): 0

    check result2 == 25

  test "Option field with variant nesting":
    # Test Option fields in nested variant structures
    variant Inner:
      Value(data: int)
      Empty()

    variant Outer:
      Container(content: Option[Inner])
      Placeholder()

    let withInner = Outer.Container(some(Inner.Value(42)))
    let withEmpty = Outer.Container(some(Inner.Empty()))
    let withNone = Outer.Container(none(Inner))

    # Pattern match nested variant in Option
    let result1 = match withInner:
      Outer.Container(Some(inner)):
        match inner:
          Inner.Value(d): d
          Inner.Empty(): 0
      Outer.Container(None()): -1
      Outer.Placeholder(): -2

    check result1 == 42

    let result2 = match withEmpty:
      Outer.Container(Some(inner)):
        match inner:
          Inner.Value(d): d
          Inner.Empty(): 0
      Outer.Container(None()): -1
      Outer.Placeholder(): -2

    check result2 == 0

    let result3 = match withNone:
      Outer.Container(Some(inner)):
        match inner:
          Inner.Value(d): d
          Inner.Empty(): 0
      Outer.Container(None()): -1
      Outer.Placeholder(): -2

    check result3 == -1

  test "Option[float] with precision guards":
    # Test Option with float type and precision-based guards
    variant Sensor:
      Reading(readingId: int, value: Option[float])
      Offline(offlineId: int)

    let highReading = Sensor.Reading(1, some(99.5))
    let lowReading = Sensor.Reading(2, some(10.2))
    let noReading = Sensor.Reading(3, none(float))

    # Guards on float Option values
    let result1 = match highReading:
      Sensor.Reading(i, Some(v)) and v > 50.0: "High: " & $v
      Sensor.Reading(i, Some(v)): "Low: " & $v
      Sensor.Reading(i, None()): "No data"
      Sensor.Offline(i): "Offline"

    check result1 == "High: 99.5"

    let result2 = match lowReading:
      Sensor.Reading(i, Some(v)) and v > 50.0: "High: " & $v
      Sensor.Reading(i, Some(v)): "Low: " & $v
      Sensor.Reading(i, None()): "No data"
      Sensor.Offline(i): "Offline"

    check result2 == "Low: 10.2"

  test "multiple variants with same Option field pattern":
    # Test multiple variant branches with identical Option field types
    variant Message:
      Info(infoText: string, infoMeta: Option[string])
      Warning(warnText: string, warnMeta: Option[string])
      Error(errorText: string, errorMeta: Option[string])

    let infoWithMeta = Message.Info("test", some("meta"))
    let warningNoMeta = Message.Warning("warning", none(string))
    let errorWithMeta = Message.Error("error", some("stack"))

    # Pattern matching distinguishes variants despite same field types
    let result1 = match infoWithMeta:
      Message.Info(t, Some(m)): "Info: " & t & " (" & m & ")"
      Message.Info(t, None()): "Info: " & t
      Message.Warning(t, _): "Warning: " & t
      Message.Error(t, _): "Error: " & t

    check result1 == "Info: test (meta)"

    let result2 = match warningNoMeta:
      Message.Info(t, _): "Info: " & t
      Message.Warning(t, Some(m)): "Warning: " & t & " (" & m & ")"
      Message.Warning(t, None()): "Warning: " & t
      Message.Error(t, _): "Error: " & t

    check result2 == "Warning: warning"

    let result3 = match errorWithMeta:
      Message.Info(t, _): "Info: " & t
      Message.Warning(t, _): "Warning: " & t
      Message.Error(t, Some(m)): "Error: " & t & " (" & m & ")"
      Message.Error(t, None()): "Error: " & t

    check result3 == "Error: error (stack)"

  test "Option in zero-param variant combination":
    # Test combining zero-param variants with Option field variants
    variant State:
      Initialized()
      Running(pid: int, name: Option[string])
      Stopped()

    let initialized = State.Initialized()
    let runningNamed = State.Running(1234, some("server"))
    let runningUnnamed = State.Running(5678, none(string))
    let stopped = State.Stopped()

    # Pattern match across zero-param and Option variants
    let result1 = match initialized:
      State.Initialized(): "Init"
      State.Running(p, Some(n)): n & ":" & $p
      State.Running(p, None()): "Process:" & $p
      State.Stopped(): "Stopped"

    check result1 == "Init"

    let result2 = match runningNamed:
      State.Initialized(): "Init"
      State.Running(p, Some(n)): n & ":" & $p
      State.Running(p, None()): "Process:" & $p
      State.Stopped(): "Stopped"

    check result2 == "server:1234"

    let result3 = match runningUnnamed:
      State.Initialized(): "Init"
      State.Running(p, Some(n)): n & ":" & $p
      State.Running(p, None()): "Process:" & $p
      State.Stopped(): "Stopped"

    check result3 == "Process:5678"
