/////////////////////////////////////////////////////////////////////////////
// Combined prep-and-mission boot script.
/////////////////////////////////////////////////////////////////////////////
// Prepare local volume for archive-less operation if necessary; run mission
// script. This is suitable for single-CPU vessels that will be operating
// out of comms range from KSC.
/////////////////////////////////////////////////////////////////////////////

if ship:status = "prelaunch" {
  switch to archive.

  list files in scripts.
  for file in scripts {
    if file:name:endswith(".ks") {
      copy file to core:volume.
    }
  }
}

switch to core:volume.
run mission_mun.
