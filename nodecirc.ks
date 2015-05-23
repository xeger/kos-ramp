parameter circAt.

local errMax is 3.
local obt is ship:obt.

local apsisR is 0.
local apsisT is 0.

if circAt = "periapsis" {
  set apsisR to obt:periapsis.
  set apsisT to TIME + eta:periapsis.
} else { // default to apoapsis
  set apsisR to obt:apoapsis.
  set apsisT to TIME + eta:apoapsis.
}

local nd is node(apsisT:seconds, 0, 0, 0).
add nd.

local sma is (apsisR + obt:body:radius).

local err0 is (sma - nd:orbit:semimajoraxis).
lock err to (sma - nd:orbit:semimajoraxis).
until err < errMax {
  set nd:prograde to nd:prograde + 100 * abs(err / err0).
}

local a is ship:maxthrust/ship:mass.
local dT is nd:prograde/a.

print "Node: circularization burn in " + round(nd:eta) + " s".
