import unittest
import ../../pattern_matching

# ============================================================================
# CORE PATTERN: async() / sync() - Async/Sync Detection
# ============================================================================
# Test suite for async/sync pattern matching according to new specification

# Test functions - sync versions
proc syncFunc(): string = "sync"
proc syncInt(): int = 42
proc syncBool(): bool = true
proc syncNoReturn() = discard

suite "Core Pattern: async() / sync()":

  test "sync() matches synchronous functions":
    var result = ""
    match syncFunc:
      sync(): result = "sync function"
      _: result = "not sync"
    check result == "sync function"

  test "sync() matches sync functions with different return types":
    var result1, result2, result3 = ""

    match syncFunc:
      sync(): result1 = "sync"
      _: result1 = "not sync"

    match syncInt:
      sync(): result2 = "sync"
      _: result2 = "not sync"

    match syncBool:
      sync(): result3 = "sync"
      _: result3 = "not sync"

    check result1 == "sync"
    check result2 == "sync"
    check result3 == "sync"

  test "sync patterns with fallthrough work":
    var result = ""
    match syncFunc:
      async(): result = "async"
      sync(): result = "sync"
      _: result = "unknown"
    check result == "sync"

  test "sync and async are mutually exclusive":
    var result = ""
    match syncInt:
      async(): result = "async"
      sync(): result = "sync"
      _: result = "unknown"
    check result == "sync"

  test "sync patterns with multiple arms work":
    var result = ""
    match syncBool:
      async(): result = "async"
      sync(): result = "sync"
      _: result = "other"
    check result == "sync"

  test "sync pattern with wildcard fallback":
    var result = ""
    match syncFunc:
      sync(): result = "synchronous"
      _: result = "other"
    check result == "synchronous"

# Note: Actual async function testing requires async context
# The spec states async() checks for Future[T] return type
# For now, testing that sync() correctly identifies non-async functions
