@lazyglobal off.
/////////////////////////////////////////////////////////////////////////////
// Depart
/////////////////////////////////////////////////////////////////////////////
// Undocks and departs the ship.
//
// Finds a docked port, undock it and use RCS to back away, then return the
// control to the root/control part.
/////////////////////////////////////////////////////////////////////////////

Parameter dockPort is 0.

runoncepath("lib_dock").
runoncepath("lib_util").
runoncepath("lib_ui").

local departDistance is 90.
local departSpeed is 3.
local stepWait is 3.

local DPort is dockChooseDeparturePort().
if dockPort <> 0 and dockPort:isType("DockingPort") set DPort to dockPort.

local targetUndock is core:vessel.

if DPort <> 0 {
	wait stepWait. uiBanner("Depart", "Releasing the dock port", 2).
	// Undocks and wait a little to physics stabilize.
	DPort:undock(). wait stepWait.

	// Switch control to our vessel and target the one we just undocked.
	uiBanner("Depart", "Controlling from " + ship:name).
	set KUniverse:ActiveVessel to core:vessel. wait stepWait.
	set target to targetUndock. wait stepWait.
	uiBanner("Depart", "Departing from " + target:name).

	// Back up from the target
	rcs on.
	lock steering to ship:facing.
	local lock targetSpeed to -(target:velocity:orbit - ship:velocity:orbit).
	until targetSpeed:mag >= departSpeed or target:distance >= departDistance {
		local Thrust is min(1, max(0.1, departSpeed - targetSpeed:mag)).
		set ship:control:translation to v(0, 0,-Thrust).
		wait 0.
	}
	set ship:control:translation to v(0, 0, 0).
	wait until target:distance >= departDistance.

	// Restore control to the default part
	// The default part is the root part or the first controllable one it can fine.
	// To override it, Tag a part as "Control" in VAB/SPH.
	dockControlFromCore(dockDefaultControlPart()).
	lock steering to lookdirup(-target:position, ship:up:vector).
	wait until utilIsShipFacing(-target:position, 10, 0.1).
	utilRCSCancelVelocity(targetSpeed@, 0.1).
	unlock steering.
	ship:control:neutralize on.
	sas on.
	rcs off.
	uiBanner("Depart", "Departed from " + targetUndock:name, 2).
} else {
	uiError("Depart", "No docking port is docked now").
}
