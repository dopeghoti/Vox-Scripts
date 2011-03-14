#bind pub - Voxelhead:	imabot
bind pub - Voxelhead,	imabot

proc imabot {nick idx handle channel args} {
	if {![checkUser $nick $channel]} {return}
	puthelp "PRIVMSG $channel :$nick, I am a bot."
} 
