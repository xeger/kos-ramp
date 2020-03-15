if homeconnection:isconnected {
	local ARC is volume(0).
	switch to ARC.
	local scriptname is "/start/" + ship:name + ".ks".
	local scriptpath is path(scriptname).
	if not exists(scriptpath) {
		copypath("0:/mission/sample.ks", scriptname).
		print "Created " + scriptname.
		print "To run mission immediately:".
		print "  reboot.".
	} else {
		reboot.
	}
} else {
	print "Can't open the archive. Extend antennas or get closer to Kerbin.".
}
