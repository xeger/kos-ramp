/////////////////////////////////////////////////////////////////////////////
// Automated-mission boot script.
/////////////////////////////////////////////////////////////////////////////
// Copy all scripts to local volume; run mission script. This is suitable for
// single-CPU vessels that will be operating out of comms range.
//
// To customize the mission, edit mission.ks before launch; it will be
// persisted onto the craft you launch, suitable for archive-free operation.
/////////////////////////////////////////////////////////////////////////////

if ship:status = "prelaunch" {
  switch to archive.

  list files in scripts.
  for file in scripts {
    if file:name:endswith(".ks") {
      copypath(file,core:volume).
    }
  }
}

switch to core:volume.
run mission.
wait 15.
reboot.
