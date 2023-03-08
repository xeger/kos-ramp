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

if incl <> "" or not hasTarget {
	local i1 is 0.
	if incl <> "" set i1 to incl.

	set di to i1 - i0.
	set ta to -orbit:argumentOfPeriapsis.
} else {
	local sp is ship:position - body:position.
	local tp is target:position - body:position.
	local sv is ship:velocity:orbit.
	local tv is target:velocity:orbit.
	local sn is vcrs(sv, sp). // our normal vector
	local tn is vcrs(tv, tp). // its normal vector
	local ln is vcrs(tn, sn). // from AN to DN

	set di to vang(sn, tn).
	set ta to vang(sp, ln).
	// fix sign by comparing cross-product to normal vector (the angle is either 0 or 180)
	if vang(vcrs(sp, ln), sn) < 90 set ta to -ta.
	set ta to ta + orbit:trueAnomaly.

	// DEBUG:
	// clearVecDraws().
	// vecDraw(ship:position, sn:normalized * orbit:semiMajorAxis, blue,  "sn", 1, true).
	// vecDraw(ship:position, tn:normalized * orbit:semiMajorAxis, green, "tn", 1, true).
	// vecDraw(ship:position, ln:normalized * orbit:semiMajorAxis, red,   "ln=tn * sn", 1, true).
	// vecDraw(ship:position, sp:normalized * orbit:semiMajorAxis, white, "sp", 1, true).
	// vecDraw(ship:position, vcrs(sp, ln):normalized * orbit:semiMajorAxis*.5, yellow, "sp * ln", 1, true, 0.3).
	// set vecDraw(body:position, ln:normalized * orbit:semiMajorAxis,
	// red, "ln", 1, true):startUpdater to { return body:position. }.
}

set ta to utilAngleTo360(ta).
if ta < orbit:trueAnomaly { set ta to ta + 180. set di to -di. }
local dt is utilDtTrue(ta).
local t1 is t0 + dt.

local v is velocityAt(ship, t1):orbit:mag.
local nv is v * sin(di).
local pv is v *(cos(di) - 1).

// FIXME: nv + pv for highly eccentric orbits

// TODO: check burn time and use the other node if we do not have anough time
// TODO: use node closer to apoapsis (ta > 90 and < 270) for eccentric orbits

add node(t1, 0, nv, pv).

// DEBUG:
// terminal:input:getchar().
