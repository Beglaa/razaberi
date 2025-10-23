import ../../pattern_matching
import unittest

type
  User = object
    name: string
    permissions: set[Permission]
  
  Permission = enum
    Read, Write, Admin
  
  Project = object
    name: string
    priority: int
    lead: User
  
  Department = object
    name: string
    users: seq[User]
    projects: seq[Project]

suite "Deep Object Destructuring Tests":
  test "basic nested object pattern":
    let dept = Department(
      name: "Engineering",
      users: @[User(name: "Alice", permissions: {Admin, Read})],
      projects: @[Project(name: "Project A", priority: 1, 
                         lead: User(name: "Bob", permissions: {Admin}))]
    )
    
    let result = match dept:
      Department(name: n, users: users): "dept: " & n & " with " & $users.len & " users"
      _: "other"
    
    check result == "dept: Engineering with 1 users"
    
  test "nested object with field pattern":
    let dept = Department(
      name: "Engineering", 
      users: @[User(name: "Alice", permissions: {Admin, Read})],
      projects: @[]
    )
    
    # Test if we can match nested object fields
    let result = match dept:
      Department(name: "Engineering", users: [User(name: "Alice", permissions: perms)]): "found alice with perms"
      Department(name: "Engineering", users: _): "engineering dept"
      _: "other"
    
    check result == "found alice with perms"
    
  test "attempt deep nested object matching":
    let proj = Project(
      name: "Critical Project",
      priority: 1,
      lead: User(name: "Admin User", permissions: {Admin})
    )
    
    # Try to match deep nested structure
    let result = match proj:
      Project(lead: User(permissions: {Admin}, name: leadName)): "admin lead: " & leadName
      Project(lead: User(name: leadName)): "lead: " & leadName
      _: "other"
    
    check result == "admin lead: Admin User"