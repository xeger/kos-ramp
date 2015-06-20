/////////////////////////////////////////////////////////////////////////////
// Idempotent mission script
/////////////////////////////////////////////////////////////////////////////
// Carry out the vessel's mission. Run at any time to resume the mission.
/////////////////////////////////////////////////////////////////////////////

run lib_ui.

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
  uiBanner("Mission unplanned; you take it from here!").
  //if missionAccomplished() {
  //  set target to body("Kerbin").
  //} else {
  //  set target to body("Mun").
  //}

  run transfer.
}
