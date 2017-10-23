/////////////////////////////////////////////////////////////////////////////
// Land
/////////////////////////////////////////////////////////////////////////////
// Make groundfall
/////////////////////////////////////////////////////////////////////////////

run once lib_ui.

global land_slip    is 0.05.                     // transverse speed @ touchdown (m/s)
global land_grav is body:mu / (body:radius ^ 2). // surface gravity
global land_accel is uiAssertAccel("Landing").   // our rocket's go juice
global land_descend is land_accel.               // how fast we can fall during final descent
global land_impact is 1.                         // neg. vertical speed at touchdown

lock land_ground to ship:geoposition:position.
lock land_sv to ship:velocity:surface.
lock land_svR to land_sv:mag * vdot(land_sv:normalized, land_ground:normalized) * land_ground:normalized.
lock land_svT to land_sv - land_svR.

// Control transverse speed using RCS; keep it below allowable slip velocity.
function landCounterSlip {
  if land_svT:mag > land_slip {
    local sense is ship:facing.
    local dirV is V(
      vdot(land_svT, sense:starvector),
      0,
      vdot(land_svT, sense:vector)
    ).

    set ship:control:translation to -(dirV / land_slip / 2).
  }
  else {
    set ship:control:translation to 0.
  }
}

// Perform braking until velocity starts to increase again.
function landBrake {
  local vMin is land_sv.
  until land_sv:mag > vMin:mag + 0.5 {
    if land_sv:mag < vMin:mag {
      set vMin to land_sv.
    }
    wait 0.1.
  }
}

// Determine time to impact in free fall.
function landEtaImpact {
  return (sqrt(4 * land_grav * land_ground:mag + land_svR:mag^2) - land_svR:mag) / (2*land_grav).
}

rcs on.
sas off.

// Use an orbital reference frame until we establish where
// we are in the landing process.
lock steering to lookdirup(retrograde:vector, ship:facing:upvector).
lock land_tBrake to land_sv:mag / land_accel.

local suicide is false.
local final is false.

// Perform braking burn at perigee if necessary.
if status = "ORBITING" {
  if ship:periapsis < max(body:atm:height * 0.8, body:radius * 0.2) {
    // We're still in orbit, but perigee is low enough to be considered terminal.
    // Coast to perigee and perform a braking burn.
    uiDebug("braking burn in T" + -round(eta:periapsis - land_tBrake, 1)).
    run warp(eta:periapsis - land_tBrake - 60).
    wait until vdot(retrograde:vector, ship:facing:forevector) > 0.995.
    run warp(eta:periapsis - land_tBrake - 1).
    wait until eta:periapsis < land_tBrake.
    uiBanner("Land", "Braking burn").
    lock throttle to min(land_sv:mag/land_accel, 1.0).
    landBrake.
    unlock throttle.
    set ship:control:pilotmainthrottle to 0.
  } else {
    uiFatal("Landing", "Must deorbit before landing").
  }
}

// Switch to surface reference frame.
lock steering to lookdirup((-land_ground):normalized, ship:facing:upvector).
lock land_tBrake to land_svR:mag / land_accel.
  lock land_tGround to landEtaImpact().

wait until vdot((-land_ground):normalized, ship:facing:forevector) > 0.99.

// Descent loop. It has three phases
//   descent: Free fall toward the ground; use RCS to kill horizontal velocity
//   suicide: Kill most of downward velocity as late as possible
//   final: limit downward velocity during the last second before contact
until status = "Landed" or status = "Splashed" {
  local pointingUp is vdot(ship:facing:forevector, land_ground:normalized) < 0.
  local fallingDown is vdot(land_svR:normalized, land_ground:normalized) > 0.

  landCounterSlip().

  if final {
    if pointingUp and fallingDown and land_svR:mag > land_impact {
      // fire retros for soft touchdown
      lock throttle to (land_svR:mag / (ship:availablethrust / ship:mass)).
    } else {
      unlock throttle.
      set ship:control:pilotmainthrottle to 0.
    }
  }
  else if suicide {
    local touch is 1.5*(land_svR:mag-1) + 0.5*land_grav*1.5^2.

    if land_ground:mag < touch {
      uiBanner("Landing", "Final descent").
      set final to true.
    } else if pointingUp and fallingDown and land_svR:mag > land_impact {
      lock throttle to (land_accel / (ship:availablethrust / ship:mass)).
    } else {
      unlock throttle.
      set ship:control:pilotmainthrottle to 0.
    }
  }
  else {
    // Descent: warp to suicide burn
    if land_tGround < land_tBrake {
      uiBanner("Landing", "Suicide burn (" + round(land_tGround, 0)+ " < " + round(land_tBrake, 0)+ ")").
      legs on.
      gear on.
      wait 0.25.
      legs on.
      gear on.
      set suicide to true.
    } else {
      local delay is floor( abs(land_tGround - land_tBrake) / 10 ) * 10.
      if delay > 1 {
        uiDebug("suicide burn in T" + -round(land_tGround - land_tBrake, 1)).
        run warp(delay).
      }
    }
  }
}

rcs off.
unlock throttle.
set ship:control:pilotmainthrottle to 0.
sas on.
