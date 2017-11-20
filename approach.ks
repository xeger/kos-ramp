/////////////////////////////////////////////////////////////////////////////
// Approach
/////////////////////////////////////////////////////////////////////////////
// Kills transverse velocity w/r/t target and establishes forward velocity.
/////////////////////////////////////////////////////////////////////////////

//Those functions are for use by this program ONLY!
function CancelVelT {
  lock steering to lookdirup(-velT:normalized, ship:facing:upvector).
  wait until vdot(-velT:normalized, ship:facing:forevector) >= 0.99 and ship:angularvel:mag < 0.1. 

  uiBanner("Maneuver", "Match transverse velocity").
  lock throttle to min(velT:mag / accel, 1.0).
  wait until velT:mag < 0.5.
  lock throttle to 0.

  // Finish with RCS 
  utilRCSCancelVelocity(velT@).
}

function CancelVel {
  lock steering to lookdirup(-vel:normalized, ship:facing:upvector).
  wait until vdot(-vel:normalized, ship:facing:forevector) >= 0.99 and ship:angularvel:mag < 0.1. 

  uiBanner("Maneuver", "Match velocity").
  lock throttle to min(vel:mag / accel, 1.0).
  wait until vel:mag < 0.5.
  lock throttle to 0.

  // Finish with RCS 
  utilRCSCancelVelocity(vel@).
}

function GetCloser {
  uiBanner("Maneuver", "Begin approach").
  // Make sure the ship is approaching target
  local dot is vdot(target:position, velR).
  until dot >= 0 {
      lock steering to lookdirup(target:position, ship:facing:upvector).
      wait until vdot(target:position:normalized, ship:facing:forevector) >= 0.99 and ship:angularvel:mag < 0.01. 
      lock throttle to 1.
      set dot to vdot(target:position, velR).
  }
  lock throttle to 0.

  lock steering to lookdirup(target:position, ship:facing:upvector).
  wait until vdot(target:position:normalized, ship:facing:forevector) >= 0.99 and ship:angularvel:mag < 0.01. 

  uiBanner("Maneuver", "Accelerate towards target").
  local t0 is time:seconds.
  lock throttle to 1.
  wait until target:position:mag / velR:mag < (time:seconds - t0 + 30) or vel:mag > 50.
  lock throttle to 0.

  lock steering to lookdirup(-vel:normalized, ship:facing:upvector).
  wait until vdot(-vel:normalized, ship:facing:forevector) >= 0.99 and ship:angularvel:mag < 0.01. 
  local stopDistance is 0.5 * accel * (vel:mag / accel)^2.
  local dt is ((target:position:mag - stopDistance) / vel:mag) - 15.
  if dt > 0 {
    if dt > 60 {
      uiBanner("Maneuver", "Warping to brake").
      run warp(dt).
    }
    else {
      uiBanner("Maneuver", "Waiting " + dt + " seconds to brake").
      wait dt.
    }
  }

  uiBanner("Maneuver", "Braking.").
  dockMatchVelocity(max(1.0, min(10.0, target:position:mag / 60.0))).
}


run once lib_dock.
run once lib_ui.

local accel is uiAssertAccel("Maneuver").
lock vel to (ship:velocity:orbit - target:velocity:orbit).
lock velR to vdot(vel, target:position:normalized) * target:position:normalized.
lock velT to vxcl(target:position:normalized,vel).


// Don't let unbalanced RCS mess with our velocity
rcs off.
sas off.


uiBanner("Maneuver", "Target to far, manouvering to match velocity.").
if target:position:mag > 5000 or vel:mag > 25 {
  run node_vel_tgt.
  run node.
  sas off.
}

local IsNear is False.

until IsNear {

  sas off.
  rcs off.

  if target:position:mag / vel:mag < 30 { // Nearby target; come to a stop first
    CancelVel().
  } 

  if velT:mag > 1 { // Cancel transverse velocity first
    CancelVelT().
  }

  GetCloser().

  if    vdot(target:position,vel) > 0.9 //Ship is going towards the target
    and (vel:mag > 1 and vel:mag < 10)  //Target relative speed is reasonable
    and target:position:mag < 500 {     //Target is near
      SET IsNear to True .
  } 

  wait 0.

}

unlock velR.
unlock velT.
unlock vel.

sas on.
