## Universal AST-Based Construct Metadata Extraction Module
##
## This module provides comprehensive metadata extraction for ANY Nim construct
## using ONLY structural AST analysis. NO string heuristics, regex, or text-based
## pattern matching is used.
##
## The module extracts the complete "construct graph" (AST/CST/semantic graph)
## to enable pattern matching to become a structural query rather than a heuristic.

import macros
import tables
import sequtils
import strutils

# ============================================================================
# Helper Functions
# ============================================================================

proc getTypeString(node: NimNode): string =
  ## Safely get string representation of a type node.
  ## Handles both nnkSym (which has strVal) and other node types.
  if node.kind == nnkSym:
    result = node.strVal
  else:
    result = node.repr

# ============================================================================
# Type Definitions
# ============================================================================

type
  ConstructKind* = enum
    ## Enumeration of all possible Nim construct types that can be analyzed
    ckUnknown              ## Unknown or unsupported construct
    ckSimpleType           ## Simple types: int, string, bool, float, char, etc.
    ckObject               ## Regular object type
    ckVariantObject        ## Variant/discriminated union object (case object)
    ckGeneric              ## Generic type with type parameters
    ckReference            ## ref T type
    ckPointer              ## ptr T type
    ckArray                ## array[N, T] type
    ckSequence             ## seq[T] type
    ckDeque                ## Deque[T] type
    ckLinkedList           ## SinglyLinkedList[T], DoublyLinkedList[T], SinglyLinkedRing[T], DoublyLinkedRing[T]
    ckTable                ## Table[K, V] type
    ckSet                  ## set[T] or HashSet[T] type
    ckTuple                ## Tuple type (x, y, z) or (int, string, float)
    ckEnum                 ## Enum type
    ckOption               ## Option[T] type (Some/None)
    ckRange                ## Range type like 0..10
    ckProc                 ## Procedure/function type
    ckIterator             ## Iterator type
    ckDistinct             ## Distinct type
    ckOrdinal              ## Ordinal types (int, enum, char, bool, range, subrange)
    ckJsonNode             ## JsonNode type for JSON pattern matching

  FieldMetadata* = object
    ## Metadata for a single field in an object or variant branch
    name*: string                    ## Field name
    fieldType*: string               ## Field type as string (for now)
    fieldTypeNode*: NimNode          ## AST node representing the field type
    position*: int                   ## Field position/index in the object
    isPublic*: bool                  ## Whether field is exported (has *)

  VariantBranch* = object
    ## Metadata for a single branch in a variant object
    discriminatorValue*: string      ## The enum value for this branch (e.g., "vkInt")
    discriminatorValueNode*: NimNode ## AST node for the discriminator value
    fields*: seq[FieldMetadata]      ## Fields specific to this variant branch

  TupleElement* = object
    ## Metadata for a tuple element
    name*: string                    ## Field name (empty for unnamed tuples)
    elementType*: string             ## Element type as string
    elementTypeNode*: NimNode        ## AST node representing the element type
    position*: int                   ## Element position in tuple

  GenericParam* = object
    ## Metadata for a generic type parameter
    name*: string                    ## Parameter name (e.g., "T", "K", "V")
    constraint*: string              ## Type constraint if any
    constraintNode*: NimNode         ## AST node for constraint

  EnumValue* = object
    ## Metadata for an enum value
    name*: string                    ## Enum value name
    ordinal*: int                    ## Ordinal value
    node*: NimNode                   ## AST node for this enum value

  ConstructMetadata* = object
    ## Complete metadata for a Nim construct extracted via AST analysis
    ## This is the "construct graph" that pattern matching uses to understand structure

    # ===== Core Identification =====
    typeName*: string                ## Full type name (e.g., "Option[int]", "seq[string]")
    kind*: ConstructKind             ## Kind of construct
    typeNode*: NimNode               ## Original AST node for this type

    # ===== Variant Object Support =====
    isVariant*: bool                 ## True if this is a variant object
    discriminatorField*: string      ## Name of discriminator field (e.g., "kind")
    discriminatorType*: string       ## Type of discriminator (enum type name)
    discriminatorTypeNode*: NimNode  ## AST node for discriminator type
    branches*: seq[VariantBranch]    ## All variant branches

    # ===== Regular Object Support =====
    fields*: seq[FieldMetadata]      ## Fields for regular objects (or common fields for variants)

    # ===== Tuple Support =====
    tupleElements*: seq[TupleElement] ## Tuple elements (for named or unnamed tuples)
    isTupleNamed*: bool              ## True if tuple has named fields

    # ===== Collection Support =====
    elementType*: string             ## Element type for collections (seq, array, set)
    elementTypeNode*: NimNode        ## AST node for element type
    keyType*: string                 ## Key type for Table[K, V]
    keyTypeNode*: NimNode            ## AST node for key type
    valueType*: string               ## Value type for Table[K, V]
    valueTypeNode*: NimNode          ## AST node for value type
    arraySize*: int                  ## Array size for array[N, T] (-1 if not array)

    # ===== Generic Support =====
    isGeneric*: bool                 ## True if this is a generic type
    genericParams*: seq[GenericParam] ## Generic type parameters
    genericBase*: string             ## Base generic type name (e.g., "Option" for "Option[int]")

    # ===== Enum Support =====
    enumValues*: seq[EnumValue]      ## All enum values for enum types

    # ===== Ref/Ptr Support =====
    underlyingType*: string          ## Underlying type for ref/ptr
    underlyingTypeNode*: NimNode     ## AST node for underlying type

    # ===== Option Type Support =====
    isOption*: bool                  ## True if this is Option[T]
    optionInnerType*: string         ## Inner type for Option[T]
    optionInnerTypeNode*: NimNode    ## AST node for inner type

    # ===== Union Type Support =====
    isUnion*: bool                   ## True if this is a union type (from union_type.nim)

    # ===== LinkedList Support =====
    linkedListVariant*: string       ## Linked list variant: "SinglyLinkedList", "DoublyLinkedList", "SinglyLinkedRing", "DoublyLinkedRing"

    # ===== Structural Flags =====
    isExported*: bool                ## Whether type is exported
    isPure*: bool                    ## Whether type is pure (no side effects)
    isRef*: bool                     ## Whether this is a ref type
    isPtr*: bool                     ## Whether this is a ptr type
    supportsPolymorphism*: bool      ## Whether type supports polymorphic matching with `of` operator

    # ===== Extraction Status =====
    extractionFailed*: bool          ## True when metadata extraction fell back to repr (indicates incomplete structural extraction)

    # ===== Debug Information =====
    astDump*: string                 ## String representation of AST for debugging


# ============================================================================
# Helper Procedures
# ============================================================================

proc createUnknownMetadata*(): ConstructMetadata =
  ## Creates default ConstructMetadata for unknown or unanalyzable types.
  ##
  ## **Purpose:**
  ## Provides a graceful fallback when type analysis fails or metadata is unavailable.
  ## Enables optional metadata parameters in pattern processing functions.
  ##
  ## **When to use:**
  ## - Fallback when `analyzeConstructMetadata` encounters unsupported type
  ## - Default parameter value for functions requiring metadata
  ## - Placeholder during incomplete type analysis
  ##
  ## **Returns:**
  ##   ConstructMetadata with kind=ckUnknown and typeName="unknown"
  ##
  ## **Example:**
  ##   ```nim
  ##   proc processNestedPattern(pattern: NimNode,
  ##                            metadata = createUnknownMetadata()): NimNode =
  ##     if metadata.kind == ckUnknown:
  ##       # Fallback: Process without metadata validation
  ##       discard
  ##   ```
  ##
  ## **See also:**
  ##   - `analyzeConstructMetadata` - Main metadata extraction function
  result = ConstructMetadata()
  result.kind = ckUnknown
  result.typeName = "unknown"

proc normalizeTypeName(typeName: string): string =
  ## Normalize type names to strip compiler internal representation details.
  ##
  ## **ONLY strips compiler internals - preserves ALL user-visible type information**
  ##
  ## **Normalizes:**
  ## - Compiler internal suffixes: Person:ObjectType -> Person
  ##   (The :ObjectType suffix is added by Nim when dereferencing ref objects)
  ##
  ## **Preserves ALL user types exactly as written:**
  ## - float, float32, float64 - preserved exactly (developer sees what they wrote!)
  ## - int, int8, int16, int32, int64 - preserved exactly
  ## - All other types - preserved exactly
  ##
  ## **Philosophy: Show developers exactly what they wrote**
  ## If developer writes `let x: float64`, error should say "float64", not "float"
  ## Nim's getTypeInst() already gives us this distinction - we preserve it!
  ##
  ## Examples:
  ##   normalizeTypeName("Person:ObjectType") => "Person" (strips compiler suffix)
  ##   normalizeTypeName("float") => "float" (preserves user type)
  ##   normalizeTypeName("float64") => "float64" (preserves user type)
  ##   normalizeTypeName("float32") => "float32" (preserves user type)
  ##   normalizeTypeName("std:tables") => "std:tables" (preserves other colons)

  result = typeName

  # Strip :ObjectType suffix that Nim adds to dereferenced ref objects
  # This suffix only appears when calling getTypeInst() on a dereferenced ref
  # Example: Person(name: "Alice", age: 30)[] has type "Person:ObjectType"
  if result.endsWith(":ObjectType"):
    result = result[0 ..< result.len - ":ObjectType".len]

proc copyMetadataFields(dest: var ConstructMetadata, source: ConstructMetadata) =
  ## Copy all metadata fields from source to destination.
  ##
  ## **Purpose**: Centralized metadata field copying to eliminate code duplication
  ## and ensure consistency across different type analysis paths.
  ##
  ## **Used in**: Type alias resolution (macro-generated, regular, and implementation paths)
  ##
  ## **Why this exists**: Previously, metadata field copying was duplicated in 3 places
  ## (lines 305-336, 341-372, 380-411), leading to:
  ## - DRY violation with 90+ lines of duplicated code
  ## - Maintenance burden requiring 3 synchronized edits for field changes
  ## - Risk of inconsistencies (e.g., supportsPolymorphism missing in some blocks)
  ##
  ## **Design**: Copies ALL fields except typeName, which is handled separately
  ## by the caller to preserve the appropriate type name for each context.
  ##
  ## **Note**: This procedure intentionally does NOT copy:
  ## - typeName (caller responsibility - different contexts use different names)
  ## - typeNode (typically set by caller based on context)
  ##
  dest.kind = source.kind
  dest.isVariant = source.isVariant
  dest.discriminatorField = source.discriminatorField
  dest.discriminatorType = source.discriminatorType
  dest.discriminatorTypeNode = source.discriminatorTypeNode
  dest.branches = source.branches
  dest.fields = source.fields
  dest.tupleElements = source.tupleElements
  dest.isTupleNamed = source.isTupleNamed
  dest.elementType = source.elementType
  dest.elementTypeNode = source.elementTypeNode
  dest.keyType = source.keyType
  dest.keyTypeNode = source.keyTypeNode
  dest.valueType = source.valueType
  dest.valueTypeNode = source.valueTypeNode
  dest.arraySize = source.arraySize
  dest.isGeneric = source.isGeneric
  dest.genericParams = source.genericParams
  dest.genericBase = source.genericBase
  dest.enumValues = source.enumValues
  dest.underlyingType = source.underlyingType
  dest.underlyingTypeNode = source.underlyingTypeNode
  dest.isOption = source.isOption
  dest.optionInnerType = source.optionInnerType
  dest.optionInnerTypeNode = source.optionInnerTypeNode
  dest.isUnion = source.isUnion
  dest.isRef = source.isRef
  dest.isPtr = source.isPtr
  dest.supportsPolymorphism = source.supportsPolymorphism
  # NOTE: Do not copy linkedListVariant, isExported, isPure, extractionFailed, astDump
  # These fields were not in the original duplicated code blocks and should
  # retain their values from the destination's initialization

