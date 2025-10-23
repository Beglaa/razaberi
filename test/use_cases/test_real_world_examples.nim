import unittest
import ../../pattern_matching

# Test 1: Simple routing patterns
proc routeSimple(request: string): string =
  match request:
    "GET /": "homepage"
    "GET /api": "api"
    "POST /users": "create"
    _: "not_found"

# Test 2: Status handling
proc handleStatus(status: string): string =
  match status:
    "success": "ok"
    "error": "failed" 
    _: "unknown"

# Test 3: Tuple patterns for more complex routing
proc routeTuple(data: (string, string)): string =
  match data:
    ("GET", "/"): "homepage_tuple"
    ("POST", "/api"): "api_post"
    _: "not_found_tuple"

suite "Real-World Examples":

  test "Simple routing works":
    check routeSimple("GET /") == "homepage"
    check routeSimple("GET /api") == "api"
    check routeSimple("POST /users") == "create"
    check routeSimple("DELETE /test") == "not_found"

  test "Status handling works":
    check handleStatus("success") == "ok"
    check handleStatus("error") == "failed"
    check handleStatus("unknown") == "unknown"

  test "Tuple routing works":
    check routeTuple(("GET", "/")) == "homepage_tuple"
    check routeTuple(("POST", "/api")) == "api_post"
    check routeTuple(("DELETE", "/test")) == "not_found_tuple"