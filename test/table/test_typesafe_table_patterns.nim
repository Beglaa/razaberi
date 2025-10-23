import unittest
import tables, sequtils
import options
import ../../pattern_matching

suite "Type-Safe Table Pattern Tests":
  test "Table[string, int] with rest capture":
    # Test that **rest works with non-string value types
    let data = {"port": 8080, "timeout": 30, "retries": 3, "workers": 4}.toTable
    let result = match data:
      {"port": port, **rest}: 
        "Port: " & $port & ", Rest keys: " & $rest.len
      _: "no match"
    check(result == "Port: 8080, Rest keys: 3")
    
    # Verify rest table contains correct types and values
    let verification = match data:
      {"port": port, **rest}:
        rest.getOrDefault("timeout") == 30 and rest.getOrDefault("retries") == 3 and rest.getOrDefault("workers") == 4
      _: false
    check(verification == true)

  test "Table[int, string] patterns":
    # Test integer keys with string values
    let statusCodes = {200: "OK", 404: "Not Found", 500: "Internal Error", 401: "Unauthorized"}.toTable
    let result1 = match statusCodes:
      {200: message, **rest}: "Success: " & message & " (+" & $rest.len & " other codes)"
      _: "no match"
    check(result1 == "Success: OK (+3 other codes)")
    
    let result2 = match statusCodes:
      {404: message}: "Client error: " & message
      {500: message}: "Server error: " & message  
      {200: message}: "Success: " & message
      _: "unknown status"
    check(result2 == "Client error: Not Found")

  test "Table[string, float] with precision":
    # Test floating point values in tables
    let metrics = {"cpu_usage": 85.5, "memory_usage": 67.2, "disk_usage": 45.8, "network_io": 12.3}.toTable
    let result = match metrics:
      {"cpu_usage": cpu, "memory_usage": mem, **rest}:
        if cpu > 80.0 and mem > 60.0:
          "High resource usage detected"
        else:
          "Normal usage"
      _: "insufficient data"
    check(result == "High resource usage detected")

  test "Table[string, bool] configuration":
    # Test boolean values in configuration tables
    let config = {"debug": true, "ssl_enabled": false, "cache_enabled": true, "logging": true}.toTable
    let result = match config:
      {"debug": true, "ssl_enabled": ssl, **rest}:
        "Debug mode with SSL: " & $ssl & " and " & $rest.len & " other settings"
      {"debug": false, **rest}:
        "Production mode with " & $rest.len & " settings"
      _: "invalid config"
    check(result == "Debug mode with SSL: false and 2 other settings")

  test "Table with custom enum keys":
    type Priority = enum
      Low, Medium, High, Critical
    
    let taskPriorities = {Low: "backup", Medium: "review", High: "fix_bug", Critical: "security"}.toTable
    let result = match taskPriorities:
      {Critical: task, **rest}:
        "URGENT: " & task & " (+" & $rest.len & " other tasks)"
      {High: task, **rest}:
        "Important: " & task & " (+" & $rest.len & " other tasks)"
      _: "normal workload"
    check(result == "URGENT: security (+3 other tasks)")

  test "Table[string, Option[string]] with missing values":
    # Test tables containing Option types
    let userData = {"name": some("Alice"), "email": none(string), "phone": some("+1234567890")}.toTable
    let result = match userData:
      {"name": name, "email": email, **rest}:
        if name.isSome and email.isNone:
          "User " & name.get() & " has no email but " & $rest.len & " other field(s)"
        else:
          "Different user pattern"
      _: "invalid user data"
    check(result == "User Alice has no email but 1 other field(s)")

  test "Empty table handling":
    # Verify proper handling of empty tables
    let empty = initTable[string, int]()
    let result = match empty:
      {"key": value, **rest}: "found data"
      {"key": value}: "found key only" 
      emptyTable and emptyTable.len == 0: "empty table"
      _: "no match"
    check(result == "empty table")

  test "Complex nested type safety":
    # Test tables with complex value types
    type UserInfo = object
      id: int
      active: bool
    
    let users = {"admin": UserInfo(id: 1, active: true), "guest": UserInfo(id: 2, active: false)}.toTable
    let result = match users:
      {"admin": admin, **rest}:
        if admin.active:
          "Active admin (id: " & $admin.id & ") with " & $rest.len & " other users"
        else:
          "Inactive admin"
      _: "no admin user"
    check(result == "Active admin (id: 1) with 1 other users")
    
    # Verify that rest capture maintains proper types
    let typeCheck = match users:
      {"admin": admin, **rest}:
        # rest should be Table[string, UserInfo]
        rest.hasKey("guest") and not rest.getOrDefault("guest").active
      _: false
    check(typeCheck == true)

  test "Large table with type safety":
    # Test performance and type safety with larger tables
    var largeTable = initTable[int, string]()
    for i in 1..100:
      largeTable[i] = "value_" & $i
    
    let result = match largeTable:
      {1: first, 50: middle, 100: last, **rest}:
        first & " | " & middle & " | " & last & " (+" & $rest.len & " more)"
      _: "pattern not matched"
    
    check(result == "value_1 | value_50 | value_100 (+97 more)")
    check(largeTable.len == 100)  # Original table unchanged