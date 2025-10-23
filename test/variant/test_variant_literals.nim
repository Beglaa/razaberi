import unittest
import ../../variant_dsl
import ../../pattern_matching

# ============================================================================
# VARIANT DSL LITERAL PATTERN TESTING
# ============================================================================
# Purpose: Test all literal types in variant discriminators and fields
# Coverage: int, string, float, bool, char, nil literals
# ============================================================================

suite "Variant Literals - Integer Patterns":

  test "integer literal matching in variant fields":
    variant NumberValue:
      IntVal(value: int)
      FloatVal(fValue: float)

    let val42 = NumberValue.IntVal(42)
    let val100 = NumberValue.IntVal(100)
    let valNeg5 = NumberValue.IntVal(-5)

    # Test exact integer literal matching
    let result42 = match val42:
      NumberValue.IntVal(42): "exactly 42"
      NumberValue.IntVal(100): "exactly 100"
      NumberValue.IntVal(_): "some other int"
      NumberValue.FloatVal(_): "float value"

    check result42 == "exactly 42"

    let result100 = match val100:
      NumberValue.IntVal(42): "exactly 42"
      NumberValue.IntVal(100): "exactly 100"
      NumberValue.IntVal(_): "some other int"
      NumberValue.FloatVal(_): "float value"

    check result100 == "exactly 100"

    let resultNeg5 = match valNeg5:
      NumberValue.IntVal(42): "exactly 42"
      NumberValue.IntVal(100): "exactly 100"
      NumberValue.IntVal(-5): "negative five"
      NumberValue.IntVal(_): "some other int"
      NumberValue.FloatVal(_): "float value"

    check resultNeg5 == "negative five"

  test "integer literal with multiple patterns":
    variant Counter:
      Count(value: int)
      Reset()

    let count42 = Counter.Count(42)
    let count100 = Counter.Count(100)
    let count50 = Counter.Count(50)

    # Test integer literals - multiple separate patterns
    let result1 = match count42:
      Counter.Count(42): "special value"
      Counter.Count(100): "special value"
      Counter.Count(_): "regular value"
      Counter.Reset: "reset"

    check result1 == "special value"

    let result2 = match count100:
      Counter.Count(42): "special value"
      Counter.Count(100): "special value"
      Counter.Count(_): "regular value"
      Counter.Reset: "reset"

    check result2 == "special value"

    let result3 = match count50:
      Counter.Count(42): "special value"
      Counter.Count(100): "special value"
      Counter.Count(_): "regular value"
      Counter.Reset: "reset"

    check result3 == "regular value"

  test "integer literal with guards":
    variant Score:
      Points(value: int)
      Bonus(extra: int)

    let points42 = Score.Points(42)
    let points10 = Score.Points(10)
    let points100 = Score.Points(100)

    # Test integer literals combined with guards
    let result1 = match points42:
      Score.Points(42) and true: "exactly 42"
      Score.Points(v) and v > 50: "high score"
      Score.Points(v) and v < 20: "low score"
      Score.Points(_): "medium score"
      Score.Bonus(_): "bonus points"

    check result1 == "exactly 42"

    let result2 = match points10:
      Score.Points(42): "exactly 42"
      Score.Points(v) and v > 50: "high score"
      Score.Points(v) and v < 20: "low score"
      Score.Points(_): "medium score"
      Score.Bonus(_): "bonus points"

    check result2 == "low score"

    let result3 = match points100:
      Score.Points(42): "exactly 42"
      Score.Points(v) and v > 50: "high score"
      Score.Points(v) and v < 20: "low score"
      Score.Points(_): "medium score"
      Score.Bonus(_): "bonus points"

    check result3 == "high score"

