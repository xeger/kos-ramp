Introduction
============

Getting Started
===============

Run the launch program to ascend to a circular orbit a few hundred km above
your local atmosphere:

    run mission.

After you reach a stable orbit, select a target. Use the transfer or rendezvous
programs to reach your target.

    set target to vessel("My Awesome Missions").
    run rendezvous.

    set target to body("Mun").
    run transfer.

Automating a Mission
--------------------

If you want to script your entire mission end-to-end, it is highly suggested
that you choose `boot_mission` as the boot script for your vessel's main CPU.

To change the mission profile, just edit the mission script so the ship
behaves the right way in each mission state.

Preparing for Launch
--------------------

If your ship will travel farther than 100km from KSC, you should install
a secondary CPU on the vessel and run `boot_prep` to copy the mission
software onto the primary volume. Running archive scripts is fine in low
orbit, but a space probe needs to be able to think for itself!

Contributing & Customizing
==========================

*WARNING*: notice the control flow between programs is very flat. I try never
to call more than 2-3 programs deep. This is because the kOS VM seems to have
bugs with deep call chains; specifically, local variables acquire wrong values
when they have certain names!

See comments in node_apo/node_peri for an example.

Program Naming
--------------

One-word programs should require no parameters so they can be `run` from the
console. Multi-word programs may accept many parameters and must be called
like a function (generally by another program, or possibly from the console).

Program names must be as short as possible while still conveying the purpose
of the program.

Names must follow lexical ordering, i.e. all programs related to maneuver-node
management begin with `node-`: `node_apo`, `node_peri` and so forth. The program
simply named `node` is standalone; it executes the next node, then halts.

The additional words of a program name should convey _what_ the program
accomplishes for single-purpose programs, and _when_ during the mission
the program needs to run, for more complex or long-running program.

1. `node_apo`: create node to change apoapsis
2. `launch_asc`: perform ascent phase of launch

Parameter Passing
-----------------

Whenever possible, programs and functions should accept parameters with
"ordinary" units and frames of reference. The name of the parameter
should convey its unit of measure. Suggested units/frames are:

1. Name of ship orbital position e.g. "apoapsis"
2. Universal time (UT) in seconds after the epoch
3. Altitude (ALT) in meters above SoI surface

Function Libraries
------------------

Programs beginning with `lib/` contain reusable functions and are invoked by
other programs to make use of rudimentary kOS function sharing.

Comments and Documentation
--------------------------

Every program should begin with comments explaining what the program does.
Functions should be likewise commented. Every parameter (to a program _or_ a
function) needs a comment explaining the purpose of the parameter and whether it
is optional.
