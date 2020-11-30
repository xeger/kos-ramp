parameter recipient.
parameter command.
parameter arguments is list().

run once lib_ui.

set data to lexicon().

data:add("command",command).
data:add("arguments",arguments).

if not recipient:istype("Vessel") and recipient:istype("String"){
	List Targets in validRecipients.
	set found to false.
	for v in validRecipients{
		if(v:name = recipient){
			set recipient to vessel(recipient).
			set found to true.
			break.
		}
	}
	if not found{
		uiError("comm","Vessel, '"+recipient+"', cant be found").
	}
}else{
	uiError("comm","Recipient is not of type VESSEL").
}

if recipient:connection:isconnected{
	recipient:connection:sendmessage(data).
	
	wait 0.
	
	set kuniverse:activevessel to recipient.
	
	wait until not ship:messages:empty.
	
	set response to ship:messages:pop.
	if response:content["success"] = 1 {
		uiBanner("comm",response:content["message"]).
	}else{
		uiError("comm","Error: "+response:content["message"]).
	}
	
}else{
	uiError("comm","Connection to "+recipient:name+" could not be established").
}
