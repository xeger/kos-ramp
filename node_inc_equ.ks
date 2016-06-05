/////////////////////////////////////////////////////////////////////////////
// Change alignment relative to equator.
/////////////////////////////////////////////////////////////////////////////
// Perform a plane-change maneuver at the next ascending or descending node
// with the equatorial orbit. Limit plane change to +/- 30 degrees and halt
// with a fatal error if plane change would lead to an escaping or terminal
// orbit.
/////////////////////////////////////////////////////////////////////////////

parameter desiredInclin.

local pos0 is ship:position-ship:body:position.
local vel0 is ship:velocity:orbit.

local posEqu is V(pos0:x, 0, pos0:z).
local angEqu is vang(pos0,posEqu).

if pos0:y > 0 {
	if vel0:y > 0 {
		// above & traveling away from equator; need to rise to inc, then fall back to 0
		set angEqu to 2 * ship:obt:inclination - abs(angEqu).
	}
} else {
	if vel0:y < 0 {
		// below & traveling away from the equator; need to fall to inc, then rise back to 0
		set angEqu to 2 * ship:obt:inclination - abs(angEqu).
	}
}

local frac is (angEqu / (4 * ship:obt:inclination)).
local dt is frac * ship:obt:period.
local T is time + dt.

local relInclin is abs(ship:obt:inclination - desiredInclin).
if abs(relInclin) > 30 {
	// clamp inclination change to (-30, 30) degrees to avoid escaping
	set relInclin to relInclin / abs(relInclin / 30).
}

local velEqu is velocityat(ship, T):orbit.
local dv is 2 * velEqu:mag * sin(relInclin / 2).

if vel0:y <= 0 and velEqu:y <= 0 {
	add node(T:seconds, 0, dv, 0).
} else {
	add node(T:seconds, 0, -dv, 0).
}

local trans is orbitat(ship, time:seconds + nextnode:eta + 5):transition.
if trans <> "FINAL" {
	remove nextnode.
	uiFatal("Node", "STRANDED: unstable plane change").
}
