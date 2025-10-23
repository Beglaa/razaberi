## Pattern Validation Module
##
## Provides compile-time pattern validation using structural analysis.
## All validation functions use analyzeConstructMetadata for type structure queries.
##
## NO string heuristics - pure AST structural analysis.

import macros
import strutils
import construct_metadata

# Export construct_metadata types for convenience
export ConstructMetadata, ConstructKind, FieldMetadata, TupleElement

# ============================================================================
# Pattern Type Inference
# ============================================================================

type
  PatternKind* = enum
    ## Classification of pattern types based on AST structure
    pkLiteral          ## Literal pattern: 42, "hello", true, 3.14, 'c'
    pkVariable         ## Variable binding: x, name, value
    pkWildcard         ## Wildcard: _
    pkObject           ## Object/class pattern: Point(x, y)
    pkTuple            ## Tuple pattern: (x, y, z)
    pkSequence         ## Sequence/array pattern: [a, b, c]
    pkTable            ## Table pattern: {"key": value}
    pkSet              ## Set pattern: {Red, Blue}
    pkOption           ## Option pattern: Some(x), None()
    pkGuard            ## Guard pattern: x and x > 10
    pkOr               ## OR pattern: 1 | 2 | 3
    pkAt               ## @ pattern: 42 @ num
    pkType             ## Type constraint: int(x), string(s)
    pkFunction         ## Function pattern: arity(2), returns(int)
    pkUnknown          ## Unknown/unsupported pattern

  PatternInfo* = object
    ## Complete information about a pattern
    kind*: PatternKind
    node*: NimNode
    typeName*: string           ## For object/type patterns
    fieldNames*: seq[string]    ## For object patterns
    elementCount*: int          ## For tuple/sequence/array patterns (-1 if variable)
    isSpread*: bool            ## For sequence patterns with spread operator

  ValidationResult* = object
    ## Result of pattern validation
    ## Using object instead of tuple to avoid Nim compiler issues with tuples in macro context
    isValid*: bool
    errorMessage*: string

# ============================================================================
# Forward Declarations
# ============================================================================

proc inferPatternKind*(pattern: NimNode): PatternKind
proc analyzePattern*(pattern: NimNode): PatternInfo {.noSideEffect.}
proc validatePatternStructure*(pattern: NimNode, metadata: ConstructMetadata): ValidationResult {.noSideEffect.}
proc validateObjectPattern*(pattern: NimNode, metadata: ConstructMetadata): ValidationResult {.noSideEffect.}
proc validateTuplePattern*(pattern: NimNode, metadata: ConstructMetadata): ValidationResult {.noSideEffect.}
proc validateSequencePattern*(pattern: NimNode, metadata: ConstructMetadata): ValidationResult {.noSideEffect.}
proc validateTablePattern*(pattern: NimNode, metadata: ConstructMetadata): ValidationResult {.noSideEffect.}
proc validateSetPattern*(pattern: NimNode, metadata: ConstructMetadata): ValidationResult {.noSideEffect.}
proc validateEnumPattern*(pattern: NimNode, metadata: ConstructMetadata): ValidationResult {.noSideEffect.}
proc validateRefPattern*(pattern: NimNode, metadata: ConstructMetadata): ValidationResult {.noSideEffect.}
proc validatePtrPattern*(pattern: NimNode, metadata: ConstructMetadata): ValidationResult {.noSideEffect.}
proc validateDequePattern*(pattern: NimNode, metadata: ConstructMetadata): ValidationResult {.noSideEffect.}
proc validateLinkedListPattern*(pattern: NimNode, metadata: ConstructMetadata): ValidationResult {.noSideEffect.}
proc validateJsonNodePattern*(pattern: NimNode, metadata: ConstructMetadata): ValidationResult {.noSideEffect.}
proc generateValidationError*(pattern: NimNode, metadata: ConstructMetadata,
                             errorMsg: string): string

# ============================================================================
# Error Message Generators
# ============================================================================

proc levenshteinDistance(s1, s2: string): int =
  ## Calculate Levenshtein distance between two strings
  ## Used for suggesting corrections to misspelled field names
  ##
  ## Levenshtein distance is the minimum number of single-character edits
  ## (insertions, deletions, or substitutions) needed to change one string into another
  ##
  ## Algorithm uses dynamic programming with space optimization
  ## Time complexity: O(n*m), Space complexity: O(m)

  if s1.len == 0: return s2.len
  if s2.len == 0: return s1.len

  # Use rolling array for space optimization
  var costs = newSeq[int](s2.len + 1)
  for j in 0..s2.len:
    costs[j] = j

  for i in 1..s1.len:
    var lastValue = i
    for j in 1..s2.len:
      let newValue = if s1[i-1] == s2[j-1]:
                       costs[j-1]
                     else:
                       min([costs[j-1], costs[j], lastValue]) + 1
      costs[j-1] = lastValue
      lastValue = newValue
    costs[s2.len] = lastValue

  return costs[s2.len]

proc generateFieldSuggestions(fieldName: string, availableFields: seq[string]): string =
  ## Generate suggestions for misspelled field names using Levenshtein distance
  ## Returns suggestion text if a close match is found (adaptive threshold)
  ## Returns empty string if no close matches
  ##
  ## Uses Levenshtein distance to find the closest matching field name
  ## Only suggests if the distance is small enough to be a likely typo
  ##
  ## Adaptive Threshold Strategy:
  ## - Short field names (2-6 chars): threshold = 2 (conservative, avoid false suggestions)
  ## - Medium field names (7-12 chars): threshold = 3-4 (balanced)
  ## - Long field names (13+ chars): threshold scales to ~33% of length (generous, catch genuine typos)
  ##
  ## Formula: max(fieldName.len div 3, 2)
  ## This ensures minimum threshold of 2, scaling to approximately 1/3 of field length

  if availableFields.len == 0:
    return ""

  # Find closest match
  var bestMatch = ""
  var bestDistance = 999

  for field in availableFields:
    let dist = levenshteinDistance(fieldName, field)
    if dist < bestDistance:
      bestDistance = dist
      bestMatch = field

  # Adaptive threshold: more conservative for short names, generous for long names
  # Examples: 2-char → threshold 2, 9-char → threshold 3, 30-char → threshold 10
  let threshold = max(fieldName.len div 3, 2)

  if bestDistance <= threshold:
    return "\n  Did you mean '" & bestMatch & "'?"
  else:
    return ""

proc hasOperatorInGuard(guard: NimNode, op: string): bool =
  ## Recursively check if guard expression contains a specific operator
  ## Used to provide context-aware operator hints
  if guard == nil:
    return false

  case guard.kind:
  of nnkInfix:
    if guard.len >= 1 and guard[0].kind == nnkIdent:
      if guard[0].strVal == op:
        return true
    # Recursively check children
    for child in guard:
      if hasOperatorInGuard(child, op):
        return true

  of nnkPrefix, nnkCall, nnkCommand, nnkPar, nnkBracket, nnkStmtList:
    # Recursively check children
    for child in guard:
      if hasOperatorInGuard(child, op):
        return true

  else:
    discard

  return false

proc generateOperatorHints*(guard: NimNode = nil): string =
  ## Generate context-aware hints about Nim's special operators for guard expressions
  ## Only shows hints relevant to operators found in the guard expression
  ##
  ## Appended to guard-related error messages to help users avoid common mistakes
  ##
  ## Args:
  ##   guard: Optional guard expression to analyze for context-aware hints
  ##
  ## Returns: Short, actionable hint text about relevant operators, or empty if no hints needed
  if guard == nil:
    # No guard provided - show general hint
    return "\n\nHint: Nim operators for guards: 'notin' (not 'not in'), 'isnot' (not 'is not'), 'isNil(x)' or 'x == nil'"

  var hints: seq[string] = @[]

  # Check for 'in' operator - suggest 'notin'
  if hasOperatorInGuard(guard, "in"):
    hints.add("Use 'notin' instead of 'not in' for membership testing")

  # Check for 'is' operator - suggest 'isnot'
  if hasOperatorInGuard(guard, "is"):
    hints.add("Use 'isnot' instead of 'not is' for type checking")

  # If no specific hints, return empty (error is likely not operator-related)
  if hints.len == 0:
    return ""

  # Build hint message
  result = "\n\nHint: " & hints.join("; ")

proc generateFieldError(fieldName: string, metadata: ConstructMetadata, pattern: NimNode): string =
  ## Generate comprehensive error message for invalid field access
  ## Includes:
  ## - Clear description of the error
  ## - List of available fields
  ## - Pattern representation
  ## - Scrutinee type information
  ## - Suggestion for likely typos (using Levenshtein distance)
  ##
  ## Uses structural metadata to provide accurate field information

  let allFields = getAllFieldNames(metadata)
  let suggestion = generateFieldSuggestions(fieldName, allFields)

  result = "Field '" & fieldName & "' does not exist in type '" & metadata.typeName & "'."
  if allFields.len > 0:
    result &= "\n  Available fields: " & allFields.join(", ")
  result &= "\n  Pattern: " & pattern.repr
  result &= "\n  Scrutinee type: " & prettyPrintType(metadata)
  if suggestion != "":
    result &= suggestion

proc generateTypeMismatchError(patternTypeName: string, metadata: ConstructMetadata,
                                pattern: NimNode): string =
  ## Generate comprehensive error message for type mismatch
  ## Includes:
  ## - Clear "Pattern type mismatch" header
  ## - Pattern expected type
  ## - Actual scrutinee type
  ## - WHY explanation of incompatibility
  ## - HOW to fix suggestion
  ##
  ## Uses structural metadata to provide accurate type information

  result = "Pattern type mismatch:\n"
  result &= "  Pattern expects: " & patternTypeName & "\n"
  result &= "  Scrutinee type: " & prettyPrintType(metadata) & "\n\n"

  # Add WHY explanation based on scrutinee type
  result &= "  Why incompatible:\n"
  case metadata.kind:
  of ckObject:
    result &= "    The scrutinee is an object with named fields, but the pattern\n"
    result &= "    treats it as type '" & patternTypeName & "'.\n"
    result &= "    Objects require field names in patterns.\n"
  of ckTuple:
    result &= "    The scrutinee is a tuple with positional elements, but the pattern\n"
    result &= "    treats it as type '" & patternTypeName & "'.\n"
    result &= "    Tuples use parentheses: (elem1, elem2, ...).\n"
  of ckSequence, ckArray:
    result &= "    The scrutinee is a " & (if metadata.kind == ckSequence: "sequence" else: "array") &
              " collection, but the pattern\n"
    result &= "    treats it as type '" & patternTypeName & "'.\n"
    result &= "    Collections use brackets: [elem1, elem2, ...].\n"
  of ckTable:
    result &= "    The scrutinee is a table (key-value mapping), but the pattern\n"
    result &= "    treats it as type '" & patternTypeName & "'.\n"
    result &= "    Tables use braces: {\"key\": value, ...}.\n"
  of ckSet:
    result &= "    The scrutinee is a set (unique values), but the pattern\n"
    result &= "    treats it as type '" & patternTypeName & "'.\n"
    result &= "    Sets use braces: {value1, value2, ...}.\n"
  else:
    result &= "    Type '" & patternTypeName & "' is not compatible with '" &
              metadata.typeName & "'.\n"

  result &= "\n  How to fix:\n"
  result &= "    Match the pattern syntax to the scrutinee type,\n"
  result &= "    or use a wildcard '_' to match any value."

proc generateElementCountError(patternCount: int, expectedCount: int,
                                metadata: ConstructMetadata, pattern: NimNode): string =
  ## Generate comprehensive error message for element count mismatch
  ## Includes:
  ## - Clear description of count mismatch
  ## - Pattern element count
  ## - Expected element count
  ## - Pattern representation
  ## - Scrutinee type information
  ## - Helpful suggestion (add or remove elements)
  ## - Example patterns (including spread operators for arrays)
  ##
  ## Works for both tuples and arrays

  let diff = patternCount - expectedCount
  let patternType = if metadata.kind == ckTuple: "Tuple" else: "Array"

  result = patternType & " element count mismatch:\n"
  result &= "  Pattern has: " & $patternCount & " elements\n"
  result &= "  " & patternType & " has: " & $expectedCount & " elements\n\n"
  result &= "  Pattern: " & pattern.repr & "\n"
  result &= "  Scrutinee type: " & prettyPrintType(metadata) & "\n\n"

  if diff > 0:
    result &= "  Fix: Remove " & $diff & " element" & (if diff > 1: "s" else: "") &
              " from the pattern to match the " & patternType.toLowerAscii() & " size.\n"
  else:
    result &= "  Fix: Add " & $(-diff) & " element" & (if diff < -1: "s" else: "") &
              " to the pattern to match the " & patternType.toLowerAscii() & " size.\n"

  # Add pattern examples for arrays (spread operators are useful)
  if metadata.kind == ckArray and expectedCount > 0:
    result &= "\n  Example patterns:\n"
    # Show exact match example
    var exactExample = newSeq[string](expectedCount)
    for i in 0..<expectedCount:
      exactExample[i] = "elem" & $(i+1)
    result &= "    Exact match: [" & exactExample.join(", ") & "]\n"

    # Show spread pattern examples
    if expectedCount >= 2:
      result &= "    With spread: [first, *rest]  # Captures first element + remaining\n"
      result &= "                 [*init, last]   # Captures all but last + last element\n"
    if expectedCount >= 3:
      result &= "                 [first, *middle, last]  # Captures first, middle elements, and last\n"

    # Tip for variable-length patterns
    result &= "\n  Tip: For variable-length patterns, use seq[T] or openArray[T] instead of array[N, T]"

proc generateUnionBranchError(fieldName: string, discriminatorValue: string,
                                metadata: ConstructMetadata, pattern: NimNode): string =
  ## Generate union-friendly error message for branch access violations
  ## Hides internal implementation details (kind, val0, val1, ukInt, etc.)
  ## Provides user-friendly messages matching union type mental model
  ##
  ## Instead of: "Field 'val1' not accessible when kind = ukString"
  ## Generates: "Cannot access string variant when union contains int"

  # Extract the variant type from discriminator value (current branch)
  # ukInt -> int, ukString -> string, etc.
  var currentVariantType = discriminatorValue
  if currentVariantType.startsWith("uk"):
    currentVariantType = currentVariantType[2..^1].toLowerAscii()

  # Determine which variant the pattern is trying to access from field name
  # val0 -> first type, val1 -> second type, etc.
  var attemptedVariantType = ""
  if fieldName.startsWith("val") and fieldName.len > 3:
    let indexStr = fieldName[3..^1]
    try:
      let index = parseInt(indexStr)
      # Look up the branch by index to get its discriminator value
      if index >= 0 and index < metadata.branches.len:
        let branch = metadata.branches[index]
        attemptedVariantType = branch.discriminatorValue
        if attemptedVariantType.startsWith("uk"):
          attemptedVariantType = attemptedVariantType[2..^1].toLowerAscii()
    except ValueError:
      discard

  result = "Union type branch safety error:\n"
  result &= "  Union type: " & metadata.typeName & "\n"
  result &= "  Pattern attempts to access variant that doesn't match current value\n\n"

  result &= "  Explanation: This union currently contains a '" & currentVariantType &
            "' variant, but the pattern tries to access fields from a different variant branch"

  # Add the attempted variant type if we successfully determined it
  if attemptedVariantType != "" and attemptedVariantType != currentVariantType:
    result &= " (in this case '" & attemptedVariantType & "')"

  result &= ".\n\n"

  result &= "  Fix: Ensure your pattern matches the correct variant branch for " & currentVariantType & " values."

proc extractConstructorName(discriminatorValue: string): string =
  ## Extract user-facing constructor name from discriminator enum value
  ## Used to generate error messages showing what users should actually type
  ##
  ## Handles two naming patterns:
  ## 1. Prefixed: "{prefix}k{ConstructorName}" -> "ConstructorName"
  ##    Examples: "skActive" -> "Active", "vkInt" -> "Int"
  ## 2. Plain: "ConstructorName" -> "ConstructorName"
  ##    Examples: "Active" -> "Active", "Inactive" -> "Inactive"
  ##
  ## The 'k' character acts as a separator between the type prefix and constructor name.
  ## This follows the naming convention used by variant_dsl.nim:
  ##   typeName.toLowerAscii()[0..0] & "k" & constructorName
  ##
  ## Args:
  ##   discriminatorValue: The enum value from variant metadata (e.g., "skActive")
  ##
  ## Returns:
  ##   The user-facing constructor name (e.g., "Active")
  ##
  ## Design rationale:
  ##   Users write: Status.Active(x)
  ##   Not: Status.skActive(x)
  ##   Error messages should show what users actually type.

  # Find 'k' separator position
  let kPos = discriminatorValue.find('k')

  # Check if 'k' exists and has content after it
  if kPos > 0 and kPos < discriminatorValue.len - 1:
    # Found 'k' separator - extract constructor name after it
    # Example: "skActive" -> position 1 -> "Active"
    return discriminatorValue[(kPos + 1)..^1]
  else:
    # No 'k' separator found - discriminator IS the constructor name
    # Example: "Active" -> "Active" (no prefix)
    return discriminatorValue

