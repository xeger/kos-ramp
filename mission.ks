/////////////////////////////////////////////////////////////////////////////
// Idempotent mission script
/////////////////////////////////////////////////////////////////////////////
// Carry out the vessel's mission. Run at any time to resume the mission.
/////////////////////////////////////////////////////////////////////////////

run once lib_ui.

global mission_goal is body("Mun").

function missionAccomplished {
  return ship:body = mission_goal.
}

if ship:status = "prelaunch" {
  wait 1.
  stage.
}

if ship:status = "prelaunch" or ship:status = "flying" or ship:status = "sub_orbital" {
  local atmo is body:atm:height.
  local gt0  is atmo * 0.2.
  local gt1  is atmo * 0.4.
  local apo  is atmo + (body:radius / 4).

  if missionAccomplished() {
    uiBanner("Mission", "Final descent to " + body:name).
    run land.
  } else {
    uiBanner("Mission", "Ascent from " + body:name).
    run launch_asc(gt0, gt1, 1.0, apo).
  }
}

if ship:status = "escaping" {
  // TODO handle this in a smarter way
  run warp(eta:transition - 5).
}

if ship:status = "orbiting" {
  // TODO handle non-final orbit (finish transfer)
  if missionAccomplished() {
    //run land.
  } else {
    //set target to mission_goal.
    //run transfer.
  }
}
