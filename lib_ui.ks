clearscreen.
clearvecdraws().

global ui_announce is 0.
global ui_announceMsg is "".

global ui_debug     is true.  // Debug messages on console and screen
global ui_debugNode is true. // Explain node planning
global ui_debugAxes is false. // Explain 3-axis navigation e.g. docking

global ui_DebugStb is vecdraw(v(0,0,0), v(0,0,0), GREEN, "Stb", 1, false).
global ui_DebugUp is vecdraw(v(0,0,0), v(0,0,0), BLUE, "Up", 1, false).
global ui_DebugFwd is vecdraw(v(0,0,0), v(0,0,0), RED, "Fwd", 1, false).

global ui_myPort is vecdraw(v(0,0,0), v(0,0,0), YELLOW, "Ship", 1, false).
global ui_hisPort is vecdraw(v(0,0,0), v(0,0,0), PURPLE, "Dock", 1, false).

function uiConsole {
  parameter prefix.
  parameter msg.

  print "T+" + round(time:seconds) + " " + prefix + ": " + msg.
}

function uiBanner {
  parameter prefix.
  parameter msg.

  if (time:seconds - ui_announce > 60) or (ui_announceMsg <> msg) {
    uiConsole(prefix, msg).
    hudtext(msg, 10, 4, 24, GREEN, false).
    set ui_announce to time:seconds.
    set ui_announceMsg to msg.
  }
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

function uiShowPorts {
  parameter myPort.
  parameter hisPort.
  parameter dist.
  parameter ready.

  if myPort <> 0 {
    set ui_myPort:start to myPort:position.
    set ui_myPort:vec to myPort:portfacing:vector*dist.
    if ready {
      set ui_myPort:color to GREEN.
    } else {
      set ui_myPort:color to RED.
    }
    set ui_myPort:show to true.
  } else {
    set ui_myPort:show to false.
  }

  if hisPort <> 0 {
    set ui_hisPort:start to hisPort:position.
    set ui_hisPort:vec to hisPort:portfacing:vector*dist.
    set ui_hisPort:show to true.
  } else {
    set ui_hisPort:show to false.
  }
}

function uiAssertAccel {
  parameter prefix.

  local accel is ship:availablethrust / ship:mass. // kN over tonnes; 1000s cancel

  if accel <= 0 {
    uiError(prefix, "ENGINE FAULT - RESUME CONTROL").
    wait 5.
    reboot.
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
  parameter mdv.
  parameter msg.

  if ui_debugNode {
    local nd is node(T, mdv:x, mdv:y, mdv:z).
    add(nd).
    uiDebug(msg).
    wait(0.5).
    remove(nd).
  }
}

function uiDebugAxes {
  parameter origin.
  parameter dir.
  parameter length.

  if ui_debugAxes = true {
    if length:x <> 0 {
      set ui_DebugStb:start to origin.
      set ui_DebugStb:vec to dir:starvector*length:x.
      set ui_DebugStb:show to true.
    } else {
      set ui_DebugStb:show to false.
    }

    if length:y <> 0 {
      set ui_DebugUp:start to origin.
      set ui_DebugUp:vec to dir:upvector*length:y.
      set ui_DebugUp:show to true.
    } else {
      set ui_DebugUp:show to false.
    }

    if length:z <> 0 {
      set ui_DebugFwd:start to origin.
      set ui_DebugFwd:vec to dir:vector*length:z.
      set ui_DebugFwd:show to true.
    } else {
      set ui_DebugFwd:show to false.
    }
  }
}
