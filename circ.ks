/////////////////////////////////////////////////////////////////////////////
// Circularize.
/////////////////////////////////////////////////////////////////////////////
// Circularizes at the nearest apoapsis or periapsis
/////////////////////////////////////////////////////////////////////////////

run once lib_ui.
run once lib_util.
run once lib_staging.

if Career():canMakeNodes and periapsis > max(body:atm:height,1000)
{
	if obt:transition = "ESCAPE" or eta:periapsis < eta:apoapsis
    	run node_apo(obt:periapsis).
  	else run node_peri(obt:apoapsis).
	run node.
	uiBanner("Circ", "Circularized; e=" + round(ship:obt:eccentricity, 3)).
}
else if apoapsis > 0 and eta:apoapsis < eta:periapsis
{
	sas off.
	set v0 to velocityAt(ship,time:seconds+eta:apoapsis):orbit.
	lock steering to v0.
	stagingPrepare().
	// deltaV = required orbital speed minus predicted speed
	set dv to sqrt(body:mu/(body:radius+apoapsis))-v0:mag.
	set dt to burnTimeForDv(dv)/2.
	uiBanner("Circ", "Coast to apoapsis.").
	wait until utilIsShipFacing(v0).
	run warp(eta:apoapsis - dt - 30).
	lock steering to prograde.
	wait until utilIsShipFacing(prograde:forevector).
	run warp(eta:apoapsis - dt - 5).
	wait until eta:apoapsis <= dt + 0.1.
	uiBanner("Circ", "Burn to raise periapsis.").
	lock throttle to max(1, 2 * ship:obt:eccentricity / max(.1,thrustToWeight())).
	local function circSteering {
		if eta:apoapsis < eta:periapsis return prograde.
		// pitch up a bit when we passed apopapsis to compensate for potentionally low TWR as this is often used after launch script
		// note that ship's pitch is actually yaw in world perspective (pitch = normal, yaw = radial-out)
		return prograde:vector+r(0,min(30,max(0,orbit:period-eta:apoapsis)),0).
	}
	lock steering to circSteering().
	local maxHeight is ship:obt:apoapsis*1.01.
	until ship:obt:eccentricity < 0.001		// circular
		or ship:obt:apoapsis > maxHeight	// something went wrong?
		or eta:apoapsis > orbit:period/3 and eta:apoapsis < orbit:period*2/3 // happens with good accuracy
	{
		stagingCheck().
		wait 0.5.
	}
	set ship:control:pilotmainthrottle to 0.
	unlock throttle.
	unlock steering.
	sas on.
}
else
	uiError("Circ", "Either escape trajectory or closer to periapsis").//TODO
