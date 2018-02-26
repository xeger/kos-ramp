// Ascend from a planet, performing a gravity turn and staging as necessary.
// Achieve circular orbit with desired apoapsis (calls circ.ks at the end).

// Final apoapsis (altitude in meters, or kilometers if lower than 1000)
parameter apo is 200000.
if apo < 1000 set apo to apo*1000. //kilometers were in mind, anything below 3km is madness anywhere

// Heading during launch (90 for equatorial prograde orbit)
parameter hdg is 90.

// Roll/rotation during launch
local function defaultRotation {
	// do not rotate the rocket 180° if we are already facing the proper way
	if abs(ship:facing:roll-180-hdg) < 30 return 0.
	return 180. // needed for shuttles, should not harm rockets
}
parameter launchRoll is defaultRotation().

// Profile parameters
local topAlt is max(body:atm:height,3000).
parameter profile 	is 5.	// profile (1-9, bigger means less aggresive turn)
parameter sRatio	is 12.	// speed/altitude ratio at minimal orbit height to base the curve on
							// higher is for speed, more than 10 means switch earlier to full speed-based
parameter minAlt	is 100.	// minimal altitude to start turning
parameter minSpd	is 100.	// minimal speed to start turning
parameter maxSpd	is .8.	// target escape speed (absolute or portion of minimal oribt speed).

set profile to profile/10.
set sRatio	to sRatio/10.
if maxSpd <= 2 set maxSpd to maxSpd*sqrt(body:mu/(body:radius+topAlt)).

runoncepath("lib_parts").
runoncepath("lib_ui").
runoncepath("lib_util").
runoncepath("lib_warp").
runoncepath("lib_staging").

stagingPrepare(). // can take some time, do it ahead
uiBanner("ascent","Ascent to "+round(apo/1000)+"km; heading "+hdg + "º").
uiConsole("ascent","Roll: "+launchRoll+"°; profile: "+(profile*10)+"/"+(sRatio*10)).

/////////////////////////////////////////////////////////////////////////////
// Steering function for continuous lock.

local pitch is 90.
function ascentSteering {
//	horizontal if periapsis out of atmosphere
	if periapsis >= topAlt
		return heading(hdg,0) * r(0,0,launchRoll).
	
//	smooth transition from surface to orbital speed by ratio of altitude to target apoapsis
	local factor is max(0,min(1,(altitude/topAlt)^2)).
	local speed is (1-factor)*velocity:surface:mag+velocity:orbit:mag*factor.

	if altitude <= minAlt or speed <= minSpd {
	//	pitch up first
		set pitch to 90.
		if speed > minSpd set minSpd to speed.
		if altitude > minAlt set minAlt to altitude.
	} else {
	//	mix of speed-based and altitude-based curve
		local altRatio is max(0,min(1,(altitude-minAlt)/(topAlt-minAlt))).
		local ratio is min(1,sRatio*altRatio).
		local fraction is ((1-ratio)*altRatio +
			ratio*min(1,(speed-minSpd)/(maxSpd-minSpd)))^profile.
		set pitch to 90-90*fraction.
	//	compensate for differences from desired prograde pitch
		local srfAngle to 90-vAng(up:vector,srfPrograde:vector).
		local current is (1-factor)*srfAngle+factor*(90-vAng(up:vector,prograde:vector)).
		if pitch < current and altitude < topAlt/3
			set pitch to max(0, min(90, pitch + 3*altitude/topAlt*(pitch-current))).
		else set pitch to max(0, min(90, 2*pitch-current)).
	//	limit AoA when Q is high
		local maxAngle is 3/max(0.1,ship:q^2).
		set pitch to min(srfAngle+maxAngle,max(srfAngle-maxAngle,pitch)).
	}
	return heading(hdg,pitch) * r(0,0,launchRoll).
}

/////////////////////////////////////////////////////////////////////////////
// Throttle function for continuous lock.

function ascentSpeedLimit {
	return 200+.9*sqrt(body:mu/(body:radius+topAlt))*(1-min(1,
		(ship:q+body:atm:altitudePressure(altitude))^.3)).
}

local period is 10. //printouts
local speed  is 0.
local cutoff is 200.
function ascentThrottle {
	set period to 10.
	if apoapsis >= apo return 0.
	set speed to ship:airspeed.
//	avoid overheat or aerodynamic catastrophe by limiting throttle
//	but no less than 30% to keep some gimbaling
	local safeMax is 1.
	if altitude < topAlt {
		set cutoff to ascentSpeedLimit().
		set lmited to altitude < topAlt and speed > cutoff.
		if lmited {
			set period to 1.
			set safeMax to max(0.3, 1 - ((speed - cutoff) / cutoff)^.6).
		}
	}
//	ease throttle when apoapsis near target
//	or we are still in atmosphere and apoapsis above the boundary (for gimbaling)
	local easeMax is 1.
	if apoapsis > topAlt and altitude < topAlt*.9
		set easeMax to max(0.3, (apo-apoapsis)/max(1,apo-topAlt)).
	if apoapsis > apo*0.95
		set easeMax to min(easeMax, 0.01+20*(1-apoapsis/apo)).
//	let pilot throttle down if needed
	return min(ship:control:pilotMainThrottle, min(safeMax,easeMax)).
}

