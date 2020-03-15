Universal RAMP Boot Loader `(/boot/boot.ks)`
============================================

This program is intended to manage any kind of craft without needing to access the archive in real-time.

It can update RAMP code on ship's drive, extend antennas to reach Kerbal Space Center and also look for a ship-specific mission file. When no connection to KSC is available, it will work offline without prejudice.

Folder structure
----------------

Since kOS v1.0.0 there is support for subfolders. A special subfolder called `boot` holds the scripts that can be selected during ship building in VAB or SPH. (See https://ksp-kos.github.io/KOS/general/volumes.html#boot for more info). You should copy `boot.ks` inside that folder, and all other RAMP files into `/ramp` folder. This let your script folder free for any files you want to use.
When it runs, `boot.ks` will look for a file with the same name of your ship inside `/start` folder, then copy that file to ship's drive and runs it from there. You can update ship's start script at any time, and the next time kOS computer reboots, it will look for the new version, copy and run it. (As long is possible to communicate with KSC, otherwise will proceed with any copy of the script it have saved locally.)
Optionally, RAMP can log its console outputs to a file in `/logs` folder. See `lib_ui.ks` file for more details.

Craft startup script
---------------------

You should provide a craft startup script in the `/start` folder that contains
your vessel's mission logic.

If no script is found for your craft, `boot.ks` will just copy all RAMP scripts
to the vessel's drive and stop.

You can use the script `initialize.ks` to create a sample mission for your ship. You'll find the sample script in the `/start` folder and will be named after your ship. Although it's a sample, it might get you to Mun if you uncomment the transfer command:

```
// We choose go to to the Mun and do the other things!
set target to mun.

// TODO: Do the other things, not because they are easy, but because they are hard!
// run transfer.
```

Feel free to change that to anything that suits your mission, or to copy a
more robust and complete example from the scripts under the `mission/`
folder.

Disk space usage
----------------

RAMP scripts use about 150kb of memory. That seems low, but default kOS hard disk values are very small. In order to be able to load RAMP into ship's memory, is suggested to use a `ModuleManager` patch, for example:
```
@PART[kOSMachine1m]
{
	@MODULE[kOSProcessor]
	{
		diskSpace = 524288
	}
}
@PART[KAL9000]
{
	@MODULE[kOSProcessor]
	{
		diskSpace = 262144
	}
}
@PART[KR-2042]
{
	@MODULE[kOSProcessor]
	{
		diskSpace = 16384
	}
}
@PART[kOSMachineRad]
{
	@MODULE[kOSProcessor]
	{
		diskSpace = 131072
	}
}
```
