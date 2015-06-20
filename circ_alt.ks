/////////////////////////////////////////////////////////////////////////////
// Circularize to altitude.
/////////////////////////////////////////////////////////////////////////////
// (Re)circularizes at a designated altitude, immediately if possible, else
// at the next apsis.
/////////////////////////////////////////////////////////////////////////////

parameter alt.

local circApsis is "apoapsis".

if obt:eccentricity < 0.1 {
  run node_alt(alt).
  local prograde is nextnode:prograde.
  run node.

  if prograde < 0 {
    run node_apo(obt:periapsis).
  } else {
    run node_peri(obt:apoapsis).
  }
  run node.
} else {
  uiWarning("Circ", "Unfinished program!").
  reboot.
}
