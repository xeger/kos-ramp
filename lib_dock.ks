/////////////////////////////////////////////////////////////////////////////
// Docking functions
/////////////////////////////////////////////////////////////////////////////
// Shared logic for docking. Assumes that every ship has one port!
/////////////////////////////////////////////////////////////////////////////

run lib_pid.

// Constant docking parameters
global dock_scale is 50.  // alignment speed scaling factor (m)
global dock_start is 25.  // ideal start distance (m) & approach speed scaling factor
global dock_final is 1.   // final-approach distance (m)
global dock_algnV is 5.   // max alignment speed (m/s)
global dock_apchV is 1.   // max approach speed (m/s)
global dock_dockV is 0.1. // final-approach radial speed (m/s)

// Velocity controllers (during alignment)
global dock_X1 is pidInit(1.4, 0.4, 0.2, -1, 1).
global dock_Y1 is pidInit(1.4, 0.4, 0.2, -1, 1).

// Position controllers (during approach)
global dock_X2 is pidInit(0.4, 0, 1.0, -1, 1).
global dock_Y2 is pidInit(0.4, 0, 1.0, -1, 1).

// Shared velocity controller
global dock_Z is pidInit(0.8, 0.4, 0.2, -1, 1).

// Prepare to dock by orienting the ship and priming SAS/RCS
function dockPrepare {
  parameter myPort, hisPort.

  clearvecdraws().
  sas off.
  lock steering to lookdirup(-hisPort:portfacing:forevector, v(0,1,0)).
  wait until vdot(myPort:portfacing:forevector, hisPort:portfacing:forevector) < -0.99.
  rcs on.
}

// Finish docking
function dockFinish {
  unlock steering.
  rcs off.
  sas on.
  uiShowPorts(0, 0, 0, false).
  uiDebugAxes(0,0, v(0,0,0)).
}

// Back off from target in order to approach from the correct side.
function dockBack {
  parameter pos, vel.

  set ship:control:fore to -pidSeek(dock_Z, dock_algnV, vel:Z).
}

// Center docking ports in X/Y while slowly moving forward
function dockAlign {
  parameter pos, vel.

  // Taper X/Y/Z speed according to distance from target
  local vScaleX is min(abs(pos:X / dock_scale), 1).
  local vScaleY is min(abs(pos:Y / dock_scale), 1).
  local vScaleZ is min(abs(pos:Z / dock_start), 1).

  local vWantX is -(pos:X / abs(pos:X)) * dock_algnV * vScaleX.
  local vWantY is -(pos:Y / abs(pos:Y)) * dock_algnV * vScaleY.

  if pos:Z > dock_start {
    // Move forward at a distance-dependent speed between
    // approach and final-approach
    set ship:control:fore to -pidSeek(dock_Z, -max(dock_dockV, dock_apchV*vScaleZ), vel:Z).
  } else {
    // Halt at approach-start distance
    set ship:control:fore to -pidSeek(dock_Z, 0, vel:Z).
  }

  // Drift into alignment
  local rcsStarb is -1 * pidSeek(dock_X1, vWantX, vel:X).
  local rcsTop to -1 * pidSeek(dock_Y1, vWantY, vel:Y).
  set ship:control:starboard to rcsStarb.
  set ship:control:top to rcsTop.
}

// Close remaining distance to the target, slowing drastically near
// the end.
function dockApproach {
  parameter pos, vel.

  // Taper Z speed according to distance from target
  local vScaleZ is min(abs(pos:Z / dock_start), 1).

  if pos:Z < dock_final {
    // Final approach: barely inch forward!
    set ship:control:fore to -pidSeek(dock_Z, -dock_dockV, vel:Z).
  } else {
    // Move forward at a distance-dependent speed between
    // approach and final-approach
    set ship:control:fore to -pidSeek(dock_Z, -max(dock_dockV, dock_apchV*vScaleZ), vel:Z).
  }

  // Stay aligned
  local rcsStarb is -1 * pidSeek(dock_X2, 0, pos:X).
  local rcsTop is -1 * pidSeek(dock_Y2, 0, pos:Y).
  set ship:control:starboard to rcsStarb.
  set ship:control:top to rcsTop.
}

// Figure out how to undock
function dockChooseDeparturePort {
  for port in core:element:dockingPorts {
    if dockComplete(port) {
      return port.
    }
  }

  return 0.
}

// Find suitable docking ports on self and target
function dockChoosePorts {
  local hisPort is 0.
  local myPort is 0.

  local myMods is ship:modulesnamed("ModuleDockingNode").
  for mod in myMods {
    // TODO get this to work on ships with more than one port
    //if mod:part:controlfrom = true {
      set myPort to mod:part.
    //}
  }

  if myPort <> 0 {
    local myMass is myPort:mass.

    // HACK: distinguish between targeted vessel and targeted port using mass > 2 tonnes
    if target:mass > 2 {
      local hisMods is target:modulesnamed("ModuleDockingNode").
      local bestAngle is 180.

      for mod in hisMods {
        if abs(mod:part:mass - myMass) < 0.1 and
          mod:part:targetable and mod:part:state = "Ready" and
          vang(target:position, mod:part:portfacing:vector) < bestAngle
        {
          set hisPort to mod:part.
        }
      }
    } else {
      set hisPort to target.
    }

    if hisPort = 0 {
      set myPort to 0.
    }
  }

  if hisPort <> 0 and myPort <> 0 {
    set target to hisPort.
    return myPort.
  } else {
    return 0.
  }
}

function dockPending {
  parameter port.

  if port:state = "PreAttached" {
    return true.
  } else {
    return false.
  }
}
// Determine whether chosen port is docked
function dockComplete {
  parameter port.

  if port:state = "Docked (docker)" or port:state = "Docked (dockee)" or port:state = "Docked (same vessel)" {
    return true.
  } else {
    return false.
  }
}
