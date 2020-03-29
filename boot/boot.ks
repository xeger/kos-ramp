/////////////////////////////////////////////////////////////////////////////
// Universal boot script for RAMP system.
/////////////////////////////////////////////////////////////////////////////
// Copy all scripts to local volume; run mission script. This is suitable for
// single-CPU vessels that will be operating out of comms range.
//
// To customize the mission, edit <ship name>.ks in 0:/start folder before
// launch; it will be persisted onto the craft you launch, suitable for
// archive-free operation.
//
// Nevertheless, every time this boots, it will try to copy the files again,
// if possible.
// It expects the RAMP scripts files to be saved in 0:/ramp folder.
/////////////////////////////////////////////////////////////////////////////

// Print informational message.
function bootConsole {
	parameter msg.

	print "T+" + round(time:seconds) + " boot: " + msg.
}

// Print error message and shutdown CPU.
function bootError {
	parameter msg.

	print "T+" + round(time:seconds) + " boot: " + msg.

	hudtext(msg, 10, 4, 36, RED, false).

	local vAlarm to GetVoice(0).
	set vAlarm:wave to "TRIANGLE".
	set vAlarm:volume to 0.5.
	vAlarm:play(
		list(
			note("A#4", 0.2, 0.25),
			note("A4",  0.2, 0.25),
			note("A#4", 0.2, 0.25),
			note("A4",  0.2, 0.25),
			note("R",   0.2, 0.25),
			note("A#4", 0.2, 0.25),
			note("A4",  0.2, 0.25),
			note("A#4", 0.2, 0.25),
			note("A4",  0.2, 0.25)
		)
	).
	shutdown.
}

function bootWarning {
	parameter msg.

	print "T+" + round(time:seconds) + " boot: " + msg.

	hudtext(msg, 10, 4, 24, YELLOW, false).
}

// Print system info; wait for all parts to load
clearscreen.
bootConsole("RAMP @ " + core:element:name).
bootConsole("kOS " + core:version).
bootConsole(round(core:volume:freespace / 1024, 1) + "/" + round(core:volume:capacity / 1024) + " kB free").
wait 1.

// Set up volumes
set hd to core:volume.
set ARC to 0.
set StartupLocalFile to path(core:volume) + "/startup.ks".
set Failsafe to false.

bootConsole("Attemping to connect to KSC...").
if homeconnection:isconnected {
	bootConsole("Connected to KSC, copying updated files...").
	set ARC to volume(0).
	switch to ARC.

	if exists("ramp") {
		cd ("ramp").
	} else if exists("kos-ramp") {
		cd ("kos-ramp").
	}

	local copyok is true.
	list files in fls.
	local fSize is 0.
	for f in fls {
		if f:name:endswith(".ks") {
			// remove file if it alredy exists, needed to avoid requirement of double space on reboot
			if hd:exists(f:name) hd:delete(f:name).
			set fSize to fSize + f:size.
		}
	}
	if core:volume:freespace > fSize {
		for f in fls {
			if f:name:endswith(".ks") {
				if not copypath(f, hd) { copyok off. }.
			}
		}
		if copyok {
			bootConsole("RAMP initialized.").
		} else {
			bootWarning("File copy failed.").
			failsafe on.
		}
	} else {
		bootWarning("Core volume too small.").
		failsafe on.
	}
} else {
	bootConsole("No connection to KSC detected.").
	if exists(StartupLocalFile) {
		bootConsole("Local RAMP startup, proceeding.").
	} else {
		bootConsole("RAMP not detected; extend antennas and reboot...").
		if Career():candoactions {
			for P in ship:parts {
				if P:modules:contains("ModuleDeployableAntenna") {
					local M is P:getmodule("ModuleDeployableAntenna").
					for A in M:allactionnames() {
						if A:contains("Extend") { M:doaction(A, true). }
					}.
				}
			}.
			reboot.
		} else {
			bootError("Cannot contact KSC. Add antennas?").
		}
	}
}

local StartupOk is false.

bootConsole("Looking for remote startup script...").
if homeconnection:isconnected {
	local StartupScript is path("0:/start/" + ship:name).
	if exists(StartupScript) {
		bootConsole("Copying remote startup script from archive.").
		switch to hd.
		if copypath(StartupScript, StartupLocalFile) {
			StartupOk on.
		} else {
			bootConsole("Startup file copy failed. Is there enough space?").
		}
	} else {
		print "--------------------------------------".
		print "No remote startup script found.".
		print "You can create a sample one by typing:".
		print "  run initialize.".
		print "--------------------------------------".
	}
} else {
	switch to hd.
	if exists(StartupLocalFile) {
		bootConsole("Using local startup script copied from archive.").
		StartupOk on.
	} else {
		bootError("Cannot find RAMP scripts or connect to KSC; please restart mission!").
	}
}

if Failsafe {
	bootWarning("Failsafe mode: run from archive.").
	switch to archive.
} else {
	switch to hd.
}

if StartupOk {
	runpath(StartupLocalFile).
} else {
	bootWarning("Need user input; see kOS console.").
	print "RAMP ready for commands:". print "".
}
