/////////////////////////////////////////////////////////////////////////////
// Match velocity with target
/////////////////////////////////////////////////////////////////////////////
// Cancel most velocity with respect to target. Any residual speed will be
// small (typically < 1 m/s) and pointed directly at the target.
/////////////////////////////////////////////////////////////////////////////

run lib_ui.
run lib_util.

sas off.

local accel is uiAssertAccel("Maneuver").
lock vel to (ship:velocity:orbit - target:velocity:orbit).
lock velR to vdot(vel, target:position:normalized) * target:position:normalized.
lock velT to vel - velR.

lock steering to lookdirup(-vel:normalized, ship:facing:upvector).
wait until vdot(-vel:normalized, ship:facing:forevector) >= 0.99.

uiBanner("Maneuver", "Braking burn").
lock throttle to min(vel:mag / accel, 1.0).
when vel:mag < 3 then {
  unlock steering.
  sas on.
  lock throttle to min(vel:mag / accel, 0.1).
}
wait until vel:mag < 1.
set throttle to 0.

// TODO use RCS to cancel remaining dv

unlock vel.
unlock velT.
unlock velR.

unlock steering.
sas on.
