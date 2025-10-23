## Variant DSL - Production Implementation
##
## A Patty-style DSL for creating Nim variant objects that integrates seamlessly
## with the existing pattern matching library. This implementation uses structural
## AST analysis exclusively, avoiding string matching or text-based heuristics.
##
## Example usage:
## ```nim
## import variant_dsl
##
## variant Result:
##   Success(value: string)
##   Error(message: string)
##
## let success = Success("data loaded")
## let error = Error("network timeout")
## ```
##
## Generated objects work with pattern matching via discriminator-based matching:
## ```nim
## let result = match success:
##   obj and obj.kind == rkSuccess: "Success: " & obj.value
##   obj and obj.kind == rkError: "Error: " & obj.message
##   _: "Unknown"
## ```

import std/macros
import std/strutils

## Generate discriminator enum value name using structural type information
##
## This function creates consistent discriminator enum value names for variant objects
## by combining a type prefix with the constructor name. The naming pattern ensures
## uniqueness while maintaining readability.
##
## **Purpose**: Create unique, predictable discriminator enum value names
##
## **Naming Pattern**: `{typeName[0].toLower}k{constructorName}`
##
## **Examples**:
##   - Type: Result, Constructor: Success → rkSuccess
##   - Type: Option, Constructor: Some → okSome
##   - Type: Tree, Constructor: Leaf → tkLeaf
##
## Args:
##   typeName: The variant type name (e.g., "Result", "Option")
##   constructorName: The constructor variant name (e.g., "Success", "Error")
##
## Returns:
##   A string containing the discriminator enum value name
##
## Note:
##   Uses structural analysis of type names to ensure consistent naming
##   across all generated variant objects.
##
## See also:
##   - `getConstructorInfo` for AST-based constructor parsing
##   - `generateVariantImpl` for complete variant generation
proc genEnumName(typeName: string, constructorName: string): string =
  let prefix = typeName.toLowerAscii()[0..0] & "k"
  result = prefix & constructorName

## Constructor information extracted through structural AST analysis
type
  ConstructorInfo = object
    name: string              ## Constructor name (extracted from AST identifier)
    isZeroParam: bool         ## True for Empty(), false for Value(data: int)
    params: seq[tuple[name: string, paramType: NimNode]]  ## Parameter list (supports multi-param)

## Parse constructor information using structural AST analysis exclusively
##
## Extracts constructor metadata from AST nodes without any string-based heuristics.
## This function performs pure structural analysis on the AST to determine constructor
## characteristics including parameter count, names, and types.
##
## **Purpose**: Convert variant DSL syntax into structured constructor metadata
##
## **AST Pattern Analysis**:
##   - `nnkCall`: Zero-parameter constructor (Empty())
##   - `nnkObjConstr`: Single or multi-parameter constructor (Value(data: int, flags: bool))
##
## **Supported Constructor Forms**:
##   ```nim
##   Empty()                          # Zero-parameter
##   Value(data: int)                 # Single parameter
##   Add(left: int, right: int)       # Multiple parameters
##   ```
##
## Args:
##   node: NimNode representing a constructor definition from the variant body
##
## Returns:
##   ConstructorInfo containing parsed name, parameter information, and zero-param flag
##
## Raises:
##   Compile-time error if AST pattern is invalid or unsupported
##
## Implementation Notes:
##   This function operates on AST node structure exclusively, never on string content.
##   All parsing uses structural AST traversal through node.kind and indexed access.
##
## See also:
##   - `ConstructorInfo` type for returned metadata structure
##   - `generateConstructorProc` for constructor generation using this metadata
proc getConstructorInfo(node: NimNode): ConstructorInfo =
  case node.kind
  of nnkCall:
    # Zero-parameter constructor: Empty()
    # AST structure: Call[Ident["Empty"]]
    result.name = node[0].strVal
    result.isZeroParam = true
    result.params = @[]

  of nnkObjConstr:
    # Single or multi-parameter constructor: Value(data: int) or Add(left: int, right: int)
    # AST structure: ObjConstr[Ident["Value"], ExprColonExpr[Ident["data"], Ident["int"]]]
    result.name = node[0].strVal
    result.isZeroParam = false
    result.params = @[]

    # Extract all parameters using structural AST traversal
    for i in 1 ..< node.len:
      let paramNode = node[i]
      if paramNode.kind == nnkExprColonExpr:
        # Valid parameter: name: type
        result.params.add((
          name: paramNode[0].strVal,
          paramType: paramNode[1]
        ))
      else:
        error("Invalid parameter format in constructor " & result.name & ": " & repr(paramNode))

  else:
    # Unsupported AST node type
    error("Unsupported constructor AST pattern: " & $node.kind & " in " & repr(node))

