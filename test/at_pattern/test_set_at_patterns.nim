import "../../pattern_matching"
import unittest

type
  Permission = enum
    Read, Write, Admin
  
  Status = enum
    Active, Inactive, Pending

suite "Set @ Pattern Tests":
  test "basic set @ pattern with enum":
    let perms = {Admin}
    let result = match perms:
      {Admin} @ captured: "admin: " & $captured
      {Read, Write} @ captured: "read-write: " & $captured
      _ @ captured: "other: " & $captured
    
    check result == "admin: {Admin}"
    
  test "set @ pattern with multiple elements":
    let perms = {Read, Write}
    let result = match perms:
      {Admin} @ captured: "admin only"
      {Read, Write} @ captured: "read-write access"
      _ @ captured: "other"
    
    check result == "read-write access"
    
  test "set @ pattern with integers":
    let numbers = {1, 2, 3}
    let result = match numbers:
      {1, 2, 3} @ captured: "one-two-three: " & $captured
      {1, 2} @ captured: "one-two: " & $captured
      _ @ captured: "other: " & $captured
    
    check result == "one-two-three: {1, 2, 3}"
    
  test "set @ pattern with characters":
    let chars = {'a', 'b', 'c'}
    let result = match chars:
      {'a', 'b', 'c'} @ captured: "abc: " & $captured
      {'a', 'b'} @ captured: "ab: " & $captured
      _ @ captured: "other: " & $captured
    
    check result == "abc: {'a', 'b', 'c'}"
    
  test "set @ pattern with guards":
    let perms = {Admin, Read}
    let result = match perms:
      ({Admin} @ captured) and captured.len == 1: "admin only: " & $captured
      ({Admin, Read} @ captured) and Admin in captured: "admin with read"
      _ @ captured: "other: " & $captured
    
    check result == "admin with read"
    
  test "set @ pattern with complex guards":
    let numbers = {5, 10, 15}
    let result = match numbers:
      (_ @ captured) and captured.len > 3: "large set"
      (_ @ captured) and captured.len == 3: "three elements: " & $captured
      _ @ captured: "other"
    
    check result == "three elements: {5, 10, 15}"
    
  test "empty set @ pattern":
    let empty: set[Permission] = {}
    let result = match empty:
      {} @ captured: "empty set: " & $captured
      _ @ captured: "non-empty: " & $captured
    
    check result == "empty set: {}"
    
  test "mixed enum types (should work with set equality)":
    let statuses = {Active, Pending}
    let result = match statuses:
      {Active, Pending} @ captured: "active-pending: " & $captured
      {Active} @ captured: "active only: " & $captured
      _ @ captured: "other: " & $captured
    
    check result == "active-pending: {Active, Pending}"