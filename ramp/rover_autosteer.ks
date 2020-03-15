@lazyglobal off.

parameter TargetToFollow.
parameter DistanceToFollow is 30.
parameter speedlimit is 28. // Speed limit. Default 28m/s ~ 100km/h
parameter turnfactor is 5. // Turnfactor
parameter BreakTime is 3. // Time the craft need to stop with brakes.

runoncepath("lib_ui").
runoncepath("lib_parts").
runoncepath("lib_terrain").
runoncepath("lib_rover").


local wtVAL is 0. // Wheel Throttle Value
local kTurn is 0. // Wheel turn value.
local targetspeed is 0.
local targetdistance is 0.
local targetBearing is 0.
local runmode is 0.
local RelSpeed is ship:groundspeed.
local FollowingVessel is false.
local gs is 0.
local Waypoints is queue().
local NotifyInterval is 10.
local LastNotify is 0.
local NextWaypoint is 0.
local N is TerrainNormalVector().
local turnlimit is 0.

///////////////
// Main program
///////////////

// Deal with targets
if TargetToFollow:istype("vessel") {
	// Following another rover
	FollowingVessel on.
	lock CoordToFollow to TargetToFollow:geoposition.
} else if TargetToFollow:istype("GeoCoordinates") {
	// Going to one point
	FollowingVessel off.
	lock CoordToFollow to TargetToFollow.
} else if TargetToFollow:istype("List") {
	// Following a list of waypoints
	for item in TargetToFollow {
		if item:istype("GeoCoordinates") waypoints:push(Item).
	}
	set NextWaypoint to ship:geoposition.
	Lock CoordToFollow to NextWaypoint.
}

// Reset controls
set ship:control:neutralize to true.
set ship:control:pilotmainthrottle to 0.
brakes off.
sas off.
rcs off.
lights on.
fuelcells on.
partsDisableReactionWheels().
partsExtendAntennas().

// Check if rover is in a good state to be controlled.
if ship:status = "PRELAUNCH" {
	uiWarning("Rover", "Rover is in Pre-Launch State. Launch it!").
	wait until ship:status <> "PRELAUNCH".
} else if ship:status <> "LANDED" {
	uiError("Rover", "Can't drive a rover that is " + ship:status).
	set runmode to -1.
}

local WThrottlePID is pidloop(0.15, 0.005, 0.020, -1, 1). // Kp, Ki, Kd, MinOutput, MaxOutput
set WThrottlePID:setpoint to 0.

local SpeedPID is pidloop(0.3, 0.001, 0.010,-speedlimit, speedlimit).
set SpeedPID:setpoint to 0.

local WSteeringkP is 0.010.
local WSteeringPID is pidloop(WSteeringkP, 0.0001, 0.002, -1, 1). // Kp, Ki, Kd, MinOutput, MaxOutput
set WSteeringPID:setpoint to 0.


until runmode = -1 {

	set targetBearing to CoordToFollow:bearing.
	set TargetDistance to CoordToFollow:distance.
	set gs to vdot(ship:facing:vector, ship:velocity:surface).
	set turnlimit to min(1, turnfactor / abs(gs)). // Scale the turning radius based on current speed

	set N to TerrainNormalVector().

	if runmode = 0 { // Govern the rover
		// Wheel Throttle and brakes:
		if FollowingVessel or waypoints:empty() {
			// If following a vessel or have just one waypoint, use the distance from they to compute speed and braking.
			set targetspeed to SpeedPID:update(time:seconds, DistanceToFollow - TargetDistance).
			if RelSpeed > 2 set brakes to TargetDistance / RelSpeed <= BreakTime.
			else brakes off.
		} else {
			// When have a list of waypoints, use the distance to next waypoint plus cosine error to the next one to compute speed and braking.
			local SpeedFactor is waypoints:peek():distance * max(0, cos(abs(waypoints:peek():bearing))).
			set targetspeed to SpeedPID:update(time:seconds, DistanceToFollow - (TargetDistance + SpeedFactor)).
			if RelSpeed > 2 set brakes to (TargetDistance + SpeedFactor) / RelSpeed <= BreakTime.
			else brakes off.
		}
		if FollowingVessel {
			set RelSpeed to vdot(ship:facing:vector:normalized, (ship:velocity:surface - TargetToFollow:velocity:surface)).
		} else{
			set RelSpeed to gs.
		}
		set wtVAL to WThrottlePID:update(time:seconds, RelSpeed - targetspeed).


		// Steering:
		if gs < 0 set targetBearing to -targetBearing.
		set WSteeringPID:MaxOutput to 1 * turnlimit.
		set WSteeringPID:MinOutput to -1 * turnlimit.
		set WSteeringPID:kP to WSteeringkP * turnlimit * 2.
		set kturn to WSteeringPID:update(time:seconds, targetBearing).

		// Detect jumps and engage stability control
		if ship:status <> "LANDED" {
			if roverStabilzeJump(N) {
				uiBanner("Rover", "Wow, that was a long jump!").
			}
		}
		// Detect rollover
		if roverIsRollingOver(N) {
			set turnfactor to max(1, turnfactor * 0.9). // Reduce turnfactor
			roverStabilzeJump(N). // Engage Stability control
		}
	}
	// Here it really control the rover.
	set wtVAL to min(1, (max(-1, wtVAL))).
	set kTurn to min(1, (max(-1, kTurn))).
	set ship:control:wheelthrottle to wtval.
	set ship:control:wheelsteer to kTurn.

	if not FollowingVessel {
		if abs(DistanceToFollow - TargetDistance) <= DistanceToFollow {
			if waypoints:empty() set runmode to -1.
			else {
				set nextWaypoint to waypoints:pop().
				uiBanner("Rover", "Next waypoint in " + round(nextWaypoint:distance) + "m" ).
			}
		}
	}
	wait 0. // Waits for next physics tick.
}

uiBanner("Rover", "Destination reached.", 2).

// Clear before end
unlock Throttle.
unlock Steering.
partsEnableReactionWheels().
set ship:control:translation to v(0, 0, 0).
set ship:control:neutralize to true.
set ship:control:pilotmainthrottle to 0.
BRAKES on.
