Introduction
============

Getting Started
===============

Roadmap
=======

1. Steal stuff from http://kos.wikia.com/wiki/Maneuvering_modules
2. Solve terrible oscillations caused by `LOCK STEERING TO`
3. Hohmann transfer

Scratchpad
==========

Tsiolkovsky burn duration
-------------------------

// this doesn't work; it seems to be off by quite a bit?

print "TONY AWESOME".
list engines in engs.
local thrustSum is 0.0.
local denomSum is 0.0.

// c.f. http://wiki.kerbalspaceprogram.com/wiki/Tutorial:Advanced_Rocket_Design#Delta-V
FOR eng IN engs
{
  local thrust is eng:maxthrust * eng:thrustlimit.
  set thrustSum to thrustSum + thrust.
  set denomSum to denomSum + (thrust / (eng:isp * 9.82)).
}.
local Isp is thrustSum / denomSum.
local massBurn is ((ship:mass * 1000) / constant():e ^ (nd:deltav:mag / Isp)).
local tsiol is ((ship:mass* 1000) - massBurn) / (thrustSum / Isp).
print "TONY AWESOME will burn " + round(massBurn, 1) + " kg".
print "TONY AWESOME tsiol dob is " + round(tsiol, 1).
