#	Mutes users on Esper.net who are spammy.
#

bind flud -|- pub chanflood

proc chanflood {nick host handle type channel} {
	if { [ botisop $channel ] } {
		putquick "mode $channel +q *!$host"	
		putlog "Muting $nick for spamming."
		utimer 21 [list putquick "mode $channel -q *!$host"]
		puthelp "PRIVMSG $nick :The Enter key is not punctuation. For apparently using it as such, you have been temporarily muted in $channel.  If you have a lot to say, please put it on one line."
		return 1
	}
}

#  if {[regexp -all -inline -- {(.)\1{7}} $text]} {# contains something that'S repeated 8 (7+1) times }
#

bind pubm -|- * spamcheck


proc spamcheck { nick host handle channel text } {
	if { $channel == "#minecraft" } {
		return 0
	}
	if { [ botisop $channel ] } {
		if { [ regexp -- {(.)\1{7}} [ string map {" " ""} $text ] ] } {
			#	The line contains something that was repeated 8 (7+1) times
			putquick "mode $channel +q *!$host"
			putlog "Muting $nick for excessive repetition in $channel."
			utimer 21 [ list putquick "mode $channel -q *!$host" ]
			puthelp "PRIVMSG $nick :Seriously; don't repeat characters like that.   It's rude. (If you pasted something, don't do that either. Use pastebin.)"
		}
	}
	return 0
}
