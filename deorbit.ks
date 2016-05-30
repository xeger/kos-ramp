run once lib_ui.

// Ship linear speed along orbital track, per second.
function landRun {
  local R is ship:obt:semimajoraxis - body:radius.
  return 2 * constant:pi * R / ship:obt:period.
}

// Ship angular velocity in orbit, per second.
function landSpin {
  return 2 * constant:pi / ship:obt:period.
}

// 3-vector of (latitudinal, longitudinal, 0) change in position, per second.
// AKA "land speed."
function landSpinGeo {
    local spin is v(landSpin * sin(ship:obt:inclination), landSpin * cos(ship:obt:inclination), 0).
    local bodySpin is v(0, (2 * constant:pi) / body:rotationperiod, 0).
    return v(spin:x - bodySpin:x, spin:y - bodySpin:y, 0).
}

// 3-vector of (eta to target lat, eta to target long, 0)
function landEta {
  parameter geo.

  local me is ship:geoposition.
  local lsg is landSpinGeo.

  return v(
    Constant:DegToRad * (geo:lat - me:lat) / lsg:x,
    Constant:DegToRad * (geo:lng - me:lng) / lsg:y,
    0
  ).
}

set ksc to latlng(-0.1025, -74.5752777777777).

lock steering to lookdirup(retrograde:vector, ship:facing:upvector).

// HACK: very crude deorbit program; fails to account for sidereal motion,
//       wastes time to make calculations easier, & only works for locations
//       on the equator!!!

until landEta(ksc):y > 0 {
  uiBanner("Deorbit", "eta=" + round(landEta(ksc):y, 1)).
  run warp(ship:obt:period / 4).
  wait 1.
}
uiBanner("Deorbit", "Warp to base leg").
run warp(landEta(ksc):y).
wait 1.

uiBanner("Deorbit", "Warp to deorbit burn").
run warp(ship:obt:period / 2).
wait 1.

uiBanner("Deorbit", "Perform retrograde burn now!!").
