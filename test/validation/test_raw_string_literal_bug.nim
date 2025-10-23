import unittest
import std/strutils
import ../../pattern_matching

{.push warning[UnusedImport]: off.}
{.push hint[XDeclaredButNotUsed]: off.}

# ============================================================================
# CRITICAL BUG: Raw String Literals (nnkRStrLit) Not Handled in Pattern Matching
# ============================================================================
# 
# BUG DESCRIPTION:
# Raw string literals (r"string") and triple-quoted strings ("""string""") 
# cause pattern matching to fail with "Unsupported pattern type" error.
# The main pattern case statement only handles nnkStrLit but not nnkRStrLit
# or nnkTripleStrLit, despite them being handled elsewhere in the code.
#
# ERROR: "Unsupported pattern type 'nnkRStrLit' for scrutinee of type 'string'"
# LOCATION: Main pattern matching case statement at pattern_matching.nim:~2280
# IMPACT: MEDIUM - Raw and triple-quoted string patterns fail compilation
# ROOT CAUSE: Missing nnkRStrLit and nnkTripleStrLit in main literal pattern case
# SOLUTION: Add nnkRStrLit and nnkTripleStrLit to literal pattern case statement

suite "Raw String Literal Pattern Bug - Missing nnkRStrLit/nnkTripleStrLit":

  test "BUG: Raw string literals fail in pattern matching":
    # This test should FAIL with current implementation
    # Error: "Unsupported pattern type 'nnkRStrLit'"
    
    let rawString = r"path\to\file\with\backslashes"
    
    # This pattern should work but currently fails
    let result = match rawString:
      r"path\to\file\with\backslashes": "raw string matched"
      _: "raw string not matched"
    
    check result == "raw string matched"

  test "BUG: Triple-quoted strings fail in pattern matching":
    # This test should FAIL with current implementation  
    # Error: "Unsupported pattern type 'nnkTripleStrLit'"
    
    let tripleString = """multi
line
string"""
    
    # This pattern should work but currently fails
    let result = match tripleString:
      """multi
line
string""": "triple string matched"
      _: "triple string not matched"
    
    check result == "triple string matched"

  test "BUG: Raw strings in OR patterns should work":
    # Test raw strings in more complex patterns
    
    let testStr = r"config\file.ini"
    
    let result = match testStr:
      r"config\file.ini" | r"settings\app.conf": "config file found"
      _: "config file not found"
    
    check result == "config file found"

  test "BUG: Raw strings in nested patterns should work":
    # Test raw strings in object patterns
    
    type PathConfig = object
      configPath: string
      dataPath: string
    
    let config = PathConfig(
      configPath: r"C:\Program Files\App\config.ini",
      dataPath: r"C:\Program Files\App\data\"
    )
    
    let result = match config:
      PathConfig(configPath: r"C:\Program Files\App\config.ini", dataPath: path): 
        "Found config with data path: " & path
      _: "Config not matched"
    
    check result.startsWith("Found config with data path:")

  # BASELINE TESTS: These should work to verify the framework
  test "Baseline: Regular string literals work (control test)":
    # Control test - regular strings should work
    let normalStr = "regular string"
    
    let result = match normalStr:
      "regular string": "normal string matched"
      _: "normal string not matched"
    
    check result == "normal string matched"

  test "Baseline: Raw strings work when NOT in patterns":
    # Test that raw strings work fine when not used in patterns
    let rawStr = r"test\path"
    let expected = r"test\path"
    
    check rawStr == expected  # This should work fine

# EXPECTED BEHAVIOR:
# 1. Current: Compilation fails with "Unsupported pattern type 'nnkRStrLit'"
# 2. After fix: Raw and triple-quoted string patterns should work like normal strings
# 3. The literal pattern case statement needs nnkRStrLit and nnkTripleStrLit added