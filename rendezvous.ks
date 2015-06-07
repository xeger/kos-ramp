// Rendezvous with another vessel orbiting the same body

run ui.

local ri is abs(obt:inclination - target:obt:inclination).

if ri > 0.1 {
  uiMessage("Rendezvous", "Match planes").
  run node_inc_tgt.
  run node.
}

run node_hoh.
uiMessage("Rendezvous", "Hohmann transfer").
run node.

run node_vel_tgt.
uiMessage("Rendezvous", "Match velocities").
run node.

uiError("Rendezvous", "UNFINISHED SCRIPT! RUN FOR YOUR LIFE!")
local die is 1/0.
