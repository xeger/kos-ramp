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

if ship:status = "PRELAUNCH" {
  wait 1.
  uiBanner("Mission", "Launch!").
  set ship:control:pilotmainthrottle to 1.
  stage.
  wait 2. // Wait to ship stabilize
}

if ship:status = "FLYING" or ship:status = "SUB_ORBITAL" {
  if missionAccomplished() {
    uiBanner("Mission", "Descend to " + body:name).
    run land.
  } else if not (ship:status = "ESCAPING" or ship:status = "ORBITING") {
    uiBanner("Mission", "Ascend from " + body:name).
    run launch_asc(body:atm:height + (body:radius / 10)).
  }
}

if ship:status = "ESCAPING" {
  // TODO handle this in a smarter way
  run warp(eta:transition - 5).
}

if ship:status = "ORBITING" {
  // TODO handle non-final orbit (finish transfer if resumed during it)
  if missionAccomplished() {
    run land.
  } else {
    uiBanner("Mission", "Transfer to " + mission_goal:name).
    set target to mission_goal.
    run transfer.
  }
}
