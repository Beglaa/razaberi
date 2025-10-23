import unittest
import ../../pattern_matching

{.push warning[UnusedImport]: off.}
{.push hint[XDeclaredButNotUsed]: off.}

# ============================================================================
# BUG: Spread Patterns Not Supported in Object Constructor Fields
# ============================================================================
# 
# BUG DESCRIPTION:
# Spread patterns (*rest, *middle, etc.) fail when used inside object 
# constructor fields, generating compilation error:
# "Unsupported nested pattern in object constructor field: nnkPrefix"
# 
# ERROR LOCATION: 
# pattern_matching.nim object constructor field processing
# 
# CURRENT STATE:
# - Spread patterns work in direct match: match seq: [first, *rest] -> OK
# - Spread patterns work in tuples: match tup: (first, *rest) -> OK  
# - BUT BROKEN: match obj: Obj(field: [first, *rest]) -> Error
# 
# EXPECTED BEHAVIOR:
# Object constructor fields should support all sequence patterns including
# spread patterns when the field is a sequence type.
# 
# IMPACT: 
# Cannot use spread patterns when matching sequence fields inside objects,
# limiting pattern expressiveness for structured data.

suite "Spread Pattern Object Field Bug":

  test "BUG: Spread pattern in object sequence field fails compilation":
    type Container = object
      items: seq[int]
      name: string
    
    let container = Container(
      items: @[1, 2, 3, 4],
      name: "test"
    )
    
    # This now works with the fix
    let result = match container:
      Container(items: [first, *rest], name: "test"): "matched with spread: " & $first & ", rest len: " & $rest.len
      Container(items: [1, 2, 3, 4], name: "test"): "exact match"
      _: "no match"
    
    check result == "matched with spread: 1, rest len: 3"

  test "Control: Spread patterns work outside object fields":
    # Verify that spread patterns work in other contexts
    let sequence = @[10, 20, 30, 40]
    
    # This works fine - spread patterns in direct match
    let result = match sequence:
      [first, *rest]: "first: " & $first & ", rest len: " & $rest.len
      _: "no match"
    
    check result == "first: 10, rest len: 3"

  test "Control: Exact sequence patterns work in object fields":
    # Verify that non-spread sequence patterns work in object fields
    type Data = object
      numbers: seq[int]
      flags: seq[bool]
    
    let data = Data(
      numbers: @[100, 200],
      flags: @[true, false]
    )
    
    # These should work - exact sequence patterns in object fields
    let result = match data:
      Data(numbers: [100, 200], flags: [true, false]): "exact sequences"
      Data(numbers: [100, 200], flags: f): "numbers exact, flags: " & $f.len
      Data(numbers: n, flags: f): "both variable: " & $n.len & ", " & $f.len
      _: "no match"
    
    check result == "exact sequences"

  test "BUG DEMO: What happens with nested sequence spread":
    type 
      NestedContainer = object
        outer: seq[seq[int]]
        label: string
    
    let nested = NestedContainer(
      outer: @[@[1, 2], @[3, 4, 5], @[6]],
      label: "nested"
    )
    
    # This would be very useful but likely also fails:
    # NestedContainer(outer: [first_seq, *rest_seqs], label: "nested")
    
    # Test what we can do instead
    let result = match nested:
      NestedContainer(outer: [[1, 2], [3, 4, 5], [6]], label: "nested"): "exact nested match"
      NestedContainer(outer: o, label: "nested"): "nested variable: " & $o.len
      _: "no match"
    
    check result == "exact nested match"

  test "Feature Request: Complex spread use cases we can't do":
    type 
      ComplexData = object
        headers: seq[string]
        body: seq[string] 
        footers: seq[string]
    
    let complex = ComplexData(
      headers: @["h1", "h2"],
      body: @["line1", "line2", "line3", "line4"],
      footers: @["f1"]
    )
    
    # These patterns would be incredibly useful but don't work:
    # ComplexData(headers: [*h], body: [first, *middle, last], footers: [*f])
    # ComplexData(headers: @["h1", "h2"], body: [first, *rest], footers: f)
    
    # Limited to exact or variable patterns
    let result = match complex:
      ComplexData(headers: ["h1", "h2"], body: b, footers: ["f1"]): "partial exact: " & $b.len & " body lines"
      ComplexData(headers: h, body: b, footers: f): "all vars: " & $h.len & "," & $b.len & "," & $f.len
      _: "no match"
    
    check result == "partial exact: 4 body lines"