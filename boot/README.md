Universal RAMP Boot Loader `(/boot/boot.ks)`
============================================

This script is intended to install the scripts required for the processor to complete its mission.
If the home connection is available, all (or part) of the RAMP scripts are installed to local storage as well as an optional core-specific mission script.  The mission script (if any) is executed regardless of the presence or absence of a connection.

Folder structure
----------------

Support for subdirectories was added in kOS v1.0.0.  A special directory named `/boot` holds the boot scripts which can be selected in the editor.  Please see https://ksp-kos.github.io/KOS/general/volumes.html#boot for additional information.  The contents of the repository's `boot` directory should be copied into that directory, and all other RAMP files should be copied into a directory named `/ramp`.

By default, the `boot.ks` script will copy the entire contents of the `/ramp` directory to local storage.  It can be helpful to conserve local storage by only copying a subset of that directory.  As an example, assume that you have a small processor which only requires `lib_ui.ks` and `lib_parts.ks` in addition to the mission script.  Copy the `boot.ks` script to another name (say `boot_small.ks`) in the `/boot` directory, and change the line `SET FLS TO "".` to `SET FLS TO LIST("lib_ui", "lib_parts").` in the new file.

Mission script
--------------

Mission scripts are stored in the `/start` directory.  They are named for the vessel (and optionally, the core) upon which they run.  If the boot script is executed on a core with no name tag on a vessel named "Mun Mission", the script would be named `/start/Mun Mission.ks`.  For a core with the name tag "Probe" on a vessel named "Test Relay", the script would be named `/start/Test Relay - Probe.ks`.  If a script is found, it will be executed after files are copied.

You can use the script `initialize.ks` to create a sample file for your core.  The sample code is similar to this:
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
		diskSpace = 180000
	}
}
@PART[KR-2042]
{
	@MODULE[kOSProcessor]
	{
		diskSpace = 256000
	}
}
@PART[kOSMachineRad]
{
	@MODULE[kOSProcessor]
	{
		diskSpace = 256000
	}
}
@PART[KAL9000]
{
	@MODULE[kOSProcessor]
	{
		diskSpace = 512000
	}
}
```
