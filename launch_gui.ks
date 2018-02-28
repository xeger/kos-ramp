if ship = activeShip and (status = "landed" or status = "prelaunch") {
	local wnd is gui(200).
	local function init {
		parameter item.
		parameter align is "center".
		set item:style:align to align.
		set item:style:hstretch to true.
		return item.
	}
	local function label {
		parameter text.
		return init(wnd:addLabel(text)).
	}
	local function editor {
		parameter text is "".
		return init(wnd:addTextField(text)).
	}
	local function button {
		parameter text.
		return init(wnd:addButton(text)).
	}
	label("Launch Options").
	label("Target Altitude [km]").
	local alt is editor("200").
	label("Launch Heading [°]").
	local hdg is editor("90").

	if kUniverse:originEditor = "SPH" or ship:name:matchesPattern("\bSSTO\b") {
		local go is button("LAUNCH!").
		local no is button("CANCEL").
		wnd:show().
		wait until go:pressed or no:pressed.
		if go:takePress {
			set alt to alt:text:toScalar().
			set hdg to hdg:text:toScalar().
			wnd:hide().
			run launch_ssto(alt,hdg).
		} else
			wnd:hide().
	} else {
		label("Roll/Rotation").
		local rot is editor("0").
		label("Launch Profile [1-9]").
		label("(higher is safer)").
		local pro is editor("5").
		label("Speed/Altitude [0-20]").
		local srt is editor("12").
		label("Minimal Altitude").
		local mia is editor("100").
		label("Minimal Speed").
		local msp is editor("100").
		local go is button("LAUNCH!").
		local no is button("CANCEL").
		wnd:show().
		wait until go:pressed or no:pressed.
		if go:takePress {
			set alt to alt:text:toScalar().
			set hdg to hdg:text:toScalar().
			set rot to rot:text:toScalar().
			set pro to pro:text:toScalar().
			set srt to srt:text:toScalar().
			set mia to mia:text:toScalar().
			set msp to msp:text:toScalar().
			wnd:hide().
			run launch_asc(alt,hdg,rot,pro,srt,mia,msp).
		} else
			wnd:hide().
	}
}
