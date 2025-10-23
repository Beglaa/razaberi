import "../../pattern_matching"
import unittest
import tables
import sets

suite "Complete Collection Type Support":
  
  # ===============================
  # seq[T] - COMPREHENSIVE SUPPORT
  # ===============================
  test "seq[T] - basic patterns":
    let items = @["a", "b", "c"]
    let result = match items:
      ["a", "b", "c"]: "exact match"
      ["a", "b"]: "partial"
      _: "other"
    check result == "exact match"
    
  test "seq[T] - wildcard patterns":
    let items = @[1, 2, 3, 4, 5]
    let result = match items:
      [1, 2, *rest]: "starts with 1,2 plus " & $rest.len
      _: "other"
    check result == "starts with 1,2 plus 3"
    
  test "seq[T] - with guards":
    let items = @[1, 2, 3, 4, 5]
    let result = match items:
      items and items.len > 3: "long sequence: " & $items.len
      items: "short sequence: " & $items.len
    check result == "long sequence: 5"
    
  # ===============================
  # Table[K,V] - COMPREHENSIVE SUPPORT  
  # ===============================
  test "Table[K,V] - basic patterns":
    let config = {"port": 8080, "timeout": 30}.toTable
    let result = match config:
      {"port": 8080, "timeout": 30}: "exact config"
      {"port": p}: "has port " & $p
      _: "other"
    check result == "exact config"
    
  test "Table[K,V] - rest capture":
    let data = {"a": 1, "b": 2, "c": 3}.toTable
    let result = match data:
      {"a": 1, **rest}: "has a=1 plus " & $rest.len & " others"
      _: "other"
    check result == "has a=1 plus 2 others"
    
  test "Table[K,V] - type variations":
    let statusCodes = {200: "OK", 404: "Not Found"}.toTable
    let result = match statusCodes:
      {200: msg, **rest}: "success: " & msg & " (+" & $rest.len & ")"
      _: "other"
    check result == "success: OK (+1)"
    
  # ===============================
  # set[T] - COMPREHENSIVE SUPPORT
  # ===============================
  test "set[T] - basic patterns":
    let numbers = {1, 2, 3}
    let result = match numbers:
      {1, 2, 3}: "exact set match"
      {1, 2}: "subset"
      _: "other"
    check result == "exact set match"
    
  test "set[T] - enum patterns":
    type Color = enum Red, Green, Blue
    let colors = {Red, Blue}
    let result = match colors:
      {Red, Blue}: "red and blue set"
      {Green}: "green set"
      _: "other"
    check result == "red and blue set"
    
  test "set[T] - wildcard patterns":
    type Permission = enum Read, Write, Admin, Execute
    let perms = {Admin, Read, Write}
    let result = match perms:
      {Admin, *rest}: "admin plus " & $rest.len & " others"
      _: "other"
    check result == "admin plus 2 others"
    
  test "set[T] - @ patterns":
    let numbers = {5, 10, 15}
    let result = match numbers:
      {5, 10, 15} @ captured: "captured: " & $captured.len
      _: "other"
    check result == "captured: 3"
    
  # ===============================
  # array[I,T] - COMPREHENSIVE SUPPORT
  # ===============================
  test "array[I,T] - basic patterns":
    let arr: array[3, int] = [1, 2, 3]
    let result = match arr:
      [1, 2, 3]: "exact array"
      _: "other"
    check result == "exact array"
    
  test "array[I,T] - character arrays":
    let chars: array[3, char] = ['a', 'b', 'c']
    let result = match chars:
      ['a', 'b', 'c']: "abc array"
      _: "other"
    check result == "abc array"
    
  test "array[I,T] - with guards":
    let arr: array[3, int] = [1, 2, 3]
    let result = match arr:
      arr and arr.len == 3: "array of 3"
      arr: "other array"
    check result == "array of 3"
    
  # ===============================
  # COMPLEX COMBINATIONS
  # ===============================
  test "table with sequence values":
    let data = {
      "count": 3,
      "active": 1
    }.toTable
    
    let result = match data:
      {"count": 3, "active": 1}: "exact match"
      {"count": c, **rest}: "count=" & $c & " plus " & $rest.len
      _: "other"
    check result == "exact match"
    
  test "set @ patterns with complex guards":
    type Status = enum Active, Inactive, Pending
    let statuses = {Active, Pending}
    let result = match statuses:
      (statuses @ captured) and Active in captured: "has active: " & $captured.len
      statuses: "no active: " & $statuses.len
    check result == "has active: 2"