## Generate equality operator using structural constructor information
##
## Creates a template-based equality operator (`==`) for variant objects that correctly
## handles discriminator-based comparison. The generated operator first checks if both
## values have the same discriminator, then performs field-wise comparison for that variant.
##
## **Purpose**: Generate type-safe equality operators for variant objects
##
## **Generated Code Structure**:
##   ```nim
##   template `==`(a, b: TypeName): bool =
##     if a.kind == b.kind:
##       case a.kind
##       of enumValue1: true  # zero-param variant
##       of enumValue2: a.field1 == b.field1 and a.field2 == b.field2
##     else:
##       false
##   ```
##
## **Delegation Pattern**: Generates simple field comparisons `a.field == b.field`
## and delegates to each field type's own `==` operator for the actual comparison logic.
## This approach ensures correctness for complex field types including nested variants.
##
## **Compile-Time Validation**: Uses `when compiles()` to detect missing `==` operators
## on field types and generates helpful error messages with implementation examples.
##
## **Template vs Proc**: Uses template definition instead of proc to ensure higher
## priority in overload resolution, preventing conflicts with system's generic `==`.
##
## **Export Control**: Conditionally exports `==` based on shouldExport flag:
##   - Private variants (test blocks) → non-exported `==`
##   - Exported variants (module-level) → exported `==*`
##
## Args:
##   typeName: String name of the variant type
##   typeIdent: NimNode identifier for the type (used in signatures)
##   constructorInfos: Sequence of parsed constructor metadata
##   shouldExport: Whether to export the equality operator with `*`
##
## Returns:
##   NimNode containing the complete template definition for the equality operator
##
## Implementation Notes:
##   Uses genSym for hygienic template parameters to avoid variable capture.
##   Generates compile-time error messages for missing field equality operators.
##
## See also:
##   - `generateConstructorProc` for constructor generation
##   - `generateVariantImpl` for complete variant type generation
proc generateEqualityOperator(typeName: string, typeIdent: NimNode,
                              constructorInfos: seq[ConstructorInfo],
                              shouldExport: bool): NimNode =
  # Debug: confirm we're generating equality
  hint("Generating == for " & typeName)

  # Use genSym for hygienic template parameters
  let aParam = genSym(nskParam, "a")
  let bParam = genSym(nskParam, "b")

  # Build case branches structurally from constructor information
  var caseBranches: seq[NimNode] = @[]

  for info in constructorInfos:
    let enumValue = ident(genEnumName(typeName, info.name))

    if info.isZeroParam:
      # of enumValue: true (template returns last expression)
      caseBranches.add(nnkOfBranch.newTree(
        enumValue,
        nnkStmtList.newTree(newLit(true))
      ))
    else:
      # Build field comparison expression with compile-time validation
      # Uses `when compiles()` to detect missing == operators and provide helpful errors
      var comparisonExpr: NimNode = nil
      for param in info.params:
        let fieldName = ident(param.name)
        let fieldTypeName = param.paramType.repr

        # Generate field comparison with compile-time check
        # when compiles(a.field == b.field):
        #   a.field == b.field
        # else:
        #   {.error: "Type 'FieldType' requires == operator".}
        #   false
        let aField = nnkDotExpr.newTree(aParam, fieldName)
        let bField = nnkDotExpr.newTree(bParam, fieldName)
        let fieldEqualityCheck = nnkInfix.newTree(ident("=="), aField, bField)

        # Generate error message for missing == operator
        let errorMsg = "Type '" & fieldTypeName & "' in variant '" & typeName &
                      "' requires an explicit equality operator (==).\n\n" &
                      "  Field: " & param.name & " (type: " & fieldTypeName & ")\n" &
                      "  Variant: " & typeName & "\n\n" &
                      "  Solution: Define a custom `==` operator for type '" & fieldTypeName & "'\n\n" &
                      "  Example:\n" &
                      "  proc `==`(a, b: " & fieldTypeName & "): bool =\n" &
                      "    # Compare fields of " & fieldTypeName & "\n" &
                      "    # For variant objects, check discriminator first\n" &
                      "    # For regular objects, compare all fields\n" &
                      "    result = ... # your comparison logic"

        let fieldComp = nnkWhenStmt.newTree(
          nnkElifBranch.newTree(
            nnkCall.newTree(ident("compiles"), fieldEqualityCheck),
            nnkStmtList.newTree(fieldEqualityCheck)
          ),
          nnkElse.newTree(
            nnkStmtList.newTree(
              nnkPragma.newTree(
                nnkExprColonExpr.newTree(ident("error"), newLit(errorMsg))
              ),
              newLit(false)
            )
          )
        )

        if comparisonExpr.isNil:
          comparisonExpr = fieldComp
        else:
          comparisonExpr = nnkInfix.newTree(ident("and"), comparisonExpr, fieldComp)

      # of enumValue: comparisonExpr (template returns last expression)
      caseBranches.add(nnkOfBranch.newTree(
        enumValue,
        nnkStmtList.newTree(comparisonExpr)
      ))

  # Build complete case statement
  let caseStmt = nnkCaseStmt.newTree(nnkDotExpr.newTree(aParam, ident("kind")))
  for branch in caseBranches:
    caseStmt.add(branch)

  # Build final template instead of proc - templates have higher priority in overload resolution
  # This ensures our == is chosen over system's generic == template
  # Conditionally export the == operator based on shouldExport flag
  let eqOpName = if shouldExport:
    nnkPostfix.newTree(ident("*"), ident("=="))
  else:
    ident("==")

  result = nnkTemplateDef.newTree(
    eqOpName,                                     # 0: name (conditionally exported)
    newEmptyNode(),                               # 1: generic params
    newEmptyNode(),                               # 2: (reserved)
    nnkFormalParams.newTree(                      # 3: formal params
      ident("bool"),
      nnkIdentDefs.newTree(aParam, typeIdent, newEmptyNode()),
      nnkIdentDefs.newTree(bParam, typeIdent, newEmptyNode())
    ),
    newEmptyNode(),    # 4: pragma (empty for templates)
    newEmptyNode(),                               # 5: (reserved)
    nnkStmtList.newTree(
      nnkIfStmt.newTree(
        nnkElifBranch.newTree(
          nnkInfix.newTree(
            ident("=="),
            nnkDotExpr.newTree(aParam, ident("kind")),
            nnkDotExpr.newTree(bParam, ident("kind"))
          ),
          nnkStmtList.newTree(caseStmt)
        ),
        nnkElse.newTree(
          nnkStmtList.newTree(newLit(false))
        )
      )
    )
  )

