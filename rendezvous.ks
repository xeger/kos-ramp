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

// Match velocity at closest approach
local approachT is utilClosestApproach(ship, target).
local aprVship is velocityat(ship, approachT):orbit.
local aprVtgt is velocityat(target, approachT):orbit.
local brakingT is (aprVtgt - aprVship):mag / accel.
run warp(approachT - time:seconds - brakingT).
run match.

// Make sure we don't drift apart
run dock.
