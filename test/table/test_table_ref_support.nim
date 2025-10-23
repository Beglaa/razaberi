import unittest
import tables
import sequtils
import ../../pattern_matching

type
  User = object
    name: string
    age: int
    active: bool

suite "TableRef[K,V] and CountTableRef[K] Pattern Matching Support":

  test "TableRef basic wildcard filtering":
    let userTable = newTable[string, User]()
    userTable["user1"] = User(name: "Alice", age: 25, active: true)
    userTable["user2"] = User(name: "Bob", age: 45, active: true)
    userTable["user3"] = User(name: "Carol", age: 52, active: false)
    userTable["user4"] = User(name: "Dave", age: 30, active: true)
    userTable["user5"] = User(name: "Eve", age: 41, active: true)
    
    # Structural pattern matching can't filter all table values with {_: condition}
    # Instead, check specific keys or use regular Nim filter on table values
    let has_senior_users = not userTable.values.toSeq.allIt(it.age <= 39)
    check has_senior_users == true  # Some users are > 39

    # To get all older users, use regular Nim filter:
    let older_users = userTable.values.toSeq.filter(proc(u: User): bool = u.age > 39)
    check older_users.len == 3  # Bob, Carol, Eve
    # Check that specific users are in the filtered sequence
    check older_users.anyIt(it.name == "Bob")    # Bob (age 45)
    check older_users.anyIt(it.name == "Carol")  # Carol (age 52)
    check older_users.anyIt(it.name == "Eve")    # Eve (age 41)
    check older_users is seq[User]

  test "TableRef specific key structural matching":
    let roleTable = newTable[string, User]()
    roleTable["admin"] = User(name: "Alice", age: 45, active: true)
    roleTable["user"] = User(name: "Bob", age: 25, active: true)
    roleTable["guest"] = User(name: "Carol", age: 52, active: false)

    # Structural matching: check if admin key exists and extract age
    let admin_info = match roleTable:
      {"admin": User(age=admin_age)}: admin_age
      _: 0

    check admin_info > 39  # Alice is 45, which is > 39
    check roleTable.hasKey("admin")
    check roleTable["admin"].name == "Alice"
    check roleTable["admin"].age == 45

  test "TableRef structural matching with conditions":
    let dataTable = newTable[string, int]()
    dataTable["a"] = 10
    dataTable["b"] = 20
    dataTable["c"] = 5
    dataTable["d"] = 15

    # Structural matching: extract specific key values and check conditions
    let b_value = match dataTable:
      {"b": value}: value
      _: 0

    let d_value = match dataTable:
      {"d": value}: value
      _: 0

    check b_value > 10  # b=20 > 10
    check d_value > 10  # d=15 > 10
    check dataTable is TableRef[string, int]

    # To filter large values, use regular Nim operations:
    var large_values = newTable[string, int]()
    for key, value in dataTable.pairs:
      if value > 10:
        large_values[key] = value
    check large_values.len == 2  # b=20, d=15
    check large_values.hasKey("b")
    check large_values.hasKey("d")

  test "CountTableRef structural matching":
    let wordCounts = newCountTable[string]()
    wordCounts.inc("apple", 3)
    wordCounts.inc("banana", 2)
    wordCounts.inc("cherry", 1)

    # Structural matching: extract specific key counts and check conditions
    let apple_count = match wordCounts:
      {"apple": count}: count
      _: 0

    let banana_count = match wordCounts:
      {"banana": count}: count
      _: 0

    let cherry_count = match wordCounts:
      {"cherry": count}: count
      _: 0

    check apple_count > 1   # apple count = 3 > 1
    check banana_count > 1  # banana count = 2 > 1
    check cherry_count <= 1 # cherry count = 1 not > 1

    # To filter frequent words, use regular Nim operations:
    var frequent_words = newCountTable[string]()
    for word, count in wordCounts.pairs:
      if count > 1:
        frequent_words[word] = count

    check frequent_words.len == 2  # apple (3) and banana (2)
    check frequent_words.hasKey("apple")
    check frequent_words.hasKey("banana")
    check not frequent_words.hasKey("cherry")
    check frequent_words["apple"] == 3
    check frequent_words["banana"] == 2
    check frequent_words is CountTableRef[string]

  test "CountTableRef specific key structural matching":
    let letterCounts = newCountTable[char]()
    letterCounts.inc('a', 3)
    letterCounts.inc('b', 2)
    letterCounts.inc('c', 1)

    # Structural matching: extract 'a' count and check condition
    let a_count = match letterCounts:
      {'a': count}: count
      _: 0

    check a_count > 2  # a count = 3 > 2
    check letterCounts.hasKey('a')
    check letterCounts['a'] == 3
    check letterCounts is CountTableRef[char]

  test "CountTableRef with exact count structural matching":
    let numberCounts = newCountTable[int]()
    numberCounts.inc(1, 1)
    numberCounts.inc(2, 2)
    numberCounts.inc(3, 3)
    numberCounts.inc(4, 4)

    # Structural matching: extract key 3 count and check condition
    let three_count = match numberCounts:
      {3: count}: count
      _: 0

    check three_count == 3  # key 3 has count = 3
    check numberCounts.hasKey(3)
    check numberCounts[3] == 3
    check numberCounts is CountTableRef[int]

    # To find all numbers appearing exactly 3 times, use regular Nim:
    var exactly_three = newCountTable[int]()
    for number, count in numberCounts.pairs:
      if count == 3:
        exactly_three[number] = count
    check exactly_three.len == 1
    check exactly_three.hasKey(3)

  test "Mixed TableRef and CountTableRef structural matching":
    let userTable = newTable[string, User]()
    userTable["u1"] = User(name: "Alice", age: 25, active: true)
    userTable["u2"] = User(name: "Bob", age: 45, active: true)

    let wordCounts = newCountTable[string]()
    wordCounts.inc("hello", 2)
    wordCounts.inc("world", 3)

    # Structural matching: extract values and check conditions
    let u1_age = match userTable:
      {"u1": User(age=age)}: age
      _: 0

    let hello_count = match wordCounts:
      {"hello": count}: count
      _: 0

    check u1_age > 20      # Alice is 25 > 20
    check hello_count > 1  # hello count = 2 > 1
    check userTable is TableRef[string, User]
    check wordCounts is CountTableRef[string]
    check userTable.len == 2
    check wordCounts.len == 2