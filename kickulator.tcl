# Minecraft Help Channel Management Commands
#
#
setudef flag "kickingboots"

bind pub -|- ".boot" mcha:boot
bind pub -|- ".punt" mcha:punt

proc mcha:boot {nick idx handle channel args} {
	if { ! [ channel get $channel "kickingboots" ] } { 
		putlog "$channel doesn't care about $nick kicking remotely."
		return 0 
	}
	set argl [split $args]
	if {[llength $argl] >= "2"} {
		set reasonl [lassign $argl jerk]
		#lassign $argl jerk
		set jerk [string trimleft $jerk \{]
		#set reason [join $argl]
		set reason [string trimright [join $reasonl] \}]
		putkick #minecrafthelp "$jerk" "\[$nick\]: $reason"
		putlog "$nick kicking $jerk from #minecrafthelp because of $reason"
		puthelp "PRIVMSG $channel :$nick, I have kicked $jerk from #minecrafthelp."
	} else {
		puthelp "PRIVMSG $channel :$nick - You must use the format .boot NICK REASON; e. g. .boot Jerkface534 spamming the channel"
		putlog "$nick failed to remote kick properly"
	}
}


proc mcha:punt {nick idx handle channel args} {
	if { ! [ channel get $channel "kickingboots" ] } { 
		putlog "$channel doesn't care about $nick punting remotely."
		return 0 
	}
	set argl [split $args]
	if {[llength $argl] >= "2"} {
		set reasonl [lassign $argl jerk]
		#lassign $argl jerk
		set jerk [string trimleft $jerk \{]
		#set reason [join $argl]
		set reason [string trimright [join $reasonl] \}]
		putkick #minecrafthelp "$jerk" "\[$nick\]: $reason"
		putlog "$nick punting $jerk from #minecrafthelp because of $reason"
		newchanban #minecrafthelp "$jerk!*@*" DopeGhoti "Automated ban:  punted from the channel by $nick - $reason" "10m"
		puthelp "PRIVMSG $channel :$nick, I have banned $jerk from #minecrafthelp for ten minutes."
	} else {
		puthelp "PRIVMSG $channel :$nick - You must use the format .punt NICK REASON; e. g. .punt Jerkface534 spamming the channel"
		putlog "$nick failed to remote punt properly"
	}
}

putlog "Kicking and punting loaded."
