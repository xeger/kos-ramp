Introduction
============

Getting Started
===============

Run the launch program to ascend to a circular orbit 20km above your local
atmosphere:

    run launch.

After you reach a stable orbit, plan maneuvers using the `node-` programs and
execute them using the program whose name is simply `node`.

    run node_apo(180000). // plan periapsis burn to raise apoapsis to 180km
    run node.            // make it so!

Automating a Mission
--------------------

If you want to script your entire mission end-to-end, it is highly suggested
that you copy the `launch` program into a program named `mission` that lives
on your vessel.

The `mission` program should be capable of running any phase of your mission;
when executed, it should inspect the state of the world to determine which
phase is current and resume operation starting with that phase.

kOS halts execution when you switch away from a vessel. By creating an
idempotent mission script, you will save yourself from endless frustration
having to reprogram your CPUs and remember your progress every time you restore
a saved game!

Preparing for Launch
--------------------

TODO - implement/discuss `prep` script to precompile all programs & copy them
onto the vessel's CPUs.

Contributing & Customizing
==========================

Program Naming
--------------

One-word programs should require no parameters so they can be `run` from the
console. Multi-word programs may accept many parameters and must be called
like a function (generally by another program, or possibly from the console).

Program names must be as short as possible while still conveying the purpose
of the program.

Names must follow lexical ordering, i.e. all programs related to maneuver-node
management begin with `node-`: `node_apo`, `node_circ` and so forth. The program
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

The programs under `lib/` are reusable code that you can copy-paste into
programs in order to save time. kOS doesn't support true code sharing, but we
can share code by being good citizens and curating our library.

Comments and Documentation
--------------------------

Every program should begin with comments explaining what the program does.
Functions should be likewise commented. Every parameter (to a program _or_ a
function) needs a comment explaining the purpose of the parameter and whether it
is optional.