suite "Variant Literals - String Patterns":

  test "string literal matching in variant fields":
    variant Command:
      Text(text: string)
      Number(num: int)

    let hello = Command.Text("hello")
    let exit = Command.Text("exit")
    let quit = Command.Text("quit")

    # Test exact string literal matching
    let result1 = match hello:
      Command.Text("hello"): "greeting"
      Command.Text("exit"): "exiting"
      Command.Text("quit"): "quitting"
      Command.Text(_): "other text"
      Command.Number(_): "number"

    check result1 == "greeting"

    let result2 = match exit:
      Command.Text("hello"): "greeting"
      Command.Text("exit"): "exiting"
      Command.Text("quit"): "quitting"
      Command.Text(_): "other text"
      Command.Number(_): "number"

    check result2 == "exiting"

    let result3 = match quit:
      Command.Text("hello"): "greeting"
      Command.Text("exit"): "exiting"
      Command.Text("quit"): "quitting"
      Command.Text(_): "other text"
      Command.Number(_): "number"

    check result3 == "quitting"

  test "string literal with multiple patterns":
    variant Input:
      UserInput(input: string)
      Empty()

    let exitInput = Input.UserInput("exit")
    let quitInput = Input.UserInput("quit")
    let helpInput = Input.UserInput("help")

    # Test string literals - multiple separate patterns
    let result1 = match exitInput:
      Input.UserInput("exit"): "terminating"
      Input.UserInput("quit"): "terminating"
      Input.UserInput("help"): "showing help"
      Input.UserInput(_): "processing"
      Input.Empty: "no input"

    check result1 == "terminating"

    let result2 = match quitInput:
      Input.UserInput("exit"): "terminating"
      Input.UserInput("quit"): "terminating"
      Input.UserInput("help"): "showing help"
      Input.UserInput(_): "processing"
      Input.Empty: "no input"

    check result2 == "terminating"

    let result3 = match helpInput:
      Input.UserInput("exit"): "terminating"
      Input.UserInput("quit"): "terminating"
      Input.UserInput("help"): "showing help"
      Input.UserInput(_): "processing"
      Input.Empty: "no input"

    check result3 == "showing help"

  test "string literal with guards":
    variant Message:
      TextMsg(content: string)
      BinaryMsg(data: int)

    let shortMsg = Message.TextMsg("hi")
    let longMsg = Message.TextMsg("hello world")

    # Test string literals with guards
    let result1 = match shortMsg:
      Message.TextMsg("hi"): "short greeting"
      Message.TextMsg(s) and s.len > 5: "long message"
      Message.TextMsg(_): "regular message"
      Message.BinaryMsg(_): "binary"

    check result1 == "short greeting"

    let result2 = match longMsg:
      Message.TextMsg("hi"): "short greeting"
      Message.TextMsg(s) and s.len > 5: "long message"
      Message.TextMsg(_): "regular message"
      Message.BinaryMsg(_): "binary"

    check result2 == "long message"

suite "Variant Literals - Float Patterns":

  test "float literal matching in variant fields":
    variant Measurement:
      FloatValue(value: float)
      IntValue(iValue: int)

    let pi = Measurement.FloatValue(3.14)
    let e = Measurement.FloatValue(2.71)
    let temp = Measurement.FloatValue(37.0)

    # Test exact float literal matching
    let result1 = match pi:
      Measurement.FloatValue(3.14): "pi approximation"
      Measurement.FloatValue(2.71): "e approximation"
      Measurement.FloatValue(37.0): "body temperature"
      Measurement.FloatValue(_): "other float"
      Measurement.IntValue(_): "integer"

    check result1 == "pi approximation"

    let result2 = match e:
      Measurement.FloatValue(3.14): "pi approximation"
      Measurement.FloatValue(2.71): "e approximation"
      Measurement.FloatValue(37.0): "body temperature"
      Measurement.FloatValue(_): "other float"
      Measurement.IntValue(_): "integer"

    check result2 == "e approximation"

    let result3 = match temp:
      Measurement.FloatValue(3.14): "pi approximation"
      Measurement.FloatValue(2.71): "e approximation"
      Measurement.FloatValue(37.0): "body temperature"
      Measurement.FloatValue(_): "other float"
      Measurement.IntValue(_): "integer"

    check result3 == "body temperature"

  test "float literal with multiple patterns":
    variant Temperature:
      Celsius(value: float)
      Fahrenheit(fValue: float)

    let freezing = Temperature.Celsius(0.0)
    let boiling = Temperature.Celsius(100.0)
    let room = Temperature.Celsius(20.0)

    # Test float literals - multiple separate patterns
    let result1 = match freezing:
      Temperature.Celsius(0.0): "critical point"
      Temperature.Celsius(100.0): "critical point"
      Temperature.Celsius(_): "normal temperature"
      Temperature.Fahrenheit(_): "fahrenheit scale"

    check result1 == "critical point"

    let result2 = match boiling:
      Temperature.Celsius(0.0): "critical point"
      Temperature.Celsius(100.0): "critical point"
      Temperature.Celsius(_): "normal temperature"
      Temperature.Fahrenheit(_): "fahrenheit scale"

    check result2 == "critical point"

    let result3 = match room:
      Temperature.Celsius(0.0): "critical point"
      Temperature.Celsius(100.0): "critical point"
      Temperature.Celsius(_): "normal temperature"
      Temperature.Fahrenheit(_): "fahrenheit scale"

    check result3 == "normal temperature"

  test "float literal with guards":
    variant Reading:
      FloatReading(value: float)
      IntReading(iValue: int)

    let exact = Reading.FloatReading(3.14)
    let high = Reading.FloatReading(100.5)
    let low = Reading.FloatReading(1.0)

    # Test float literals with guards
    let result1 = match exact:
      Reading.FloatReading(3.14): "pi constant"
      Reading.FloatReading(v) and v > 50.0: "high reading"
      Reading.FloatReading(v) and v < 2.0: "low reading"
      Reading.FloatReading(_): "normal reading"
      Reading.IntReading(_): "integer reading"

    check result1 == "pi constant"

    let result2 = match high:
      Reading.FloatReading(3.14): "pi constant"
      Reading.FloatReading(v) and v > 50.0: "high reading"
      Reading.FloatReading(v) and v < 2.0: "low reading"
      Reading.FloatReading(_): "normal reading"
      Reading.IntReading(_): "integer reading"

    check result2 == "high reading"

    let result3 = match low:
      Reading.FloatReading(3.14): "pi constant"
      Reading.FloatReading(v) and v > 50.0: "high reading"
      Reading.FloatReading(v) and v < 2.0: "low reading"
      Reading.FloatReading(_): "normal reading"
      Reading.IntReading(_): "integer reading"

    check result3 == "low reading"

