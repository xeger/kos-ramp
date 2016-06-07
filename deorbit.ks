run once lib_ui.

// Ship average angular velocity in orbit, per second. Measured in radians!.
function landSpin {
  return 2 * constant:pi / ship:obt:period.
}

// Ship linear speed along orbital track, per second. Assumes circular orbit!
function landRun {
  // angular speed * circumference of orbit = linear speed
  return (ship:obt:semimajoraxis - body:radius) * landSpin.
}

// 3-vector of (latitudinal, longitudinal, 0) change in position, per second,
// AKA "land speed" over SOI body. Measured in radians! Assumes circular orbit!
function landSpinGeo {
    local spin is v(landSpin * sin(ship:obt:inclination), landSpin * cos(ship:obt:inclination), 0).
    local bodySpin is v(0, (2 * constant:pi) / body:rotationperiod, 0).
    return v(spin:x - bodySpin:x, spin:y - bodySpin:y, 0).
}

// 3-vector of (eta to target lat, eta to target long, 0). Can look beyond
// next intersection if it's too soon to plan a deorbit burn.
//   geo: GeoCoordinate; landing target
//   grace: number, minimum acceptable eta
function landEta {
  parameter geo.
  parameter grace.

  local me is ship:geoposition.
  local lsg is landSpinGeo.
  local orbT is ship:obt:period / 2.

  local dLat is (geo:lat - me:lat).
  local dLong is (geo:lng - me:lng).

  local eta is v(
    Constant:DegToRad * dLat / lsg:x,
    Constant:DegToRad * dLong / lsg:y,
    0
  ).

  local i is 1.
  until eta:x > grace {
    set eta to v((Constant:DegToRad * dLat + i*constant:pi) / lsg:x, eta:y, 0).
    set i to i + 1.
  }

  set i to 1.
  until eta:y > grace {
    set eta to v(eta:x, (Constant:DegToRad * dLong + 2*i*constant:pi) / lsg:y, 0).
    set i to i + 1.
  }

  return eta.
}

// Plan the deorbit burn. Does not account for target
// latitude; only accurate for equatorial targets!
function landNodeDeorbit {
  parameter geo.

  local etaGeo is landEta(geo, ship:obt:period / 2).

  // find ideal deorbit burn point not accounting for planetary spin
  local geoShip is positionat(ship, time + etaGeo:y).
  local geoLng is body:geopositionof(geoShip).
  local geoPeriHeight is body:radius * 0.025.
  if body:atm:height > 0 {
    set geoPeriHeight to body:atm:height * 0.2.
  }
  local geoHeight is (geoShip - geoLng:altitudeposition(geoPeriHeight)):mag.
  local newSMA is ship:orbit:semimajoraxis - geoHeight.
  local newPeriod is sqrt(2 * constant:pi * (newSMA ^ 3 / body:mu)).

  // amount of ground we will gain/lose while traveling from terminal apoapsis
  // to terminal periapsis (faster orbit, since smaller).
  local spin is landSpinGeo.
  local gainLng is spin:y * (newPeriod / 2).
  local gainT is gainLng / landSpin.

  local etaBurn is etaGeo:y - (ship:obt:period / 2) + gainT.

  run node_peri(0).
  local nd is nextnode.
  set nd:eta to etaBurn.
}

set ksc to latlng(-0.1025, -74.5752777777777).
set origin to latlng(0.0, 0.0).

landNodeDeorbit(origin).
