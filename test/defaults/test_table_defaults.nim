import std/unittest
import ../../pattern_matching
import std/tables

suite "table default patterns":
  test "basic table patterns with consistent = syntax for defaults":
    let config = {"host": "localhost", "port": "8080"}.toTable
    
    # Test basic table matching with new (= default) syntax
    let result1 = match config:
      {"host": (host = "default"), "port": (port = "3000"), "ssl": (ssl = "false")} : 
        "Host: " & host & ", Port: " & port & ", SSL: " & ssl
      _ : "No match"
    
    check result1 == "Host: localhost, Port: 8080, SSL: false"
    
    # Test table with completely missing keys using defaults
    let empty_config = initTable[string, string]()
    let result2 = match empty_config:
      {"host": (host = "localhost"), "port": (port = "8080")} : 
        "Default config - Host: " & host & ", Port: " & port
      _ : "No match"
    
    check result2 == "Default config - Host: localhost, Port: 8080"

  test "mixed existing and missing keys":
    let partial_config = {"debug": "true", "timeout": "30"}.toTable
    let result = match partial_config:
      {"debug": (debug = "false"), "timeout": (timeout = "60"), "retries": (retries = "3")} : 
        "Debug: " & debug & ", Timeout: " & timeout & ", Retries: " & retries
      _ : "No match"
    
    check result == "Debug: true, Timeout: 30, Retries: 3"

  test "rest capture with defaults":
    let server_config = {"host": "prod.server", "extra1": "value1", "extra2": "value2"}.toTable
    let result = match server_config:
      {"host": (host = "localhost"), "port": (port = "8080"), **rest} : 
        "Server: " & host & ":" & port & ", Extra: " & $rest.len & " settings"
      _ : "No match"
    
    check result == "Server: prod.server:8080, Extra: 2 settings"

  test "explicit values override defaults":
    let full_config = {"host": "api.server", "port": "443", "ssl": "true"}.toTable
    let result = match full_config:
      {"host": (host = "localhost"), "port": (port = "8080"), "ssl": (ssl = "false")} : 
        "Full config - " & host & ":" & port & " (SSL: " & ssl & ")"
      _ : "No match"
    
    check result == "Full config - api.server:443 (SSL: true)"