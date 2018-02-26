/////////////////////////////////////////////////////////////////////////////
// Circularize.
/////////////////////////////////////////////////////////////////////////////
// Circularizes at the nearest apoapsis or periapsis
/////////////////////////////////////////////////////////////////////////////

run once lib_ui.
run once lib_util.

if Career():canMakeNodes and periapsis > max(body:atm:height,1000)
{
	utilRemoveNodes().
	if obt:transition = "ESCAPE" or eta:periapsis < eta:apoapsis
    	run node({run node_apo(obt:periapsis).}).
  	else run node({run node_peri(obt:apoapsis).}).
	uiBanner("Circ", "Circularized; e=" + round(ship:obt:eccentricity, 3)).
}
else if apoapsis > 0 and eta:apoapsis < eta:periapsis
{
	run once lib_staging.
	run once lib_warp.

	local sstate is sas.
	sas off.
	local t1 is time:seconds+eta:apoapsis.
	local dt is 60.
	local canAt is false.
	if Career():canMakeNodes {
		set canAt to true.
		set v0 to velocityAt(ship,t1):orbit.
		set dir to lookdirup(v0, positionAt(ship,t1)-body:position).
		lock steering to dir.
	//	deltaV = required orbital speed minus predicted speed
		set dv to sqrt(body:mu/(body:radius+apoapsis))-v0:mag.
		set dt to burnTimeForDv(dv)*2/3. // we better start earlier
	} else
	//	posotionAt and velocityAt not allowed if nodes are not allowed
		lock steering to prograde.
	stagingPrepare().
	uiBanner("Circ", "Coast to apoapsis.").
	wait until utilIsShipFacing().
	warpSeconds(eta:apoapsis - dt - 30).
	lock steering to prograde.
	wait until utilIsShipFacing(prograde:forevector).
	warpSeconds(eta:apoapsis - dt - 5).
	wait until eta:apoapsis <= dt + 0.1.
	uiBanner("Circ", "Burn to raise periapsis.").
	local function circSteering {
		if eta:apoapsis < eta:periapsis {
		//	prevent raising apoapsis
			if eta:apoapsis > 1 {
				if canAt return velocityAt(ship,time:seconds+eta:apoapsis):orbit.
				local pos is ship:position-body:position.
				return vcrs(pos,vcrs(ship:velocity:orbit,pos)).
			}
		//	go prograde in last second (above velocityAt often has problems with time=now)
			return prograde.
		}
		// pitch up a bit when we passed apopapsis to compensate for potentionally low TWR as this is often used after launch script
		// note that ship's pitch is actually yaw in world perspective (pitch = normal, yaw = radial-out)
		return prograde:vector+r(0,min(30,max(0,orbit:period-eta:apoapsis)),0).
	}
	lock steering to circSteering().
	local maxThrottle is 1.
	lock throttle to min(maxThrottle,
		(sqrt(body:mu/(body:radius+apoapsis))-ship:velocity:orbit:mag)*ship:mass/max(1,availableThrust)).
	local maxHeight is ship:obt:apoapsis*1.01+1000.
	local almostThere is 0.
	local prevTick is time:seconds.
	until orbit:eccentricity < 0.0001 // circular
		or eta:apoapsis > orbit:period/3 and eta:apoapsis < orbit:period*2/3 // happens with good accuracy
		or orbit:apoapsis > maxHeight and periapsis > max(body:atm:height,1000)+1000 // something went wrong?
		or orbit:apoapsis > maxHeight*1.5+5000 // something went really really wrong
	{
		stagingCheck().
		wait 0.5.

	//	for logic if we cannot use velocityAt
		if not canAt {
			local now is time:seconds.
			set dt to max(3,dt-0.5*(now-prevTick)).
			if eta:apoapsis < eta:periapsis {
				set dt to min(dt,eta:apoapsis+3).
				set maxThrottle to 1.1*dt-eta:apoapsis.
			}
			else set maxThrottle to 1.
			set prevTick to now.
		}

		if orbit:eccentricity < 0.001 {
			if almostThere = 0 set almostThere to time:seconds.
			else if time:seconds-almostThere > 10 break.
		}
	}
	set ship:control:pilotmainthrottle to 0.
	unlock all.
	set sas to sstate.

	if orbit:eccentricity > 0.1 or orbit:periapsis < max(body:atm:height,1000)
		uiFatal("Circ", "Error; e=" + round(orbit:eccentricity, 4) + ", peri=" + round(periapsis)).
	uiBanner("Circ", "Circularized; e=" + round(orbit:eccentricity, 4)).
}
else
	uiError("Circ", "Either escape trajectory or closer to periapsis").//TODO