## Generate constructor procedure using structural AST construction
##
## Creates UFCS-style constructor procedures for variant objects that enable clean,
## collision-free instantiation syntax. Constructors use a typedesc parameter as the
## first argument to enable method-call syntax on the type itself.
##
## **Purpose**: Generate type-safe constructors with UFCS support
##
## **Generated Constructor Forms**:
##   - Zero-param: `proc Ready(_: typedesc[Status]): Status`
##   - Multi-param: `proc Value(_: typedesc[TypeName], data: int): TypeName`
##
## **UFCS Benefits**:
##   - Collision-free: `Status.Ready()` instead of `Ready()`
##   - Namespace clarity: Type name scopes the constructor
##   - IDE-friendly: Constructors appear in type's method list
##
## **Usage Examples**:
##   ```nim
##   # Zero-parameter constructor
##   let status = Status.Ready()
##
##   # Multi-parameter constructor
##   let result = Result.Success("completed")
##   let error = Result.Error("failed")
##   ```
##
## **Generated Code Structure**:
##   ```nim
##   proc ConstructorName(_: typedesc[TypeName], params...): TypeName =
##     TypeName(kind: discriminatorValue, fields...)
##   ```
##
## **Export Control**: Conditionally exports constructors based on shouldExport flag:
##   - Private variants → non-exported constructors
##   - Exported variants → exported constructors with `*`
##
## Args:
##   typeName: String name of the variant type
##   info: ConstructorInfo containing parsed constructor metadata
##   shouldExport: Whether to export the constructor with `*`
##
## Returns:
##   NimNode containing the complete proc definition for the constructor
##
## Implementation Notes:
##   Uses structural AST construction to avoid manual AST manipulation errors.
##   Properly initializes discriminator field for all constructor variants.
##
## See also:
##   - `getConstructorInfo` for constructor metadata extraction
##   - `generateEqualityOperator` for equality operator generation
proc generateConstructorProc(typeName: string, info: ConstructorInfo, shouldExport: bool): NimNode =
  let typeIdent = ident(typeName)
  let procName = ident(info.name)
  let enumValue = ident(genEnumName(typeName, info.name))

  if info.isZeroParam:
    # Zero-parameter constructor with typedesc: proc Empty(_: typedesc[TypeName]): TypeName
    # Enables UFCS: TypeName.Empty()
    # Conditionally export the constructor
    let exportedProcName = if shouldExport:
      nnkPostfix.newTree(ident("*"), procName)
    else:
      procName
    result = nnkProcDef.newTree(
      exportedProcName,
      newEmptyNode(),  # Generic parameters
      newEmptyNode(),  # Pragmas
      nnkFormalParams.newTree(
        typeIdent,  # Return type
        nnkIdentDefs.newTree(
          ident("_"),
          nnkBracketExpr.newTree(ident("typedesc"), typeIdent),
          newEmptyNode()
        )
      ),
      newEmptyNode(),  # Reserved
      newEmptyNode(),  # Reserved
      nnkStmtList.newTree(  # Body
        nnkObjConstr.newTree(
          typeIdent,
          nnkExprColonExpr.newTree(ident("kind"), enumValue)
        )
      )
    )
  else:
    # Multi-parameter constructor with typedesc: proc Value(_: typedesc[TypeName], data: int): TypeName
    # Enables UFCS: TypeName.Value(42)
    var formalParams = @[typeIdent]  # Return type first
    var fieldAssignments: seq[NimNode] = @[]

    # Add typedesc parameter as first parameter (enables UFCS)
    let typedescParam = nnkIdentDefs.newTree(
      ident("_"),
      nnkBracketExpr.newTree(ident("typedesc"), typeIdent),
      newEmptyNode()
    )
    formalParams.add(typedescParam)

    # Add discriminator assignment
    fieldAssignments.add(nnkExprColonExpr.newTree(ident("kind"), enumValue))

    # Build formal parameters and field assignments using structural AST construction
    for param in info.params:
      let paramIdent = ident(param.name)
      formalParams.add(nnkIdentDefs.newTree(paramIdent, param.paramType, newEmptyNode()))
      fieldAssignments.add(nnkExprColonExpr.newTree(paramIdent, paramIdent))

    # Construct the complete procedure using manual AST construction for multi-parameter support
    # Conditionally export the constructor
    let exportedProcName = if shouldExport:
      nnkPostfix.newTree(ident("*"), procName)
    else:
      procName
    result = nnkProcDef.newTree(
      exportedProcName,                            # Conditionally exported
      newEmptyNode(),                              # Generic parameters
      newEmptyNode(),                              # Pragmas
      nnkFormalParams.newTree(formalParams),       # Parameters
      newEmptyNode(),                              # Reserved
      newEmptyNode(),                              # Reserved
      nnkStmtList.newTree(                         # Body
        nnkObjConstr.newTree(@[typeIdent] & fieldAssignments)
      )
    )

