/////////////////////////////////////////////////////////////////////////////
// Rendezvous with target
/////////////////////////////////////////////////////////////////////////////
// Maneuver close to another vessel orbiting the same body.
/////////////////////////////////////////////////////////////////////////////

run lib_ui.
run lib_util.

if ship:body <> target:body {
  uiError("Rendezvous", "Target outside of SoI").
  local die is 1/0.
}

local accel is uiAssertAccel("Rendezvous").
local approachT is utilClosestApproach(ship, target).
local approachX is (positionat(target, approachT) - positionat(ship, approachT)):mag.

// Perform Hohmann transfer if necessary
if target:position:mag > 25000 and approachX > 25000 {
  uiDebug("Closest approach is " + round(approachX, 1)).
  local ri is abs(obt:inclination - target:obt:inclination).

  // Align if necessary
  if ri > 0.1 {
    uiBanner("Rendezvous", "Alignment burn").
    run node_inc_tgt.
    run node.
  }

  run node_hoh.

  if utilHasNextNode() = false {
    uiBanner("Rendezvous", "Transfer to phasing orbit").
    run circ_alt(target:altitude * 1.666).
    run node_hoh.
  }

  uiBanner("Rendezvous", "Transfer injection burn").
  run node.
}

// Finish Hohmann transfer if necessary
set approachT to utilClosestApproach(ship, target).
local aprVship is velocityat(ship, approachT):orbit.
local aprVtgt is velocityat(target, approachT):orbit.
local brakingT is (aprVtgt - aprVship):mag / accel.
run warp(approachT - time:seconds - brakingT).

sas off.

lock velR to vdot((ship:velocity:orbit - target:velocity:orbit), target:position:normalized) * target:position:normalized.
lock velT to (ship:velocity:orbit - target:velocity:orbit) - velR.

// Cancel transverse velocity
if velT:mag > 0.1 {
  uiBanner("Rendezvous", "Match velocities").

  lock steering to lookdirup(-velT, ship:facing:upvector).
  wait until vdot(-velT:normalized, ship:facing:forevector) >= 0.99.

  lock throttle to min(velT:mag/accel, 1.0).
  wait until velT:mag < 0.01.
  set throttle to 0.
  unlock steering.
}

unlock velT.
unlock velR.

// Turn toward target
lock steering to lookdirup(target:position, ship:facing:upvector).
wait until vdot(target:position:normalized, ship:facing:forevector) >= 0.99.

lock vel to (ship:velocity:orbit - target:velocity:orbit).

// Establish forward velocity
if vdot(vel, target:position) < 0.0 {
  uiBanner("Rendezvous", "Approach").

  lock throttle to min(vel:mag / accel, 1.0).
  wait until vdot(vel, target:position) > 0.0 and vel:mag > 5.
  set throttle to 0.
}

unlock steering.
sas on.
run warp((target:position:mag - 250) / vel:mag).

run dock.
