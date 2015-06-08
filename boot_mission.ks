/////////////////////////////////////////////////////////////////////////////
// Perform mission at boot.
/////////////////////////////////////////////////////////////////////////////
// Runs the mission; doesn't bother to prep volumes. Switches to archive if
// ship is sitting on the launch pad.
//
// If you boot a CPU with this, you should make sure its volume gets prepped
// with all the necessary scripts, e.g. by using boot_prep on a secondary
// CPU that you install. Or you can make sure your vessel has some really
// long antennas so the archive is always in reach!
/////////////////////////////////////////////////////////////////////////////

if ship:status = "prelaunch" {
  switch to 0.
  wait 5.
  run mission.
} else {
  run mission.
}
