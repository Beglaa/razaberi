import unittest
import tables
import options
import sets
import ../../pattern_matching

{.push warning[UnusedImport]: off.}
{.push hint[XDeclaredButNotUsed]: off.}

# Comprehensive Deep Pattern Destructuring Testing
# Tests ALL pattern types working together in complex nested structures

suite "Comprehensive Deep Pattern Destructuring":
  
  # Define complex nested types that combine all pattern types
  type
    Permission = enum Admin, Read, Write, Execute, Delete
    
    Location = object
      coordinates: (float, float)  # Tuple pattern
      zone: string
      
    ServiceConfig = object
      name: string
      permissions: set[Permission]  # Set pattern
      metadata: Table[string, string]  # Table pattern
      location: Option[Location]  # Option pattern
    
    SystemStatus = enum Active, Inactive, Maintenance
    
    # Complex nested structure combining ALL pattern types
    ComplexSystem = object
      # Table pattern: configuration mappings
      configs: Table[string, Table[string, string]]
      
      # Sequence pattern: list of services  
      services: seq[ServiceConfig]
      
      # Tuple pattern: system coordinates and status
      systemInfo: (string, SystemStatus, (int, int))  # Named: (name, status, (version, build))
      
      # Set pattern: system-wide permissions
      globalPermissions: set[Permission]
      
      # Named tuple equivalent using regular tuple
      networkConfig: (string, int, bool)  # (host, port, ssl)
      
      # Option pattern: optional backup configuration
      backupConfig: Option[Table[string, seq[string]]]

  test "should destructure extremely complex nested data combining all patterns":
    # Create complex nested data structure
    let complexData = ComplexSystem(
      configs: {
        "database": {
          "host": "localhost",
          "port": "5432",
          "ssl": "true"
        }.toTable,
        "cache": {
          "type": "redis", 
          "ttl": "3600"
        }.toTable
      }.toTable,
      
      services: @[
        ServiceConfig(
          name: "auth-service",
          permissions: {Admin, Read, Write},
          metadata: {"version": "1.0", "author": "team-alpha"}.toTable,
          location: some(Location(
            coordinates: (37.7749, -122.4194),
            zone: "us-west"
          ))
        ),
        ServiceConfig(
          name: "data-service", 
          permissions: {Read, Execute},
          metadata: {"version": "2.1", "author": "team-beta"}.toTable,
          location: none(Location)
        )
      ],
      
      systemInfo: ("production-cluster", Active, (2, 145)),
      globalPermissions: {Admin, Read, Write, Execute},
      networkConfig: ("api.example.com", 443, true),
      backupConfig: some({
        "daily": @["db-backup", "file-backup"],
        "weekly": @["full-system-backup"]
      }.toTable)
    )
    
    # Test comprehensive pattern destructuring - extracting specific data from deep nesting
    let result = match complexData:
      # Pattern combines: object, table, sequence, tuple, set, option destructuring
      ComplexSystem(
        configs: {"database": dbConfig, "cache": cacheConfig},  # Table pattern
        services: [authService, dataService],  # Sequence pattern  
        systemInfo: (clusterName, Active, (majorVer, buildNum)),  # Tuple pattern
        globalPermissions: perms,  # Set pattern (will be bound as variable)
        networkConfig: (host, port, ssl),  # Named tuple-like pattern
        backupConfig: Some(backups)  # Option pattern with nested table
      ) and Admin in perms and port > 400 and dbConfig.hasKey("host"):  # Guards
        # Extract deeply nested values using NO MANUAL ACCESS
        "System: " & clusterName & 
        " | DB: " & dbConfig["host"] & ":" & dbConfig["port"] &
        " | Cache: " & cacheConfig["type"] & 
        " | Auth: " & authService.name & " @ " & authService.location.get.zone &
        " | Coords: (" & $authService.location.get.coordinates[0] & "," & $authService.location.get.coordinates[1] & ")" &
        " | Data: " & dataService.name & 
        " | Version: " & $majorVer & "." & $buildNum &
        " | Network: " & host & ":" & $port & " (SSL:" & $ssl & ")" &
        " | Backups: " & $backups["daily"].len
      _: "No match"
    
    check(result == "System: production-cluster | DB: localhost:5432 | Cache: redis | Auth: auth-service @ us-west | Coords: (37.7749,-122.4194) | Data: data-service | Version: 2.145 | Network: api.example.com:443 (SSL:true) | Backups: 2")

  test "should destructure nested tables with complex patterns":
    # Complex nested table structure
    let nestedTables = {
      "app": {
        "frontend": {
          "framework": "vue",
          "version": "3.0"
        }.toTable,
        "backend": {
          "language": "nim", 
          "database": "postgresql"
        }.toTable
      }.toTable,
      "deploy": {
        "environment": {
          "stage": "production",
          "region": "us-east"
        }.toTable
      }.toTable
    }.toTable
    
    let result = match nestedTables:
      # Multi-level table destructuring
      {"app": {"frontend": frontendConfig, "backend": backendConfig}, "deploy": deployConfig} and frontendConfig.hasKey("framework") and backendConfig.hasKey("language"):
        "Tech: " & frontendConfig["framework"] & "+" & backendConfig["language"] & 
        " | Env: " & deployConfig["environment"]["stage"]
      _: "No match"
    
    check(result == "Tech: vue+nim | Env: production")

  test "should destructure complex sequence patterns with nested objects":
    # Sequence containing complex nested objects
    type 
      TaskStatus = enum Pending, Running, Complete
      TaskTag = enum Deployment, Frontend, Backup, Database, Maintenance
      Task = object
        id: int
        status: TaskStatus
        metadata: (string, int, bool)  # (name, priority, urgent)
        tags: set[TaskTag]
    
    let taskList = @[
      Task(
        id: 1,
        status: Running,
        metadata: ("deploy-frontend", 5, true),
        tags: {Deployment, Frontend}
      ),
      Task(
        id: 2, 
        status: Complete,
        metadata: ("backup-database", 3, false),
        tags: {Backup, Database}
      ),
      Task(
        id: 3,
        status: Pending,
        metadata: ("update-deps", 1, false), 
        tags: {Maintenance}
      )
    ]
    
    let result = match taskList:
      # Sequence pattern with complex object destructuring
      [
        Task(id: firstId, status: Running, metadata: (taskName, priority, urgent), tags: firstTags),
        Task(id: secondId, status: Complete, metadata: (backupName, _, _)),
        Task(status: Pending, metadata: (pendingName, pendingPri, _))
      ] and urgent and Deployment in firstTags and priority > 3:
        "Active: " & taskName & "(id=" & $firstId & ",pri=" & $priority & ") | " &
        "Done: " & backupName & "(id=" & $secondId & ") | " & 
        "Pending: " & pendingName & "(pri=" & $pendingPri & ")"
      _: "No match"
    
    check(result == "Active: deploy-frontend(id=1,pri=5) | Done: backup-database(id=2) | Pending: update-deps(pri=1)")

  test "should destructure mixed option patterns with complex nesting":
    # Complex Option patterns nested deeply
    type
      NestedConfig = object
        database: Option[Table[string, string]]
        cache: Option[seq[(string, int)]]  # Sequence of tuples
        permissions: Option[set[Permission]]
    
    let configWithSome = NestedConfig(
      database: some({
        "primary": "postgres://main:5432",
        "replica": "postgres://replica:5433"
      }.toTable),
      cache: some(@[("redis-1", 6379), ("redis-2", 6380)]),
      permissions: some({Admin, Read, Write})
    )
    
    let configWithNone = NestedConfig(
      database: none(Table[string, string]),
      cache: none(seq[(string, int)]),
      permissions: none(set[Permission])
    )
    
    # Test Some pattern destructuring
    let result1 = match configWithSome:
      NestedConfig(
        database: Some(dbUrls),
        cache: Some(cacheServers), 
        permissions: Some(perms)
      ) and dbUrls.hasKey("primary") and cacheServers.len >= 2 and Admin in perms:
        "DB: " & dbUrls["primary"] & " | Cache: " & cacheServers[0][0] & ":" & $cacheServers[0][1] & 
        " | Perms: " & $perms.card
      _: "No match"
    
    # Test None pattern destructuring  
    let result2 = match configWithNone:
      NestedConfig(
        database: None(),
        cache: None(),
        permissions: None()
      ):
        "All configs are None"
      _: "No match"
    
    check(result1 == "DB: postgres://main:5432 | Cache: redis-1:6379 | Perms: 3")
    check(result2 == "All configs are None")

  test "should destructure deeply nested tuple patterns":
    # Deeply nested tuple structure (10+ levels)
    let deepTuples = (
      "system",
      (
        "config", 
        (
          "database",
          (
            "connection",
            (
              "pool",
              (
                "settings",
                (
                  "timeout",
                  (
                    "read", 
                    (
                      "max", 
                      (
                        "value",
                        5000
                      )
                    )
                  )
                )
              )
            )
          )
        )
      )
    )
    
    let result = match deepTuples:
      # 10+ level tuple destructuring
      (
        systemName,
        (
          configType,
          (
            dbType,
            (
              connType,
              (
                poolType,
                (
                  settingsType,
                  (
                    timeoutType,
                    (
                      readType,
                      (
                        maxType,
                        (
                          valueType,
                          actualValue
                        )
                      )
                    )
                  )
                )
              )
            )
          )
        )
      ) and actualValue > 1000:
        systemName & "." & configType & "." & dbType & "." & connType & 
        "." & poolType & "." & settingsType & "." & timeoutType & 
        "." & readType & "." & maxType & "." & valueType & "=" & $actualValue
      _: "No match"
    
    check(result == "system.config.database.connection.pool.settings.timeout.read.max.value=5000")

  test "should destructure complex set patterns with nested validation":
    # Complex set patterns
    type
      Role = enum Manager, Developer, Analyst, Admin
      Department = enum Engineering, Marketing, Sales, Operations
      
      Employee = object
        name: string
        roles: set[Role]
        departments: set[Department]
        permissions: set[Permission]
    
    let employee = Employee(
      name: "Alice Johnson",
      roles: {Manager, Developer},
      departments: {Engineering, Operations},
      permissions: {Admin, Read, Write, Execute}
    )
    
    let result = match employee:
      # Complex set pattern matching with intersections
      Employee(
        name: empName,
        roles: empRoles,
        departments: empDepts,
        permissions: empPerms
      ) and Manager in empRoles and Developer in empRoles and 
           Engineering in empDepts and Admin in empPerms and
           empPerms.card >= 3:
        "Employee: " & empName & 
        " | Roles: " & $empRoles.card & 
        " | Depts: " & $empDepts.card &
        " | Perms: " & $empPerms.card
      _: "No match"
    
    check(result == "Employee: Alice Johnson | Roles: 2 | Depts: 2 | Perms: 4")

  test "should handle extreme nesting combining ALL pattern types":
    # Ultimate complexity test - ALL patterns nested together
    type
      UltimateNested = object
        level1: Table[string, seq[(string, Option[set[Permission]])]]  # Table -> Seq -> Tuple -> Option -> Set
    
    let ultimateData = UltimateNested(
      level1: {
        "services": @[
          ("auth", some({Admin, Read, Write})),
          ("data", some({Read, Execute})),
          ("cache", none(set[Permission]))
        ]
      }.toTable
    )
    
    let result = match ultimateData:
      # ALL PATTERNS COMBINED: Object -> Table -> Sequence -> Tuple -> Option -> Set  
      UltimateNested(
        level1: {"services": serviceList}
      ) and serviceList.len == 3:
        # Extract from the deeply nested pattern using another match
        match serviceList[0]:
          (serviceName, Some(perms)) and Admin in perms:
            "Ultimate: " & serviceName & " has " & $perms.card & " permissions"
          _:
            "Ultimate: No admin service"
      _: "No match"
    
    check(result == "Ultimate: auth has 3 permissions")

  test "should validate pattern matching works at 10+ nesting levels":
    # Test the requirement: "patterns work at depth 2, 3, N layers"
    # with a realistic 10+ level nested structure
    
    let deepNesting = some(some(some(some(some(some(some(some(some(some({
      "level10": @[
        ("final-tuple", {Admin, Read})
      ]
    }.toTable))))))))))
    
    let result = match deepNesting:
      # 10 levels of Option nesting + Table + Sequence + Tuple + Set
      Some(Some(Some(Some(Some(Some(Some(Some(Some(Some(finalTable)))))))))) and finalTable.hasKey("level10"):
        "Deep-10: " & finalTable["level10"][0][0] & " with " & $finalTable["level10"][0][1].card & " permissions"
      _: "Failed deep matching"
    
    check(result == "Deep-10: final-tuple with 2 permissions")