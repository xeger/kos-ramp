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


run lib_ui.
run lib_dock.
run lib_pid.

// Constant docking parameters
local distApproach is 10.    // minimum initial distance from target
local distDock is 1.         // distance for final approach
local speedAlign is 0.3.     // max transverse speed while aligning
local speedStay is 0.05.     // max tranverse speed during approach
local speedApproach is 0.5.  // approach speed
local speedDock is 0.1.      // final approach

sas off.

local tgtVessel is target.
local myPort is dockChoosePorts().

if myPort = 0 {
  uiError("Dock", "Switch ship control to a docking port").
  local die is 1/0.
}

// Physical state that influences the docking algorithm
lock apchDot to vdot(target:position:normalized, target:facing:forevector).
lock dX to vdot((target:position - myPort:position), myPort:portfacing:starvector).
lock dY to vdot((target:position - myPort:position), myPort:portfacing:upvector).
lock dZ to vdot((target:position - myPort:position), myPort:portfacing:vector).
lock vX to vdot((tgtVessel:velocity:orbit - ship:velocity:orbit), myPort:portfacing:starvector).
lock vY to vdot((tgtVessel:velocity:orbit - ship:velocity:orbit), myPort:portfacing:upvector).
lock vZ to vdot((tgtVessel:velocity:orbit - ship:velocity:orbit), myPort:portfacing:vector).

// PID controllers to use during alignment
local pidX1 is pidInit(1, 0, 4, -1, 1).
local pidY1 is pidInit(1, 0, 4, -1, 1).
local pidZ1 is pidInit(1, 1, 1, -1, 1).

// PID controllers to use during approach
local pidX2 is pidInit(1, 0, 0, -0.2, 0.2).
local pidY2 is pidInit(1, 0, 0, -0.2, 0.2).
local pidZ2 is pidInit(1, 1, 1, -1, 1).

lock steering to lookdirup(-target:portfacing:forevector, ship:facing:upvector).
wait until vdot(myport:portfacing:forevector, target:portfacing:forevector) < -0.99.

rcs on.

until dockComplete(myPort) {
  uiDebugAxes(myPort, target).

  if dz < 0 {
    dockAnnounce("Move to correct side of target").

    set ship:control:fore to -pidSeek(pidZ1, speedApproach * 4, vZ).
  } else if apchDot > -0.999 {
    dockAnnounce("Align with target").

    // Don't approach if we aren't aligned
    set ship:control:fore to -pidSeek(pidZ1, 0, vZ).

    // Drift into alignment with target
    local actStar is pidSeek(pidX1, 0, dX).
    local actTop  is pidSeek(pidY1, 0, dY).
    if (dx < 0 and vx < speedAlign) or (dx > 0 and vx > -speedAlign) {
      set ship:control:starboard to actStar.
    } else {
      set ship:control:starboard to 0.
    }
    if (dy < 0 and vy < speedAlign) or (dy > 0 and vy > -speedAlign) {
      set ship:control:top to actTop.
    } else {
      set ship:control:top to 0.
    }
  } else {
    if dZ > distDock {
      dockAnnounce("Approach target").
      set ship:control:fore to -pidSeek(pidZ2, -speedApproach, vZ).
    } else {
      dockAnnounce("Final approach").
      set ship:control:fore to -pidSeek(pidZ2, -speedDock, vZ).
    }

    // Stay aligned
    local actStar is pidSeek(pidX2, 0, dX).
    local actTop  is pidSeek(pidY2, 0, dY).
    if (dx < 0 and vx < speedStay) or (dx > 0 and vx > -speedStay) {
      set ship:control:starboard to actStar.
    } else {
      set ship:control:starboard to 0.
    }
    if (dy < 0 and vy < speedStay) or (dy > 0 and vy > -speedStay) {
      set ship:control:top to actTop.
    } else {
      set ship:control:top to 0.
    }
  }
}

uiBanner("Dock", "Docking complete").
uiDebugAxes(0,0).

sas on.
rcs off.
