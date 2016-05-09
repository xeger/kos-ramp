/////////////////////////////////////////////////////////////////////////////
// Land
/////////////////////////////////////////////////////////////////////////////
// Make groundfall
/////////////////////////////////////////////////////////////////////////////

run once lib_ui.

global land_slip    is 0.05. // transverse speed @ touchdown (m/s)
global land_warp    is 3.    // warp factor during descent
global land_descend is 10.0. // max speed during final descent (m/s)
global land_touch   is 10.   // touchdown height during final descent (m)
sas off.

until status <> "ORBITING" {
  lock steering to lookdirup(retrograde:vector, ship:facing:upvector).
  until status <> "ORBITING" {
    uiBanner("Landing", "Deorbit burn").
  }
}

if status = "SUB_ORBITAL" or status = "FLYING" {
  lock steering to lookdirup(-ship:velocity:surface, v(1,0,0)).

  local grav is body:mu / (body:position:mag ^ 2).
  local accel is uiAssertAccel("Landing").
  local brake is false.
  local final is false.
  local touchdown is false.

  until status <> "SUB_ORBITAL" and status <> "FLYING" {
    local geo is ship:geoposition.
    local ground is geo:position:normalized.
    local sv is ship:velocity:surface.
    local svR is vdot(sv, ground) * ground.
    local svT is sv - svR.
    local dtBrake is abs(sv:mag / accel).
    local dtGround is (sqrt(4 * grav * abs(geo:position:mag) + sv:mag^2) - sv:mag) / (2*grav).

    if final {
      // Final descent: fall straight down; fire retros at touchdown.
      legs on.

      // decide when to touch down
      if dtBrake >= dtGround-1 {
        set touchdown to true.
      }

      // control transverse speed; keep it below allowable slip
      if svT:mag > land_slip {
        local sense is ship:facing.
        local dirV is V(
          vdot(svT, sense:starvector),
          0,
          vdot(svT, sense:vector)
        ).

        set ship:control:translation to -(dirV / land_slip / 2).
      }
      else {
        set ship:control:translation to 0.
      }

      // deploy legs and fire retros for soft touchdown
      if touchdown and vdot(svR, ground) > 0 {
        lock throttle to (sv:mag / accel) * 0.8.
      }
      else {
        lock throttle to 0.
      }
    }
    else if brake  {
      // Braking burn: scrub velocity down to final-descent speed
      if sv:mag > land_descend {
        lock throttle to min((sv:mag - land_descend * 0.5) / accel, 1.0).
      }
      else {
        uiBanner("Landing", "Final descent").
        lock steering to lookdirup(-ship:geoposition:position:normalized, v(1, 0, 0)).
        rcs on.
        lock throttle to 0.
        set final to true.
      }
    }
    else {
      // Deorbit: monitor & predict when to perform braking burn
      local rF is positionat(ship, time:seconds + dtBrake).
      local geoF is body:geopositionof(rF).
      local altF is rf:y - geoF:position:y.

      if altF < -100 {
        uiBanner("Landing", "Braking burn").
        set brake to true.
      }
    }
  }
}

if status = "LANDED" or status = "SPLASHED" {
  lock throttle to 0.
  rcs off.
  sas on.
  uiBanner("Landing", "Landing completed").
} else {
  uiError("Landing", "Cannot land from " + status).
}
