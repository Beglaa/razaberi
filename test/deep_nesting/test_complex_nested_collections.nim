import unittest
import std/tables
import std/sets
import ../../pattern_matching

{.push warning[UnusedImport]: off.}
{.push hint[XDeclaredButNotUsed]: off.}

# Hunt for new bugs: Complex nested collections + empty collection edge cases
suite "Complex Nested Collections Bug Hunt":

  test "should handle seq -> table -> tuple -> table nesting":
    type
      # Complex nested structure: seq[table[string, tuple[table[string, int], bool]]]
      InnerTable = Table[string, int]
      MiddleTuple = tuple[data: InnerTable, active: bool]
      MiddleTable = Table[string, MiddleTuple]
      OuterSeq = seq[MiddleTable]
      
      Container = object
        collections: OuterSeq
        metadata: string
    
    # Create test data
    var innerTab1 = initTable[string, int]()
    innerTab1["count"] = 42
    innerTab1["limit"] = 100
    
    var innerTab2 = initTable[string, int]()
    innerTab2["min"] = 5
    innerTab2["max"] = 95
    
    var middleTab1 = initTable[string, MiddleTuple]()
    middleTab1["config1"] = (data: innerTab1, active: true)
    middleTab1["config2"] = (data: innerTab2, active: false)
    
    var middleTab2 = initTable[string, MiddleTuple]()
    middleTab2["backup"] = (data: innerTab1, active: true)
    
    let testData = Container(
      collections: @[middleTab1, middleTab2],
      metadata: "complex_test"
    )
    
    # Test the complex nested pattern
    let result = match testData:
      Container(
        collections: [
          {"config1": (data: {"count": countVal, **_}, active: isActive1), **restConfigs},
          {"backup": (data: backupData, active: isActive2), **_}
        ],
        metadata: meta
      ) and countVal == 42 and isActive1 and isActive2:
        "Complex: count=" & $countVal & " active1=" & $isActive1 & " active2=" & $isActive2 & " meta=" & meta
      _: "Complex pattern failed"
    
    check(result == "Complex: count=42 active1=true active2=true meta=complex_test")

  test "should handle empty sequence patterns":
    type
      EmptySeqContainer = object
        items: seq[int]
        name: string
    
    # Test with empty sequence
    let emptyData = EmptySeqContainer(items: @[], name: "empty")
    
    let result1 = match emptyData:
      EmptySeqContainer(items: [], name: n):
        "Empty seq: " & n
      _: "Empty seq failed"
    
    check(result1 == "Empty seq: empty")
    
    # Test with non-empty sequence
    let nonEmptyData = EmptySeqContainer(items: @[1, 2, 3], name: "filled")
    
    let result2 = match nonEmptyData:
      EmptySeqContainer(items: [], name: _):
        "Should not match non-empty"
      EmptySeqContainer(items: [first, *rest], name: n):
        "Non-empty seq: first=" & $first & " rest=" & $rest.len & " name=" & n
      _: "Non-empty seq failed"
    
    check(result2 == "Non-empty seq: first=1 rest=2 name=filled")

  test "should handle empty table patterns":
    type
      EmptyTableContainer = object
        config: Table[string, int]
        status: string
    
    # Test with empty table
    let emptyTableData = EmptyTableContainer(
      config: initTable[string, int](),
      status: "empty"
    )
    
    let result1 = match emptyTableData:
      EmptyTableContainer(config: {}, status: s):
        "Empty table: " & s
      _: "Empty table failed"
    
    check(result1 == "Empty table: empty")
    
    # Test with non-empty table
    var nonEmptyTable = initTable[string, int]()
    nonEmptyTable["key1"] = 10
    nonEmptyTable["key2"] = 20
    
    let nonEmptyTableData = EmptyTableContainer(
      config: nonEmptyTable,
      status: "filled"
    )
    
    let result2 = match nonEmptyTableData:
      EmptyTableContainer(config: {}, status: _):
        "Should not match non-empty"
      EmptyTableContainer(config: {"key1": val1, **rest}, status: s):
        "Non-empty table: key1=" & $val1 & " rest=" & $rest.len & " status=" & s
      _: "Non-empty table failed"
    
    check(result2 == "Non-empty table: key1=10 rest=1 status=filled")

  test "should handle empty set patterns":
    type
      EmptySetContainer = object
        tags: set[char]
        permissions: set[int8]
        name: string
    
    # Test with empty sets
    let emptySetData = EmptySetContainer(
      tags: {},
      permissions: {},
      name: "empty_sets"
    )
    
    let result1 = match emptySetData:
      EmptySetContainer(tags: {}, permissions: {}, name: n):
        "Empty sets: " & n
      _: "Empty sets failed"
    
    check(result1 == "Empty sets: empty_sets")
    
    # Test with non-empty sets
    let nonEmptySetData = EmptySetContainer(
      tags: {'a', 'b', 'c'},
      permissions: {1, 2, 3, 4},
      name: "filled_sets"
    )
    
    let result2 = match nonEmptySetData:
      EmptySetContainer(tags: {}, permissions: {}, name: _):
        "Should not match non-empty"
      EmptySetContainer(tags: {'a', 'b'}, permissions: {1, 2}, name: n):
        "Partial set match: " & n
      _: "Non-empty sets failed"
    
    check(result2 == "Non-empty sets failed")  # This might reveal a bug

  test "should handle nested empty collections":
    type
      # Mix empty and non-empty collections
      NestedEmpty = object
        seqs: seq[seq[int]]
        tables: seq[Table[string, int]]
        sets: seq[set[char]]
    
    # Create data with mix of empty and non-empty nested collections
    var table1 = initTable[string, int]()
    table1["data"] = 42
    
    let mixedData = NestedEmpty(
      seqs: @[
        @[],           # Empty inner seq
        @[1, 2, 3]     # Non-empty inner seq
      ],
      tables: @[
        initTable[string, int](),  # Empty table
        table1                     # Non-empty table
      ],
      sets: @[
        {},            # Empty set
        {'x', 'y'}     # Non-empty set
      ]
    )
    
    let result = match mixedData:
      NestedEmpty(
        seqs: [[], [first, *rest]],
        tables: [{}, {"data": dataVal, **_}],
        sets: [{}, {'x', 'y'}]
      ) and first == 1 and dataVal == 42:
        "Mixed empty/non-empty: first=" & $first & " data=" & $dataVal & " rest=" & $rest.len
      _: "Mixed collections failed"
    
    check(result == "Mixed empty/non-empty: first=1 data=42 rest=2")

  test "should handle table -> seq -> tuple -> table edge case":
    # Reverse the nesting order to test different code paths
    type
      InnerTable = Table[string, string]
      MiddleTuple = tuple[id: int, config: InnerTable]
      MiddleSeq = seq[MiddleTuple]
      OuterTable = Table[string, MiddleSeq]
      
      ReverseContainer = object
        data: OuterTable
        version: int
    
    # Create reverse nested data
    var innerConfig = initTable[string, string]()
    innerConfig["host"] = "localhost"
    innerConfig["port"] = "8080"
    
    var outerData = initTable[string, MiddleSeq]()
    outerData["servers"] = @[
      (id: 1, config: innerConfig),
      (id: 2, config: initTable[string, string]())  # Empty inner table
    ]
    
    let reverseData = ReverseContainer(
      data: outerData,
      version: 2
    )
    
    let result = match reverseData:
      ReverseContainer(
        data: {
          "servers": [
            (id: serverId1, config: {"host": hostVal, "port": portVal}),
            (id: serverId2, config: {})
          ]
        },
        version: ver
      ) and serverId1 == 1 and serverId2 == 2 and ver >= 2:
        "Reverse: server1=" & $serverId1 & " host=" & hostVal & " port=" & portVal & " server2=" & $serverId2
      _: "Reverse nesting failed"
    
    check(result == "Reverse: server1=1 host=localhost port=8080 server2=2")

  test "should handle deeply nested empty collection at various levels":
    type
      Level4 = Table[string, int]
      Level3 = tuple[data: Level4, empty_seq: seq[int]]
      Level2 = Table[string, Level3]  
      Level1 = seq[Level2]
      
      DeepContainer = object
        deep: Level1
        flag: bool
    
    # Create data with empty collections at different nesting levels
    var level4_empty = initTable[string, int]()  # Empty at level 4
    var level4_full = initTable[string, int]()
    level4_full["value"] = 99
    
    var level2_1 = initTable[string, Level3]()
    level2_1["config1"] = (data: level4_empty, empty_seq: @[])    # Empty collections
    level2_1["config2"] = (data: level4_full, empty_seq: @[1, 2]) # Non-empty collections
    
    var level2_2 = initTable[string, Level3]()  # Empty level2 table
    
    let deepData = DeepContainer(
      deep: @[level2_1, level2_2],  # Second element is empty table
      flag: true
    )
    
    let result = match deepData:
      DeepContainer(
        deep: [
          {
            "config1": (data: {}, empty_seq: []),
            "config2": (data: {"value": val}, empty_seq: [a, b])
          },
          {}  # Empty table at level 2
        ],
        flag: isSet
      ) and val == 99 and a == 1 and b == 2 and isSet:
        "Deep empty: val=" & $val & " seq=(" & $a & "," & $b & ") flag=" & $isSet
      _: "Deep empty collections failed"
    
    check(result == "Deep empty: val=99 seq=(1,2) flag=true")