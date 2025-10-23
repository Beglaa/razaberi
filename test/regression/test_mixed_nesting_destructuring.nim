import unittest
import ../../pattern_matching

{.push warning[UnusedImport]: off.}
{.push hint[XDeclaredButNotUsed]: off.}

# Test for mixed nesting: Object -> Tuple -> Object -> Named Tuple -> Object
# This pattern often reveals edge cases in destructuring logic

suite "Mixed Nesting Destructuring Tests":
  
  test "should destructure object -> tuple -> object -> named tuple -> object chain":
    # Define the nested structure types
    type
      # Level 5 (deepest): Simple object with property
      InnerData = object
        name: string
        value: int
      
      # Level 4: Named tuple containing the inner object
      Config = tuple[enabled: bool, data: InnerData, timeout: int]
      
      # Level 3: Object containing the named tuple
      Settings = object
        id: int
        config: Config
        active: bool
      
      # Level 2: Regular tuple containing the object
      # (int, Settings, string) - positional tuple
      
      # Level 1: Outer object containing the tuple
      Container = object
        version: string
        content: tuple[priority: int, settings: Settings, status: string]
        debug: bool
    
    # Create test data
    let testObj = Container(
      version: "1.0",
      content: (
        priority: 42,
        settings: Settings(
          id: 123,
          config: (
            enabled: true,
            data: InnerData(name: "test_data", value: 999),
            timeout: 5000
          ),
          active: true
        ),
        status: "running"
      ),
      debug: false
    )
    
    # Test the destructuring pattern
    let result = match testObj:
      Container(
        version: ver,
        content: (priority: prio, settings: Settings(id: settingsId, config: (enabled: isEnabled, data: InnerData(name: dataName, value: dataValue), timeout: timeoutVal), active: isActive), status: stat),
        debug: debugFlag
      ) and ver == "1.0" and prio > 40 and dataValue == 999:
        "Success: " & ver & " | Priority=" & $prio & " | Settings=" & $settingsId & 
        " | Config=" & $isEnabled & " | Data=" & dataName & ":" & $dataValue & 
        " | Timeout=" & $timeoutVal & " | Active=" & $isActive & " | Status=" & stat & 
        " | Debug=" & $debugFlag
      _: "Pattern match failed"
    
    check(result == "Success: 1.0 | Priority=42 | Settings=123 | Config=true | Data=test_data:999 | Timeout=5000 | Active=true | Status=running | Debug=false")
  
  test "should handle partial destructuring with wildcards":
    type
      InnerData = object
        name: string
        value: int
      
      Config = tuple[enabled: bool, data: InnerData, timeout: int]
      
      Settings = object
        id: int
        config: Config
        active: bool
      
      Container = object
        version: string
        content: tuple[priority: int, settings: Settings, status: string]
        debug: bool
    
    let testObj = Container(
      version: "2.0",
      content: (
        priority: 10,
        settings: Settings(
          id: 456,
          config: (
            enabled: false,
            data: InnerData(name: "prod_data", value: 777),
            timeout: 3000
          ),
          active: false
        ),
        status: "stopped"
      ),
      debug: true
    )
    
    # Test with wildcards and guards
    let result = match testObj:
      Container(
        version: _,  # Ignore version
        content: (priority: _, settings: Settings(id: id, config: (enabled: _, data: InnerData(name: name, value: _), timeout: _), active: _), status: status),
        debug: _
      ) and id > 400 and status == "stopped":
        "Partial match: ID=" & $id & " | Name=" & name & " | Status=" & status
      _: "No match"
    
    check(result == "Partial match: ID=456 | Name=prod_data | Status=stopped")
  
  test "should handle nested objects with same field names":
    # Test name collision handling
    type
      Inner = object
        name: string
        id: int
      
      Middle = tuple[name: string, inner: Inner]
      
      Outer = object
        name: string
        middle: Middle
    
    let testObj = Outer(
      name: "outer_name",
      middle: (
        name: "middle_name", 
        inner: Inner(name: "inner_name", id: 42)
      )
    )
    
    let result = match testObj:
      Outer(
        name: outerName,
        middle: (name: middleName, inner: Inner(name: innerName, id: innerId))
      ):
        "Names: " & outerName & " -> " & middleName & " -> " & innerName & " (ID=" & $innerId & ")"
      _: "Failed"
    
    check(result == "Names: outer_name -> middle_name -> inner_name (ID=42)")

  test "should handle deep nesting with guards at multiple levels":
    type
      Core = object
        value: int
        flag: bool
      
      Level3 = tuple[core: Core, multiplier: float]
      
      Level2 = object
        level3: Level3
        count: int
      
      Level1 = tuple[level2: Level2, name: string]
      
      Root = object
        level1: Level1
        version: int
    
    let testObj = Root(
      version: 3,
      level1: (
        level2: Level2(
          level3: (
            core: Core(value: 100, flag: true),
            multiplier: 2.5
          ),
          count: 5
        ),
        name: "deep_test"
      )
    )
    
    # Multiple guards at different levels
    let result = match testObj:
      Root(
        version: ver,
        level1: (level2: Level2(level3: (core: Core(value: val, flag: f), multiplier: mult), count: cnt), name: n)
      ) and ver >= 3 and val == 100 and f == true and mult > 2.0 and cnt < 10:
        "Deep: v=" & $ver & " val=" & $val & " mult=" & $mult & " cnt=" & $cnt & " name=" & n
      _: "Deep match failed"
    
    check(result == "Deep: v=3 val=100 mult=2.5 cnt=5 name=deep_test")