// Change to desired orbital inclinations by planning a burn at the ascending or
// descending node, whichever comes first.

// Desired orbital inclination
parameter target_inclination is 0.
runOncePath("lib_util").

if hasnode remove nextnode.

local ri is target_inclination-ship:orbit:inclination.
local t0 is time:seconds.
local dt is utilDtTrue(360-orbit:argumentOfPeriapsis).
local d2 is utilDtTrue(180-orbit:argumentOfPeriapsis).
if d2 < dt { set dt to d2. set ri to -ri. }
local t1 is t0+dt.

local v is velocityAt(ship, t1):orbit:mag.
local nv is v * sin(ri).
local pv is v * (cos(ri) - 1).

add node(t1, 0, nv, pv).
