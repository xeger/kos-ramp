/////////////////////////////////////////////////////////////////////////////
// Idempotent mission script
/////////////////////////////////////////////////////////////////////////////
// Carry out the vessel's mission. Run at any time to resume the mission.
/////////////////////////////////////////////////////////////////////////////

run lib_ui.

global mission_goal is body("Mun").

function missionAccomplished {
  return ship:body = mission_goal.
}

if ship:status = "prelaunch" {
  uiBanner("Mission", "Ascent from " + body:name).
  stage.
  wait 1.
}

if ship:status = "flying" or ship:status = "sub_orbital" {
  local atmo is body:atm:height.
  local gt0  is atmo * 0.15.
  local gt1  is atmo * 1.0.
  local apo  is atmo + (body:radius / 4).

  if missionAccomplished() {
    run land.
  } else {
    run launch_asc(gt0, gt1, 1.2, apo).
  }
}

if ship:status = "escaping" {
  // TODO handle this in a smarter way
  run warp(eta:transition - 5).
}

if ship:status = "orbiting" {
  // TODO handle non-final orbit (finish transfer)
  if missionAccomplished() {
    run land.
  } else {
    set target to mission_goal.
    run transfer.
  }
}
