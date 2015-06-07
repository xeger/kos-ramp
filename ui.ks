function uiConsole {
  parameter prefix.
  parameter msg.

  return "T+" + round(time:seconds) + " " + prefix + ": " + msg.
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
  parameter msg.

  print "Node: " + msg.
  hudtext(msg, 10, 4, 36, RED, false).
}

function uiDebugNode {
  parameter T.
  parameter msg.

  //local nd is node(T, 0, 0, 0).
  //add(nd).
  uiConsole("Debug", msg).
  //hudtext(msg, 1, 3, 24, WHITE, false).
  //wait(1).
  //remove(nd).
}