proc generateVariantConstructorError(typeName: string, constructorName: string,
                                      metadata: ConstructMetadata, pattern: NimNode): string =
  ## Generate comprehensive error message for invalid UFCS variant constructor
  ## Includes:
  ## - Clear description of the error
  ## - List of available constructors (user-facing names)
  ## - Internal discriminator values (for debugging)
  ## - Pattern representation
  ## - Variant type information
  ## - Suggestion for likely typos (using Levenshtein distance)
  ##
  ## Handles:
  ## - Non-existent constructor names
  ## - Wrong type name
  ## - Typo suggestions using Levenshtein distance
  ##
  ## Error message format:
  ##   Available constructors: Active, Inactive
  ##     (Internal discriminators: skActive, skInactive)
  ##   Did you mean 'Active'?
  ##
  ## This dual-format approach:
  ## - Shows users what they should type (Active, Inactive)
  ## - Provides internal representation for debugging (skActive, skInactive)
  ## - Maintains full transparency without sacrificing usability

  # Check if this is a variant type
  if not metadata.isVariant:
    result = "Pattern error: '" & typeName & "." & constructorName & "' is not a valid variant constructor.\n"
    result &= "  Type '" & metadata.typeName & "' is not a variant object.\n"
    result &= "  Pattern: " & pattern.repr & "\n"
    result &= "  Scrutinee type: " & prettyPrintType(metadata)
    return

  # STRUCTURAL QUERY: Extract both user-facing and internal names from metadata
  # These come from AST analysis (construct_metadata), not string heuristics
  var userFacingConstructors = newSeq[string]()
  var internalDiscriminators = newSeq[string]()

  for branch in metadata.branches:
    # Extract user-facing constructor name (what users type)
    let constructorName = extractConstructorName(branch.discriminatorValue)
    userFacingConstructors.add(constructorName)

    # Keep internal discriminator value (for debugging)
    internalDiscriminators.add(branch.discriminatorValue)

  # Generate field suggestions using Levenshtein distance on user-facing names
  let suggestion = generateFieldSuggestions(constructorName, userFacingConstructors)

  result = "Variant constructor '" & constructorName & "' does not exist in type '" & metadata.typeName & "'."
  if userFacingConstructors.len > 0:
    # Show user-facing constructor names first (what they should type)
    result &= "\n  Available constructors: " & userFacingConstructors.join(", ")
    # Show internal discriminator values second (for debugging/understanding)
    result &= "\n    (Internal discriminators: " & internalDiscriminators.join(", ") & ")"
  result &= "\n  Pattern: " & pattern.repr
  result &= "\n  Scrutinee type: variant object '" & metadata.typeName & "'"
  if suggestion != "":
    result &= suggestion

proc generatePatternTypeError(patternKind: PatternKind, metadata: ConstructMetadata,
                               pattern: NimNode): string =
  ## Generate comprehensive error message for pattern type incompatibility
  ## Includes:
  ## - Clear description of incompatibility
  ## - Pattern type
  ## - Scrutinee type
  ## - WHY explanation
  ## - HOW to fix suggestions
  ##
  ## Suggests appropriate pattern syntax based on scrutinee type

  result = "Pattern type incompatibility:\n"
  result &= "  Pattern type: " & $patternKind & "\n"
  result &= "  Scrutinee type: " & prettyPrintType(metadata) & "\n\n"

  # Add WHY explanation
  result &= "  Why incompatible:\n"
  case metadata.kind:
  of ckObject:
    if patternKind == pkTuple:
      result &= "    You're using a tuple pattern (a, b, c) on an object type.\n"
      result &= "    Objects have named fields, not positional elements.\n"
    elif patternKind == pkSequence:
      result &= "    You're using a sequence pattern [a, b, c] on an object type.\n"
      result &= "    Objects have named fields, not indexed elements.\n"
    else:
      result &= "    Pattern type '" & $patternKind & "' doesn't match object structure.\n"

  of ckTuple:
    if patternKind == pkObject:
      result &= "    You're using an object pattern Type(a, b) on a tuple.\n"
      result &= "    Tuples have positional elements, not named fields.\n"
    elif patternKind == pkSequence:
      result &= "    You're using a sequence pattern [a, b] on a tuple.\n"
      result &= "    Tuples use parentheses (), not brackets [].\n"
    else:
      result &= "    Pattern type '" & $patternKind & "' doesn't match tuple structure.\n"

  of ckSequence, ckArray:
    if patternKind == pkObject:
      result &= "    You're using an object pattern Type(a, b) on a " &
                (if metadata.kind == ckSequence: "sequence" else: "array") & ".\n"
      result &= "    Collections have indexed elements, not named fields.\n"
    elif patternKind == pkTuple:
      result &= "    You're using a tuple pattern (a, b) on a " &
                (if metadata.kind == ckSequence: "sequence" else: "array") & ".\n"
      result &= "    Collections use brackets [], not parentheses ().\n"
    else:
      result &= "    Pattern type '" & $patternKind & "' doesn't match collection structure.\n"

  of ckTable:
    result &= "    You're using a " & $patternKind & " pattern on a Table.\n"
    result &= "    Tables require key-value patterns: {\"key\": value, ...}.\n"

  of ckSet:
    result &= "    You're using a " & $patternKind & " pattern on a Set.\n"
    result &= "    Sets require element patterns: {elem1, elem2, ...}.\n"

  else:
    result &= "    Pattern type '" & $patternKind & "' is not compatible with " & $metadata.kind & " type.\n"

  result &= "\n  How to fix:\n"

  # Generate specific suggestions based on scrutinee type
  case metadata.kind:
  of ckObject:
    let fields = getAllFieldNames(metadata)
    if fields.len > 0:
      result &= "    Use object pattern: " &
                metadata.typeName & "(" & fields.join(", ") & ")\n"
    result &= "    Or use wildcard: _\n"

  of ckTuple:
    var placeholders = newSeq[string](metadata.tupleElements.len)
    for i in 0..<placeholders.len:
      placeholders[i] = "_"
    result &= "    Use tuple pattern: (" & placeholders.join(", ") & ")\n"
    result &= "    Or use wildcard: _\n"

  of ckSequence, ckArray:
    result &= "    Use sequence pattern: [elem1, elem2, ...]\n"
    result &= "    With spread: [first, *rest] or [*init, last]\n"
    result &= "    Or use wildcard: _\n"

  of ckTable:
    result &= "    Use table pattern: {\"key1\": val1, \"key2\": val2}\n"
    result &= "    With rest: {\"key\": val, **rest}\n"
    result &= "    Or use wildcard: _\n"

  of ckSet:
    result &= "    Use set pattern: {elem1, elem2, elem3}\n"
    result &= "    Or use wildcard: _\n"

  else:
    result &= "    Use a pattern that matches the scrutinee type,\n"
    result &= "    or use wildcard: _\n"

proc generateNestedPatternError(fieldPath: seq[string], depth: int,
                                 fieldName: string, metadata: ConstructMetadata,
                                 pattern: NimNode): string =
  ## Generate comprehensive error message for nested pattern validation errors
  ## Includes:
  ## - Clear indication of nesting depth
  ## - Field access path (e.g., "Outer.middle.inner.invalidField")
  ## - Pattern representation
  ## - Field availability information
  ## - Context about nesting depth
  ##
  ## Helps users understand where in a deeply nested pattern the error occurred

  result = "Nested pattern validation error at depth " & $depth & ":\n"
  result &= "  Path: " & fieldPath.join(".") & "\n"
  result &= "  Pattern: " & pattern.repr & "\n\n"

  let allFields = getAllFieldNames(metadata)
  result &= "  Field '" & fieldName & "' does not exist in type '" &
            metadata.typeName & "'.\n"
  if allFields.len > 0:
    result &= "  Available fields: " & allFields.join(", ") & "\n"

  result &= "\n  Context: Validating nested pattern at depth " & $depth &
            " of object hierarchy."

# ============================================================================
# Pattern Kind Inference
# ============================================================================

proc inferPatternKind*(pattern: NimNode): PatternKind =
  ## Classifies pattern type from AST structure using pure structural analysis.
  ##
  ## This function performs **syntax-only classification** based on AST node kinds
  ## and structure, with **zero semantic interpretation** of identifier names.
  ## Semantic disambiguation (e.g., `Some` as Option vs custom object) is deferred
  ## to `validatePatternStructure` which uses scrutinee metadata.
  ##
  ## **Classification Strategy:**
  ## - **Literals**: All literal node kinds (int, float, string, char, bool, nil)
  ## - **Variables**: Unquoted identifiers (except `_` and bool literals)
  ## - **Wildcard**: The `_` identifier
  ## - **Objects**: Call expressions (`Type(...)`) and dot expressions (`Type.Variant`)
  ## - **Tuples**: Tuple constructors `(...)`
  ## - **Sequences**: Bracket expressions `[...]` and sequence literals `@[...]`
  ## - **Tables**: Table constructors with key-value pairs `{key: value}`
  ## - **Sets**: Curly braces without colons `{elem1, elem2}`
  ## - **Guards**: Infix `and`/`or` operators
  ## - **OR patterns**: Infix `|` operator
  ## - **@ patterns**: Infix `@` operator
  ##
  ## **Ambiguity Handling:**
  ## - Empty `{}` defaults to pkSet (validated against scrutinee later)
  ## - Call expressions default to pkObject (Some/None/custom disambiguated later)
  ## - UFCS syntax `Type.Variant` classified as pkObject variant constructor
  ##
  ## Args:
  ##   pattern: Pattern AST node to classify
  ##
  ## Returns:
  ##   PatternKind enum representing the syntactic pattern type
  ##
  ## Example:
  ##   ```nim
  ##   let kind1 = inferPatternKind(newLit(42))  # pkLiteral
  ##   let kind2 = inferPatternKind(ident("x"))  # pkVariable
  ##   let kind3 = inferPatternKind(ident("_"))  # pkWildcard
  ##   ```
  ##
  ## Performance:
  ##   O(1) - Simple node kind matching with minimal child inspection
  ##
  ## See also:
  ##   - `analyzePattern` - Extracts complete pattern metadata
  ##   - `validatePatternStructure` - Semantic validation using metadata

  case pattern.kind:
  of nnkIdent:
    # Identifier - could be wildcard, bool literal, or variable
    if pattern.strVal == "_":
      return pkWildcard
    elif pattern.strVal in ["true", "false"]:
      return pkLiteral
    else:
      return pkVariable  # Could also be enum literal, but we treat as variable

  of nnkIntLit, nnkInt8Lit, nnkInt16Lit, nnkInt32Lit, nnkInt64Lit,
     nnkUIntLit, nnkUInt8Lit, nnkUInt16Lit, nnkUInt32Lit, nnkUInt64Lit,
     nnkFloat32Lit, nnkFloat64Lit, nnkFloat128Lit, nnkFloatLit,
     nnkStrLit, nnkRStrLit, nnkTripleStrLit, nnkCharLit, nnkNilLit:
    return pkLiteral

  of nnkCall, nnkObjConstr:
    # Call expression or object constructor - could be object constructor, option pattern, type constraint, etc.
    # Semantic disambiguation requires scrutinee metadata - done in validatePatternStructure
    # Default to pkObject and let metadata determine actual meaning
    # nnkObjConstr is used for object patterns in sequence contexts: [Employee(role: "Dev")]
    return pkObject

  of nnkDotExpr:
    # UFCS variant constructor pattern: Status.Active, TypeName.Constructor
    # This is the pattern syntax after the UFCS constructor collision fix
    # Example: Status.Active() in match becomes DotExpr after validateAndExtractArms
    if pattern.len == 2 and pattern[0].kind == nnkIdent and pattern[1].kind == nnkIdent:
      return pkObject  # Treat as variant constructor (object-like pattern)
    return pkUnknown

  of nnkBracket:
    # Bracket expression - sequence/array pattern
    return pkSequence

  of nnkTableConstr:
    # Table constructor - table pattern
    return pkTable

  of nnkCurly:
    # Curly braces - could be set pattern OR table pattern
    # Disambiguate by checking for key-value pairs or spread operators
    # Table pattern: {key: value, ...} or {**rest}
    # Set pattern: {elem1, elem2, ...}
    if pattern.len == 0:
      # Empty {} - ambiguous, default to pkSet (will be validated based on scrutinee)
      return pkSet
    # Check if any element is a key-value pair (nnkExprColonExpr) or spread (**rest)
    for element in pattern:
      if element.kind == nnkExprColonExpr:
        # Has key: value pairs - it's a table pattern
        return pkTable
      elif element.kind == nnkPrefix and element.len >= 2 and
           element[0].kind == nnkIdent and element[0].strVal == "**":
        # Has **rest spread operator - it's a table pattern
        return pkTable
    # No key-value pairs or spread - it's a set pattern
    return pkSet

  of nnkTupleConstr:
    # Tuple constructor - tuple pattern
    return pkTuple

  of nnkInfix:
    # Infix operator - OR, @, or guard pattern
    if pattern.len >= 3:
      let op = pattern[0].strVal
      if op == "|":
        return pkOr
      elif op == "@":
        return pkAt
      elif op in ["and", "or"]:
        return pkGuard
    return pkUnknown

  of nnkPrefix:
    # Prefix operator - sequence literals (@[...]), negation, or other prefix
    # CRITICAL: Distinguish between sequence literals and @ binding patterns
    # - Sequence literal: nnkPrefix(@, nnkBracket(...)) → @[1, 2, 3]
    # - @ binding pattern: nnkInfix(@, pattern, var) → pattern @ var
    if pattern.len >= 2 and pattern[0].kind == nnkIdent and pattern[0].strVal == "@":
      # Check if this is a sequence literal by examining the child
      if pattern[1].kind == nnkBracket:
        # This is a sequence literal: @[...]
        return pkSequence
      else:
        # This is an @ binding pattern (though normally these are nnkInfix)
        return pkAt
    return pkUnknown

  else:
    return pkUnknown

# ============================================================================
# Pattern Analysis
# ============================================================================

proc analyzePattern*(pattern: NimNode): PatternInfo {.noSideEffect.} =
  ## Extracts complete structural information about a pattern for validation and code generation.
  ##
  ## This function performs **deep structural analysis** of pattern AST nodes to extract
  ## all metadata needed for subsequent validation and code generation. It builds upon
  ## `inferPatternKind` by extracting pattern-specific details like field names,
  ## element counts, type names, and spread operators.
  ##
  ## **Extracted Information:**
  ## - **Pattern kind**: Via `inferPatternKind` (literal, variable, object, tuple, etc.)
  ## - **Type names**: For object patterns (`Point` from `Point(x, y)`)
  ## - **Field names**: For object patterns (positional and named fields)
  ## - **Element count**: For tuple/sequence patterns (-1 for variable-length)
  ## - **Spread detection**: For sequence patterns with `*rest` operators
  ## - **Constructor names**: For UFCS variant constructors (`Status.Active`)
  ##
  ## **Object Pattern Forms:**
  ## 1. Traditional call: `Type(field1, field2)`
  ## 2. Object constructor: `Type(field1: value1, field2: value2)`
  ## 3. UFCS variant: `TypeName.Constructor` (variant object syntax)
  ##
  ## **Sequence Pattern Analysis:**
  ## - Detects spread operators: `[first, *middle, last]`
  ## - Counts elements: Fixed count for exact patterns, -1 for spread patterns
  ## - Sets `isSpread` flag when `*` prefix operator detected
  ##
  ## Args:
  ##   pattern: Pattern AST node to analyze
  ##
  ## Returns:
  ##   PatternInfo object with complete pattern metadata
  ##
  ## Example:
  ##   ```nim
  ##   # Object pattern analysis
  ##   let info1 = analyzePattern(quote do: Point(x, y))
  ##   assert info1.kind == pkObject
  ##   assert info1.typeName == "Point"
  ##   assert info1.fieldNames == @["x", "y"]
  ##
  ##   # Sequence pattern analysis
  ##   let info2 = analyzePattern(quote do: [a, *rest, b])
  ##   assert info2.kind == pkSequence
  ##   assert info2.isSpread == true
  ##   assert info2.elementCount == -1
  ##
  ##   # Tuple pattern analysis
  ##   let info3 = analyzePattern(quote do: (x, y, z))
  ##   assert info3.kind == pkTuple
  ##   assert info3.elementCount == 3
  ##   ```
  ##
  ## Performance:
  ##   O(n) where n = number of pattern elements (fields, tuple elements, etc.)
  ##
  ## See also:
  ##   - `inferPatternKind` - Pattern kind classification
  ##   - `validatePatternStructure` - Uses PatternInfo for validation

  result = PatternInfo()
  result.kind = inferPatternKind(pattern)
  result.node = pattern
  result.elementCount = -1  # Default: variable length

  case result.kind:
  of pkObject:
    # Extract type name and field names from object pattern
    # Three forms supported:
    # 1. Traditional call: nnkCall(TypeName, field1, field2, ...)
    # 2. Object constructor: nnkObjConstr(TypeName, field1: value1, ...)
    # 3. UFCS constructor: nnkDotExpr(TypeName, Constructor)

    if pattern.kind == nnkDotExpr and pattern.len == 2:
      # UFCS variant constructor: Status.Active
      # TypeName is pattern[0], Constructor is pattern[1]
      result.typeName = pattern[0].strVal
      # Store constructor name in fieldNames for now (semantic meaning determined later)
      # This will be validated in validateVariantConstructorPattern
      result.fieldNames.add(pattern[1].strVal)

    elif pattern.kind in {nnkCall, nnkObjConstr} and pattern.len >= 1:
      result.typeName = pattern[0].strVal

      # Extract field names from arguments
      for i in 1..<pattern.len:
        let arg = pattern[i]
        case arg.kind:
        of nnkIdent:
          # Positional field: field
          result.fieldNames.add(arg.strVal)
        of nnkExprEqExpr, nnkExprColonExpr:
          # Named field: field=value or field:value
          if arg.len >= 1:
            result.fieldNames.add(arg[0].strVal)
        else:
          # Other patterns (guards, @, etc.) - skip for now
          discard

  of pkTuple:
    # Count tuple elements
    result.elementCount = pattern.len

  of pkSequence:
    # Check for spread operator and count elements
    result.isSpread = false

    for element in pattern:
      if element.kind == nnkPrefix and element.len >= 2 and
         element[0].strVal == "*":
        result.isSpread = true
        break

    # Element count (-1 for spread patterns indicating variable length)
    if result.isSpread:
      result.elementCount = -1
    else:
      result.elementCount = pattern.len

  else:
    # Other pattern kinds don't need additional analysis
    discard