## Internal implementation shared by both variant and variantExport macros
##
## Generates complete variant object types with discriminator enums, constructors,
## and equality operators using pure structural AST analysis. This is the core
## implementation that powers both `variant` and `variantExport` macros.
##
## **Purpose**: Transform variant DSL syntax into complete Nim variant object types
##
## **Structural Transformation Pipeline**:
##   1. Parse variant type name from AST identifier
##   2. Structurally analyze each constructor definition via `getConstructorInfo`
##   3. Generate discriminator enum using AST construction
##   4. Generate variant object type with case-based field layout
##   5. Generate equality operator template with field-wise comparison
##   6. Generate UFCS-style constructor procedures for all variants
##
## **Generated Components**:
##   - Discriminator enum type (TypeNameKind)
##   - Variant object type with case-based field layout
##   - Template-based equality operator (`==`)
##   - UFCS constructor procedures for each variant
##
## **Export Strategy**:
##   - `shouldExport = false`: Private variant (for tests, local scope)
##   - `shouldExport = true`: Exported variant (for libraries, module-level)
##
## **Implementation Philosophy**:
##   All operations use AST structure analysis exclusively, never string matching.
##   This approach ensures correctness, maintainability, and integration with
##   Nim's type system and pattern matching capabilities.
##
## Args:
##   typeName: NimNode identifier containing the variant type name
##   body: NimNode statement list containing constructor definitions
##   shouldExport: Whether to export all generated symbols with `*`
##
## Returns:
##   NimNode statement list containing all generated type definitions, operators, and constructors
##
## Raises:
##   Compile-time error if constructor syntax is invalid or AST patterns are unsupported
##
## Example Generated Structure:
##   ```nim
##   type
##     ResultKind = enum
##       rkSuccess, rkError
##
##     Result = object
##       case kind: ResultKind
##       of rkSuccess: value: string
##       of rkError: message: string
##
##   template `==`(a, b: Result): bool = ...
##
##   proc Success(_: typedesc[Result], value: string): Result = ...
##   proc Error(_: typedesc[Result], message: string): Result = ...
##   ```
##
## See also:
##   - `variant` macro for private variant generation
##   - `variantExport` macro for exported variant generation
##   - `getConstructorInfo` for constructor parsing
##   - `generateEqualityOperator` for equality generation
##   - `generateConstructorProc` for constructor generation
proc generateVariantImpl(typeName: NimNode, body: NimNode, shouldExport: bool): NimNode =
  # Extract type name and create identifiers
  let typeNameStr = typeName.strVal

  # Create identifiers based on export flag
  let typeIdent = if shouldExport:
    nnkPostfix.newTree(ident("*"), ident(typeNameStr))
  else:
    ident(typeNameStr)

  let enumTypeName = if shouldExport:
    nnkPostfix.newTree(ident("*"), ident(typeNameStr & "Kind"))
  else:
    ident(typeNameStr & "Kind")

  # Create plain identifiers for type references (never have export markers)
  let enumTypeRef = ident(typeNameStr & "Kind")
  let typeRef = ident(typeNameStr)  # Plain type reference for signatures

  # Parse all constructor definitions using structural AST analysis
  var constructorInfos: seq[ConstructorInfo] = @[]

  for i in 0 ..< body.len:
    constructorInfos.add(getConstructorInfo(body[i]))

  # Build complete result using structural AST construction
  result = nnkStmtList.newTree()

  # 1. Generate discriminator enum type using structural AST construction
  var enumValues: seq[NimNode] = @[newEmptyNode()]  # Empty first element for enum
  for info in constructorInfos:
    enumValues.add(ident(genEnumName(typeNameStr, info.name)))

  let enumTypeSection = nnkTypeSection.newTree(
    nnkTypeDef.newTree(
      enumTypeName,  # Non-exported for test compatibility
      newEmptyNode(),
      nnkEnumTy.newTree(enumValues)
    )
  )
  result.add(enumTypeSection)

  # 2. Generate variant object type using structural AST construction
  var caseBranches: seq[NimNode] = @[]

  # Add discriminator field (conditionally exported)
  let kindFieldIdent = if shouldExport:
    nnkPostfix.newTree(ident("*"), ident("kind"))
  else:
    ident("kind")

  let discriminatorField = nnkIdentDefs.newTree(
    kindFieldIdent,
    enumTypeRef,  # Use reference, not the exported version
    newEmptyNode()
  )

  # Generate case branches for each constructor
  for info in constructorInfos:
    let enumValue = ident(genEnumName(typeNameStr, info.name))

    if info.isZeroParam:
      # Zero-parameter case: no fields
      caseBranches.add(nnkOfBranch.newTree(
        enumValue,
        nnkRecList.newTree()
      ))
    else:
      # Multi-parameter case: add all fields (conditionally exported)
      var fields: seq[NimNode] = @[]
      for param in info.params:
        let fieldIdent = if shouldExport:
          nnkPostfix.newTree(ident("*"), ident(param.name))
        else:
          ident(param.name)

        fields.add(nnkIdentDefs.newTree(
          fieldIdent,
          param.paramType,
          newEmptyNode()
        ))

      caseBranches.add(nnkOfBranch.newTree(
        enumValue,
        nnkRecList.newTree(fields)
      ))

  # Build complete variant object type
  let caseStmt = nnkRecCase.newTree(@[discriminatorField] & caseBranches)
  let objectTypeSection = nnkTypeSection.newTree(
    nnkTypeDef.newTree(
      typeIdent,  # Non-exported for test compatibility
      newEmptyNode(),
      nnkObjectTy.newTree(
        newEmptyNode(),  # No inheritance
        newEmptyNode(),  # No pragmas
        nnkRecList.newTree(caseStmt)
      )
    )
  )
  result.add(objectTypeSection)

  # 3. Generate equality operator IMMEDIATELY after type definition
  # This ensures Type has == before it's needed by seq[Type] or other generic instantiations
  # Use plain type reference (not exported) for parameter types in equality operator
  result.add(generateEqualityOperator(typeNameStr, typeRef, constructorInfos, shouldExport))

  # 4. Generate constructor procedures for all variants
  for info in constructorInfos:
    result.add(generateConstructorProc(typeNameStr, info, shouldExport))

