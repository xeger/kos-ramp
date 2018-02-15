function resetWarp {
	kUniverse:timeWarp:cancelWarp().
	wait until kUniverse:timeWarp:isSettled.
	set warpMode to "RAILS".
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
		wait 0.
		local dt is time:seconds - t1.
		if dt > 10 {
			warpTo(t1).
			wait until warp = 0 and kUniverse:timeWarp:isSettled.
		} else
		{// warpTo will not warp 10 seconds and less
			physWarp(4).
			wait until time:seconds >= t1-3.
			physWarp(3).
			wait until time:seconds >= t1-1.
			resetWarp().
			break.
		}
	}
	wait until time:seconds >= t1.
	return seconds.
}
