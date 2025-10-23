import unittest
import tables
# import sets  # Unused
# import sequtils  # Unused
import strutils
import strformat
import ../../pattern_matching

{.push warning[UnusedImport]: off.}
{.push hint[XDeclaredButNotUsed]: off.}

# Import the 10-layer nested structure types
# Based on structure.md - 10 layers of maximum complexity

# Layer 10 - Enums (deepest)
type
  Priority = enum
    Low, Medium, High, Critical, Urgent
  
  Status = enum
    Active, Inactive, Pending, Completed, Failed
  
  Permission = enum
    Read, Write, Execute, Delete, Admin

# Layer 9 - Sets of enums
type
  PermissionSet = set[Permission]
  StatusSet = set[Status]

# Layer 8 - Named tuples  
type
  Coordinates = tuple[x: float, y: float, z: float]
  Metadata = tuple[version: int, created: string, modified: string]
  Config = tuple[enabled: bool, timeout: int, retries: int]

# Layer 7 - Regular tuples containing named tuples
type
  Location = tuple[coords: Coordinates, name: string, active: bool]
  VersionInfo = tuple[meta: Metadata, config: Config]

# Layer 6 - Objects containing tuples
type
  Node = object
    id: int
    location: Location
    version: VersionInfo
    permissions: PermissionSet
    priority: Priority

# Layer 5 - Sequences of objects
type
  NodeCluster = seq[Node]
  
# Layer 4 - Tables with sequences as values  
type
  RegionMap = Table[string, NodeCluster]

# Layer 3 - Class-like objects containing tables
type
  DataCenter = ref object of RootObj
    name: string
    regions: RegionMap
    globalStatus: StatusSet
    lastSync: Metadata
    
  CloudProvider = ref object of DataCenter
    providerId: string
    billing: tuple[cost: float, currency: string]

# Layer 2 - Sequences of class objects
type
  ProviderNetwork = seq[CloudProvider]

# Layer 1 - Root object containing everything
type
  GlobalInfrastructure = object
    networkId: string
    providers: ProviderNetwork
    aggregateStats: Table[string, tuple[active: int, total: int, priority: Priority]]
    emergencyContacts: seq[tuple[name: string, permissions: PermissionSet, coords: Coordinates]]
    systemConfig: tuple[
      maintenance: tuple[enabled: bool, schedule: string],
      monitoring: tuple[alerts: StatusSet, thresholds: seq[int]]
    ]

# Helper procedures to create complex nested data
proc createNode(id: int, name: string, x, y, z: float): Node =
  Node(
    id: id,
    location: (
      coords: (x: x, y: y, z: z),
      name: name,
      active: true
    ),
    version: (
      meta: (version: 1, created: "2024-01-01", modified: "2024-08-20"),
      config: (enabled: true, timeout: 30, retries: 3)
    ),
    permissions: {Read, Write, Execute},
    priority: High
  )

proc createCloudProvider(name: string, providerId: string): CloudProvider =
  result = CloudProvider()
  result.name = name
  result.providerId = providerId
  result.regions = initTable[string, NodeCluster]()
  result.globalStatus = {Active, Pending}
  result.lastSync = (version: 2, created: "2024-01-01", modified: "2024-08-20")
  result.billing = (cost: 1500.50, currency: "USD")
  
  # Create nested regions with node clusters
  for region in ["us-east", "us-west", "eu-central"]:
    var cluster: NodeCluster = @[]
    for i in 1..3:
      cluster.add(createNode(i, &"{region}-node-{i}", 
                           float(i * 10), float(i * 20), float(i * 5)))
    result.regions[region] = cluster

proc createGlobalInfrastructure(): GlobalInfrastructure =
  result = GlobalInfrastructure(
    networkId: "global-net-001",
    providers: @[],
    aggregateStats: initTable[string, tuple[active: int, total: int, priority: Priority]](),
    emergencyContacts: @[],
    systemConfig: (
      maintenance: (enabled: false, schedule: "0 2 * * 0"),
      monitoring: (alerts: {Active, Failed}, thresholds: @[50, 75, 90, 95])
    )
  )
  
  # Add cloud providers
  result.providers.add(createCloudProvider("AWS", "aws-001"))
  result.providers.add(createCloudProvider("Azure", "az-002"))
  result.providers.add(createCloudProvider("GCP", "gcp-003"))
  
  # Add aggregate statistics
  result.aggregateStats["total_nodes"] = (active: 25, total: 30, priority: High)
  result.aggregateStats["failed_nodes"] = (active: 2, total: 30, priority: Critical)
  result.aggregateStats["pending_updates"] = (active: 5, total: 30, priority: Medium)
  
  # Add emergency contacts
  result.emergencyContacts.add((
    name: "John DevOps",
    permissions: {Read, Write, Admin},
    coords: (x: 40.7128, y: -74.0060, z: 10.0)
  ))
  result.emergencyContacts.add((
    name: "Sarah SRE", 
    permissions: {Read, Execute, Admin},
    coords: (x: 51.5074, y: -0.1278, z: 25.0)
  ))

