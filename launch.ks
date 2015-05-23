stage.

local gt0 is 6500.
local gt1 is 60000.
local apo is 100000.

print "Launch: ascending to " + round(apo / 1000) + " km orbit; gravity turn " + round(gt0 / 1000) + "-" + round(gt1 / 1000) + " km".
run ascend(gt0, gt1, apo).
