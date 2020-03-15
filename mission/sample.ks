// Sample mission script: Mun mission with commented-out transfer command.
// Designed for readability, not robustness! See other mission files for
// more thorough and fault-tolerant examples.

run once lib_ui.

if ship:status = "PRELAUNCH" {
	set ship:control:pilotmainthrottle to 1.
	stage.
	wait 2.
}

if ship:status = "FLYING" or ship:status = "SUB_ORBITAL" {
	run launch_asc(body:atm:height + (body:radius / 10)).
}

// We choose go to to the Mun and do the other things!
set target to mun.

// TODO: Do the other things, not because they are easy, but because they are hard!
//run transfer.

// TODO: nuke these after uncommenting transfer command.
uiBanner("Mission", "Need input; see kOS console").
print "To visit Mun, edit the craft's start file, save changes, and reboot this processor.".
