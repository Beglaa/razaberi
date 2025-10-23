import unittest
import ../../pattern_matching

{.push warning[UnusedImport]: off.}
{.push hint[XDeclaredButNotUsed]: off.}

# ============================================================================
# BUG: Reference Object with Sequence Field Pattern Comparison Bug
# ============================================================================
#
# BUG DESCRIPTION: 
# When pattern matching on ref objects that contain sequence fields with 
# literal sequence patterns, the macro generates incorrect comparison code.
#
# DISCOVERED BUG: 
# The pattern matching macro incorrectly generates:
#   `len(refObj[].seqField) == ["a", "b", "c"]` 
# Instead of:
#   `refObj[].seqField == @["a", "b", "c"]`
#
# TECHNICAL DETAILS:
# The issue occurs in the object constructor pattern processing where 
# sequence field patterns are incorrectly treated as length comparisons
# rather than direct sequence comparisons when inside ref objects.
#
# IMPACT: 
# Any pattern matching on ref objects with sequence fields using literal
# sequence patterns will fail to compile with type mismatch errors.
#
# LOCATION: pattern_matching.nim line ~11970 in generated comparison code

suite "Reference Object Sequence Field Comparison Bug":

  test "BUG: ref object with sequence field literal pattern fails":
    # This should work but generates incorrect comparison code
    type SeqHolder = ref object
      data: seq[string]
      count: int
    
    let holder = SeqHolder(data: @["a", "b", "c"], count: 3)
    
    # This pattern should work but generates buggy code:
    # len(holder[].data) == ["a", "b", "c"] (incorrect)
    # instead of: holder[].data == @["a", "b", "c"] (correct)
    let result = match holder:
      nil: "nil"
      SeqHolder(data: @["a", "b", "c"], count: 3): "exact match"
      SeqHolder(data: @["a", "b"], count: _): "partial match"
      SeqHolder(count: c): "count: " & $c
      _: "no match"
    
    check result == "exact match"

  test "BUG: ref object with sequence field variable binding works":
    # This should work as a control test  
    type SeqHolder = ref object
      data: seq[string]
      count: int
    
    let holder = SeqHolder(data: @["x", "y"], count: 2)
    
    # Variable binding should work fine
    let result = match holder:
      nil: "nil"
      SeqHolder(data: d, count: 2): "data: " & $d
      SeqHolder(count: c): "count: " & $c
      _: "no match"
    
    check result == "data: @[\"x\", \"y\"]"

  test "BUG: Direct sequence pattern works (control)":
    # This should work as a control test - direct sequence matching
    let data = @["a", "b", "c"]
    
    # Direct sequence matching should work
    let result = match data:
      @["a", "b", "c"]: "exact match"
      @["a", "b"]: "partial match" 
      _: "no match"
    
    check result == "exact match"

  test "BUG: Non-ref object with sequence field works (control)":  
    # This should work as a control test
    type SeqHolder = object  # Note: not ref
      data: seq[string]
      count: int
    
    let holder = SeqHolder(data: @["a", "b", "c"], count: 3)
    
    # Non-ref object should work fine
    let result = match holder:
      SeqHolder(data: @["a", "b", "c"], count: 3): "exact match"
      SeqHolder(data: @["a", "b"], count: _): "partial match"
      SeqHolder(count: c): "count: " & $c
      _: "no match"
    
    check result == "exact match"