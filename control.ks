clearscreen.
run once lib_stage.

local wnd is gui(200).
local function init {
	parameter item.
	parameter width is 0.
	parameter stretch to true.
	parameter align is "center".
	set item:style:align to align.
	set item:style:width to width.
	if width = 0 set item:style:hstretch to stretch.
	return item.
}
local function label {
	parameter wnd.
	parameter text.
	parameter width is 0.
	parameter stretch to true.
	parameter align is "center".
	return init(wnd:addLabel(text), width, stretch, align).
}
local function editor {
	parameter wnd.
	parameter text is "".
	parameter width is 0.
	parameter stretch to true.
	parameter align is "center".
	return init(wnd:addTextField(text), width, stretch, align).
}
local function button {
	parameter wnd.
	parameter text.
	parameter width is 0.
	parameter stretch to true.
	parameter align is "center".
	return init(wnd:addButton(text), width, stretch, align).
}
local function radio {
	parameter lst.
	parameter btn.
	lst:add(btn).
	set btn:toggle to true.
	return btn.
}

label(wnd,"Control "+ship:name).
local dir is list().
local row is wnd:addHLayout().
local dirPro is radio(dir,button(row,"Prograde",100)).
local dirRet is radio(dir,button(row,"Retrograde",100)).
local row is wnd:addHLayout().
local dirNrm is radio(dir,button(row,"Normal",100)).
local dirAnN is radio(dir,button(row,"Anti-N",100)).
local row is wnd:addHLayout().
local dirOut is radio(dir,button(row,"Radial OUT",100)).
local dirRIn is radio(dir,button(row,"Radial IN", 100)).
local row is wnd:addHLayout().
local dirUnl is radio(dir,button(row,"UNLOCK",100)).
local done is button(row,"CLOSE",100).

local function uncheck {
	parameter lst.
	parameter except.
	for btn in lst if btn <> except set btn:pressed to false.
}
local function check {
	parameter lst.
	parameter btn.
	uncheck(list, btn).
	set btn:pressed to true.
}
local function onToggle {
	parameter lst.
	parameter def.
	parameter btn.
	parameter fn.
	parameter on.
	if on { uncheck(lst,btn). fn(). }
	else {
		for b in lst if b:pressed return.
		set def:pressed to true.
	}
}
local function bindToggle {
	parameter btn.
	parameter fn1.
	parameter fn2.
	set btn:onToggle to { parameter on. fn1(btn,fn2,on). }. //fn1:bind(btn,fn2) does not work - bug in kOS?
	return btn.
}
local dirToggle is onToggle@:bind(dir,dirUnl).
bindToggle(dirPro, dirToggle, { sas off. lock steering to prograde. }).
bindToggle(dirRet, dirToggle, { sas off. lock steering to retrograde. }).
bindToggle(dirNrm, dirToggle, { sas off. lock steering to vcrs(velocity:orbit,ship:position-body:position). }).
bindToggle(dirAnN, dirToggle, { sas off. lock steering to vcrs(ship:position-body:position,velocity:orbit). }).
bindToggle(dirOut, dirToggle, { sas off. lock steering to ship:position-body:position. }).
bindToggle(dirRIn, dirToggle, { sas off. lock steering to body:position-ship:position. }).
bindToggle(dirUnl, dirToggle, { unlock steering. }).
set dirUnl:pressed to true.

wnd:show().
until done:takePress {
	stagingCheck().
	wait 0.3.
}
wnd:hide().
unlock all.
