## Phase 1 Integration Tests - Deep Nesting
## Tests 5-10 level deep nesting patterns

import unittest
import ../../pattern_matching

suite "Phase 1 Integration - Deep Nesting":

  test "5-level deep object nesting":
    type
      L5 = object
        val: int
      L4 = object
        l5: L5
      L3 = object
        l4: L4
      L2 = object
        l3: L3
      L1 = object
        l2: L2

    let obj = L1(l2: L2(l3: L3(l4: L4(l5: L5(val: 42)))))

    let result = match obj:
      L1(l2: L2(l3: L3(l4: L4(l5: L5(val: v))))): $v
      _: "no match"

    check result == "42"

  test "6-level deep object nesting":
    type
      L6 = object
        val: int
      L5 = object
        l6: L6
      L4 = object
        l5: L5
      L3 = object
        l4: L4
      L2 = object
        l3: L3
      L1 = object
        l2: L2

    let obj = L1(l2: L2(l3: L3(l4: L4(l5: L5(l6: L6(val: 99))))))

    let result = match obj:
      L1(l2: L2(l3: L3(l4: L4(l5: L5(l6: L6(val: v)))))): $v
      _: "no match"

    check result == "99"

  test "7-level deep tuple nesting":
    let data = (1, (2, (3, (4, (5, (6, 7))))))

    let result = match data:
      (a, (b, (c, (d, (e, (f, g)))))): $a & $b & $c & $d & $e & $f & $g
      _: "no match"

    check result == "1234567"

  test "8-level mixed nesting (objects and tuples)":
    type
      L8 = object
        val: int
      L7 = object
        data: (int, L8)
      L6 = object
        l7: L7
      L5 = object
        data: (L6, int)
      L4 = object
        l5: L5
      L3 = object
        data: (int, L4)
      L2 = object
        l3: L3
      L1 = object
        data: (L2, int)

    let obj = L1(
      data: (L2(l3: L3(
        data: (100, L4(l5: L5(
          data: (L6(l7: L7(
            data: (200, L8(val: 42))
          )), 300)
        )))
      )), 400)
    )

    let result = match obj:
      L1(data: (L2(l3: L3(data: (n1, L4(l5: L5(data: (L6(l7: L7(data: (n2, L8(val: v)))), n3)))))), n4)):
        $n1 & "," & $n2 & "," & $v & "," & $n3 & "," & $n4
      _: "no match"

    check result == "100,200,42,300,400"

  test "10-level deep object nesting (stress test)":
    type
      L10 = object
        val: int
      L9 = object
        l10: L10
      L8 = object
        l9: L9
      L7 = object
        l8: L8
      L6 = object
        l7: L7
      L5 = object
        l6: L6
      L4 = object
        l5: L5
      L3 = object
        l4: L4
      L2 = object
        l3: L3
      L1 = object
        l2: L2

    let obj = L1(l2: L2(l3: L3(l4: L4(l5: L5(l6: L6(l7: L7(l8: L8(l9: L9(l10: L10(val: 1000))))))))))

    let result = match obj:
      L1(l2: L2(l3: L3(l4: L4(l5: L5(l6: L6(l7: L7(l8: L8(l9: L9(l10: L10(val: v)))))))))): $v
      _: "no match"

    check result == "1000"

  test "Mixed nesting: objects, tuples, sequences (5 levels)":
    type
      Inner = object
        data: (int, int)
      Middle = object
        items: seq[Inner]
      Outer = object
        middle: (Middle, string)
      Container = object
        outer: Outer

    let obj = Container(
      outer: Outer(
        middle: (Middle(
          items: @[Inner(data: (1, 2)), Inner(data: (3, 4))]
        ), "label")
      )
    )

    let result = match obj:
      Container(outer: Outer(middle: (Middle(items: [Inner(data: (a, b)), Inner(data: (c, d))]), label))):
        label & ":" & $a & "," & $b & "," & $c & "," & $d
      _: "no match"

    check result == "label:1,2,3,4"

  test "Deep nesting with multiple values at each level":
    type
      L4 = object
        x, y: int
      L3 = object
        a, b: L4
      L2 = object
        left, right: L3
      L1 = object
        top, bottom: L2

    let obj = L1(
      top: L2(
        left: L3(a: L4(x: 1, y: 2), b: L4(x: 3, y: 4)),
        right: L3(a: L4(x: 5, y: 6), b: L4(x: 7, y: 8))
      ),
      bottom: L2(
        left: L3(a: L4(x: 9, y: 10), b: L4(x: 11, y: 12)),
        right: L3(a: L4(x: 13, y: 14), b: L4(x: 15, y: 16))
      )
    )

    let result = match obj:
      L1(
        top: L2(
          left: L3(a: L4(x: x1, y: y1), b: L4(x: x2, y: y2)),
          right: L3(a: L4(x: x3, y: y3), b: L4(x: x4, y: y4))
        ),
        bottom: L2(
          left: L3(a: L4(x: x5, y: y5), b: L4(x: x6, y: y6)),
          right: L3(a: L4(x: x7, y: y7), b: L4(x: x8, y: y8))
        )
      ):
        $x1 & "," & $x2 & "," & $x3 & "," & $x4 & "," & $x5 & "," & $x6 & "," & $x7 & "," & $x8
      _: "no match"

    check result == "1,3,5,7,9,11,13,15"

  test "Deep sequence nesting (5 levels)":
    let data = @[@[@[@[@[1, 2], @[3, 4]], @[@[5, 6], @[7, 8]]], @[@[@[9, 10], @[11, 12]], @[@[13, 14], @[15, 16]]]]]

    let result = match data:
      [[[[[a, b], [c, d]], [[e, f], [g, h]]], [[[i, j], [k, l]], [[m, n], [o, p]]]]]:
        $a & $b & $c & $d & $e & $f & $g & $h & $i & $j & $k & $l & $m & $n & $o & $p
      _: "no match"

    check result == "12345678910111213141516"

  test "Deep tuple nesting with mixed types (6 levels)":
    let data = (1, ("a", (2.0, (true, ("b", 3)))))

    let result = match data:
      (n1, (s1, (f, (b, (s2, n2))))):
        $n1 & s1 & $f & $b & s2 & $n2
      _: "no match"

    check result == "1a2.0trueb3"