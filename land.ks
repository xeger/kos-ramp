/////////////////////////////////////////////////////////////////////////////
// Land
/////////////////////////////////////////////////////////////////////////////
// Make groundfall
/////////////////////////////////////////////////////////////////////////////

run once lib_ui.

global land_slip    is 0.05.                            // transverse speed @ touchdown (m/s)
global land_grav is body:mu / (body:radius ^ 2).        // surface gravity
global land_accel is uiAssertAccel("Landing").          // our rocket's go juice
global land_descend is 1.                               // neg. vertical speed at touchdown
lock land_ground to ship:geoposition:position.
lock land_sv to ship:velocity:surface.
lock land_svR to land_sv:mag * vdot(land_sv:normalized, land_ground:normalized) * land_ground:normalized.
lock land_svT to land_sv - land_svR.

// control transverse speed using RCS; keep it below allowable slip velocity
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

function landEtaFreeFall {
  return (sqrt(4 * land_grav * land_ground:mag + land_svR:mag^2) - land_svR:mag) / (2*land_grav).
}

// Determine time of impact based on free-fall or suicide-burn model,
// depending on how far we are from the ground.
function landEtaImpact {
  local aBrake is land_accel - land_grav.
  local quadrat is land_svR:mag^2 - 2*aBrake*land_ground:mag.
  local ff is landEtaFreeFall().

  if quadrat > 0 {
    // we're close to the ground; predict impact eta if we were to begin
    // suicide burn now (unless we're too close!)
    return min(ff, (land_svR:mag + sqrt(quadrat)) / aBrake).
  } else {
    // quadratic does not converge; we're too far from the ground.
    // use free-fall model instead.
    return ff.
  }
}

sas off.
lock steering to lookdirup(retrograde:vector, ship:facing:upvector).
wait until vdot(retrograde:vector, ship:facing:forevector) > 0.99.

if status = "ORBITING" {
  if ship:periapsis < body:atm:height * 0.8 or ship:periapsis <= body:radius * 0.2 {
    // We're still in orbit, but perigee is low enough to be considered terminal.
    // Coast to perigee and perform a braking burn.
    lock land_tBrake to land_sv:mag / land_accel.
    run warp(eta:periapsis - land_tBrake - 5).
    wait until eta:periapsis <= land_tBrake.
    local vMin is land_sv.
    lock throttle to min(vMin:mag/land_accel, 1.0).
    until land_sv:mag > (vMin:mag + 0.1) {
      if land_sv:mag < vMin:mag {
        set vMin to land_sv.
      }
    }
    unlock land_tBrake.
    unlock throttle.
  } else {
    uiFatal("Landing", "Must deorbit before landing").
  }
}

lock land_tBrake to (land_svR:mag - land_descend) / land_accel.
lock land_tGround to landEtaImpact().

lock steering to lookdirup(-ship:velocity:surface, ship:facing:upvector).

local suicide is false.
local final is false.
local touchdown is false.

rcs on.

// Descent loop. It has four stages.
//   descent: Free fall toward the ground
//   braking: cancel downward velocity
until status = "Landed" or status = "Splashed" {
  local pointingUp is vdot(ship:facing:forevector, land_ground:normalized) < 0.
  local fallingDown is vdot(land_svR:normalized, land_ground:normalized) > 0.

  if final {
    landCounterSlip().

    if pointingUp and fallingDown and land_svR:mag > land_descend {
      // fire retros for soft touchdown
      lock throttle to (land_svR:mag / (ship:availablethrust / ship:mass)).
    } else {
      lock throttle to 0.
    }
  }
  else if suicide {
    landCounterSlip().
    local touch is 1.5*(land_svR:mag-1) + 0.5*land_grav*1.5^2.

    if land_ground:mag < touch {
      uiBanner("Landing", "Final descent").
      lock steering to lookdirup((-land_ground):normalized, ship:facing:upvector).
      set final to true.
    } else if pointingUp and fallingDown and land_tGround < land_tBrake {
      lock throttle to (land_accel / (ship:availablethrust / ship:mass)).
    } else {
      lock throttle to (land_descend / (ship:availablethrust / ship:mass)).
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

lock throttle to 0.
rcs off.
sas on.
