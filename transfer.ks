/////////////////////////////////////////////////////////////////////////////
// Transfer to target
/////////////////////////////////////////////////////////////////////////////
// Hohmann transfer to a satellite of the vessel's SoI body.
/////////////////////////////////////////////////////////////////////////////

run lib_ui.

if ship:body <> target:body {
  uiError("Transfer", "Target outside of SoI").
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

until obt:transition <> "encounter" {
  run warp(eta:transition+1).
}

// TODO - deal with collision (radial burn)

uiBanner("Transfer", "Transfer braking burn").
run circ.
