/////////////////////////////////////////////////////////////////////////////
// Dock
/////////////////////////////////////////////////////////////////////////////
// Docks with the target.
//
// Chooses an arbitrary docking port on the vessel, then finds a compatible
// port on the target (or uses the selected port if a port is already
// selected).
//
// Once a port is chosen, moves the docking ports into alignment and then
// approaches at a slow speed.
/////////////////////////////////////////////////////////////////////////////


runoncepath("lib_ui").
runoncepath("lib_dock").
runoncepath("lib_parts").

local DockingDone is False.
local MaxDistanceToApproach is 5000.
local TargetVessel is 0.
if hastarget and target:istype("Vessel") set TargetVessel to Target.
else if hastarget and target:istype("DockingPort") set TargetVessel to target:ship.

until DockingDone {
	if hastarget and ship:status = "ORBITING" and TargetVessel:Distance < KUNIVERSE:DEFAULTLOADDISTANCE:ORBIT:UNPACK {

		global dock_myPort is dockChoosePorts().
		global dock_hisPort is target.

		if dock_myPort <> 0 {
			global dock_station is dock_hisPort:ship.
			uiBanner("Dock", "Dock with " + dock_station:name).
			dockPrepare(dock_myPort, target).

			until dockComplete(dock_myPort) or not hastarget or target <> dock_hisPort {
				local rawD is target:position - dock_myPort:position.
				local sense is ship:facing.

				local dockD is V(
					vdot(rawD, sense:starvector),
					vdot(rawD, sense:upvector),
					vdot(rawD, sense:vector)
				).
				local rawV is dock_station:velocity:orbit - ship:velocity:orbit.
				local dockV is V(
					vdot(rawV, sense:starvector),
					vdot(rawV, sense:upvector),
					vdot(rawV, sense:vector)
				).
				local needAlign is (abs(dockD:x) > abs(dockD:z) / 10) or (abs(dockD:y) > abs(dockD:z) / 10).

				// Avoid errors just after docking complete; hastarget is unreliable
				// (maybe due to preemptible VM) and so we also put in a distance-based safeguard.
				if hastarget and dockD:mag > 1 {
					uiShowPorts(dock_myPort, target, dock_start / 2, not needAlign).
					uiShowPorts(dock_myPort, target, dock_start / 2, not needAlign).
					uiDebugAxes(dock_myPort:position, sense, v(10, 10, 10)).
					uiDebugAxes(dock_myPort:position, sense, v(10, 10, 10)).
				}

				if dockD:Z < 0 {
					dockBack(dockD, dockV).
				} else if needAlign or dockD:Z > dock_start {
					dockAlign(dockD, dockV).
				} else {
					dockApproach(dockD, dockV, dock_myPort).
				}
				wait 0.
			}

			uiBanner("Dock", "Docking complete").
			dockFinish().
		} else {
			uiError("Dock", "No suitable docking port; try moving closer?").
		}
		DockingDone on.
	} else if hastarget and TargetVessel:Distance >= KUNIVERSE:DEFAULTLOADDISTANCE:ORBIT:UNPACK
		and Target:Distance < MaxDistanceToApproach {
		uiWarning("Dock", "Target too far, approaching.").
		run approach.
	} else if hastarget and TargetVessel:Distance >= MaxDistanceToApproach {
		uiError("Dock", "Target too far, RUN RENDEZVOUS instead.").
		DockingDone on.
	} else {
		uiError("Dock", "No target selected").
		DockingDone on.
	}
}
