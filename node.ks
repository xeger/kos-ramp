/////////////////////////////////////////////////////////////////////////////
// Run node
/////////////////////////////////////////////////////////////////////////////
// Execute a maneuver node, warping if necessary to save time.
/////////////////////////////////////////////////////////////////////////////

run once lib_ui.
run once lib_util.

// Configuration constants; these are pre-set for automated missions. If you
// have a ship that turns poorly, you may need to decrease these and perform
// manual corrections.
global node_bestFacing is 0.995. // ~5  degrees error (10 degree cone)
global node_okFacing   is 0.94.  // ~20 degrees error (40 degree cone)
 
local sstate is sas. // Save SAS State

// quo vadis?
global nodeNd is nextnode.

// Remember fuel level when we autostage to keep us from autostaging the
// craft to death. This assumes that  "terminal stages" have no fuel, just
// chutes and other descend-y things.
global nodeStageFuelInit is 0.

// keep ship pointed at node
sas off.
lock steering to utilFaceBurn(lookdirup(nodeNd:deltav, ship:up:vector)).

// estimate burn direction & duration
global nodeAccel is uiAssertAccel("Node").
global nodeFacing is lookdirup(nodeNd:deltav, ship:facing:topvector).
global nodeDob is (nodeNd:deltav:mag / nodeAccel).

uiDebug("Orient to burn").
// If have time, wait to ship almost align with maneuver node.
// If have little time, wait at least to ship face inside 40º cone from the node.
// This prevents backwards burns, but still allows steering via engine thrust.
wait until (vdot(facing:forevector, nodeFacing:forevector) >= node_bestFacing) or
           ((nodeNd:eta <= nodeDob / 2) and (vdot(facing:forevector, nodeFacing:forevector) >= node_okFacing)).

// warp to burn time; give 15 seconds slack for final steering adjustments
global nodeHang is (nodeNd:eta - nodeDob/2) - 15.
uiDebug("Warping " + round(nodeHang) + " seconds").
if nodeHang > 0 {
  run warp(nodeHang).
  wait 15.
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
      if(vdot(facing:forevector, nodeFacing:forevector) >= node_okFacing) {
        //feather the throttle
        set ship:control:pilotmainthrottle to min(nodeDvMin/nodeAccel, 1.0).
      } else {
        // we are not facing correctly! cut back thrust to 10% so gimbaled
        // engine will push us back on course
        set ship:control:pilotmainthrottle to 0.1.
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

set ship:control:pilotmainthrottle to 0.
unlock steering.

// Make fine adjustments using RCS (for up to 15 seconds)
lock ndDeltaV to -nodeNd:deltav.
utilRCSCancelVelocity(ndDeltaV@,0.1,15).

// Fault if remaining dv > 5% of initial AND mag is > 0.1 m/s
if nodeNd:deltav:mag > nodeDv0:mag * 0.05 and nodeNd:deltav:mag > 0.1 {
  uiFatal("Node", "BURN FAULT " + round(nodeNd:deltav:mag, 1) + " m/s").
} else if nodeNd:deltav:mag > 0.1 {
  uiWarning("Node", "BURN FAULT " + round(nodeNd:deltav:mag, 1) + " m/s").
}

remove nodeNd.
unlock steering.
set sas to sstate.