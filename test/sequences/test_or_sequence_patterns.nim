# Test OR patterns with sequence literals (nnkBracket support)
import unittest
import ../../pattern_matching

# Test 1: Simple OR sequence patterns
proc testCommandOR(cmd: seq[string]): string =
  match cmd:
    ["exit"] | ["quit"] | ["bye"]: "Exit command"
    ["help"] | ["?"]: "Help command"
    ["ls"] | ["list"] | ["dir"]: "List command"
    ["cd"] | ["chdir"]: "Change directory command"
    []: "Empty command"
    _: "Unknown command"

# Test 2: OR sequence patterns with different lengths
proc testMixedLengthOR(data: seq[string]): string =
  match data:
    ["a"] | ["b", "c"]: "Short or medium"
    ["x", "y", "z"] | ["1", "2", "3", "4"]: "Long sequences"
    []: "Empty"
    _: "Other"

# Test 3: OR sequence patterns with wildcards
proc testORWithWildcards(tokens: seq[string]): string =
  match tokens:
    ["start"] | ["begin"] | ["init"]: "Starting commands"
    ["stop", _] | ["end", _]: "Stopping commands with arg"
    ["set", _, "on"] | ["set", _, "off"]: "Setting commands"
    _: "Unknown pattern"

# Test 4: OR sequence patterns in complex expressions
proc testComplexOR(input: seq[int]): string =
  match input:
    [0] | [1] | [2]: "Single small number"
    [0, 0] | [1, 1] | [2, 2]: "Repeated small numbers"
    [10, 20] | [30, 40] | [50, 60]: "Specific pairs"
    [_, 100] | [_, 200]: "Ending with special number"
    _: "Other pattern"

# Test 5: OR sequence patterns with nested OR
proc testNestedSeqOR(data: seq[string]): string =
  match data:
    (["red"] | ["green"] | ["blue"]): "Primary color"
    (["cat"] | ["dog"]) | (["fish"] | ["bird"]): "Animals"
    _: "Unknown"

suite "OR Patterns with Sequence Literals":

  test "Simple OR sequence patterns work":
    # Test exit commands
    check testCommandOR(@["exit"]) == "Exit command"
    check testCommandOR(@["quit"]) == "Exit command"
    check testCommandOR(@["bye"]) == "Exit command"
    
    # Test help commands
    check testCommandOR(@["help"]) == "Help command"
    check testCommandOR(@["?"]) == "Help command"
    
    # Test list commands
    check testCommandOR(@["ls"]) == "List command"
    check testCommandOR(@["list"]) == "List command"
    check testCommandOR(@["dir"]) == "List command"
    
    # Test change directory commands
    check testCommandOR(@["cd"]) == "Change directory command"
    check testCommandOR(@["chdir"]) == "Change directory command"
    
    # Test edge cases
    check testCommandOR(@[]) == "Empty command"
    check testCommandOR(@["unknown"]) == "Unknown command"

  test "Mixed length OR sequence patterns work":
    # Test different length sequences in OR
    check testMixedLengthOR(@["a"]) == "Short or medium"
    check testMixedLengthOR(@["b", "c"]) == "Short or medium"
    
    check testMixedLengthOR(@["x", "y", "z"]) == "Long sequences"
    check testMixedLengthOR(@["1", "2", "3", "4"]) == "Long sequences"
    
    check testMixedLengthOR(@[]) == "Empty"
    check testMixedLengthOR(@["other"]) == "Other"

  test "OR sequence patterns with wildcards work":
    # Test starting commands
    check testORWithWildcards(@["start"]) == "Starting commands"
    check testORWithWildcards(@["begin"]) == "Starting commands"
    check testORWithWildcards(@["init"]) == "Starting commands"
    
    # Test stopping commands with arguments
    check testORWithWildcards(@["stop", "server"]) == "Stopping commands with arg"
    check testORWithWildcards(@["end", "process"]) == "Stopping commands with arg"
    
    # Test setting commands
    check testORWithWildcards(@["set", "debug", "on"]) == "Setting commands"
    check testORWithWildcards(@["set", "verbose", "off"]) == "Setting commands"
    
    check testORWithWildcards(@["unknown", "pattern"]) == "Unknown pattern"

  test "Complex OR sequence patterns work":
    # Test single numbers
    check testComplexOR(@[0]) == "Single small number"
    check testComplexOR(@[1]) == "Single small number"
    check testComplexOR(@[2]) == "Single small number"
    
    # Test repeated numbers
    check testComplexOR(@[0, 0]) == "Repeated small numbers"
    check testComplexOR(@[1, 1]) == "Repeated small numbers"
    check testComplexOR(@[2, 2]) == "Repeated small numbers"
    
    # Test specific pairs
    check testComplexOR(@[10, 20]) == "Specific pairs"
    check testComplexOR(@[30, 40]) == "Specific pairs"
    check testComplexOR(@[50, 60]) == "Specific pairs"
    
    # Test ending patterns
    check testComplexOR(@[5, 100]) == "Ending with special number"
    check testComplexOR(@[99, 200]) == "Ending with special number"
    
    check testComplexOR(@[3, 4, 5]) == "Other pattern"

  test "Nested OR sequence patterns work":
    # Test colors
    check testNestedSeqOR(@["red"]) == "Primary color"
    check testNestedSeqOR(@["green"]) == "Primary color" 
    check testNestedSeqOR(@["blue"]) == "Primary color"
    
    # Test animals
    check testNestedSeqOR(@["cat"]) == "Animals"
    check testNestedSeqOR(@["dog"]) == "Animals"
    check testNestedSeqOR(@["fish"]) == "Animals"
    check testNestedSeqOR(@["bird"]) == "Animals"
    
    check testNestedSeqOR(@["other"]) == "Unknown"

