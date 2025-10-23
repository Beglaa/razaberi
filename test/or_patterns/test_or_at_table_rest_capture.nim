import unittest
import ../../pattern_matching
import tables

suite "OR @ patterns with table rest capture":

  test "OR @ with table rest capture - basic two alternatives":
    # Pattern: {"host": h, **rest} | {"server": h, **rest} @ matched
    # Both alternatives bind: h, rest
    # @ pattern binds: matched
    let config1 = {"host": "server1", "port": "8080", "extra": "data"}.toTable
    let config2 = {"server": "server2", "port": "9000", "extra": "info"}.toTable

    # Test with first alternative matching
    let result1 = match config1:
      {"host": h, "port": p, **rest} | {"server": h, "port": p, **rest} @ matched:
        "Host/Server: " & h & ", Port: " & p & ", Rest: " & $rest.len & ", Matched: " & $matched.len
      _: "no match"

    check result1 == "Host/Server: server1, Port: 8080, Rest: 1, Matched: 3"

    # Test with second alternative matching
    let result2 = match config2:
      {"host": h, "port": p, **rest} | {"server": h, "port": p, **rest} @ matched:
        "Host/Server: " & h & ", Port: " & p & ", Rest: " & $rest.len & ", Matched: " & $matched.len
      _: "no match"

    check result2 == "Host/Server: server2, Port: 9000, Rest: 1, Matched: 3"

  test "OR @ with table rest capture - no match case":
    let config = {"unknown": "value", "port": "8080"}.toTable

    let result = match config:
      {"host": h, "port": p, **rest} | {"server": h, "port": p, **rest} @ matched:
        "matched"
      _: "no match"

    check result == "no match"

  test "OR @ with table rest capture - three alternatives":
    let config1 = {"prod": "server1", "port": "8080", "ssl": "true"}.toTable
    let config2 = {"dev": "server2", "port": "9000", "debug": "true"}.toTable
    let config3 = {"staging": "server3", "port": "3000", "logs": "verbose"}.toTable

    let result1 = match config1:
      {"prod": s, "port": p, **rest} | {"dev": s, "port": p, **rest} | {"staging": s, "port": p, **rest} @ cfg:
        "Server: " & s & ", Port: " & p & ", Rest keys: " & $rest.len & ", Config size: " & $cfg.len
      _: "no match"

    check result1 == "Server: server1, Port: 8080, Rest keys: 1, Config size: 3"

    let result2 = match config2:
      {"prod": s, "port": p, **rest} | {"dev": s, "port": p, **rest} | {"staging": s, "port": p, **rest} @ cfg:
        "Server: " & s & ", Port: " & p & ", Rest keys: " & $rest.len & ", Config size: " & $cfg.len
      _: "no match"

    check result2 == "Server: server2, Port: 9000, Rest keys: 1, Config size: 3"

    let result3 = match config3:
      {"prod": s, "port": p, **rest} | {"dev": s, "port": p, **rest} | {"staging": s, "port": p, **rest} @ cfg:
        "Server: " & s & ", Port: " & p & ", Rest keys: " & $rest.len & ", Config size: " & $cfg.len
      _: "no match"

    check result3 == "Server: server3, Port: 3000, Rest keys: 1, Config size: 3"

  test "OR @ with table rest capture - with guards":
    let config1 = {"host": "localhost", "port": "8080", "ssl": "true"}.toTable
    let config2 = {"server": "prod.com", "port": "443", "ssl": "true"}.toTable

    let result1 = match config1:
      {"host": h, "port": p, **rest} | {"server": h, "port": p, **rest} @ cfg and rest.hasKey("ssl"):
        "SSL enabled for " & h & " on port " & p & ", config has " & $cfg.len & " keys"
      {"host": h, "port": p, **rest} | {"server": h, "port": p, **rest} @ cfg:
        "No SSL for " & h
      _: "no match"

    check result1 == "SSL enabled for localhost on port 8080, config has 3 keys"

    let result2 = match config2:
      {"host": h, "port": p, **rest} | {"server": h, "port": p, **rest} @ cfg and rest.hasKey("ssl"):
        "SSL enabled for " & h & " on port " & p & ", config has " & $cfg.len & " keys"
      {"host": h, "port": p, **rest} | {"server": h, "port": p, **rest} @ cfg:
        "No SSL for " & h
      _: "no match"

    check result2 == "SSL enabled for prod.com on port 443, config has 3 keys"

  test "OR @ with table rest capture - empty rest":
    let config1 = {"host": "server1", "port": "8080"}.toTable
    let config2 = {"server": "server2", "port": "9000"}.toTable

    let result1 = match config1:
      {"host": h, "port": p, **rest} | {"server": h, "port": p, **rest} @ matched:
        "Host: " & h & ", Port: " & p & ", Rest: " & $rest.len & ", Total: " & $matched.len
      _: "no match"

    check result1 == "Host: server1, Port: 8080, Rest: 0, Total: 2"

    let result2 = match config2:
      {"host": h, "port": p, **rest} | {"server": h, "port": p, **rest} @ matched:
        "Host: " & h & ", Port: " & p & ", Rest: " & $rest.len & ", Total: " & $matched.len
      _: "no match"

    check result2 == "Host: server2, Port: 9000, Rest: 0, Total: 2"

  test "OR @ with table rest capture - nested in tuple (complex nested patterns)":
    # Correct syntax: (pattern1 | pattern2) @ var
    # Parentheses group the OR pattern before the @ binding
    let data1 = ("req-123", {"host": "localhost", "port": "8080", "ssl": "true"}.toTable)
    let data2 = ("req-456", {"server": "prod.com", "port": "443", "region": "us-east"}.toTable)

    # Test with first alternative (host key)
    let result1 = match data1:
      (id, ({"host": h, "port": p, **rest} | {"server": h, "port": p, **rest}) @ cfg):
        "ID: " & id & ", Host/Server: " & h & ":" & p & ", Rest: " & $rest.len & ", Config: " & $cfg.len
      _: "no match"

    check result1 == "ID: req-123, Host/Server: localhost:8080, Rest: 1, Config: 3"

    # Test with second alternative (server key)
    let result2 = match data2:
      (id, ({"host": h, "port": p, **rest} | {"server": h, "port": p, **rest}) @ cfg):
        "ID: " & id & ", Host/Server: " & h & ":" & p & ", Rest: " & $rest.len & ", Config: " & $cfg.len
      _: "no match"

    check result2 == "ID: req-456, Host/Server: prod.com:443, Rest: 1, Config: 3"

    # Test with guards
    let data3 = ("admin", {"host": "secure.com", "port": "443", "ssl": "true", "auth": "token"}.toTable)
    let result3 = match data3:
      (user, ({"host": h, "port": p, **rest} | {"server": h, "port": p, **rest}) @ cfg) and rest.hasKey("ssl"):
        user & " accessing " & h & " with SSL (config size: " & $cfg.len & ")"
      _: "no match"

    check result3 == "admin accessing secure.com with SSL (config size: 4)"

  test "OR @ with table rest capture - access rest contents":
    let config = {"host": "localhost", "port": "8080", "ssl": "true", "debug": "false"}.toTable

    let result = match config:
      {"host": h, "port": p, **rest} | {"server": h, "port": p, **rest} @ cfg:
        "SSL: " & rest["ssl"] & ", Debug: " & rest["debug"] & ", Config size: " & $cfg.len
      _: "no match"

    check result == "SSL: true, Debug: false, Config size: 4"