suite "Variant Literals - Boolean Patterns":

  test "boolean literal matching in variant fields":
    variant Flag:
      BoolFlag(enabled: bool)
      IntFlag(value: int)

    let trueFlag = Flag.BoolFlag(true)
    let falseFlag = Flag.BoolFlag(false)

    # Test boolean matching using guards (true/false are treated as identifiers, not literals)
    let result1 = match trueFlag:
      Flag.BoolFlag(b) and b == true: "enabled"
      Flag.BoolFlag(b) and b == false: "disabled"
      Flag.IntFlag(_): "integer flag"

    check result1 == "enabled"

    let result2 = match falseFlag:
      Flag.BoolFlag(b) and b == true: "enabled"
      Flag.BoolFlag(b) and b == false: "disabled"
      Flag.IntFlag(_): "integer flag"

    check result2 == "disabled"

  test "boolean values with discriminator patterns":
    variant Setting:
      BoolSetting(value: bool)
      StringSetting(text: string)

    let enabled = Setting.BoolSetting(true)
    let disabled = Setting.BoolSetting(false)

    # Test boolean values by matching discriminator only
    let result1 = match enabled:
      Setting.BoolSetting: "boolean setting"
      Setting.StringSetting: "string setting"

    check result1 == "boolean setting"

    let result2 = match disabled:
      Setting.BoolSetting: "boolean setting"
      Setting.StringSetting: "string setting"

    check result2 == "boolean setting"

  test "boolean values with guards":
    variant Status:
      Active(isRunning: bool)
      Pending(count: int)

    let running = Status.Active(true)
    let stopped = Status.Active(false)

    # Test boolean values with explicit guard comparisons
    let result1 = match running:
      Status.Active(b) and b == true: "actively running"
      Status.Active(b) and b == false: "stopped"
      Status.Pending(_): "pending"

    check result1 == "actively running"

    let result2 = match stopped:
      Status.Active(b) and b == true: "actively running"
      Status.Active(b) and b == false: "stopped"
      Status.Pending(_): "pending"

    check result2 == "stopped"

