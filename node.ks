/////////////////////////////////////////////////////////////////////////////
// Run node
/////////////////////////////////////////////////////////////////////////////
// Execute a maneuver node, warping if necessary to save time.
/////////////////////////////////////////////////////////////////////////////

run once lib_ui.
run once lib_util.
// Configuration constants; these are pre-set for automated missions; if you
// have a ship that turns poorly, you may need to decrease these and perform
// manual corrections.
global node_bestFacing is 5.   // ~5  degrees error (10 degree cone)
global node_okFacing   is 20.  // ~20 degrees error (40 degree cone)
 
local sstate is sas. // Save SAS State

// quo vadis?
global nodeNd is nextnode.

// Remember fuel level when we autostage to keep us from autostaging the
// craft to death. This assumes that  "terminal stages" have no fuel, just
// chutes and other descend-y things.
global nodeStageFuelInit is 0.

// keep ship pointed at node
sas off.
lock NodeSteerDir to utilFaceBurn(lookdirup(nodeNd:deltav, ship:up:vector)). 
lock steering to NodeSteerDir.

// estimate burn direction & duration
global nodeAccel is uiAssertAccel("Node").
global nodeFacing is lookdirup(nodeNd:deltav, ship:facing:topvector).
global nodeDob is (nodeNd:deltav:mag / nodeAccel).

uiDebug("Orient to burn").
// If have time, wait to ship almost align with maneuver node.
// If have little time, wait at least to ship face in general direction of node
// This prevents backwards burns, but still allows steering via engine thrust.
// If ship is not rotating for some reason, will proceed anyway. (Maybe only torque source is engine gimbal?)
local orientationOk is false.
until orientationOk {
  wait 0. //Noticed a performance issue with crafts with many parts. This forces the loop to wait one physics tick.
  local steerVec is utilFaceBurn(lookdirup(nodeNd:deltav, ship:up:vector)):vector.
  if  utilIsShipFacing(steerVec,node_bestFacing,0.5) or
      ((nodeNd:eta <= nodeDob / 2) and utilIsShipFacing(steerVec,node_okFacing,5)) or 
      ship:angularvel:mag < 0.0001 { set orientationOk to true. }
}

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
    wait 0. //Let a physics tick run each loop.

    set nodeAccel to ship:availablethrust / ship:mass.

    if(nodeNd:deltav:mag < nodeDvMin) {
        set nodeDvMin to nodeNd:deltav:mag.
    }

    if nodeAccel > 0 {
      if utilIsShipFacing(NodeSteerDir:vector,node_okFacing,2) {
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
// Release all controls to be safe.
unlock steering.
unlock throttle.
unlock NodeSteerDir.
set ship:control:neutralize to true.
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
set sas to sstate.