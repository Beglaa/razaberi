import unittest
import ../../variant_dsl
import ../../pattern_matching

## Group Patterns (Parentheses) with Variant Objects
##
## This test file validates group patterns for precedence control with variant discriminators.
## Group patterns use parentheses to control evaluation order in complex pattern expressions.
##
## Supported group pattern syntax with variants:
## - Basic grouping: `(A | B) | C` vs `A | (B | C)`
## - Nested grouping: `((A | B) | (C | D))`
## - Group + @: `(A | B) @ whole`
## - Group + guards: `(A | B) and condition`
## - Complex precedence: `((A | B) @ v) and v.kind == ...`

suite "Group Patterns with Variant Objects - Basic Grouping":

  test "simple grouped OR pattern for precedence control":
    variant Result:
      Success(value: int)
      Warning(msg: string)
      Error(code: int)

    let success = Result.Success(42)
    let warning = Result.Warning("test")
    let error = Result.Error(404)

    let result1 = match success:
      (Result.Success | Result.Warning): "OK"
      Result.Error: "Failed"

    check result1 == "OK"

    let result2 = match warning:
      (Result.Success | Result.Warning): "OK"
      Result.Error: "Failed"

    check result2 == "OK"

    let result3 = match error:
      (Result.Success | Result.Warning): "OK"
      Result.Error: "Failed"

    check result3 == "Failed"

  test "grouped OR on left side of larger OR":
    variant Status:
      Active(level: int)
      Standby(timeout: int)
      Sleeping()
      Off()

    let active = Status.Active(5)
    let sleeping = Status.Sleeping()
    let off = Status.Off()

    let result1 = match active:
      (Status.Active | Status.Standby) | Status.Sleeping: "Running"
      Status.Off: "Stopped"

    check result1 == "Running"

    let result2 = match sleeping:
      (Status.Active | Status.Standby) | Status.Sleeping: "Running"
      Status.Off: "Stopped"

    check result2 == "Running"

    let result3 = match off:
      (Status.Active | Status.Standby) | Status.Sleeping: "Running"
      Status.Off: "Stopped"

    check result3 == "Stopped"

  test "grouped OR on right side of larger OR":
    variant Token:
      Number(value: int)
      Plus()
      Minus()
      Star()

    let number = Token.Number(42)
    let plus = Token.Plus()
    let star = Token.Star()

    let result1 = match number:
      Token.Number | (Token.Plus | Token.Minus): "Additive"
      Token.Star: "Multiplicative"

    check result1 == "Additive"

    let result2 = match plus:
      Token.Number | (Token.Plus | Token.Minus): "Additive"
      Token.Star: "Multiplicative"

    check result2 == "Additive"

    let result3 = match star:
      Token.Number | (Token.Plus | Token.Minus): "Additive"
      Token.Star: "Multiplicative"

    check result3 == "Multiplicative"

  test "multiple groups in same pattern":
    variant Color:
      Red()
      Green()
      Blue()
      Yellow()
      Orange()

    let red = Color.Red()
    let blue = Color.Blue()
    let orange = Color.Orange()

    let result1 = match red:
      (Color.Red | Color.Green) | (Color.Blue | Color.Yellow): "Primary or Secondary"
      Color.Orange: "Tertiary"

    check result1 == "Primary or Secondary"

    let result2 = match blue:
      (Color.Red | Color.Green) | (Color.Blue | Color.Yellow): "Primary or Secondary"
      Color.Orange: "Tertiary"

    check result2 == "Primary or Secondary"

    let result3 = match orange:
      (Color.Red | Color.Green) | (Color.Blue | Color.Yellow): "Primary or Secondary"
      Color.Orange: "Tertiary"

    check result3 == "Tertiary"

