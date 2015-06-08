/////////////////////////////////////////////////////////////////////////////
// Prelaunch mission preparation.
/////////////////////////////////////////////////////////////////////////////
// Copy mission programs onto another CPU before launch. This is designed
// to be installed on a secondary CPU (e.g. attached to a launch stage).
//
// TODO: make this work on ships that have 3+ CPUs (named volume?)
// TODO: make compilation work (it has bugs with running lib_ui?!)
/////////////////////////////////////////////////////////////////////////////

if ship:status = "prelaunch" {
  switch to archive.
  list files in scripts.
  for ks in scripts {
    if ks <> "README.md" {
      copy ks to 2.
    }
  }

  run lib_ui.
  uiStatus("Boot", "Prepare flight control software").
}