suite "Variant Literals - Character Patterns":

  test "character literal matching in variant fields":
    variant CharValue:
      Char(ch: char)
      String(str: string)

    let charA = CharValue.Char('A')
    let charZ = CharValue.Char('z')
    let charPlus = CharValue.Char('+')

    # Test exact character literal matching
    let result1 = match charA:
      CharValue.Char('A'): "letter A"
      CharValue.Char('z'): "letter z"
      CharValue.Char('+'): "plus sign"
      CharValue.Char(_): "other character"
      CharValue.String(_): "string value"

    check result1 == "letter A"

    let result2 = match charZ:
      CharValue.Char('A'): "letter A"
      CharValue.Char('z'): "letter z"
      CharValue.Char('+'): "plus sign"
      CharValue.Char(_): "other character"
      CharValue.String(_): "string value"

    check result2 == "letter z"

    let result3 = match charPlus:
      CharValue.Char('A'): "letter A"
      CharValue.Char('z'): "letter z"
      CharValue.Char('+'): "plus sign"
      CharValue.Char(_): "other character"
      CharValue.String(_): "string value"

    check result3 == "plus sign"

  test "character literal with multiple patterns":
    variant Symbol:
      CharSymbol(symbol: char)
      IntSymbol(code: int)

    let plus = Symbol.CharSymbol('+')
    let minus = Symbol.CharSymbol('-')
    let star = Symbol.CharSymbol('*')

    # Test character literals - multiple separate patterns
    let result1 = match plus:
      Symbol.CharSymbol('+'): "arithmetic operator"
      Symbol.CharSymbol('-'): "arithmetic operator"
      Symbol.CharSymbol('*'): "multiplication"
      Symbol.CharSymbol(_): "other symbol"
      Symbol.IntSymbol(_): "integer code"

    check result1 == "arithmetic operator"

    let result2 = match minus:
      Symbol.CharSymbol('+'): "arithmetic operator"
      Symbol.CharSymbol('-'): "arithmetic operator"
      Symbol.CharSymbol('*'): "multiplication"
      Symbol.CharSymbol(_): "other symbol"
      Symbol.IntSymbol(_): "integer code"

    check result2 == "arithmetic operator"

    let result3 = match star:
      Symbol.CharSymbol('+'): "arithmetic operator"
      Symbol.CharSymbol('-'): "arithmetic operator"
      Symbol.CharSymbol('*'): "multiplication"
      Symbol.CharSymbol(_): "other symbol"
      Symbol.IntSymbol(_): "integer code"

    check result3 == "multiplication"

  test "character literal with guards":
    variant Letter:
      CharLetter(ch: char)
      DigitLetter(digit: int)

    let upperA = Letter.CharLetter('A')
    let lowerZ = Letter.CharLetter('z')

    # Test character literals with guards
    let result1 = match upperA:
      Letter.CharLetter('A') and true: "capital A"
      Letter.CharLetter(c) and c >= 'a': "lowercase letter"
      Letter.CharLetter(_): "other character"
      Letter.DigitLetter(_): "digit"

    check result1 == "capital A"

    let result2 = match lowerZ:
      Letter.CharLetter('A'): "capital A"
      Letter.CharLetter(c) and c >= 'a': "lowercase letter"
      Letter.CharLetter(_): "other character"
      Letter.DigitLetter(_): "digit"

    check result2 == "lowercase letter"

suite "Variant Literals - Nil Patterns":

  test "nil checking with guards for ref fields":
    variant RefValue:
      RefInt(refValue: ref int)
      PlainInt(plainValue: int)

    var validRef = new(int)
    validRef[] = 42

    let withRef = RefValue.RefInt(validRef)
    let withNil = RefValue.RefInt(nil)

    # Test nil checking using guards (nil cannot be used as literal pattern)
    let result1 = match withRef:
      RefValue.RefInt(r) and not r.isNil: "valid reference"
      RefValue.RefInt(r) and r.isNil: "null reference"
      RefValue.PlainInt(_): "plain integer"

    check result1 == "valid reference"

    let result2 = match withNil:
      RefValue.RefInt(r) and not r.isNil: "valid reference"
      RefValue.RefInt(r) and r.isNil: "null reference"
      RefValue.PlainInt(_): "plain integer"

    check result2 == "null reference"

  test "nil checking with guards for optional refs":
    variant OptionalRef:
      MaybeRef(refval: ref string)
      DefiniteValue(value: string)

    var validStringRef = new(string)
    validStringRef[] = "test"

    let withStringRef = OptionalRef.MaybeRef(validStringRef)
    let withNilRef = OptionalRef.MaybeRef(nil)

    # Test nil checking with guards
    let result1 = match withStringRef:
      OptionalRef.MaybeRef(r) and not r.isNil: "has reference"
      OptionalRef.MaybeRef(r) and r.isNil: "no reference"
      OptionalRef.DefiniteValue(_): "definite"

    check result1 == "has reference"

    let result2 = match withNilRef:
      OptionalRef.MaybeRef(r) and not r.isNil: "has reference"
      OptionalRef.MaybeRef(r) and r.isNil: "no reference"
      OptionalRef.DefiniteValue(_): "definite"

    check result2 == "no reference"

