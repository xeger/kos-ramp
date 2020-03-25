// Determine the time of ship1's closest approach to ship2.
function utilClosestApproach {
	parameter ship1.
	parameter ship2.

	local Tmin is time:seconds.
	local Tmax is Tmin + 2 * max(ship1:obt:period, ship2:obt:period).

	until Tmax - Tmin < 5 {
		local dt2 is (Tmax - Tmin) / 2.
		local Rl is utilCloseApproach(ship1, ship2, Tmin, Tmin + dt2).
		local Rh is utilCloseApproach(ship1, ship2, Tmin + dt2, Tmax).
		if Rl < Rh {
			set Tmax to Tmin + dt2.
		} else {
			set Tmin to Tmin + dt2.
		}
	}

	return (Tmax + Tmin) / 2.
}

// Given that ship1 "passes" ship2 during time span, find the APPROXIMATE
// distance of closest approach, but not precise! Use this iteratively to find
// the true closest approach.
function utilCloseApproach {
	parameter ship1.
	parameter ship2.
	parameter Tmin.
	parameter Tmax.

	local Rbest is (ship1:position - ship2:position):mag.
	local dt is (Tmax - Tmin) / 32.

	local T is Tmin.
	until T >= Tmax {
		local X is (positionat(ship1, T)) - (positionat(ship2, T)).
		if X:mag < Rbest {
			set Rbest to X:mag.
		}
		set T to T + dt.
	}

	return Rbest.
}