# ============================================================================
# Main Validation Entry Point
# ============================================================================

proc validatePatternStructure*(pattern: NimNode, metadata: ConstructMetadata): ValidationResult {.noSideEffect.} =
  ## **Main validation entry point** - validates patterns against scrutinee metadata using structural queries.
  ##
  ## This is the **central validation dispatcher** for the entire pattern matching library.
  ## It implements the core philosophy: **pattern syntax alone is insufficient** - we must
  ## query scrutinee metadata to determine semantic meaning and compatibility.
  ##
  ## **Metadata-Driven Validation Philosophy:**
  ## Pattern matching requires semantic understanding that pure AST analysis cannot provide.
  ## Consider `Some(x)` - is it an Option pattern or a custom object constructor? Only
  ## scrutinee metadata reveals the truth. This function uses `ConstructMetadata` from
  ## `analyzeConstructMetadata` to make informed validation decisions.
  ##
  ## **Validation Strategy:**
  ## 1. Analyze pattern structure via `analyzePattern`
  ## 2. Handle meta-patterns (guards, OR, @) by recursively validating underlying patterns
  ## 3. Dispatch to type-specific validators based on scrutinee metadata kind
  ## 4. Generate rich, actionable error messages with suggestions (Levenshtein distance, etc.)
  ##
  ## **Always-Valid Patterns:**
  ## - **Variables**: `x`, `name`, `value` - bind to any scrutinee
  ## - **Wildcards**: `_` - matches anything without binding
  ##
  ## **Meta-Pattern Handling:**
  ## - **Guards** (`pattern and condition`): Validates underlying pattern
  ## - **OR patterns** (`a | b`): Valid if at least ONE side is valid
  ## - **@ patterns** (`pattern @ name`): Validates underlying pattern
  ##
  ## **Type-Specific Dispatch:**
  ## Based on `metadata.kind`, dispatches to:
  ## - `validateObjectPattern` - Object/variant patterns
  ## - `validateTuplePattern` - Tuple patterns
  ## - `validateSequencePattern` - Sequence/array patterns
  ## - `validateTablePattern` - Table/dict patterns
  ## - `validateSetPattern` - Set patterns
  ## - `validateEnumPattern` - Enum patterns (flexible: literals, OR, sets)
  ## - `validateRefPattern` - Reference type patterns
  ## - `validatePtrPattern` - Pointer type patterns
  ## - `validateDequePattern` - Deque patterns
  ## - `validateLinkedListPattern` - LinkedList patterns
  ## - `validateJsonNodePattern` - JSON patterns
  ##
  ## **Ambiguity Resolution:**
  ## - Empty `{}`: Could be set or table - allowed on both, validated by context
  ## - `Some(x)`: Option pattern vs object - disambiguated via metadata
  ## - Set patterns on sequences: Allowed (converts to HashSet comparison)
  ##
  ## Args:
  ##   pattern: Pattern AST node to validate
  ##   metadata: Scrutinee metadata from `analyzeConstructMetadata`
  ##
  ## Returns:
  ##   ValidationResult with:
  ##   - `isValid`: true if pattern is compatible with scrutinee
  ##   - `errorMessage`: Empty if valid, detailed error with suggestions if invalid
  ##
  ## Example:
  ##   ```nim
  ##   # Validating object pattern
  ##   type Point = object
  ##     x, y: int
  ##
  ##   let metadata = analyzeConstructMetadata(Point.getTypeInst())
  ##   let pattern = quote do: Point(x, y)
  ##   let result = validatePatternStructure(pattern, metadata)
  ##   assert result.isValid == true
  ##
  ##   # Invalid field access
  ##   let badPattern = quote do: Point(z)
  ##   let badResult = validatePatternStructure(badPattern, metadata)
  ##   assert badResult.isValid == false
  ##   # Error suggests: "Did you mean: x, y?"
  ##   ```
  ##
  ## Performance:
  ##   O(1) dispatch + cost of type-specific validator
  ##
  ## See also:
  ##   - `analyzeConstructMetadata` - Extracts scrutinee metadata (construct_metadata.nim)
  ##   - `analyzePattern` - Extracts pattern metadata
  ##   - `validateObjectPattern` - Object pattern validator
  ##   - `validateTuplePattern` - Tuple pattern validator
  ##   - `validateSequencePattern` - Sequence pattern validator
  ##   - All other type-specific validators

  let patternInfo = analyzePattern(pattern)

  # Handle meta-patterns (guards, OR, @) that wrap other patterns
  # These need to be handled before type-specific validation
  case patternInfo.kind:
  of pkGuard:
    # Guard pattern: pattern and condition
    # Validate the underlying pattern (left side of 'and')
    if pattern.kind == nnkInfix and pattern.len >= 3:
      let underlyingPattern = pattern[1]
      return validatePatternStructure(underlyingPattern, metadata)
    return ValidationResult(isValid: true, errorMessage: "")

  of pkOr:
    # OR pattern: pattern1 | pattern2
    # For mixed-type OR patterns (e.g., "hello" | false on bool),
    # at least ONE side must be valid for the scrutinee type
    if pattern.kind == nnkInfix and pattern.len >= 3:
      let leftPattern = pattern[1]
      let rightPattern = pattern[2]
      let leftResult = validatePatternStructure(leftPattern, metadata)
      let rightResult = validatePatternStructure(rightPattern, metadata)

      # If at least one side is valid, the OR pattern is valid
      if leftResult.isValid or rightResult.isValid:
        return ValidationResult(isValid: true, errorMessage: "")

      # Both sides are invalid - return error from left side
      return leftResult
    return ValidationResult(isValid: true, errorMessage: "")

  of pkAt:
    # @ pattern: pattern @ name
    # Validate the underlying pattern (left side of '@')
    if pattern.kind == nnkInfix and pattern.len >= 3:
      let underlyingPattern = pattern[1]
      return validatePatternStructure(underlyingPattern, metadata)
    return ValidationResult(isValid: true, errorMessage: "")

  else:
    discard  # Continue to type-specific validation

  # Use METADATA to determine what patterns are valid
  case metadata.kind:
  of ckObject, ckVariantObject:
    # Scrutinee is object - pattern must be object-compatible
    case patternInfo.kind:
    of pkObject:
      return validateObjectPattern(pattern, metadata)
    of pkVariable, pkWildcard:
      return ValidationResult(isValid: true, errorMessage: "")  # Variable/wildcard always valid
    else:
      let errorMsg = generatePatternTypeError(patternInfo.kind, metadata, pattern)
      return ValidationResult(isValid: false, errorMessage: errorMsg)

  of ckTuple:
    # Scrutinee is tuple - pattern must be tuple-compatible
    case patternInfo.kind:
    of pkTuple:
      return validateTuplePattern(pattern, metadata)
    of pkVariable, pkWildcard:
      return ValidationResult(isValid: true, errorMessage: "")
    else:
      let errorMsg = generatePatternTypeError(patternInfo.kind, metadata, pattern)
      return ValidationResult(isValid: false, errorMessage: errorMsg)

  of ckSequence, ckArray:
    # Scrutinee is sequence/array - pattern must be sequence-compatible
    case patternInfo.kind:
    of pkSequence:
      return validateSequencePattern(pattern, metadata)
    of pkSet:
      # Set patterns on arrays/sequences are ALLOWED for HashSet conversion
      # e.g., {1, 2, 3} on [1, 2, 3] → converts both to HashSet for comparison
      # This is used for set-based matching on array/sequence types
      return validateSetPattern(pattern, metadata)
    of pkVariable, pkWildcard:
      return ValidationResult(isValid: true, errorMessage: "")
    else:
      let errorMsg = generatePatternTypeError(patternInfo.kind, metadata, pattern)
      return ValidationResult(isValid: false, errorMessage: errorMsg)

  of ckTable:
    # Scrutinee is table - pattern must be table-compatible
    case patternInfo.kind:
    of pkTable:
      return validateTablePattern(pattern, metadata)
    of pkSet:
      # AMBIGUITY: Empty {} can be either set or table
      # Allow empty set pattern {} on tables (it means empty table)
      if pattern.kind == nnkCurly and pattern.len == 0:
        return ValidationResult(isValid: true, errorMessage: "")
      else:
        # Non-empty set pattern on table - invalid
        let errorMsg = generatePatternTypeError(patternInfo.kind, metadata, pattern)
        return ValidationResult(isValid: false, errorMessage: errorMsg)
    of pkVariable, pkWildcard:
      return ValidationResult(isValid: true, errorMessage: "")
    else:
      let errorMsg = generatePatternTypeError(patternInfo.kind, metadata, pattern)
      return ValidationResult(isValid: false, errorMessage: errorMsg)

  of ckSet:
    # Scrutinee is set - pattern must be set-compatible
    case patternInfo.kind:
    of pkSet:
      return validateSetPattern(pattern, metadata)
    of pkVariable, pkWildcard:
      return ValidationResult(isValid: true, errorMessage: "")
    else:
      let errorMsg = generatePatternTypeError(patternInfo.kind, metadata, pattern)
      return ValidationResult(isValid: false, errorMessage: errorMsg)

  of ckEnum:
    # Scrutinee is enum - use direct validation (enums support many pattern types)
    # Enum patterns are flexible: literals, variables, OR, sets, guards
    # Use validateEnumPattern which handles all these cases structurally
    return validateEnumPattern(pattern, metadata)

  of ckOption:
    # Scrutinee is Option - use METADATA to determine if pattern is valid
    # Pattern Some(x) or None() are now classified as pkObject (no name-based guessing)
    # Use metadata to disambiguate: is this an Option pattern or Object pattern?
    case patternInfo.kind:
    of pkObject:
      # Check if pattern is Some/None call (Option pattern syntax)
      if pattern.kind == nnkCall and pattern.len >= 1 and pattern[0].kind == nnkIdent:
        let callName = pattern[0].strVal
        if callName in ["Some", "None"]:
          # METADATA says Option, SYNTAX says Some/None → Option pattern!
          return ValidationResult(isValid: true, errorMessage: "")

      # Not Some/None - invalid for Option type
      let errorMsg = "Pattern type incompatibility:\\n" &
                    "  Pattern: " & pattern.repr & "\\n" &
                    "  Scrutinee type: " & prettyPrintType(metadata) & "\\n\\n" &
                    "  Option types can only be matched with Some(x) or None() patterns."
      return ValidationResult(isValid: false, errorMessage: errorMsg)

    of pkVariable, pkWildcard:
      return ValidationResult(isValid: true, errorMessage: "")

    else:
      let errorMsg = generatePatternTypeError(patternInfo.kind, metadata, pattern)
      return ValidationResult(isValid: false, errorMessage: errorMsg)

  of ckReference:
    # Scrutinee is ref type - validate underlying type access patterns
    return validateRefPattern(pattern, metadata)

  of ckPointer:
    # Scrutinee is ptr type - validate underlying type access patterns
    return validatePtrPattern(pattern, metadata)

  of ckDeque:
    # Scrutinee is Deque - validate sequence-like patterns
    return validateDequePattern(pattern, metadata)

  of ckLinkedList:
    # Scrutinee is LinkedList - validate sequence-like patterns
    return validateLinkedListPattern(pattern, metadata)

  of ckJsonNode:
    # Scrutinee is JsonNode - validate JSON patterns
    return validateJsonNodePattern(pattern, metadata)

  of ckSimpleType, ckOrdinal, ckRange, ckDistinct, ckUnknown:
    # For simple types (string, int, bool, float, char, etc.), ordinals, ranges, distinct types
    # Reject inappropriate composite pattern kinds
    # Valid: literals, variables, wildcards, guards, OR, @, set (as OR chain sugar)
    # Invalid: table, sequence, tuple, object patterns
    case patternInfo.kind:
    of pkLiteral, pkVariable, pkWildcard, pkGuard, pkOr, pkAt, pkType:
      # These patterns are valid for simple types
      return ValidationResult(isValid: true, errorMessage: "")
    of pkSet:
      # Set patterns on ordinal scalar types are ALLOWED as OR pattern sugar
      # e.g., {1, 2, 3} on int → converts to 1 | 2 | 3
      # This is valid for: int, char, bool, enum (ordinal types)
      # Reject for non-ordinal types like string, float
      if metadata.kind == ckOrdinal or metadata.typeName in ["int", "char", "bool"]:
        return ValidationResult(isValid: true, errorMessage: "")
      else:
        # Non-ordinal type (string, float, etc.) - reject set pattern
        let errorMsg = "Pattern type incompatibility:\n" &
                      "  Cannot use set pattern syntax {...} on non-ordinal type\n" &
                      "  Pattern: " & pattern.repr & "\n" &
                      "  Scrutinee type: " & prettyPrintType(metadata) & "\n\n" &
                      "  Set patterns are only valid for ordinal types (int, char, bool, enum)\n" &
                      "  For strings, use OR patterns: \"a\" | \"b\" | \"c\""
        return ValidationResult(isValid: false, errorMessage: errorMsg)
    of pkTable:
      # Table pattern on non-table type
      let errorMsg = "Pattern type incompatibility:\n" &
                    "  Cannot use table pattern syntax {...: ...} on non-table type\n" &
                    "  Pattern: " & pattern.repr & "\n" &
                    "  Scrutinee type: " & prettyPrintType(metadata) & "\n\n" &
                    "  Fix: Use appropriate pattern for the scrutinee type"
      return ValidationResult(isValid: false, errorMessage: errorMsg)
    of pkSequence:
      # Sequence pattern on non-sequence type
      let errorMsg = "Pattern type incompatibility:\n" &
                    "  Cannot use sequence pattern syntax [...] on non-sequence type\n" &
                    "  Pattern: " & pattern.repr & "\n" &
                    "  Scrutinee type: " & prettyPrintType(metadata) & "\n\n" &
                    "  Fix: Use appropriate pattern for the scrutinee type"
      return ValidationResult(isValid: false, errorMessage: errorMsg)
    of pkTuple:
      # Tuple pattern on non-tuple type
      let errorMsg = "Pattern type incompatibility:\n" &
                    "  Cannot use tuple pattern syntax (...) on non-tuple type\n" &
                    "  Pattern: " & pattern.repr & "\n" &
                    "  Scrutinee type: " & prettyPrintType(metadata) & "\n\n" &
                    "  Fix: Use appropriate pattern for the scrutinee type"
      return ValidationResult(isValid: false, errorMessage: errorMsg)
    of pkObject:
      # Object pattern on non-object type
      let errorMsg = "Pattern type incompatibility:\n" &
                    "  Cannot use object pattern syntax Type(...) on non-object type\n" &
                    "  Pattern: " & pattern.repr & "\n" &
                    "  Scrutinee type: " & prettyPrintType(metadata) & "\n\n" &
                    "  Fix: Use appropriate pattern for the scrutinee type"
      return ValidationResult(isValid: false, errorMessage: errorMsg)
    else:
      # Unknown pattern kind - allow by default
      return ValidationResult(isValid: true, errorMessage: "")

  else:
    # For any other construct kinds not explicitly handled above
    # Allow patterns by default to avoid false positives
    return ValidationResult(isValid: true, errorMessage: "")

# ============================================================================
# Literal Type Inference Helpers
# ============================================================================

