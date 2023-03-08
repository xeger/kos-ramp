// boot script
SET FLS TO "". // LIST("lib_ui", "lib_parts").

// burn before reading
CORE:VOLUME:DELETE(CORE:BOOTFILENAME).

LOCAL StartupScript IS CORE:ELEMENT:NAME.
IF CORE:PART:TAG <> "" {
	SET StartupScript TO CORE:ELEMENT:NAME+" - "+CORE:PART:TAG.
}

// Install files to local volume.
FUNCTION INSTALL {
	PARAMETER FLS IS "".
	PARAMETER SRC IS PATH("0:/ramp").
	IF FLS = "" {
		SET FLS TO OPEN(SRC):LIST():KEYS.
	}
	SET NotFound TO LIST().
	SET CopyFailed TO LIST().
	SET DiskFull TO FALSE.

	FOR F IN FLS {
		LOCAL LF IS SRC:COMBINE(F).
		IF EXISTS(LF) {
			IF OPEN(LF):SIZE > CORE:VOLUME:FREESPACE {
				SET DiskFull TO TRUE.
				CopyFailed:ADD(F).
			} ELSE {
				IF NOT COPYPATH(LF, CORE:VOLUME) {
					CopyFailed:ADD(F).
				}
			}
		} ELSE {
			NotFound:ADD(F).
		}
	}
	IF NOT NotFound:EMPTY() {
		bootWarning("Files not found: " + NotFound:JOIN(", ")).
	}
	IF NOT CopyFailed:EMPTY() {
		bootWarning("Copy failed: " + CopyFailed:JOIN(", ")).
	}
	IF DiskFull {
		bootError("Insufficient free space!").
	}
}

function bootWarning {
	parameter msg.

	print "T+" + round(time:seconds) + " boot: " + msg.

	hudtext(msg, 10, 4, 24, YELLOW, false).
}

//Print info
CLEARSCREEN.
print "kOS processor version " + core:version.
print "Running on " + StartupScript.
print core:volume:capacity + " total space".
print core:volume:freespace + " bytes free".
Print "Universal RAMP bootloader".
WAIT 1.

IF HOMECONNECTION:ISCONNECTED {
	PRINT "Installing required files.".
	INSTALL(FLS).
	PRINT "Installing startup file.".
	INSTALL(LIST(StartupScript), PATH("0:/start/")).
}
IF EXISTS(StartupScript) {
	PRINT "Replacing boot script with mission script.".
	SET CORE:BOOTFILENAME TO StartupScript.
	PRINT "Rebooting!".
	REBOOT.
} ELSE {
	PRINT "No remote startup script found.".
	IF EXISTS("initialize") {
		PRINT "You can create a sample one by typing:".
		PRINT "RUN INITIALIZE.".
	}
}
PRINT "Proceed.".
