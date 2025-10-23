import unittest
import options
import ../../pattern_matching

suite "Simple Nested Option Pattern Tests":
  
  # Define types for testing
  type
    HttpResponse = object
      statusCode: int
      body: string
    
    HttpRequestState = object
      request: string
      response: Option[HttpResponse]
      status: string

  test "State machine pattern without variable binding":
    # Test the exact pattern from the failing showcase - without using the bound variable
    let state = HttpRequestState(
      request: "GET /users",
      response: some(HttpResponse(statusCode: 200, body: "OK")),
      status: "processed"
    )
    
    # Test without using the bound variable in the body
    let result = match state:
      HttpRequestState(status="processed", response=Some(_)) and state.response.get.statusCode in [200, 201]:
        "Success: " & state.response.get.body
      HttpRequestState(status="processed", response=Some(_)) and state.response.get.statusCode >= 400:
        "Error: " & state.response.get.body
      HttpRequestState(response=None()):
        "No response"
      _:
        "Unknown state"
    
    check(result == "Success: OK")

  test "Simple Some pattern detection":
    let state = HttpRequestState(
      request: "POST /data",
      response: some(HttpResponse(statusCode: 201, body: "Created")),
      status: "processed"
    )
    
    let result = match state:
      HttpRequestState(response=Some(_)):
        "Has response"
      HttpRequestState(response=None()):
        "No response"
      _:
        "Unknown"
    
    check(result == "Has response")

  test "Simple None pattern detection":
    let state = HttpRequestState(
      request: "DELETE /item",
      response: none(HttpResponse),
      status: "pending"
    )
    
    let result = match state:
      HttpRequestState(response=Some(_)):
        "Has response"
      HttpRequestState(response=None()):
        "No response"
      _:
        "Unknown"
    
    check(result == "No response")

  test "Option pattern with field access":
    let state = HttpRequestState(
      request: "GET /test",
      response: some(HttpResponse(statusCode: 404, body: "Not Found")),
      status: "error"
    )
    
    # Access the field directly rather than using bound variable
    let result = match state:
      HttpRequestState(response=Some(_), status="error"):
        "Error response: " & state.response.get.body
      HttpRequestState(response=Some(_)):
        "Success response"
      HttpRequestState(response=None()):
        "No response"
      _:
        "Unknown"
    
    check(result == "Error response: Not Found")