/////////////////////////////////////////////////////////////////////////////
// Idempotent mission script
/////////////////////////////////////////////////////////////////////////////
// Carry out the vessel's mission. Run at any time to resume the mission.
/////////////////////////////////////////////////////////////////////////////

run lib_ui.

global mission_goal is body("Mun").

function missionAccomplished {
  return false. // TODO actually discern this
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
    //run land_any.
  } else {
    uiStatus("Mission", "Ascent from " + body:name).
    run launch_asc(gt0, gt1, apo).
  }
}

if ship:status = "escaping" {
  // TODO get a bit about this smarter (when to circ instead?)
  run warp(eta:transition - 5).
}

if ship:status = "orbiting" {
  uiWarning("Mission", "Mission unplanned; you take it from here!").

  // Let's go to the Mun .. or back!
  //if missionAccomplished() {
  //  set target to body("Kerbin").
  //} else {
  //  set target to mission_goal.
  //}
  //run transfer.

  // Let's rendezvous with another spacecraft!
  //set target to mission_goal.
  //run rendezvous.
}