proc inferLiteralType*(node: NimNode): string =
  ## Infers the Nim type of a literal AST node from its node kind.
  ##
  ## This function performs **pure structural type inference** on literal nodes by examining
  ## AST node kinds (nnkIntLit, nnkStrLit, etc.), with **zero string heuristics**. Returns
  ## empty string for non-literal nodes (variables, expressions, etc.).
  ##
  ## **Type Inference Rules:**
  ## - Integer literals: `nnkIntLit` variants → `"int"` or `"uint"`
  ## - Float literals: `nnkFloatLit` variants → `"float"`
  ## - String literals: `nnkStrLit` variants → `"string"`
  ## - Character literals: `nnkCharLit` → `"char"`
  ## - Boolean literals: `true`/`false` identifiers → `"bool"`
  ## - Nil literal: `nnkNilLit` → `"nil"`
  ## - Non-literals: Variables, expressions → `""` (empty)
  ##
  ## **Use Cases:**
  ## - Compile-time literal type validation in patterns
  ## - Detecting type mismatches (e.g., `"string"` in `int` sequence)
  ## - Generating type-specific error messages
  ##
  ## Args:
  ##   node: AST node to infer type from
  ##
  ## Returns:
  ##   Type name as string (`"int"`, `"string"`, etc.), or `""` if not a literal
  ##
  ## Example:
  ##   ```nim
  ##   assert inferLiteralType(newLit(42)) == "int"
  ##   assert inferLiteralType(newLit("hello")) == "string"
  ##   assert inferLiteralType(ident("x")) == ""  # Not a literal
  ##   ```
  ##
  ## Performance:
  ##   O(1) - Simple node kind switch
  ##
  ## See also:
  ##   - `typesAreCompatible` - Type compatibility checking
  ##   - `isLiteralCompatibleWithType` - Metadata-based compatibility

  case node.kind:
  of nnkIntLit, nnkInt8Lit, nnkInt16Lit, nnkInt32Lit, nnkInt64Lit:
    return "int"
  of nnkUIntLit, nnkUInt8Lit, nnkUInt16Lit, nnkUInt32Lit, nnkUInt64Lit:
    return "uint"
  of nnkFloatLit, nnkFloat32Lit, nnkFloat64Lit, nnkFloat128Lit:
    return "float"
  of nnkStrLit, nnkRStrLit, nnkTripleStrLit:
    return "string"
  of nnkCharLit:
    return "char"
  of nnkIdent:
    # Check for bool literals
    if node.strVal in ["true", "false"]:
      return "bool"
    return ""  # Variable or identifier, not a literal
  of nnkNilLit:
    return "nil"
  else:
    return ""

proc typesAreCompatible*(actualType, expectedType: string): bool =
  ## Checks type compatibility using Nim's pattern matching type rules with structural analysis.
  ##
  ## This function implements **Nim-specific type compatibility rules** for pattern matching,
  ## handling numeric coercion, type aliases, and explicit incompatibilities (char/int, bool/int, etc.).
  ## Uses **pure structural type name comparison** - no string heuristics.
  ##
  ## **Compatibility Rules:**
  ## - **Direct match**: `int` ↔ `int`, `string` ↔ `string`
  ## - **Nil compatibility**: `nil` compatible with any type (ref types, Options)
  ## - **Numeric coercion**: `int` literal can match `uint16`, `float`, etc.
  ## - **Float restriction**: `float` literals only match float types, NOT `int`
  ## - **Type aliases**: `float` ↔ `float64`
  ##
  ## **Explicit Incompatibilities:**
  ## - `char` ↔ `int` (bug fix #5, #8)
  ## - `bool` ↔ `int` (bug fix #6)
  ## - `bool` ↔ `string` (bug fix #9)
  ##
  ## **Numeric Literal Rules (matches Nim's type system):**
  ## 1. Integer literals (42) → ANY numeric type (int, uint16, float, etc.) ✓
  ## 2. Float literals (42.5) → ONLY float types (float, float32, float64) ✓
  ## 3. This ensures pattern validation matches Nim's type coercion semantics
  ##
  ## Args:
  ##   actualType: Type of literal/pattern element
  ##   expectedType: Expected type from metadata
  ##
  ## Returns:
  ##   true if types are compatible for pattern matching
  ##
  ## Example:
  ##   ```nim
  ##   assert typesAreCompatible("int", "int")
  ##   assert typesAreCompatible("int", "uint16")  # Numeric coercion
  ##   assert typesAreCompatible("int", "float")   # Integer literal → float
  ##   assert not typesAreCompatible("float", "int")  # Float literal ≠ int
  ##   assert not typesAreCompatible("char", "int")  # Explicit incompatibility
  ##   ```
  ##
  ## Performance:
  ##   O(1) - String comparisons and set membership checks
  ##
  ## See also:
  ##   - `inferLiteralType` - Extract literal type from AST
  ##   - `isLiteralCompatibleWithType` - Metadata-driven compatibility checking

  # Direct match
  if actualType == expectedType:
    return true

  # nil is ONLY compatible with reference types (ref, ptr, Option, cstring, pointer)
  # Value types (int, string, float, bool, char, etc.) CANNOT be nil
  # This catches obvious type errors at compile time
  if actualType == "nil":
    # Allow nil for reference types
    if expectedType.startsWith("ref ") or
       expectedType.startsWith("ptr ") or
       expectedType.startsWith("Option[") or
       expectedType in ["cstring", "pointer", "ptr", "ref"]:
      return true
    # Reject nil for value types (int, string, float, bool, char, etc.)
    else:
      return false

  # BUG #5, #8: Reject char/int incompatibility (both directions)
  # Chars and ints are NOT compatible in pattern matching
  if (actualType == "char" and expectedType in ["int", "int8", "int16", "int32", "int64",
                                                  "uint", "uint8", "uint16", "uint32", "uint64"]):
    return false
  if (expectedType == "char" and actualType in ["int", "int8", "int16", "int32", "int64",
                                                  "uint", "uint8", "uint16", "uint32", "uint64"]):
    return false

  # BUG #6: Reject bool/int incompatibility
  # Bool and int are NOT compatible in pattern matching (even though bool is an enum in Nim)
  if (actualType == "bool" and expectedType in ["int", "int8", "int16", "int32", "int64",
                                                  "uint", "uint8", "uint16", "uint32", "uint64"]):
    return false
  if (expectedType == "bool" and actualType in ["int", "int8", "int16", "int32", "int64",
                                                  "uint", "uint8", "uint16", "uint32", "uint64"]):
    return false

  # BUG #9: Reject bool/string incompatibility
  # Bool and string are NOT compatible in pattern matching
  if (actualType == "bool" and expectedType == "string"):
    return false
  if (expectedType == "bool" and actualType == "string"):
    return false

  # Helper to check if a type is an integer type
  proc isIntegerType(t: string): bool =
    t in ["int", "int8", "int16", "int32", "int64",
          "uint", "uint8", "uint16", "uint32", "uint64"]

  # Helper to check if a type is a float type
  proc isFloatType(t: string): bool =
    t in ["float", "float32", "float64"]

  # Helper to check if a type is numeric (int or float)
  proc isNumericType(t: string): bool =
    isIntegerType(t) or isFloatType(t)

  # Nim's numeric literal compatibility rules for pattern matching:
  # 1. Integer literals (42) can match ANY numeric type (int, uint16, float, etc.)
  #    - Nim allows: let x: float = 42  ✓
  # 2. Float literals (42.5) can ONLY match float types, NOT integer types
  #    - Nim rejects: let x: int = 42.5  ✗
  # 3. This ensures pattern matching validation matches Nim's type system

  # Integer literals can match any numeric type
  # Note: Range type checking moved to metadata-based function below
  if isIntegerType(actualType) and isNumericType(expectedType):
    return true

  # Float literals can ONLY match float types (strict checking)
  if isFloatType(actualType) and isFloatType(expectedType):
    return true

  return false

proc isLiteralCompatibleWithType*(literalType: string, expectedTypeStr: string, typeNode: NimNode): bool =
  ## Check if a literal type is compatible with an expected type using structural metadata analysis
  ## This function uses AST-based type checking for range detection while maintaining string-based fallbacks
  ##
  ## Parameters:
  ##   - literalType: The type of the literal (e.g., "int", "string") from inferLiteralType()
  ##   - expectedTypeStr: The expected type as a string (from metadata.elementType, etc.)
  ##   - typeNode: The AST node representing the expected type (for structural analysis)
  ##
  ## Returns: true if the literal can match the expected type
  ##
  ## Note: typeNode may be invalid/placeholder in some cases (e.g., CountTable valueTypeNode),
  ##       so we always check expectedTypeStr first before using structural analysis

  # Special handling for nil literals: check if target type is a reference type
  if literalType == "nil":
    # If we have a type node, use structural analysis to detect reference types
    if typeNode != nil and typeNode.kind != nnkEmpty:
      let typeMetadata = analyzeConstructMetadata(typeNode)
      # Allow nil for reference types (ref, ptr, Option)
      if typeMetadata.kind in {ckReference, ckPointer, ckOption}:
        return true
      # Also allow for cstring and pointer keywords
      if expectedTypeStr in ["cstring", "pointer", "ptr", "ref"]:
        return true
      # Reject nil for value types
      return false
    # No type node available, fallback to string-based check
    elif typesAreCompatible(literalType, expectedTypeStr):
      return true
    else:
      return false

  # Use typesAreCompatible for basic string-based checks (non-nil cases)
  if typesAreCompatible(literalType, expectedTypeStr):
    return true

  # If typeNode is not available or invalid, we can't do structural analysis
  if typeNode == nil or typeNode.kind == nnkEmpty:
    return false

  # Analyze the expected type to get its metadata for range detection
  let typeMetadata = analyzeConstructMetadata(typeNode)

  # Validate that the type node actually represents the expected type
  # (In some cases like CountTable, valueTypeNode is a placeholder and doesn't match valueType string)
  # Only use structural metadata if it matches the expected type string
  if typeMetadata.typeName != expectedTypeStr:
    # Type node doesn't match expected type string, don't use it for structural checks
    return false

  # Helper to check if a type is an integer type
  proc isIntegerType(t: string): bool =
    t in ["int", "int8", "int16", "int32", "int64",
          "uint", "uint8", "uint16", "uint32", "uint64"]

  # Helper to check if a type is numeric (int or float)
  proc isNumericType(t: string): bool =
    t in ["int", "int8", "int16", "int32", "int64",
          "uint", "uint8", "uint16", "uint32", "uint64",
          "float", "float32", "float64"]

  # Integer literals can match range types (proper structural check)
  # Example: literal 42 can match range[0..255]
  if isIntegerType(literalType) and typeMetadata.kind == ckRange:
    return true

  # Range type values can match integer types ONLY (not floats)
  # Example: range[0..10] value can match int
  # Note: Float literals cannot match range types (ranges are integer-only)
  if typeMetadata.kind == ckRange and isIntegerType(literalType):
    return true

  return false

proc generateLiteralTypeMismatchError*(literalType, expectedType: string,
                                        position: int, pattern: NimNode): string =
  ## Generate error message for literal type mismatch
  ## Provides clear, actionable feedback about the type error
  ##
  ## Example output:
  ##   "Literal type mismatch at position 0:
  ##    Expected: int
  ##    Got: string (literal: "wrong")
  ##
  ##    Fix: Use an int literal like 42 instead of a string"

  result = "Literal type mismatch at position " & $position & ":\\n"
  result &= "  Expected: " & expectedType & "\\n"
  result &= "  Got: " & literalType & "\\n\\n"
  result &= "  Pattern: " & pattern.repr & "\\n\\n"

  # Provide helpful suggestion
  case expectedType:
  of "int":
    result &= "  Fix: Use an int literal like 42, not a " & literalType
  of "string":
    result &= "  Fix: Use a string literal like \\\"text\\\", not a " & literalType
  of "float":
    result &= "  Fix: Use a float literal like 3.14, not a " & literalType
  of "bool":
    result &= "  Fix: Use a bool literal (true or false), not a " & literalType
  of "char":
    result &= "  Fix: Use a char literal like 'a', not a " & literalType
  else:
    result &= "  Fix: Use a " & expectedType & " value, not a " & literalType

# ============================================================================
# Specific Pattern Validators
# ============================================================================

proc validateVariantConstructorPattern*(pattern: NimNode, metadata: ConstructMetadata): ValidationResult {.noSideEffect.} =
  ## Validates UFCS variant constructor patterns with strict type and field checking.
  ##
  ## This validator handles **UFCS (Uniform Function Call Syntax) variant constructors** like
  ## `Status.Active` or `Status.Active(msg)`, performing strict validation of type names,
  ## discriminator values, field counts, and field types using **pure structural queries**.
  ##
  ## **Validation Strategy:**
  ## - **Strict type matching**: Type name must EXACTLY match scrutinee (prevents cross-type pollution)
  ## - **Structural queries**: Uses metadata branches to validate constructors
  ## - **Field count**: Validates argument count matches branch field requirements
  ## - **Field types**: Literal field values validated against branch field types
  ## - **Discriminator mapping**: Maps constructor name to discriminator enum value
  ##
  ## **Supported Pattern Forms:**
  ## 1. **Simple UFCS**: `Status.Active` (nnkDotExpr, no parentheses)
  ## 2. **UFCS with fields**: `Status.Active(msg)` (nnkCall wrapping nnkDotExpr)
  ##
  ## **Type Name Matching:**
  ## - Direct match: `"Status"` == `"Status"`
  ## - Suffix match: `"Status:ObjectType"` matches `"Status"` (Nim adds suffix)
  ## - Union type aliases: Handles `UnionType1_int_string` aliasing
  ##
  ## **Constructor Name Matching (Bug PV-1 Fix):**
  ## - Exact match: `"skActive"` == `"skActive"`
  ## - Suffix match with 'k' separator: `"skActive".endsWith("Active")` AND char before is 'k'
  ## - Prevents false positives: `"Active"` should NOT match `"skIntActive"`
  ##
  ## Args:
  ##   pattern: UFCS variant pattern AST node (nnkDotExpr or nnkCall)
  ##   metadata: Scrutinee metadata with variant object structure
  ##
  ## Returns:
  ##   ValidationResult with detailed error on mismatch
  ##
  ## Example:
  ##   ```nim
  ##   type Status = object
  ##     case kind: StatusKind
  ##     of skActive: message: string
  ##     of skIdle: discard
  ##
  ##   # Valid: Correct constructor, correct field count
  ##   let pattern1 = quote do: Status.Active("running")
  ##   assert validateVariantConstructorPattern(pattern1, metadata).isValid
  ##
  ##   # Invalid: Wrong type name
  ##   let pattern2 = quote do: Result.Active("running")  # Error!
  ##   assert not validateVariantConstructorPattern(pattern2, metadata).isValid
  ##   ```
  ##
  ## Performance:
  ##   O(b + f) where b = branch count, f = field count
  ##
  ## See also:
  ##   - `validateObjectPattern` - Delegates UFCS patterns to this validator
  ##   - `findMatchingDiscriminatorValue` - Maps constructor names (construct_metadata.nim)

  # Handle both nnkDotExpr and nnkCall patterns
  var typeName: string
  var constructorName: string
  var providedFieldCount = 0
  var providedFields: seq[NimNode] = @[]

  if pattern.kind == nnkDotExpr and pattern.len == 2:
    # Simple UFCS: Status.Active (no parentheses)
    typeName = pattern[0].strVal
    constructorName = pattern[1].strVal
    providedFieldCount = 0

  elif pattern.kind == nnkCall and pattern.len >= 1 and pattern[0].kind == nnkDotExpr and pattern[0].len == 2:
    # UFCS with parentheses: Status.Active() or Status.Active(field1, field2)
    typeName = pattern[0][0].strVal
    constructorName = pattern[0][1].strVal
    providedFieldCount = pattern.len - 1  # Exclude the DotExpr itself
    for i in 1 ..< pattern.len:
      providedFields.add(pattern[i])

  else:
    return ValidationResult(isValid: false, errorMessage: "Invalid UFCS constructor pattern syntax")

  # STRUCTURAL QUERY: STRICT type name check for UFCS variant patterns
  # For UFCS patterns (Status.Active), the type name MUST exactly match the scrutinee type
  # This prevents: Result.Active when scrutinee is Status, StatusB.Active when scrutinee is StatusA
  #
  # Allowed matches:
  # 1. Direct match: "Status" == "Status"
  # 2. Suffix match: "Status:ObjectType" matches "Status" (Nim adds :ObjectType suffix)
  # 3. Union type aliases: "UnionType1_int_string" with pattern using alias name
  var typeMatches = false

  # Direct match
  if metadata.typeName == typeName:
    typeMatches = true
  # Suffix match (Nim adds :ObjectType to object types)
  elif metadata.typeName.startsWith(typeName & ":"):
    typeMatches = true
  # Union type alias match
  elif metadata.isUnion and metadata.typeName.startsWith("UnionType") and not typeName.startsWith("UnionType"):
    typeMatches = true

  if not typeMatches:
    let errorMsg = generateTypeMismatchError(typeName, metadata, pattern)
    return ValidationResult(isValid: false, errorMessage: errorMsg)

  # STRUCTURAL QUERY: For variant objects, check that branches exist
  if metadata.isVariant:
    # Structural check: variant must have at least one branch
    if metadata.branches.len == 0:
      return ValidationResult(isValid: false,
                             errorMessage: "Variant type '" & metadata.typeName &
                                         "' has no branches (empty variant)")

    # Check if constructor name matches ANY discriminator value
    # We check by seeing if the constructor name appears in any discriminator
    # This is still using the metadata structure, not generating strings
    var matchingBranch: VariantBranch
    var found = false
    for branch in metadata.branches:
      # STRUCTURAL QUERY: Check if discriminator matches constructor name
      # The discriminator values come from AST analysis (construct_metadata)
      # We check for exact match OR suffix match (not substring match anywhere)
      # - Exact match: "skInt" == "skInt" (full discriminator value)
      # - Suffix match: "skInt".endsWith("Int") (constructor name without prefix)
      # NOTE: Using `in` operator would be too permissive - "Int" would match
      #       "skPr**int**erKind" as a substring, causing false positives
      #
      # IMPORTANT (BUG PV-1 FIX): Must verify the character before constructor name is 'k'
      # - Correct: "skActive".endsWith("Active") AND char before "Active" is 'k' ✓
      # - Incorrect: "skIntActive".endsWith("Active") but char before "Active" is 't' ✗
      # This prevents false positives like "Active" matching "IntActive"
      if constructorName == branch.discriminatorValue:
        found = true
        matchingBranch = branch
        break
      elif branch.discriminatorValue.endsWith(constructorName):
        # Verify that the character immediately before the constructor name is 'k' (separator)
        let prefixLen = branch.discriminatorValue.len - constructorName.len
        if prefixLen >= 1 and branch.discriminatorValue[prefixLen - 1] == 'k':
          found = true
          matchingBranch = branch
          break

    if not found:
      let errorMsg = generateVariantConstructorError(typeName, constructorName, metadata, pattern)
      return ValidationResult(isValid: false, errorMessage: errorMsg)

    # FIELD COUNT VALIDATION: Check if pattern provides correct number of fields
    let expectedFieldCount = matchingBranch.fields.len

    if providedFieldCount != expectedFieldCount:
      let errorMsg = "Field count mismatch in UFCS variant pattern:\n" &
                    "  Pattern: " & pattern.repr & "\n" &
                    "  Constructor '" & constructorName & "' expects " & $expectedFieldCount &
                    " field(s), but pattern provides " & $providedFieldCount & " field(s)\n\n" &
                    (if expectedFieldCount > 0:
                      "  Expected fields:\n" &
                      (block:
                        var fieldList = ""
                        for field in matchingBranch.fields:
                          fieldList &= "    - " & field.name & ": " & field.fieldType & "\n"
                        fieldList)
                    else:
                      "  Constructor takes no fields\n") &
                    "  Fix: " &
                    (if expectedFieldCount > providedFieldCount:
                      "Add " & $(expectedFieldCount - providedFieldCount) & " more field(s)"
                    elif providedFieldCount > expectedFieldCount:
                      "Remove " & $(providedFieldCount - expectedFieldCount) & " field(s)"
                    else:
                      "Match field count exactly")
      return ValidationResult(isValid: false, errorMessage: errorMsg)

    # FIELD TYPE VALIDATION: For literal patterns, check type compatibility
    # Only validate literals (int, string, etc.) - variables and complex patterns are checked at runtime
    for i, providedField in providedFields:
      if i < matchingBranch.fields.len:
        let expectedField = matchingBranch.fields[i]
        let providedType = inferLiteralType(providedField)

        # Only validate if we can infer the type (i.e., it's a literal)
        if providedType.len > 0:
          # Simple type compatibility check for literals
          # int matches int, string matches string, etc.
          let expectedType = expectedField.fieldType

          # Check if types are compatible
          var typesMatch = false
          if providedType == expectedType:
            typesMatch = true
          # Allow numeric compatibility (int matches int variants)
          elif providedType == "int" and expectedType in ["int", "int8", "int16", "int32", "int64", "uint", "uint8", "uint16", "uint32", "uint64"]:
            typesMatch = true
          elif providedType in ["int8", "int16", "int32", "int64", "uint", "uint8", "uint16", "uint32", "uint64"] and expectedType == "int":
            typesMatch = true

          if not typesMatch:
            let errorMsg = "Field type mismatch in UFCS variant pattern:\n" &
                          "  Pattern: " & pattern.repr & "\n" &
                          "  Field '" & expectedField.name & "' (position " & $(i+1) & "):\n" &
                          "    Expected type: " & expectedType & "\n" &
                          "    Provided type: " & providedType & "\n" &
                          "    Provided value: " & providedField.repr & "\n\n" &
                          "  Fix: Use a value of type " & expectedType & " for field '" & expectedField.name & "'"
            return ValidationResult(isValid: false, errorMessage: errorMsg)

  return ValidationResult(isValid: true, errorMessage: "")

