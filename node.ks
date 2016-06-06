/////////////////////////////////////////////////////////////////////////////
// Run node
/////////////////////////////////////////////////////////////////////////////
// Execute a maneuver node, warping if necessary to save time.
/////////////////////////////////////////////////////////////////////////////

run lib_ui.

// quo vadis?
global nodeNd is nextnode.

// Remember fuel level when we autostage to keep us from autostaging the
// craft to death. This assumes that  "terminal stages" have no fuel, just
// chutes and other descend-y things.
global nodeStageFuelInit is 0.

// keep ship pointed at node
sas off.
lock steering to lookdirup(nodeNd:deltav, ship:facing:topvector).

// estimate burn direction & duration
global nodeAccel is uiAssertAccel("Node").
global nodeFacing is lookdirup(nodeNd:deltav, ship:facing:topvector).
global nodeDob is (nodeNd:deltav:mag / nodeAccel).

uiDebug("Orient to burn").
wait until vdot(facing:forevector, nodeFacing:forevector) >= 0.995 or nodeNd:eta <= nodeDob / 2.

// warp to burn time; give 3 seconds slack for final steering adjustments
global nodeHang is (nodeNd:eta - nodeDob/2) - 3.
if nodeHang > 0 {
  run warp(nodeHang).
  wait 3.
}

global nodeDone  is false.
global nodeDv0   is nodeNd:deltav.
global nodeDvMin is nodeDv0:mag.

uiDebug("Begin burn").

until nodeDone
{
    set nodeAccel to ship:availablethrust / ship:mass.

    if(nodeNd:deltav:mag < nodeDvMin) {
        set nodeDvMin to nodeNd:deltav:mag.
    }

    if nodeAccel > 0 {
      //feather the throttle
      if vdot(facing:forevector, nodeFacing:forevector) > 0.9 {
        set ship:control:pilotmainthrottle to min(nodeDvMin/nodeAccel, 1.0).
      } else {
        set ship:control:pilotmainthrottle to 0.
      }

      // three conditions for being done:
      //   1) overshot (node delta vee is pointing opposite from initial)
      //   2) burn DV increases (off target due to wobbles)
      //   3) burn DV gets too small for main engines to cope with
      set nodeDone to (vdot(nodeDv0, nodeNd:deltav) < 0) or
                      (nodeNd:deltav:mag > nodeDvMin + 0.1) or
                      (nodeNd:deltav:mag <= 0.2).
    } else {
        // no nodeAccel -- out of fuel; time to auto stage!
        uiWarning("Node", "Stage " + stage:number + " separation during burn").
        local now is time:seconds.

        if nodeStageFuelInit = 0 or stage:liquidfuel < nodeStageFuelInit {
          stage.
          wait until stage:ready.
          set nodeStageFuelInit to stage:liquidfuel.
        }
    }
}
lock throttle to 0.
set ship:control:pilotmainthrottle to 0.
unlock steering.

// Make fine adjustments using RCS (for up to 15 seconds)
if nodeNd:deltav:mag > 0.1 {
  uiDebug("Fine tune with RCS").
  rcs on.
  local t0 is time.
  until nodeNd:deltav:mag < 0.1 or (time - t0):seconds > 15 {
    local sense is ship:facing.
    local dirV is V(
      vdot(nodeNd:deltav, sense:starvector),
      vdot(nodeNd:deltav, sense:upvector),
      vdot(nodeNd:deltav, sense:vector)
    ).

    set ship:control:translation to dirV:normalized.
  }
  set ship:control:translation to 0.
  rcs off.
}

// Fault if remaining dv > 5% of initial AND mag is > 0.1 m/s
if nodeNd:deltav:mag > nodeDv0:mag * 0.05 and nodeNd:deltav:mag > 0.1 {
  uiFatal("Node", "BURN FAULT " + round(nodeNd:deltav:mag, 1) + " m/s").
} else if nodeNd:deltav:mag > 0.1 {
  uiWarning("Node", "BURN FAULT " + round(nodeNd:deltav:mag, 1) + " m/s").
}

remove nodeNd.
sas on.
