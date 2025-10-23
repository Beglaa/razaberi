import unittest
import ../../pattern_matching
import tables

# BUG REPRODUCTION TEST: @ Pattern with Table Rest Capture Variable Scoping
#
# This test reproduces a bug where @ patterns combined with table rest capture (**rest)
# don't properly expose the variables from within the pattern to the match body.
#
# Bug Description:
# When using patterns like {"key": value, **rest} @ tableVar, the variables 'value' and 'rest' 
# should be accessible in the match body, but they are not properly exposed due to
# incorrect variable scoping in @ pattern processing.
#
# Expected Behavior:
# Both the individual pattern variables (like 'rest', 'value') AND the @ binding variable  
# should be accessible in the match body, similar to how other @ patterns work.

suite "BUG: @ Pattern with Table Rest Capture Variable Scoping":
  
  test "BUG: @ pattern should expose both rest capture and @ binding":
    let config = {"host": "localhost", "port": "8080", "debug": "true", "ssl": "false"}.toTable
    
    # BUG REPRODUCTION: This should expose both 'rest' and 'fullConfig'
    # but currently 'rest' is not accessible due to variable scoping issue
    let result = match config:
      {"host": h, "port": p, **rest} @ fullConfig:
        "Host: " & h & ", Port: " & p & ", Rest count: " & $rest.len & ", Full count: " & $fullConfig.len
      _: "no match"
    
    # Should work: both rest and fullConfig should be accessible
    check result == "Host: localhost, Port: 8080, Rest count: 2, Full count: 4"

  test "BUG: @ pattern with table defaults and rest capture":
    let partialConfig = {"host": "api.server", "extra": "value"}.toTable
    
    # BUG REPRODUCTION: Complex case with defaults and rest capture in @ pattern
    let result = match partialConfig:
      {"host": (h = "localhost"), "port": (p = "8080"), **extras} @ config:
        "Host: " & h & ", Port: " & p & ", Extras: " & $extras.len & ", Total: " & $config.len
      _: "no match"
    
    # Should bind: h="api.server", p="8080" (default), extras contains "extra", config is full table
    check result == "Host: api.server, Port: 8080, Extras: 1, Total: 2"

  test "BUG: nested @ patterns with table rest capture":
    type Config = object
      settings: Table[string, string] 
      name: string
    
    let cfg = Config(
      settings: {"host": "prod.server", "debug": "true", "extra1": "val1", "extra2": "val2"}.toTable,
      name: "production"
    )
    
    # BUG REPRODUCTION: Nested @ pattern with table rest capture
    let result = match cfg:
      Config(settings: {"host": h, "debug": d, **extras} @ allSettings, name: n):
        "Name: " & n & ", Host: " & h & ", Debug: " & d & ", Extras: " & $extras.len & ", Settings: " & $allSettings.len
      _: "no match"
    
    check result == "Name: production, Host: prod.server, Debug: true, Extras: 2, Settings: 4"

  test "OR patterns with consistent variable names in @ patterns - NOW WORKING":
    # OR @ patterns with table rest capture are NOW IMPLEMENTED!
    # Pattern: {"host": h, **rest} | {"server": h, **rest} @ matched
    let config1 = {"host": "server1", "port": "8080", "extra": "data"}.toTable
    let config2 = {"server": "server2", "port": "9000", "ssl": "true"}.toTable

    # Test with first alternative
    let result1 = match config1:
      {"host": h, "port": p, **rest} | {"server": h, "port": p, **rest} @ matched:
        "Host: " & h & ", Port: " & p & ", Rest: " & $rest.len & ", Total: " & $matched.len
      _: "no match"

    check result1 == "Host: server1, Port: 8080, Rest: 1, Total: 3"

    # Test with second alternative
    let result2 = match config2:
      {"host": h, "port": p, **rest} | {"server": h, "port": p, **rest} @ matched:
        "Host: " & h & ", Port: " & p & ", Rest: " & $rest.len & ", Total: " & $matched.len
      _: "no match"

    check result2 == "Host: server2, Port: 9000, Rest: 1, Total: 3"

  test "BUG: @ pattern with sequence in table value and rest capture":
    type DataHolder = object
      items: seq[string]
      metadata: Table[string, string]
    
    let holder = DataHolder(
      items: @["a", "b", "c"],
      metadata: {"type": "list", "version": "1.0", "extra": "data"}.toTable
    )
    
    # BUG REPRODUCTION: Complex nested pattern with sequence and table rest capture in @ pattern
    let result = match holder:
      DataHolder(items: [first, *middle, last], metadata: {"type": t, **meta} @ allMeta):
        "First: " & first & ", Middle: " & $middle.len & ", Last: " & last & 
        ", Type: " & t & ", Meta: " & $meta.len & ", AllMeta: " & $allMeta.len
      _: "no match"
    
    check result == "First: a, Middle: 1, Last: c, Type: list, Meta: 2, AllMeta: 3"

suite "BUG CONTROL TESTS: @ Pattern Variable Scoping Validation":
  
  test "CONTROL: Regular @ patterns should still work":
    let simple = {"key": "value"}.toTable
    
    # Control test: simple @ pattern should continue to work
    let result = match simple:
      {"key": v} @ table:
        "Value: " & v & ", Table size: " & $table.len
      _: "no match"
    
    check result == "Value: value, Table size: 1"

  test "CONTROL: Table rest capture without @ should work":
    let data = {"a": "1", "b": "2", "c": "3"}.toTable
    
    # Control test: rest capture without @ should continue to work
    let result = match data:
      {"a": val, **rest}:
        "A: " & val & ", Rest: " & $rest.len
      _: "no match"
    
    check result == "A: 1, Rest: 2"

  test "CONTROL: @ patterns with other collection types":
    let items = @["first", "second", "third", "fourth"]
    
    # Control test: @ patterns with sequences should work
    let result = match items:
      [head, *tail] @ allItems:
        "Head: " & head & ", Tail: " & $tail.len & ", All: " & $allItems.len  
      _: "no match"
    
    check result == "Head: first, Tail: 3, All: 4"