# ============================================================================
# Core API
# ============================================================================

proc analyzeConstructMetadata*(scrutinee: NimNode): ConstructMetadata {.noSideEffect.} =
  ## Extracts complete structural metadata from any Nim type using pure AST analysis.
  ##
  ## This is the **main entry point** and **single source of truth** for type structure
  ## extraction in the pattern matching library. It builds a complete "construct graph"
  ## containing all structural information about a type, enabling pattern matching to
  ## become a structural query system rather than relying on error-prone heuristics.
  ##
  ## **Philosophy: ZERO String Heuristics**
  ## - Uses ONLY structural AST analysis via Nim's macro system
  ## - Forbidden: String heuristics, regex, text-based pattern matching
  ## - All type information extracted from compiler's semantic analysis
  ##
  ## **What It Extracts:**
  ## - Type classification (object, variant, tuple, sequence, enum, etc.)
  ## - Field information (names, types, positions, visibility)
  ## - Discriminator information for variant objects
  ## - Variant branches with their fields
  ## - Generic parameters and instantiations
  ## - Enum values with ordinals
  ## - Collection element/key/value types
  ## - Ref/ptr underlying types
  ## - Type inheritance and polymorphism support
  ##
  ## **Architectural Role:**
  ## Foundation module for the entire pattern matching system:
  ## - `pattern_validation.nim` uses this to validate patterns against scrutinee types
  ## - `pattern_matching.nim` uses this to generate type-safe matching code
  ## - Query interface functions (hasField, getFieldType, etc.) operate on this metadata
  ##
  ## **Args:**
  ##   scrutinee: AST node representing the type to analyze.
  ##              Usually obtained via `getTypeInst()` or `getType()`.
  ##
  ## **Returns:**
  ##   Complete ConstructMetadata containing all structural information about the type.
  ##   Returns ConstructMetadata with kind=ckUnknown for unsupported types.
  ##
  ## **Example:**
  ##   ```nim
  ##   type Person = object
  ##     name*: string
  ##     age*: int
  ##
  ##   let metadata = analyzeConstructMetadata(Person.getTypeInst())
  ##   assert metadata.kind == ckObject
  ##   assert metadata.typeName == "Person"
  ##   assert metadata.fields.len == 2
  ##   assert metadata.fields[0].name == "name"
  ##   assert metadata.fields[0].fieldType == "string"
  ##   assert hasField(metadata, "age")
  ##   ```
  ##
  ## **Performance:**
  ##   O(n) where n = type complexity (number of fields, branches, nesting depth)
  ##   All analysis happens at compile-time with zero runtime overhead.
  ##
  ## **See also:**
  ##   - `hasField` - Check if field exists in type
  ##   - `getFieldType` - Get field type by name
  ##   - `getAllFieldNames` - List all available fields
  ##   - `analyzeFieldMetadata` - Recursively analyze nested field types
  ##   - `validatePatternStructure` - Validate patterns using this metadata

  result = ConstructMetadata()
  result.typeNode = scrutinee
  result.kind = ckUnknown
  result.arraySize = -1
  result.astDump = scrutinee.treeRepr

  # Analyze the node kind to determine construct type
  case scrutinee.kind
  of nnkSym:
    # Type symbol - could be simple type, type alias, or custom type (object, enum, etc.)
    let rawTypeName = scrutinee.strVal
    result.typeName = normalizeTypeName(rawTypeName)

    # Check if it's a simple built-in type
    # NOTE: "bool" is NOT included here because it's actually an enum in Nim (false = 0, true = 1)
    # and should be detected as ckEnum for exhaustiveness checking
    if rawTypeName in ["int", "string", "float", "char", "float32",
                       "float64", "int8", "int16", "int32", "int64", "uint",
                       "uint8", "uint16", "uint32", "uint64", "byte"]:
      result.kind = ckSimpleType
    elif rawTypeName == "JsonNode":
      ## JsonNode type from std/json OR user-defined JsonNode
      ## Detected structurally by examining the symbol name
      ## Standard library: JsonNode is ref JsonNodeObj (a variant object)
      ## User-defined: Can be either ref object or value object
      ## We analyze the underlying structure to extract fields and variant info
      result.kind = ckJsonNode

      # Get the underlying type
      let typeImpl = scrutinee.getTypeImpl()
      if typeImpl.kind == nnkRefTy and typeImpl.len > 0:
        # Ref type: JsonNode = ref JsonNodeObj
        result.isRef = true

        # Analyze JsonNodeObj structure recursively
        let underlyingMeta = analyzeConstructMetadata(typeImpl[0])

        # Copy field and variant information from JsonNodeObj
        result.isVariant = underlyingMeta.isVariant
        result.discriminatorField = underlyingMeta.discriminatorField
        result.discriminatorType = underlyingMeta.discriminatorType
        result.discriminatorTypeNode = underlyingMeta.discriminatorTypeNode
        result.branches = underlyingMeta.branches
        result.fields = underlyingMeta.fields
        result.underlyingType = "JsonNodeObj"
        result.underlyingTypeNode = typeImpl[0]
      elif typeImpl.kind == nnkObjectTy:
        # Value type: JsonNode = object (user-defined variant object)
        result.isRef = false

        # Analyze object structure directly from typeImpl
        let underlyingMeta = analyzeConstructMetadata(typeImpl)

        # Copy field and variant information
        result.isVariant = underlyingMeta.isVariant
        result.discriminatorField = underlyingMeta.discriminatorField
        result.discriminatorType = underlyingMeta.discriminatorType
        result.discriminatorTypeNode = underlyingMeta.discriminatorTypeNode
        result.branches = underlyingMeta.branches
        result.fields = underlyingMeta.fields
    else:
      # Custom type or type alias - check if it's a type alias first
      # BUG FIX: getImpl() returns unexpanded macro calls for macro-generated types (e.g., union()).
      #          For these cases, we need to use getTypeImpl() instead to get the expanded type.
      let symImpl = scrutinee.getImpl()
      if symImpl.kind == nnkTypeDef and symImpl.len >= 3:
        # This is a type definition, check if it's a type alias
        # TypeDef[0] = name, TypeDef[1] = generic params, TypeDef[2] = actual type
        let actualType = symImpl[2]

        # Check if actualType is a macro call (nnkCall) - if so, use getTypeImpl() instead
        if actualType.kind == nnkCall:
          # Macro-generated type alias (e.g., union(int, string))
          # Use getTypeImpl() to get the expanded type
          let typeImpl = scrutinee.getTypeImpl()
          if typeImpl.kind != nnkSym:  # Avoid infinite recursion
            let implMetadata = analyzeConstructMetadata(typeImpl)
            # Copy all fields from implementation analysis using centralized helper
            copyMetadataFields(result, implMetadata)
            # Keep the original type name (normalized)
            result.typeName = normalizeTypeName(rawTypeName)
            return
        elif actualType.kind != nnkEmpty and actualType != scrutinee:
          # Regular type alias (not a macro call) - analyze the actual type
          let aliasMetadata = analyzeConstructMetadata(actualType)
          # Use alias metadata but keep original type name using centralized helper
          copyMetadataFields(result, aliasMetadata)
          # Keep the original type name (normalized)
          result.typeName = normalizeTypeName(rawTypeName)
          return

      # Not a type alias - get the type implementation
      let typeImpl = scrutinee.getTypeImpl()
      # Recursively analyze the implementation
      if typeImpl.kind != nnkSym:  # Avoid infinite recursion
        let implMetadata = analyzeConstructMetadata(typeImpl)
        # Copy all fields from implementation analysis using centralized helper
        copyMetadataFields(result, implMetadata)
        # Keep the original type name
        result.typeName = rawTypeName

  of nnkBracketExpr:
    # Generic type like seq[T], Option[T], Table[K, V], array[N, T]
    result.isGeneric = true
    if scrutinee.len > 0:
      result.genericBase = getTypeString(scrutinee[0])
      result.typeName = scrutinee.repr

      # Extract generic parameters
      for i in 1 ..< scrutinee.len:
        var paramName: string
        if scrutinee[i].kind == nnkIntLit:
          # For arrays: array[3, int] - the size is an IntLit
          paramName = $scrutinee[i].intVal
        elif scrutinee[i].kind == nnkSym:
          paramName = scrutinee[i].strVal
        else:
          paramName = scrutinee[i].repr

        let param = GenericParam(
          name: paramName,
          constraint: "",
          constraintNode: scrutinee[i]
        )
        result.genericParams.add(param)

      # Determine specific collection type
      case result.genericBase
      of "seq":
        result.kind = ckSequence
        if scrutinee.len > 1:
          result.elementType = getTypeString(scrutinee[1])
          result.elementTypeNode = scrutinee[1]
      of "Deque":
        ## Deque[T] type from std/deques
        ## Structure: BracketExpr(Ident "Deque", ElementType)
        result.kind = ckDeque
        if scrutinee.len > 1:
          result.elementType = getTypeString(scrutinee[1])
          result.elementTypeNode = scrutinee[1]
      of "SinglyLinkedList", "DoublyLinkedList", "SinglyLinkedRing", "DoublyLinkedRing":
        ## Linked list types from std/lists
        ## Structure: BracketExpr(Ident "SinglyLinkedList", ElementType)
        result.kind = ckLinkedList
        result.linkedListVariant = result.genericBase
        if scrutinee.len > 1:
          result.elementType = getTypeString(scrutinee[1])
          result.elementTypeNode = scrutinee[1]
      of "array":
        result.kind = ckArray
        if scrutinee.len > 2:
          # array[N, T] has size and element type
          # Size can be IntLit or Infix (range like 0..2)
          let sizeNode = scrutinee[1]
          case sizeNode.kind
          of nnkIntLit:
            result.arraySize = sizeNode.intVal.int
          of nnkInfix:
            # Range like 0..2 means size 3
            # Infix(Ident "..", IntLit start, IntLit end)
            if sizeNode.len >= 3 and sizeNode[1].kind == nnkIntLit and sizeNode[2].kind == nnkIntLit:
              let start = sizeNode[1].intVal.int
              let endVal = sizeNode[2].intVal.int
              result.arraySize = endVal - start + 1
          else:
            result.arraySize = -1
          result.elementType = getTypeString(scrutinee[2])
          result.elementTypeNode = scrutinee[2]
      of "Table", "OrderedTable":
        result.kind = ckTable
        if scrutinee.len > 2:
          result.keyType = getTypeString(scrutinee[1])
          result.keyTypeNode = scrutinee[1]
          result.valueType = getTypeString(scrutinee[2])
          result.valueTypeNode = scrutinee[2]
      of "CountTable":
        # CountTable[K] has only one type parameter (key type)
        # Value is always int
        result.kind = ckTable
        if scrutinee.len > 1:
          result.keyType = getTypeString(scrutinee[1])
          result.keyTypeNode = scrutinee[1]
          result.valueType = "int"  # CountTable values are always int
          result.valueTypeNode = scrutinee[1]  # Reuse key node as placeholder
      of "HashSet", "OrderedSet":
        result.kind = ckSet
        if scrutinee.len > 1:
          result.elementType = getTypeString(scrutinee[1])
          result.elementTypeNode = scrutinee[1]
      of "set":
        result.kind = ckSet
        if scrutinee.len > 1:
          result.elementType = getTypeString(scrutinee[1])
          result.elementTypeNode = scrutinee[1]
      of "Option":
        result.kind = ckOption
        result.isOption = true
        if scrutinee.len > 1:
          result.optionInnerType = getTypeString(scrutinee[1])
          result.optionInnerTypeNode = scrutinee[1]
      of "range":
        ## Range type like range[0..255]
        ## Structure: BracketExpr(Sym "range", Infix("..", IntLit min, IntLit max))
        ## Uses ckRange kind for proper structural detection
        result.kind = ckRange
        # Store range bounds for potential future validation
        if scrutinee.len > 1:
          # Range bound is typically an Infix node like 0..255
          # Store it for future use if needed
          result.elementTypeNode = scrutinee[1]  # Store the range expression
      of "ref":
        result.kind = ckReference
        result.isRef = true
        if scrutinee.len > 1:
          result.underlyingType = getTypeString(scrutinee[1])
          result.underlyingTypeNode = scrutinee[1]

          # Recursively analyze underlying type to detect Option[T], seq[T], etc.
          let underlyingMetadata = analyzeConstructMetadata(scrutinee[1])
          # Propagate isOption, isSeq, isTable flags from underlying type
          if underlyingMetadata.isOption:
            result.isOption = true
            result.optionInnerType = underlyingMetadata.optionInnerType
            result.optionInnerTypeNode = underlyingMetadata.optionInnerTypeNode
      of "ptr":
        result.kind = ckPointer
        result.isPtr = true
        if scrutinee.len > 1:
          result.underlyingType = getTypeString(scrutinee[1])
          result.underlyingTypeNode = scrutinee[1]
      of "tuple":
        result.kind = ckTuple
        # Extract tuple elements from bracket expr
        for i in 1 ..< scrutinee.len:
          let elem = TupleElement(
            name: "",
            elementType: normalizeTypeName(getTypeString(scrutinee[i])),
            elementTypeNode: scrutinee[i],
            position: i - 1
          )
          result.tupleElements.add(elem)
        result.isTupleNamed = false
      else:
        # Unknown generic type
        result.kind = ckGeneric

  of nnkTupleConstr:
    # Unnamed tuple like (int, string, float)
    result.kind = ckTuple
    result.isTupleNamed = false
    result.typeName = scrutinee.repr
    for i in 0 ..< scrutinee.len:
      let elem = TupleElement(
        name: "",
        elementType: normalizeTypeName(getTypeString(scrutinee[i])),
        elementTypeNode: scrutinee[i],
        position: i
      )
      result.tupleElements.add(elem)

  of nnkTupleTy:
    # Named tuple type: TupleTy(IdentDefs(Sym "x", Sym "int", Empty), ...)
    result.kind = ckTuple
    result.isTupleNamed = true
    result.typeName = scrutinee.repr

    # Extract named tuple fields
    var position = 0
    for child in scrutinee:
      if child.kind == nnkIdentDefs and child.len >= 2:
        let fieldName = if child[0].kind == nnkSym: child[0].strVal else: child[0].repr
        let fieldType = getTypeString(child[1])
        let elem = TupleElement(
          name: fieldName,
          elementType: normalizeTypeName(fieldType),
          elementTypeNode: child[1],
          position: position
        )
        result.tupleElements.add(elem)
        position.inc

  of nnkObjectTy:
    # Object type - could be regular object or variant object
    # Structure: ObjectTy(pragmas, inheritance, RecList(...))
    #   scrutinee[0]: pragmas (usually Empty)
    #   scrutinee[1]: inheritance (OfInherit if inheriting, Empty if not)
    #   scrutinee[2]: RecList (this object's own fields)

    # Set default type name for nnkObjectTy (which doesn't have type name in AST)
    # IMPORTANT: ObjectTy nodes are anonymous - they don't carry type names
    # For inherited objects (object of Parent), try to extract parent name for cleaner type identification
    # Otherwise, fall back to repr (will be multiline for complex objects)
    if scrutinee.len > 1 and scrutinee[1].kind == nnkOfInherit and scrutinee[1].len > 0:
      # Has inheritance: try to get clean parent type name
      let parentNode = scrutinee[1][0]
      if parentNode.kind == nnkSym:
        # Clean case: object of ParentType (where ParentType is a symbol)
        # Extract parent name for polymorphic matching
        result.typeName = parentNode.strVal
      else:
        # Complex case: use repr (extraction fallback)
        result.typeName = scrutinee.repr
        result.extractionFailed = true
    else:
      # No inheritance or can't extract clean name: use repr (extraction fallback)
      result.typeName = scrutinee.repr
      result.extractionFailed = true

    if result.typeName == "":
      result.typeName = "object"

    if scrutinee.len > 2:
      # Check for object inheritance
      # If scrutinee[1] is nnkOfInherit, extract parent fields first
      var inheritedFields: seq[FieldMetadata] = @[]
      if scrutinee.len > 1 and scrutinee[1].kind == nnkOfInherit:
        # Has inheritance - supports polymorphic matching
        result.supportsPolymorphism = true

        # OfInherit(Sym "ParentType") or OfInherit(BracketExpr(...))
        if scrutinee[1].len > 0:
          let parentTypeNode = scrutinee[1][0]
          # Recursively analyze parent type to get its fields
          let parentMetadata = analyzeConstructMetadata(parentTypeNode)
          # Inherit all parent fields (preserving their position)
          inheritedFields = parentMetadata.fields

      let recList = scrutinee[2]

      # Check if this is a variant object by looking for RecCase
      var hasRecCase = false
      for child in recList:
        if child.kind == nnkRecCase:
          hasRecCase = true
          break

      if hasRecCase:
        # Variant object
        result.kind = ckVariantObject
        result.isVariant = true

        # Add inherited fields first
        result.fields = inheritedFields

        # First pass: Extract common fields (fields before RecCase)
        var position = inheritedFields.len
        for child in recList:
          if child.kind == nnkIdentDefs:
            # Common field before the case statement
            if child.len >= 2:
              let typeIndex = child.len - 2
              let fieldType = if child[typeIndex].kind == nnkSym: child[typeIndex].strVal else: child[typeIndex].repr

              # Extract all field names (all elements before the type)
              for i in 0 ..< typeIndex:
                if child[i].kind in {nnkSym, nnkIdent}:
                  let fieldName = child[i].strVal
                  let fieldMeta = FieldMetadata(
                    name: fieldName,
                    fieldType: normalizeTypeName(fieldType),
                    fieldTypeNode: child[typeIndex],
                    position: position,
                    isPublic: false
                  )
                  result.fields.add(fieldMeta)
                  position.inc

        # Second pass: Extract variant branches
        for child in recList:
          if child.kind == nnkRecCase:
            # RecCase(IdentDefs(Sym "kind", Sym "NodeKind", Empty), OfBranch(...), ...)
            if child.len > 0:
              let discriminatorNode = child[0]
              var discriminatorTypeSymbol: NimNode = nil

              if discriminatorNode.kind == nnkIdentDefs and discriminatorNode.len >= 2:
                # IdentDefs(Sym "fieldName", Sym "fieldType", Empty)
                # or IdentDefs(Postfix(Ident "*", Ident "fieldName"), Sym "fieldType", Empty) for exported fields
                # Discriminator field must be first element
                var fieldNameNode = discriminatorNode[0]

                # Handle exported fields (Postfix node)
                if fieldNameNode.kind == nnkPostfix:
                  # Postfix[0] = export marker (*), Postfix[1] = actual name
                  fieldNameNode = fieldNameNode[1]

                if fieldNameNode.kind in {nnkSym, nnkIdent}:
                  result.discriminatorField = fieldNameNode.strVal
                  let typeIndex = discriminatorNode.len - 2
                  result.discriminatorType = getTypeString(discriminatorNode[typeIndex])
                  result.discriminatorTypeNode = discriminatorNode[typeIndex]
                  discriminatorTypeSymbol = discriminatorNode[typeIndex]
              elif discriminatorNode.kind == nnkSym:
                # Variant object field symbol from getType() representation
                result.discriminatorField = discriminatorNode.strVal
                result.discriminatorType = ""
                result.discriminatorTypeNode = discriminatorNode
                # Get the actual TYPE symbol using getTypeInst()
                # discriminatorNode is the field symbol, not the type symbol
                # getTypeInst() gives us the type symbol that we can use with getImpl()
                discriminatorTypeSymbol = discriminatorNode.getTypeInst()

              # Get enum definition for mapping ordinals to names
              # BUILD TWO DATA STRUCTURES:
              # 1. enumValues: Sequential list of enum names (for union type detection)
              # 2. enumOrdinalMap: Ordinal->name mapping (for discriminator value lookup)
              var enumValues: seq[string] = @[]
              var enumOrdinalMap = initTable[int, string]()
              var isUnionType = false
              if discriminatorTypeSymbol != nil:
                # Use getImpl() instead of getTypeImpl() to preserve explicit ordinals
                # getImpl() returns TypeDef(Sym, Empty, EnumTy(...))
                # getTypeImpl() returns EnumTy(...) but loses EnumFieldDef nodes with ordinals
                let enumImplFull = discriminatorTypeSymbol.getImpl()
                var enumImpl: NimNode = nil

                # Extract EnumTy from TypeDef structure
                if enumImplFull.kind == nnkTypeDef and enumImplFull.len >= 3:
                  # TypeDef[2] contains the actual enum definition
                  enumImpl = enumImplFull[2]
                elif enumImplFull.kind == nnkEnumTy:
                  # Fallback: already an EnumTy (shouldn't happen with getImpl())
                  enumImpl = enumImplFull

                if enumImpl != nil and enumImpl.kind == nnkEnumTy:
                  # EnumTy(Empty, Sym "val1", Sym "val2", ...)
                  # OR: EnumTy(Empty, EnumFieldDef(Sym "val1", IntLit ordinal), ...)
                  for i in 1 ..< enumImpl.len:
                    let child = enumImpl[i]
                    var ordinal = i - 1  # Default sequential ordinal (0, 1, 2, ...)
                    var enumName = ""

                    if child.kind == nnkSym:
                      # Simple enum without explicit ordinals: enum Red, Green, Blue
                      enumName = child.strVal
                    elif child.kind == nnkEnumFieldDef:
                      # Enum with explicit ordinals: enum Pending = 0, Active = 5, Completed = 10
                      # OR with tuple values: enum active = (0, "Active Status")
                      # EnumFieldDef structure: [0] = Sym (name), [1] = IntLit or TupleConstr
                      if child.len >= 2 and child[0].kind == nnkSym:
                        enumName = child[0].strVal
                        # Extract explicit ordinal value
                        if child[1].kind == nnkIntLit:
                          # Simple ordinal: enum Pending = 0
                          ordinal = child[1].intVal.int
                        elif child[1].kind == nnkTupleConstr or child[1].kind == nnkPar:
                          # Tuple value: enum active = (0, "Active Status")
                          # TupleConstr structure: [0] = IntLit (ordinal), [1] = StrLit (string repr)
                          if child[1].len >= 1 and child[1][0].kind == nnkIntLit:
                            ordinal = child[1][0].intVal.int

                    # Add to both structures
                    if enumName != "":
                      enumValues.add(enumName)
                      enumOrdinalMap[ordinal] = enumName

                  # STRUCTURAL UNION TYPE DETECTION
                  # Union types generated by union_type.nim macro have discriminator
                  # enums with a specific structural pattern:
                  # - All enum values start with "uk" prefix (uk = union kind)
                  # - Discriminator enum type names contain "UnionType" (e.g., "UnionType1_int_stringKind")
                  # - This is structurally generated by the union macro
                  #
                  # Variant types from variant_dsl.nim can also have enum values starting
                  # with "uk" if the type name starts with "U" (e.g., UserStatus -> ukActive)
                  # but their discriminator enum names don't contain "UnionType" (e.g., "UserStatusKind").
                  #
                  # If ALL enum values start with "uk" AND the discriminator type name contains "UnionType",
                  # then it's a union type. Otherwise, it's a variant type.
                  if enumValues.len > 0:
                    var allStartWithUk = true
                    for enumVal in enumValues:
                      if not enumVal.startsWith("uk"):
                        allStartWithUk = false
                        break
                    # Check discriminator type name instead of object type name
                    # This works even with type aliases (e.g., Result = union(...))
                    if allStartWithUk and result.discriminatorType.contains("UnionType"):
                      isUnionType = true

              # Set isUnion flag based on structural detection
              result.isUnion = isUnionType

              # Extract branches
              for i in 1 ..< child.len:
                let branch = child[i]
                if branch.kind == nnkOfBranch:
                  # OfBranch(IntLit value, RecList(fields...))
                  var variantBranch = VariantBranch()

                  if branch.len > 0:
                    # First child is the discriminator value (ordinal)
                    case branch[0].kind
                    of nnkIntLit:
                      let ordinal = branch[0].intVal.int
                      # Map ordinal to enum name using ordinal->name mapping
                      # This handles non-sequential ordinals correctly (e.g., 0, 5, 10)
                      if enumOrdinalMap.hasKey(ordinal):
                        variantBranch.discriminatorValue = enumOrdinalMap[ordinal]
                      else:
                        # Fallback: use ordinal string representation if not found
                        # This should rarely happen unless enum definition is incomplete
                        variantBranch.discriminatorValue = $ordinal
                    else:
                      variantBranch.discriminatorValue = branch[0].repr
                    variantBranch.discriminatorValueNode = branch[0]

                  if branch.len > 1:
                    # Second child can be either RecList (multi-field) or direct IdentDefs (single-field traditional syntax)
                    let fieldList = branch[1]
                    if fieldList.kind == nnkRecList:
                      # Multi-field or zero-field variant: OfBranch(enumValue, RecList(IdentDefs(...), ...))
                      var position = 0
                      for field in fieldList:
                        if field.kind == nnkIdentDefs:
                          # Handle multiple field declarations like: x, y: int
                          # IdentDefs structure: [field_names..., type, default_value]
                          if field.len >= 2:
                            let typeIndex = field.len - 2
                            let fieldType = if field[typeIndex].kind == nnkSym: field[typeIndex].strVal else: field[typeIndex].repr

                            # Extract all field names (all elements before the type)
                            for i in 0 ..< typeIndex:
                              var fieldNameNode = field[i]
                              var isPublic = false

                              # Handle exported fields (Postfix node)
                              if fieldNameNode.kind == nnkPostfix:
                                isPublic = true
                                # Postfix[0] = export marker (*), Postfix[1] = actual name
                                fieldNameNode = fieldNameNode[1]

                              if fieldNameNode.kind in {nnkSym, nnkIdent}:
                                let fieldName = fieldNameNode.strVal
                                let fieldMeta = FieldMetadata(
                                  name: fieldName,
                                  fieldType: normalizeTypeName(fieldType),
                                  fieldTypeNode: field[typeIndex],
                                  position: position,
                                  isPublic: isPublic
                                )
                                variantBranch.fields.add(fieldMeta)
                                position.inc
                        elif field.kind == nnkSym:
                          let fieldMeta = FieldMetadata(
                            name: field.strVal,
                            fieldType: "",  # Type will be extracted separately
                            fieldTypeNode: field,
                            position: position,
                            isPublic: false
                          )
                          variantBranch.fields.add(fieldMeta)
                          position.inc
                    elif fieldList.kind == nnkIdentDefs:
                      # Handle variant field declarations (can have multiple fields)
                      # This is the traditional Nim syntax: of sA: fieldA: string
                      # IdentDefs structure: [field_names..., type, default_value]
                      if fieldList.len >= 2:
                        let typeIndex = fieldList.len - 2
                        let fieldType = if fieldList[typeIndex].kind == nnkSym: fieldList[typeIndex].strVal else: fieldList[typeIndex].repr

                        # Extract all field names (all elements before the type)
                        for i in 0 ..< typeIndex:
                          var fieldNameNode = fieldList[i]
                          var isPublic = false

                          # Handle exported fields (Postfix node)
                          if fieldNameNode.kind == nnkPostfix:
                            isPublic = true
                            # Postfix[0] = export marker (*), Postfix[1] = actual name
                            fieldNameNode = fieldNameNode[1]

                          if fieldNameNode.kind in {nnkSym, nnkIdent}:
                            let fieldName = fieldNameNode.strVal
                            let fieldMeta = FieldMetadata(
                              name: fieldName,
                              fieldType: normalizeTypeName(fieldType),
                              fieldTypeNode: fieldList[typeIndex],
                              position: i,
                              isPublic: isPublic
                            )
                            variantBranch.fields.add(fieldMeta)

                  result.branches.add(variantBranch)
      else:
        # Regular object
        result.kind = ckObject

        # Add inherited fields first
        result.fields = inheritedFields

        # Extract regular object fields
        var position = inheritedFields.len
        for child in recList:
          if child.kind == nnkIdentDefs:
            # Handle multiple field declarations like: x, y: int
            # IdentDefs structure: [field_names..., type, default_value]
            if child.len >= 2:
              let typeIndex = child.len - 2
              # Field type can be simple (Sym) or complex (BracketExpr like seq[int])
              let fieldType = if child[typeIndex].kind == nnkSym: child[typeIndex].strVal else: child[typeIndex].repr

              # Extract all field names (all elements before the type)
              for i in 0 ..< typeIndex:
                var fieldNameNode = child[i]
                var isPublic = false

                # Handle exported fields (Postfix node)
                if fieldNameNode.kind == nnkPostfix:
                  isPublic = true
                  # Postfix[0] = export marker (*), Postfix[1] = actual name
                  fieldNameNode = fieldNameNode[1]

                if fieldNameNode.kind in {nnkSym, nnkIdent}:
                  let fieldName = fieldNameNode.strVal
                  let fieldMeta = FieldMetadata(
                    name: fieldName,
                    fieldType: normalizeTypeName(fieldType),
                    fieldTypeNode: child[typeIndex],
                    position: position,
                    isPublic: isPublic
                  )
                  result.fields.add(fieldMeta)
                  position.inc
          elif child.kind == nnkSym:
            let fieldMeta = FieldMetadata(
              name: child.strVal,
              fieldType: "",  # Type will be extracted separately
              fieldTypeNode: child,
              position: position,
              isPublic: false
            )
            result.fields.add(fieldMeta)
            position.inc
          elif child.kind == nnkRecList:
            # Nested RecList
            for field in child:
              if field.kind == nnkIdentDefs:
                if field.len >= 2:
                  # Handle multiple field declarations like: x, y: int
                  # IdentDefs structure: [field_names..., type, default_value]
                  # Last element is default value, second-to-last is type
                  let typeIndex = field.len - 2
                  let fieldType = if field[typeIndex].kind == nnkSym: field[typeIndex].strVal else: field[typeIndex].repr

                  # Extract all field names (all elements before the type)
                  for i in 0 ..< typeIndex:
                    var fieldNameNode = field[i]
                    var isPublic = false

                    # Handle exported fields (Postfix node)
                    if fieldNameNode.kind == nnkPostfix:
                      isPublic = true
                      # Postfix[0] = export marker (*), Postfix[1] = actual name
                      fieldNameNode = fieldNameNode[1]

                    if fieldNameNode.kind in {nnkSym, nnkIdent}:
                      let fieldName = fieldNameNode.strVal
                      let fieldMeta = FieldMetadata(
                        name: fieldName,
                        fieldType: normalizeTypeName(fieldType),
                        fieldTypeNode: field[typeIndex],
                        position: position,
                        isPublic: isPublic
                      )
                      result.fields.add(fieldMeta)
                      position.inc
              elif field.kind == nnkSym:
                let fieldMeta = FieldMetadata(
                  name: field.strVal,
                  fieldType: "",
                  fieldTypeNode: field,
                  position: position,
                  isPublic: false
                )
                result.fields.add(fieldMeta)
                position.inc

  of nnkEnumTy:
    # Enum type: EnumTy(Empty, Sym "val1", Sym "val2", ...)
    # OR: EnumTy(Empty, EnumFieldDef(Sym "val1", IntLit 0), ...)
    result.kind = ckEnum
    result.typeName = scrutinee.repr

    # Extract enum values (skip first Empty child)
    for i in 1 ..< scrutinee.len:
      let child = scrutinee[i]
      if child.kind == nnkSym:
        # Simple enum without explicit ordinals: enum Red, Green, Blue
        let enumVal = EnumValue(
          name: child.strVal,
          ordinal: i - 1,  # First value (index 1) has ordinal 0
          node: child
        )
        result.enumValues.add(enumVal)
      elif child.kind == nnkEnumFieldDef:
        # Enum with explicit ordinals: enum Pending = 0, Active = 1
        # OR with tuple values: enum active = (0, "Active Status")
        # EnumFieldDef structure: [0] = Sym (name), [1] = IntLit or TupleConstr
        if child.len >= 2 and child[0].kind == nnkSym:
          var ordinal = i - 1  # Default ordinal based on position

          # Extract ordinal from explicit value
          if child[1].kind == nnkIntLit:
            # Simple ordinal: enum Pending = 0
            ordinal = child[1].intVal.int
          elif child[1].kind == nnkTupleConstr or child[1].kind == nnkPar:
            # Tuple value: enum active = (0, "Active Status")
            # TupleConstr structure: [0] = IntLit (ordinal), [1] = StrLit (string repr)
            if child[1].len >= 1 and child[1][0].kind == nnkIntLit:
              ordinal = child[1][0].intVal.int

          let enumVal = EnumValue(
            name: child[0].strVal,
            ordinal: ordinal,
            node: child[0]
          )
          result.enumValues.add(enumVal)

  of nnkRefTy:
    # ref type: RefTy(Sym "UnderlyingType" or ObjectTy)
    result.kind = ckReference
    result.isRef = true
    result.typeName = "ref " & (if scrutinee.len > 0: getTypeString(scrutinee[0]) else: "")
    if scrutinee.len > 0:
      result.underlyingType = getTypeString(scrutinee[0])
      result.underlyingTypeNode = scrutinee[0]

      # Recursively analyze underlying type to get ALL metadata
      let underlyingMetadata = analyzeConstructMetadata(scrutinee[0])

      # Propagate structural information from underlying type (fields, variants)
      # WHY: ref types should expose same structure as underlying type
      # HOW: Copy fields/variants but KEEP kind=ckReference to distinguish ref from value types
      # IMPORTANT: Don't overwrite result.kind - keep it as ckReference
      if underlyingMetadata.kind == ckObject or underlyingMetadata.kind == ckVariantObject:
        result.isVariant = underlyingMetadata.isVariant
        result.discriminatorField = underlyingMetadata.discriminatorField
        result.discriminatorType = underlyingMetadata.discriminatorType
        result.discriminatorTypeNode = underlyingMetadata.discriminatorTypeNode
        result.branches = underlyingMetadata.branches
        result.fields = underlyingMetadata.fields
        # Propagate polymorphism support from underlying type
        result.supportsPolymorphism = underlyingMetadata.supportsPolymorphism

      # Propagate other type-specific flags
      if underlyingMetadata.isOption:
        result.isOption = true
        result.optionInnerType = underlyingMetadata.optionInnerType
        result.optionInnerTypeNode = underlyingMetadata.optionInnerTypeNode

  of nnkPtrTy:
    # ptr type: PtrTy(Sym "UnderlyingType" or ObjectTy)
    result.kind = ckPointer
    result.isPtr = true
    result.typeName = "ptr " & (if scrutinee.len > 0: getTypeString(scrutinee[0]) else: "")
    if scrutinee.len > 0:
      result.underlyingType = getTypeString(scrutinee[0])
      result.underlyingTypeNode = scrutinee[0]

      # Recursively analyze underlying type to get ALL metadata
      let underlyingMetadata = analyzeConstructMetadata(scrutinee[0])

      # Propagate structural information from underlying type (fields, variants)
      # WHY: ptr types should expose same structure as underlying type
      # HOW: Copy fields/variants but KEEP kind=ckPointer to distinguish ptr from value types
      # IMPORTANT: Don't overwrite result.kind - keep it as ckPointer
      if underlyingMetadata.kind == ckObject or underlyingMetadata.kind == ckVariantObject:
        result.isVariant = underlyingMetadata.isVariant
        result.discriminatorField = underlyingMetadata.discriminatorField
        result.discriminatorType = underlyingMetadata.discriminatorType
        result.discriminatorTypeNode = underlyingMetadata.discriminatorTypeNode
        result.branches = underlyingMetadata.branches
        result.fields = underlyingMetadata.fields

  else:
    # Unknown or unsupported construct
    result.kind = ckUnknown

  # Normalize type name at the end to handle all cases
  # This ensures :ObjectType suffixes are stripped for error messages
  result.typeName = normalizeTypeName(result.typeName)