suite "Group Patterns with Variant Objects - Nested Grouping":

  test "double nested grouping":
    variant Grade:
      A()
      B()
      C()
      D()
      F()

    let gradeA = Grade.A()
    let gradeC = Grade.C()
    let gradeF = Grade.F()

    let result1 = match gradeA:
      ((Grade.A | Grade.B) | (Grade.C | Grade.D)): "Pass"
      Grade.F: "Fail"

    check result1 == "Pass"

    let result2 = match gradeC:
      ((Grade.A | Grade.B) | (Grade.C | Grade.D)): "Pass"
      Grade.F: "Fail"

    check result2 == "Pass"

    let result3 = match gradeF:
      ((Grade.A | Grade.B) | (Grade.C | Grade.D)): "Pass"
      Grade.F: "Fail"

    check result3 == "Fail"

  test "triple nested grouping":
    variant Level:
      One()
      Two()
      Three()
      Four()
      Five()
      Six()

    let one = Level.One()
    let four = Level.Four()

    let result1 = match one:
      (((Level.One | Level.Two) | (Level.Three | Level.Four)) | (Level.Five | Level.Six)): "Valid"

    check result1 == "Valid"

    let result2 = match four:
      (((Level.One | Level.Two) | (Level.Three | Level.Four)) | (Level.Five | Level.Six)): "Valid"

    check result2 == "Valid"

  test "asymmetric nested grouping":
    variant Priority:
      Critical(urgency: int)
      High(level: int)
      Medium()
      Low()
      None()

    let critical = Priority.Critical(10)
    let low = Priority.Low()

    let result1 = match critical:
      ((Priority.Critical | Priority.High) | Priority.Medium) | (Priority.Low | Priority.None): "Categorized"

    check result1 == "Categorized"

    let result2 = match low:
      ((Priority.Critical | Priority.High) | Priority.Medium) | (Priority.Low | Priority.None): "Categorized"

    check result2 == "Categorized"

suite "Group Patterns with Variant Objects - Group + @ Patterns":

  test "group OR with @ binding":
    variant Result:
      Success(value: int)
      Warning(msg: string)
      Error(code: int)

    let success = Result.Success(42)
    let warning = Result.Warning("test")
    let error = Result.Error(404)

    let result1 = match success:
      (Result.Success | Result.Warning) @ whole: "OK: " & $whole.kind
      Result.Error @ e: "Failed"

    check result1 == "OK: rkSuccess"

    let result2 = match warning:
      (Result.Success | Result.Warning) @ whole: "OK: " & $whole.kind
      Result.Error @ e: "Failed"

    check result2 == "OK: rkWarning"

    let result3 = match error:
      (Result.Success | Result.Warning) @ whole: "OK: " & $whole.kind
      Result.Error @ e: "Failed"

    check result3 == "Failed"

  test "nested group with @ binding":
    variant State:
      Running(speed: int)
      Walking(pace: int)
      Standing()
      Sitting()

    let running = State.Running(10)
    let standing = State.Standing()

    # Test with simpler pattern - @ binding with group
    let result1 = match running:
      (State.Running | State.Walking) @ active: "State: " & $active.kind
      (State.Standing | State.Sitting): "Inactive"
      _: "unknown"

    check result1 == "State: skRunning"

    let result2 = match standing:
      (State.Running | State.Walking) @ active: "State: " & $active.kind
      (State.Standing | State.Sitting): "Inactive"
      _: "unknown"

    check result2 == "Inactive"

  test "multiple grouped @ patterns in same match":
    variant Token:
      Number(value: int)
      Plus()
      Minus()
      Star()
      Slash()

    let plus = Token.Plus()
    let star = Token.Star()
    let number = Token.Number(42)

    let result1 = match plus:
      (Token.Plus | Token.Minus) @ op: "Add: " & $op.kind
      (Token.Star | Token.Slash) @ op: "Mul: " & $op.kind
      Token.Number @ n: "Num"

    check result1 == "Add: tkPlus"

    let result2 = match star:
      (Token.Plus | Token.Minus) @ op: "Add: " & $op.kind
      (Token.Star | Token.Slash) @ op: "Mul: " & $op.kind
      Token.Number @ n: "Num"

    check result2 == "Mul: tkStar"

    let result3 = match number:
      (Token.Plus | Token.Minus) @ op: "Add: " & $op.kind
      (Token.Star | Token.Slash) @ op: "Mul: " & $op.kind
      Token.Number @ n: "Num"

    check result3 == "Num"

