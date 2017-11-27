/////////////////////////////////////////////////////////////////////////////
// Docking functions
/////////////////////////////////////////////////////////////////////////////
// Shared logic for docking. Assumes that every ship has one port!
/////////////////////////////////////////////////////////////////////////////

// Constant docking parameters
global dock_scale is 25.   // alignment speed scaling factor (m)
global dock_start is 30.   // ideal start distance (m) & approach speed scaling factor
global dock_final is 1.    // final-approach distance (m)
global dock_algnV is 2.5.  // max alignment speed (m/s)
global dock_apchV is 1.    // max approach speed (m/s)
global dock_dockV is 0.1.  // final approach speed (m/s)
global dock_predV is 0.01. // pre dock speed (m/s)

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

  // Control from myPort
  partsControlFromDockingPort(myPort).

  sas off.
  lock steering to lookdirup(-hisPort:portfacing:forevector, hisPort:portfacing:upvector).
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
  clearvecdraws().
}

// Back off from target in order to approach from the correct side.
function dockBack {
  parameter backPos, backVel.

  //Move away from the station when backing more than start distance
  if backPos:z < -dock_start {
    if abs(backPos:x) < 50 {
      local vWantX is (backPos:X / abs(backPos:X)) * max(dock_dockV, 0.5).
      set dock_X1:setpoint to vWantX.
    }
    else set dock_X1:setpoint to 0.
    set ship:control:starboard to -1 * dock_X1:update(time:seconds, backVel:X).
  }

  set dock_Z:setpoint to dock_algnV.
  set ship:control:fore to -dock_Z:update(time:seconds, backVel:Z).
}

// Center docking ports in X/Y while slowly moving forward
function dockAlign {
  parameter alignPos, alignVel.

  // Taper X/Y/Z speed according to distance from target
  local vScaleX is min(abs(alignPos:X / dock_scale), dock_algnV).
  local vScaleY is min(abs(alignPos:Y / dock_scale), dock_algnV).
  local vScaleZ is min(abs(alignPos:Z / dock_start), dock_algnV).

  // Never align slower than final-approach speed
  local vWantX is -(alignPos:X / abs(alignPos:X)) * max(dock_dockV, dock_algnV * vScaleX).
  local vWantY is -(alignPos:Y / abs(alignPos:Y)) * max(dock_dockV, dock_algnV * vScaleY).
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
    if not dockPending(ship:controlpart) {
      // Final approach: barely inch forward!
      set vWantZ to -dock_dockV.
    }
    else {
      set vWantZ to -dock_predV.
    }
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
//   - if current control part is a port, use it.
//   - if target is a vessel, find an unoccupied port that matches one in our ship
//   - (else target is already a port)
//   - find port on ship that fits the target port
function dockChoosePorts {
  local myPort is 0.
  local hisPort is 0.
  local hisPorts is list().
  local myPorts is list().

  // Docking port is already targeted
  if target:istype("Part") 
     and target:MODULES:CONTAINS("ModuleDockingNode") 
     and target:state = "Ready" { 
    hisPorts:add(target).
  }
  else if target:istype("Vessel") { // ship is targeted; list all free ports.
    for port in target:dockingports { 
      if port:state = "Ready" hisPorts:add(port).
    }
  }

  // List all my ship ports not occupied. 
  if SHIP:CONTROLPART:MODULES:CONTAINS("ModuleDockingNode") and 
  not SHIP:CONTROLPART:STATE:CONTAINS("docked") myPorts:add(SHIP:CONTROLPART).
  else {  
    for port in ship:dockingports {
      if not port:state:contains("docked") myPorts:add(port).
    }
  }

  // Checks if both ships have ports. 
  if myPorts:LENGTH = 0 OR hisPorts:LENGTH = 0 {
    return 0.
  }

  // Iterates through my ship ports and try to match with a port in target ship.
  if hisPort = 0 { 
    for myP in myPorts {
      if myPort = 0 {
        for hisP in hisPorts {
          if hisPort = 0 and hisP:NODETYPE = myP:NODETYPE {
            set myPort to myP.
            set hisPort to hisP.
          }
        }
      }
    }
  }
  else{ // Target port was pre-selected. Just find a suitable port in my ship
    for myP in myPorts {
      if myPort = 0 and hisPort:NODETYPE = myP:NODETYPE {
        set myPort to myP. 
      }
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

  set residual to max(0.1, residual). // Minimum residual value allowed.
  set RCSTheresold to 1. // Below this speed will use RCS

  // Don't let unbalanced RCS mess with our velocity
  rcs off.
  sas off.

  local matchStation is 0.
  if target:istype("Part") {
    set matchStation to target:ship.
  } else {
    set matchStation to target.
  }

  local matchAccel is uiAssertAccel("Dock").
  local lock matchVel to (ship:velocity:orbit - matchStation:velocity:orbit).

  if matchVel:mag > residual + RCSTheresold {
    // Point away from relative velocity vector
    local lock steerDir to utilFaceBurn(lookdirup(-matchVel, ship:facing:upvector)).
    lock steering to steerDir.
    wait until utilIsShipFacing(steerDir:vector).

    // Cancel velocity
    local v0 is matchVel:mag.
    lock throttle to min(matchVel:mag / matchAccel, 1.0).
    wait 0.1. // Let some time pass so the difference in speed is correcly acounted.
    // Stops the engines if reach near residual speed or if speed starts increasing. (May happens with some cases where the ship is not perfecly aligned with matchVel and residual is very low)
    until (matchVel:mag <= (residual + RCSTheresold)) or (matchVel:mag > v0) {
      set v0 to matchVel:mag.
      wait 0.1. //Assure measurements are made some time apart. 
    }

    lock throttle to 0.
    unlock throttle.
  }
  // Use RCS to cancel remaining dv
  unlock steering.
  utilRCSCancelVelocity(matchVel@,residual,15).

  unlock matchVel.
}

