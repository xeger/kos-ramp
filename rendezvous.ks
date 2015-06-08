// Rendezvous with another vessel orbiting the same body

run lib_ui.

local ri is abs(obt:inclination - target:obt:inclination).

if ri > 0.1 {
  uiBanner("Rendezvous", "Alignment burn").
  run node_inc_tgt.
  run node.
}

// TODO if > 5 orbits, switch to phasing orbit

run node_hoh.
uiBanner("Rendezvous", "Injection burn").
run node.

run node_vel_tgt.
uiBanner("Rendezvous", "Braking burn").
run node.

uiError("Rendezvous", "UNFINISHED SCRIPT! RUN FOR YOUR LIFE!").
local die is 1/0.
