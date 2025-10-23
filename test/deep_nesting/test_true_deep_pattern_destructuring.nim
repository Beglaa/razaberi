import unittest
import options
import ../../pattern_matching

# TRUE Deep Pattern Destructuring Testing - Working patterns only

suite "TRUE Deep Pattern Destructuring":
  
  test "should match 10-level nested Option patterns":
    let deep10 = some(some(some(some(some(some(some(some(some(some("value"))))))))))
    
    let result = match deep10:
      Some(Some(Some(Some(Some(Some(Some(Some(Some(Some(v)))))))))):
        "10-level: " & v
      _: "failed"
    
    check(result == "10-level: value")

  test "should test 8-level deep Option patterns":
    let deep8 = some(some(some(some(some(some(some(some("eight"))))))))
    
    let result = match deep8:
      Some(Some(Some(Some(Some(Some(Some(Some(v)))))))):
        "8-level: " & v
      _: "failed"
    
    check(result == "8-level: eight")

  test "should match mixed deep patterns":
    let mixed = some(some(some(("outer", some(some("inner"))))))
    
    let result = match mixed:
      Some(Some(Some((o, Some(Some(i)))))):
        "Mixed: " & o & "+" & i
      _: "failed"
    
    check(result == "Mixed: outer+inner")

  test "should test 6-level deep patterns":
    let deep6 = some(some(some(some(some(some("six"))))))
    
    let result = match deep6:
      Some(Some(Some(Some(Some(Some(v)))))):
        "6-level: " & v
      _: "failed"
    
    check(result == "6-level: six")

  test "should test 7-level deep patterns":
    let deep7 = some(some(some(some(some(some(some("seven")))))))
    
    let result = match deep7:
      Some(Some(Some(Some(Some(Some(Some(v))))))):
        "7-level: " & v
      _: "failed"
    
    check(result == "7-level: seven")