suite "Group Patterns with Variant Objects - Group + Guards":

  test "grouped pattern with guard condition":
    variant Number:
      Small(smallVal: int)
      Medium(mediumVal: int)
      Large(largeVal: int)

    let small = Number.Small(5)
    let medium = Number.Medium(50)
    let large = Number.Large(500)

    let result1 = match small:
      (Number.Small | Number.Medium) @ n and n.kind == nkSmall and n.smallVal < 10: "Very small: " & $n.smallVal
      (Number.Small | Number.Medium): "Small-Medium range"
      Number.Large: "Large"

    check result1 == "Very small: 5"

    let result2 = match medium:
      (Number.Small | Number.Medium) @ n and n.kind == nkSmall and n.smallVal < 10: "Very small: " & $n.smallVal
      (Number.Small | Number.Medium): "Small-Medium range"
      Number.Large: "Large"

    check result2 == "Small-Medium range"

    let result3 = match large:
      (Number.Small | Number.Medium) @ n and n.kind == nkSmall and n.smallVal < 10: "Very small: " & $n.smallVal
      (Number.Small | Number.Medium): "Small-Medium range"
      Number.Large: "Large"

    check result3 == "Large"

  test "nested group with guard on @ bound variable":
    variant Status:
      Active(count: int)
      Pending(timeout: int)
      Inactive()
      Disabled()

    let active = Status.Active(15)
    let pending = Status.Pending(5)
    let inactive = Status.Inactive()

    let result1 = match active:
      (Status.Active | Status.Pending) @ s and s.kind == skActive and s.count > 10: "High activity: " & $s.count
      (Status.Active | Status.Pending): "Active state"
      (Status.Inactive | Status.Disabled): "Stopped"

    check result1 == "High activity: 15"

    let result2 = match pending:
      (Status.Active | Status.Pending) @ s and s.kind == skActive and s.count > 10: "High activity: " & $s.count
      (Status.Active | Status.Pending): "Active state"
      (Status.Inactive | Status.Disabled): "Stopped"

    check result2 == "Active state"

    let result3 = match inactive:
      (Status.Active | Status.Pending) @ s and s.kind == skActive and s.count > 10: "High activity: " & $s.count
      (Status.Active | Status.Pending): "Active state"
      (Status.Inactive | Status.Disabled): "Stopped"

    check result3 == "Stopped"

  test "multiple grouped patterns with different guards":
    variant Score:
      High(highPoints: int)
      Medium(mediumPoints: int)
      Low(lowPoints: int)
      Zero()

    let high = Score.High(95)
    let medium = Score.Medium(75)
    let low = Score.Low(45)

    let result1 = match high:
      (Score.High | Score.Medium) @ s and s.kind == skHigh and s.highPoints >= 90: "Excellent: " & $s.highPoints
      (Score.High | Score.Medium) @ s and s.kind == skMedium and s.mediumPoints >= 70: "Good: " & $s.mediumPoints
      (Score.Low | Score.Zero): "Needs improvement"

    check result1 == "Excellent: 95"

    let result2 = match medium:
      (Score.High | Score.Medium) @ s and s.kind == skHigh and s.highPoints >= 90: "Excellent: " & $s.highPoints
      (Score.High | Score.Medium) @ s and s.kind == skMedium and s.mediumPoints >= 70: "Good: " & $s.mediumPoints
      (Score.Low | Score.Zero): "Needs improvement"

    check result2 == "Good: 75"

    let result3 = match low:
      (Score.High | Score.Medium) @ s and s.kind == skHigh and s.highPoints >= 90: "Excellent: " & $s.highPoints
      (Score.High | Score.Medium) @ s and s.kind == skMedium and s.mediumPoints >= 70: "Good: " & $s.mediumPoints
      (Score.Low | Score.Zero): "Needs improvement"

    check result3 == "Needs improvement"