suite "Variant Literals - Mixed Literal Patterns":

  test "mixed literal types in same variant":
    variant MixedValue:
      IntVal(iValue: int)
      FloatVal(fValue: float)
      StringVal(sValue: string)
      BoolVal(bValue: bool)
      CharVal(cValue: char)

    let int42 = MixedValue.IntVal(42)
    let floatPi = MixedValue.FloatVal(3.14)
    let strHello = MixedValue.StringVal("hello")
    let boolTrue = MixedValue.BoolVal(true)
    let charA = MixedValue.CharVal('A')

    # Test mixed literal matching
    let result1 = match int42:
      MixedValue.IntVal(42): "integer 42"
      MixedValue.FloatVal(3.14): "pi"
      MixedValue.StringVal("hello"): "greeting"
      MixedValue.BoolVal(true): "true boolean"
      MixedValue.CharVal('A'): "letter A"
      _: "other value"

    check result1 == "integer 42"

    let result2 = match floatPi:
      MixedValue.IntVal(42): "integer 42"
      MixedValue.FloatVal(3.14): "pi"
      MixedValue.StringVal("hello"): "greeting"
      MixedValue.BoolVal(true): "true boolean"
      MixedValue.CharVal('A'): "letter A"
      _: "other value"

    check result2 == "pi"

    let result3 = match strHello:
      MixedValue.IntVal(42): "integer 42"
      MixedValue.FloatVal(3.14): "pi"
      MixedValue.StringVal("hello"): "greeting"
      MixedValue.BoolVal(true): "true boolean"
      MixedValue.CharVal('A'): "letter A"
      _: "other value"

    check result3 == "greeting"

    let result4 = match boolTrue:
      MixedValue.IntVal(42): "integer 42"
      MixedValue.FloatVal(3.14): "pi"
      MixedValue.StringVal("hello"): "greeting"
      MixedValue.BoolVal(true): "true boolean"
      MixedValue.CharVal('A'): "letter A"
      _: "other value"

    check result4 == "true boolean"

    let result5 = match charA:
      MixedValue.IntVal(42): "integer 42"
      MixedValue.FloatVal(3.14): "pi"
      MixedValue.StringVal("hello"): "greeting"
      MixedValue.BoolVal(true): "true boolean"
      MixedValue.CharVal('A'): "letter A"
      _: "other value"

    check result5 == "letter A"

  test "literals with complex combinations":
    variant ComplexValue:
      Number(numValue: int)
      Text(textValue: string)
      Symbol(symbolValue: char)

    let num42 = ComplexValue.Number(42)
    let num100 = ComplexValue.Number(100)
    let textExit = ComplexValue.Text("exit")
    let textQuit = ComplexValue.Text("quit")
    let symbolPlus = ComplexValue.Symbol('+')
    let symbolMinus = ComplexValue.Symbol('-')

    # Test complex patterns with different literal types
    let result1 = match num42:
      ComplexValue.Number(42): "special number"
      ComplexValue.Number(100): "special number"
      ComplexValue.Text("exit"): "termination command"
      ComplexValue.Text("quit"): "termination command"
      ComplexValue.Symbol('+'): "arithmetic operator"
      ComplexValue.Symbol('-'): "arithmetic operator"
      _: "other value"

    check result1 == "special number"

    let result2 = match textExit:
      ComplexValue.Number(42): "special number"
      ComplexValue.Number(100): "special number"
      ComplexValue.Text("exit"): "termination command"
      ComplexValue.Text("quit"): "termination command"
      ComplexValue.Symbol('+'): "arithmetic operator"
      ComplexValue.Symbol('-'): "arithmetic operator"
      _: "other value"

    check result2 == "termination command"

    let result3 = match symbolPlus:
      ComplexValue.Number(42): "special number"
      ComplexValue.Number(100): "special number"
      ComplexValue.Text("exit"): "termination command"
      ComplexValue.Text("quit"): "termination command"
      ComplexValue.Symbol('+'): "arithmetic operator"
      ComplexValue.Symbol('-'): "arithmetic operator"
      _: "other value"

    check result3 == "arithmetic operator"

  test "literals with complex guard combinations":
    variant GuardValue:
      IntGuard(value: int)
      StrGuard(text: string)
      FloatGuard(fValue: float)

    let int50 = GuardValue.IntGuard(50)
    let strLong = GuardValue.StrGuard("hello world")
    let floatHigh = GuardValue.FloatGuard(75.5)

    # Test complex guard patterns with literals
    let result1 = match int50:
      GuardValue.IntGuard(42): "exactly 42"
      GuardValue.IntGuard(v) and v > 25 and v < 75: "medium range"
      GuardValue.IntGuard(_): "other int"
      GuardValue.StrGuard(s) and s.len > 5: "long string"
      GuardValue.StrGuard(_): "short string"
      GuardValue.FloatGuard(f) and f > 50.0: "high float"
      GuardValue.FloatGuard(_): "low float"

    check result1 == "medium range"

    let result2 = match strLong:
      GuardValue.IntGuard(42): "exactly 42"
      GuardValue.IntGuard(v) and v > 25 and v < 75: "medium range"
      GuardValue.IntGuard(_): "other int"
      GuardValue.StrGuard("hello") and true: "exact hello"
      GuardValue.StrGuard(s) and s.len > 5: "long string"
      GuardValue.StrGuard(_): "short string"
      GuardValue.FloatGuard(f) and f > 50.0: "high float"
      GuardValue.FloatGuard(_): "low float"

    check result2 == "long string"

    let result3 = match floatHigh:
      GuardValue.IntGuard(42): "exactly 42"
      GuardValue.IntGuard(v) and v > 25 and v < 75: "medium range"
      GuardValue.IntGuard(_): "other int"
      GuardValue.StrGuard(s) and s.len > 5: "long string"
      GuardValue.StrGuard(_): "short string"
      GuardValue.FloatGuard(3.14): "pi"
      GuardValue.FloatGuard(f) and f > 50.0: "high float"
      GuardValue.FloatGuard(_): "low float"

    check result3 == "high float"

