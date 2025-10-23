import unittest
import ../../variant_dsl
import ../../pattern_matching

##[
Multi-Field Constructor Tests
==============================

Tests that variant DSL supports constructors with multiple fields.
This is a core feature for real-world use cases where variant branches
need to carry multiple pieces of data.
]##

suite "Multi-field Constructor Tests":

  test "two fields in constructor":
    variant Status:
      Active(count: int, some_other_field: string)
      Inactive()

    # Construction
    let active = Status.Active(42, "running")
    let inactive = Status.Inactive()

    # Field access
    check active.kind == skActive
    check active.count == 42
    check active.some_other_field == "running"
    check inactive.kind == skInactive

    # Pattern matching
    let result1 = match active:
      Status.Active(c, s): c + s.len
      Status.Inactive(): 0

    let result2 = match inactive:
      Status.Active(c, s): c + s.len
      Status.Inactive(): 0

    check result1 == 49  # 42 + "running".len (7)
    check result2 == 0

  test "three fields in constructor":
    variant Response:
      Success(code: int, message: string, data: string)
      Error(errCode: int, errMsg: string, stackTrace: string)
      Pending(requestId: int, status: string, progress: float)

    let success = Response.Success(200, "OK", "result data")
    let error = Response.Error(500, "Internal Error", "stack trace here")
    let pending = Response.Pending(12345, "processing", 0.75)

    # Field access
    check success.code == 200
    check success.message == "OK"
    check success.data == "result data"

    check error.errCode == 500
    check error.errMsg == "Internal Error"
    check error.stackTrace == "stack trace here"

    check pending.requestId == 12345
    check pending.status == "processing"
    check pending.progress == 0.75

    # Pattern matching with all three fields
    let successDesc = match success:
      Response.Success(c, m, d): $c & ": " & m & " - " & d
      Response.Error(ec, em, st): $ec & ": " & em
      Response.Pending(id, s, p): $id & " - " & s & " (" & $p & ")"

    check successDesc == "200: OK - result data"

  test "mixed field types":
    variant Config:
      Database(host: string, port: int, ssl: bool, timeout: float)
      Cache(size: int, enabled: bool)

    let db = Config.Database("localhost", 5432, true, 30.0)
    let cache = Config.Cache(1024, true)

    check db.host == "localhost"
    check db.port == 5432
    check db.ssl == true
    check db.timeout == 30.0

    check cache.size == 1024
    check cache.enabled == true

    # Pattern matching
    let dbInfo = match db:
      Config.Database(h, p, ssl, t): h & ":" & $p & " (SSL: " & $ssl & ")"
      Config.Cache(s, e): "Cache: " & $s

    check dbInfo == "localhost:5432 (SSL: true)"
