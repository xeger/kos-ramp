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

  local etaDeorbit is v(
    Constant:DegToRad * dLat / lsg:x,
    Constant:DegToRad * dLong / lsg:y,
    0
  ).

  local i is 1.
  until etaDeorbit:x > grace or i > 1024{
    set etaDeorbit to v((Constant:DegToRad * dLat + i*constant:pi) / lsg:x, etaDeorbit:y, 0).
    set i to i + 1.
    if mod(i,256) = 0 and i > 0 {
       uiDebug("lat lsg=" + round(etaDeorbit:x, 1) + "eta=" + round(etaDeorbit:x, 1)).
    }
  }

  set i to 1.
  until etaDeorbit:y > grace or i > 1024 {
    set etaDeorbit to v(etaDeorbit:x, (Constant:DegToRad * dLong + 2*i*constant:pi) / lsg:y, 0).
    set i to i + 1.
    if mod(i,256) = 0 and i > 0 {
      uiDebug("lng lsg="+ round(etaDeorbit:y, 1) + "eta=" + round(etaDeorbit:y, 1)).
      //uiDebug("theta=" + (2 * constant:pi / ship:obt:period) + " sin(inc)=" + sin(ship:obt:inclination)).
    }
  }

  return etaDeorbit.
}

// Plan the deorbit burn. Only accurate for equatorial targets!
// Does not handle inclinations > 90!
function landNodeDeorbit {
  parameter geo.

  local geoHeight is geo:terrainheight + 3000.
  local etaGeo is landEta(geo, ship:obt:period / 2).

  // find ideal deorbit burn point not accounting for planetary spin
  local geoShip is positionat(ship, time + etaGeo:y).
  local geoLng is body:geopositionof(geoShip).

  // figure out enough elements of post-burn terminal orbit to let us compute
  // the time we'll spend on descent.
  // TODO account for atmospheric drag
  local newSMA is body:radius + geoHeight.
  local newPeriod is sqrt(2 * constant:pi * (newSMA ^ 3 / body:mu)).

  // amount of ground we will gain/lose while traveling from terminal apoapsis
  // to terminal periapsis (faster orbit, since smaller).
  local spin is landSpinGeo.
  local gainLng is spin:y * (newPeriod / 2).
  local gainT is gainLng / landSpin.

  local etaBurn is etaGeo:y - (ship:obt:period / 2) + gainT.

  run node_peri(geoHeight).
  local nd is nextnode.
  set nd:eta to etaBurn.
}

set ksc to latlng(-0.1025, -74.5752777777777).
set origin to latlng(0.0, 0.0).

if hastarget {
  uiBanner("Deorbit", "Land near " + target:name).
  landNodeDeorbit(target:geoposition).
} else {
  landNodeDeorbit(origin).
}
