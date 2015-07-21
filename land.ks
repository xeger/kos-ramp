/////////////////////////////////////////////////////////////////////////////
// Land
/////////////////////////////////////////////////////////////////////////////
// Make groundfall
/////////////////////////////////////////////////////////////////////////////

run lib_ui.

local done is false.

local accel is uiAssertAccel("Landing").
sas off.

if status = "ORBITING" {
  lock steering to lookdirup(retrograde, ship:facing:upvector).
  until status <> "ORBITING" {
    uiBanner("Landing", "Deorbit burn").
  }
}

if status = "SUB_ORBITAL" or status = "FLYING" {
  until status <> "SUB_ORBITAL" and status <> "FLYING" {
    local geo is ship:geoposition.
    local v is ship:velocity:surface.
    local vy is vdot(v, -geo:position:normalized).

    if geo:position:mag < 100 {
      uiBanner("Landing", "Final descent").
      set legs to true.
      lock steering to lookdirup(-geo:position, ship:facing:upvector).
    } else {
      uiBanner("Landing", "Descent to " + body:name).

      if vy > 0 {
        lock steering to lookdirup(v, ship:facing:upvector).
      } else {
        lock steering to lookdirup(-v, ship:facing:upvector).
      }
    }
  }
}

if status = "LANDED" or status = "SPLASHED" {
  lock throttle to 0.
  sas on.
  uiBanner("Landing", "Landing completed").
} else {
  uiError("Landing", "Landing aborted; invalid status " + status).
}