## Public macro wrappers

macro variant*(typeName: untyped, body: untyped): untyped =
  ## Private variant DSL macro for creating non-exported variant object types
  ##
  ## This macro provides a Patty-style DSL for defining variant objects with
  ## discriminator-based field layouts. Generated types are private (not exported)
  ## and suitable for local scope, test blocks, or module-internal use.
  ##
  ## **Purpose**: Create private variant object types with automatic constructor generation
  ##
  ## **Suitable For**:
  ##   - Unit tests that define variants inside test blocks
  ##   - Local scope variant definitions within procedures
  ##   - Private module-internal types
  ##   - Temporary or test-only data structures
  ##
  ## **DSL Syntax**:
  ##   ```nim
  ##   variant TypeName:
  ##     Constructor1()                    # Zero-parameter variant
  ##     Constructor2(field: Type)         # Single-parameter variant
  ##     Constructor3(x: int, y: string)   # Multi-parameter variant
  ##   ```
  ##
  ## **Generated Components**:
  ##   - Discriminator enum: `TypeNameKind` (private)
  ##   - Variant object: `TypeName` (private)
  ##   - Equality operator: `==` (private template)
  ##   - UFCS constructors: `TypeName.Constructor()` (private procs)
  ##
  ## **Pattern Matching Integration**:
  ##   Generated variants work seamlessly with the pattern matching library
  ##   through discriminator-based matching:
  ##   ```nim
  ##   let result = match value:
  ##     obj and obj.kind == rkSuccess: "Success: " & obj.value
  ##     obj and obj.kind == rkError: "Error: " & obj.message
  ##     _: "Unknown"
  ##   ```
  ##
  ## **Constructor Usage**:
  ##   ```nim
  ##   # Zero-parameter constructor
  ##   let empty = Option.None()
  ##
  ##   # Single-parameter constructor
  ##   let some = Option.Some(42)
  ##
  ##   # Multi-parameter constructor
  ##   let point = Point.Cartesian(10, 20)
  ##   ```
  ##
  ## Args:
  ##   typeName: Untyped identifier for the variant type name
  ##   body: Untyped statement list containing constructor definitions
  ##
  ## Returns:
  ##   Statement list containing all generated definitions (private)
  ##
  ## Example:
  ##   ```nim
  ##   variant Result:
  ##     Success(value: string)
  ##     Error(message: string)
  ##
  ##   # Usage
  ##   let success = Result.Success("completed")
  ##   let error = Result.Error("failed")
  ##
  ##   # Pattern matching
  ##   let msg = match success:
  ##     Result(kind == rkSuccess): "Got: " & success.value
  ##     Result(kind == rkError): "Error: " & success.message
  ##   ```
  ##
  ## See also:
  ##   - `variantExport` for exported variant types
  ##   - `generateVariantImpl` for implementation details
  generateVariantImpl(typeName, body, shouldExport = false)

