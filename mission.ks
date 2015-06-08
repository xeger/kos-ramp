/////////////////////////////////////////////////////////////////////////////
// Idempotent mission script
/////////////////////////////////////////////////////////////////////////////
// Carry out the vessel's mission. Run at any time to resume the mission.
/////////////////////////////////////////////////////////////////////////////

global missionGoal is body("Mun").

function missionAccomplished {
  return false. // TODO get smarter (look at vessel name, etc)
}

if ship:status = "prelaunch" {
  stage.
  wait 1.
}

if ship:status = "flying" or ship:status = "sub_orbital" {
  local atmo is body:atm:height.
  local gt0  is atmo * 0.1.
  local gt1  is atmo * 1.0.
  local apo  is atmo + (body:radius / 3).

  if missionAccomplished() {
    run launch_asc(gt0, gt1, apo).
  } else {
    run land_any.
  }
}

if ship:status = "escaping" {
  // TODO warp to transition
}

if ship:status = "orbiting" {
  // TODO if hyperbolic, plan to circ at periapsis
  // TODO if stable, ensure circular
  // TODO if !accomplished, ensure planes aligned with target
}
