About OffsetSteering Function
=============================

Some crafts, specially shuttles and space planes, may have engines thrust vector offset from the craft longitudinal axis. This will lead to some inaccuracies when burning a maneuver node pointing the craft nose to it.

The function OffsetSteering tries to compensate for that, pointing the craft in a way the true acceleration vector matches the desired direction, not the ship nose. 

How it works
------------

The function uses data from Double-C Seismic Accelerometer and GRAVMAX Negative Gravioli Detector to compute the real acceleration of the craft and make the corrections as needed. 

The function will not compute any corrections for crafts without the required sensors installed. 

This function will save a file called *oss.json* in the same directory it ran. That file contains all persistent data the function computes. It's safe to delete the file, the only effect is a reduced precision in next time the function is used, for few seconds, until it computes new data.

How to use this function in your own scripts
--------------------------------------------

Make sure to include the command *run once lib_util.ks* (or any file that contain the function) before trying to use ti.
Then change any *LOCK STEERING* statement to use the function, exemple:

	LOCK STEERING TO OffsetSteering(PROGRADE).
	
