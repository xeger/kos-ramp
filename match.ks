/////////////////////////////////////////////////////////////////////////////
// Match velocity with target
/////////////////////////////////////////////////////////////////////////////
// Cancel most velocity with respect to target. Any residual speed will be
// small (typically < 1 m/s) and pointed directly at the target.
/////////////////////////////////////////////////////////////////////////////

run lib_ui.
run lib_util.

// Don't let unbalanced RCS mess with our velocity
rcs off.
sas off.

// HACK: distinguish between currently-targeted vessel and port using mass > 2 tonnes
local station is 0.
if target:mass < 2 {
  set station to target:ship.
} else {
  set station to target.
}

local accel is uiAssertAccel("Maneuver").
lock vel to (ship:velocity:orbit - station:velocity:orbit).

lock steering to lookdirup(-vel:normalized, ship:facing:upvector).
wait until vdot(-vel:normalized, ship:facing:forevector) >= 0.99.

uiBanner("Maneuver", "Braking burn").
lock throttle to min(vel:mag / accel, 1.0).
when vel:mag < 3 then {
  unlock steering.
  sas on.
  lock throttle to min(vel:mag / accel, 0.1).
}
wait until vel:mag < 0.2 and vel:z <= 0.
set throttle to 0.

// TODO use RCS to cancel remaining dv

unlock vel.

unlock steering.
sas on.
