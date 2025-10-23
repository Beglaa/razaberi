import unittest
import strutils
import ../../pattern_matching

suite "Deep Mixed Pattern isSome Bug":

  test "should handle nested object-tuple-sequence patterns without isSome error":
    ## BUG DISCOVERED: Pattern matching fails with "undeclared field: 'isSome'" error
    ## when processing deeply nested patterns combining objects, tuples, and sequences.
    ##
    ## **Root Cause**: The pattern matching implementation incorrectly assumes Option types
    ## exist in certain nested pattern combinations, specifically when processing:
    ## 1. Object containing tuple
    ## 2. Tuple containing another tuple
    ## 3. Inner tuple containing sequence
    ## 4. Sequence of tuples with named fields
    ## 5. Guard conditions accessing sequence elements
    ##
    ## **Error Location**: pattern_matching.nim:11156 - tries to access .isSome on non-Option type
    ##
    ## **Pattern Structure That Triggers Bug**:
    ## ```nim
    ## Object(
    ##   tup: tuple[
    ##     inner: tuple[
    ##       arr: seq[tuple[x: int, y: string]]
    ##     ]
    ##   ]
    ## )
    ## ```
    ##
    ## **Expected Behavior**: Pattern should match successfully and bind variables correctly
    ## **Actual Behavior**: Compilation fails with "undeclared field: 'isSome'" error
    ##
    ## **Impact**: This bug affects any complex nested patterns mixing objects, tuples,
    ## and sequences with guard conditions, limiting the library's real-world usage for
    ## complex data structures like API responses, configuration files, and domain models.

    type
      # Structure that triggers the bug: Object -> Tuple -> Tuple -> Sequence -> Tuple
      NestedMixed = object
        data: tuple[
          inner: tuple[
            item_list: seq[tuple[id: int, name: string, value: float]]
          ]
        ]

    let complex_data = NestedMixed(
      data: (
        inner: (
          item_list: @[
            (id: 1, name: "first", value: 10.5),
            (id: 2, name: "second", value: 20.5),
            (id: 3, name: "third", value: 30.5)
          ]
        )
      )
    )

    # This pattern matching expression should work but currently fails
    # with "undeclared field: 'isSome'" compilation error
    let result = match complex_data:
      NestedMixed(data: (inner: (item_list: matched_items))) and
        matched_items.len > 2 and
        matched_items[0].id == 1 and
        matched_items[1].name == "second" and
        matched_items[2].value > 25.0 :
        "SUCCESS: Complex nested pattern matched - found " & $matched_items.len &
        " items, first ID: " & $matched_items[0].id &
        ", second name: " & matched_items[1].name &
        ", third value: " & $matched_items[2].value
      _ : "FAILED: Pattern did not match"

    # Test should pass when bug is fixed
    check(result.startsWith("SUCCESS: Complex nested pattern matched"))

  test "should handle variations of the nested pattern bug":
    ## Additional test cases to verify the bug fix covers all variations
    ## of the problematic pattern structure

    type
      # Variation 1: Different field types in sequence tuples
      VariantA = object
        nested: tuple[
          level2: tuple[
            data: seq[tuple[active: bool, count: int]]
          ]
        ]

      # Variation 2: More complex sequence element structure
      VariantB = object
        outer: tuple[
          middle: tuple[
            records: seq[tuple[key: string, metadata: tuple[version: int, flags: bool]]]
          ]
        ]

    let variant_a = VariantA(
      nested: (
        level2: (
          data: @[(active: true, count: 42), (active: false, count: 84)]
        )
      )
    )

    let variant_b = VariantB(
      outer: (
        middle: (
          records: @[
            (key: "item1", metadata: (version: 1, flags: true)),
            (key: "item2", metadata: (version: 2, flags: false))
          ]
        )
      )
    )

    # Both of these should also trigger the same bug pattern
    let result_a = match variant_a:
      VariantA(nested: (level2: (data: items))) and items.len == 2 and items[0].active :
        "Variant A matched: " & $items[0].count
      _ : "Variant A failed"

    let result_b = match variant_b:
      VariantB(outer: (middle: (records: recs))) and recs.len == 2 and recs[0].metadata.version == 1 :
        "Variant B matched: " & recs[0].key
      _ : "Variant B failed"

    check(result_a == "Variant A matched: 42")
    check(result_b == "Variant B matched: item1")

  test "should demonstrate workaround patterns that avoid the bug":
    ## Document alternative patterns that work around the bug
    ## until the core issue is fixed

    type
      WorkaroundType = object
        data: tuple[
          inner: tuple[
            items: seq[tuple[id: int, name: string]]
          ]
        ]

    let workaround_data = WorkaroundType(
      data: (
        inner: (
          items: @[(id: 1, name: "test"), (id: 2, name: "demo")]
        )
      )
    )

    # Workaround 1: Extract intermediate variables first
    let intermediate = workaround_data.data.inner.items
    let workaround1 = match intermediate:
      [first, second] and first.id == 1 and second.name == "demo" :
        "Workaround 1 successful: " & first.name & " " & second.name
      _ : "Workaround 1 failed"

    # Workaround 2: Use simpler pattern without deep nesting in guards
    let workaround2 = match workaround_data:
      WorkaroundType(data: (inner: (items: item_array))) :
        if item_array.len == 2 and item_array[0].id == 1:
          "Workaround 2 successful: " & $item_array.len & " items"
        else:
          "Workaround 2 validation failed"
      _ : "Workaround 2 failed"

    check(workaround1 == "Workaround 1 successful: test demo")
    check(workaround2 == "Workaround 2 successful: 2 items")

    # The original buggy pattern would be:
    # match workaround_data:
    #   WorkaroundType(data: (inner: (items: items))) and items.len == 2 and items[0].id == 1 :
    #     "Should work but triggers isSome bug"