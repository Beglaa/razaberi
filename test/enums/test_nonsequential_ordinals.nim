## Comprehensive test for variant objects with non-sequential enum ordinals
## Tests the fix for bug CM-6: proper handling of non-sequential ordinals

import unittest
import ../../pattern_matching

suite "Non-Sequential Enum Ordinals in Variant Objects":

  test "non-sequential ordinals with gaps":
    type
      Priority = enum
        pLow = 0
        pMedium = 5
        pHigh = 10

      Task = object
        case priority: Priority
        of pLow:
          description: string
        of pMedium:
          deadline: string
        of pHigh:
          assignee: string

    # Test pLow (ordinal 0)
    let lowTask = Task(priority: pLow, description: "Easy task")
    let result1 = match lowTask:
      Task(priority: pLow, description: d):
        "Low: " & d
      Task(priority: pMedium, deadline: dl):
        "Medium: " & dl
      Task(priority: pHigh, assignee: a):
        "High: " & a
      _:
        "Unknown"

    check result1 == "Low: Easy task"

    # Test pMedium (ordinal 5)
    let mediumTask = Task(priority: pMedium, deadline: "Friday")
    let result2 = match mediumTask:
      Task(priority: pLow, description: d):
        "Low: " & d
      Task(priority: pMedium, deadline: dl):
        "Medium: " & dl
      Task(priority: pHigh, assignee: a):
        "High: " & a
      _:
        "Unknown"

    check result2 == "Medium: Friday"

    # Test pHigh (ordinal 10)
    let highTask = Task(priority: pHigh, assignee: "Alice")
    let result3 = match highTask:
      Task(priority: pLow, description: d):
        "Low: " & d
      Task(priority: pMedium, deadline: dl):
        "Medium: " & dl
      Task(priority: pHigh, assignee: a):
        "High: " & a
      _:
        "Unknown"

    check result3 == "High: Alice"

  test "non-sequential with guards":
    type
      Level = enum
        lNovice = 0
        lIntermediate = 10
        lExpert = 100

      Player = object
        case level: Level
        of lNovice:
          tutorials: int
        of lIntermediate:
          missions: int
        of lExpert:
          achievements: int

    let novicePlayer = Player(level: lNovice, tutorials: 5)
    let result1 = match novicePlayer:
      Player(level: lNovice, tutorials: t and t > 3):
        "Novice with many tutorials: " & $t
      Player(level: lNovice):
        "Novice"
      _:
        "Other"

    check result1 == "Novice with many tutorials: 5"

    let intermediatePlayer = Player(level: lIntermediate, missions: 42)
    let result2 = match intermediatePlayer:
      Player(level: lIntermediate, missions: m and m > 40):
        "Intermediate veteran: " & $m
      Player(level: lIntermediate):
        "Intermediate"
      _:
        "Other"

    check result2 == "Intermediate veteran: 42"

  test "powers of two ordinals":
    type
      Permission = enum
        pNone = 0
        pRead = 1
        pWrite = 2
        pExecute = 4
        pAdmin = 8

      Access = object
        case permission: Permission
        of pNone:
          reason: string
        of pRead:
          file: string
        of pWrite:
          path: string
        of pExecute:
          script: string
        of pAdmin:
          command: string

    let readAccess = Access(permission: pRead, file: "data.txt")
    let result = match readAccess:
      Access(permission: pNone, reason: r):
        "None: " & r
      Access(permission: pRead, file: f):
        "Read: " & f
      Access(permission: pWrite, path: p):
        "Write: " & p
      Access(permission: pExecute, script: s):
        "Execute: " & s
      Access(permission: pAdmin, command: c):
        "Admin: " & c

    check result == "Read: data.txt"

  test "mixed sequential and non-sequential":
    type
      Grade = enum
        gF = 0
        gD = 1
        gC = 2
        gB = 5
        gA = 10

      StudentRecord = object
        case grade: Grade
        of gF:
          reason: string
        of gD:
          dNotes: string
        of gC:
          cNotes: string
        of gB:
          commendation: string
        of gA:
          award: string

    let failingStudent = StudentRecord(grade: gF, reason: "Incomplete work")
    let result1 = match failingStudent:
      StudentRecord(grade: gF, reason: r):
        "Failed: " & r
      StudentRecord(grade: gD, dNotes: n):
        "D grade: " & n
      StudentRecord(grade: gC, cNotes: n):
        "C grade: " & n
      StudentRecord(grade: gB, commendation: c):
        "B grade: " & c
      StudentRecord(grade: gA, award: a):
        "A grade: " & a

    check result1 == "Failed: Incomplete work"

    let topStudent = StudentRecord(grade: gA, award: "Honor Roll")
    let result2 = match topStudent:
      StudentRecord(grade: gF, reason: r):
        "Failed: " & r
      StudentRecord(grade: gD, dNotes: n):
        "D grade: " & n
      StudentRecord(grade: gC, cNotes: n):
        "C grade: " & n
      StudentRecord(grade: gB, commendation: c):
        "B grade: " & c
      StudentRecord(grade: gA, award: a):
        "A grade: " & a

    check result2 == "A grade: Honor Roll"
