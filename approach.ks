/////////////////////////////////////////////////////////////////////////////
// Approach
/////////////////////////////////////////////////////////////////////////////
// Kills transverse velocity w/r/t target and establishes forward velocity.
/////////////////////////////////////////////////////////////////////////////

runoncepath("lib_util").
runoncepath("lib_dock").
runoncepath("lib_ui").

//Those functions are for use by this program ONLY!
function CancelVelT {
  uiBanner("Maneuver", "Match transverse velocity").
  if velT:mag > 1 {
    local lock steerDir to utilFaceBurn(lookdirup(-velT:normalized, ship:facing:upvector)).
    lock steering to steerDir.
    wait until utilIsShipFacing(steerDir:vector).
    
    //Preditcs time to complete the burn with 50% plus error
    local tP is ( (velT:mag / accel)*1.5 ) + time:seconds.

    lock throttle to min(velT:mag / accel, 1.0).
    wait until (velT:mag < 0.5) or (time:seconds > tP).
    lock throttle to 0.
  }
  // Finish with RCS 
  utilRCSCancelVelocity(velT@).
  unlock throttle.
  unlock steering.
}

function CancelVel {
  uiBanner("Maneuver", "Match velocity").
  if vel:mag > 1 {
    local lock steerDir to utilFaceBurn(lookdirup(-vel:normalized, ship:facing:upvector)).
    lock steering to steerDir.
    wait until utilIsShipFacing(steerDir:vector).

    //Preditcs time to complete the burn with 50% plus error
    local tP is ( (vel:mag / accel)*1.5 ) + time:seconds.

    lock throttle to min(vel:mag / accel, 1.0).
    wait until (vel:mag < 0.5) or (time:seconds > tP).
    lock throttle to 0.
  }
  // Finish with RCS 
  utilRCSCancelVelocity(vel@).
  unlock throttle.
  unlock steering.
}

function GetCloser {
  uiBanner("Maneuver", "Accelerate towards target").
  // Make sure the ship is approaching target
  local dot is vdot(target:position, velR).
  until dot >= 0 {
      local lock steerDir to utilFaceBurn(lookdirup(target:position, ship:facing:upvector)).
      lock steering to steerDir.
      wait until utilIsShipFacing(steerDir:vector,1,1).
      lock throttle to 1.
      set dot to vdot(target:position, velR).
  }
  lock throttle to 0.

  //Accelerate towards target
  local lock steerDir to utilFaceBurn(lookdirup(target:position, ship:facing:upvector)).
  lock steering to steerDir.
  wait until utilIsShipFacing(steerDir:vector,1,0.5).
  local t0 is time:seconds.
  lock throttle to 1.
  wait until target:position:mag / velR:mag < (time:seconds - t0 + 60) or vel:mag > 100 .
  lock throttle to 0.

  //Cancel any small traverse speed that may had been introduced by previous burn
  utilRCSCancelVelocity(velT@,0.01,5).
  unlock throttle.
  unlock steering.
}

function BrakeForEncounter {
  //Turn back to brake 
  local lock steerDir to utilFaceBurn(lookdirup(-vel:normalized, ship:facing:upvector)).
  lock steering to steerDir.
  wait until utilIsShipFacing(steerDir:vector) .
  local stopDistance is 0.5 * accel * (vel:mag / accel)^2.
  local dt is ((target:position:mag - stopDistance) / vel:mag) - 5.
  if dt > 0 {
    if dt > 60 {
      uiBanner("Maneuver", "Warping to brake").
      runpath("warp",dt).
    }
    else {
      uiBanner("Maneuver", "Waiting " + round(dt) + " seconds to brake").
      wait dt.
    }
  }

  uiBanner("Maneuver", "Braking.").
  dockMatchVelocity(max(1.0, min(5.0, target:position:mag / 60.0))).
  unlock throttle.
  unlock steering.
}

//////////////////////////////////////
// Main program
/////////////////////////////////////


local accel is uiAssertAccel("Maneuver").
lock vel to (ship:velocity:orbit - target:velocity:orbit).
lock velR to vdot(vel, target:position:normalized) * target:position:normalized.
lock velT to vxcl(target:position:normalized,vel).



// Don't let unbalanced RCS mess with our velocity
rcs off.
sas off.


// Main logic checks
local lock GoingTowardsTarget to  vang(target:position,vel) < 10.   //Ship travelling towards target

local lock IsNearTarget to  (target:position:mag < 150) OR               //Ship is VERY close to target.
                            (target:position:mag < 850 and               //Target is near
                            (vel:mag > 1 and vel:mag < 10) and           //Target relative speed is reasonable
                            GoingTowardsTarget).                       //The ship moves towards target

until IsNearTarget {

  until GoingTowardsTarget() {

    // If ship is in nearby vicinty of target, or going away from it, cancel relative speed.
    if target:position:mag / vel:mag < 30 or vang(target:position,vel) > 90 { 
      CancelVel().
    } 

    // Cancel transverse velocity before attemps to get closer
    if velT:mag > 1 { 
      CancelVelT().
    }
    
    if not (GoingTowardsTarget and vel:mag > 5) {
    // Burn in direction to target at a sensible speed.
    GetCloser().
    }
    wait 0. 
  }

  BrakeForEncounter().
  wait 0.
}

unlock velR.
unlock velT.
unlock vel.

// Release all controls to be safe.
unlock steering.
unlock throttle.
set ship:control:neutralize to true.
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.

sas on.