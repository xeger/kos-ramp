IF HOMECONNECTION:ISCONNECTED {
    LOCAL ARC IS VOLUME(0).
    SWITCH TO ARC.
    LOCAL SCRIPTNAME IS "/start/"+SHIP:NAME + ".ks".
    LOCAL SCRIPTPATH IS PATH(SCRIPTNAME).
    IF NOT EXISTS(SCRIPTPATH) {
        COPYPATH("0:/mission/sample.ks", SCRIPTNAME).
        PRINT "Created " + SCRIPTNAME.
        PRINT "To run mission immediately:".
        PRINT "  REBOOT.".
    }
    ELSE {
        REBOOT.
    }
}
ELSE {
    PRINT "Can't open the archive. Extend antennas or get closer to Kerbin.".
}
