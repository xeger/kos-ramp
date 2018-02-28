// Change inclination by planning a burn at the ascending or
// descending node, whichever comes first.

// Desired orbital inclination,
// default is zero or match target if selected
parameter incl is "".

runOncePath("lib_util").
utilRemoveNodes().

local di is 0. // inclination difference (target-current)
local ta is 0. // angle from periapsis to DN (burn in normal direction here)
local t0 is time:seconds.
local i0 is orbit:inclination.
local sp is ship:position-body:position.
local sv is ship:velocity:orbit.
local sn is vcrs(sv, sp). // our plane normal vector

if incl <> "" or not hasTarget
{
	local i1 is 0.
	if incl <> "" set i1 to incl.

	set di to i1-i0.
	set ta to -orbit:argumentOfPeriapsis.
}
else
{
	local i1 is target:orbit:inclination.
	local tp is target:position-body:position.
	local tv is target:velocity:orbit.
	local tn is vcrs(tv, tp). // its plane normal vector
	local ln is vcrs(tn, sn). // from AN to DN

	set di to utilVecAng(sn, tn, ln).
	set ta to utilVecAng(sp, ln, sn).
	set ta to ta + orbit:trueAnomaly.
}

set ta to utilAngleTo360(ta).
if ta < orbit:trueAnomaly { set ta to ta+180. set di to -di. }
local dt is utilDtTrue(ta).
local t1 is t0+dt.

local v is velocityAt(ship, t1):orbit.
local dv is v*angleAxis(-di,positionAt(ship,t1)-body:position)-v.

if dt < 5+.5*dv:mag*ship:mass/max(0.1,ship:availableThrust) {
	set ta to ta+180.
	set di to -di.
	set dt to utilDtTrue(ta).
	set t1 to t0+dt.
	set v  to velocityAt(ship, t1):orbit.
	set dv to v*angleAxis(-di,positionAt(ship,t1)-body:position)-v.
}
//TODO: use node closer to apoapsis (ta > 90 and < 270) for highly eccentric orbits

local pv is vdot(dv,v:normalized).
local nv is vdot(dv,sn:normalized).
local rv is vdot(dv,vcrs(sn,v):normalized).
add node(t1, rv, nv, pv).
