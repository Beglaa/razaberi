## Comprehensive Tests for Set Subset/Superset Operations
##
## This test suite validates set relational operations in pattern matching:
## - Subset testing: x <= {...}
## - Proper subset testing: x < {...}
## - Superset testing: x >= {...}
## - Proper superset testing: x > {...}
## - Equality testing: {...} (exact match)
##
## Test Coverage:
## 1. Enum set subset/superset operations
## 2. Integer set subset/superset operations
## 3. Char set subset/superset operations
## 4. Bool set subset/superset operations
## 5. Combined subset operations with guards
## 6. Empty set edge cases
## 7. Set equality vs subset distinction

import unittest
import ../../pattern_matching

suite "Set Subset/Superset Operations":

  # ============================================================================
  # Test 1: Enum Set Subset Operations
  # ============================================================================

  test "enum set subset testing with <=":
    type Color = enum Red, Green, Blue, Yellow

    let colorSet1 = {Red, Green}
    let result1 = match colorSet1:
      x <= {Red, Green, Blue}: "subset of RGB"
      _: "not subset"

    check result1 == "subset of RGB"

    # Test proper subset (not equal)
    let colorSet2 = {Red, Green}
    let result2 = match colorSet2:
      x < {Red, Green, Blue}: "proper subset of RGB"
      _: "not proper subset"

    check result2 == "proper subset of RGB"

    # Test equality (not proper subset)
    let colorSet3 = {Red, Green}
    let result3 = match colorSet3:
      x < {Red, Green}: "proper subset"
      x <= {Red, Green}: "equal"
      _: "neither"

    check result3 == "equal"

  test "enum set superset testing with >=":
    type Color = enum Red, Green, Blue, Yellow

    let colorSet1 = {Red, Green, Blue}
    let result1 = match colorSet1:
      x >= {Red, Green}: "superset of Red-Green"
      _: "not superset"

    check result1 == "superset of Red-Green"

    # Test proper superset (not equal)
    let colorSet2 = {Red, Green, Blue}
    let result2 = match colorSet2:
      x > {Red, Green}: "proper superset of Red-Green"
      _: "not proper superset"

    check result2 == "proper superset of Red-Green"

  # ============================================================================
  # Test 2: Integer Set Subset Operations
  # ============================================================================

  test "integer set subset testing":
    let intSet = {1, 2, 3}
    let result = match intSet:
      x <= {1, 2, 3, 4, 5}: "subset of 1-5"
      _: "not subset"

    check result == "subset of 1-5"

  test "integer set proper subset vs equality":
    let intSet = {1, 2}
    let result = match intSet:
      x < {1, 2}: "proper subset (should not match)"
      x <= {1, 2}: "equal set"
      _: "neither"

    check result == "equal set"

  test "integer set superset testing":
    let intSet = {1, 2, 3, 4, 5}
    let result = match intSet:
      x >= {1, 2, 3}: "superset of 1-3"
      _: "not superset"

    check result == "superset of 1-3"

  # ============================================================================
  # Test 3: Char Set Subset Operations
  # ============================================================================

  test "char set subset testing":
    let charSet = {'a', 'b', 'c'}
    let result = match charSet:
      x <= {'a', 'b', 'c', 'd', 'e'}: "subset of a-e"
      _: "not subset"

    check result == "subset of a-e"

  test "char set superset testing":
    let charSet = {'a', 'b', 'c', 'd'}
    let result = match charSet:
      x >= {'a', 'b'}: "superset of a-b"
      _: "not superset"

    check result == "superset of a-b"

  # ============================================================================
  # Test 4: Bool Set Subset Operations
  # ============================================================================

  test "bool set subset testing":
    let boolSet1 = {true}
    let result1 = match boolSet1:
      x <= {true, false}: "subset of all bools"
      _: "not subset"

    check result1 == "subset of all bools"

    let boolSet2 = {false}
    let result2 = match boolSet2:
      x < {true, false}: "proper subset"
      _: "not proper subset"

    check result2 == "proper subset"

  # ============================================================================
  # Test 5: Combined Subset Operations with Guards
  # ============================================================================

  test "subset with additional guards":
    type Color = enum Red, Green, Blue, Yellow

    let colorSet = {Red, Green}
    let result = match colorSet:
      x <= {Red, Green, Blue} and x.card == 2: "subset with 2 elements"
      x <= {Red, Green, Blue}: "subset only"
      _: "no match"

    check result == "subset with 2 elements"

  test "multiple subset conditions":
    let intSet = {2, 3}
    let result = match intSet:
      x <= {1, 2, 3, 4} and x >= {2}: "between ranges"
      _: "no match"

    check result == "between ranges"

  # ============================================================================
  # Test 6: Empty Set Edge Cases
  # ============================================================================

  test "empty set is subset of any set":
    type SmallInt = range[0..10]
    let emptySet: set[SmallInt] = {}
    let result = match emptySet:
      x <= {1.SmallInt, 2, 3}: "empty is subset"
      _: "not subset"

    check result == "empty is subset"

  test "empty set is not proper subset of empty set":
    type SmallInt = range[0..10]
    let emptySet: set[SmallInt] = {}
    let result = match emptySet:
      x < {}: "proper subset (should not match)"
      x <= {}: "equal to empty"
      _: "neither"

    check result == "equal to empty"

  test "any set is superset of empty set":
    let intSet = {1, 2, 3}
    let result = match intSet:
      x >= {}: "superset of empty"
      _: "not superset"

    check result == "superset of empty"

  # ============================================================================
  # Test 7: Set Equality vs Subset Distinction
  # ============================================================================

  test "exact set match vs subset":
    type Color = enum Red, Green, Blue

    let colorSet = {Red, Green}
    let result = match colorSet:
      {Red, Green}: "exact match"
      x <= {Red, Green, Blue}: "subset (should not reach)"
      _: "no match"

    check result == "exact match"

  test "order independence in exact match":
    let intSet = {3, 1, 2}
    let result = match intSet:
      {1, 2, 3}: "matched (order independent)"
      _: "no match"

    check result == "matched (order independent)"

  # ============================================================================
  # Test 8: Disjoint Sets
  # ============================================================================

  test "disjoint sets are not subsets":
    type Color = enum Red, Green, Blue, Yellow, Orange

    let colorSet = {Red, Green}
    let result = match colorSet:
      x <= {Blue, Yellow}: "subset (should not match)"
      _: "not subset"

    check result == "not subset"

  # ============================================================================
  # Test 9: Practical Use Cases
  # ============================================================================

  test "permission checking example":
    type Permission = enum Read, Write, Execute

    let userPermissions = {Read, Write}
    let result = match userPermissions:
      x >= {Read, Write, Execute}: "admin or higher"
      x >= {Read, Write}: "editor or higher"
      x >= {Read}: "reader or higher"
      _: "no permissions"

    check result == "editor or higher"

  test "feature flag checking example":
    type Feature = enum
      BasicFeature, PremiumFeature, EnterpriseFeature

    let enabledFeatures = {BasicFeature, PremiumFeature}
    let result = match enabledFeatures:
      x >= {BasicFeature, PremiumFeature, EnterpriseFeature}: "enterprise plan"
      x >= {BasicFeature, PremiumFeature}: "premium plan"
      x >= {BasicFeature}: "basic plan"
      _: "no plan"

    check result == "premium plan"

  test "state machine transitions":
    type State = enum
      Idle, Running, Paused, Stopped

    let allowedTransitions = {Running, Paused}
    let result = match allowedTransitions:
      x <= {Idle, Running, Paused, Stopped}: "valid subset"
      _: "invalid transitions"

    check result == "valid subset"