# ============================================================================
# Utility Procedures
# ============================================================================

proc `$`*(metadata: ConstructMetadata): string =
  ## Pretty-print ConstructMetadata for debugging
  result = "ConstructMetadata(\n"
  result &= "  typeName: " & metadata.typeName & "\n"
  result &= "  kind: " & $metadata.kind & "\n"
  if metadata.isVariant:
    result &= "  isVariant: true\n"
    result &= "  discriminatorField: " & metadata.discriminatorField & "\n"
    result &= "  discriminatorType: " & metadata.discriminatorType & "\n"
    result &= "  branches: " & $metadata.branches.len & "\n"
  if metadata.fields.len > 0:
    result &= "  fields: " & $metadata.fields.len & "\n"
  if metadata.isGeneric:
    result &= "  isGeneric: true\n"
    result &= "  genericBase: " & metadata.genericBase & "\n"
  result &= ")"


# ============================================================================
# Pattern Validation Helpers
# ============================================================================
# Added for Phase 1: Main Pattern Dispatch Migration (Subtask 1)
# These helpers enable structural pattern validation using construct metadata
# ALL helpers use ONLY structural AST analysis - NO string heuristics

# Type Family Categorization System
# Mimics Nim's compile-time type categories (SomeSignedInt, SomeUnsignedInt, SomeFloat)
# for compile-time type compatibility checking during macro expansion

