import unittest
import ../../pattern_matching

type
  TestObj = ref object
    value: int
    name: string

suite "Ref Nil Object Constructor Priority Bug Test":
  # CRITICAL BUG: Object constructor patterns incorrectly match nil ref values
  # BUG LOCATION: pattern_matching.nim:10736-10749 in nnkObjConstr handling
  # ROOT CAUSE: when scrutineeVar is className: true branch succeeds without nil check
  
  test "nil ref should NOT match object constructor pattern":
    let obj: TestObj = nil
    
    # BUG: This should match the nil pattern, not the object constructor
    let result = match obj:
      TestObj(value: _, name: _): "WRONG - object matched nil!"
      nil: "CORRECT - nil matched"
      _: "wildcard"
    
    check result == "CORRECT - nil matched"

  test "nil ref should NOT cause segfault in object constructor pattern":
    let obj: TestObj = nil
    
    # BUG: This currently segfaults because it tries to access fields of nil
    let result = match obj:
      TestObj(value: v, name: n): "matched: " & $v & " " & n
      nil: "nil matched"
      _: "other"
    
    check result == "nil matched"

  test "non-nil ref should still work correctly":
    let obj = TestObj(value: 42, name: "test")
    
    let result = match obj:
      TestObj(value: v, name: n): "matched: " & $v & " " & n
      nil: "nil matched"
      _: "other"
    
    check result == "matched: 42 test"

  test "mixed ref types with nil should work correctly":
    let obj1: TestObj = nil
    let obj2 = TestObj(value: 100, name: "valid")
    
    let result1 = match obj1:
      TestObj(value: _, name: _): "obj1_matched"
      nil: "obj1_nil"
      _: "obj1_other"
    
    let result2 = match obj2:
      TestObj(value: v, name: n): "obj2_matched_" & $v
      nil: "obj2_nil"
      _: "obj2_other"
    
    check result1 == "obj1_nil"
    check result2 == "obj2_matched_100"

  test "nested object constructor with nil ref field":
    type
      NestedObj = ref object
        inner: TestObj
        id: int
    
    let nested = NestedObj(inner: nil, id: 5)
    
    # This should work: non-nil outer object, nil inner field
    let result = match nested:
      NestedObj(inner: TestObj(value: _, name: _), id: _): "inner_matched"
      NestedObj(inner: nil, id: i): "inner_nil_id_" & $i
      nil: "outer_nil"
      _: "other"
    
    check result == "inner_nil_id_5"