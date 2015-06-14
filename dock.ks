/////////////////////////////////////////////////////////////////////////////
// Docking guidance.
/////////////////////////////////////////////////////////////////////////////
// Draw some vectors and provide helpful prompts to lead the pilot
// through docking.
/////////////////////////////////////////////////////////////////////////////

run lib_ui.
run lib_dock.

sas off.

// NEED from KOS CORE:
//   - tell if I have a target
//   - tell if target is vessel or part
//   - unset target
//   - set control to my part (optional? still be nice!)

local myPort is dockChoosePorts().
lock steering to lookdirup(-target:portfacing:forevector, ship:facing:upvector).

if myPort = 0 {
  uiError("Dock", "Switch ship control to a docking port").
  local die is 1/0.
}

lock dockDot to vdot(target:position:normalized, target:facing:forevector).
lock apchDot to vdot(target:position:normalized, target:facing:forevector).

until dockComplete(myPort) {
  if dockDot > 0 {
    dockAnnounce("Move to correct side of target").
    uiDebugAxes(myPort, target).
  } else if apchDot > -0.999 {
    dockAnnounce("Align with target").
    uiDebugAxes(myPort, target).
  }
}

uiBanner("Dock", "Aligned!").
uiDebugAxes(0,0).
sas on.
