// Plan a deorbit burn in one minute. The landing site may be
// anywhere.

local geoHeight is max(body:atm:height / 2, 5000).
run node_peri(geoHeight).
set nextnode:eta to 60.
