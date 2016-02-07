/////////////////////////////////////////////////////////////////////////////
// Idempotent mission script: Voyage to Mun.
/////////////////////////////////////////////////////////////////////////////
// Launches from Kerbin, transfers to Munar orbit, and lands on Mun.
//
// Can be safely resumed at ALMOST any point during the mission and it will
// make progress (hence "idempotent.") A few conditions that it doesn't yet
// handle:
//   - when landed on any body, does nothing.
//   - when current orbit is non-final (i.e. if resumed when nodes are already
//     planned, or during a transfer orbit), makes bad decisions and plans
//     unneccessary nodes.
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
    uiBanner("Mission", "Descend to " + body:name).
    run land.
  } else {
    uiBanner("Mission", "Ascend from " + body:name).
    run launch_asc(gt0, gt1, 1.0, apo).
  }
}

if ship:status = "escaping" {
  // TODO handle this in a smarter way
  run warp(eta:transition - 5).
}

if ship:status = "orbiting" {
  // TODO handle non-final orbit (finish transfer if resumed during it)
  if missionAccomplished() {
    run land.
  } else {
    uiBanner("Mission", "Transfer to " + mission_goal:name)
    set target to mission_goal.
    run transfer.
  }
}
