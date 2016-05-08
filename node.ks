/////////////////////////////////////////////////////////////////////////////
// Run node
/////////////////////////////////////////////////////////////////////////////
// Execute a maneuver node, warping if necessary to save time.
/////////////////////////////////////////////////////////////////////////////

run lib_ui.

// quo vadis?
global nodeNd is nextnode.

// a delta-v so small that it might as well be nothing...
global nodeEpislon is 0.01.

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

    if nodeAccel > nodeEpislon {
      //feather the throttle
      set ship:control:pilotmainthrottle to min(nodeDvMin/nodeAccel, 1.0).

      if vdot(nodeDv0, nodeNd:deltav) < 0 {
          // cut the throttle as soon as our nodeNd:deltav and initial deltav
          // start facing opposite directions (i.e. if we overshoot)
          set ship:control:pilotmainthrottle to 0.
          set nodeDone to true.
      } else if nodeNd:deltav:mag > nodeDvMin + 0.05 {
          // our burn dv has started to INCREASE again; we haven't overshot,
          // but node has gone all wobbly and we can't rely on main engine
          // for any more dv progress.
          set ship:control:pilotmainthrottle to 0.
          set nodeDone to true.
      }
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

unlock steering.
set ship:control:pilotmainthrottle to 0.

// Make fine adjustments using RCS (for up to 15 seconds)
if nodeNd:deltav:mag > 0.1 {
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

if nodeNd:deltav:mag > nodeDv0:mag * 0.05 and nodeNd:deltav:mag > nodeEpislon {
  uiFatal("Node", "BURN FAULT " + round(nodeNd:deltav:mag, 1) + " m/s").
} else if nodeNd:deltav:mag > 0.1 {
  uiWarning("Node", "BURN FAULT " + round(nodeNd:deltav:mag, 1) + " m/s").
}

remove nodeNd.
sas on.
