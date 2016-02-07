/////////////////////////////////////////////////////////////////////////////
// Test boot. Ascend to stable orbit around any planet.
/////////////////////////////////////////////////////////////////////////////

switch to archive.
run once lib_ui.

if ship:status = "prelaunch" {
  wait 1.
  stage.
}

if ship:status = "prelaunch" or ship:status = "flying" or ship:status = "sub_orbital" {
  local atmo is body:atm:height.
  local gt0  is atmo * 0.2.
  local gt1  is atmo * 0.4.
  local apo  is atmo + (body:radius / 4).

  uiBanner("Mission", "Ascend from " + body:name).
  run launch_asc(gt0, gt1, 1.0, apo).
}

if ship:status = "orbiting" {
  uiBanner("Mission", "Orbit " + body:name).
}
