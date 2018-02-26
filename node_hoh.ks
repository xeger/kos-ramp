// Delta vee math stolen from http://en.wikipedia.org/wiki/Hohmann_transfer_orbit#Calculation
// Phase angle math stolen from https://docs.google.com/document/d/1IX6ykVb0xifBrB4BRFDpqPO6kjYiLvOcEo3zwmZL0sQ/edit
// and here https://forum.kerbalspaceprogram.com/index.php?/topic/122685-how-to-calculate-a-rendezvous/
// and from here too https://forum.kerbalspaceprogram.com/index.php?/topic/85285-phase-angle-calculation-for-kos/
// Hyperbolic Departure for Interplanetary Transfer is from http://www.braeunig.us/space/interpl.htm
// Final *arcsin* correction from here: https://ocw.mit.edu/courses/aeronautics-and-astronautics/16-07-dynamics-fall-2009/lecture-notes/MIT16_07F09_Lec17.pdf

runoncepath("lib_ui").
runoncepath("lib_util").

local we is ship.
local it is target.
if body <> target:body {
	if body:hasBody and body:body = target:body {
	//	e.g. from Kerbin to Duna or from Mun to Minmus, calculate like if transfering Kerbin/Mun itself
		set we to body.
	} else if body:hasBody and target:body:hasBody and body:body = target:body:body {
	//	e.g. Kerbin to Ike, redirect to Duna.
		set we to body.
		set it to target:body.
	} else
	//	from Mun to Ike or something similarly stupid?
		uiFatal("Hohmann", "Incompatible orbits").
}
local our is we:orbit.
local its is it:orbit.

// can hit Mun and Minmus with 0.1, since precise burn vector calculation
// but eta to burn prediction gets bad with higher eccentricity
if orbit:eccentricity > 0.05
	uiWarning("Hohmann", "Eccentric ship e=" + round(orbit:eccentricity, 1)).

if we = ship {
//	again, would need time correction (patch for angle change variation)
	if its:eccentricity > 0.05
		uiWarning("Hohmann", "Eccentric target e=" + round(its:eccentricity, 1)).
} else {
//	do not even try if we are not in same plane
	if ship:orbit:inclination > 1
		uiFatal("Hohmann", "Ship inclination=" + round(ship:orbit:inclination)).
}
//	should add correcting node half-way (if going to higher orbit, fix it before if going lower)
local ri is our:inclination - its:inclination.
if abs(ri) > 0.2 // and we = ship and our:semiMajorAxis > its:semiMajorAxis
	uiWarning("Hohmann", "Inclination difference ri=" + round(ri, 1)).

utilRemoveNodes().

// Compute prograde delta-vee required to achieve Hohmann transfer between circualr orbits
// negative means retrograde burn, used as first prediction
local function hohDv {
  parameter r1 is our:semimajoraxis.
  parameter r2 is its:semimajoraxis.
  return sqrt(our:body:mu/r1) * (sqrt((2*r2)/(r1+r2)) - 1).
}

local r1 is our:semiMajorAxis.
local r2 is its:semiMajorAxis.
local pt is 0.5 * ((r1+r2) / (2*r2))^1.5.
local ft is pt - floor(pt).
// angular distance that target will travel during transfer (if circular)
local theta is 360 * ft.
// angles to universal reference direction
local sa is our:lan + our:argumentOfPeriapsis + our:trueAnomaly. 
local ta is its:lan + its:argumentOfPeriapsis + its:trueAnomaly.
local t0 is time:seconds.
// match angle (+k*360)
local ma is utilAngleTo360(ta+theta-sa-180).
// angle change rate (inaccurate for eccentric orbits but good for a start)
local ar is 360/our:period - 360/its:period.
// estimated burn time
local dv is hohDv().
local mt is 5+.5*dv*ship:mass/max(0.1,ship:availableThrust).
// k closest to zero such that (ma + k*360)/ar >= mt
local k is (mt*ar - ma)/360.
// closest integer
if ar < 0 set k to floor(k).
else set k to ceiling(k).
// time to node (exact if both orbits are perfectly circular)
local dt is (ma+k*360)/ar.
// precise burn vector
local t1 is t0+dt.
local v1 is velocityAt(we,t1):orbit.
local p1 is positionAt(we,t1)-our:body:position.
local r1 is p1:mag.
// prograde, normal and radial-out normalized
local pv is v1:normalized.
local nv is vcrs(v1,p1):normalized.
local rv is vcrs(nv,v1):normalized.
// https://en.wikipedia.org/wiki/Orbital_speed#Precise_orbital_speed
local v2 is sqrt(our:body:mu*(2/r1-2/(r1+r2))) * vcrs(p1,nv):normalized.
local dv is v2 - v1.
if we = ship
	add node(t1, vdot(dv,rv), vdot(dv,nv), vdot(dv,pv)).
else {
//	interplanetary transfer (or moon-to-moon)
	local pb is sqrt(dv:mag^2+2*body:mu/orbit:semiMajorAxis) - sqrt(body:mu/orbit:semiMajorAxis).
	local mt is 5+.5*pb*ship:mass/max(0.1,ship:availableThrust).
	local ca is utilVecAng(positionAt(ship,t1)-body:position, v2, nv)
		-90-arcsin(1/(1+orbit:semiMajorAxis*dv:mag^2/body:mu)).
	if r2 < r1 set ca to ca+180.
	set ca to utilAngleTo360(ca).
	local dt is ca/360*orbit:period.
	if ca > 180 and t1 + dt - orbit:period > mt
		set t1 to t1 + dt - orbit:period.
	else set t1 to t1 + dt.
	add node(t1, 0, 0, pb).
}
