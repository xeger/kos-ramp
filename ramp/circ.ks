/////////////////////////////////////////////////////////////////////////////
// Circularize.
/////////////////////////////////////////////////////////////////////////////
// Circularizes at the nearest apoapsis or periapsis
/////////////////////////////////////////////////////////////////////////////

run once lib_ui.
run once lib_util.

if Career():canMakeNodes and periapsis > max(body:atm:height, 1000) {
	utilRemoveNodes().
	if obt:transition = "ESCAPE" or eta:periapsis < eta:apoapsis
		run node({run node_apo(obt:periapsis).}).
	else run node({run node_peri(obt:apoapsis).}).
	uiBanner("Circ", "Circularized; e=" + round(ship:obt:eccentricity, 3)).
} else if apoapsis > 0 and eta:apoapsis < eta:periapsis {
	run once lib_staging.
	run once lib_warp.

	local sstate is sas.
	sas off.
	set v0 to velocityAt(ship, time:seconds + eta:apoapsis):orbit.
	lock steering to v0.
	stagingPrepare().
	// deltaV = required orbital speed minus predicted speed
	set dv to sqrt(body:mu / (body:radius + apoapsis)) - v0:mag.
	set dt to burnTimeForDv(dv) / 2.
	uiBanner("Circ", "Coast to apoapsis.").
	wait until utilIsShipFacing(v0).
	warpSeconds(eta:apoapsis - dt - 30).
	lock steering to prograde.
	wait until utilIsShipFacing(prograde:forevector).
	warpSeconds(eta:apoapsis - dt - 5).
	wait until eta:apoapsis <= dt + 0.1.
	uiBanner("Circ", "Burn to raise periapsis.").
	local function circSteering {
		if eta:apoapsis < eta:periapsis {
			// prevent raising apoapsis
			if eta:apoapsis > 1 return velocityAt(ship, time:seconds + eta:apoapsis):orbit.
			// go prograde in last second (above velocityAt often has problems with time=now)
			return prograde.
		}
		// pitch up a bit when we passed apopapsis to compensate for potentionally low TWR as this is often used after launch script
		// note that ship's pitch is actually yaw in world perspective (pitch = normal, yaw = radial-out)
		return prograde:vector + r(0, min(30, max(0, orbit:period - eta:apoapsis)), 0).
	}
	lock steering to circSteering().
	lock throttle to (sqrt(body:mu / (body:radius + apoapsis)) - ship:velocity:orbit:mag) * ship:mass / max(1, availableThrust).
	local maxHeight is ship:obt:apoapsis * 1.01 + 1000.
	until orbit:eccentricity < 0.0005 // circular
		or eta:apoapsis > orbit:period / 3 and eta:apoapsis < orbit:period * 2 / 3 // happens with good accuracy
		or orbit:apoapsis > maxHeight and periapsis > max(body:atm:height, 1000) + 1000 // something went wrong?
		or orbit:apoapsis > maxHeight * 1.5 + 5000 // something went really really wrong
	{
		stagingCheck().
		wait 0.5.
	}
	set ship:control:pilotmainthrottle to 0.
	unlock all.
	set sas to sstate.

	if orbit:eccentricity > 0.1 or orbit:periapsis < max(body:atm:height, 1000)
		uiFatal("Circ", "Error; e=" + round(orbit:eccentricity, 3) + ", peri=" + round(periapsis)).
	uiBanner("Circ", "Circularized; e=" + round(orbit:eccentricity, 3)).
} else {
	// TODO
	uiError("Circ", "Either escape trajectory or closer to periapsis").
}
