// boot script

SET FLS TO "". // LIST("lib_ui", "lib_parts").

LOCAL StartupScript IS CORE:ELEMENT:NAME.
IF CORE:PART:TAG <> "" {
	SET StartupScript TO CORE:ELEMENT:NAME+" - "+CORE:PART:TAG.
}

//Print info
CLEARSCREEN.
print "kOS processor version " + core:version.
print "Running on " + StartupScript.
print core:volume:capacity + " total space".
print core:volume:freespace + " bytes free".
Print "Universal RAMP bootloader".
//Waits 5 seconds for ship loads and stabilize physics, etc...
WAIT 5.

IF HOMECONNECTION:ISCONNECTED {
	PRINT "Installing required files.".
	RUNPATH("0:/ramp/install", FLS).
	PRINT "Installing startup file.".
	RUNPATH("0:/ramp/install", LIST(StartupScript), PATH("0:/start/")).
}
IF EXISTS(StartupScript) {
	RUNPATH(StartupScript).
} ELSE {
	PRINT "No remote startup script found.".
	IF EXISTS("initialize") {
		PRINT "You can create a sample one by typing:".
		PRINT "  RUN initialize.".
	}
}
PRINT "Proceed.".
