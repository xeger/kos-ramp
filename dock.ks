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
// NOTE -- to make this more usable, I need some stuff from kOS core:
//   - tell if I have a target
//   - tell if target is vessel or part (currently cheat with mass)
//   - unset target
//   - set control to my part (optional? still be nice!)
//
// TODO
//   - choose port better
/////////////////////////////////////////////////////////////////////////////

run lib_ui.
run lib_dock.

local myPort is dockChoosePorts().
local hisPort is target.
local station is target:ship.

if myPort <> 0 {
  uiBanner("Dock", "Dock with " + station:name).
  dockPrepare(myPort, target).

  until target <> hisPort or dockComplete(myPort) {
    local rawD is target:position - myPort:position.
    local sense is ship:facing.

    local dockD is V(
      vdot(rawD, sense:starvector),
      vdot(rawD, sense:upvector),
      vdot(rawD, sense:vector)
    ).
    local rawV is station:velocity:orbit - ship:velocity:orbit.
    local dockV is V(
      vdot(rawV, sense:starvector),
      vdot(rawV, sense:upvector),
      vdot(rawV, sense:vector)
    ).
    local needAlign is vdot(target:position:normalized, target:facing:forevector) > -0.9975.

    uiShowPorts(myPort, target, dock_start / 2, not needAlign).
    uiDebugAxes(myPort:position, sense, v(10,10,10)).

    if dockD:Z < 0 {
      dockBack(dockD, dockV).
    } else if needAlign or dockD:Z > dock_start {
      dockAlign(dockD, dockV).
    } else {
      dockApproach(dockD, dockV).
    }
  }

  uiBanner("Dock", "Docking complete").
  dockFinish().
} else {
  uiError("Dock", "No suitable docking port; try moving closer?").
}
