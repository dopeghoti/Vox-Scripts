bind	join	-	"#minecrafthelp *"	joinmsg-nothing

bind	pub	-|o	".sitedown"		joinmsg-turnon
bind	pub	-|o	".siteup"		joinmsg-turnoff

set joinmsgtext "It seems someone turned on the auto-greeting without setting an actual message.  Please ask a channel operator to turn this off, as I am sure that this is getting annoying."

proc joinmsg-nothing { nick uhost handle channel {text ""} } {

}

proc joinmsg-notice { nick uhost handle channel {text ""} } {
	global joinmsgtext
	utimer 3 [list puthelp "NOTICE $nick :\x02$nick, welcome to #minecrafthelp.  $joinmsgtext"]

}

proc joinmsg-turnon { nick uhost handle channel {text ""} } {
	unbind	join	-	"#minecrafthelp *"	joinmsg-nothing
	bind	join	-	"#minecrafthelp *"	joinmsg-notice
	putlog	"JOIN MESSAGES ENABLED IN #minecrafthelp"
	puthelp "PRIVMSG $channel :$nick, I will now give that message to anyone joining #minecrafthelp."
	global joinmsgtext
	set joinmsgtext "$text"
}

proc joinmsg-turnoff { nick uhost handle channel {text ""} } {
	unbind	join	-	"#minecrafthelp *"	joinmsg-notice
	bind	join	-	"#minecrafthelp *"	joinmsg-nothing
	putlog	"JOIN MESSAGES DISABLED IN #minecrafthelp"
	puthelp "PRIVMSG $channel :$nick, I will stop addressing everyone who joins #minecrafthelp."
}
putlog "Service notice script loaded.  Use .sitedown and .siteup to toggle.  Defaults to .steup mode (no message)."


