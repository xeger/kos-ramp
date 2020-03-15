@lazyglobal off.

function roverStabilzeJump {
	parameter N is TerrainNormalVector().
	// Needs lib_terrain and lib_parts to run in the main program!

	// Declarations
	local StartLand is 0.
	local StartJump is time:seconds.
	local LongJump is false.
	local LongJumpST is 3. // Settle time for Long Jumps
	local ShortJumpST is 1. // Settle time for Short Jumps or roll overs
	local Stabilized is false.

	// Ease wheels controls
	set SHIP:CONTROL:WHEELTHROTTLE to 0.
	set SHIP:CONTROL:WHEELSTEER to 0.

	// Try to steer the rover straight with terrain
	LOCK STEERING TO LOOKDIRUP(vxcl(N, VELOCITY:SURFACE), SHIP:UP:vector).
	RCS on. SAS off.
	partsEnableReactionWheels().

	Until Stabilized {
		if ship:status <> "LANDED" { // Deals with rover while in air
			// Use RCS to try to soften the landing if predicted airtime is greater than 1 second.
			if ALT:RADAR / ship:verticalspeed > 1 {
				local sense is ship:facing.
				local dirV is V(
					vdot(ship:up:vector, sense:starvector),
					vdot(ship:up:vector, sense:upvector),
					vdot(ship:up:vector, sense:vector)
				).
				set ship:control:translation to dirV:normalized.
			}
			// Stop the RCS translation up.
			else set ship:control:translation to v(0, 0, 0).
			// Detects long jumps
			if time:seconds - StartJump > 3 set longJump to True.
			set StartLand to 0.
		} else { // Deals with rover on ground
			if StartLand = 0 { // Means it just landed or started a rollover
				SET StartLand to TIME:SECONDS.
			} else if longJump and time:seconds - StartLand <= LongJumpST { // Stabilze landing
				local sense is ship:facing.
				local dirV is V(
					vdot(-ship:up:vector, sense:starvector),
					vdot(-ship:up:vector, sense:upvector),
					vdot(-ship:up:vector, sense:vector)
				).
				set ship:control:translation to dirV:normalized.
			} else if time:seconds - StartLand > ShortJumpST {
				SET Stabilized to True.
			}
		}
		wait 0.
	}
	// Reset ship controls
	SAS OFF. RCS OFF. UNLOCK STEERING.
	SET ship:control:translation to v(0, 0, 0).
	partsDisableReactionWheels().
	return LongJump.
}

function roverIsRollingOver {
	parameter N is TerrainNormalVector().
	parameter Limit is 20.
	return vang(vxcl(ship:facing:vector, ship:facing:upvector), vxcl(ship:facing:vector, N)) > Limit.
}
