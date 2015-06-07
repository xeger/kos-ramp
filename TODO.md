TODO
====
1. Debug auto-stage at launch (switch to more reliable until-loop)
2. Test physics warp, transfer
3. Finish rendezvous with a 'final approach' program

Scratchpad
==========

Tsiolkovsky burn duration
-------------------------

Derived from http://wiki.kerbalspaceprogram.com/wiki/Tutorial:Advanced_Rocket_Design#Delta-V

Basic idea: compute vessel Isp; mass-flow rate of engines; total mass burn;
derive burn duration using Tsiolkovsky formula.

Implemented, but it doesn't work; it gives bogus duration. Need to debug...

    list engines in engs.
    local thrustSum is 0.0.
    local denomSum is 0.0.

    FOR eng IN engs
    {
      local thrust is eng:maxthrust * eng:thrustlimit.
      set thrustSum to thrustSum + thrust.
      set denomSum to denomSum + (thrust / (eng:isp * 9.82)).
    }.

    local Isp is thrustSum / denomSum.
    local massBurn is ((ship:mass * 1000) / constant():e ^ (nd:deltav:mag / Isp)).
    local tsiol is ((ship:mass* 1000) - massBurn) / (thrustSum / Isp).
