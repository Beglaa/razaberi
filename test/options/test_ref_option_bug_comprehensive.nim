## Comprehensive Test Suite for ref Option[T] Pattern Matching Bug
## 
## BUG DESCRIPTION:
## Pattern matching with `ref Option[T]` fails compilation because the library
## tries to call `.isSome`, `.isNone`, and `.get()` directly on ref types.
## Nim's auto-dereferencing works for field access but NOT for method calls.
##
## ERROR MESSAGE:
## Error: undeclared field: 'isSome' for type RefOption
##
## EXPECTED BEHAVIOR AFTER FIX:
## - ref Option[T] patterns should work by auto-dereferencing: refOption[].isSome  
## - Nil safety: check refOption != nil before dereferencing
## - Option[ref T] should continue working unchanged

import unittest
import options
import ../../pattern_matching

suite "Ref Option[T] Pattern Matching Bug - Comprehensive":
  
  test "ref Option[T] Some pattern basic - CRITICAL BUG":
    ## This test demonstrates the core bug with ref Option[T] pattern matching
    ## Should FAIL compilation until fixed
    type RefOption = ref Option[int]
    
    let data: RefOption = new Option[int]
    data[] = some(42)
    
    # BUG: This fails with "undeclared field: 'isSome' for type RefOption"
    # FIX: Should generate `data != nil and data[].isSome`
    let result = match data:
      Some(x): x * 2
      None(): 0
    
    check result == 84
  
  test "ref Option[T] None pattern basic - CRITICAL BUG":
    ## Tests None pattern with ref Option[T]
    type RefOption = ref Option[int]
    
    let data: RefOption = new Option[int]
    data[] = none(int)
    
    # BUG: This fails with "undeclared field: 'isNone' for type RefOption"
    # FIX: Should generate `data != nil and data[].isNone`
    let result = match data:
      Some(x): x * 2  
      None(): -1
    
    check result == -1
  
  test "ref Option[T] with guards - CRITICAL BUG":
    ## Tests Some pattern with guard expressions on ref Option[T]
    type RefOption = ref Option[int]
    
    let data: RefOption = new Option[int]
    data[] = some(50)
    
    # BUG: Guard evaluation also fails due to .get() call on ref type
    # FIX: Should use data[].get() for value extraction
    let result = match data:
      Some(x) and x > 40: x + 10
      Some(x): x
      None(): 0
    
    check result == 60
  
  test "ref Option[T] nested in object fields - CRITICAL BUG":
    ## Tests ref Option[T] as object fields  
    type
      RefOption = ref Option[string]
      Person = object
        name: string
        email: RefOption
    
    let person = Person(
      name: "Alice",
      email: (let e = new Option[string]; e[] = some("alice@test.com"); e)
    )
    
    # BUG: Field access on ref Option fails
    # FIX: Should handle nested ref Option field patterns
    let result = match person:
      Person(name: n, email: Some(email)): n & ": " & email
      Person(name: n, email: None()): n & ": no email"
      _: "unknown"
    
    check result == "Alice: alice@test.com"
  
  test "ref Option[T] nil handling - Should work after fix":
    ## Tests nil ref Option[T] - this part should work with proper nil checks
    type RefOption = ref Option[int]
    
    let data: RefOption = nil
    
    # This should work - matching nil is different from pattern matching content
    let result = match data:
      nil: -999
      Some(x): x
      None(): 0
    
    check result == -999
  
  test "Option[ref T] should continue working - NOT the bug":
    ## This tests Option[ref T] which is different and should continue working
    ## This is NOT the bug - this should work before and after the fix
    let refInt = new int
    refInt[] = 42
    let data: Option[ref int] = some(refInt)
    
    # This works because we call .isSome on Option directly, not on ref
    let result = match data:
      Some(x): x[] * 2  # x is ref int, so we need manual dereference here
      None(): 0
    
    check result == 84
  
  test "ref Option[T] complex nested pattern - CRITICAL BUG":
    ## Tests complex nested patterns with ref Option types
    type
      RefOptionInt = ref Option[int]
      RefOptionString = ref Option[string]  
      ComplexData = object
        id: RefOptionInt
        name: RefOptionString
        active: bool
    
    let item = ComplexData(
      id: (let i = new Option[int]; i[] = some(123); i),
      name: (let n = new Option[string]; n[] = some("test"); n),
      active: true
    )
    
    # BUG: Multiple ref Option field access will fail
    # FIX: Each field should use proper dereferencing
    let result = match item:
      ComplexData(id: Some(id), name: Some(name), active: true): 
        $id & ":" & name
      ComplexData(id: Some(id), name: None(), active: true):
        $id & ":anonymous"
      _: "invalid"
    
    check result == "123:test"
  
  test "ref Option[T] with default values - CRITICAL BUG":
    ## Tests ref Option with default value patterns
    type
      RefOption = ref Option[int]
      Config = object
        port: RefOption
        timeout: int
    
    let config = Config(
      port: (let p = new Option[int]; p[] = none(int); p),
      timeout: 30
    )
    
    # BUG: Default value extraction from ref Option will fail
    # FIX: Should properly handle ref Option in default patterns
    let result = match config:
      Config(port: Some(p), timeout: t): p + t
      Config(port: None(), timeout: t): 8080 + t  # Default port
    
    check result == 8110  # 8080 + 30
  
  test "multiple ref Option[T] types - CRITICAL BUG":
    ## Tests pattern matching with multiple different ref Option types
    type
      RefOptionInt = ref Option[int]
      RefOptionString = ref Option[string]
    
    let intData: RefOptionInt = new Option[int]
    intData[] = some(42)
    
    let strData: RefOptionString = new Option[string] 
    strData[] = some("hello")
    
    # BUG: Both ref Option types should fail compilation
    # FIX: Both should work with proper dereferencing
    let intResult = match intData:
      Some(x): x * 2
      None(): 0
      
    let strResult = match strData:
      Some(s): s & "!"
      None(): ""
    
    check intResult == 84
    check strResult == "hello!"