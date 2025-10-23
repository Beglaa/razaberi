# Test state machine patterns (lines 233-254 from pm_use_cases.md)
import unittest
import ../../pattern_matching
import tables, options

# Define state machine types (lines 227-231)
type
  State = enum
    Idle, Connecting, Connected, Error

  Event = enum
    Connect, Success, Timeout, Disconnect, Reset

# Test 1: Simple state machine with enum patterns (lines 233-241)
proc handleEvent(currentState: State, event: string): State =
  match (currentState, event):
    (Idle, "connect"): Connecting
    (Connecting, "success"): Connected
    (Connecting, "timeout"): Error
    (Connected, "disconnect"): Idle
    (Connected, "error"): Error
    (Error, "reset"): Idle
    (_, _): currentState  # No transition - return current state

# Test 2: Game state machine with table patterns (lines 244-254)
type
  GameState = object
    turn: string
    difficulty: string
    status: string
    board: seq[seq[Option[string]]]

proc createBoard(): seq[seq[Option[string]]] =
  @[@[none(string), none(string), none(string)],
    @[none(string), none(string), none(string)],
    @[none(string), none(string), none(string)]]

proc handleGameMove(gameState: GameState, move: (string, int, int)): string =
  # Use pattern matching for state machine logic
  if gameState.status == "game_over":
    "Game already finished"
  else:
    match (gameState.turn, move[0]):
      ("player", "place"):
        let x = move[1]
        let y = move[2] 
        if x < gameState.board.len and y < gameState.board[0].len and gameState.board[x][y].isNone:
          "Player places at (" & $x & ", " & $y & ")"
        else:
          "Invalid placement"
      ("ai", _):
        if gameState.difficulty == "easy":
          "AI makes random move"
        elif gameState.difficulty == "hard":
          "AI makes optimal move"
        else:
          "Invalid AI difficulty"
      _:
        "Invalid move"

# Alternative game state handler using table-based matching
proc handleGameMoveTable(turn: string, difficulty: string, status: string, move: (string, int, int)): string =
  match (turn, difficulty, status, move):
    ("player", _, "", ("place", x, y)): "Player places at (" & $x & ", " & $y & ")"
    ("ai", "easy", "", _): "AI makes random move"  
    ("ai", "hard", "", _): "AI makes optimal move"
    (_, _, "game_over", _): "Game already finished"
    _: "Invalid move"

# Test 3: Network protocol state machine
type
  NetworkState = enum
    Disconnected, Connecting, Connected, Authenticating, Authenticated, Failed

proc handleNetworkEvent(state: NetworkState, event: string, data: string): NetworkState =
  match (state, event, data):
    (Disconnected, "connect", _): Connecting
    (Connecting, "connected", _): Connected
    (Connected, "authenticate", _): Authenticating
    (Authenticating, "auth_success", _): Authenticated
    (Authenticating, "auth_failed", _): Failed
    (Authenticated, "disconnect", _): Disconnected
    (Failed, "retry", _): Connecting
    _: state  # No state change

# Test 4: Complex state machine with conditional logic
proc handleComplexState(state: string, action: string, value: int): string =
  match (state, action):
    ("loading", "progress"): 
      if value >= 100: "Loading complete"
      elif value >= 50: "Loading halfway"
      else: "Still loading"
    ("ready", "start"): "Starting process"
    ("running", "stop"): "Process stopped"
    ("error", "reset"): "Reset to initial state"
    _: "Unknown state transition"

suite "State Machine Patterns":

  test "Simple state machine transitions work":
    # Test state transitions
    check handleEvent(Idle, "connect") == Connecting
    check handleEvent(Connecting, "success") == Connected
    check handleEvent(Connecting, "timeout") == Error
    check handleEvent(Connected, "disconnect") == Idle
    check handleEvent(Connected, "error") == Error
    check handleEvent(Error, "reset") == Idle
    
    # Test no transition case
    check handleEvent(Idle, "invalid") == Idle
    check handleEvent(Connected, "unknown") == Connected

  test "Game state machine patterns work":
    let playerState = GameState(turn: "player", difficulty: "", status: "", board: createBoard())
    let aiEasyState = GameState(turn: "ai", difficulty: "easy", status: "", board: createBoard())
    let aiHardState = GameState(turn: "ai", difficulty: "hard", status: "", board: createBoard())
    let gameOverState = GameState(turn: "", difficulty: "", status: "game_over", board: createBoard())
    
    # Test player moves
    check handleGameMove(playerState, ("place", 0, 0)) == "Player places at (0, 0)"
    check handleGameMove(playerState, ("place", 5, 5)) == "Invalid placement"
    
    # Test AI moves  
    check handleGameMove(aiEasyState, ("any", 0, 0)) == "AI makes random move"
    check handleGameMove(aiHardState, ("any", 1, 1)) == "AI makes optimal move"
    
    # Test game over
    check handleGameMove(gameOverState, ("place", 0, 0)) == "Game already finished"
    
    # Test invalid moves
    check handleGameMove(playerState, ("invalid", 0, 0)) == "Invalid move"

  test "Table-based state machine patterns work":
    # Test table-based state machine patterns
    check handleGameMoveTable("player", "", "", ("place", 1, 2)) == "Player places at (1, 2)"
    check handleGameMoveTable("ai", "easy", "", ("any", 0, 0)) == "AI makes random move"
    check handleGameMoveTable("ai", "hard", "", ("any", 0, 0)) == "AI makes optimal move"
    check handleGameMoveTable("player", "", "game_over", ("place", 0, 0)) == "Game already finished"
    check handleGameMoveTable("unknown", "", "", ("invalid", 0, 0)) == "Invalid move"
  test "Network protocol state machine works":
    # Test network state transitions
    check handleNetworkEvent(Disconnected, "connect", "") == Connecting
    check handleNetworkEvent(Connecting, "connected", "") == Connected
    check handleNetworkEvent(Connected, "authenticate", "user123") == Authenticating
    check handleNetworkEvent(Authenticating, "auth_success", "") == Authenticated
    check handleNetworkEvent(Authenticating, "auth_failed", "") == Failed
    check handleNetworkEvent(Authenticated, "disconnect", "") == Disconnected
    check handleNetworkEvent(Failed, "retry", "") == Connecting
    
    # Test no state change
    check handleNetworkEvent(Connected, "invalid", "") == Connected

  test "Complex state machine with guards works":
    # Test loading states with value guards
    check handleComplexState("loading", "progress", 100) == "Loading complete"
    check handleComplexState("loading", "progress", 75) == "Loading halfway"
    check handleComplexState("loading", "progress", 25) == "Still loading"
    
    # Test other state transitions
    check handleComplexState("ready", "start", 0) == "Starting process"
    check handleComplexState("running", "stop", 0) == "Process stopped"
    check handleComplexState("error", "reset", 0) == "Reset to initial state"
    
    # Test unknown transitions
    check handleComplexState("unknown", "action", 0) == "Unknown state transition"