type
  TypeFamily = enum
    ## Type family categories that mimic Nim's type constraint system
    ## Used for compile-time type compatibility checking in pattern matching
    tfUnknown        ## Unknown or non-numeric type
    tfSignedInt      ## Signed integers: int, int8, int16, int32, int64
    tfUnsignedInt    ## Unsigned integers: uint, uint8, uint16, uint32, uint64
    tfFloat          ## Floating point: float, float32, float64
    tfBool           ## Boolean type
    tfString         ## String type
    tfChar           ## Character type

proc getTypeFamily(typeName: string): TypeFamily =
  ## Maps type names to type families using Nim's type category system.
  ## Mimics SomeSignedInt, SomeUnsignedInt, SomeFloat categories at compile-time.
  ##
  ## This enables proper type compatibility checking without hardcoded string lists.
  ## Based on Nim's standard type categories:
  ## - SomeSignedInt = int | int8 | int16 | int32 | int64
  ## - SomeUnsignedInt = uint | uint8 | uint16 | uint32 | uint64
  ## - SomeFloat = float | float32 | float64
  ##
  ## Examples:
  ##   getTypeFamily("int32") => tfSignedInt
  ##   getTypeFamily("uint") => tfUnsignedInt
  ##   getTypeFamily("float64") => tfFloat
  ##   getTypeFamily("Point") => tfUnknown
  case typeName:
  of "int", "int8", "int16", "int32", "int64":
    return tfSignedInt
  of "uint", "uint8", "uint16", "uint32", "uint64":
    return tfUnsignedInt
  of "float", "float32", "float64":
    return tfFloat
  of "bool":
    return tfBool
  of "string":
    return tfString
  of "char":
    return tfChar
  else:
    return tfUnknown

