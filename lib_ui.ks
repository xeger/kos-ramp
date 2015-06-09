global libui_debug is false.

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

  if libui_debug {
    local nd is node(T, 0, 0, 0).
    add(nd).
    uiDebug(msg).
    wait(1).
    remove(nd).
  }
}