/////////////////////////////////////////////////////////////////////////////
// Deploy fairings and panels at proper altitude; call in a loop.

local deployed is false.
function ascentDeploy {
	if deployed return.
	if ship:altitude < ship:body:atm:height return.
	set deployed to true.
	set sound to 1.
	if partsDeployFairings() {
		uiBanner("ascent", "Fairings deployed", sound).
		set sound to 0.
		wait 0.
	}
	if partsExtendSolarPanels() {
		uiBanner("ascent", "Solar panels extended", sound).
		set sound to 0.
	}
	if partsExtendAntennas()
		uiBanner("ascent", "Antennas extended", sound).
}

/////////////////////////////////////////////////////////////////////////////
// Perform initial setup; trim ship for ascent.
/////////////////////////////////////////////////////////////////////////////

sas off.
bays off.
// panels off. - bug in kOS with OX-STAT: KSP-KOS/KOS#2213
partsRetractSolarPanels().
radiators off.

/////////////////////////////////////////////////////////////////////////////
// Enter ascent loop.
/////////////////////////////////////////////////////////////////////////////

lock steering to ascentSteering().
lock throttle to ascentThrottle().
set ship:control:pilotMainThrottle to 1.

local warped is 0.
local phase is 0.
local lastInfo is time:seconds-7. 
until apoapsis >= apo {
	stagingCheck().
	ascentDeploy().
	if warped = 0 and altitude > topAlt/10 {
		physWarp(1).
		set warped to 1.
		uiConsole("ascent", "Warping Px2, Alt: " + round(altitude)).
	}
	if warped = 1 and altitude >= topAlt and (apoapsis/apo <= 0.99 or apo-apoapsis <= 1000) {
		resetWarp().
		set warped to -1.
		uiConsole("ascent", "Canceling warp, Apo: " + round(apoapsis)).
	}
	if phase = 0 and periapsis >= topAlt {
		set phase to 1.
		uiBanner("ascent", "Horizontal burn").
	}
	local now is time:seconds.
	if now-lastInfo >= period {//see ascentSteering()
		set lastInfo to now.
		local a is round(90-vAng(up:vector,srfPrograde:vector)).
		if phase = 0 {
			if altitude < topAlt uiConsole("Alt", round(altitude) + " Speed: " + round(speed) + "/" + round(cutoff)
				+" Q:" + round(ship:q*100) + "+" + round(body:atm:altitudePressure(altitude)*100)+" A: "+a+"/"+round(pitch)).
			else uiConsole("Alt", round(altitude) + " Orbital Speed: " + round(velocity:orbit:mag)+" A: "+a+"/"+round(pitch)).
		}
		else uiConsole("Alt", round(altitude) + " Speed: " + round(velocity:orbit:mag) + " Apo: " + round(apoapsis)).
	}
	wait 0.
}
uiBanner("ascent", "Engine cutoff").

/////////////////////////////////////////////////////////////////////////////
// Coast to apoapsis and hand off to circularization program.
/////////////////////////////////////////////////////////////////////////////

// Roll with top up
uiBanner("ascent", "Point prograde").
lock steering to lookdirup(prograde:vector,ship:position-body:position).

// Warp to end of atmosphere
until altitude >= topAlt {
	stagingCheck().
	wait 0.1.
	if warped < 1 {
		physWarp(1).
		if warped = 0 {
			set warped to 1.
			uiConsole("ascent", "Warping Px2, Alt: " + round(altitude)).
		} else {
			set warped to 2.
			uiConsole("ascent", "Warping again").
		}
	}
	if warped = 1 and (apoapsis/apo <= 0.99 or apo-apoapsis <= 1000) {
		resetWarp().
		set warped to -1.
		uiConsole("ascent", "Canceling warp, Apo: " + round(apoapsis)).
	}
}
set ship:control:pilotMainThrottle to 0.
if warped > 0 resetWarp().
// Discard fairings and deploy panels, if they aren't yet.
ascentDeploy().
wait 1.
unlock all.
// Circularize
run circ({return eta:apoapsis.}).
// Stabilize
lock steering to prograde.
wait 1.
unlock all.
sas on. // better leave that on
