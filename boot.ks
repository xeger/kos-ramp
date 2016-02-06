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

// TODO: handle unavailable archive, copying to volumes at start, etc
switch to 0.

if ship:status = "prelaunch" {
  run mission.
} else {
  run mission.
}
