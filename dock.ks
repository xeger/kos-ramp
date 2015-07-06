/////////////////////////////////////////////////////////////////////////////
// Dock
/////////////////////////////////////////////////////////////////////////////
// Dock with the target.
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
/////////////////////////////////////////////////////////////////////////////

// TODO
//   - choose port better

clearvecdraws().
run lib_ui.
run lib_dock.

local tgtVessel is 0.
// HACK: distinguish between targeted vessel and targeted port using mass > 2 tonnes
if target:mass < 2 {
  set tgtVessel to target:ship.
} else {
  set tgtVessel to target.
}

local myPort is dockChoosePorts().

if myPort <> 0 {
  sas off.

  lock steering to lookdirup(-target:portfacing:forevector, target:portfacing:upvector).
  wait until vdot(myport:portfacing:forevector, target:portfacing:forevector) < -0.99.

  rcs on.

  lock rawD to target:position - myPort:position.
  lock dockD to V(
    vdot(rawD, myPort:portfacing:starvector),
    vdot(rawD, myPort:portfacing:upvector),
    vdot(rawD, myPort:portfacing:vector)
  ).
  lock rawV to tgtVessel:velocity:orbit - ship:velocity:orbit.
  lock dockV to V(
    vdot(rawV, myPort:portfacing:starvector),
    vdot(rawV, myPort:portfacing:upvector),
    vdot(rawV, myPort:portfacing:vector)
  ).
  lock needAlign to (apchDot > -0.995).
  lock apchDot to vdot(target:position:normalized, target:facing:forevector).

  until dockComplete(myPort) {
    uiShowPorts(myPort, target, dock_start / 2, not needAlign).
    uiDebugAxes(myPort:position, myPort:portfacing, dockD).

    if dockD:Z < 0 {
      uiBanner("Dock", "Back off from target").
      dockBack(dockD, dockV).
    } else if needAlign {
      uiBanner("Dock", "Align with target").
      dockAlign(dockD, dockV).
    } else {
      uiBanner("Dock", "Approach target").
      dockApproach(dockD, dockV).
    }
  }

  unlock steering.
  rcs off.
  sas on.

  uiBanner("Dock", "Docking complete").
  uiShowPorts(0, 0, 0, false).
  uiDebugAxes(0,0, v(0,0,0)).
} else {
  uiError("Dock", "No suitable docking port; try moving closer?").
}
