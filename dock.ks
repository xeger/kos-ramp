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
//   - store d, v as vectors
//   - choose port better

run lib_ui.
run lib_dock.
run lib_pid.

// Constant docking parameters
local scaleApproach is 100. // Distance scaling factor (per X m)
local distApproach is 25.   // minimum initial distance from target
local distDock is 3.        // distance for final approach
local speedLimit is 5.      // max transverse/fwd speed while aligning
local speedCreep is 1.      // creep-forward speed during align/approach
local speedDock is 0.2.     // final approach

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

// Velocity controllers (during alignment)
local pidX1 is pidInit(1.4, 0.1, 2.0, -1, 1).
local pidY1 is pidInit(1.4, 0.1, 2.0, -1, 1).

// Position controllers (during approach)
local pidX2 is pidInit(0.4, 0, 1.4, -1, 1).
local pidY2 is pidInit(0.4, 0, 1.4, -1, 1).

// Shared velocity controller
local pidZ is pidInit(0.8, 0.4, 0.2, -1, 1).

lock steering to lookdirup(-target:portfacing:forevector, ship:facing:upvector).
wait until vdot(myport:portfacing:forevector, target:portfacing:forevector) < -0.99.

sas off.
rcs on.

clearscreen.

until dockComplete(myPort) {
  uiDebugAxes(myPort, target, v(dX, dY, scaleApproach)).

  local vScaleX is min(abs(dX / scaleApproach), 1).
  local vScaleY is min(abs(dY / scaleApproach), 1).
  local vWantX is -(dX / abs(dX)) * speedLimit * vScaleX.
  local vWantY is -(dY / abs(dY)) * speedLimit * vScaleY.

  if dz < 0 {
    dockAnnounce("Move to correct side of target").

    set ship:control:fore to -pidSeek(pidZ, speedLimit, vZ).
  } else if apchDot > -0.99 {
    dockAnnounce("Align with target").

    if dZ > distApproach {
      // Creep slowly forward, braking only when necessary
      if vZ > -speedCreep and vZ < -speedLimit {
        pidSeek(pidZ, -speedCreep, vZ).
        set ship:control:fore to 0.
      } else {
        set ship:control:fore to -pidSeek(pidZ, -speedCreep, vZ).
      }
    } else {
      /// Stop at distApproach
      set ship:control:fore to -pidSeek(pidZ, 0, vZ).
    }

    // Drift into alignment
    set ship:control:starboard to pidSeek(pidX1, vWantX, vX).
    set ship:control:top to pidSeek(pidY1, vWantY, vY).
  } else {
    if dZ < distDock {
      dockAnnounce("Final approach").
      set ship:control:fore to -pidSeek(pidZ, -speedDock, vZ).
    } else {
      dockAnnounce("Approach target").
      local vScaleZ is min(abs(dZ / scaleApproach), 1).
      set ship:control:fore to -pidSeek(pidZ, -max(speedCreep, speedLimit*vScaleZ), vZ).
    }

    // Stay aligned
    set ship:control:starboard to pidSeek(pidX2, 0, dX).
    set ship:control:top to pidSeek(pidY2, 0, dY).
  }
}

unlock steering.
rcs off.
sas on.

uiBanner("Dock", "Docking complete").
uiDebugAxes(0,0, v(0,0,0)).
