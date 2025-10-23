## Helper template to test compilation failures
## check shouldNotCompile (
##   let result = match 42:
##     1: "one"
##     _ @ x: "wildcard: " & $x
##     2: "two"  # This should cause compile error
## )
template shouldNotCompile*(code: untyped): bool =
  not compiles(code)

# Helper template to test compilation success
template shouldCompile*(code: untyped): bool =
  compiles(code)