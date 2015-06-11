global libui_debug     is true.
global libui_debugNode is false.

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

  if libui_debug {
    uiConsole("Debug", msg).
    hudtext(msg, 1, 3, 24, WHITE, false).
  }
}

function uiDebugNode {
  parameter T.
  parameter msg.

  if libui_debugNode {
    local nd is node(T, 0, 0, 0).
    add(nd).
    uiDebug(msg).
    wait(1).
    remove(nd).
  }
}