function utilFaceBurn {

	// This function is intended to use with shuttles and spaceplanes that have engines not in line with CoM.
	// Usage: lock steering to utilFaceBurn(THEDIRECTIONYOUWANTTOSTEER).
	// Example: lock steering to utilFaceBurn(PROGRADE).

	parameter dirtosteer. // The direction you want the ship to steer to
	local newdirtosteer is dirtosteer. // Return value. Defaults to original direction.

	local OSS is lexicon(). // Used to store all persistent data
	local trueacc is 0. // Used to store ship acceleration vector

	function HasSensors {
		// Checks if ship have required sensors:
		// - Accelerometer (Double-C Seismic Accelerometer)
		// - Gravity Sensor (GRAVMAX Negative Gravioli Detector)
		local HasA is false.
		local HasG is false.
		list sensors in senselist.
		for S in senselist {
			if S:type = "ACC" { set HasA to true. }
			if S:type = "GRAV" { set HasG to true. }
		}
		return HasA and HasG.
	}

	function InitOSS {
		// Initialize persistent data.
		local lex is lexicon().
		lex:add("t0", time:seconds).
		lex:add("pitch_angle", 0).
		lex:add("pitch_sum", 0).
		lex:add("yaw_angle", 0).
		lex:add("yaw_sum", 0).
		lex:add("Average_samples", 0).
		lex:add("Average_Interval", 1).
		lex:add("Average_Interval_Max", 5).
		lex:add("Ship_Name", ship:name:tostring).
		lex:add("HasSensors", HasSensors()).
		return lex.
	}

	if exists("oss.json") { // Looks for saved data
		set OSS to readjson("oss.json").
		if OSS["Ship_Name"] <> ship:name:tostring {
			set OSS to InitOSS().
		}
	} else {
		set OSS to InitOSS().
	}

	if OSS["HasSensors"] { // Checks for sensors
		lock trueacc to ship:sensors:acc - ship:sensors:grav.
	} else { // If ship have no sensors, just returns direction without any correction
		return dirtosteer.
	}


	// Only account for offset thrust if there is thrust!
	if throttle > 0.1 {
		local dt to time:seconds - OSS["t0"]. // Delta Time
		if dt > OSS["Average_Interval"] {
			// This section takes the average of the offset, reset the average counters and reset the timer.
			set oss["t0"] to time:seconds.
			if OSS["Average_samples"] > 0 {
				// Pitch
				set OSS["pitch_angle"] to OSS["pitch_sum"] / OSS["Average_samples"].
				set OSS["pitch_sum"] to OSS["pitch_angle"].
				// Yaw
				set OSS["yaw_angle"] to OSS["yaw_sum"] / OSS["Average_samples"].
				set OSS["yaw_sum"] to OSS["yaw_angle"].
				// Sample count
				set OSS["Average_samples"] to 1.
				// Increases the Average interval to try to keep the adjusts more smooth.
				if OSS["Average_Interval"] < OSS["Average_Interval_Max"] {
					set OSS["Average_Interval"] to max(OSS["Average_Interval_Max"], (OSS["Average_Interval"] + dt)) .
				}
			}
		} else { // Accumulate the thrust offset error to be averaged by the section above

			// Thanks to reddit.com/user/ElWanderer_KSP
			// exclude the left/right vector to leave only forwards and up/down
			local pitch_error_vec is vxcl(facing:starvector, trueacc).
			local pitch_error_ang is vang(facing:vector, pitch_error_vec).
			If vdot(facing:topvector, pitch_error_vec) > 0{
				set pitch_error_ang to -pitch_error_ang.
			}

			// exclude the up/down vector to leave only forwards and left/right
			local yaw_error_vec is vxcl(facing:topvector, trueacc).
			local yaw_error_ang is vang(facing:vector, yaw_error_vec).
			if vdot(facing:starvector, yaw_error_vec) < 0{
				set yaw_error_ang to -yaw_error_ang.
			}
			// LOG "P: " + pitch_error_ang to "0:/oss.txt".
			// LOG "Y: " + yaw_error_ang to "0:/oss.txt".
			set OSS["pitch_sum"] to OSS["pitch_sum"] + pitch_error_ang.
			set OSS["yaw_sum"] to OSS["yaw_sum"] + yaw_error_ang.
			set OSS["Average_samples"] to OSS["Average_samples"] + 1.
		}
		// Set the return value to original direction combined with the thrust offset
		// set newdirtosteer to r(0-OSS["pitch_angle"], OSS["yaw_angle"], 0) * dirtosteer.
		set newdirtosteer to dirtosteer.
		if abs(OSS["pitch_angle"]) > 1 { // Don't bother correcting small errors
			set newdirtosteer to angleaxis(-OSS["pitch_angle"], ship:facing:starvector) * newdirtosteer.
		}
		if abs(OSS["yaw_angle"]) > 1 { // Don't bother correcting small errors
			set newdirtosteer to angleaxis(OSS["yaw_angle"], ship:facing:upvector) * newdirtosteer.
		}
	}
	// This function is pretty processor intensive, make sure it don't execute too much often.
	wait 0.2.
	// Saves the persistent values to a file.
	writejson(OSS, "oss.json").
	return newdirtosteer.
}


function utilRCSCancelVelocity {
	// MUST Be a delegate to a vector
	// Example:
	//
	// lock myVec to myNode:DeltaV.
	// utilRCSCancelVelocity(myVec@).
	parameter CancelVec.
	parameter residualSpeed is 0.01. // Admissible residual speed.
	parameter MaximumTime is 15. // Maximum time to achieve results.

	local lock tgtVel to -CancelVec().

	// Save ship's systems status
	local rstatus is rcs.
	local sstatus is sas.

	// Prevents ship to rotate
	sas off.
	lock steering to ship:facing.
	uiDebug("Fine tune with RCS").
	// Cancel the speed.
	rcs on.
	local t0 is time.
	until tgtVel:mag < residualSpeed or (time - t0):seconds > MaximumTime {
		local sense is ship:facing.
		local dirV is V(
			vdot(tgtVel, sense:starvector),
			vdot(tgtVel, sense:upvector),
			vdot(tgtVel, sense:vector)
		).
		set ship:control:translation to dirV:normalized.
		wait 0.
	}

	// Return ship controls to previus condition
	set ship:control:translation to v(0, 0, 0).
	set ship:control:neutralize to true.
	set ship:control:pilotmainthrottle to 0.
	unlock steering.
	unlock throttle.
	set rcs to rstatus.
	set sas to sstatus.
}

