	// install files to local volume
// ex: SET LIBS TO LIST("lib_ui", "lib_parts").  RUN INSTALL(LIBS).

PARAMETER FLS IS "".
PARAMETER SRC IS PATH("0:/ramp").

IF HOMECONNECTION:ISCONNECTED {
	IF FLS = "" {
		SET FLS TO OPEN(SRC):LIST():KEYS.
	}

	// PRINT "Connected to network.  Installing files...".
	LOCAL CopyOK IS TRUE.
	FOR F IN FLS {
		// PRINT "Copying file: " + F.
		IF NOT COPYPATH(SRC:COMBINE(F), CORE:VOLUME) {
			SET CopyOK TO FALSE.
		}
	}
	IF CopyOK {
		// PRINT "Files copied successfully.".
	} ELSE {
		PRINT "Error copying files.  Check disk space!".
	}
} ELSE {
	PRINT "Not connected to network!".
}
