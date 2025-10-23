import unittest
import options
import ../../pattern_matching

# TRUE Deep Pattern Destructuring Testing
# Testing actual deep pattern syntax, not shallow patterns with deep guards

suite "Simple Deep Pattern Destructuring":
  
  test "should match 5-level nested Option patterns":
    # Test deep Option pattern destructuring
    let deep_some = some(some(some(some(some("deep_value")))))
    let shallow_none = none(Option[Option[Option[Option[string]]]])
    
    # Test 5-level deep pattern matching - THIS IS TRUE DEEP PATTERN DESTRUCTURING
    let result1 = match deep_some:
      Some(Some(Some(Some(Some(value))))):
        "Deep pattern matched: " & value
      _ : "No match"
    
    let result2 = match shallow_none:
      Some(Some(Some(Some(Some(value))))):
        "Should not match None"
      None():
        "None pattern matched"  
      _ : "No match"
    
    check(result1 == "Deep pattern matched: deep_value")
    check(result2 == "None pattern matched")

  test "should match 3-level nested tuple patterns":
    # Test deep tuple pattern destructuring
    let deep_tuple = ((("tuple_value",),),)
    
    # THIS IS TRUE DEEP PATTERN DESTRUCTURING
    let result = match deep_tuple:
      (((value,),),):
        "Deep tuple pattern: " & value
      _ : "No match"
    
    check(result == "Deep tuple pattern: tuple_value")

  test "should demonstrate difference - shallow vs deep patterns":
    # Create deep structure
    type
      SimpleLevel3 = object
        level3: string
      SimpleLevel2 = object  
        level2: SimpleLevel3
      SimpleDeepStruct = object
        level1: SimpleLevel2
    
    let data = SimpleDeepStruct(
      level1: SimpleLevel2(level2: SimpleLevel3(level3: "deep_data"))
    )
    
    # WRONG WAY (what I was doing before) - shallow pattern with deep guard
    let wrong_way = match data:
      SimpleDeepStruct(level1=l1) and l1.level2.level3 == "deep_data":
        "Shallow pattern + deep guard: WRONG approach"
      _ : "No match"
    
    # RIGHT WAY - true deep pattern destructuring  
    let right_way = match data:
      SimpleDeepStruct(level1=SimpleLevel2(level2=SimpleLevel3(level3=value))):
        "Deep pattern destructuring: " & value
      _ : "No match"
    
    check(wrong_way == "Shallow pattern + deep guard: WRONG approach")
    check(right_way == "Deep pattern destructuring: deep_data")

  test "should push deeper with Options":
    # Test even deeper Option patterns
    let deep_8 = some(some(some(some(some(some(some(some("level_8"))))))))
    
    let result = match deep_8:
      Some(Some(Some(Some(Some(Some(Some(Some(value)))))))):
        "8-level deep pattern: " & value
      _ : "No match"
    
    check(result == "8-level deep pattern: level_8")
  
  test "should test pattern limits":
    # Test where the pattern matching starts to struggle
    let very_deep = some(some(some(some(some(some(some(some(some(some("level_10"))))))))))
    
    let result = match very_deep:
      Some(Some(Some(Some(Some(Some(Some(Some(Some(Some(value)))))))))):
        "10-level deep pattern: " & value
      _ : "Pattern failed or too deep"
    
    # This will show us if 10-level deep patterns work
    check(result == "10-level deep pattern: level_10")