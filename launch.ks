// Immediate launch.
stage.

local atmo is ship:obt:body:atm:height.
local gt0  is atmo * 0.1.
local gt1  is atmo * 0.9.
local apo  is atmo + 20000. // clear the atmosphere by 20km

print "Launch: ascending to " + round(apo / 1000) + " km orbit; gravity turn " + round(gt0 / 1000) + "-" + round(gt1 / 1000) + " km".
run launchascend(gt0, gt1, apo).
