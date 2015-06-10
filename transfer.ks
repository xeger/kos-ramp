// Hohmann transfer to a satellite of the vessel's SoI body.

run lib_ui.

local ri is abs(obt:inclination - target:obt:inclination).

if ri > 0.1 {
  uiBanner("Transfer", "Alignment burn").
  run node_inc_tgt.
  run node.
}

run node_hoh.
uiBanner("Transfer", "Injection burn").
run node.

wait 1. // TODO let warp deal with ship under acceleration
until obt:transition <> "encounter" {
  run warp(eta:transition+1).
}

uiBanner("Transfer", "Braking burn").
run circ.
