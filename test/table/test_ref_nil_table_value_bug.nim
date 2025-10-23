import unittest
import tables
import ../../pattern_matching

{.push warning[UnusedImport]: off.}
{.push hint[XDeclaredButNotUsed]: off.}

suite "Minimal Nil Table Fix":

  test "nil pattern in table values works":
    type Node = ref object
      id: int
    
    let nilNode: Node = nil
    let table = {"test": nilNode}.toTable
    
    let result = match table:
      {"test": nil}: "success"
      _: "fail"
    
    check result == "success"