macro variantExport*(typeName: untyped, body: untyped): untyped =
  ## Exported variant DSL macro for creating public variant object types
  ##
  ## This macro provides a Patty-style DSL for defining variant objects with
  ## discriminator-based field layouts. Generated types are exported (marked with `*`)
  ## and suitable for library APIs, public modules, and cross-module visibility.
  ##
  ## **Purpose**: Create exported variant object types for public APIs
  ##
  ## **Suitable For**:
  ##   - Library modules that need cross-module visibility
  ##   - Public API types exposed to users
  ##   - Module-level variant definitions for public consumption
  ##   - Shared data structures across module boundaries
  ##
  ## **IMPORTANT Scope Restrictions**:
  ##   Must be used at module scope only. Cannot be used inside:
  ##   - Procedures or functions
  ##   - Templates or macros
  ##   - Test blocks or local scopes
  ##   - Any nested context
  ##
  ## **DSL Syntax**:
  ##   ```nim
  ##   variantExport TypeName:
  ##     Constructor1()                    # Zero-parameter variant
  ##     Constructor2(field: Type)         # Single-parameter variant
  ##     Constructor3(x: int, y: string)   # Multi-parameter variant
  ##   ```
  ##
  ## **Generated Components** (all exported):
  ##   - Discriminator enum: `TypeNameKind*` (exported)
  ##   - Variant object: `TypeName*` (exported)
  ##   - Equality operator: `==*` (exported template)
  ##   - UFCS constructors: `Constructor*()` (exported procs)
  ##
  ## **Pattern Matching Integration**:
  ##   Generated variants work seamlessly with the pattern matching library
  ##   through discriminator-based matching across module boundaries:
  ##   ```nim
  ##   # In module A
  ##   variantExport Result:
  ##     Success(value: string)
  ##     Error(message: string)
  ##
  ##   # In module B (importing module A)
  ##   let result = match value:
  ##     obj and obj.kind == rkSuccess: "Success: " & obj.value
  ##     obj and obj.kind == rkError: "Error: " & obj.message
  ##     _: "Unknown"
  ##   ```
  ##
  ## **Constructor Usage**:
  ##   ```nim
  ##   # Zero-parameter constructor
  ##   let empty = Option.None()
  ##
  ##   # Single-parameter constructor
  ##   let some = Option.Some(42)
  ##
  ##   # Multi-parameter constructor
  ##   let point = Point.Cartesian(10, 20)
  ##   ```
  ##
  ## **Export Markers**:
  ##   All generated symbols receive export markers (`*`):
  ##   - Type definition: `TypeName* = object`
  ##   - Discriminator enum: `TypeNameKind* = enum`
  ##   - Constructors: `proc Constructor*(...)`
  ##   - Equality operator: `template ==*(...)`
  ##
  ## Args:
  ##   typeName: Untyped identifier for the variant type name
  ##   body: Untyped statement list containing constructor definitions
  ##
  ## Returns:
  ##   Statement list containing all generated definitions (exported)
  ##
  ## Example:
  ##   ```nim
  ##   # Module: result.nim
  ##   variantExport Result:
  ##     Success(value: string)
  ##     Error(message: string)
  ##
  ##   # Usage in same module
  ##   let success = Result.Success("completed")
  ##   let error = Result.Error("failed")
  ##
  ##   # Usage in another module
  ##   import result
  ##   let res = Result.Success("imported usage works")
  ##
  ##   # Pattern matching
  ##   let msg = match res:
  ##     Result(kind == rkSuccess): "Got: " & res.value
  ##     Result(kind == rkError): "Error: " & res.message
  ##   ```
  ##
  ## See also:
  ##   - `variant` for private variant types
  ##   - `generateVariantImpl` for implementation details
  generateVariantImpl(typeName, body, shouldExport = true)

# Export both macros for public use
export variant, variantExport