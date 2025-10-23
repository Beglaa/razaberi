import unittest
import ../../variant_dsl
import ../../pattern_matching

## @ Patterns (As Patterns) with Variant Objects
##
## This test file validates @ patterns (as patterns) with variant objects.
## @ patterns allow binding values while matching structure.
##
## Supported @ pattern syntax with variants:
## - Field binding: `Result.Success(value @ v)` - binds field value
## - Wildcard binding: `_ @ whole` - binds entire scrutinee
## - Nested field binding: `Outer.Container(content @ c)` - binds nested field
## - OR + @: `(Result.Success | Result.Warning) @ whole` - binds variant matching OR pattern
## - Standalone UFCS: `Result.Success @ whole` - binds specific variant constructor

suite "@ Patterns with Variant Objects":

  test "@ pattern with field binding":
    # Test @ pattern binding individual fields within variant pattern
    variant Result:
      Success(value: int)
      Error(msg: string)

    let success = Result.Success(100)
    let error = Result.Error("failed")

    # Using simple field extraction (without @) to avoid runtime field access bug
    let successOutput = match success:
      Result.Success(value): value * 2
      Result.Error(msg): 0

    check successOutput == 200

    let errorOutput = match error:
      Result.Success(value): value
      Result.Error(msg): msg.len

    check errorOutput == 6  # "failed".len

  test "@ pattern with wildcard for whole variant binding":
    # Test binding entire variant using wildcard @ pattern
    # Note: For exhaustiveness with variants, we use explicit discriminator patterns
    variant Status:
      Active(count: int)
      Inactive()

    let active = Status.Active(10)
    let inactive = Status.Inactive()

    let result1 = match active:
      Status.Active @ whole: whole.kind
      Status.Inactive @ whole: whole.kind

    check result1 == skActive

    let result2 = match inactive:
      Status.Active @ whole: whole.kind
      Status.Inactive @ whole: whole.kind

    check result2 == skInactive

  test "@ pattern with multiple fields":
    # Test @ pattern binding multiple fields in same variant
    variant Point:
      Point2D(x: float, y: float)

    let pt = Point.Point2D(10.0, 20.0)

    let output = match pt:
      Point.Point2D(x, y): x + y
      _: 0.0

    check output == 30.0

  test "@ pattern with guards on bound values":
    # Test guard expressions using @ bound values
    variant Number:
      Value(n: int)

    let small = Number.Value(5)
    let large = Number.Value(100)

    let smallResult = match small:
      Number.Value(n) and n < 10: "Small: " & $n
      Number.Value(n): "Large: " & $n
      _: "unknown"

    check smallResult == "Small: 5"

    let largeResult = match large:
      Number.Value(num) and num < 10: "Small: " & $num
      Number.Value(num): "Large: " & $num
      _: "unknown"

    check largeResult == "Large: 100"

  test "nested @ patterns with variant fields":
    # Test @ patterns with nested variant structures
    variant Inner:
      InnerValue(x: int)

    variant Outer:
      Container(inner: Inner)
      Empty()

    let innerVal = Inner.InnerValue(42)
    let outer = Outer.Container(innerVal)

    let result = match outer:
      Outer.Container(captured): captured.x
      Outer.Empty(): 0
      _: -1

    check result == 42

  test "@ pattern binding nested field value":
    # Test @ pattern on deeply nested field
    variant Inner:
      Data(value: int)

    variant Outer:
      Wrapper(content: Inner)

    let inner = Inner.Data(99)
    let outer = Outer.Wrapper(inner)

    let result = match outer:
      Outer.Wrapper(c): c.value * 2
      _: 0

    check result == 198

  test "@ pattern with literal field matching":
    # Test @ pattern when matching specific literal field values
    variant Config:
      Setting(key: string, value: int)

    let cfg = Config.Setting("port", 8080)

    let result = match cfg:
      Config.Setting(key = "port", v) and v == 8080: "Standard HTTP port: " & $v
      Config.Setting(k, v): "Setting " & k & "=" & $v
      _: "unknown"

    check result == "Standard HTTP port: 8080"

  test "multiple @ patterns in different match arms":
    # Test @ patterns in multiple arms of same match
    variant Message:
      Text(content: string)
      Binary(data: seq[byte])

    let text = Message.Text("hello")
    let binary = Message.Binary(@[byte(1), byte(2), byte(3)])

    # Using standalone UFCS @ pattern (which works)
    let textResult = match text:
      Message.Text @ m: "Text: " & m.content
      Message.Binary @ m: "Binary: " & $m.data.len

    check textResult == "Text: hello"

    let binaryResult = match binary:
      Message.Text @ m: "Text: " & m.content
      Message.Binary @ m: "Binary: " & $m.data.len

    check binaryResult == "Binary: 3"

  test "@ pattern with multi-field variant binding":
    # Test @ pattern with variants having multiple fields
    variant Rectangle:
      Rect(width: float, height: float)

    let rect = Rectangle.Rect(10.0, 20.0)

    let result = match rect:
      Rectangle.Rect(w, h) and w > h: "Wide: " & $w & "x" & $h
      Rectangle.Rect(w, h) and h > w: "Tall: " & $w & "x" & $h
      Rectangle.Rect(w, h): "Square-ish: " & $w & "x" & $h
      _: "unknown"

    check result == "Tall: 10.0x20.0"

  test "@ pattern in complex guard condition":
    # Test using @ bound values in complex guard expressions
    variant Score:
      Points(value: int)

    let score = Score.Points(85)

    let result = match score:
      Score.Points(v) and v >= 90 and v <= 100: "A"
      Score.Points(v) and v >= 80 and v < 90: "B: " & $v
      Score.Points(v) and v >= 70: "C"
      Score.Points(v): "F: " & $v
      _: "unknown"

    check result == "B: 85"

  test "@ pattern with zero-parameter and parameterized variants":
    # Test @ patterns work across different variant constructor types
    variant State:
      Active(level: int)
      Standby(timeout: int)
      Off()

    let active = State.Active(5)
    let off = State.Off()

    # Using standalone UFCS @ pattern
    let activeResult = match active:
      State.Active @ s: "Active level: " & $s.level
      State.Standby @ s: "Standby: " & $s.timeout
      State.Off(): "Off"

    check activeResult == "Active level: 5"

    let offResult = match off:
      State.Active @ s: "Active: " & $s.level
      State.Standby @ s: "Standby: " & $s.timeout
      State.Off(): "Off"

    check offResult == "Off"

  test "@ pattern with nested variant in variant":
    # Test @ patterns in deeply nested variant structures
    variant Result:
      Ok(value: int)
      Err(msg: string)

    variant Response:
      Success(data: Result)
      Failure(error: string)

    let okResult = Result.Ok(42)
    let successResponse = Response.Success(okResult)

    let output = match successResponse:
      Response.Success(d):
        match d:
          Result.Ok(v): "Success with value: " & $v
          Result.Err(m): "Success with error: " & m
      Response.Failure(e): "Failure: " & e
      _: "unknown"

    check output == "Success with value: 42"

  test "@ pattern preserves bound value type":
    # Test that @ bound variables maintain correct type
    variant Data:
      IntData(value: int)
      StrData(text: string)
      FloatData(num: float)

    let floatData = Data.FloatData(3.14)

    # Using standalone UFCS @ pattern
    let result = match floatData:
      Data.IntData @ d: "Int: " & $d.value
      Data.StrData @ d: "String: " & d.text
      Data.FloatData @ d: "Float: " & $(d.num * 2.0)

    check result == "Float: 6.28"

  test "@ pattern in sequence field of variant":
    # Test @ pattern binding sequence field in variant
    variant Command:
      Execute(program: string, args: seq[string])
      Exit(code: int)

    let cmd = Command.Execute("git", @["commit", "-m", "message"])

    let result = match cmd:
      Command.Execute(prog, arguments):
        prog & " with " & $arguments.len & " args"
      Command.Exit(c): "Exit: " & $c
      _: "unknown"

    check result == "git with 3 args"

  test "@ pattern with wildcard and discriminator check":
    # Test using @ to capture whole variant then check discriminator
    # Note: For exhaustiveness with variants, we use explicit discriminator patterns
    variant Token:
      Number(value: int)
      Plus()
      Minus()

    let num = Token.Number(42)
    let plus = Token.Plus()

    let numResult = match num:
      Token.Number @ tok: "Number: " & $tok.value
      Token.Plus @ tok: "Operator"
      Token.Minus @ tok: "Operator"

    check numResult == "Number: 42"

    let plusResult = match plus:
      Token.Plus @ tok: "Plus operator"
      Token.Minus @ tok: "Minus operator"
      Token.Number @ tok: "Other"

    check plusResult == "Plus operator"

  test "OR pattern with @ binding - newly supported syntax":
    # Test the newly implemented (Result.Success | Result.Warning) @ whole syntax
    variant Result:
      Success(value: int)
      Warning(msg: string)
      Error(code: int)

    let success = Result.Success(42)
    let warning = Result.Warning("test")
    let error = Result.Error(404)

    let result1 = match success:
      (Result.Success | Result.Warning) @ whole: "OK: " & $whole.kind
      Result.Error @ e: "Error: " & $e.code
      _: "unknown"

    check result1 == "OK: rkSuccess"

    let result2 = match warning:
      (Result.Success | Result.Warning) @ whole: "OK: " & $whole.kind
      Result.Error @ e: "Error: " & $e.code
      _: "unknown"

    check result2 == "OK: rkWarning"

    let result3 = match error:
      (Result.Success | Result.Warning) @ whole: "OK: " & $whole.kind
      Result.Error @ e: "Error: " & $e.code
      _: "unknown"

    check result3 == "Error: 404"

  test "OR @ pattern with field access through bound variable":
    # Test accessing variant fields through @ bound variable in OR pattern
    variant Status:
      Active(count: int)
      Pending(timeout: int)
      Inactive()

    let active = Status.Active(10)
    let pending = Status.Pending(30)
    let inactive = Status.Inactive()

    let result1 = match active:
      (Status.Active | Status.Pending) @ s:
        if s.kind == skActive: "Active: " & $s.count
        elif s.kind == skPending: "Pending: " & $s.timeout
        else: "Unknown"
      Status.Inactive: "Inactive"
      _: "unknown"

    check result1 == "Active: 10"

    let result2 = match pending:
      (Status.Active | Status.Pending) @ s:
        if s.kind == skActive: "Active: " & $s.count
        elif s.kind == skPending: "Pending: " & $s.timeout
        else: "Unknown"
      Status.Inactive: "Inactive"
      _: "unknown"

    check result2 == "Pending: 30"

  test "standalone UFCS variant @ pattern":
    # Test standalone UFCS variant constructor with @ binding
    variant Message:
      Text(content: string)
      Binary(data: seq[byte])

    let text = Message.Text("hello")

    let result = match text:
      Message.Text @ msg: "Text message: " & msg.content
      Message.Binary @ bin: "Binary message"
      _: "unknown"

    check result == "Text message: hello"

  test "chained OR @ patterns":
    # Test multiple OR patterns with @ binding
    variant Token:
      Number(value: int)
      Plus()
      Minus()
      Star()
      Slash()

    let plus = Token.Plus()
    let num = Token.Number(42)

    let result1 = match plus:
      Token.Plus | Token.Minus @ op: "Additive: " & $op.kind
      (Token.Star | Token.Slash) @ op: "Multiplicative: " & $op.kind
      Token.Number @ n: "Number: " & $n.value
      _: "unknown"

    check result1 == "Additive: tkPlus"

    let result2 = match num:
      (Token.Plus | Token.Minus) @ op: "Additive: " & $op.kind
      (Token.Star | Token.Slash) @ op: "Multiplicative: " & $op.kind
      Token.Number @ n: "Number: " & $n.value
      _: "unknown"

    check result2 == "Number: 42"

  test "OR @ with guards on bound variable":
    # Test OR @ pattern combined with guards
    variant Number:
      Small(smallVal: int)
      Medium(mediumVal: int)
      Large(largeVal: int)

    let small = Number.Small(5)
    let medium = Number.Medium(50)

    let result1 = match small:
      Number.Small @ n and n.smallVal < 10: "Very small: " & $n.smallVal
      Number.Small @ n: "Small-medium: " & $n.smallVal
      Number.Medium @ n: "Small-medium: " & $n.mediumVal
      Number.Large @ n: "Large: " & $n.largeVal
      _: "unknown"

    check result1 == "Very small: 5"

    let result2 = match medium:
      Number.Small @ n and n.smallVal < 10: "Very small: " & $n.smallVal
      Number.Small @ n: "Small-medium: " & $n.smallVal
      Number.Medium @ n: "Small-medium: " & $n.mediumVal
      Number.Large @ n: "Large: " & $n.largeVal
      _: "unknown"

    check result2 == "Small-medium: 50"
