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

//Print system info
CLEARSCREEN.
bootConsole("RAMP @ " + core:element:name).
bootConsole("kOS " + core:version).
bootConsole(round(core:volume:freespace/1024, 1) + "/" + round(core:volume:capacity/1024) + " kB free").
//Waits 5 seconds for ship loads and stabilize physics, etc...
WAIT 5.

//Set up volumes
SET HD TO CORE:VOLUME.
SET StartupLocalFile TO "startup.ks".
SET Failsafe TO false.

bootConsole("Attemping to connect to KSC...").
IF HOMECONNECTION:ISCONNECTED {
	bootConsole("Connected to KSC, copying updated files...").
	SET ARC TO VOLUME(0).
	SWITCH TO ARC.

  IF EXISTS("kos-ramp") {
	  CD ("kos-ramp").
  } ELSE IF EXISTS("ramp") {
    CD ("ramp").
  }

  RUNONCEPATH("lib_install.ks").
  LOCAL success IS false.

  IF installIsPossible() {
    if installFiles() {
      bootConsole("RAMP initialized").
    }
    ELSE {
      bootWarning("RAMP failsafe (copy failed)").
      failsafe on.
    }
  }
  ELSE {
    bootWarning("RAMP failsafe (too big)").
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

IF HOMECONNECTION:ISCONNECTED {
  bootConsole("Looking for remote startup script...").
	LOCAL shipScript is PATH("0:/start/"+SHIP:NAME).
  LOCAL coreScript is PATH(shipScript + "-" + CORE:TAG).
  local toCopy is "".
  IF EXISTS(coreScript) {
    set toCopy to coreScript.
	} ELSE IF EXISTS(shipScript) {
    set toCopy to shipScript.
  } else {
    PRINT "No remote startup script found.".
    PRINT "You can create a sample one by typing:".
    PRINT "  RUN UTIL_MAKESTARTUP.".
  }

  IF toCopy <> "" {
    bootConsole("Copying remote startup script from archive.").
    SWITCH TO HD.
    IF COPYPATH(toCopy, StartupLocalFile) {
      StartupOk ON.
    }
    ELSE {
      bootConsole("Could not copy the file. Is there enough space?").
    }
  }
}
ELSE {
	IF EXISTS(StartupLocalFile) {
		bootConsole("Using local startup script copied from archive.").
		StartupOk ON.
	}
	ELSE
	{
		bootError("Cannot find RAMP scripts or connect to KSC; please restart mission!").
	}
}

IF NOT Failsafe {
  SWITCH TO HD.
}

IF StartupOk {
	RUNPATH(StartupLocalFile).
}
ELSE {
  bootWarning("RAMP: need input").
  bootWarning("see kOS console").
  PRINT "RAMP ready for commands:". PRINT "".
}