suite "Variant Literals - Edge Cases":

  test "zero and negative integer literals":
    variant SignedInt:
      Value(num: int)

    let zero = SignedInt.Value(0)
    let negFive = SignedInt.Value(-5)
    let posFive = SignedInt.Value(5)

    # Test zero and negative literals
    let result1 = match zero:
      SignedInt.Value(0): "zero"
      SignedInt.Value(-5): "negative five"
      SignedInt.Value(5): "positive five"
      SignedInt.Value(_): "other"

    check result1 == "zero"

    let result2 = match negFive:
      SignedInt.Value(0): "zero"
      SignedInt.Value(-5): "negative five"
      SignedInt.Value(5): "positive five"
      SignedInt.Value(_): "other"

    check result2 == "negative five"

  test "empty string literal":
    variant TextValue:
      Text(content: string)

    let empty = TextValue.Text("")
    let nonEmpty = TextValue.Text("test")

    # Test empty string literal
    let result1 = match empty:
      TextValue.Text(""): "empty string"
      TextValue.Text(_): "non-empty string"

    check result1 == "empty string"

    let result2 = match nonEmpty:
      TextValue.Text(""): "empty string"
      TextValue.Text(_): "non-empty string"

    check result2 == "non-empty string"

  test "special float values":
    variant SpecialFloat:
      FloatSpecial(value: float)

    let zero = SpecialFloat.FloatSpecial(0.0)
    let negZero = SpecialFloat.FloatSpecial(-0.0)
    let one = SpecialFloat.FloatSpecial(1.0)

    # Test special float values
    let result1 = match zero:
      SpecialFloat.FloatSpecial(0.0): "zero"
      SpecialFloat.FloatSpecial(1.0): "one"
      SpecialFloat.FloatSpecial(_): "other"

    check result1 == "zero"

    let result2 = match one:
      SpecialFloat.FloatSpecial(0.0): "zero"
      SpecialFloat.FloatSpecial(1.0): "one"
      SpecialFloat.FloatSpecial(_): "other"

    check result2 == "one"

  test "whitespace in string literals":
    variant WhitespaceText:
      Content(text: string)

    let space = WhitespaceText.Content(" ")
    let tab = WhitespaceText.Content("\t")
    let newline = WhitespaceText.Content("\n")

    # Test whitespace string literals
    let result1 = match space:
      WhitespaceText.Content(" "): "space"
      WhitespaceText.Content("\t"): "tab"
      WhitespaceText.Content("\n"): "newline"
      WhitespaceText.Content(_): "other"

    check result1 == "space"

    let result2 = match tab:
      WhitespaceText.Content(" "): "space"
      WhitespaceText.Content("\t"): "tab"
      WhitespaceText.Content("\n"): "newline"
      WhitespaceText.Content(_): "other"

    check result2 == "tab"

    let result3 = match newline:
      WhitespaceText.Content(" "): "space"
      WhitespaceText.Content("\t"): "tab"
      WhitespaceText.Content("\n"): "newline"
      WhitespaceText.Content(_): "other"

    check result3 == "newline"
