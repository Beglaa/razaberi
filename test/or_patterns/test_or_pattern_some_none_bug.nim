import unittest
import std/options
include ../../pattern_matching

# ============================================================================
# REAL-WORLD PATTERN MATCHING SCENARIOS - COMPLEX OPTION HANDLING
# ============================================================================
# These tests demonstrate valuable real-world use cases for pattern matching:
# - API response processing with optional fields
# - Configuration validation with multiple valid setups
# - Data pipeline processing with varying record completeness
#
# APPROACH:
# Use separate match arms for each valid combination instead of OR patterns
# with inconsistent variable bindings. This approach:
# - Adheres to OR pattern variable consistency validation
# - Provides clear, maintainable code
# - Avoids compile-time "undeclared identifier" errors
#
# BUSINESS VALUE:
# These patterns are cleaner than nested if-elif chains for handling
# "acceptable combinations" of optional data fields.
# ============================================================================

type
  ApiResponse = object
    userId: Option[int]
    email: Option[string] 
    phone: Option[string]
    
  ConfigData = object
    dbHost: Option[string]
    dbPort: Option[int]
    configFile: Option[string]

suite "Real-World Pattern Matching - Complex Option Handling":

  test "API Response Processing - Multiple Valid Combinations":
    # Real scenario: API can return different combinations of user data
    # We want to process responses that have "sufficient information"
    let response = ApiResponse(
      userId: some(123), 
      email: some("user@example.com"), 
      phone: none(string)
    )
    
    var processed = false

    # FIXED: Use separate match arms for each valid combination
    # Each arm has its own variable bindings - no inconsistency
    match response:
      ApiResponse(userId: Some(id), email: Some(email), phone: _):
        processed = true
        # Process with id + email
      ApiResponse(userId: Some(id), email: _, phone: Some(phone)):
        processed = true
        # Process with id + phone
      ApiResponse(userId: _, email: Some(email), phone: Some(phone)):
        processed = true
        # Process with email + phone
      _:
        # Insufficient data - skip or request more info
        discard
    
    check processed == true

  test "Configuration Validation - Different Valid Setups":
    # Real scenario: App can be configured in multiple valid ways
    let config = ConfigData(
      dbHost: some("localhost"), 
      dbPort: some(5432), 
      configFile: none(string)
    )
    
    var isValid = false

    # FIXED: Use separate match arms for each valid configuration
    match config:
      ConfigData(dbHost: Some(host), dbPort: Some(port), configFile: _):
        isValid = true
        # Direct DB config
      ConfigData(dbHost: _, dbPort: _, configFile: Some(file)):
        isValid = true
        # File-based config
      ConfigData(dbHost: Some(host), dbPort: _, configFile: Some(file)):
        isValid = true
        # Hybrid config
      _:
        # Invalid configuration
        discard
    
    check isValid == true

  test "Data Pipeline - Process Records with Different Completeness":
    # Real scenario: Data pipeline processing records with varying completeness
    type
      DataRecord = object
        id: Option[string]
        timestamp: Option[int64]
        value: Option[float]
        metadata: Option[string]
    
    let record = DataRecord(
      id: some("rec1"), 
      timestamp: some(1640995200'i64), 
      value: some(42.0), 
      metadata: some("complete")
    )
    
    var canProcess = false

    # FIXED: Use separate match arms for each valid record combination
    # We need either (id + timestamp) OR (id + value) OR (timestamp + value)
    match record:
      DataRecord(id: Some(recordId), timestamp: Some(ts), value: _, metadata: _):
        canProcess = true
        # ID + timestamp
      DataRecord(id: Some(recordId), timestamp: _, value: Some(val), metadata: _):
        canProcess = true
        # ID + value
      DataRecord(id: _, timestamp: Some(ts), value: Some(val), metadata: _):
        canProcess = true
        # timestamp + value
      _:
        # Too sparse - cannot process
        discard
    
    check canProcess == true