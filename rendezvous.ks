/////////////////////////////////////////////////////////////////////////////
// Rendezvous with target
/////////////////////////////////////////////////////////////////////////////
// Maneuver close to another vessel orbiting the same body.
/////////////////////////////////////////////////////////////////////////////

run lib_ui.
run lib_util.

if ship:body <> target:body {
  uiError("Rendezvous", "Target outside of SoI").
  wait 5.
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
// TODO make node_vel_tgt more accurate and use it here (currently only used for steering guidance)
set approachT to utilClosestApproach(ship, target).
local aprVship is velocityat(ship, approachT):orbit.
local aprVtgt is velocityat(target, approachT):orbit.
local brakingT is (aprVtgt - aprVship):mag / accel.
sas off.
run node_vel_tgt.
lock steering to lookdirup(nextnode:deltav, ship:facing:topvector).
wait until vdot(nextnode:deltav:normalized, ship:facing:vector) > 0.99.
unlock steering.
remove nextnode.
run warp(approachT - time:seconds - brakingT).

run approach.
wait until target:position:mag < 150.
run dock.