proc validateObjectPattern*(pattern: NimNode, metadata: ConstructMetadata): ValidationResult {.noSideEffect.} =
  ## Validates object/class destructuring patterns against object type metadata.
  ##
  ## This validator ensures object patterns correctly destructure object types, enforcing
  ## type compatibility, field existence, and variant object discriminator safety rules.
  ##
  ## **Pattern Forms Supported:**
  ## 1. **Traditional call**: `Point(x, y)` - positional or named field access
  ## 2. **UFCS variant (no parens)**: `Status.Active` - variant constructor without fields
  ## 3. **UFCS variant (with parens)**: `Status.Active(msg)` - variant constructor with fields
  ##
  ## **Validation Checks:**
  ## - **Type compatibility**: Pattern type name must match scrutinee type (via `isCompatibleType`)
  ## - **Field existence**: All accessed fields must exist in type (via `hasField`)
  ## - **Typo detection**: Uses Levenshtein distance to suggest corrections for misspelled fields
  ## - **Variant safety**: Discriminator-based field access validation for variant objects
  ## - **Branch-specific fields**: Enforces discriminator presence when accessing branch fields
  ## - **Union type support**: Handles union type discriminator patterns with structural validation
  ##
  ## **Variant Object Safety:**
  ## For variant objects with discriminator fields (e.g., `kind: enum`), this validator:
  ## - Requires discriminator field in pattern when accessing branch-specific fields
  ## - Validates branch-specific field access matches discriminator value
  ## - Prevents access to fields from incorrect variant branches
  ## - Supports UFCS syntax where discriminator is implicit (`Status.Active` → `kind: skActive`)
  ##
  ## **Error Messages Generated:**
  ## - Type mismatch with available constructors
  ## - Field not found with Levenshtein-based suggestions
  ## - Discriminator validation errors (must use enum value, not string/int)
  ## - Branch safety violations with branch availability info
  ## - Union type branch errors with discriminator guidance
  ##
  ## Args:
  ##   pattern: Object pattern AST node (nnkCall, nnkObjConstr, or nnkDotExpr)
  ##   metadata: Scrutinee metadata with object structure
  ##
  ## Returns:
  ##   ValidationResult indicating validity and error details
  ##
  ## Example:
  ##   ```nim
  ##   type Status = object
  ##     case kind: StatusKind
  ##     of skActive: message: string
  ##     of skIdle: idleTime: int
  ##
  ##   # Valid: Discriminator present for branch field
  ##   let metadata = analyzeConstructMetadata(Status.getTypeInst())
  ##   let pattern1 = quote do: Status(kind: skActive, message: msg)
  ##   assert validateObjectPattern(pattern1, metadata).isValid
  ##
  ##   # Invalid: Missing discriminator for branch field
  ##   let pattern2 = quote do: Status(message: msg)  # Error!
  ##   let result = validateObjectPattern(pattern2, metadata)
  ##   assert not result.isValid
  ##
  ##   # Valid: UFCS variant syntax
  ##   let pattern3 = quote do: Status.Active(msg)
  ##   assert validateObjectPattern(pattern3, metadata).isValid
  ##   ```
  ##
  ## Performance:
  ##   O(f * n) where f = fields in pattern, n = fields in type metadata
  ##
  ## See also:
  ##   - `validateVariantConstructorPattern` - UFCS variant validation (delegated internally)
  ##   - `hasField` - Field existence checking (construct_metadata.nim)
  ##   - `isCompatibleType` - Type name compatibility (construct_metadata.nim)
  ##   - `validateFieldAccess` - Variant branch safety (construct_metadata.nim)

  # Handle UFCS variant constructor patterns: Status.Active or Status.Active(...)
  if pattern.kind == nnkDotExpr:
    return validateVariantConstructorPattern(pattern, metadata)

  # Handle UFCS variant constructor with parentheses: Status.Active() or Status.Active(field)
  if pattern.kind == nnkCall and pattern.len >= 1 and pattern[0].kind == nnkDotExpr:
    return validateVariantConstructorPattern(pattern, metadata)

  if pattern.kind notin {nnkCall, nnkObjConstr} or pattern.len < 1:
    return ValidationResult(isValid: false, errorMessage: "Invalid object pattern syntax")

  # Use repr to handle both simple idents and complex types like seq[int]
  let patternTypeName = pattern[0].repr

  # SPECIAL CASE: For union types with discriminator patterns, skip type name check
  # Union types use type aliases (e.g., Simple_EX -> UnionType1_int_string)
  # Old-style patterns like Simple_EX(kind: ukInt, val0: v) should be validated
  # based on discriminator structure, not type name string matching
  var skipTypeCheck = false
  if metadata.isUnion and metadata.isVariant:
    # Check if pattern has discriminator field
    for i in 1 ..< pattern.len:
      if pattern[i].kind in {nnkExprColonExpr, nnkExprEqExpr}:
        let fieldName = pattern[i][0]
        if fieldName.kind in {nnkIdent, nnkSym} and
           fieldName.strVal == metadata.discriminatorField:
          # Pattern has discriminator field - skip type name check
          # Structural validation will ensure correctness
          skipTypeCheck = true
          break

  # Check type name compatibility using structural analysis (unless skipped)
  if not skipTypeCheck and not isCompatibleType(patternTypeName, metadata):
    let errorMsg = generateTypeMismatchError(patternTypeName, metadata, pattern)
    return ValidationResult(isValid: false, errorMessage: errorMsg)

  # For variant objects, extract discriminator value for branch safety checking
  var discriminatorValue = ""
  if metadata.isVariant and metadata.discriminatorField != "":
    # Check for UFCS variant constructor pattern: TypeName.Constructor(fields...)
    # In this case, the discriminator is implicit in the constructor name
    if pattern[0].kind == nnkDotExpr and pattern[0].len == 2:
      let constructorName = pattern[0][1].strVal
      discriminatorValue = findMatchingDiscriminatorValue(constructorName, metadata)
    else:
      # Look for explicit discriminator field assignment in pattern
      for i in 1..<pattern.len:
        let arg = pattern[i]
        if arg.kind in {nnkExprEqExpr, nnkExprColonExpr} and arg.len >= 2:
          if arg[0].kind == nnkIdent and arg[0].strVal == metadata.discriminatorField:
            # Found discriminator assignment - validate value type
            # BUG #12: Discriminator values must be enum identifiers, not strings or ints
            if arg[1].kind == nnkStrLit:
              let errorMsg = "Invalid discriminator value type:\n" &
                            "  Discriminator field '" & metadata.discriminatorField & "' expects an enum value\n" &
                            "  Got: string literal \"" & arg[1].strVal & "\"\n\n" &
                            "  Pattern: " & pattern.repr & "\n\n" &
                            "  Fix: Use the enum value directly without quotes\n" &
                            "  Example: " & pattern[0].repr & "(" & metadata.discriminatorField & ": " &
                            arg[1].strVal & ", ...)"
              return ValidationResult(isValid: false, errorMessage: errorMsg)
            elif arg[1].kind in {nnkIntLit, nnkInt8Lit, nnkInt16Lit, nnkInt32Lit, nnkInt64Lit,
                                  nnkUIntLit, nnkUInt8Lit, nnkUInt16Lit, nnkUInt32Lit, nnkUInt64Lit}:
              let errorMsg = "Invalid discriminator value type:\n" &
                            "  Discriminator field '" & metadata.discriminatorField & "' expects an enum value\n" &
                            "  Got: integer literal " & $arg[1].intVal & "\n\n" &
                            "  Pattern: " & pattern.repr & "\n\n" &
                            "  Fix: Use the enum value name instead of its ordinal value"
              return ValidationResult(isValid: false, errorMessage: errorMsg)
            elif arg[1].kind == nnkIdent:
              # Valid enum identifier
              discriminatorValue = arg[1].strVal

  # Validate each field pattern
  for i in 1..<pattern.len:
    let arg = pattern[i]
    var fieldName = ""

    case arg.kind:
    of nnkIdent:
      # Positional field
      fieldName = arg.strVal
    of nnkExprEqExpr, nnkExprColonExpr:
      # Named field
      if arg.len >= 1 and arg[0].kind == nnkIdent:
        fieldName = arg[0].strVal
    of nnkPrefix:
      # Handle **rest patterns
      if arg.len >= 2 and arg[0].strVal == "**":
        continue  # Skip validation for rest patterns
    of nnkInfix:
      # Handle @ patterns, guards, etc.
      continue
    else:
      continue

    # Check if field exists using structural metadata
    if fieldName != "" and not hasField(metadata, fieldName):
      let errorMsg = generateFieldError(fieldName, metadata, pattern)
      return ValidationResult(isValid: false, errorMessage: errorMsg)

    # For variant objects, enforce discriminator field presence for branch-specific fields
    if metadata.isVariant and fieldName != "" and fieldName != metadata.discriminatorField:
      # Check if this field is branch-specific (not a common field)
      var isCommonField = false
      for field in metadata.fields:
        if field.name == fieldName:
          isCommonField = true
          break

      # If field is branch-specific, discriminator must be present
      if not isCommonField and discriminatorValue == "":
        # Find which branch(es) contain this field for error message
        var branchesWithField: seq[string] = @[]
        for branch in metadata.branches:
          for field in branch.fields:
            if field.name == fieldName:
              branchesWithField.add(branch.discriminatorValue)
              break

        let branchList = branchesWithField.join(", ")
        let errorMsg = "Variant object discriminator field required:\n" &
                       "  Field '" & fieldName & "' is branch-specific and requires discriminator field '" &
                       metadata.discriminatorField & "' in pattern\n\n" &
                       "  Pattern: " & pattern.repr & "\n\n" &
                       "  Explanation: Field '" & fieldName & "' only exists in branch(es): " & branchList & "\n" &
                       "  You must specify the discriminator field to safely access this field.\n\n" &
                       "  Example: " & pattern[0].repr & "(" & metadata.discriminatorField & ": " &
                       branchesWithField[0] & ", " & fieldName & ": ...)"
        return ValidationResult(isValid: false, errorMessage: errorMsg)

    # For variant objects, validate branch-specific field access when discriminator is present
    if metadata.isVariant and fieldName != "" and discriminatorValue != "":
      if not validateFieldAccess(metadata, fieldName, discriminatorValue):
        # Field exists but is in wrong branch for this discriminator value
        # Use union-friendly error messages for union types, variant object messages otherwise
        let errorMsg = if metadata.isUnion:
                         generateUnionBranchError(fieldName, discriminatorValue, metadata, pattern)
                       else:
                         "Variant object branch safety error:\n" &
                         "  Field '" & fieldName & "' is not accessible when " &
                         metadata.discriminatorField & " = " & discriminatorValue & "\n\n" &
                         "  Pattern: " & pattern.repr & "\n\n" &
                         "  Explanation: Field '" & fieldName & "' belongs to a different variant branch.\n" &
                         "  Check which fields are available for discriminator value '" & discriminatorValue & "'."
        return ValidationResult(isValid: false, errorMessage: errorMsg)

  return ValidationResult(isValid: true, errorMessage: "")

