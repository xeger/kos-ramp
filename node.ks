/////////////////////////////////////////////////////////////////////////////
// Run node
/////////////////////////////////////////////////////////////////////////////
// Execute a maneuver node, warping if necessary to save time.
/////////////////////////////////////////////////////////////////////////////

run lib_ui.

local nd is nextnode.
local epsilon is 0.25.

local nstages is 0.

lock accel to ship:availablethrust / ship:mass.

// keep ship pointed at node
sas off.
lock steering to lookdirup(nd:deltav, ship:facing:topvector).

// estimate direction & duration
local np is lookdirup(nd:deltav, ship:facing:topvector).
local dob is (nd:deltav:mag / accel).

wait until vdot(facing:forevector, np:forevector) >= 0.99.

run warp(nd:eta - dob/2 - 1).

local tset is 0.
lock throttle to tset.

local done  is false.
local dv0   is nd:deltav.
local dvMin is dv0:mag.

until done
{
    if(nd:deltav:mag < dvMin) {
        set dvMin to nd:deltav:mag.
    }

    if accel > 0 {
      //feather the throttle
      set tset to min(dvMin/accel, 1.0).

      if vdot(dv0, nd:deltav) < 0 {
          // cut the throttle as soon as our nd:deltav and initial deltav
          // start facing opposite dir ections
          lock throttle to 0.
          set done to true.
      } else if nd:deltav:mag > dvMin + 0.1 {
          lock throttle to 0.
          set done to true.
      }
    } else {
        // no accel -- out of fuel; time to auto stage!
        uiWarning("Node", "Stage " + stage:number + " separation during burn").
        stage.
        wait until stage:ready.
    }
}

unlock steering.
unlock throttle.
set ship:control:pilotmainthrottle to 0.

if nd:deltav:mag > 0.1 {
  rcs on.
  local t0 is time.
  until nd:deltav:mag < 0.1 or (time - t0):seconds > 15 {
    local sense is ship:facing.
    local dirV is V(
      vdot(nd:deltav, sense:starvector),
      vdot(nd:deltav, sense:upvector),
      vdot(nd:deltav, sense:vector)
    ).

    set ship:control:translation to dirV:normalized.
  }
  set ship:control:translation to 0.
  rcs off.
}

if nd:deltav:mag > dv0:mag * 0.05 {
  uiError("Node", "VARIANCE " + round(nd:deltav:mag, 1) + " m/s").
  wait 5.
  reboot.
} else if nd:deltav:mag > 0.1 {
  uiWarning("Node", "VARIANCE " + round(nd:deltav:mag, 1) + " m/s").
}

remove nd.
sas on.
