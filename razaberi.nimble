# Package

version       = "0.1.0"
author        = "Elvis Begluk"
description   = "Pattern matching library for Nim programing language"
license       = "MIT"
srcDir        = "."
skipDirs      = @["test", "docs"]

# Dependencies

requires "nim >= 2.2.0"

# Tasks

task test, "Run all tests":
  exec "./run_all_tests.sh"

task docs, "Generate documentation":
  exec "nim doc --project --index:on --git.url:https://github.com/your-repo/razaberi --git.commit:main --outdir:docs/htmldocs pattern_matching.nim"

# Compiler settings

switch("hint", "XDeclaredButNotUsed:off")
switch("warning", "UnusedImport:off")
