/////////////////////////////////////////////////////////////////////////////
// Docking functions
/////////////////////////////////////////////////////////////////////////////
// Shared logic for docking. Assumes that every ship has one port!
/////////////////////////////////////////////////////////////////////////////

// Constant docking parameters
global dock_scale is 25.   // alignment speed scaling factor (m)
global dock_start is 10.   // ideal start distance (m) & approach speed scaling factor
global dock_final is 1.    // final-approach distance (m)
global dock_algnV is 2.5.  // max alignment speed (m/s)
global dock_apchV is 1.    // max approach speed (m/s)
global dock_dockV is 0.2.  // final approach speed (m/s)
global dock_scale is 2.    // max speed multiple when ship is far from target

//global dock_Z is pidloop(1.4, 0, 0.4, -1, 1).

// Velocity controllers (during alignment)
global dock_X1 is pidloop(1.4, 0, 0.4, -1, 1).
global dock_Y1 is pidloop(1.4, 0, 0.4, -1, 1).

// Position controllers (during approach)
global dock_X2 is pidloop(0.4, 0, 1.2, -1, 1).
global dock_Y2 is pidloop(0.4, 0, 1.2, -1, 1).

// Shared velocity controller
global dock_Z is pidloop(1.4, 0.2, 0.4, -1, 1).

// Prepare to dock by orienting the ship and priming SAS/RCS
function dockPrepare {
  parameter myPort, hisPort.

  sas off.
  lock steering to lookdirup(-hisPort:portfacing:forevector, v(0,1,0)).
  set t0 to time:seconds.
  wait until vdot(myPort:portfacing:forevector, hisPort:portfacing:forevector) < -0.9 or (time:seconds - t0 > 15).
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
  parameter backPos, backVel.

  set dock_Z:setpoint to dock_algnV.
  set ship:control:fore to -dock_Z:update(time:seconds, backVel:Z).
}

// Center docking ports in X/Y while slowly moving forward
function dockAlign {
  parameter alignPos, alignVel.

  // Taper X/Y/Z speed according to distance from target
  local vScaleX is min(abs(alignPos:X / dock_scale), dock_scale).
  local vScaleY is min(abs(alignPos:Y / dock_scale), dock_scale).
  local vScaleZ is min(abs(alignPos:Z / dock_start), dock_scale).

  // Never align slower than final-approach speed
  local vWantX is -(alignPos:X / abs(alignPos:X)) * min(dock_dockV, dock_algnV * vScaleX).
  local vWantY is -(alignPos:Y / abs(alignPos:Y)) * min(dock_dockV, dock_algnV * vScaleY).
  local vWantZ is 0.

  if alignPos:Z >= dock_start {
    // Move forward at a distance-dependent speed between
    // approach and final-approach
    set vWantZ to -max(dock_dockV, dock_apchV*vScaleZ).
  } else {
    // Halt at approach-start distance
    set vWantZ to 0.
  }

  // Drift into alignment
  set dock_X1:setpoint to vWantX.
  set dock_Y1:setpoint to vWantY.
  set dock_Z:setpoint to vWantZ.
  set ship:control:starboard to -1 * dock_X1:update(time:seconds, alignVel:X).
  set ship:control:top to -1 * dock_Y1:update(time:seconds, alignVel:Y).
  set ship:control:fore to -1 * dock_Z:update(time:seconds, alignVel:Z).
}

// Close remaining distance to the target, slowing drastically near
// the end.
function dockApproach {
  parameter aprchPos, aprchVel.

  // Taper Z speed according to distance from target
  local vScaleZ is min(abs(aprchPos:Z / dock_start), dock_scale).
  local vWantZ is 0.

  if aprchPos:Z < dock_final {
    // Final approach: barely inch forward!
    set vWantZ to -dock_dockV.
  } else {
    // Move forward at a distance-dependent speed between
    // approach and final-approach
    set vWantZ to -max(dock_dockV, dock_apchV*vScaleZ).
  }

  set dock_Z:setpoint to vWantZ.
  set ship:control:fore to -dock_Z:update(time:seconds, aprchVel:Z).

  // Stay aligned
  set dock_X2:setpoint to 0.
  set dock_Y2:setpoint to 0.
  set ship:control:starboard to -1 * dock_X2:update(time:seconds, aprchPos:X).
  set ship:control:top to -1 * dock_Y2:update(time:seconds, aprchPos:Y).
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

// Find suitable docking ports on self and target. Works using a heuristic:
//   - if target is a vessel, target biggest unoccupied port
//   - (else target is already a port)
//   - find port on ship with same mass
function dockChoosePorts {
  local myPort is 0.
  local hisPort is 0.

  if not target:name:contains("docking") {
    // ship is targeted; find a good port
    local hisMods is target:modulesnamed("ModuleDockingNode").
    for mod in hisMods {
      if mod:part:state = "Ready" and mod:part:mass > hisPort:mass {
        set hisPort to mod:part.
      }
    }
  }
  else {
    // dock is already targeted
    set hisPort to target.
  }

  local myMods is ship:modulesnamed("ModuleDockingNode").
  for mod in myMods {
    if mod:part:mass = hisPort:mass {
      set myPort to mod:part.
    }
  }

  if hisPort <> 0 and myPort <> 0 {
    set target to hisPort.
    myPort:controlfrom.
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

// Cancel most velocity with respect to target. Leave residual speed
function dockMatchVelocity {
  parameter residual.

  set residual to max(0.2, residual).

  // Don't let unbalanced RCS mess with our velocity
  rcs off.
  sas off.

  local matchStation is 0.
  if target:name:contains("docking") {
    set matchStation to target:ship.
  } else {
    set matchStation to target.
  }

  local matchAccel is uiAssertAccel("Dock").
  lock matchVel to (ship:velocity:orbit - matchStation:velocity:orbit).

  // Point away from relative velocity vector
  lock steering to lookdirup(-matchVel:normalized, ship:facing:upvector).
  wait until vdot(-matchVel:normalized, ship:facing:forevector) >= 0.99.

  // Cancel velocity
  lock throttle to min(matchVel:mag / matchAccel, 1.0).

  wait until matchVel:z <= 0 and matchVel:mag <= residual and (residual = 0 or matchVel:mag > residual * 0.8).

  unlock throttle.
  set ship:control:pilotmainthrottle to 0.

  // TODO use RCS to cancel remaining dv

  unlock matchVel.

  lock steering to lookdirup(matchStation:position, ship:facing:upvector).
  wait until vdot(matchStation:position, ship:facing:forevector) >= 0.99.

  unlock steering.
  sas on.
}
