function resetWarp {
	kUniverse:timeWarp:cancelWarp().
	set warp to 0.
	wait 0.
	wait until kUniverse:timeWarp:isSettled.
	set warpMode to "RAILS".
	wait until kUniverse:timeWarp:isSettled.
}
function railsWarp {
	parameter w.
	if warpMode <> "RAILS"
		resetWarp().
	set warp to w.
}
function physWarp {
	parameter w.
	if warpMode <> "PHYSICS" {
		kUniverse:timeWarp:cancelWarp().
		wait until kUniverse:timeWarp:isSettled.
		set warpMode to "PHYSICS".
	}
	set warp to w.
}
function warpSeconds {
	parameter seconds.
	if seconds <= 1 return 0.
	local t1 is time:seconds+seconds.
	until time:seconds >= t1-1 {
		resetWarp().
		if time:seconds < t1-10 {
			warpTo(t1).
			wait 1.
			wait until time:seconds >= t1-1 or (warp = 0 and kUniverse:timeWarp:isSettled).
		} else
		{// warpTo will not warp 10 seconds and less
			if time:seconds < t1-3 {
				physWarp(4).
				wait until time:seconds >= t1-3.
			}
			if time:seconds < t1-2 {
				physWarp(3).
				wait until time:seconds >= t1-2.
			}
			if time:seconds < t1-1 {
				physWarp(2).
				wait until time:seconds >= t1-1.
			}
			resetWarp().
			break.
		}
	}
	resetWarp().
	wait until time:seconds >= t1.
	return seconds.
}
