import unittest
import ../../pattern_matching

{.push warning[UnusedImport]: off.}
{.push hint[XDeclaredButNotUsed]: off.}

# Push the limits - these patterns often break implementations
suite "Extreme Nesting Edge Cases":

  test "should handle tuple inside object inside tuple inside object":
    type
      # This creates: Object -> Tuple -> Object -> Tuple pattern
      Inner = object
        coords: tuple[x: float, y: float, z: float]
        meta: tuple[id: int, name: string]
      
      Wrapper = tuple[inner: Inner, status: bool, count: int]
      
      Outer = object
        wrapper: Wrapper
        timestamp: string
    
    let data = Outer(
      wrapper: (
        inner: Inner(
          coords: (x: 10.5, y: 20.5, z: 30.5),
          meta: (id: 42, name: "test")
        ),
        status: true,
        count: 100
      ),
      timestamp: "2024-01-01"
    )
    
    let result = match data:
      Outer(
        wrapper: (inner: Inner(coords: (x: xPos, y: yPos, z: zPos), meta: (id: metaId, name: metaName)), status: isOk, count: cnt),
        timestamp: ts
      ) and xPos > 10.0 and metaId == 42 and isOk and cnt >= 100:
        "Complex: x=" & $xPos & " y=" & $yPos & " z=" & $zPos & " id=" & $metaId & " name=" & metaName & " count=" & $cnt & " time=" & ts
      _: "Failed complex nesting"
    
    check(result == "Complex: x=10.5 y=20.5 z=30.5 id=42 name=test count=100 time=2024-01-01")

  test "should handle anonymous tuples with different patterns":
    type
      # Mix named and anonymous tuples
      Config = object
        settings: tuple[timeout: int, retries: int]  # Named tuple
        coords: (float, float, int)                  # Anonymous tuple - corrected syntax
        flags: tuple[a: bool, b: bool, c: int, d: string]  # Mixed
    
    let data = Config(
      settings: (timeout: 5000, retries: 3),
      coords: (1.1, 2.2, 42),
      flags: (a: true, b: false, c: 999, d: "test")
    )
    
    let result = match data:
      Config(
        settings: (timeout: t, retries: r),
        coords: (x, y, z),  # Anonymous tuple destructuring
        flags: (a: flagA, b: flagB, c: flagC, d: flagD)
      ) and t > 1000 and r <= 5 and x < 2.0 and z == 42 and flagA and not flagB:
        "Tuples: timeout=" & $t & " retries=" & $r & " coords=(" & $x & "," & $y & "," & $z & ") flags=(" & $flagA & "," & $flagB & "," & $flagC & "," & flagD & ")"
      _: "Tuple pattern failed"
    
    check(result == "Tuples: timeout=5000 retries=3 coords=(1.1,2.2,42) flags=(true,false,999,test)")

  test "should handle nested object constructors with inheritance":
    type
      # Test inheritance in nested patterns
      Base = ref object of RootObj
        id: int
      
      Derived = ref object of Base
        name: string
        config: tuple[enabled: bool, value: float]
      
      Container = object
        item: Base  # Polymorphic field
        metadata: tuple[version: int, derived: Derived]
    
    let derivedObj = Derived(id: 123, name: "derived", config: (enabled: true, value: 3.14))
    let anotherDerived = Derived(id: 456, name: "another", config: (enabled: false, value: 2.71))
    
    let data = Container(
      item: derivedObj,
      metadata: (version: 2, derived: anotherDerived)
    )
    
    # This is tricky - matching inheritance with nested patterns
    let result = match data:
      Container(
        item: Derived(id: itemId, name: itemName, config: (enabled: itemEnabled, value: itemValue)),
        metadata: (version: ver, derived: Derived(id: metaId, name: metaName, config: (enabled: metaEnabled, value: metaValue)))
      ) and itemId == 123 and ver == 2 and itemEnabled and not metaEnabled:
        "Inheritance: item=" & $itemId & ":" & itemName & " (" & $itemValue & ") meta=" & $metaId & ":" & metaName & " (" & $metaValue & ")"
      _: "Inheritance pattern failed"
    
    check(result == "Inheritance: item=123:derived (3.14) meta=456:another (2.71)")

  test "should handle extremely deep tuple nesting":
    type
      # Create 6-level deep tuple nesting
      Level6 = tuple[value: int, flag: bool]
      Level5 = tuple[inner: Level6, multiplier: float]
      Level4 = tuple[data: Level5, name: string]
      Level3 = tuple[content: Level4, id: int]
      Level2 = tuple[level3: Level3, count: int]
      Level1 = tuple[level2: Level2, version: string]
      
      Root = object
        deep: Level1
        status: string
    
    let data = Root(
      deep: (
        level2: (
          level3: (
            content: (
              data: (
                inner: (value: 999, flag: true),
                multiplier: 2.5
              ),
              name: "deep_name"
            ),
            id: 777
          ),
          count: 42
        ),
        version: "v1.0"
      ),
      status: "active"
    )
    
    # 6-level deep destructuring with guards
    let result = match data:
      Root(
        deep: (level2: (level3: (content: (data: (inner: (value: val, flag: f), multiplier: mult), name: n), id: deepId), count: cnt), version: ver),
        status: stat
      ) and val == 999 and f and mult > 2.0 and deepId > 700 and cnt < 50:
        "Deep6: val=" & $val & " mult=" & $mult & " name=" & n & " id=" & $deepId & " count=" & $cnt & " ver=" & ver & " status=" & stat
      _: "Deep nesting failed"
    
    check(result == "Deep6: val=999 mult=2.5 name=deep_name id=777 count=42 ver=v1.0 status=active")

  test "should handle mixed ref objects in tuples":
    type
      # Mix ref objects with value types in tuples
      RefData = ref object
        name: string
        value: int
      
      # Tuple containing both ref and value types
      MixedTuple = tuple[refObj: RefData, valueObj: tuple[x: int, y: string], count: int]
      
      Container = object
        mixed: MixedTuple
        extra: RefData
    
    let ref1 = RefData(name: "ref1", value: 111)
    let ref2 = RefData(name: "ref2", value: 222)
    
    let data = Container(
      mixed: (
        refObj: ref1,
        valueObj: (x: 42, y: "test"),
        count: 5
      ),
      extra: ref2
    )
    
    # Pattern matching with ref object dereferencing in tuples
    let result = match data:
      Container(
        mixed: (refObj: RefData(name: refName, value: refVal), valueObj: (x: valX, y: valY), count: cnt),
        extra: RefData(name: extraName, value: extraVal)
      ) and refVal == 111 and valX == 42 and extraVal == 222:
        "Mixed refs: ref1=" & refName & ":" & $refVal & " val=(" & $valX & "," & valY & ") count=" & $cnt & " extra=" & extraName & ":" & $extraVal
      _: "Mixed ref pattern failed"
    
    check(result == "Mixed refs: ref1=ref1:111 val=(42,test) count=5 extra=ref2:222")