// Returns true if:
// Ship is facing the FaceVec whiting a tolerance of maxDeviationDegrees and
// with a Angular velocity less than maxAngularVelocity.
function utilIsShipFacing {
	parameter face.
	parameter maxDeviationDegrees is 8.
	parameter maxAngularVelocity is 0.01.

	if face:istype("direction") set face to face:vector.
	return vdot(face:normalized, ship:facing:forevector:normalized) >= cos(maxDeviationDegrees) and
		ship:angularvel:mag < maxAngularVelocity.
}

function utilLongitudeTo360 {
	// Converts longitudes from -180 to +180 into a 0-360 degrees.
	// Imagine you start from Greenwitch to East, and instead of stop a 180º, keep until reach Greenwitch again at 360º
	// i.e.: 10  >  10
	//      170 > 170
	//      180 > 180
	//      -10 > 350
	//     -170 > 190
	//     -180 > 180
	// From youtube.com/cheerskevin
	parameter lng.
	return mod(lng + 360, 360).
}

function utilReduceTo360 {
	// Converts angles that are more than 360 to 0-360
	// i.e: 720 > 0
	//     730 > 10
	//     400 > 40
	parameter ang.
	return ang - 360 * floor(ang / 360).
}

function utilCompassHeading {
	// Returns the same HDG number that Kerbal shows in bottom of Nav Ball
	local northPole is latlng( 90, 0). // Reference heading
	if northPole:bearing <= 0 {
		return abs(northPole:bearing).
	} else {
		return (180 - northPole:bearing) + 180.
	}
}

function utilHeadingToBearing {
	// Converts a heading from 0 to 360 into bearings from -180 to +180
	parameter hdg.
	if hdg > 180 return hdg - 360.
	else if hdg < -180 return hdg + 360.
	else return hdg.
}

// remove all nodes and wait one tick if there was any
function utilRemoveNodes {
	if not hasNode return.
	for n in allNodes remove n.
	wait 0.
}

// convert any angle to range [0, 360)
function utilAngleTo360 {
	parameter pAngle.
	set pAngle to mod(pAngle, 360).
	if pAngle < 0 set pAngle to pAngle + 360.
	return pAngle.
}

// convert from true to mean anomaly
function utilMeanFromTrue {
	parameter pAnomaly.
	parameter pOrbit is orbit.
	local e is pOrbit:eccentricity.
	if e < 0.001 return pAnomaly. // circular, no need for conversion
	if e >= 1 { print "ERROR: meanFromTrue(" + round(pAnomaly, 2) + ") with e=" + round(e, 5). return pAnomaly. }
	set pAnomaly to pAnomaly * 0.5.
	set pAnomaly to 2 * arctan2(sqrt(1 - e) * sin(pAnomaly), sqrt(1 + e) * cos(pAnomaly)).
	// https://en.wikipedia.org/wiki/Eccentric_anomaly
	// https://en.wikipedia.org/wiki/Mean_anomaly
	return pAnomaly - e * sin(pAnomaly) * 180 / constant:pi.
}

// eta to mean anomaly (angle from periapsis converted to mean-motion circle)
function utilDtMean {
	parameter pAnomaly.
	parameter pOrbit is orbit.
	return utilAngleTo360(pAnomaly - utilMeanFromTrue(pOrbit:trueAnomaly)) / 360 * pOrbit:period.
}

// eta to true anomaly (angle from periapsis in the direction of movement)
// note: this is the ultimate ETA function which is in KSP API known as GetDTforTrueAnomaly
function utilDtTrue {
	parameter pAnomaly.
	parameter pOrbit is orbit.
	return utilAngleTo360(utilMeanFromTrue(pAnomaly) - utilMeanFromTrue(pOrbit:trueAnomaly)) / 360 * pOrbit:period.
}
