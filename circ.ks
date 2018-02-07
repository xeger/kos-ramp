/////////////////////////////////////////////////////////////////////////////
// Circularize.
/////////////////////////////////////////////////////////////////////////////
// Circularizes at the nearest apsis.
/////////////////////////////////////////////////////////////////////////////

run once lib_ui.
run once lib_util.

IF Career():CANMAKENODES {
  if obt:transition = "ESCAPE" or eta:periapsis < eta:apoapsis {
    run node_apo(obt:periapsis).
  } else {
    run node_peri(obt:apoapsis).
  }

  run node.

  uiBanner("Circ", "Circularized; e=" + round(ship:obt:eccentricity, 3)).
} ELSE {
  sas off.
  lock steering to ship:prograde.
  uiBanner("Circ", "Coast to apoapsis.").
  wait until utilIsShipFacing(ship:prograde:forevector).
  run warp(eta:apoapsis - 30).
  wait until utilIsShipFacing(ship:prograde:forevector).
  // TODO be less lazy; calculate ideal delay for perfect circularization
  wait until eta:apoapsis < 15.
  uiBanner("Circ", "Burn to raise periapsis.").
  set ship:control:pilotmainthrottle to max(1, 2 * ship:obt:eccentricity).
  local height is ship:obt:apoapsis + 500.
  WAIT UNTIL ship:obt:eccentricity < 0.01 or ship:obt:apoapsis > height.
  set ship:control:pilotmainthrottle to 0.
  sas on.
}
