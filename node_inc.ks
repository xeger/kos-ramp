// Change inclination by planning a burn at the ascending or
// descending node, whichever comes first.

// TODO: Consider dV for both nodes and maybe select the more efficient (when orbit:eccentricity is high)

// Desired orbital inclination,
// default is zero or match target if selected
parameter target_inclination is "".

runOncePath("lib_util").
utilRemoveNodes().

local di is 0. // inclination difference
local dt is 0. // time to DN
local d2 is 0. // time to AN
local t0 is time:seconds.

if hasTarget and target_inclination = ""
{
	local sp is ship:position-body:position.
	local sv is ship:velocity:orbit.
	local tp is target:position-body:position.
	local tv is target:velocity:orbit.
	local sn is vcrs(sv, sp). // normal vector
	local tn is vcrs(tv, tp).
	local ln is vcrs(sn, tn). // from body to DN

	set di to vang(sn, tn).
	set dt to utilDtTrue(orbit:trueAnomaly+180-vang(sp, ln)).
	set d2 to utilDtTrue(orbit:trueAnomaly+180+vang(sp,-ln)).
}
else
{
	local i0 is orbit:inclination.
	local i1 is 0.
	if target_inclination <> "" set i1 to target_inclination.

	set di to i1-i0.
	set dt to utilDtTrue(360-orbit:argumentOfPeriapsis).
	set d2 to utilDtTrue(180-orbit:argumentOfPeriapsis).
}

if d2 < dt { set dt to d2. set di to -di. }
local t1 is t0+dt.

local v is velocityAt(ship, t1):orbit:mag.
local nv is v * sin(di).
local pv is v *(cos(di)-1).

add node(t1, 0, nv, pv).
