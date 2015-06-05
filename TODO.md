TODO
====
1. Debug auto-stage at launch; don't orient to circ node until out of atmo!
2. smoke test Hohmann transfer w/fudge factor
3. Match velocity at closest approach
4. Physics warp when needed
5. Fine-tune closest approach

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