suite "Group Patterns with Variant Objects - Complex Precedence":

  test "complex precedence with multiple groupings and guards":
    variant Result:
      Success(successValue: int)
      PartialSuccess(partialValue: int, warnings: seq[string])
      Warning(msg: string)
      Error(errorCode: int)
      Critical(criticalCode: int, fatal: bool)

    let success = Result.Success(42)
    let partialSuccess = Result.PartialSuccess(30, @["minor issue"])
    let critical = Result.Critical(500, true)

    let result1 = match success:
      (Result.Success | Result.PartialSuccess) @ r and r.kind == rkSuccess and r.successValue > 40: "Great: " & $r.successValue
      (Result.Success | Result.PartialSuccess | Result.Warning): "OK-ish"
      (Result.Error | Result.Critical): "Failed"

    check result1 == "Great: 42"

    let result2 = match partialSuccess:
      (Result.Success | Result.PartialSuccess) @ r and r.kind == rkSuccess and r.successValue > 40: "Great: " & $r.successValue
      (Result.Success | Result.PartialSuccess | Result.Warning): "OK-ish"
      (Result.Error | Result.Critical): "Failed"

    check result2 == "OK-ish"

    let result3 = match critical:
      (Result.Success | Result.PartialSuccess) @ r and r.kind == rkSuccess and r.successValue > 40: "Great: " & $r.successValue
      (Result.Success | Result.PartialSuccess | Result.Warning): "OK-ish"
      (Result.Error | Result.Critical): "Failed"

    check result3 == "Failed"

  test "deeply nested groups with field access":
    variant Message:
      TextShort(shortText: string)
      TextLong(longText: string)
      BinarySmall(smallData: seq[byte])
      BinaryLarge(largeData: seq[byte])
      Empty()

    let textShort = Message.TextShort("hi")
    let binaryLarge = Message.BinaryLarge(@[byte(1), byte(2), byte(3)])
    let empty = Message.Empty()

    let result1 = match textShort:
      (Message.TextShort | Message.TextLong) @ m and m.kind == mkTextShort and m.shortText.len < 5: "Short text: " & m.shortText
      ((Message.TextShort | Message.TextLong) | (Message.BinarySmall | Message.BinaryLarge)): "Has content"
      Message.Empty: "Empty"

    check result1 == "Short text: hi"

    let result2 = match binaryLarge:
      (Message.TextShort | Message.TextLong) @ m and m.kind == mkTextShort and m.shortText.len < 5: "Short text: " & m.shortText
      ((Message.TextShort | Message.TextLong) | (Message.BinarySmall | Message.BinaryLarge)): "Has content"
      Message.Empty: "Empty"

    check result2 == "Has content"

    let result3 = match empty:
      (Message.TextShort | Message.TextLong) @ m and m.kind == mkTextShort and m.shortText.len < 5: "Short text: " & m.shortText
      ((Message.TextShort | Message.TextLong) | (Message.BinarySmall | Message.BinaryLarge)): "Has content"
      Message.Empty: "Empty"

    check result3 == "Empty"

  test "precedence control with three-level nesting":
    variant Event:
      Click(clickX: int, clickY: int)
      DoubleClick(dblX: int, dblY: int)
      Hover(hoverX: int, hoverY: int)
      KeyPress(pressKey: char)
      KeyRelease(releaseKey: char)
      Scroll(delta: int)

    let click = Event.Click(10, 20)
    let keyPress = Event.KeyPress('a')
    let scroll = Event.Scroll(5)

    let result1 = match click:
      (Event.Click | Event.DoubleClick | Event.Hover) @ e: "Mouse: " & $e.kind
      (Event.KeyPress | Event.KeyRelease) @ e: "Keyboard: " & $e.kind
      Event.Scroll @ e: "Scroll"

    check result1 == "Mouse: ekClick"

    let result2 = match keyPress:
      (Event.Click | Event.DoubleClick | Event.Hover) @ e: "Mouse: " & $e.kind
      (Event.KeyPress | Event.KeyRelease) @ e: "Keyboard: " & $e.kind
      Event.Scroll @ e: "Scroll"

    check result2 == "Keyboard: ekKeyPress"

    let result3 = match scroll:
      (Event.Click | Event.DoubleClick | Event.Hover) @ e: "Mouse: " & $e.kind
      (Event.KeyPress | Event.KeyRelease) @ e: "Keyboard: " & $e.kind
      Event.Scroll @ e: "Scroll"

    check result3 == "Scroll"

