/////////////////////////////////////////////////////////////////////////////
// Match velocity with target
/////////////////////////////////////////////////////////////////////////////
// Cancel most velocity with respect to target. Any residual speed will be
// small (typically < 1 m/s) and pointed directly at the target.
/////////////////////////////////////////////////////////////////////////////

run lib_ui.
run lib_util.

sas off.

local accel is uiAssertAccel("Rendezvous").
lock vel to (ship:velocity:orbit - target:velocity:orbit).
lock velR to vdot(vel, target:position:normalized) * target:position:normalized.
lock velT to vel - velR.

// Establish forward velocity
if vdot(vel, target:position) < 0.0 {
  uiBanner("Maneuver", "Braking burn").

  lock steering to lookdirup(target:position:normalized, ship:facing:upvector).
  wait until vdot(target:position:normalized, ship:facing:forevector) >= 0.95.

  lock throttle to min(vel:mag / accel, 1.0).
  wait until vdot(vel, target:position) > 0.0.
  set throttle to 0.
}

// Cancel transverse velocity
if velT:mag > 0.1 {
  uiBanner("Maneuver", "Match transverse velocity").

  lock steering to lookdirup(-velT:normalized, ship:facing:upvector).
  wait until vdot(-velT:normalized, ship:facing:forevector) >= 0.95.

  lock throttle to min(velT:mag/accel, 1.0).
  wait until velT:mag < 1.
  set throttle to 0.
  unlock steering.
}

// Cut forward velocity if necessary
if velR:mag * 60 > target:position:mag {
  uiBanner("Maneuver", "Match radial velocity").

  lock steering to lookdirup(-velR:normalized, ship:facing:upvector).
  wait until vdot(-vel:normalized, ship:facing:forevector) >= 0.99.

  lock throttle to min(velR:mag / accel, 1.0).
  wait until vdot(vel, target:position) > 0.0 and vel:mag > 0.
  set throttle to 0.
}

unlock vel.
unlock velT.
unlock velR.

unlock steering.
sas on.
