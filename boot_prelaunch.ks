/////////////////////////////////////////////////////////////////////////////
// Prelaunch mission preparation.
/////////////////////////////////////////////////////////////////////////////
// Copy mission programs onto all CPU volumes before launch.
//
// TODO: make compilation work (it has bugs with running lib_ui?!)
/////////////////////////////////////////////////////////////////////////////

if ship:status = "prelaunch" {
  list volumes in vols.
  local Nvols is vols:length.

  switch to archive.
  list files in scripts.
  for ks in scripts {
    if ks <> "README.md" {
      local N is 1.
      until N > (Nvols - 1) {
        copy ks to N.
        set N to N + 1.
      }
    }
  }

  run lib_ui.
  uiStatus("Boot", "Ready " + (vols:length-1) + " CPU(s) for launch").
}
