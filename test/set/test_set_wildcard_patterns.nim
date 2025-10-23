import "../../pattern_matching"
import unittest

type
  Permission = enum
    Read, Write, Admin, Execute
  
  Color = enum
    Red, Green, Blue, Yellow

suite "Set Wildcard Pattern Tests":
  test "basic set wildcard with single required element":
    let perms = {Admin, Read, Write}
    let result = match perms:
      {Admin, *rest}: "has admin"
      {Read, *rest}: "has read"  
      _: "other"
    
    check result == "has admin"
    
  test "set wildcard with multiple required elements":
    let perms = {Read, Write, Execute}
    let result = match perms:
      {Admin, Read, *rest}: "admin+read"
      {Read, Write, *rest}: "read+write"
      _: "other"
    
    check result == "read+write"
    
  test "set wildcard with empty rest":
    let perms = {Admin}
    let result = match perms:
      {Admin, *rest}: "admin only"
      _: "other"
    
    check result == "admin only"
    
  test "set wildcard with rest variable":
    let perms = {Admin, Read, Write}
    let result = match perms:
      {Admin, *rest}: "admin with " & $rest.len & " others"
      _: "other"
    
    check result == "admin with 2 others"
    
  test "set wildcard with underscore (ignored rest)":
    let perms = {Admin, Read, Write}
    let result = match perms:
      {Admin, *_}: "has admin"
      {Read, *_}: "has read"
      _: "other"
    
    check result == "has admin"
    
  test "set wildcard with integer sets":
    let numbers = {1, 2, 3, 4, 5}
    let result = match numbers:
      {1, 2, *rest}: "starts with 1,2: " & $rest.len & " more"
      {1, *rest}: "starts with 1: " & $rest.len & " more"
      _: "other"
    
    check result == "starts with 1,2: 3 more"
    
  test "set wildcard with guards":
    let perms = {Admin, Read, Write, Execute}
    let result = match perms:
      ({Admin, *rest}) and rest.len > 2: "admin with many others"
      ({Admin, *rest}) and rest.len > 0: "admin with some others"
      {Admin, *rest}: "admin only"
      _: "other"
    
    check result == "admin with many others"
    
  test "set wildcard @ patterns":
    let perms = {Admin, Read}
    let result = match perms:
      ({Admin, *rest} @ allPerms) and rest.len > 0: "captured all"
      {Admin, *rest}: "admin with " & $rest.len & " others"
      _: "other"
    
    check result == "captured all"
    
  test "no required elements, only wildcard":
    let colors = {Red, Green, Blue}
    let result = match colors:
      {*all}: "got " & $all.len & " colors"
      _: "none"
    
    check result == "got 3 colors"
    
  test "wildcard with character sets":
    let chars = {'a', 'b', 'c', 'd'}
    let result = match chars:
      {'a', 'b', *rest}: "ab plus " & $rest.len
      {'a', *rest}: "a plus " & $rest.len
      _: "other"
    
    check result == "ab plus 2"
    
  test "wildcard pattern matching priority":
    let perms = {Read, Write}
    let result = match perms:
      {Read, Write, *rest}: "exact match"
      {Read, *rest}: "partial match"
      _: "no match"
    
    check result == "exact match"