proc validateTuplePattern*(pattern: NimNode, metadata: ConstructMetadata): ValidationResult {.noSideEffect.} =
  ## Validates tuple destructuring patterns against tuple type metadata.
  ##
  ## This validator ensures tuple patterns correctly destructure tuple types by verifying
  ## element count compatibility. Supports both exact-count tuples and patterns with
  ## default values for excess elements.
  ##
  ## **Validation Checks:**
  ## - **Element count**: Pattern element count must match scrutinee tuple size
  ## - **Default value support**: Pattern can have MORE elements if extras provide defaults
  ## - **Syntax validation**: Ensures pattern is a valid tuple constructor (nnkTupleConstr)
  ##
  ## **Default Value Handling:**
  ## Patterns like `(x, y, z = 0)` are valid even if scrutinee is 2-tuple, as long as
  ## extra elements have default values (= operator). This allows flexible tuple destructuring
  ## with fallback values.
  ##
  ## **Error Messages Generated:**
  ## - Element count mismatch with actionable suggestions ("Add N elements" or "Remove N elements")
  ## - Syntax errors for non-tuple patterns
  ##
  ## Args:
  ##   pattern: Tuple pattern AST node (nnkTupleConstr)
  ##   metadata: Scrutinee metadata with tuple structure
  ##
  ## Returns:
  ##   ValidationResult indicating validity and error details
  ##
  ## Example:
  ##   ```nim
  ##   type Point3D = tuple[x, y, z: int]
  ##
  ##   # Valid: Exact count match
  ##   let metadata = analyzeConstructMetadata(Point3D.getTypeInst())
  ##   let pattern1 = quote do: (x, y, z)
  ##   assert validateTuplePattern(pattern1, metadata).isValid
  ##
  ##   # Valid: With default value
  ##   let pattern2 = quote do: (x, y, z, w = 0)
  ##   assert validateTuplePattern(pattern2, metadata).isValid
  ##
  ##   # Invalid: Too few elements, no defaults
  ##   let pattern3 = quote do: (x, y)
  ##   assert not validateTuplePattern(pattern3, metadata).isValid
  ##   ```
  ##
  ## Performance:
  ##   O(1) - Simple element count comparison
  ##
  ## See also:
  ##   - `getExpectedElementCount` - Extracts tuple size (construct_metadata.nim)
  ##   - `validateSequencePattern` - Similar validation for sequences

  if pattern.kind != nnkTupleConstr:
    return ValidationResult(isValid: false, errorMessage: "Invalid tuple pattern syntax")

  let expectedCount = metadata.tupleElements.len
  let patternCount = pattern.len

  # Count elements with default values in the pattern
  # Default value syntax: (x, y = 10) or (x, (y = 10))
  var elementsWithDefaults = 0
  for element in pattern:
    if element.kind == nnkExprEqExpr:
      # Direct default: y = 10
      elementsWithDefaults.inc
    elif element.kind == nnkPar and element.len == 1 and element[0].kind == nnkAsgn:
      # Parenthesized default: (y = 10)
      elementsWithDefaults.inc

  # Calculate minimum required elements (elements without defaults)
  let minRequiredElements = patternCount - elementsWithDefaults

  # Pattern can have more elements than scrutinee IF the extra elements have defaults
  # Pattern must have at least as many non-default elements as scrutinee has
  if minRequiredElements > expectedCount:
    let errorMsg = generateElementCountError(minRequiredElements, expectedCount, metadata, pattern)
    return ValidationResult(isValid: false, errorMessage: errorMsg)

  # If pattern has fewer elements than scrutinee (without defaults), that's an error
  if patternCount < expectedCount and elementsWithDefaults == 0:
    let errorMsg = generateElementCountError(patternCount, expectedCount, metadata, pattern)
    return ValidationResult(isValid: false, errorMessage: errorMsg)

  # Validate element types for literal patterns
  # Variables and wildcards are always valid (runtime binding)
  # Only literal values need type checking at compile time
  for i in 0 ..< min(pattern.len, metadata.tupleElements.len):
    let element = pattern[i]

    # Skip default value patterns - extract the actual pattern
    let actualElement = if element.kind == nnkExprEqExpr and element.len > 1:
                          element[1]  # Get the default value for type checking
                        else:
                          element

    # Infer literal type (empty string if not a literal)
    let literalType = inferLiteralType(actualElement)

    # If it's a literal, check type compatibility
    if literalType != "":
      let expectedType = metadata.tupleElements[i].elementType
      let expectedTypeNode = metadata.tupleElements[i].elementTypeNode

      # Use metadata-based type checking if type node is available, otherwise fall back to string comparison
      let compatible = if expectedTypeNode != nil and expectedTypeNode.kind != nnkEmpty:
                         isLiteralCompatibleWithType(literalType, expectedType, expectedTypeNode)
                       else:
                         typesAreCompatible(literalType, expectedType)

      if not compatible:
        let errorMsg = generateLiteralTypeMismatchError(literalType, expectedType, i, pattern)
        return ValidationResult(isValid: false, errorMessage: errorMsg)

  return ValidationResult(isValid: true, errorMessage: "")

proc validateSequencePattern*(pattern: NimNode, metadata: ConstructMetadata): ValidationResult {.noSideEffect.} =
  ## Validates sequence/array destructuring patterns against collection type metadata.
  ##
  ## This validator handles both sequences (variable-length) and arrays (fixed-length),
  ## enforcing size constraints for arrays and validating element type compatibility for literals.
  ##
  ## **Validation Checks:**
  ## - **Array size**: Fixed-size arrays must match exactly (without spread) or meet minimum (with spread)
  ## - **Sequence size**: Sequences accept any pattern size (no validation needed)
  ## - **Element types**: Literal elements must be compatible with `metadata.elementType`
  ## - **Nested arrays**: Recursively validates nested bracket patterns
  ## - **Spread operators**: `*rest` patterns capture variable-length segments
  ##
  ## **Pattern Forms:**
  ## - Exact match: `[a, b, c]` - requires 3 elements for array[3]
  ## - Spread pattern: `[first, *middle, last]` - requires minimum 2 elements
  ## - Default values: `[a, b, c = 0]` - provides fallback for missing elements
  ## - Nested: `[[1, 2], [3, 4]]` - recursively validates inner patterns
  ##
  ## **Error Messages Generated:**
  ## - Array size mismatch with actionable guidance
  ## - Element type incompatibility with literal type details
  ## - Nested pattern validation errors propagated from inner patterns
  ##
  ## Args:
  ##   pattern: Sequence pattern AST node (nnkBracket)
  ##   metadata: Scrutinee metadata with sequence/array structure
  ##
  ## Returns:
  ##   ValidationResult indicating validity and error details
  ##
  ## Example:
  ##   ```nim
  ##   type FixedArray = array[3, int]
  ##
  ##   # Valid: Exact match
  ##   let metadata = analyzeConstructMetadata(FixedArray.getTypeInst())
  ##   let pattern1 = quote do: [a, b, c]
  ##   assert validateSequencePattern(pattern1, metadata).isValid
  ##
  ##   # Valid: Spread pattern
  ##   let pattern2 = quote do: [first, *rest]
  ##   assert validateSequencePattern(pattern2, metadata).isValid
  ##
  ##   # Invalid: Too few elements
  ##   let pattern3 = quote do: [a, b]
  ##   assert not validateSequencePattern(pattern3, metadata).isValid
  ##   ```
  ##
  ## Performance:
  ##   O(n) where n = number of pattern elements (for type checking)
  ##
  ## See also:
  ##   - `validateTuplePattern` - Similar validation for tuples
  ##   - `inferLiteralType` - Extracts literal types for validation

  if pattern.kind != nnkBracket:
    return ValidationResult(isValid: false, errorMessage: "Invalid sequence/array pattern syntax")

  # For arrays, check size constraints
  if metadata.kind == ckArray and metadata.arraySize > 0:
    # Count non-spread elements
    # NOTE: Defaults don't make sense for arrays (fixed size), so we count ALL elements
    var hasSpread = false
    var minElements = 0

    for element in pattern:
      if element.kind == nnkPrefix and element.len >= 2 and
         element[0].strVal == "*":
        hasSpread = true
      else:
        minElements.inc

    # If no spread, exact match required
    # Arrays are fixed-size, so pattern must match exactly (defaults don't help)
    if not hasSpread and minElements != metadata.arraySize:
      let errorMsg = generateElementCountError(minElements, metadata.arraySize, metadata, pattern)
      return ValidationResult(isValid: false, errorMessage: errorMsg)

    # If spread, check minimum elements
    if hasSpread and minElements > metadata.arraySize:
      let errorMsg = generateElementCountError(minElements, metadata.arraySize, metadata, pattern)
      return ValidationResult(isValid: false, errorMessage: errorMsg)

  # Validate element types if metadata has elementType information
  if metadata.elementType != "":
    for element in pattern:
      # Skip spread operators (*rest)
      if element.kind == nnkPrefix and element.len >= 2 and element[0].strVal == "*":
        continue

      # Skip default assignments (x = 10)
      var elementToValidate = element
      if element.kind == nnkExprEqExpr:
        # For defaults, validate the pattern part (element[0])
        elementToValidate = element[0]

      # Extract pattern from guard expressions: "wrong" and x > 5
      # Guards are nnkInfix with "and" or "or"
      if elementToValidate.kind == nnkInfix and elementToValidate.len >= 3:
        let op = elementToValidate[0].strVal
        if op == "and" or op == "or":
          # Extract the left side (the pattern being guarded)
          elementToValidate = elementToValidate[1]

      # Recursively validate nested bracket patterns (nested arrays)
      # Example: [[1, 2], [3, 4]] - validate each inner [1, 2] and [3, 4]
      if elementToValidate.kind == nnkBracket and metadata.elementTypeNode != nil:
        # Get metadata for the nested array element type
        let nestedMetadata = analyzeConstructMetadata(metadata.elementTypeNode)
        # Recursively validate the nested pattern
        let nestedResult = validateSequencePattern(elementToValidate, nestedMetadata)
        if not nestedResult.isValid:
          return nestedResult
        # Nested validation passed, continue to next element
        continue

      # Check literal type compatibility
      let literalType = inferLiteralType(elementToValidate)
      if literalType != "":
        # Use metadata-based type checking if type node is available
        let compatible = if metadata.elementTypeNode != nil and metadata.elementTypeNode.kind != nnkEmpty:
                           isLiteralCompatibleWithType(literalType, metadata.elementType, metadata.elementTypeNode)
                         else:
                           typesAreCompatible(literalType, metadata.elementType)

        if not compatible:
          let errorMsg = "Sequence element type mismatch:\n" &
                        "  Expected element type: " & metadata.elementType & "\n" &
                        "  Got: " & literalType & "\n\n" &
                        "  Pattern: " & pattern.repr & "\n\n" &
                        "  Fix: Use " & metadata.elementType & " elements, not " & literalType
          return ValidationResult(isValid: false, errorMessage: errorMsg)
      # For non-literals, we skip validation here
      # Complex patterns (tuples, objects, guards) will be validated during code generation
      # This allows flexibility for:
      # - Special patterns like empty(), single(), length() for linked lists
      # - Object patterns like Employee(role: "Dev") - validated separately
      # - Guard patterns with variables
      # Simple literal type validation above catches most type errors

  # Sequences accept any size
  return ValidationResult(isValid: true, errorMessage: "")

proc validateTablePattern*(pattern: NimNode, metadata: ConstructMetadata): ValidationResult {.noSideEffect.} =
  ## Validates table/dictionary destructuring patterns against Table type metadata.
  ##
  ## This validator ensures table patterns correctly destructure Table[K, V] types by
  ## validating key and value type compatibility for literals, while allowing variables
  ## and wildcards for runtime binding.
  ##
  ## **Validation Checks:**
  ## - **Syntax**: Must be nnkTableConstr (`{key: value}`)
  ## - **Key types**: Literal keys must be compatible with `metadata.keyType`
  ## - **Value types**: Literal values must be compatible with `metadata.valueType`
  ## - **Runtime binding**: Variables and wildcards in keys/values always valid
  ##
  ## **Pattern Forms:**
  ## - Basic: `{"port": 8080, "debug": true}`
  ## - Variables: `{"port": p, "debug": d}`  - runtime binding
  ## - Spread: `{"port": 8080, **rest}`  - captures remaining pairs
  ##
  ## Args:
  ##   pattern: Table pattern AST node (nnkTableConstr)
  ##   metadata: Scrutinee metadata with Table structure
  ##
  ## Returns:
  ##   ValidationResult indicating validity and error details
  ##
  ## Performance:
  ##   O(n) where n = number of key-value pairs
  ##
  ## See also:
  ##   - `inferLiteralType` - Type inference for literal validation
  ##   - `typesAreCompatible` - Type compatibility checking

  if pattern.kind != nnkTableConstr:
    return ValidationResult(isValid: false, errorMessage: "Invalid table pattern syntax")

  # Validate each key-value pair
  for entry in pattern:
    if entry.kind == nnkExprColonExpr and entry.len >= 2:
      let keyNode = entry[0]
      let valueNode = entry[1]

      # Check key type if it's a literal
      let keyLiteralType = inferLiteralType(keyNode)
      if keyLiteralType != "":
        # Use metadata-based type checking if type node is available
        let keyCompatible = if metadata.keyTypeNode != nil and metadata.keyTypeNode.kind != nnkEmpty:
                              isLiteralCompatibleWithType(keyLiteralType, metadata.keyType, metadata.keyTypeNode)
                            else:
                              typesAreCompatible(keyLiteralType, metadata.keyType)

        if not keyCompatible:
          let errorMsg = "Table key type mismatch:\n" &
                        "  Expected key type: " & metadata.keyType & "\n" &
                        "  Got: " & keyLiteralType & "\n\n" &
                        "  Pattern: " & pattern.repr & "\n\n" &
                        "  Fix: Use a " & metadata.keyType & " key, not a " & keyLiteralType
          return ValidationResult(isValid: false, errorMessage: errorMsg)

      # Check value type if it's a literal
      let valueLiteralType = inferLiteralType(valueNode)
      if valueLiteralType != "":
        # Use metadata-based type checking if type node is available
        let valueCompatible = if metadata.valueTypeNode != nil and metadata.valueTypeNode.kind != nnkEmpty:
                                 isLiteralCompatibleWithType(valueLiteralType, metadata.valueType, metadata.valueTypeNode)
                               else:
                                 typesAreCompatible(valueLiteralType, metadata.valueType)

        if not valueCompatible:
          let errorMsg = "Table value type mismatch:\\n" &
                        "  Expected value type: " & metadata.valueType & "\\n" &
                        "  Got: " & valueLiteralType & "\\n\\n" &
                        "  Pattern: " & pattern.repr & "\\n\\n" &
                        "  Fix: Use a " & metadata.valueType & " value, not a " & valueLiteralType
          return ValidationResult(isValid: false, errorMessage: errorMsg)

  return ValidationResult(isValid: true, errorMessage: "")

proc validateSetPattern*(pattern: NimNode, metadata: ConstructMetadata): ValidationResult {.noSideEffect.} =
  ## Validates set patterns against set[T] type metadata.
  ##
  ## This validator ensures set patterns correctly match set types by validating element
  ## type compatibility for literals and enum identifiers, while allowing variables for
  ## runtime binding. Also used for ordinal types as OR pattern sugar ({1, 2, 3} → 1 | 2 | 3).
  ##
  ## **Validation Checks:**
  ## - **Syntax**: Must be nnkCurly (`{elem1, elem2}`)
  ## - **Element types**: Literal elements must be compatible with `metadata.elementType`
  ## - **Enum validation**: Enum identifiers validated against `metadata.enumValues`
  ## - **Runtime binding**: Variables and wildcards always valid
  ##
  ## **Pattern Forms:**
  ## - Enum sets: `{Red, Blue, Green}`
  ## - Ordinal sets: `{1, 2, 3}` (also works as OR pattern sugar on ordinal types)
  ## - Mixed: `{Red, x}` where x is variable binding
  ##
  ## Args:
  ##   pattern: Set pattern AST node (nnkCurly)
  ##   metadata: Scrutinee metadata with set/ordinal structure
  ##
  ## Returns:
  ##   ValidationResult indicating validity and error details
  ##
  ## Performance:
  ##   O(n) where n = number of set elements
  ##
  ## See also:
  ##   - `inferLiteralType` - Type inference for literal validation
  ##   - `validateEnumPattern` - Enum validation logic

  if pattern.kind != nnkCurly:
    return ValidationResult(isValid: false, errorMessage: "Invalid set pattern syntax")

  # Check if element type is an enum by analyzing element type metadata
  var elementMetadata: ConstructMetadata
  var isEnumElementType = false
  if not metadata.elementTypeNode.isNil:
    elementMetadata = analyzeConstructMetadata(metadata.elementTypeNode)
    isEnumElementType = (elementMetadata.kind == ckEnum)

  # Validate each element
  for element in pattern:
    # Skip validation for variables, wildcards, and spread operators (runtime binding)
    # Use structural AST checks, not string heuristics
    if element.kind == nnkIdent and element.strVal == "_":
      continue  # Wildcard - always valid
    elif element.kind == nnkPrefix and element.len >= 2 and element[0].strVal == "*":
      continue  # Spread operator (*rest) - always valid

    if element.kind == nnkIdent:
      let identStr = element.strVal

      # Check if this is a bool literal (true/false) masquerading as an identifier
      if identStr in ["true", "false"]:
        # Bool literal - validate type compatibility
        # Use metadata-based type checking if type node is available
        let boolCompatible = if metadata.elementTypeNode != nil and metadata.elementTypeNode.kind != nnkEmpty:
                               isLiteralCompatibleWithType("bool", metadata.elementType, metadata.elementTypeNode)
                             else:
                               typesAreCompatible("bool", metadata.elementType)

        if not boolCompatible:
          let errorMsg = "Set element type mismatch:\n" &
                        "  Expected element type: " & metadata.elementType & "\n" &
                        "  Got: bool\n\n" &
                        "  Pattern: " & pattern.repr & "\n\n" &
                        "  Fix: Use " & metadata.elementType & " elements, not bool"
          return ValidationResult(isValid: false, errorMessage: errorMsg)
        # If compatible, continue to next element
        continue

      # Check if this is an enum set
      if isEnumElementType:
        # For enum sets, distinguish between enum literals and variable bindings
        # Strategy: Check if identifier matches an enum value
        # - If it matches → enum literal (validate)
        # - If it doesn't match → variable binding (allow)
        var isValidEnumValue = false
        for enumVal in elementMetadata.enumValues:
          if enumVal.name == identStr:
            isValidEnumValue = true
            break

        if isValidEnumValue:
          # This is an enum literal - valid, continue
          continue
        else:
          # This identifier doesn't match any enum value
          # → Treat as variable binding (always valid)
          # Variables can bind to enum values at runtime
          continue
      # For non-enum identifiers, allow them (variables)
      continue

    # Infer literal type for non-identifier elements (empty string if not a literal)
    let literalType = inferLiteralType(element)

    # If it's a literal, check type compatibility
    if literalType != "":
      # Use metadata-based type checking if type node is available
      let compatible = if metadata.elementTypeNode != nil and metadata.elementTypeNode.kind != nnkEmpty:
                         isLiteralCompatibleWithType(literalType, metadata.elementType, metadata.elementTypeNode)
                       else:
                         typesAreCompatible(literalType, metadata.elementType)

      if not compatible:
        let errorMsg = "Set element type mismatch:\n" &
                      "  Expected element type: " & metadata.elementType & "\n" &
                      "  Got: " & literalType & "\n\n" &
                      "  Pattern: " & pattern.repr & "\n\n" &
                      "  Fix: Use " & metadata.elementType & " elements, not " & literalType
        return ValidationResult(isValid: false, errorMessage: errorMsg)

  return ValidationResult(isValid: true, errorMessage: "")

