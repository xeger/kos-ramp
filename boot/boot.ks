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

//Print info
CLEARSCREEN.
print "kOS processor version " + core:version.
print "Running on " + core:element:name.
print core:volume:capacity + " total space".
print core:volume:freespace + " bytes free".
Print "Universal RAMP bootloader".
//Waits 5 seconds for ship loads and stabilize physics, etc...
WAIT 5.

//Set up volumes
SET HD TO CORE:VOLUME.
SET ARC TO 0.
SET Startup to "startup".

PRINT "Attemping to connect to KSC...".
IF HOMECONNECTION:ISCONNECTED {
	PRINT "Connected to KSC, copying updated files...".
	SET ARC TO VOLUME(0).
	SWITCH TO ARC.
	CD ("ramp").	
	LOCAL copyok is TRUE.
	LIST FILES IN FLS.
	FOR F IN FLS {
		IF NOT COPYPATH(F,HD) { COPYOK OFF. }.
	}
	IF copyok {
		PRINT "Files copied successfully.".
	}
	ELSE {
		PRINT "Error copying files. There is enough space?".
	}
}
ELSE {
	PRINT "No connection to KSC detected.".
	IF EXISTS(Startup) {
		PRINT "Existing RAMP files found, proceeding.".
	}
	ELSE {
		PRINT "No existing RAMP files detected. Trying to raise antennas and rebooting...".
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
}

SWITCH TO HD.
LOCAL StartupOk is FALSE.

print "Looking for remote startup script...".
IF HOMECONNECTION:ISCONNECTED {
	LOCAL StartupScript is PATH("0:/start/"+SHIP:NAME).
	IF EXISTS(StartupScript) {
		PRINT "Remote startup script found!".
		IF COPYPATH(StartupScript,Startup) {
			StartupOk ON.
		}
		ELSE {
			PRINT "Could not copy the file. There is enough space?".
		}
	}
	ELSE {
		PRINT "No remote startup script found.".
		PRINT "You can create a sample one by typing:". 
		PRINT "RUN UTIL_MAKESTARTUP.".
	}
}
ELSE { 
	IF EXISTS(Startup) {
		PRINT "Can't connect to KSC, using local copy of startup script".
		StartupOk ON.
	}
	ELSE 
	{
		PRINT "I'm sorry, Dave. I'm afraid I can't do that.". //This should never happens!
	}
}
IF StartupOk {
	RUNPATH(Startup).
}
PRINT "Proceed.".