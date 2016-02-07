/////////////////////////////////////////////////////////////////////////////
// Test boot. Do not prepare for archive-free operation; execute a simple
// mission of ascending to a stable orbit.
/////////////////////////////////////////////////////////////////////////////

switch to archive.
run once lib_ui.

if ship:status = "prelaunch" {
  wait until stage:ready.
  stage.
  wait 1.
}

if ship:status <> "orbiting" {
  run launch_asc(body:atm:height + (body:radius / 4)).
}
