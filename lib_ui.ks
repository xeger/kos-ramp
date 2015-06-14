global ui_debug     is true.  // Debug messages on console and screen
global ui_debugVecs is true.  // Educational graphics on screen

global ui_DebugStb is vecdraw(v(0,0,0), v(0,0,0), GREEN, "Stbd", 1, false).
global ui_DebugUp is vecdraw(v(0,0,0), v(0,0,0), BLUE, "Up", 1, false).
global ui_DebugFwd is vecdraw(v(0,0,0), v(0,0,0), RED, "Fwd", 1, false).
global ui_DebugTgtFwd is vecdraw(v(0,0,0), v(0,0,0), YELLOW, "Tgt", 1, false).

function uiConsole {
  parameter prefix.
  parameter msg.

  print "T+" + round(time:seconds) + " " + prefix + ": " + msg.
}

function uiStatus {
  parameter prefix.
  parameter msg.

  uiConsole(prefix, msg).
  hudtext(msg, 10, 4, 24, GREEN, false).
}

function uiBanner {
  parameter prefix.
  parameter msg.

  uiConsole(prefix, msg).
  hudtext(msg, 10, 4, 24, GREEN, false).
}

function uiWarning {
  parameter prefix.
  parameter msg.

  uiConsole(prefix, msg).
  hudtext(msg, 10, 4, 36, YELLOW, false).
}

function uiError {
  parameter prefix.
  parameter msg.

  uiConsole(prefix, msg).
  hudtext(msg, 10, 4, 36, RED, false).
}

function uiAssertAccel {
  parameter prefix.

  local accel is ship:availablethrust / ship:mass. // kN over tonnes; 1000s cancel

  if accel = 0 {
    uiError(prefix, "ENGINE FAULT - RESUME CONTROL").
    local die is 1 / 0.
  } else {
    return accel.
  }
}

function uiDebug {
  parameter msg.

  if ui_debug {
    uiConsole("Debug", msg).
    hudtext(msg, 1, 3, 24, WHITE, false).
  }
}

function uiDebugNode {
  parameter T.
  parameter msg.

  if ui_debugVecs {
    local nd is node(T, 0, 0, 0).
    add(nd).
    uiDebug(msg).
    wait(1).
    remove(nd).
  }
}

function uiDebugAxes {
  parameter myPart.
  parameter hisPart.

  if ui_debugVecs = true {
    if myPart <> 0 {
      set ui_DebugStb:start to myPart:position.
      set ui_DebugStb:vec to myPart:portfacing:starvector*20.
      set ui_DebugUp:start to myPart:position.
      set ui_DebugUp:vec to myPart:portfacing:upvector*20.
      set ui_DebugFwd:start to myPart:position.
      set ui_DebugFwd:vec to myPart:portfacing:vector*20.
      set ui_DebugStb:show to true.
      set ui_DebugUp:show to true.
      set ui_DebugFwd:show to true.
    } else {
      set ui_DebugStb:show to false.
      set ui_DebugUp:show to false.
      set ui_DebugFwd:show to false.
    }

    if hisPart <> 0 {
      set ui_DebugTgtFwd:start to hisPart:position.
      set ui_DebugTgtFwd:vec to hisPart:portfacing:vector*20.
      set ui_DebugTgtFwd:show to true.
    } else {
      set ui_DebugTgtFwd:show to false.
    }
  }
}