proc validateEnumPattern*(pattern: NimNode, metadata: ConstructMetadata): ValidationResult {.noSideEffect.} =
  ## Validates enum patterns against enum type metadata.
  ##
  ## This validator provides **flexible enum matching** supporting literals, OR patterns,
  ## set syntax (as OR sugar), guards, and variable binding. Enum patterns are structurally
  ## validated against `metadata.enumValues` for compile-time correctness.
  ##
  ## **Validation Checks:**
  ## - **Enum literals**: Identifier names validated against enum values
  ## - **Pattern flexibility**: Accepts literals, variables, wildcards, OR, sets, guards
  ## - **Set syntax**: `{Red, Blue}` converted to OR pattern `Red | Blue`
  ## - **OR patterns**: `Red | Green | Blue` supported natively
  ##
  ## **Pattern Forms:**
  ## - Literal: `Red`, `Green`, `Blue`
  ## - Variable: `x` (binds to any enum value)
  ## - Wildcard: `_` (matches any)
  ## - OR pattern: `Red | Blue | Green`
  ## - Set pattern: `{Red, Blue, Green}` (sugar for OR)
  ## - Guard pattern: `x and x in [Red, Blue]`
  ##
  ## Args:
  ##   pattern: Enum pattern AST node
  ##   metadata: Scrutinee metadata with enum structure
  ##
  ## Returns:
  ##   ValidationResult indicating validity and error details
  ##
  ## Example:
  ##   ```nim
  ##   type Color = enum
  ##     Red, Green, Blue
  ##
  ##   let metadata = analyzeConstructMetadata(Color.getTypeInst())
  ##   let pattern1 = quote do: Red
  ##   assert validateEnumPattern(pattern1, metadata).isValid
  ##
  ##   # OR pattern
  ##   let pattern2 = quote do: Red | Blue
  ##   assert validateEnumPattern(pattern2, metadata).isValid
  ##   ```
  ##
  ## Performance:
  ##   O(n) where n = pattern complexity (enum value count for validation)
  ##
  ## See also:
  ##   - `validateSetPattern` - Set validation (similar logic for enum sets)

  case pattern.kind:
  of nnkIdent:
    # Identifier - could be enum literal, variable, or wildcard
    let identStr = pattern.strVal

    if identStr == "_":
      # Wildcard - always valid
      return ValidationResult(isValid: true, errorMessage: "")

    # Special case: bool is technically an enum in Nim (false = 0, true = 1)
    # but it's so commonly used with variable binding that we allow it
    if metadata.typeName == "bool":
      # For bool, allow both enum values (true/false) and variable binding
      # This maintains compatibility with existing code patterns
      return ValidationResult(isValid: true, errorMessage: "")

    # Check if it's a known enum value
    var isEnumValue = false
    for enumVal in metadata.enumValues:
      if enumVal.name == identStr:
        isEnumValue = true
        break

    if isEnumValue:
      # Valid enum literal
      return ValidationResult(isValid: true, errorMessage: "")
    else:
      # Unknown identifier - reject with helpful error message
      # Strict validation: only known enum values and '_' are allowed
      # Use @ pattern for variable binding: `enumValue @ varName`

      var errorMsg = "Invalid enum value '" & identStr & "' for enum type " & metadata.typeName & ".\n"

      # Collect available enum values
      if metadata.enumValues.len > 0:
        var enumNames = newSeq[string]()
        for enumVal in metadata.enumValues:
          enumNames.add(enumVal.name)
        errorMsg &= "  Available values: " & enumNames.join(", ") & "\n"

        # Try to find similar enum value using Levenshtein distance with adaptive threshold
        # Uses same adaptive strategy as field name suggestions for consistency
        var bestMatch = ""
        var bestDistance = high(int)
        for enumVal in metadata.enumValues:
          let distance = levenshteinDistance(identStr, enumVal.name)
          if distance < bestDistance:
            bestDistance = distance
            bestMatch = enumVal.name

        # Adaptive threshold: max(identStr.len div 3, 2)
        # Short enum names (2-6 chars) → threshold 2, long names scale to ~33% of length
        let threshold = max(identStr.len div 3, 2)

        if bestMatch.len > 0 and bestDistance <= threshold:
          errorMsg &= "\n  Did you mean '" & bestMatch & "'?\n"
        else:
          # No close match - likely intended as variable binding
          errorMsg &= "\n  If you want to bind this value to a variable, use the @ pattern:\n"
          errorMsg &= "    _ @ " & identStr & ": <your code here>\n"

      errorMsg &= "\n"
      errorMsg &= "  Pattern: " & pattern.repr & "\n"
      errorMsg &= "  Scrutinee type: " & prettyPrintType(metadata) & "\n\n"
      errorMsg &= "  Valid enum patterns:\n"
      errorMsg &= "    - Enum values: " & (if metadata.enumValues.len > 0: metadata.enumValues[0].name else: "value") & "\n"
      errorMsg &= "    - Wildcard: _\n"
      errorMsg &= "    - Variable binding: _ @ varName\n"
      errorMsg &= "    - With specific value: enumValue @ varName"

      return ValidationResult(isValid: false, errorMessage: errorMsg)

  of nnkInfix:
    # Infix operator - could be OR pattern (|), guard (and), etc.
    if pattern.len >= 3:
      let op = pattern[0].strVal
      if op == "|":
        # OR pattern - validate both sides
        # For mixed-type OR patterns (e.g., "hello" | false on bool),
        # at least ONE side must be valid for the scrutinee type
        let leftResult = validateEnumPattern(pattern[1], metadata)
        let rightResult = validateEnumPattern(pattern[2], metadata)

        # If at least one side is valid, the OR pattern is valid
        if leftResult.isValid or rightResult.isValid:
          return ValidationResult(isValid: true, errorMessage: "")

        # Both sides are invalid - return error from left side
        return leftResult

      elif op in ["and", "or"]:
        # Guard pattern - allow guards on enum types
        return ValidationResult(isValid: true, errorMessage: "")

      elif op == "@":
        # At pattern (@) - validate the left side (the pattern being bound)
        # Right side is just a variable name, always valid
        return validateEnumPattern(pattern[1], metadata)

    # Unknown infix operator
    let errorMsg = "Invalid infix operator in enum pattern:\\n" &
                  "  Pattern: " & pattern.repr & "\\n" &
                  "  Scrutinee type: " & prettyPrintType(metadata) & "\\n\\n" &
                  "  Enum patterns support | (OR), @ (binding), and 'and'/'or' (guards)."
    return ValidationResult(isValid: false, errorMessage: errorMsg)

  of nnkCurly:
    # Set pattern - validate all elements
    for element in pattern:
      let elementResult = validateEnumPattern(element, metadata)
      if not elementResult.isValid:
        return elementResult

    return ValidationResult(isValid: true, errorMessage: "")

  of nnkCall:
    # Object constructor on enum type - invalid
    var errorMsg = "Invalid pattern for enum type:\n" &
                  "  Pattern: " & pattern.repr & "\n" &
                  "  Scrutinee type: " & prettyPrintType(metadata) & "\n\n" &
                  "  Enum types cannot use object constructor patterns.\n"

    # Show available enum values
    if metadata.enumValues.len > 0:
      var enumNames = newSeq[string]()
      for enumVal in metadata.enumValues:
        enumNames.add(enumVal.name)
      errorMsg &= "  Available values: " & enumNames.join(", ") & "\n"

    errorMsg &= "  Valid enum patterns: enum literals (Red), variables (x), OR patterns (Red | Blue), or set patterns {Red, Blue}."
    return ValidationResult(isValid: false, errorMessage: errorMsg)

  of nnkIntLit, nnkStrLit, nnkFloatLit:
    # Special case: bool is technically an enum (false = 0, true = 1)
    # Allow int literals 0 and 1 for bool matching
    if metadata.typeName == "bool" and pattern.kind == nnkIntLit:
      let intVal = pattern.intVal.int
      if intVal == 0 or intVal == 1:
        return ValidationResult(isValid: true, errorMessage: "")

    # Literal values are NOT valid for enum patterns
    # Enums must be matched with their named values, not literals
    let literalType =
      if pattern.kind == nnkIntLit: "integer"
      elif pattern.kind == nnkStrLit: "string"
      else: "float"

    var errorMsg = "Invalid " & literalType & " literal pattern for enum type:\n" &
                  "  Pattern: " & pattern.repr & "\n" &
                  "  Scrutinee type: " & prettyPrintType(metadata) & "\n\n" &
                  "  Enum types must be matched using their named values, not " & literalType & " literals.\n"

    # Show available enum values
    if metadata.enumValues.len > 0:
      var enumNames = newSeq[string]()
      for enumVal in metadata.enumValues:
        enumNames.add(enumVal.name)
      errorMsg &= "  Available values: " & enumNames.join(", ") & "\n"

    errorMsg &= "\n  Valid enum patterns:\n"
    errorMsg &= "    - Named values: Red, Green, Blue\n"
    errorMsg &= "    - OR patterns: Red | Blue\n"
    errorMsg &= "    - Set patterns: {Red, Blue}\n"
    errorMsg &= "    - Wildcard: _"

    return ValidationResult(isValid: false, errorMessage: errorMsg)

  of nnkBracket:
    # Array/sequence pattern on enum - invalid
    var errorMsg = "Invalid sequence pattern for enum type:\n" &
                  "  Pattern: " & pattern.repr & "\n" &
                  "  Scrutinee type: " & prettyPrintType(metadata) & "\n\n" &
                  "  Enum types cannot use sequence patterns.\n"

    # Show available enum values
    if metadata.enumValues.len > 0:
      var enumNames = newSeq[string]()
      for enumVal in metadata.enumValues:
        enumNames.add(enumVal.name)
      errorMsg &= "  Available values: " & enumNames.join(", ") & "\n"

    errorMsg &= "  Did you mean a set pattern {Red, Blue} instead of [Red, Blue]?"
    return ValidationResult(isValid: false, errorMessage: errorMsg)

  of nnkPar:
    # Parenthesized pattern - unwrap and validate inner pattern
    # This handles cases like (_ @ b) and (Red | Blue)
    if pattern.len == 1:
      return validateEnumPattern(pattern[0], metadata)
    else:
      # Empty or multi-element tuple - not valid for enum
      let errorMsg = "Invalid tuple pattern for enum type:\\n" &
                    "  Pattern: " & pattern.repr & "\\n" &
                    "  Scrutinee type: " & prettyPrintType(metadata) & "\\n\\n" &
                    "  Enum types do not support tuple patterns."
      return ValidationResult(isValid: false, errorMessage: errorMsg)

  else:
    # Unknown pattern kind for enum
    let errorMsg = "Unsupported pattern kind for enum type:\\n" &
                  "  Pattern: " & pattern.repr & "\\n" &
                  "  Pattern kind: " & $pattern.kind & "\\n" &
                  "  Scrutinee type: " & prettyPrintType(metadata)
    return ValidationResult(isValid: false, errorMessage: errorMsg)

proc validateRefPattern*(pattern: NimNode, metadata: ConstructMetadata): ValidationResult {.noSideEffect.} =
  ## Validates reference type patterns with implicit dereferencing support.
  ##
  ## This validator handles `ref T` types by allowing patterns that match the underlying
  ## type `T`, enabling implicit dereferencing in pattern matching. Basic patterns like
  ## variable binding, wildcards, and nil checks are always valid.
  ##
  ## **Validation Strategy:**
  ## - **Basic patterns**: Variables (`x`), wildcards (`_`), nil literals always valid
  ## - **Implicit dereferencing**: `ref Point` accepts `Point(x, y)` patterns
  ## - **Underlying type validation**: Delegates to type-specific validator for `T`
  ## - **Structural analysis**: Uses `metadata.underlyingTypeNode` for recursive validation
  ##
  ## **Pattern Forms:**
  ## - Variable: `x` - binds to ref value
  ## - Wildcard: `_` - matches any ref (including nil)
  ## - Nil check: `nil` - matches nil references
  ## - Dereferenced: `Point(x, y)` for `ref Point` - implicit dereferencing
  ##
  ## Args:
  ##   pattern: Pattern AST node
  ##   metadata: Scrutinee metadata with ref type structure
  ##
  ## Returns:
  ##   ValidationResult indicating validity and error details
  ##
  ## Example:
  ##   ```nim
  ##   type Point = ref object
  ##     x, y: int
  ##
  ##   let metadata = analyzeConstructMetadata(Point.getTypeInst())
  ##   let pattern = quote do: Point(x, y)
  ##   assert validateRefPattern(pattern, metadata).isValid
  ##   ```
  ##
  ## Performance:
  ##   O(1) for basic patterns, delegates to underlying type validator otherwise
  ##
  ## See also:
  ##   - `validatePtrPattern` - Similar validation for pointer types
  ##   - `analyzeConstructMetadata` - Extracts underlying type metadata

  # Allow basic patterns (variable, wildcard, nil)
  case pattern.kind:
  of nnkIdent:
    # Variable binding or wildcard - always valid
    return ValidationResult(isValid: true, errorMessage: "")

  of nnkNilLit:
    # nil check - always valid for ref types
    return ValidationResult(isValid: true, errorMessage: "")

  else:
    # For other patterns, validate against the underlying type
    # ref T allows patterns that match T (implicit dereferencing)
    if metadata.underlyingTypeNode != nil:
      # Get underlying type metadata
      let underlyingMeta = analyzeConstructMetadata(metadata.underlyingTypeNode)

      # Delegate to appropriate validator based on underlying type and pattern
      case pattern.kind:
      of nnkCall, nnkObjConstr:
        # Object/Option constructor pattern - validate against underlying type
        if underlyingMeta.kind in {ckObject, ckVariantObject}:
          return validateObjectPattern(pattern, underlyingMeta)
        elif underlyingMeta.isOption or underlyingMeta.kind == ckOption:
          # Option pattern (Some/None) - allow through (handled by pattern matching)
          # Option patterns are essentially object patterns (Some[T], None[T])
          return ValidationResult(isValid: true, errorMessage: "")
        else:
          let errorMsg = "Invalid object pattern for ref type:\\n" &
                        "  Pattern: " & pattern.repr & "\\n" &
                        "  Underlying type: " & prettyPrintType(underlyingMeta) & "\\n\\n" &
                        "  Expected object or option type but got: " & $underlyingMeta.kind
          return ValidationResult(isValid: false, errorMessage: errorMsg)

      of nnkBracket:
        # Sequence/array pattern - validate against underlying sequence/array type
        if underlyingMeta.kind in {ckSequence, ckArray}:
          return validateSequencePattern(pattern, underlyingMeta)
        else:
          let errorMsg = "Invalid sequence pattern for ref type:\\n" &
                        "  Pattern: " & pattern.repr & "\\n" &
                        "  Underlying type: " & prettyPrintType(underlyingMeta) & "\\n\\n" &
                        "  Expected sequence or array type but got: " & $underlyingMeta.kind
          return ValidationResult(isValid: false, errorMessage: errorMsg)

      of nnkTupleConstr, nnkPar:
        # Tuple pattern - validate against underlying tuple type
        if underlyingMeta.kind == ckTuple:
          return validateTuplePattern(pattern, underlyingMeta)
        else:
          let errorMsg = "Invalid tuple pattern for ref type:\\n" &
                        "  Pattern: " & pattern.repr & "\\n" &
                        "  Underlying type: " & prettyPrintType(underlyingMeta) & "\\n\\n" &
                        "  Expected tuple type but got: " & $underlyingMeta.kind
          return ValidationResult(isValid: false, errorMessage: errorMsg)

      else:
        # Other patterns - allow through (will be handled by processNestedPattern)
        return ValidationResult(isValid: true, errorMessage: "")
    else:
      # No underlying type node - can't validate, allow through
      return ValidationResult(isValid: true, errorMessage: "")