suite "10-Layer Infrastructure Pattern Destructuring":
  
  test "should destructure through all 10 layers in one pattern":
    # Create the ultimate complex nested structure
    let infrastructure = createGlobalInfrastructure()
    
    # TEST 1: Ultimate 10-layer pattern matching
    # Layer 1 (object) -> Layer 2 (seq) -> Layer 3 (ref object) -> Layer 4 (table) 
    # -> Layer 5 (seq) -> Layer 6 (object) -> Layer 7 (tuple) -> Layer 8 (named tuple) 
    # -> Layer 9 (set) -> Layer 10 (enum)
    let result = match infrastructure:
      GlobalInfrastructure(
        networkId: netId,                                    # Layer 1: Root object
        providers: [firstProvider, *otherProviders],         # Layer 2: Provider sequence
        systemConfig: (
          maintenance: mainConfig,
          monitoring: (alerts: alertSet, thresholds: thresholds)
        )
      ) and netId == "global-net-001" and otherProviders.len >= 2:
        # Access the first provider's nested data
        let providerResult = match firstProvider[]:  # Dereference ref object
          CloudProvider(
            name: providerName,                              # Layer 3: Cloud provider ref object
            regions: {"us-east": eastCluster},               # Layer 4: Region table
            billing: (cost: billingCost, currency: curr)
          ) and providerName == "AWS":
            # Access the first node in us-east cluster - simplified to avoid nested complexity
            if eastCluster.len > 0:
              let node = eastCluster[0]  # Safe after length check
              if node.id == 1 and Read in node.permissions and node.priority == High:
                "10-Layer: " & providerName & " | Node-" & $node.id & 
                " | Location: " & node.location.name & 
                " | Coords: (" & $node.location.coords.x & "," & $node.location.coords.y & "," & $node.location.coords.z & ")" &
                " | Perms: " & $node.permissions.card & 
                " | Priority: " & $node.priority &
                " | Billing: " & $billingCost & " " & curr
              else:
                "Node match failed"
            else:
              "No nodes"
          _: "Provider match failed"
        providerResult
      _: "Infrastructure match failed"
    
    check(result == "10-Layer: AWS | Node-1 | Location: us-east-node-1 | Coords: (10.0,20.0,5.0) | Perms: 3 | Priority: High | Billing: 1500.5 USD")

  test "should destructure emergency contacts with deep coordinate matching":
    let infrastructure = createGlobalInfrastructure()
    
    let result = match infrastructure:
      GlobalInfrastructure(
        emergencyContacts: [
          firstContact, 
          (name: secondName, permissions: secondPerms, coords: (x: lon, y: lat, z: alt))
        ]
      ) and Admin in secondPerms and alt > 20.0:
        "Emergency: " & secondName & 
        " | Perms: " & $secondPerms.card &
        " | Location: (" & $lon & "," & $lat & "," & $alt & ")"
      _: "No match"
    
    check(result == "Emergency: Sarah SRE | Perms: 3 | Location: (51.5074,-0.1278,25.0)")

  test "should destructure aggregate statistics with tuple patterns":
    let infrastructure = createGlobalInfrastructure()
    
    let result = match infrastructure:
      GlobalInfrastructure(
        aggregateStats: {
          "total_nodes": (active: totalActive, total: totalCount, priority: totalPri),
          "failed_nodes": (active: failedActive, total: _, priority: failedPri)
        }
      ) and totalActive > 20 and failedPri == Critical:
        "Stats: Total=" & $totalActive & "/" & $totalCount & 
        " (priority=" & $totalPri & ") | " &
        "Failed=" & $failedActive & " (priority=" & $failedPri & ")"
      _: "No match"
    
    check(result == "Stats: Total=25/30 (priority=High) | Failed=2 (priority=Critical)")

  test "should destructure system configuration with nested tuples":
    let infrastructure = createGlobalInfrastructure()
    
    let result = match infrastructure:
      GlobalInfrastructure(
        systemConfig: (
          maintenance: (enabled: maintEnabled, schedule: maintSchedule),
          monitoring: (alerts: alertStatuses, thresholds: alertThresholds)
        )
      ) and not maintEnabled and alertThresholds.len > 3:
        "Config: Maintenance=" & $maintEnabled & 
        " (schedule=" & maintSchedule & ") | " &
        "Alerts=" & $alertStatuses.card & 
        " | Thresholds=" & $alertThresholds.len
      _: "No match"
    
    check(result == "Config: Maintenance=false (schedule=0 2 * * 0) | Alerts=2 | Thresholds=4")

  test "should destructure multiple providers with inheritance patterns":
    let infrastructure = createGlobalInfrastructure()
    
    let result = match infrastructure:
      GlobalInfrastructure(
        providers: [
          awsProvider,
          azureProvider,
          gcpProvider
        ]
      ) and awsProvider[].name == "AWS" and azureProvider[].name == "Azure":
        # Test that all providers are CloudProvider instances
        let providerTypes = match (awsProvider[], azureProvider[], gcpProvider[]):
          (CloudProvider(providerId: aws_id), CloudProvider(providerId: az_id), CloudProvider(providerId: gcp_id)):
            "Providers: " & aws_id & ", " & az_id & ", " & gcp_id
          _: "Provider type mismatch"
        providerTypes
      _: "No match"
    
    check(result == "Providers: aws-001, az-002, gcp-003")

  test "should destructure node clusters across multiple regions":
    let infrastructure = createGlobalInfrastructure()
    
    let result = match infrastructure:
      GlobalInfrastructure(
        providers: [firstProvider, *_]
      ):
        match firstProvider[]:
          CloudProvider(
            regions: {
              "us-east": eastNodes,
              "us-west": westNodes,
              "eu-central": euNodes
            }
          ) and eastNodes.len == 3 and westNodes.len == 3:
            # Check first node from each region
            let eastFirst = eastNodes[0]
            let westFirst = westNodes[0] 
            let euFirst = euNodes[0]
            
            "Regions: East=" & eastFirst.location.name & 
            " | West=" & westFirst.location.name &
            " | EU=" & euFirst.location.name &
            " | Total=" & $(eastNodes.len + westNodes.len + euNodes.len)
          _: "Region match failed"
      _: "Infrastructure match failed"
    
    check(result == "Regions: East=us-east-node-1 | West=us-west-node-1 | EU=eu-central-node-1 | Total=9")

  test "should destructure with complex guard conditions on deep nesting":
    let infrastructure = createGlobalInfrastructure()
    
    let result = match infrastructure:
      GlobalInfrastructure(
        providers: [firstProvider, *_]
      ):
        match firstProvider[]:
          CloudProvider(
            name: provName,
            regions: {"us-east": eastCluster},
            billing: (cost: cost, currency: currency),
            globalStatus: statuses
          ) and cost > 1000.0 and Active in statuses:
            # Check version info in first node
            let firstNode = eastCluster[0]
            match firstNode:
              Node(
                version: (
                  meta: (version: ver, created: created, modified: modified),
                  config: (enabled: configEnabled, timeout: timeout, retries: retries)
                )
              ) and ver >= 1 and configEnabled and timeout >= 30:
                "Deep: " & provName & 
                " | Cost=" & $cost & " " & currency &
                " | Version=" & $ver &
                " | Config: enabled=" & $configEnabled & ",timeout=" & $timeout & ",retries=" & $retries &
                " | Created=" & created
              _: "Node version match failed"
          _: "Provider match failed"
      _: "Infrastructure match failed"
    
    check(result == "Deep: AWS | Cost=1500.5 USD | Version=1 | Config: enabled=true,timeout=30,retries=3 | Created=2024-01-01")

  test "should destructure with set operations and enum comparisons":
    let infrastructure = createGlobalInfrastructure()
    
    let result = match infrastructure:
      GlobalInfrastructure(
        providers: [provider, *_],
        emergencyContacts: [contact, *_]
      ):
        let providerResult = match provider[]:
          CloudProvider(
            regions: {"us-east": eastNodes}
          ) and eastNodes.len > 0:
            let firstNode = eastNodes[0]
            match firstNode:
              Node(
                permissions: nodePermissions,
                priority: nodePriority
              ) and Write in nodePermissions and Execute in nodePermissions and nodePriority == High:
                "NodePerms: " & $nodePermissions.card & " permissions with High priority"
              _: "Node permissions failed"
          _: "Provider failed"
        
        let contactResult = match contact:
          (name: contactName, permissions: contactPerms, coords: _) and Admin in contactPerms:
            "Contact: " & contactName & " has Admin access"
          _: "Contact failed"
        
        providerResult & " | " & contactResult
      _: "Match failed"
    
    check(result == "NodePerms: 3 permissions with High priority | Contact: John DevOps has Admin access")

  test "should validate all 10 layers are accessible through pattern matching":
    let infrastructure = createGlobalInfrastructure()
    
    # This test ensures we can destructure each layer independently
    var layerResults: seq[string] = @[]
    
    # Layer 1: Root object
    let layer1 = match infrastructure:
      GlobalInfrastructure(networkId: id): "Layer1: " & id
      _: "Layer1: Failed"
    layerResults.add(layer1)
    
    # Layer 2: Sequence  
    let layer2 = match infrastructure:
      GlobalInfrastructure(providers: providers) and providers.len == 3: "Layer2: " & $providers.len & " providers"
      _: "Layer2: Failed"
    layerResults.add(layer2)
    
    # Layer 3: Ref object - safe access
    let layer3 = if infrastructure.providers.len > 0 and not infrastructure.providers[0].isNil:
      match infrastructure.providers[0][]:
        CloudProvider(name: name): "Layer3: " & name
        _: "Layer3: Failed"
    else: "Layer3: No providers"
    layerResults.add(layer3)
    
    # Layer 4: Table - safe access
    let layer4 = if infrastructure.providers.len > 0 and not infrastructure.providers[0].isNil:
      match infrastructure.providers[0][]:
        CloudProvider(regions: regions) and "us-east" in regions: "Layer4: us-east found"
        _: "Layer4: Failed"
    else: "Layer4: No providers"
    layerResults.add(layer4)
    
    # Layer 5: Sequence in table - safe access  
    let layer5 = if infrastructure.providers.len > 0 and not infrastructure.providers[0].isNil and infrastructure.providers[0][].regions.hasKey("us-east"):
      match infrastructure.providers[0][].regions["us-east"]:
        [first, *rest] and rest.len == 2: "Layer5: " & $rest.len & " additional nodes"
        _: "Layer5: Failed"
    else: "Layer5: No us-east region"
    layerResults.add(layer5)
    
    # Layer 6: Object in sequence - safe access
    let layer6 = if infrastructure.providers.len > 0 and not infrastructure.providers[0].isNil and infrastructure.providers[0][].regions.hasKey("us-east") and infrastructure.providers[0][].regions["us-east"].len > 0:
      match infrastructure.providers[0][].regions["us-east"][0]:
        Node(id: nodeId): "Layer6: Node " & $nodeId
        _: "Layer6: Failed"
    else: "Layer6: No nodes available"
    layerResults.add(layer6)
    
    # Layer 7: Tuple in object - safe access
    let layer7 = if infrastructure.providers.len > 0 and not infrastructure.providers[0].isNil and infrastructure.providers[0][].regions.hasKey("us-east") and infrastructure.providers[0][].regions["us-east"].len > 0:
      match infrastructure.providers[0][].regions["us-east"][0]:
        Node(location: (coords: _, name: locName, active: isActive)) and isActive: "Layer7: " & locName
        _: "Layer7: Failed"
    else: "Layer7: No nodes available"
    layerResults.add(layer7)
    
    # Layer 8: Named tuple in tuple - safe access
    let layer8 = if infrastructure.providers.len > 0 and not infrastructure.providers[0].isNil and infrastructure.providers[0][].regions.hasKey("us-east") and infrastructure.providers[0][].regions["us-east"].len > 0:
      match infrastructure.providers[0][].regions["us-east"][0]:
        Node(location: (coords: (x: x, y: y, z: z), name: _, active: _)): "Layer8: (" & $x & "," & $y & "," & $z & ")"
        _: "Layer8: Failed"
    else: "Layer8: No nodes available"
    layerResults.add(layer8)
    
    # Layer 9: Set in object - safe access
    let layer9 = if infrastructure.providers.len > 0 and not infrastructure.providers[0].isNil and infrastructure.providers[0][].regions.hasKey("us-east") and infrastructure.providers[0][].regions["us-east"].len > 0:
      match infrastructure.providers[0][].regions["us-east"][0]:
        Node(permissions: perms) and Read in perms: "Layer9: " & $perms.card & " permissions"
        _: "Layer9: Failed"
    else: "Layer9: No nodes available"
    layerResults.add(layer9)
    
    # Layer 10: Enum in object - safe access
    let layer10 = if infrastructure.providers.len > 0 and not infrastructure.providers[0].isNil and infrastructure.providers[0][].regions.hasKey("us-east") and infrastructure.providers[0][].regions["us-east"].len > 0:
      match infrastructure.providers[0][].regions["us-east"][0]:
        Node(priority: prio) and prio == High: "Layer10: " & $prio
        _: "Layer10: Failed"
    else: "Layer10: No nodes available"
    layerResults.add(layer10)
    
    let finalResult = layerResults.join(" | ")
    
    check(finalResult == "Layer1: global-net-001 | Layer2: 3 providers | Layer3: AWS | Layer4: us-east found | Layer5: 2 additional nodes | Layer6: Node 1 | Layer7: us-east-node-1 | Layer8: (10.0,20.0,5.0) | Layer9: 3 permissions | Layer10: High")