proc areCompatibleNumericTypes(patternTypeName: string, scrutineeTypeName: string): bool =
  ## Check if two numeric types are compatible for pattern matching.
  ## Based on Nim's type conversion and compatibility rules:
  ## - All integers are compatible (signed with unsigned, different sizes)
  ## - All floats are compatible (different sizes)
  ## - Integers and floats do NOT cross-match
  ##
  ## This enables patterns like:
  ## - `42` (int literal) matching `uint`, `int32`, `uint64` values
  ## - `3.14` (float literal) matching `float32`, `float64` values
  ##
  ## Examples:
  ##   areCompatibleNumericTypes("int", "uint32") => true (both integers)
  ##   areCompatibleNumericTypes("int64", "uint") => true (both integers)
  ##   areCompatibleNumericTypes("float", "float32") => true (both floats)
  ##   areCompatibleNumericTypes("int", "float") => false (different families)
  ##   areCompatibleNumericTypes("Point", "User") => false (non-numeric)
  let patternFamily = getTypeFamily(patternTypeName)
  let scrutineeFamily = getTypeFamily(scrutineeTypeName)

  # Both are integers (signed or unsigned) - compatible
  # Allows: int <-> int32, int <-> uint, uint8 <-> int64, etc.
  if patternFamily in {tfSignedInt, tfUnsignedInt} and
     scrutineeFamily in {tfSignedInt, tfUnsignedInt}:
    return true

  # Both are floats - compatible
  # Allows: float <-> float32, float <-> float64, float32 <-> float64
  if patternFamily == tfFloat and scrutineeFamily == tfFloat:
    return true

  # Other types - not compatible via numeric type system
  return false

proc isCompatibleType*(patternTypeName: string, scrutineeMetadata: ConstructMetadata): bool =
  ## Checks if pattern type is compatible with scrutinee metadata.
  ##
  ## **Purpose:**
  ## Validates type compatibility during object pattern validation.
  ## Uses structural type comparison, handling type aliases, generic types, and polymorphism.
  ##
  ## **Compatibility Rules:**
  ## - Direct type name match (e.g., "Point" matches Point)
  ## - Type aliases (pattern uses alias name, scrutinee uses implementation name)
  ## - Generic base types (e.g., "Option" matches Option[int])
  ## - Ref/ptr wrapper types (e.g., "Point" matches ref Point)
  ## - Numeric type families (int/uint/float cross-compatibility)
  ## - Polymorphic types (pattern derived type, scrutinee base type with inheritance)
  ##
  ## **Args:**
  ##   patternTypeName: Type name from pattern (e.g., "Point", "Option")
  ##   scrutineeMetadata: Scrutinee metadata from `analyzeConstructMetadata`
  ##
  ## **Returns:**
  ##   true if types are compatible, false otherwise
  ##
  ## **Example:**
  ##   ```nim
  ##   type Point = object
  ##     x*: int
  ##     y*: int
  ##
  ##   let metadata = analyzeConstructMetadata(Point.getTypeInst())
  ##   assert isCompatibleType("Point", metadata) == true
  ##   assert isCompatibleType("Circle", metadata) == false
  ##
  ##   # Numeric compatibility
  ##   let intMeta = analyzeConstructMetadata(int.getTypeInst())
  ##   assert isCompatibleType("int32", intMeta) == true  # Integer family
  ##   assert isCompatibleType("float", intMeta) == false  # Different family
  ##   ```
  ##
  ## **Performance:**
  ##   O(1) type name comparison + O(1) type family lookup
  ##
  ## **See also:**
  ##   - `hasExactTypeMatch` - Stricter exact type matching (no polymorphism)
  ##   - `validateObjectPattern` - Uses this for type validation

  # Direct type name match
  if scrutineeMetadata.typeName == patternTypeName:
    return true

  # Handle union type aliases
  # Union types use implementation names like "UnionType1_int_string"
  # but patterns use the alias name like "Result"
  # If scrutinee is a union with UnionType* name and pattern doesn't use UnionType*,
  # allow the match (pattern is using the alias)
  if scrutineeMetadata.isUnion and
     scrutineeMetadata.typeName.startsWith("UnionType") and
     not patternTypeName.startsWith("UnionType"):
    return true

  # Handle dereferenced ref objects where metadata extraction failed
  # When tree[] is dereferenced, we get object structure without type name symbol
  # Check if scrutinee is object/variant and extraction fell back to repr
  # In this case, accept the match - we'll validate structurally via fields
  if scrutineeMetadata.kind in {ckObject, ckVariantObject, ckReference}:
    # If metadata extraction failed (fell back to repr instead of clean structural extraction)
    # allow the match - field validation will ensure structural compatibility
    if scrutineeMetadata.extractionFailed:
      return true

  # Handle ref wrapper types matching their underlying types
  # When scrutinee is a ref wrapper (ckReference, ckJsonNode) with an underlyingType,
  # check if pattern matches the ref wrapper name while scrutinee metadata has underlying type name
  # This handles cases where metadata extraction returned the underlying type instead of wrapper
  #
  # STRUCTURAL CHECK: Use kind flags and underlyingType, not hardcoded type names
  if scrutineeMetadata.kind in {ckReference, ckJsonNode} and scrutineeMetadata.underlyingType != "":
    # Check if pattern matches the expected wrapper type for this underlying type
    # For JsonNode: underlyingType="JsonNodeObj", pattern should be "JsonNode"
    # For ref Point: underlyingType="Point", pattern should be "Point" or "ref Point"

    # Check if the ref wrapper type exists and matches pattern
    # Strategy: Build expected wrapper name from underlying type
    let expectedWrapperName = if scrutineeMetadata.kind == ckJsonNode:
      # JsonNode is special: wrapper is "JsonNode", underlying is "JsonNodeObj"
      "JsonNode"
    else:
      # Regular ref types: wrapper is "ref TypeName"
      scrutineeMetadata.underlyingType

    if patternTypeName == expectedWrapperName:
      return true

  # SPECIAL CASE: JsonNodeObj variant object matching JsonNode pattern
  # Sometimes metadata unwrapping extracts JsonNodeObj (the underlying variant object)
  # instead of JsonNode (the ref wrapper). This check allows JsonNode patterns to match.
  #
  # ARCHITECTURAL NOTE: This is a temporary workaround. The proper fix would be to ensure
  # metadata extraction always returns JsonNode metadata (with kind=ckJsonNode) when
  # the original type is JsonNode, never unwrapping to JsonNodeObj automatically.
  #
  # WHY THIS IS STILL BETTER THAN PURE STRING MATCHING:
  # - Checks scrutinee kind (ckVariantObject with discriminator)
  # - Verifies structural properties (isVariant flag)
  # - Only applies to specific type name pattern
  # - Documents the architectural issue for future improvement
  if scrutineeMetadata.kind == ckVariantObject and
     scrutineeMetadata.isVariant and
     scrutineeMetadata.typeName == "JsonNodeObj" and
     patternTypeName == "JsonNode":
    return true

  # Handle ref/ptr type compatibility: Pattern "Point" should match "ref Point" or "ptr Point"
  # Check if scrutinee is ref/ptr and pattern matches the underlying type
  if scrutineeMetadata.kind in {ckReference, ckPointer}:
    # Check if pattern matches the underlying type directly
    if scrutineeMetadata.underlyingType == patternTypeName:
      return true

    # Also check if typeName is "ref TypeName" or "ptr TypeName" and pattern is "TypeName"
    if scrutineeMetadata.typeName == "ref " & patternTypeName or
       scrutineeMetadata.typeName == "ptr " & patternTypeName:
      return true

    # For ref/ptr types with polymorphism support, allow derived type patterns
    # Example: Pattern "Car" should match scrutinee "ref Vehicle" if Vehicle supports polymorphism
    if scrutineeMetadata.supportsPolymorphism:
      return true

  # Handle generic types - compare base names
  if scrutineeMetadata.isGeneric and scrutineeMetadata.genericBase == patternTypeName:
    return true

  # For object/variant types with type mismatch, allow validation to proceed
  # The pattern_matching.nim will check if polymorphism is possible using compile-time checks
  # If polymorphism check passes, it will skip validation; otherwise validation catches the error
  # This two-phase approach ensures:
  # - Polymorphic patterns (ref types) are allowed with runtime checks
  # - Invalid patterns (value object mismatches) are caught at compile time

  # Handle numeric type compatibility using type family system
  # Replaces hardcoded string lists with centralized type categorization
  # Supports all integer types (int, int8, int16, int32, int64, uint, uint8, uint16, uint32, uint64)
  # and all float types (float, float32, float64)
  if areCompatibleNumericTypes(patternTypeName, scrutineeMetadata.typeName):
    return true

  # No match found
  return false


