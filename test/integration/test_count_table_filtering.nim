import unittest
import tables
import sequtils
import ../../pattern_matching

suite "CountTable Structural Pattern Matching":

  test "CountTable structural matching checks specific keys":
    let wordCounts = toCountTable(["apple", "banana", "apple", "cherry", "apple", "banana"])

    # Structural matching checks specific key
    let apple_is_frequent = match wordCounts:
      {"apple": apple_count} and apple_count > 1: true
      _: false

    check apple_is_frequent == true  # Apple appears 3 times > 1

    # For filtering by count, use regular Nim operations
    let frequent_words = wordCounts.pairs.toSeq.filter(proc(pair: (string, int)): bool = pair[1] > 1)
    check frequent_words.len == 2  # apple (3) and banana (2)
    # Frequent words validated
  
  test "CountTable demonstrates filtering behavior removed":
    let letterCounts = toCountTable(['a', 'b', 'a', 'c', 'b', 'a', 'd'])

    # Structural: check if 'a' appears more than 2 times
    let a_is_frequent = match letterCounts:
      {'a': a_count} and a_count > 2: true
      _: false

    check a_is_frequent == true  # 'a' appears 3 times > 2

    # For filtering operations, use regular Nim
    let frequent_chars = letterCounts.pairs.toSeq.filter(proc(pair: (char, int)): bool = pair[1] > 2)
    check frequent_chars.len == 1
    check frequent_chars[0][0] == 'a'
    check frequent_chars[0][1] == 3

  test "CountTable structural behavior vs filtering operations":
    let wordCounts = toCountTable(["hello", "world", "hello", "nim"])

    # Structural: check specific key existence and value
    let hello_appears_twice = match wordCounts:
      {"hello": hello_count} and hello_count == 2: true
      _: false

    check hello_appears_twice == true

    # For complex filtering, use regular Nim operations
    let frequent_words = wordCounts.pairs.toSeq.filter(proc(pair: (string, int)): bool = pair[1] > 1)
    check frequent_words.len == 1  # Only "hello" appears more than once
    check frequent_words[0][0] == "hello"
    check frequent_words[0][1] == 2