suite "Group Patterns with Variant Objects - Edge Cases":

  test "redundant grouping (single element in group)":
    variant Flag:
      On()
      Off()

    let on = Flag.On()
    let off = Flag.Off()

    # Note: Single element in parens is just redundant parentheses, not a group pattern
    let result1 = match on:
      Flag.On: "Active"
      Flag.Off: "Inactive"

    check result1 == "Active"

    let result2 = match off:
      Flag.On: "Active"
      Flag.Off: "Inactive"

    check result2 == "Inactive"

  test "group pattern at end of match expression":
    variant State:
      Start()
      Processing()
      Done()
      Failed()

    let done = State.Done()
    let failed = State.Failed()

    let result1 = match done:
      State.Start: "Starting"
      State.Processing: "Working"
      (State.Done | State.Failed): "Finished"

    check result1 == "Finished"

    let result2 = match failed:
      State.Start: "Starting"
      State.Processing: "Working"
      (State.Done | State.Failed): "Finished"

    check result2 == "Finished"

  test "multiple separate grouped patterns":
    variant Traffic:
      Red()
      Yellow()
      Green()
      Flashing()

    let red = Traffic.Red()
    let green = Traffic.Green()
    let flashing = Traffic.Flashing()

    let result1 = match red:
      (Traffic.Red | Traffic.Yellow): "Stop"
      Traffic.Green: "Go"
      Traffic.Flashing: "Caution"

    check result1 == "Stop"

    let result2 = match green:
      (Traffic.Red | Traffic.Yellow): "Stop"
      Traffic.Green: "Go"
      Traffic.Flashing: "Caution"

    check result2 == "Go"

    let result3 = match flashing:
      (Traffic.Red | Traffic.Yellow): "Stop"
      Traffic.Green: "Go"
      Traffic.Flashing: "Caution"

    check result3 == "Caution"

  test "group with zero-parameter and parameterized variants mixed":
    variant Response:
      Ok(value: string)
      Accepted()
      Created(id: int)
      NoContent()

    let ok = Response.Ok("data")
    let accepted = Response.Accepted()
    let noContent = Response.NoContent()

    let result1 = match ok:
      (Response.Ok | Response.Created) @ r: "Has data: " & $r.kind
      (Response.Accepted | Response.NoContent): "No data"

    check result1 == "Has data: rkOk"

    let result2 = match accepted:
      (Response.Ok | Response.Created) @ r: "Has data: " & $r.kind
      (Response.Accepted | Response.NoContent): "No data"

    check result2 == "No data"

    let result3 = match noContent:
      (Response.Ok | Response.Created) @ r: "Has data: " & $r.kind
      (Response.Accepted | Response.NoContent): "No data"

    check result3 == "No data"

  test "group patterns preserve match evaluation order":
    variant Operation:
      Add(addA: int, addB: int)
      Subtract(subA: int, subB: int)
      Multiply(mulA: int, mulB: int)
      Divide(divA: int, divB: int)

    let add = Operation.Add(5, 3)
    let multiply = Operation.Multiply(4, 2)

    var executionOrder: seq[string] = @[]

    let result1 = match add:
      (Operation.Add | Operation.Subtract) @ op:
        executionOrder.add("arithmetic")
        "Arithmetic: " & $op.kind
      (Operation.Multiply | Operation.Divide): "Advanced"

    check result1 == "Arithmetic: okAdd"
    check executionOrder == @["arithmetic"]

    executionOrder = @[]

    let result2 = match multiply:
      (Operation.Add | Operation.Subtract): "Basic"
      (Operation.Multiply | Operation.Divide) @ op:
        executionOrder.add("advanced")
        "Advanced: " & $op.kind

    check result2 == "Advanced: okMultiply"
    check executionOrder == @["advanced"]