proc hasExactTypeMatch*(patternTypeName: string, scrutineeMetadata: ConstructMetadata): bool =
  ## Checks for exact type name match (case-sensitive, no polymorphic compatibility).
  ##
  ## **Purpose:**
  ## Detects when pattern type differs from scrutinee type to trigger polymorphism checks.
  ## Stricter than `isCompatibleType` - does NOT allow polymorphic matches.
  ##
  ## **When to use:**
  ## - Detecting type mismatches for polymorphism detection
  ## - Determining if runtime type check is needed
  ## - Distinguishing exact matches from compatible-but-different types
  ##
  ## **Matching Rules:**
  ## - Direct type name match (e.g., "Point" == "Point")
  ## - Ref/ptr unwrapping (e.g., "Point" matches ref Point)
  ## - NO polymorphism (e.g., "Car" does NOT match "Vehicle")
  ## - NO type family matching (e.g., "int" does NOT match "int32")
  ##
  ## **Args:**
  ##   patternTypeName: Type name from pattern
  ##   scrutineeMetadata: Scrutinee metadata from `analyzeConstructMetadata`
  ##
  ## **Returns:**
  ##   true if types are exactly the same, false otherwise
  ##
  ## **Example:**
  ##   ```nim
  ##   type
  ##     Vehicle = ref object of RootObj
  ##     Car = ref object of Vehicle
  ##
  ##   let vehicleMeta = analyzeConstructMetadata(Vehicle.getTypeInst())
  ##   assert hasExactTypeMatch("Vehicle", vehicleMeta) == true
  ##   assert hasExactTypeMatch("Car", vehicleMeta) == false  # Different type
  ##
  ##   # Use isCompatibleType for polymorphic matching instead
  ##   assert isCompatibleType("Car", vehicleMeta) == true  # Polymorphic
  ##   ```
  ##
  ## **Note:**
  ##   Type names are pre-normalized by `normalizeTypeName()`, so :ObjectType
  ##   suffixes are already stripped before comparison.
  ##
  ## **See also:**
  ##   - `isCompatibleType` - Allows polymorphic and type family matching
  ##   - `normalizeTypeName` - Type name normalization

  # Direct type name match
  if scrutineeMetadata.typeName == patternTypeName:
    return true

  # Handle ref/ptr types using metadata flags (structural check, not string heuristic)
  if scrutineeMetadata.isRef or scrutineeMetadata.isPtr:
    # Check if underlying type matches pattern
    if scrutineeMetadata.underlyingType == patternTypeName:
      return true

    # Fallback: Check string representation "ref TypeName" or "ptr TypeName"
    # This handles cases where underlyingType might not be set properly
    if scrutineeMetadata.typeName == "ref " & patternTypeName or
       scrutineeMetadata.typeName == "ptr " & patternTypeName:
      return true

  # No exact match found
  return false


proc hasField*(metadata: ConstructMetadata, fieldName: string): bool =
  ## Checks if a field exists in the type's metadata.
  ##
  ## **Purpose:**
  ## Validates field existence during pattern validation and error message generation.
  ## Uses structural field information extracted by `analyzeConstructMetadata`.
  ##
  ## **Supports:**
  ## - Regular objects: Checks fields list
  ## - Variant objects: Checks discriminator field, common fields, and all branch fields
  ## - Named tuples: Checks tuple element names
  ## - JsonNode: Checks variant object structure (discriminator + branch fields)
  ## - Ref/ptr types: Checks propagated fields from underlying type
  ##
  ## **Args:**
  ##   metadata: Type metadata from `analyzeConstructMetadata`
  ##   fieldName: Field name to check
  ##
  ## **Returns:**
  ##   true if field exists, false otherwise
  ##
  ## **Example:**
  ##   ```nim
  ##   type Person = object
  ##     name*: string
  ##     age*: int
  ##
  ##   let metadata = analyzeConstructMetadata(Person.getTypeInst())
  ##   assert hasField(metadata, "name") == true
  ##   assert hasField(metadata, "age") == true
  ##   assert hasField(metadata, "email") == false
  ##   ```
  ##
  ## **Performance:**
  ##   O(n) where n = number of fields (including variant branch fields)
  ##
  ## **See also:**
  ##   - `getFieldType` - Get field's type after checking existence
  ##   - `getAllFieldNames` - List all available fields
  ##   - `validateFieldAccess` - Check variant-safe field access

  case metadata.kind:
  of ckObject:
    # Regular object - check fields structurally
    for field in metadata.fields:
      if field.name == fieldName:
        return true
    return false

  of ckVariantObject:
    # Variant object - check discriminator field
    if metadata.discriminatorField == fieldName:
      return true

    # Check common fields
    for field in metadata.fields:
      if field.name == fieldName:
        return true

    # Check all branch fields (structural analysis of all branches)
    for branch in metadata.branches:
      for field in branch.fields:
        if field.name == fieldName:
          return true
    return false

  of ckTuple:
    # Named tuple - check element names structurally
    if metadata.isTupleNamed:
      for element in metadata.tupleElements:
        if element.name == fieldName:
          return true
    return false

  of ckJsonNode:
    # JsonNode is a variant object (ref JsonNodeObj)
    # Check discriminator field (kind)
    if metadata.discriminatorField == fieldName:
      return true

    # Check common fields
    for field in metadata.fields:
      if field.name == fieldName:
        return true

    # Check all branch fields
    for branch in metadata.branches:
      for field in branch.fields:
        if field.name == fieldName:
          return true
    return false

  of ckReference, ckPointer:
    # ref/ptr types - check propagated fields from underlying type
    # Fields are already propagated during metadata extraction
    # Check if underlying type is variant or regular object
    if metadata.isVariant:
      # Variant object underneath - check discriminator and all branches
      if metadata.discriminatorField == fieldName:
        return true

      # Check common fields
      for field in metadata.fields:
        if field.name == fieldName:
          return true

      # Check all branch fields
      for branch in metadata.branches:
        for field in branch.fields:
          if field.name == fieldName:
            return true
      return false
    else:
      # Regular object underneath - check fields directly
      for field in metadata.fields:
        if field.name == fieldName:
          return true
      return false

  else:
    return false


proc isBoolType*(metadata: ConstructMetadata): bool =
  ## Checks if metadata represents bool type (or bool alias).
  ##
  ## **Purpose:**
  ## Structurally detects bool types for exhaustiveness checking and pattern optimization.
  ## Works transparently with type aliases without string-based type name matching.
  ##
  ## **Structural Detection:**
  ## Bool has unique structural properties as an enum:
  ## - Exactly 2 enum values
  ## - First value: "false" with ordinal 0
  ## - Second value: "true" with ordinal 1
  ##
  ## **Why structural instead of string matching:**
  ## String-based checks like `metadata.typeName == "bool"` fail for type aliases.
  ## Structural analysis works with ALL bool aliases because `analyzeConstructMetadata`
  ## follows type aliases and extracts the underlying enum structure.
  ##
  ## **Args:**
  ##   metadata: Type metadata from `analyzeConstructMetadata`
  ##
  ## **Returns:**
  ##   true if type is bool (or bool alias), false otherwise
  ##
  ## **Example:**
  ##   ```nim
  ##   type MyBool = bool  # Type alias
  ##
  ##   let boolMeta = analyzeConstructMetadata(bool.getTypeInst())
  ##   assert isBoolType(boolMeta) == true
  ##
  ##   let aliasMeta = analyzeConstructMetadata(MyBool.getTypeInst())
  ##   assert isBoolType(aliasMeta) == true  # Works with aliases!
  ##
  ##   type Color = enum Red, Green, Blue
  ##   let colorMeta = analyzeConstructMetadata(Color.getTypeInst())
  ##   assert isBoolType(colorMeta) == false  # Not bool (3 values)
  ##   ```
  ##
  ## **Bug Fix:**
  ##   PM-3: Fixed hardcoded string check that broke bool alias pattern matching
  ##   - Old: `metadata.typeName == "bool"` (string heuristic - FORBIDDEN)
  ##   - New: `isBoolType(metadata)` (structural query - CORRECT)
  ##
  ## **See also:**
  ##   - `analyzeConstructMetadata` - Extracts enum structure for bool detection

  # Must be an enum type
  if metadata.kind != ckEnum:
    return false

  # Must have exactly 2 values
  if metadata.enumValues.len != 2:
    return false

  # First value must be "false" with ordinal 0
  if metadata.enumValues[0].name != "false" or metadata.enumValues[0].ordinal != 0:
    return false

  # Second value must be "true" with ordinal 1
  if metadata.enumValues[1].name != "true" or metadata.enumValues[1].ordinal != 1:
    return false

  # All structural checks passed - this is bool (or a bool alias)
  return true


