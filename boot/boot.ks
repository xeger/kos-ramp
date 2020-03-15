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

	local vAlarm TO GetVoice(0).
	set vAlarm:wave to "TRIANGLE".
	set vAlarm:volume to 0.5.
	vAlarm:PLAY(
		LIST(
			NOTE("A#4", 0.2,  0.25),
			NOTE("A4",  0.2,  0.25),
			NOTE("A#4", 0.2,  0.25),
			NOTE("A4",  0.2,  0.25),
			NOTE("R",   0.2,  0.25),
			NOTE("A#4", 0.2,  0.25),
			NOTE("A4",  0.2,  0.25),
			NOTE("A#4", 0.2,  0.25),
			NOTE("A4",  0.2,  0.25)
		)
	).
	shutdown.
}

function bootWarning {
	parameter msg.

	print "T+" + round(time:seconds) + " boot: " + msg.

	hudtext(msg, 10, 4, 24, YELLOW, false).
}

//Print system info; wait for all parts to load
CLEARSCREEN.
bootConsole("RAMP @ " + core:element:name).
bootConsole("kOS " + core:version).
bootConsole(round(core:volume:freespace/1024, 1) + "/" + round(core:volume:capacity/1024) + " kB free").
WAIT 1.

//Set up volumes
SET HD TO CORE:VOLUME.
SET ARC TO 0.
SET StartupLocalFile TO path(core:volume) + "/startup.ks".
SET Failsafe TO false.

bootConsole("Attemping to connect to KSC...").
IF HOMECONNECTION:ISCONNECTED {
	bootConsole("Connected to KSC, copying updated files...").
	SET ARC TO VOLUME(0).
	SWITCH TO ARC.

	IF EXISTS("ramp") {
		CD ("ramp").
	} ELSE IF EXISTS("kos-ramp") {
		CD ("kos-ramp").
	}

	LOCAL copyok is TRUE.
	LIST FILES IN fls.
	LOCAL fSize is 0.
	FOR f IN fls {
		IF f:NAME:ENDSWITH(".ks") {
			SET fSize to fSize + f:SIZE.
		}
	}
	if core:volume:freespace > fSize {
		FOR f IN fls {
			IF f:NAME:ENDSWITH(".ks") {
				IF NOT COPYPATH(f,HD) { COPYOK OFF. }.
			}
		}
		IF copyok {
			bootConsole("RAMP initialized.").
		}
		ELSE {
			bootWarning("File copy failed.").
			failsafe on.
		}
	} else {
		bootWarning("Core volume too small.").
		failsafe on.
	}
}
ELSE {
	bootConsole("No connection to KSC detected.").
	IF EXISTS(StartupLocalFile) {
		bootConsole("Local RAMP startup, proceeding.").
	}
	ELSE {
		bootConsole("RAMP not detected; extend antennas and reboot...").
		IF Career():CANDOACTIONS {
			FOR P IN SHIP:PARTS {
				IF P:MODULES:CONTAINS("ModuleDeployableAntenna") {
					LOCAL M IS P:GETMODULE("ModuleDeployableAntenna").
					FOR A IN M:ALLACTIONNAMES() {
						IF A:CONTAINS("Extend") { M:DOACTION(A,True). }
					}.
				}
			}.
			REBOOT.
		}
		ELSE {
			bootError("Cannot contact KSC. Add antennas?").
		}
	}
}

LOCAL StartupOk is FALSE.

bootConsole("Looking for remote startup script...").
IF HOMECONNECTION:ISCONNECTED {
	LOCAL StartupScript is PATH("0:/start/"+SHIP:NAME).
	IF EXISTS(StartupScript) {
		bootConsole("Copying remote startup script from archive.").
		SWITCH TO HD.
		IF COPYPATH(StartupScript, StartupLocalFile) {
			StartupOk ON.
		}
		ELSE {
			bootConsole("Startup file copy failed. Is there enough space?").
		}
	}
	ELSE {
		PRINT "--------------------------------------".
		PRINT "No remote startup script found.".
		PRINT "You can create a sample one by typing:".
		PRINT "  RUN initialize.".
		PRINT "--------------------------------------".
	}
}
ELSE {
	SWITCH TO HD.
	IF EXISTS(StartupLocalFile) {
		bootConsole("Using local startup script copied from archive.").
		StartupOk ON.
	}
	ELSE
	{
		bootError("Cannot find RAMP scripts or connect to KSC; please restart mission!").
	}
}

IF Failsafe {
	bootWarning("Failsafe mode: run from archive.").
	SWITCH TO ARCHIVE.
}
ELSE {
	SWITCH TO HD.
}

IF StartupOk {
	RUNPATH(StartupLocalFile).
}
ELSE {
	bootWarning("Need user input; see kOS console.").
	PRINT "RAMP ready for commands:". PRINT "".
}
