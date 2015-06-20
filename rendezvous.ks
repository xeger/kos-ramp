/////////////////////////////////////////////////////////////////////////////
// Rendezvous with target
/////////////////////////////////////////////////////////////////////////////
// Maneuver close to another vessel orbiting the same body.
/////////////////////////////////////////////////////////////////////////////

run lib_ui.
run lib_util.

if ship:body <> target:body {
  uiError("Rendezvous", "Target outside of SoI").
  reboot.
}

local accel is uiAssertAccel("Rendezvous").
local approachT is utilClosestApproach(ship, target).
local approachX is (positionat(target, approachT) - positionat(ship, approachT)):mag.

// Perform Hohmann transfer if necessary
if target:position:mag > 25000 and approachX > 25000 {
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

// Match velocity at closest approach
set approachT to utilClosestApproach(ship, target).
local aprVship is velocityat(ship, approachT):orbit.
local aprVtgt is velocityat(target, approachT):orbit.
local brakingT is (aprVtgt - aprVship):mag / accel.
run node_vel_tgt.
lock steering to lookdirup(nextnode:deltav, ship:facing:topvector).
wait until vdot(nextnode:deltav:normalized, ship:facing:vector) > 0.99.
unlock steering.
run warp(approachT - time:seconds - brakingT - 1).
run match.
remove nextnode.

// Make sure we don't drift apart
run dock.