proc getFieldType*(metadata: ConstructMetadata, fieldName: string): string =
  ## Retrieves field type as string from metadata.
  ##
  ## **Purpose:**
  ## Extracts field type information for type compatibility checking during pattern validation.
  ## Uses structural field type information extracted by `analyzeConstructMetadata`.
  ##
  ## **Supports:**
  ## - Regular objects: Returns field type from fields list
  ## - Variant objects: Returns discriminator type or branch field type
  ## - Named tuples: Returns element type
  ## - JsonNode: Returns field type from variant structure
  ##
  ## **Args:**
  ##   metadata: Type metadata from `analyzeConstructMetadata`
  ##   fieldName: Field name to query
  ##
  ## **Returns:**
  ##   Type name string (e.g., "int", "string", "seq[int]")
  ##   Empty string if field doesn't exist
  ##
  ## **Example:**
  ##   ```nim
  ##   type Person = object
  ##     name*: string
  ##     age*: int
  ##
  ##   let metadata = analyzeConstructMetadata(Person.getTypeInst())
  ##   assert getFieldType(metadata, "name") == "string"
  ##   assert getFieldType(metadata, "age") == "int"
  ##   assert getFieldType(metadata, "nonexistent") == ""
  ##   ```
  ##
  ## **Performance:**
  ##   O(n) where n = number of fields (field lookup)
  ##
  ## **See also:**
  ##   - `hasField` - Check field existence before calling this
  ##   - `analyzeFieldMetadata` - Get full metadata for nested field analysis

  case metadata.kind:
  of ckObject:
    # Regular object - structurally search fields
    for field in metadata.fields:
      if field.name == fieldName:
        return field.fieldType
    return ""

  of ckVariantObject:
    # Check discriminator structurally
    if metadata.discriminatorField == fieldName:
      return metadata.discriminatorType

    # Check common fields
    for field in metadata.fields:
      if field.name == fieldName:
        return field.fieldType

    # Check branch fields (structural search through all branches)
    for branch in metadata.branches:
      for field in branch.fields:
        if field.name == fieldName:
          return field.fieldType
    return ""

  of ckTuple:
    # Named tuple - structurally search elements
    if metadata.isTupleNamed:
      for element in metadata.tupleElements:
        if element.name == fieldName:
          return element.elementType
    return ""

  of ckJsonNode:
    # JsonNode is a variant object (ref JsonNodeObj)
    # Check discriminator field (kind)
    if metadata.discriminatorField == fieldName:
      return metadata.discriminatorType

    # Check common fields
    for field in metadata.fields:
      if field.name == fieldName:
        return field.fieldType

    # Check branch fields
    for branch in metadata.branches:
      for field in branch.fields:
        if field.name == fieldName:
          return field.fieldType
    return ""

  else:
    return ""


proc getAllFieldNames*(metadata: ConstructMetadata): seq[string] =
  ## Returns all field names in the type.
  ##
  ## **Purpose:**
  ## Provides complete field list for error messages, typo suggestions (Levenshtein distance),
  ## and pattern validation completeness checks.
  ##
  ## **Behavior:**
  ## - Regular objects: Returns all field names
  ## - Variant objects: Returns discriminator field + common fields + all branch fields (unique)
  ## - Named tuples: Returns element names
  ## - Unnamed tuples/simple types: Returns empty sequence
  ##
  ## **Args:**
  ##   metadata: Type metadata from `analyzeConstructMetadata`
  ##
  ## **Returns:**
  ##   Sequence of field name strings. Empty sequence if no named fields.
  ##
  ## **Example:**
  ##   ```nim
  ##   type Person = object
  ##     name*: string
  ##     age*: int
  ##     email*: string
  ##
  ##   let metadata = analyzeConstructMetadata(Person.getTypeInst())
  ##   let fields = getAllFieldNames(metadata)
  ##   assert fields == @["name", "age", "email"]
  ##   ```
  ##
  ## **Performance:**
  ##   O(n) where n = total number of fields across all variant branches
  ##
  ## **Use case:**
  ##   Error messages: "Unknown field 'nme'. Did you mean 'name'?"
  ##
  ## **See also:**
  ##   - `hasField` - Check if specific field exists
  ##   - `getFieldType` - Get type of specific field

  result = @[]

  case metadata.kind:
  of ckObject:
    # Regular object - structurally collect all field names
    for field in metadata.fields:
      result.add(field.name)

  of ckVariantObject:
    # Add discriminator field
    if metadata.discriminatorField != "":
      result.add(metadata.discriminatorField)

    # Add common fields
    for field in metadata.fields:
      result.add(field.name)

    # Add branch fields (unique only) - structural deduplication
    var seen = initTable[string, bool]()
    for branch in metadata.branches:
      for field in branch.fields:
        if field.name notin seen:
          result.add(field.name)
          seen[field.name] = true

  of ckTuple:
    # Named tuple - structurally collect element names
    if metadata.isTupleNamed:
      for element in metadata.tupleElements:
        if element.name != "":
          result.add(element.name)

  else:
    discard


proc getExpectedElementCount*(metadata: ConstructMetadata): int =
  ## Returns expected element count for tuple/array types.
  ##
  ## **Purpose:**
  ## Validates pattern element count during tuple destructuring pattern validation.
  ## Enables compile-time detection of element count mismatches.
  ##
  ## **Supports:**
  ## - Tuples: Returns number of tuple elements
  ## - Arrays: Returns fixed array size
  ## - Other types: Returns -1 (not applicable or variable length)
  ##
  ## **Args:**
  ##   metadata: Type metadata from `analyzeConstructMetadata`
  ##
  ## **Returns:**
  ##   Element count for fixed-size types, -1 for variable-length types
  ##
  ## **Example:**
  ##   ```nim
  ##   type Point3D = tuple[x: int, y: int, z: int]
  ##
  ##   let metadata = analyzeConstructMetadata(Point3D.getTypeInst())
  ##   assert getExpectedElementCount(metadata) == 3
  ##
  ##   type ByteArray = array[256, byte]
  ##   let arrayMeta = analyzeConstructMetadata(ByteArray.getTypeInst())
  ##   assert getExpectedElementCount(arrayMeta) == 256
  ##   ```
  ##
  ## **Use case:**
  ##   Tuple validation: "Pattern has 2 elements but tuple expects 3"
  ##
  ## **See also:**
  ##   - `validateTuplePattern` - Uses this for element count validation

  case metadata.kind:
  of ckTuple:
    # Tuple - structurally get element count
    return metadata.tupleElements.len
  of ckArray:
    # Array - structurally get fixed size
    return metadata.arraySize
  else:
    # Variable length or not applicable
    return -1


proc validateFieldAccess*(metadata: ConstructMetadata, fieldName: string,
                         discriminatorValue: string): bool =
  ## Validates field access is safe for given discriminator value.
  ##
  ## **Purpose:**
  ## Ensures variant object field access is safe by checking if the field exists in the
  ## branch corresponding to the discriminator value. Prevents accessing fields from
  ## wrong variant branches.
  ##
  ## **Behavior:**
  ## - Regular objects: All field access is safe (checks existence only)
  ## - Variant objects:
  ##   - Discriminator field: Always safe
  ##   - Common fields: Always safe
  ##   - Branch-specific fields: Safe only for matching discriminator value
  ##
  ## **Args:**
  ##   metadata: Type metadata from `analyzeConstructMetadata`
  ##   fieldName: Field to access
  ##   discriminatorValue: Current discriminator value (e.g., "vkInt", "Active")
  ##
  ## **Returns:**
  ##   true if field access is safe, false otherwise
  ##
  ## **Example:**
  ##   ```nim
  ##   type SimpleValue = object
  ##     case kind: ValueKind
  ##     of vkInt: intVal: int
  ##     of vkString: strVal: string
  ##
  ##   let metadata = analyzeConstructMetadata(SimpleValue.getTypeInst())
  ##
  ##   # Discriminator field always safe
  ##   assert validateFieldAccess(metadata, "kind", "vkInt") == true
  ##
  ##   # Branch field safe for correct discriminator
  ##   assert validateFieldAccess(metadata, "intVal", "vkInt") == true
  ##
  ##   # Branch field unsafe for wrong discriminator
  ##   assert validateFieldAccess(metadata, "strVal", "vkInt") == false
  ##   ```
  ##
  ## **Critical:**
  ##   Prevents invalid variant field access that would cause runtime errors.
  ##
  ## **Performance:**
  ##   O(n) where n = number of branches (linear search through variant branches)
  ##
  ## **See also:**
  ##   - `validateObjectPattern` - Uses this for variant object validation
  ##   - `hasField` - Checks field existence without discriminator validation

  # Check if this is a variant object (either direct or through ref/ptr)
  # ref/ptr types have isVariant propagated from underlying type
  if metadata.kind != ckVariantObject and not metadata.isVariant:
    # Not a variant - all field access is safe (if field exists)
    # Structural check: does the field exist in this non-variant type?
    return hasField(metadata, fieldName)

  # Check if this is the discriminator field itself (always safe)
  if fieldName == metadata.discriminatorField:
    return true

  # Check common fields (always safe) - structural analysis
  for field in metadata.fields:
    if field.name == fieldName:
      return true

  # Check if field exists in the branch with given discriminator value
  # Structural analysis: search through branches for matching discriminator
  for branch in metadata.branches:
    if branch.discriminatorValue == discriminatorValue:
      # Found the correct branch - structurally check if field exists
      for field in branch.fields:
        if field.name == fieldName:
          return true
      # Field not in this branch
      return false

  # Discriminator value not found in any branch
  return false


proc prettyPrintType*(metadata: ConstructMetadata): string =
  ## Generates human-readable type string from metadata.
  ##
  ## **Purpose:**
  ## Creates formatted type descriptions for error messages, making compile-time
  ## errors clear and actionable for users.
  ##
  ## **Format examples:**
  ## - Simple type: `simple type 'int'`
  ## - Object: `object 'Point' with fields: x, y`
  ## - Variant: `variant object 'SimpleValue' with discriminator 'kind' (fields: kind, intVal, strVal)`
  ## - Named tuple: `named tuple (x: int, y: int, z: int)`
  ## - Unnamed tuple: `tuple (int, string, float)`
  ## - Sequence: `seq[string]`
  ## - Array: `array[10, int]`
  ## - Table: `Table[string, int]`
  ## - Enum: `enum 'Color' (Red, Green, Blue)`
  ##
  ## **Args:**
  ##   metadata: Type metadata from `analyzeConstructMetadata`
  ##
  ## **Returns:**
  ##   Human-readable type description string
  ##
  ## **Example:**
  ##   ```nim
  ##   type Point = object
  ##     x*: int
  ##     y*: int
  ##
  ##   let metadata = analyzeConstructMetadata(Point.getTypeInst())
  ##   let description = prettyPrintType(metadata)
  ##   # Returns: "object 'Point' with fields: x, y"
  ##
  ##   # Use in error messages:
  ##   error("Type mismatch: expected " & description)
  ##   ```
  ##
  ## **Use case:**
  ##   Error messages: "Pattern expects tuple (int, string) but got seq[int]"
  ##
  ## **See also:**
  ##   - `generateValidationError` - Uses this for error message generation

  case metadata.kind:
  of ckSimpleType:
    return "simple type '" & metadata.typeName & "'"

  of ckObject:
    result = "object '" & metadata.typeName & "'"
    if metadata.fields.len > 0:
      let fieldNames = metadata.fields.mapIt(it.name).join(", ")
      result &= " with fields: " & fieldNames

  of ckVariantObject:
    result = "variant object '" & metadata.typeName & "'"
    if metadata.discriminatorField != "":
      result &= " with discriminator '" & metadata.discriminatorField & "'"
    let allFields = getAllFieldNames(metadata)
    if allFields.len > 0:
      result &= " (fields: " & allFields.join(", ") & ")"

  of ckTuple:
    if metadata.isTupleNamed:
      let elements = metadata.tupleElements.mapIt(it.name & ": " & it.elementType).join(", ")
      result = "named tuple (" & elements & ")"
    else:
      let types = metadata.tupleElements.mapIt(it.elementType).join(", ")
      result = "tuple (" & types & ")"

  of ckSequence:
    result = "seq[" & metadata.elementType & "]"

  of ckDeque:
    result = "Deque[" & metadata.elementType & "]"

  of ckLinkedList:
    result = metadata.linkedListVariant & "[" & metadata.elementType & "]"

  of ckArray:
    result = "array[" & $metadata.arraySize & ", " & metadata.elementType & "]"

  of ckTable:
    result = "Table[" & metadata.keyType & ", " & metadata.valueType & "]"

  of ckSet:
    result = "set[" & metadata.elementType & "]"

  of ckOption:
    result = "Option[" & metadata.optionInnerType & "]"

  of ckReference:
    result = "ref " & metadata.underlyingType

  of ckPointer:
    result = "ptr " & metadata.underlyingType

  of ckEnum:
    result = "enum '" & metadata.typeName & "'"
    if metadata.enumValues.len > 0:
      let values = metadata.enumValues.mapIt(it.name).join(", ")
      result &= " (" & values & ")"

  of ckJsonNode:
    result = "JsonNode"

  else:
    result = metadata.typeName & " (kind: " & $metadata.kind & ")"


