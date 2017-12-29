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

//Print info
CLEARSCREEN.
bootConsole "kOS processor version " + core:version.
bootConsole "Running on " + core:element:name.
bootConsole core:volume:capacity + " total space".
bootConsole core:volume:freespace + " bytes free".
bootConsole "Universal RAMP bootloader".
//Waits 5 seconds for ship loads and stabilize physics, etc...
WAIT 5.

//Set up volumes
SET HD TO CORE:VOLUME.
SET ARC TO 0.
SET Startup to "startup".

bootConsole "Attemping to connect to KSC...".
IF HOMECONNECTION:ISCONNECTED {
	bootConsole "Connected to KSC, copying updated files...".
	SET ARC TO VOLUME(0).
	SWITCH TO ARC.
	CD ("ramp").
	LOCAL copyok is TRUE.
	LIST FILES IN FLS.
	FOR F IN FLS {
		IF NOT COPYPATH(F,HD) { COPYOK OFF. }.
	}
	IF copyok {
		bootConsole "Files copied successfully.".
	}
	ELSE {
		bootError "Error copying RAMP files. There is enough space?".
	}
}
ELSE {
	bootConsole "No connection to KSC detected.".
	IF EXISTS(Startup) {
		bootConsole "Existing RAMP files found, proceeding.".
	}
	ELSE {
		bootConsole "No existing RAMP files detected. Trying to raise antennas and rebooting...".
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
			bootError "Cannot contact KSC. Does your ship have enough fixed antennas?".
		}
	}
}

SWITCH TO HD.
LOCAL StartupOk is FALSE.

bootConsole "Looking for remote startup script...".
IF HOMECONNECTION:ISCONNECTED {
	LOCAL StartupScript is PATH("0:/start/"+SHIP:NAME).
	IF EXISTS(StartupScript) {
		bootConsole "Remote startup script found!".
		IF COPYPATH(StartupScript,Startup) {
			StartupOk ON.
		}
		ELSE {
			bootConsole "Could not copy the file. There is enough space?".
		}
	}
	ELSE {
		bootConsole "No remote startup script found.".
		bootConsole "You can create a sample one by typing:".
		bootConsole "RUN UTIL_MAKESTARTUP.".
	}
}
ELSE {
	IF EXISTS(Startup) {
		bootConsole "Can't connect to KSC, using local copy of startup script".
		StartupOk ON.
	}
	ELSE
	{
		bootError "Cannot find RAMP scripts or connect to KSC; please restart mission!"
	}
}
IF StartupOk {
	RUNPATH(Startup).
}
bootConsole "Proceed.".