proc validatePtrPattern*(pattern: NimNode, metadata: ConstructMetadata): ValidationResult {.noSideEffect.} =
  ## Validates pointer type patterns with implicit dereferencing support.
  ##
  ## This validator handles `ptr T` types identically to `ref T`, allowing patterns that
  ## match the underlying type `T` through implicit dereferencing. Supports basic patterns
  ## and delegates underlying type validation.
  ##
  ## **Validation Strategy:**
  ## - **Basic patterns**: Variables (`x`), wildcards (`_`), nil literals always valid
  ## - **Implicit dereferencing**: `ptr Point` accepts `Point(x, y)` patterns
  ## - **Underlying type validation**: Delegates to type-specific validator for `T`
  ## - **Structural analysis**: Uses `metadata.underlyingTypeNode` for recursive validation
  ##
  ## Args:
  ##   pattern: Pattern AST node
  ##   metadata: Scrutinee metadata with ptr type structure
  ##
  ## Returns:
  ##   ValidationResult indicating validity and error details
  ##
  ## Performance:
  ##   O(1) for basic patterns, delegates to underlying type validator otherwise
  ##
  ## See also:
  ##   - `validateRefPattern` - Identical validation logic for ref types

  # Allow basic patterns (variable, wildcard, nil)
  case pattern.kind:
  of nnkIdent:
    # Variable binding or wildcard - always valid
    return ValidationResult(isValid: true, errorMessage: "")

  of nnkNilLit:
    # nil check - always valid for ptr types
    return ValidationResult(isValid: true, errorMessage: "")

  else:
    # For other patterns, validate against the underlying type
    # ptr T allows patterns that match T (implicit dereferencing)
    if metadata.underlyingTypeNode != nil:
      # Get underlying type metadata
      let underlyingMeta = analyzeConstructMetadata(metadata.underlyingTypeNode)

      # Delegate to appropriate validator based on underlying type and pattern
      case pattern.kind:
      of nnkCall, nnkObjConstr:
        # Object/Option constructor pattern - validate against underlying type
        if underlyingMeta.kind in {ckObject, ckVariantObject}:
          return validateObjectPattern(pattern, underlyingMeta)
        elif underlyingMeta.isOption or underlyingMeta.kind == ckOption:
          # Option pattern (Some/None) - allow through (handled by pattern matching)
          # Option patterns are essentially object patterns (Some[T], None[T])
          return ValidationResult(isValid: true, errorMessage: "")
        else:
          let errorMsg = "Invalid object pattern for ptr type:\\n" &
                        "  Pattern: " & pattern.repr & "\\n" &
                        "  Underlying type: " & prettyPrintType(underlyingMeta) & "\\n\\n" &
                        "  Expected object or option type but got: " & $underlyingMeta.kind
          return ValidationResult(isValid: false, errorMessage: errorMsg)

      of nnkBracket:
        # Sequence/array pattern - validate against underlying sequence/array type
        if underlyingMeta.kind in {ckSequence, ckArray}:
          return validateSequencePattern(pattern, underlyingMeta)
        else:
          let errorMsg = "Invalid sequence pattern for ptr type:\\n" &
                        "  Pattern: " & pattern.repr & "\\n" &
                        "  Underlying type: " & prettyPrintType(underlyingMeta) & "\\n\\n" &
                        "  Expected sequence or array type but got: " & $underlyingMeta.kind
          return ValidationResult(isValid: false, errorMessage: errorMsg)

      of nnkTupleConstr, nnkPar:
        # Tuple pattern - validate against underlying tuple type
        if underlyingMeta.kind == ckTuple:
          return validateTuplePattern(pattern, underlyingMeta)
        else:
          let errorMsg = "Invalid tuple pattern for ptr type:\\n" &
                        "  Pattern: " & pattern.repr & "\\n" &
                        "  Underlying type: " & prettyPrintType(underlyingMeta) & "\\n\\n" &
                        "  Expected tuple type but got: " & $underlyingMeta.kind
          return ValidationResult(isValid: false, errorMessage: errorMsg)

      else:
        # Other patterns - allow through (will be handled by processNestedPattern)
        return ValidationResult(isValid: true, errorMessage: "")
    else:
      # No underlying type node - can't validate, allow through
      return ValidationResult(isValid: true, errorMessage: "")

proc validateDequePattern*(pattern: NimNode, metadata: ConstructMetadata): ValidationResult {.noSideEffect.} =
  ## Validates Deque collection patterns as sequence-like patterns.
  ##
  ## This validator treats `Deque[T]` identically to `seq[T]` for pattern matching,
  ## supporting sequence destructuring syntax with spread operators and variable binding.
  ##
  ## **Validation Strategy:**
  ## - **Sequence patterns**: `[a, b, c]` - element destructuring
  ## - **Spread patterns**: `[first, *rest]` - variable-length capture
  ## - **Basic patterns**: Variables and wildcards always valid
  ## - **Delegation**: Delegates to `validateSequencePattern` for sequence validation
  ##
  ## **Pattern Forms:**
  ## - Exact: `[a, b, c]` - matches 3-element deque
  ## - Spread: `[first, *middle, last]` - matches any size ≥ 2
  ## - Variables: `x` - binds entire deque
  ##
  ## Args:
  ##   pattern: Pattern AST node
  ##   metadata: Scrutinee metadata with Deque structure
  ##
  ## Returns:
  ##   ValidationResult indicating validity and error details
  ##
  ## Performance:
  ##   Delegates to validateSequencePattern (O(n) where n = elements)
  ##
  ## See also:
  ##   - `validateSequencePattern` - Sequence validation logic
  ##   - `validateLinkedListPattern` - Similar validation for linked lists

  # Handle variables and wildcards first (valid for any Deque)
  case pattern.kind:
  of nnkIdent:
    # Variable binding or wildcard - always valid
    return ValidationResult(isValid: true, errorMessage: "")

  of nnkBracket:
    # Sequence pattern - delegate to sequence validator
    var seqLikeMetadata = metadata
    seqLikeMetadata.kind = ckSequence
    return validateSequencePattern(pattern, seqLikeMetadata)

  of nnkPar, nnkTupleConstr:
    # Tuple patterns are explicitly rejected for Deque
    let errorMsg = "Invalid tuple pattern for Deque type:\n" &
                  "  Pattern: " & pattern.repr & "\n" &
                  "  Scrutinee type: " & prettyPrintType(metadata) & "\n\n" &
                  "  Deque types do not support tuple patterns.\n" &
                  "  Use sequence patterns [a, b, c] instead.\n" &
                  "  Pattern kind: " & $pattern.kind
    return ValidationResult(isValid: false, errorMessage: errorMsg)

  of nnkCurly:
    # Set patterns are explicitly rejected for Deque
    let errorMsg = "Invalid set pattern for " & prettyPrintType(metadata) & " type:\n" &
                  "  Pattern: " & pattern.repr & "\n\n" &
                  "  Deque types do not support set patterns.\n" &
                  "  Use sequence patterns [...] instead.\n" &
                  "  Example: [element] to match a single element\n" &
                  "  Pattern kind: " & $pattern.kind
    return ValidationResult(isValid: false, errorMessage: errorMsg)

  of nnkInfix:
    # Infix patterns: type checks (is), OR (|), @, guards (and/or)
    # All are valid for Deque - allow through
    return ValidationResult(isValid: true, errorMessage: "")

  else:
    # Invalid pattern for Deque
    let errorMsg = "Invalid pattern for Deque type:\\n" &
                  "  Pattern: " & pattern.repr & "\\n" &
                  "  Scrutinee type: " & prettyPrintType(metadata) & "\\n\\n" &
                  "  Deque types support sequence patterns [a, b, c] or variable bindings.\\n" &
                  "  Pattern kind: " & $pattern.kind
    return ValidationResult(isValid: false, errorMessage: errorMsg)

proc validateLinkedListPattern*(pattern: NimNode, metadata: ConstructMetadata): ValidationResult {.noSideEffect.} =
  ## Validates LinkedList collection patterns as sequence-like patterns.
  ##
  ## This validator treats all LinkedList types (SinglyLinkedList, DoublyLinkedList,
  ## SinglyLinkedRing, DoublyLinkedRing) identically to `seq[T]`, supporting sequence
  ## destructuring with spread operators.
  ##
  ## **Validation Strategy:**
  ## - **Sequence patterns**: `[a, b, c]` - element destructuring
  ## - **Spread patterns**: `[first, *rest]` - variable-length capture
  ## - **Basic patterns**: Variables and wildcards always valid
  ## - **Delegation**: Delegates to `validateSequencePattern` for validation
  ##
  ## Args:
  ##   pattern: Pattern AST node
  ##   metadata: Scrutinee metadata with LinkedList structure
  ##
  ## Returns:
  ##   ValidationResult indicating validity and error details
  ##
  ## Performance:
  ##   Delegates to validateSequencePattern (O(n) where n = elements)
  ##
  ## See also:
  ##   - `validateSequencePattern` - Sequence validation logic
  ##   - `validateDequePattern` - Similar validation for deques

  # Handle variables and wildcards first (valid for any LinkedList)
  case pattern.kind:
  of nnkIdent:
    # Variable binding or wildcard - always valid
    return ValidationResult(isValid: true, errorMessage: "")

  of nnkBracket:
    # Sequence pattern - delegate to sequence validator
    var seqLikeMetadata = metadata
    seqLikeMetadata.kind = ckSequence
    return validateSequencePattern(pattern, seqLikeMetadata)

  of nnkPar, nnkTupleConstr:
    # Tuple patterns are explicitly rejected for LinkedList
    let errorMsg = "Invalid tuple pattern for " & metadata.linkedListVariant & " type:\n" &
                  "  Pattern: " & pattern.repr & "\n" &
                  "  Scrutinee type: " & prettyPrintType(metadata) & "\n\n" &
                  "  LinkedList types do not support tuple patterns.\n" &
                  "  Use sequence patterns [a, b, c] instead.\n" &
                  "  Pattern kind: " & $pattern.kind
    return ValidationResult(isValid: false, errorMessage: errorMsg)

  of nnkCurly:
    # Set patterns are explicitly rejected for LinkedList
    let errorMsg = "Invalid set pattern for " & metadata.linkedListVariant & " type:\n" &
                  "  Pattern: " & pattern.repr & "\n\n" &
                  "  LinkedList types do not support set patterns.\n" &
                  "  Use sequence patterns [...] instead.\n" &
                  "  Example: [element] to match a single element\n" &
                  "  Pattern kind: " & $pattern.kind
    return ValidationResult(isValid: false, errorMessage: errorMsg)

  of nnkInfix:
    # Infix patterns: type checks (is), OR (|), @, guards (and/or)
    # All are valid for LinkedList - allow through
    return ValidationResult(isValid: true, errorMessage: "")

  else:
    # Invalid pattern for LinkedList
    let errorMsg = "Invalid pattern for " & metadata.linkedListVariant & " type:\\n" &
                  "  Pattern: " & pattern.repr & "\\n" &
                  "  Scrutinee type: " & prettyPrintType(metadata) & "\\n\\n" &
                  "  LinkedList types support sequence patterns [a, b, c] or variable bindings.\\n" &
                  "  Pattern kind: " & $pattern.kind
    return ValidationResult(isValid: false, errorMessage: errorMsg)

proc validateJsonNodePattern*(pattern: NimNode, metadata: ConstructMetadata): ValidationResult {.noSideEffect.} =
  ## Validates JSON patterns against JsonNode type with full pattern flexibility.
  ##
  ## This validator treats `JsonNode` as a universal variant type that can hold any JSON
  ## value, accepting all pattern types (literals, arrays, objects, guards, OR patterns).
  ## This reflects JSON's dynamic nature where any structure is potentially valid.
  ##
  ## **Validation Strategy:**
  ## - **All patterns valid**: JsonNode's dynamic nature accepts all pattern types
  ## - **Literal patterns**: `42`, `"hello"`, `true`, `null` - JSON primitives
  ## - **Array patterns**: `[a, b, c]` - JSON array destructuring
  ## - **Object patterns**: Field access for JSON objects
  ## - **Meta-patterns**: OR patterns, guards, @ patterns all supported
  ##
  ## **Pattern Forms:**
  ## - Literals: `42`, `"text"`, `true`, `false`, `nil`
  ## - Arrays: `[1, 2, 3]`, `[first, *rest]`
  ## - Objects: Access via guards or type checks
  ## - Variables: `x` - binds any JSON value
  ## - OR patterns: `42 | "text"` - multiple value types
  ##
  ## Args:
  ##   pattern: Pattern AST node
  ##   metadata: Scrutinee metadata (always JsonNode)
  ##
  ## Returns:
  ##   ValidationResult (always valid for JsonNode)
  ##
  ## Example:
  ##   ```nim
  ##   import json
  ##
  ##   let metadata = analyzeConstructMetadata(JsonNode.getTypeInst())
  ##   let pattern = quote do: [1, 2, 3]
  ##   assert validateJsonNodePattern(pattern, metadata).isValid
  ##   ```
  ##
  ## Performance:
  ##   O(1) - Always returns valid (no actual validation needed)
  ##
  ## See also:
  ##   - `validateObjectPattern` - For structured JSON object validation
  ##   - `validateSequencePattern` - For JSON array validation
  ## Uses structural analysis - accepts all patterns since JsonNode is dynamically typed

  case pattern.kind:
  of nnkIdent:
    # Variable binding, wildcard, or literal (true, false, null)
    return ValidationResult(isValid: true, errorMessage: "")

  of nnkIntLit, nnkFloatLit, nnkStrLit, nnkNilLit:
    # Literal values - always valid for JsonNode
    return ValidationResult(isValid: true, errorMessage: "")

  of nnkBracket:
    # Array pattern - valid for JsonNode arrays
    # Recursively validate elements
    for element in pattern:
      let elementResult = validateJsonNodePattern(element, metadata)
      if not elementResult.isValid:
        return elementResult
    return ValidationResult(isValid: true, errorMessage: "")

  of nnkTableConstr, nnkCurly:
    # Object/table pattern - valid for JsonNode objects
    # Recursively validate entries
    for entry in pattern:
      if entry.kind == nnkExprColonExpr and entry.len >= 2:
        let keyResult = validateJsonNodePattern(entry[0], metadata)
        if not keyResult.isValid:
          return keyResult
        let valueResult = validateJsonNodePattern(entry[1], metadata)
        if not valueResult.isValid:
          return valueResult
    return ValidationResult(isValid: true, errorMessage: "")

  of nnkCall:
    # Could be object field access or function call pattern
    # For JsonNode, field access is valid
    return ValidationResult(isValid: true, errorMessage: "")

  of nnkInfix:
    # OR pattern, guard, or other infix operators
    # All valid for JsonNode
    if pattern.len >= 3:
      # Recursively validate operands
      let leftResult = validateJsonNodePattern(pattern[1], metadata)
      if not leftResult.isValid:
        return leftResult
      let rightResult = validateJsonNodePattern(pattern[2], metadata)
      if not rightResult.isValid:
        return rightResult
    return ValidationResult(isValid: true, errorMessage: "")

  of nnkTupleConstr, nnkPar:
    # Tuple pattern - valid for JsonNode arrays!
    # JSON arrays can be destructured like tuples: (x, y, z)
    # Recursively validate elements
    for element in pattern:
      let elementResult = validateJsonNodePattern(element, metadata)
      if not elementResult.isValid:
        return elementResult
    return ValidationResult(isValid: true, errorMessage: "")

  of nnkPrefix:
    # Prefix operator (like spread * or negation)
    # Valid for JsonNode
    return ValidationResult(isValid: true, errorMessage: "")

  else:
    # Unknown pattern kind - accept for JsonNode (dynamically typed)
    return ValidationResult(isValid: true, errorMessage: "")

proc generateValidationError*(pattern: NimNode, metadata: ConstructMetadata,
                             errorMsg: string): string =
  ## Generates comprehensive validation error messages with full context.
  ##
  ## This is a **generic error generator** providing structured error messages that include
  ## the error description, pattern representation, and scrutinee type information. Used as
  ## a fallback when specialized error generators aren't available.
  ##
  ## **Error Message Structure:**
  ## - Error prefix: "Pattern validation error:"
  ## - Custom error message (provided by caller)
  ## - Pattern representation (via `pattern.repr`)
  ## - Scrutinee type (via `prettyPrintType`)
  ##
  ## Args:
  ##   pattern: Pattern AST node that failed validation
  ##   metadata: Scrutinee metadata for type context
  ##   errorMsg: Specific error description
  ##
  ## Returns:
  ##   Formatted error message string
  ##
  ## Example:
  ##   ```nim
  ##   let error = generateValidationError(
  ##     pattern,
  ##     metadata,
  ##     "Field 'z' does not exist"
  ##   )
  ##   # Returns:
  ##   # Pattern validation error: Field 'z' does not exist
  ##   #   Pattern: Point(x, y, z)
  ##   #   Scrutinee type: Point (fields: x, y)
  ##   ```
  ##
  ## Performance:
  ##   O(1) - String concatenation
  ##
  ## See also:
  ##   - `generateFieldError` - Specialized field error generator
  ##   - `generateTypeMismatchError` - Type mismatch errors
  ##   - `prettyPrintType` - Type formatting (construct_metadata.nim)

  result = "Pattern validation error: " & errorMsg & "\n"
  result &= "  Pattern: " & pattern.repr & "\n"
  result &= "  Scrutinee type: " & prettyPrintType(metadata)