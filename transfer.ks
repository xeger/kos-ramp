/////////////////////////////////////////////////////////////////////////////
// Transfer to target
/////////////////////////////////////////////////////////////////////////////
// Hohmann transfer to a satellite of the vessel's SoI body.
/////////////////////////////////////////////////////////////////////////////

run lib_ui.

if ship:body <> target:body {
  uiError("Transfer", "Target outside of SoI").
  local die is 1 / 0.
}

local ri is abs(obt:inclination - target:obt:inclination).

if ri > 0.1 {
  uiBanner("Transfer", "Alignment burn").
  run node_inc_tgt.
  run node.
}

run node_hoh.
uiBanner("Transfer", "Transfer injection burn").
run node.

until obt:transition <> "encounter" {
  run warp(eta:transition+1).
}

uiBanner("Transfer", "Transfer braking burn").
run circ.
