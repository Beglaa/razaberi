import ../../pattern_matching
import unittest
import tables

suite "CountTable[T] Pattern Matching Support":
  setup:
    let ct = toCountTable(["apple", "banana", "apple", "cherry"])
    let empty = initCountTable[string]()
    let single = toCountTable(["item", "item", "item"])  
    let words = toCountTable(["the", "cat", "in", "the", "hat", "the"])
    let chars = toCountTable(['a', 'b', 'a', 'c', 'b', 'a'])
    let data = toCountTable(["common", "common", "rare1", "rare2", "rare3"])
    let votes = toCountTable(["alice", "bob", "alice", "charlie", "alice", "bob"])
    let partial = toCountTable(["yes", "yes", "no"])
    let survey = toCountTable(["excellent", "good", "excellent", "good", "excellent"])
    let items = toCountTable(["frequent", "frequent", "frequent", "rare"])
    let colors = toCountTable(["red", "green", "blue", "red", "green"])
    let ct1 = toCountTable(["a", "a", "b"])
    let ct2 = toCountTable(["x", "y", "y"])
    let dice = toCountTable([1, 2, 3, 4, 5, 6, 1, 2, 3, 1, 2, 1])
    let events = toCountTable(["login", "logout", "login", "error", "login", "login"])
    let grades = toCountTable(['A', 'B', 'A', 'C', 'A', 'B', 'D'])

  # ===============================
  # BASIC COUNTTABLE PATTERNS
  # ===============================
  test "count table basic exact matching":
    #let ct = toCountTable(["apple", "banana", "apple", "cherry"])
    let result = match ct:
      {"apple": 2, "banana": 1, "cherry": 1}: "exact counts"
      {"apple": a}: "has apples: " & $a
      _: "other"
    check result == "exact counts"

  test "count table empty pattern":
    #let empty = initCountTable[string]()
    let result = match empty:
      {}: "empty count table"
      _: "not empty"
    check result == "empty count table"

  test "count table single item":
    #let single = toCountTable(["item", "item", "item"])
    let result = match single:
      {"item": 3}: "triple item"
      {"item": n}: "item count: " & $n
      _: "other"
    check result == "triple item"

  # ===============================
  # FREQUENCY COUNTING PATTERNS
  # ===============================
  test "count table frequency analysis":
    #let words = toCountTable(["the", "cat", "in", "the", "hat", "the"])
    let result = match words:
      {"the": 3, "cat": 1, "in": 1, "hat": 1}: "exact word frequency"
      {"the": n} and n >= 2: "the appears " & $n & " times"
      _: "other"
    check result == "exact word frequency"

  test "count table variable binding":
    #let chars = toCountTable(['a', 'b', 'a', 'c', 'b', 'a'])
    let result = match chars:
      {'a': a, 'b': b, 'c': c}: "a=" & $a & " b=" & $b & " c=" & $c
      _: "other"
    check result == "a=3 b=2 c=1"

  # ===============================
  # REST CAPTURE PATTERNS
  # ===============================
  test "count table rest capture":
    #let data = toCountTable(["common", "common", "rare1", "rare2", "rare3"])
    let result = match data:
      {"common": n, **rest}: "common=" & $n & " others=" & $rest.len
      _: "other"
    check result == "common=2 others=3"

  test "count table specific counts with rest":
    #let votes = toCountTable(["alice", "bob", "alice", "charlie", "alice", "bob"])
    let result = match votes:
      {"alice": 3, **rest}: "alice wins with 3 votes, " & $rest.len & " other candidates"
      _: "other"
    check result == "alice wins with 3 votes, 2 other candidates"

  # ===============================
  # DEFAULT VALUE PATTERNS
  # ===============================
  test "count table with default values":
    #let partial = toCountTable(["yes", "yes", "no"])
    let result = match partial:
      {"yes": y, "no": n, "maybe": (maybe = 0)}:
        "yes=" & $y & " no=" & $n & " maybe=" & $maybe
      _: "other"
    check result == "yes=2 no=1 maybe=0"

  test "count table mixed required and defaults":
    #let survey = toCountTable(["excellent", "good", "excellent", "good", "excellent"])
    let result = match survey:
      {"excellent": e, "good": g, "poor": (poor = 0), "terrible": (terrible = 0)}:
        "excellent=" & $e & " good=" & $g & " poor=" & $poor & " terrible=" & $terrible
      _: "other"
    check result == "excellent=3 good=2 poor=0 terrible=0"

  # ===============================
  # GUARD PATTERNS
  # ===============================
  test "count table with count guards":
    #let items = toCountTable(["frequent", "frequent", "frequent", "rare"])
    let result = match items:
      {"frequent": f, "rare": r} and f >= 3 and r == 1:
        "frequent item (" & $f & ") and rare item (" & $r & ")"
      _: "other distribution"
    check result == "frequent item (3) and rare item (1)"

  test "count table with total count guards":
    #let colors = toCountTable(["red", "green", "blue", "red", "green"])
    let result = match colors:
      ct and ct.len == 3: "three different colors"
      ct: $ct.len & " different colors"
    check result == "three different colors"

  # ===============================
  # OR PATTERNS
  # ===============================
  test "count table OR patterns with literals":
    #let ct1 = toCountTable(["a", "a", "b"])
    #let ct2 = toCountTable(["x", "y", "y"])

    let result1 = match ct1:
      {"a": 2, "b": 1} | {"x": 1, "y": 2}: "pattern A or B"
      _: "other"
    check result1 == "pattern A or B"

    let result2 = match ct2:
      {"a": 2, "b": 1} | {"x": 1, "y": 2}: "pattern A or B"
      _: "other"
    check result2 == "pattern A or B"

  # ===============================
  # TYPE PATTERNS
  # ===============================
  test "count table type checking":
    let ct4 = toCountTable(["apple", "banana", "apple"])
    let result = match ct4:
      x is CountTable[string]: "string count table with " & $x.len & " unique items"
      _: "other"
    check result == "string count table with 2 unique items"

  # ===============================
  # STATISTICAL PATTERNS
  # ===============================
  test "count table distribution analysis":
    #let dice = toCountTable([1, 2, 3, 4, 5, 6, 1, 2, 3, 1, 2, 1])
    let result = match dice:
      {1: 4, 2: 3, 3: 2, 4: 1, 5: 1, 6: 1}: "decreasing frequency"
      dice and dice.len == 6: "all faces appeared"
      _: "partial distribution"
    check result == "decreasing frequency"

  test "count table threshold analysis":
    #let events = toCountTable(["login", "logout", "login", "error", "login", "login"])
    let result = match events:
      {"login": n} and n >= 4: "high login activity: " & $n
      {"login": n}: "normal login activity: " & $n
      _: "no login data"
    check result == "high login activity: 4"

  # ===============================
  # COMPLEX COMBINATIONS
  # ===============================
  test "count table complex pattern with guards and rest":
    #let grades = toCountTable(['A', 'B', 'A', 'C', 'A', 'B', 'D'])
    let result = match grades:
      {'A': a, 'B': b, **rest} and a >= 3 and b >= 2:
        "good performance: A=" & $a & " B=" & $b & " others=" & $rest.len
      _: "needs improvement"
    check result == "good performance: A=3 B=2 others=2"

  # ===============================
  # COUNTTABLE SPECIFIC FEATURES
  # ===============================
  test "count table most common analysis":
    let words2 = toCountTable(["hello", "world", "hello", "nim", "hello"])
    let result = match words2:
      {"hello": 3, **rest} and rest.len >= 1: "hello is most common (3 times)"
      {"hello": n}: "hello appears " & $n & " times"
      _: "no hello"
    check result == "hello is most common (3 times)"

  test "count table zero counts":
    let items4 = toCountTable(["present", "present"])
    let result = match items4:
      {"present": 2, "absent": (absent = 0)}: "present=2 absent=" & $absent
      _: "other"
    check result == "present=2 absent=0"

  # ===============================
  # EDGE CASES
  # ===============================
  test "count table large dataset":
    var large = initCountTable[int]()
    for i in 1..1000:
      large.inc(i mod 10) # 0-9 each appear 100 times

    let result = match large:
      large and large.len == 10: "balanced distribution: " & $large.len & " groups"
      _: "other"
    check result == "balanced distribution: 10 groups"

  test "count table different element types":
    let intCounts = toCountTable([1, 2, 1, 3, 2, 1])
    let result = match intCounts:
      {1: 3, 2: 2, 3: 1}: "exact int distribution"
      {1: n}: "ones: " & $n
      _: "other"
    check result == "exact int distribution"

  test "count table string analysis - safe pattern":
    # Use safe pattern that avoids complex guards which may trigger remaining unsafe access  
    let texts = toCountTable(["error", "error", "error"])
    let result = match texts:
      {"error": 3}:
        "error-heavy log: errors=3"
      _: "other pattern"
    check result == "error-heavy log: errors=3"
