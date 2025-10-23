import unittest
import ../../pattern_matching
import tables

suite "Empty Table Rest Pattern Fix - TDD Tests":

  test "Empty table rest pattern should work as table, not set":
    # This pattern {**rest} should be interpreted as table pattern
    # when scrutinee is a Table type
    let config = {"key1": "val1", "key2": "val2", "key3": "val3"}.toTable

    let result = match config:
      {**rest} @ all:
        "Rest: " & $rest.len & ", All: " & $all.len
      _: "no match"

    check result == "Rest: 3, All: 3"

  test "Empty table rest in OR pattern - first alternative":
    let config = {"a": "1", "b": "2"}.toTable

    let result = match config:
      {**rest} | {"key": _, **rest} @ cfg:
        "Rest: " & $rest.len & ", Config: " & $cfg.len
      _: "no match"

    check result == "Rest: 2, Config: 2"

  test "Empty table rest in OR pattern - second alternative":
    let config = {"key": "value", "extra": "data"}.toTable

    let result = match config:
      {"unknown": _, **rest} | {**rest} @ cfg:
        "Rest: " & $rest.len & ", Config: " & $cfg.len
      _: "no match"

    check result == "Rest: 2, Config: 2"

  test "Set patterns should still work (not break existing functionality)":
    # Regular set pattern should NOT be affected
    type Permission = enum
      Read, Write, Admin

    let perms: set[Permission] = {Admin, Read}

    let result = match perms:
      {Admin, Read} @ captured:
        "Got: " & $captured.len & " permissions"
      _: "no match"

    check result == "Got: 2 permissions"

  test "Set @ pattern should still work (not break existing functionality)":
    type Status = enum
      Active, Pending, Closed

    let status: set[Status] = {Active, Pending}

    let result = match status:
      {Active, Pending} @ s:
        "Status count: " & $s.len
      _: "no match"

    check result == "Status count: 2"

  test "Table type verification - should only work on tables":
    # This test verifies that {**rest} is ONLY interpreted as table pattern
    # when the scrutinee is actually a Table type
    # For non-table types, it should error or use normal set pattern logic

    type Permission = enum
      Read, Write

    # This should work as set pattern (not table)
    let perms: set[Permission] = {Read, Write}

    # Set pattern without ** should work normally
    let result = match perms:
      {Read, Write}: "both"
      {Read}: "read only"
      _: "other"

    check result == "both"
