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

global mission_goal is vessel("KSS").

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
  uiBanner("Mission", "Ascend from " + body:name).
  run launch_asc(body:atm:height + (body:radius / 4)).
}

if ship:status = "ORBITING" { 
    uiBanner("Mission", "Transfer to " + mission_goal:name).
    set target to mission_goal.
    run rendezvous.
  }
