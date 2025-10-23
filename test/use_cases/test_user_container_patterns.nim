import unittest
import tables
import sequtils  # For filter function
import ../../pattern_matching

type
  User = object
    id: int
    name: string
    age: int

  ContainerKind = enum
    ckSeq, ckTable

  UserContainer = object
    case kind: ContainerKind
    of ckSeq:
      users: seq[User]
    of ckTable:
      userTable: Table[int, User]

# Helper constructors
proc newUserSeqContainer(users: seq[User]): UserContainer =
  UserContainer(kind: ckSeq, users: users)

proc newUserTableContainer(userTable: Table[int, User]): UserContainer =
  UserContainer(kind: ckTable, userTable: userTable)

proc newEmptySeqContainer(): UserContainer =
  UserContainer(kind: ckSeq, users: @[])

proc newEmptyTableContainer(): UserContainer =
  UserContainer(kind: ckTable, userTable: initTable[int, User]())

suite "User Container Pattern Matching Tests":
  let tom = User(id: 1, name: "Tom", age: 25)
  let alice = User(id: 2, name: "Alice", age: 30)
  let bob = User(id: 3, name: "Bob", age: 22)
  let anotherTom = User(id: 4, name: "Tom", age: 35)

  test "match seq container with Tom as first user":
    let container = newUserSeqContainer(@[tom, alice, bob, anotherTom])

    let result = match container:
      UserContainer(kind: ckSeq, users: [User(name: "Tom"), *rest]): "found Tom as first user with " & $rest.len & " others"
      UserContainer(kind: ckSeq, users: users): "seq with " & $users.len & " users"
      _: "no match"

    check result == "found Tom as first user with 3 others"

  test "match table container with specific user ID":
    var userTable = initTable[int, User]()
    userTable[1] = tom
    userTable[2] = alice
    userTable[3] = bob
    userTable[4] = anotherTom

    let container = newUserTableContainer(userTable)

    let result = match container:
      UserContainer(kind: ckTable, userTable: {1: User(name: "Tom")}): "found Tom with id 1"
      UserContainer(kind: ckTable, userTable: table): "table with " & $table.len & " users"
      _: "no match"

    check result == "found Tom with id 1"

  test "match empty seq container":
    let container = newEmptySeqContainer()

    let result = match container:
      UserContainer(kind: ckSeq, users: []): "empty_seq"
      UserContainer(kind: ckSeq, users: [User(name: "Tom")]): "has_tom"
      _: "other"

    check result == "empty_seq"

  test "match empty table container":
    let container = newEmptyTableContainer()

    let result = match container:
      UserContainer(kind: ckTable, userTable: {}): "empty_table"
      UserContainer(kind: ckTable, userTable: table): "has " & $table.len & " users"
      _: "other"

    check result == "empty_table"

  test "comprehensive pattern matching with all cases":
    let seqContainer = newUserSeqContainer(@[tom, alice])
    var tableForContainer = initTable[int, User]()
    tableForContainer[1] = tom
    tableForContainer[2] = alice
    let tableContainer = newUserTableContainer(tableForContainer)
    let emptySeqContainer = newEmptySeqContainer()
    let emptyTableContainer = newEmptyTableContainer()

    # Test seq with Tom
    let seqResult = match seqContainer:
      UserContainer(kind: ckSeq, users: []): "empty_seq"
      UserContainer(kind: ckSeq, users: [User(name: "Tom"), *rest]): "seq_has_tom"
      _: "other"

    check seqResult == "seq_has_tom"

    # Test table with Tom
    let tableResult = match tableContainer:
      UserContainer(kind: ckTable, userTable: {}): "empty_table"
      UserContainer(kind: ckTable, userTable: {1: User(name: "Tom")}): "table_has_tom"
      _: "other"

    check tableResult == "table_has_tom"

    # Test empty seq
    let emptySeqResult = match emptySeqContainer:
      UserContainer(kind: ckSeq, users: []): "empty_seq"
      UserContainer(kind: ckSeq, users: [User(name: "Tom"), *rest]): "seq_has_tom"
      _: "other"

    check emptySeqResult == "empty_seq"

    # Test empty table
    let emptyTableResult = match emptyTableContainer:
      UserContainer(kind: ckTable, userTable: {}): "empty_table"
      UserContainer(kind: ckTable, userTable: {1: User(name: "Tom")}): "table_has_tom"
      _: "other"

    check emptyTableResult == "empty_table"

  test "extract all Toms from sequence container":
    let container = newUserSeqContainer(@[tom, alice, bob, anotherTom])

    # Check if first user in container is named Tom (structural pattern matching)
    let first_is_tom = match container.users:
      [User(name: "Tom"), *rest]: true
      _: false

    check first_is_tom == true  # Tom is first

    # To get all Toms, use regular Nim filter:
    let allToms = container.users.filter(proc(u: User): bool = u.name == "Tom")
    check allToms.len == 2
    check allToms[0].name == "Tom"
    check allToms[1].name == "Tom"
    check allToms[0].id == 1
    check allToms[1].id == 4

  test "structural matching checks first element only":
    let users = @[tom, alice, bob, anotherTom]

    let first_is_tom = match users:
      [User(name: "Tom"), *rest]: true
      _: false

    check first_is_tom == true  # First user is Tom

    # To get all Toms, use regular Nim filter:
    let allToms = users.filter(proc(u: User): bool = u.name == "Tom")
    check allToms.len == 2
    check allToms[0].name == "Tom"
    check allToms[1].name == "Tom"
    check allToms[0].age == 25
    check allToms[1].age == 35

  test "structural matching with age condition checks first element":
    let container = newUserSeqContainer(@[tom, alice, bob, anotherTom])

    # Check if first user is older than 30 (structural pattern matching)
    let first_is_senior = match container.users:
      [User(age > 30), *rest]: true
      _: false

    check first_is_senior == false  # Tom (25) is not > 30

    # To filter users by age, use regular Nim filter:
    let olderUsers = container.users.filter(proc(u: User): bool = u.age > 30)
    check olderUsers.len == 1  # Only anotherTom (35) > 30
    check olderUsers[0].name == "Tom"
    check olderUsers[0].age == 35