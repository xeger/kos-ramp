// Circularizes at the nearest apoapsis or periapsis or eta provided
// run circ = at nearest apoapsis or periapsis (whichever is closer)
// run circ(0) = circularize now
// run circ(eta:apoapsis) = circularize at apoapsis, standard node steering (less precise)
// run circ({return eta:periapsis.}) = circularize at periapsis with steering for better precision

parameter nodeEta is "guess".	// default guess, eta or delegate otherwise

run once lib_util.
utilRemoveNodes().

if nodeEta:istype("scalar") {
	local t1 is time:seconds+nodeEta.
	set nodeEta to {return t1-time:seconds.}.
}
else if not nodeEta:istype("delegate") {
	if apoapsis > 0 and eta:periapsis > eta:apoapsis set nodeEta to {return eta:apoapsis.}.
	else if periapsis > min(body:atm:height,3000) set nodeEta to {return eta:periapsis.}.
	else set nodeEta to {return 0.}.
}

local function dv1 {
	parameter dt.
	if dt < 1 and orbit:eccentricity < 0.00005 return v(0,0,0).
	local p1 is ship:position-body:position.
	local v1 is velocity:orbit.
	local v2 is sqrt(body:mu/p1:mag)*vcrs(p1,vcrs(v1,p1)):normalized.
	return v2-v1.
}
local function dv2 {
	parameter dt.
	if dt < 1 return dv1(dt).
	local t1 is time:seconds+dt.
	local p1 is positionAt(ship,t1)-body:position.
	local v1 is velocityAt(ship,t1):orbit.
	local v2 is sqrt(body:mu/p1:mag)*vcrs(p1,vcrs(v1,p1)):normalized.
	return v2-v1.
}
local df is dv1@.
if Career():canMakeNodes set df to dv2@.
run node(0,0,nodeEta,df).