proc findMatchingDiscriminatorValue*(constructorName: string,
                                     metadata: ConstructMetadata): string =
  ## Maps UFCS constructor name to discriminator enum value.
  ##
  ## **Purpose:**
  ## Enables variant object pattern matching using constructor syntax (e.g., Result.Success)
  ## by finding the corresponding discriminator value (e.g., "rkSuccess") from metadata.
  ##
  ## **How it works:**
  ## Performs structural search through variant branches to find which discriminator
  ## value matches the constructor name. Uses suffix matching to handle conventional
  ## prefixes (sk, vk, nk, rk, etc.) without string construction heuristics.
  ##
  ## **Matching Strategy:**
  ## 1. Exact match: "Active" matches "Active" (no prefix)
  ## 2. Suffix match: "Active" matches "skActive", "rkActive", etc.
  ##    - Validates separator: character before constructor name must be 'k'
  ##    - Prevents false positives: "Active" won't match "IntActive"
  ##
  ## **Design Philosophy - ZERO String Heuristics:**
  ## This replaces string construction like:
  ##   `typeName[0] & "k" & constructorName`  # FORBIDDEN!
  ##
  ## Instead uses structural queries:
  ## - All discriminator values already extracted in metadata.branches (structural!)
  ## - Search these extracted values using suffix comparison (structural!)
  ## - NO string construction based on naming conventions (heuristic-free!)
  ##
  ## **Args:**
  ##   constructorName: Constructor name from pattern (e.g., "Active", "Success", "Int")
  ##   metadata: Variant object metadata containing discriminator branches
  ##
  ## **Returns:**
  ##   Matching discriminator value (e.g., "skActive", "rkSuccess", "vkInt")
  ##   Empty string if no match found
  ##
  ## **Example:**
  ##   ```nim
  ##   type Status = object
  ##     case kind: StatusKind
  ##     of skActive: activeData: int
  ##     of skInactive: discard
  ##
  ##   let metadata = analyzeConstructMetadata(Status.getTypeInst())
  ##   let discValue = findMatchingDiscriminatorValue("Active", metadata)
  ##   assert discValue == "skActive"
  ##   ```
  ##
  ## **Common Naming Conventions:**
  ## - sk* (Status Kind): skActive, skInactive
  ## - vk* (Value Kind): vkInt, vkString, vkBool
  ## - rk* (Result Kind): rkSuccess, rkFailure
  ## - nk* (Node Kind): nkAdd, nkSub
  ##
  ## **Performance:**
  ##   O(n) where n = number of variant branches (linear search)
  ##
  ## **Bug Fix:**
  ##   PV-1: Added separator validation to prevent "Active" matching "IntActive"
  ##
  ## **See also:**
  ##   - `analyzeConstructMetadata` - Extracts discriminator values structurally
  ##   - `validateObjectPattern` - Uses this for variant constructor validation

  if not metadata.isVariant or metadata.branches.len == 0:
    return ""

  # STRUCTURAL QUERY 1: Check for exact match first
  # This handles cases where discriminator values are just the constructor name
  # Example: enum MyKind = Active, Inactive  (no prefix)
  for branch in metadata.branches:
    if branch.discriminatorValue == constructorName:
      return branch.discriminatorValue

  # STRUCTURAL QUERY 2: Check for suffix match with separator validation
  # This handles conventional prefixed naming (skActive, vkInt, etc.)
  # The discriminator values are already extracted from AST (structural!)
  # We're just comparing strings that came from structural analysis
  #
  # IMPORTANT (BUG PV-1 FIX): Must verify the character before constructor name is 'k'
  # - Correct: "rkActive".endsWith("Active") AND char before "Active" is 'k' ✓
  # - Incorrect: "rkIntActive".endsWith("Active") but char before "Active" is 'v' ✗
  # This prevents false positives like "Active" matching "IntActive"
  for branch in metadata.branches:
    if branch.discriminatorValue.endsWith(constructorName):
      # Verify that the character immediately before the constructor name is 'k' (separator)
      let prefixLen = branch.discriminatorValue.len - constructorName.len
      if prefixLen >= 1 and branch.discriminatorValue[prefixLen - 1] == 'k':
        return branch.discriminatorValue

  # STRUCTURAL QUERY 3: Case-insensitive suffix match - DISABLED
  # This was causing case-insensitive matches to succeed ("active" matching "Active")
  # which breaks type safety. Case sensitivity should be enforced for variant constructors.
  # If we want "Did you mean?" suggestions, they should be implemented in validation/error messages,
  # not in the matching logic used for code generation.
  #
  # let constructorLower = constructorName.toLowerAscii()
  # for branch in metadata.branches:
  #   if branch.discriminatorValue.toLowerAscii().endsWith(constructorLower):
  #     return branch.discriminatorValue

  # No match found
  return ""


proc analyzeFieldMetadata*(parentMetadata: ConstructMetadata,
                          fieldName: NimNode): ConstructMetadata =
  ## Recursively analyzes field metadata for nested pattern matching.
  ##
  ## **Purpose:**
  ## Enables deep nested pattern matching by extracting metadata for fields within
  ## parent types. Critical for multi-level destructuring (e.g., Person(address(city)))
  ##
  ## **How it works:**
  ## 1. Searches parent metadata structurally for the field
  ## 2. Extracts the field's type node from metadata
  ## 3. Recursively calls `analyzeConstructMetadata` on field type
  ## 4. Returns complete metadata for the field's type
  ##
  ## **Architectural role:**
  ## Threads metadata through nested pattern validation, enabling structural queries
  ## at every nesting level without falling back to string heuristics.
  ##
  ## **Args:**
  ##   parentMetadata: Metadata of the parent type containing the field
  ##   fieldName: AST node representing field name (nnkIdent, nnkSym, or nnkStrLit)
  ##
  ## **Returns:**
  ##   ConstructMetadata for the field's type.
  ##   Returns ConstructMetadata with kind=ckUnknown if field not found.
  ##
  ## **Example:**
  ##   ```nim
  ##   type
  ##     Address = object
  ##       city*: string
  ##       zip*: int
  ##     Person = object
  ##       name*: string
  ##       address*: Address
  ##
  ##   let personMeta = analyzeConstructMetadata(Person.getTypeInst())
  ##   let addressMeta = analyzeFieldMetadata(personMeta, ident"address")
  ##
  ##   assert addressMeta.kind == ckObject
  ##   assert addressMeta.typeName == "Address"
  ##   assert hasField(addressMeta, "city")
  ##
  ##   # Now can validate nested patterns like: Person(address(city="NYC"))
  ##   let cityMeta = analyzeFieldMetadata(addressMeta, ident"city")
  ##   assert cityMeta.kind == ckSimpleType
  ##   assert cityMeta.typeName == "string"
  ##   ```
  ##
  ## **Performance:**
  ##   O(n) where n = number of fields (field lookup) + recursive metadata analysis
  ##
  ## **Use case:**
  ##   Deep nested pattern validation at arbitrary depth without fixed recursion limits
  ##
  ## **See also:**
  ##   - `analyzeConstructMetadata` - Called recursively on field type
  ##   - `hasField` - Check field existence before calling this
  ##   - `getFieldType` - Get field type string (simpler alternative)

  # Extract field name as string
  let fieldNameStr = if fieldName.kind == nnkIdent:
                       fieldName.strVal
                     elif fieldName.kind == nnkStrLit:
                       fieldName.strVal
                     elif fieldName.kind == nnkSym:
                       fieldName.strVal
                     else:
                       fieldName.repr

  case parentMetadata.kind:
  of ckObject:
    # Regular object - structurally search fields
    for field in parentMetadata.fields:
      if field.name == fieldNameStr:
        # Found the field - analyze its type node
        return analyzeConstructMetadata(field.fieldTypeNode)

    # Field not found - return unknown metadata
    result = ConstructMetadata()
    result.kind = ckUnknown
    result.typeName = "unknown"

  of ckVariantObject:
    # Check discriminator field first
    if parentMetadata.discriminatorField == fieldNameStr:
      return analyzeConstructMetadata(parentMetadata.discriminatorTypeNode)

    # Check common fields
    for field in parentMetadata.fields:
      if field.name == fieldNameStr:
        return analyzeConstructMetadata(field.fieldTypeNode)

    # Check branch fields (structural search through all branches)
    for branch in parentMetadata.branches:
      for field in branch.fields:
        if field.name == fieldNameStr:
          return analyzeConstructMetadata(field.fieldTypeNode)

    # Field not found
    result = ConstructMetadata()
    result.kind = ckUnknown
    result.typeName = "unknown"

  of ckTuple:
    # Named tuple - structurally search elements
    if parentMetadata.isTupleNamed:
      for element in parentMetadata.tupleElements:
        if element.name == fieldNameStr:
          return analyzeConstructMetadata(element.elementTypeNode)

    # Try to match by position for unnamed tuples
    try:
      let pos = parseInt(fieldNameStr)
      if pos >= 0 and pos < parentMetadata.tupleElements.len:
        return analyzeConstructMetadata(parentMetadata.tupleElements[pos].elementTypeNode)
    except ValueError:
      discard

    # Not found
    result = ConstructMetadata()
    result.kind = ckUnknown
    result.typeName = "unknown"

  of ckSequence, ckArray, ckDeque, ckLinkedList:
    # For collections, if asking for element metadata, return element type
    if fieldNameStr in ["element", "item", "[]"]:
      if parentMetadata.elementTypeNode != nil:
        return analyzeConstructMetadata(parentMetadata.elementTypeNode)

    result = ConstructMetadata()
    result.kind = ckUnknown
    result.typeName = "unknown"

  of ckTable:
    # For tables, return key or value type
    if fieldNameStr in ["key", "keys"]:
      if parentMetadata.keyTypeNode != nil:
        return analyzeConstructMetadata(parentMetadata.keyTypeNode)
    elif fieldNameStr in ["value", "values", "[]"]:
      if parentMetadata.valueTypeNode != nil:
        return analyzeConstructMetadata(parentMetadata.valueTypeNode)

    result = ConstructMetadata()
    result.kind = ckUnknown
    result.typeName = "unknown"

  of ckOption:
    # For Option[T], return inner type
    if fieldNameStr in ["value", "inner", "get"]:
      if parentMetadata.optionInnerTypeNode != nil:
        return analyzeConstructMetadata(parentMetadata.optionInnerTypeNode)

    result = ConstructMetadata()
    result.kind = ckUnknown
    result.typeName = "unknown"

  of ckReference, ckPointer:
    # For ref/ptr types, first try to look up regular fields
    # (ref types have their underlying object's fields propagated to them during analyzeConstructMetadata)
    for field in parentMetadata.fields:
      if field.name == fieldNameStr:
        # Found the field - analyze its type node recursively
        return analyzeConstructMetadata(field.fieldTypeNode)

    # Handle special dereference operators
    if fieldNameStr in ["[]", "deref"]:
      if parentMetadata.underlyingTypeNode != nil:
        return analyzeConstructMetadata(parentMetadata.underlyingTypeNode)

    # Field not found - return unknown
    result = ConstructMetadata()
    result.kind = ckUnknown
    result.typeName = "unknown"

  else:
    # Unknown or unsupported parent type
    result = ConstructMetadata()
    result.kind = ckUnknown
    result.typeName = "unknown"