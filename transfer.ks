/////////////////////////////////////////////////////////////////////////////
// Transfer to target
/////////////////////////////////////////////////////////////////////////////
// Hohmann transfer to a satellite of the vessel's SoI body.
/////////////////////////////////////////////////////////////////////////////

run once lib_ui.

if ship:body <> target:body {
  uiError("Transfer", "Target outside of SoI").
  wait 5.
  reboot.
}

local ri is abs(obt:inclination - target:obt:inclination).

if ri > 0.25 {
  uiBanner("Transfer", "Align planes with " + target:name).
  run node_inc_tgt.
  run node.
}

run node_hoh.
uiBanner("Transfer", "Transfer injection burn").
run node.

until obt:transition <> "ENCOUNTER" {
  run warp(eta:transition+1).
}

// Deal with collisions and retrograde orbits (sorry this script can't do free return)
local minperi is (body:atm:height + (body:radius * 0.3)).

if ship:periapsis < minperi or ship:obt:inclination > 90 {
  sas off.
  LOCK STEERING TO heading(90,0).
  wait 10.
  LOCK deltaPct TO (ship:periapsis - minperi) / minperi.
  LOCK throttle TO max(1,min(0.1,deltaPct)).
  Wait Until ship:periapsis > minperi.
  LOCK throttle to 0.
  UNLOCK throttle.
  UNLOCK STEERING.
  sas on.
}

uiBanner("Transfer", "Transfer braking burn").
run circ.
