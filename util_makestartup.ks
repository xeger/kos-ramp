LOCAL CODE IS LIST().
CODE:ADD("IF SHIP:STATUS = " + char(34) + "PRELAUNCH" + char(34) + " {").
CODE:ADD("    RUN launch_asc(120000). // Launches to 120km").
CODE:ADD("    SET TARGET TO MUN. //We choose go to to the Mun and do the other things!" ).
CODE:ADD("    // TODO: Do the other things, not because they are easy, but because they are hard!").
CODE:ADD("    //RUN transfer.").
CODE:ADD("}").


IF HOMECONNECTION:ISCONNECTED {
    LOCAL ARC IS VOLUME(0).
    SWITCH TO ARC.
    LOCAL SCRIPTNAME IS "/start/"+SHIP:NAME + ".ks".
    LOCAL SCRIPTPATH IS PATH(SCRIPTNAME).
    IF NOT EXISTS(SCRIPTPATH) {
        SET SCRIPTFILE TO ARC:CREATE(SCRIPTNAME).
        FOR LINE IN CODE {
            SCRIPTFILE:WRITELN(LINE).
        }
    }
    ELSE {
        PRINT "Script file already exists, nothing done.".
    }
}
ELSE {
    PRINT "Can't open the archive.".
}
