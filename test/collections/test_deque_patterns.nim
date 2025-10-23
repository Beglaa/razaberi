import unittest
import deques
import tables
import ../../pattern_matching

suite "Deque Pattern Matching Support":
  
  test "basic deque patterns with exact length matching":
    let deq = [1, 2, 3].toDeque
    
    match deq:
      [1, 2, 3]:
        check true
      _:
        fail()
  
  test "empty deque pattern":
    let emptyDeq = initDeque[int]()
    
    match emptyDeq:
      []:
        check true
      _:
        fail()
  
  test "single element deque":
    let singleDeq = [42].toDeque
    
    match singleDeq:
      [x]:
        check x == 42
      _:
        fail()
  
  test "deque variable binding":
    let deq = ["hello", "world"].toDeque
    
    match deq:
      [first, second]:
        check first == "hello"
        check second == "world"
      _:
        fail()
  
  test "deque with wildcards":
    let deq = [1, 2, 3, 4].toDeque
    
    match deq:
      [_, x, _, y]:
        check x == 2
        check y == 4
      _:
        fail()
  
  test "deque spread patterns - head capture":
    let deq = [1, 2, 3, 4, 5].toDeque
    
    match deq:
      [*head, last]:
        check head == [1, 2, 3, 4]
        check last == 5
      _:
        fail()
  
  test "deque spread patterns - tail capture":
    let deq = [1, 2, 3, 4, 5].toDeque
    
    match deq:
      [first, *tail]:
        check first == 1
        check tail == [2, 3, 4, 5]
      _:
        fail()
  
  test "deque spread patterns - middle capture":
    let deq = [1, 2, 3, 4, 5].toDeque
    
    match deq:
      [first, *middle, last]:
        check first == 1
        check middle == [2, 3, 4]
        check last == 5
      _:
        fail()
  
  test "deque spread patterns - all capture":
    let deq = [1, 2, 3].toDeque
    
    match deq:
      [*all]:
        check all == [1, 2, 3]
      _:
        fail()
  
  test "deque default values":
    let shortDeq = [10].toDeque
    
    match shortDeq:
      [x, y = 99]:
        check x == 10
        check y == 99
      _:
        fail()
  
  test "deque with multiple defaults":
    let emptyDeq = initDeque[int]()
    
    match emptyDeq:
      [x = 1, y = 2, z = 3]:
        check x == 1
        check y == 2
        check z == 3
      _:
        fail()
  
  test "deque spread with defaults":
    let smallDeq = [100].toDeque
    
    match smallDeq:
      [first, last = 999]:
        check first == 100
        check last == 999
      _:
        fail()
  
  test "nested deque in object pattern":
    type Container = object
      items: Deque[int]
      name: string
    
    let container = Container(items: [1, 2, 3].toDeque, name: "test")
    
    match container:
      Container(items: [1, x, 3], name: "test"):
        check x == 2
      _:
        fail()
  
  test "nested deque in table pattern":
    let data = {"values": [1, 2, 3].toDeque}.toTable
    
    match data:
      {"values": [a, b, c]}:
        check a == 1
        check b == 2
        check c == 3
      _:
        fail()
  
  test "deque OR patterns":
    let deq1 = [1].toDeque
    let deq2 = [1, 2].toDeque
    
    match deq1:
      [1] | [1, 2]:
        check true
      _:
        fail()
    
    match deq2:
      [1] | [1, 2]:
        check true
      _:
        fail()
  
  test "deque @ patterns":
    let deq = [10, 20, 30].toDeque
    
    match deq:
      x @ dq:
        check x == [10, 20, 30].toDeque
        check dq == [10, 20, 30].toDeque
      _:
        fail()
  
  test "deque guards":
    let deq = [5, 10, 15].toDeque
    
    match deq:
      [x, y, z] and x < y and y < z:
        check x == 5
        check y == 10
        check z == 15
      _:
        fail()
  
  test "complex deque pattern with multiple spreads (should fail compilation)":
    # This test verifies that multiple spreads are properly rejected
    when not compiles(
      block:
        let deq = [1, 2, 3, 4].toDeque
        match deq:
          [*start, middle, *tail]:
            discard
    ):
      check true  # Multiple spreads correctly rejected
    else:
      fail()
  
  test "deque type patterns":
    let mixedData: seq[Deque[int]] = @[[1, 2].toDeque, [3, 4, 5].toDeque]
    
    match mixedData[0]:
      dq is Deque:
        check dq == [1, 2].toDeque
      _:
        fail()
  
  test "nested deque patterns":
    type SimpleContainer = object
      items: Deque[int]
    
    let container = SimpleContainer(items: [1, 2, 3].toDeque)
    
    match container:
      SimpleContainer(items: [first, second, third]):
        check first == 1
        check second == 2  
        check third == 3
      _:
        fail()
  
  test "deque performance with large collections":
    # Test that deque patterns work efficiently with larger collections
    var largeDeq = initDeque[int]()
    for i in 1..1000:
      largeDeq.addLast(i)
    
    match largeDeq:
      [1, *middle, 1000]:
        check middle.len == 998
        check middle[0] == 2
        check middle[^1] == 999
      _:
        fail()
  
  test "deque addFirst/addLast semantics":
    var deq = initDeque[string]()
    deq.addLast("last")
    deq.addFirst("first")
    deq.addLast("end")
    # deq is now ["first", "last", "end"]
    
    match deq:
      [start, middle, final]:
        check start == "first"
        check middle == "last"
        check final == "end"
      _:
        fail()
  
  test "deque conversion patterns":
    let originalSeq = @[1, 2, 3, 4]
    let deq = originalSeq.toDeque
    
    match deq:
      [first, *rest]:
        # Verify we can convert back
        let backToSeq = @[first] & rest
        check backToSeq == originalSeq
      _:
        fail()
  
  test "empty deque with defaults":
    let emptyDeq = initDeque[int]()
    
    match emptyDeq:
      [x = 10, y = 20]:
        check x == 10
        check y == 20
      _:
        fail()
  
  test "deque rest capture with **rest pattern":
    let data = {"primary": [1, 2, 3].toDeque, "secondary": [4, 5].toDeque, "backup": [6].toDeque}.toTable
    
    match data:
      {"primary": [1, x, 3], **rest}:
        check x == 2
        check rest.len == 2
        check rest.hasKey("secondary")
        check rest.hasKey("backup")
        check rest["secondary"] == [4, 5].toDeque
        check rest["backup"] == [6].toDeque
      _:
        fail()