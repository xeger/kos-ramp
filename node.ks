// Execute a maneuver node, warping if necessary to save time.

// Example:
//	run node_peri(orbit:apoapsis). // create the node
//	run node. // execute the node
// Advanced:
//	function create_node { ... }
//	run node(create_node@). // create and execute the node using delegate
// Advanced 2:
//	run node({run node_alt(alt).}). // using anonymous function/delegate
// Manual:
//	run node("",0,{return eta:apoapsis.},{
//		parameter dt.
//		local pos is ship:position.
//		local vel is velocity:orbit.
//		if dt <= 1 and Career():canMakeNodes {
//			local t is time:seconds+dt.
//			set pos to positionAt(t).
//			set vel to velocityAt(t).
//		}
//		set pos to pos-body:position.
//		return sqrt(body:mu/pos:mag)*vcrs(pos,vcrs(vel,pos))-vel.
//	}).

parameter nodeCreator	is "".	// delegate to re-create node if needed
parameter burnTime		is 0.	// [parameter dv] estimated burn time, scalar or delegate, lib_staging:burnTimeForDt@ used if zero
parameter nodeEta		is "".	// [no parameter] delegate for dynamic eta to node/burn (can be used without node)
parameter nodeDeltaV	is "".	// [parameter dt] dynamic deltaV creation (can be used without node)

local manual is nodeDeltaV:istype("delegate").

// for sure
set ship:control:pilotMainThrottle to 0.
unlock all.

run once lib_ui.
run once lib_util.
run once lib_warp.
run once lib_staging.

if not (defined node_bestFacing)
global node_bestFacing is 1.   // ~1  degree  error ( 2 degrees cone)
if not (defined node_okFacing)
global node_okFacing   is 10.  // ~10 degrees error (20 degrees cone)

stagingPrepare().
local sstate is sas. // save SAS state
local rstate is rcs. // save RCS state
sas off.

if not hasNode {
	if nodeCreator:istype("delegate") and Career():canMakeNodes
		nodeCreator().
	if not hasNode and (not nodeDeltaV:istype("delegate") or not nodeEta:istype("delegate"))
		uiFatal("Node", "No node to execute").
}
if not nodeEta:istype("delegate") set nodeEta to { return nextNode:eta. }.
if not nodeDeltaV:istype("delegate") set nodeDeltaV to { parameter dt. return nextNode:deltaV. }.

// estimate burn direction & duration
if burnTime = 0 set burnTime to burnTimeForDv@.
local xt is 0.
local dm is nodeDeltaV(nodeEta()):mag.
if burnTime:istype("delegate") set xt to burnTime(dm)/2.
else set xt to burnTime/2. //scalar, provided as parameter
uiConsole("Node", "Estimated dV: "+round(dm,1)+" Burn Time: " + round(xt*2)).
local function steerDir {
	local dt is nodeEta().
	local dv is nodeDeltaV(dt).
	if Career():canMakeNodes
		return lookdirup(dv, positionAt(ship,time:seconds+dt)-body:position).
	return dv.
}
lock steering to steerDir().

// warp near node
local dt is nodeEta()-xt.
if dt > 0 {
	uiBanner("Node", "Warping " + round(dt) + " seconds", 0).
	local warpLoop is 3.
	if dt < 3600 set warpLoop to 2.
	if dt < 60 set warpLoop to 1.
	if dt < 10 set warpLoop to 0.
	until warpLoop = 0 {
		wait 0.
		local warped to false.
		local start is time:seconds.
		local checkRcs is not rcs.
		until utilIsShipFacing(steering,node_bestFacing,0.5) or
			nodeEta() <= xt and utilIsShipFacing(steering,node_okFacing,5) or
			ship:angularvel:mag < 0.0001 and rcs and time:seconds-start > 1
		{
			if checkRcs {
				if ship:angularvel:mag > 0.01
					set checkRcs to false.
				else if time:seconds-start > 1 {
					set checkRcs to false.
					if ship:angularvel:mag < 0.001  {
						uiBanner("Node", "Enabling RCS, AV="+round(ship:angularvel:mag,3),0).
						rcs on.
					}
				}
			}
			if not stagingCheck() wait 0.
			if not warped { set warped to true. physWarp(1). }
		}
		if warped resetWarp().
		if warpLoop > 1 {
			local extra is 60.
			if warpLoop > 2 set extra to max(3600, nodeEta()*.99).
			if (warpSeconds(nodeEta() - xt - extra) > 600 and nodeCreator:istype("delegate")) {
			//	recreate node if warped more than 10 minutes and we have node creator delegate
				unlock steering.
				utilRemoveNodes().
				nodeCreator().
				wait 0.
				if burnTime:istype("delegate") set dt to burnTime(nodeDeltaV(nodeEta()):mag)/2.
				sas off.
				lock steering to steerDir().
			}
			set warpLoop to 1.
		} else {
			warpSeconds(nodeEta() - xt - 10).
			break.
		}
	}
}

