// Hohmann transfer to a satellite of the vessel's SoI body.

run ui.

local ri is abs(obt:inclination - target:obt:inclination).

if ri > 0.1 {
  uiBanner("Transfer", "Alignment burn").
  run node_inc_tgt.
  run node.
}

run node_hoh.
uiBanner("Transfer", "Injection burn").
run node.

until obt:transition <> "escape" {
  warp(eta:transition+1).
}
until obt:transition <> "encounter" {
  warp(eta:transition+1).
}

run node_circ.
uiBanner("Transfer", "Braking burn").
run node.
