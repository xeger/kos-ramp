/////////////////////////////////////////////////////////////////////////////
// Approach
/////////////////////////////////////////////////////////////////////////////
// Kills transverse velocity w/r/t target and establishes forward velocity.
/////////////////////////////////////////////////////////////////////////////

run once lib_ui.

local accel is uiAssertAccel("Maneuver").
lock vel to (ship:velocity:orbit - target:velocity:orbit).
lock velR to vdot(vel, target:position:normalized) * target:position:normalized.
lock velT to vel - velR.

// Don't let unbalanced RCS mess with our velocity
rcs off.
sas off.

// HACK: distinguish between targeted vessel and targeted port using mass > 2 tonnes
if target:mass < 2 {
  set target to target:vessel.
}

if target:position:mag / vel:mag < 15 {
  // Nearby target; come to a stop first
  lock steering to lookdirup(-vel:normalized, ship:facing:upvector).
  wait until vdot(-vel:normalized, ship:facing:forevector) >= 0.99.

  uiBanner("Maneuver", "Match velocity").
  lock throttle to min(vel:mag / accel, 1.0).
  wait until vel:mag < 0.5.
  set throttle to 0.
} else if velT:mag > 1 {
  // Far-away target; cancel transverse velocity first
  lock steering to lookdirup(-velT:normalized, ship:facing:upvector).
  wait until vdot(-velT:normalized, ship:facing:forevector) >= 0.99.

  uiBanner("Maneuver", "Match transverse velocity").
  lock throttle to min(velT:mag / accel, 1.0).
  wait until velT:mag < 0.5.
  set throttle to 0.
}

uiBanner("Maneuver", "Begin approach").
lock dot to vdot(target:position, velR).
if dot < 0 {
  lock steering to lookdirup(-velR:normalized, ship:facing:upvector).
  wait until vdot(-velR:normalized, ship:facing:forevector) >= 0.99.
  unlock steering.
  sas on.
  lock throttle to 1.
  wait until dot > 0.
  set throttle to 0.
  sas off.
}
unlock dot.

lock steering to lookdirup(velR:normalized, ship:facing:upvector).
wait until vdot(velR:normalized, ship:facing:forevector) >= 0.99.

local t0 is time:seconds.
lock throttle to 1.
wait until target:position:mag / velR:mag < (time:seconds - t0 + 5) or vel:mag > 100.
set throttle to 0.
local dt is time:seconds - t0.

lock steering to lookdirup(-velR:normalized, ship:facing:upvector).
wait until vdot(-velR:normalized, ship:facing:forevector) >= 0.99.
local stopDistance is 0.5 * accel * (vel:mag / accel)^2.
local dt is (target:position:mag - stopDistance - 100) / vel:mag.
run warp(dt).

run match.

unlock velR.
unlock velT.
unlock vel.

sas on.
