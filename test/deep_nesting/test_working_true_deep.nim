import unittest
import options
import ../../pattern_matching

# TRUE Deep Pattern Destructuring - Working Examples
# This demonstrates ACTUAL pattern matching at depth

suite "Working True Deep Pattern Destructuring":
  
  test "should match 5-level nested Option patterns":
    # TRUE deep pattern matching - matching the pattern structure itself
    let deep_some = some(some(some(some(some("deep_value")))))
    
    # THIS IS REAL DEEP PATTERN DESTRUCTURING
    let result = match deep_some:
      Some(Some(Some(Some(Some(value))))):
        "5-level deep pattern matched: " & value
      _ : "No match"
    
    check(result == "5-level deep pattern matched: deep_value")

  test "should match deeper Option patterns":
    # Push to 8 levels
    let deep_8 = some(some(some(some(some(some(some(some("level_8"))))))))
    
    let result = match deep_8:
      Some(Some(Some(Some(Some(Some(Some(Some(value)))))))):
        "8-level deep pattern: " & value
      _ : "No match"
    
    check(result == "8-level deep pattern: level_8")

  test "should test 10-level deep Option patterns":
    # Maximum depth test
    let deep_10 = some(some(some(some(some(some(some(some(some(some("level_10"))))))))))
    
    let result = match deep_10:
      Some(Some(Some(Some(Some(Some(Some(Some(Some(Some(value)))))))))):
        "10-level deep pattern: " & value
      _ : "Pattern failed - too deep?"
    
    check(result == "10-level deep pattern: level_10")

  test "should demonstrate shallow vs deep approach":
    # Show the difference between what I was doing vs what you wanted
    let nested_options = some(some(some("target")))
    
    # WRONG: Shallow pattern + deep guard access
    # This would be: Some(opt) and opt.value.value == "target"
    
    # RIGHT: Deep pattern destructuring  
    let result = match nested_options:
      Some(Some(Some(value))):
        "Deep destructuring found: " & value
      _ : "No match"
    
    check(result == "Deep destructuring found: target")

  test "should match nested tuples with deep destructuring":
    # Deep tuple pattern matching
    let deep_tuple = ((("nested",),),)
    
    let result = match deep_tuple:
      (((value,),),):
        "Deep tuple destructuring: " & value  
      _ : "No match"
    
    check(result == "Deep tuple destructuring: nested")

  test "should test mixed deep patterns":
    # Combine Option and tuple patterns
    let mixed = some((some("inner"), "outer"))
    
    let result = match mixed:
      Some((Some(inner_val), outer_val)):
        "Mixed deep pattern: " & inner_val & " + " & outer_val
      _ : "No match"
    
    check(result == "Mixed deep pattern: inner + outer")