// burn
local dt is nodeEta().
local t1 is time:seconds + dt.
local dv is nodeDeltaV(dt).
local dv0 is dv.
local dvLast is dv.
local dvMin is dv0:mag.
local minThrottle is 0.
local maxThrottle is 0.
local function update {
//	dt and dv reused by steering
	set dt to t1-time:seconds.
	set dv to nodeDeltaV(dt).
	set dvMin to min(dvMin,dv:mag).
	if dvMin >= 0.01 set dvLast to dv.
	return min(maxThrottle,max(minThrottle,min(1,dvMin*ship:mass/max(1,availableThrust)))).
}
lock throttle to update().
lock steering to dvLast.
//TODO: make a variable, lock steering to it and update in a loop using utilFaceBurn

local almostThere to 0.
local choked to 0.
local warned to false.

if dt-xt > 5 {
	physWarp(1).
	wait until dt-xt <= 2.
	resetWarp().
}
wait until dt-xt <= 1.

uiBanner("Node", "Burn started", 0).
until dvMin < 0.05
{
	if stagingCheck() uiWarning("Node", "Stage " + (stage:number+1) + " separation during burn", 0).
	wait 0. //Let a physics tick run each loop.

	if ship:availablethrust > 0 {
		if utilIsShipFacing(steering,node_okFacing,2) {
			set minThrottle to 0.01.
			set maxThrottle to 1.
		} else {
			// we are not facing correctly! cut back thrust to 10% so gimbaled
			// engine will push us back on course
			set minThrottle to 0.1.
			set maxThrottle to 0.1.
			rcs on.
	 	}
		if vdot(dv0, dv) < 0 {
		//	overshot - node delta vee is pointing opposite from initial
			uiWarning("Node", "Overshot", 3).
			break.
		}
		local dm is dv:mag.
		if dm > dvMin + 0.1 and (not manual or dm > dvMin + max(1,dv0:mag*0.01)) {
		//	burn DV increases (off target due to wobbles)
			uiWarning("Node", "DeltaV Increase: "+round(dm,2)+" > "+round(dvMin,2), 2).
			break.
		}
		if dm < 0.2 {
		//	burn DV gets too small for main engines to cope with (maybe)
			if almostThere = 0 {
				set maxThrottle to 0.2.
				set almostThere to time:seconds.
				uiConsole("Node", "Remaining dv="+round(dm,2)).
			}
			if time:seconds-almostThere > 5 break.
			if dm < 0.05 {
				set maxThrottle to 0.025.
				if dm > 0 {
					set almostThere to time:seconds.
					wait until time:seconds-almostThere > 0.3 or dm > 0.05.
				}
				break.
			}
		}
		set choked to 0.
	} else {
		if choked = 0 set choked to time:seconds.
		if not warned and time:seconds-choked > 3 {
			set warned to true.
			uiWarn("Node", "No acceleration").
		}
		if time:seconds-choked > 30
			uiFatal("Node", "No acceleration").
	}
}

set ship:control:pilotMainThrottle to 0.
unlock throttle.
local dm is nodeDeltaV(t1-time:seconds):mag.
uiConsole("Node", "Burn finished, dv="+round(dm,2)+", min="+round(dvMin,2)).

// Make fine adjustments using RCS (for up to 15 seconds)
local limit is 0.1.
if manual set limit to 0.5.
if dm > limit {
	utilRCSCancelVelocity({return nodeDeltaV(t1-time:seconds).},limit/2,15).
	// Fault if remaining dv > 5% of initial AND mag is > 0.1 m/s
	local dm is nodeDeltaV(t1-time:seconds):mag.
	if dm > limit {
		if dm > dv0:mag * 0.05
			uiFatal("Node", "BURN FAULT " + round(dm, 1) + " m/s").
		if dm > limit and (not manual or dm > 1)
			uiWarning("Node", "BURN FAULT " + round(dm, 1) + " m/s").
	}
}

if hasNode remove nextNode.
// Release all controls to be safe.
unlock all.
set ship:control:neutralize to true.
set sas to sstate.
set rcs to rstate.