suite "OR @ patterns with table rest capture - Edge Cases":

  test "OR @ table - consistent variable names validation":
    # This ensures both alternatives bind the same variable names
    let config = {"host": "server", "port": "8080", "extra": "data"}.toTable

    let result = match config:
      {"host": name, "port": p, **extras} | {"server": name, "port": p, **extras} @ all:
        "Name: " & name & ", Port: " & p & ", Extras: " & $extras.len & ", All: " & $all.len
      _: "no match"

    check result == "Name: server, Port: 8080, Extras: 1, All: 3"

  test "OR @ table - only @ binding accessible when no pattern vars":
    let config1 = {"key1": "val1", "key2": "val2"}.toTable
    let config2 = {"key3": "val3", "key4": "val4"}.toTable

    let result1 = match config1:
      {"key1": "val1"} | {"key3": "val3"} @ matched:
        "Matched keys: " & $matched.len
      _: "no match"

    check result1 == "Matched keys: 2"

    let result2 = match config2:
      {"key1": "val1"} | {"key3": "val3"} @ matched:
        "Matched keys: " & $matched.len
      _: "no match"

    check result2 == "Matched keys: 2"

  test "OR @ table - rest capture with no common keys (empty table constructor)":
    # Pattern {**rest} @ matched - captures entire table with no explicit keys
    let config = {"key1": "val1", "key2": "val2"}.toTable

    let result = match config:
      {**rest} @ matched:
        "Rest: " & $rest.len & ", Matched: " & $matched.len
      _: "no match"

    check result == "Rest: 2, Matched: 2"

  test "OR @ table - mixed with other patterns in match":
    let config = {"host": "server1", "port": "8080", "ssl": "true"}.toTable

    let result = match config:
      {"unknown": val, **rest} @ cfg:
        "Unknown match"
      {"host": h, "port": p, **rest} | {"server": h, "port": p, **rest} @ cfg:
        "Known match: " & h & " on " & p & ", has SSL: " & $rest.hasKey("ssl")
      _: "no match"

    check result == "Known match: server1 on 8080, has SSL: true"
