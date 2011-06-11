#	Mutes users on Esper.net who are spammy.
#

bind flud -|- pub chanflood

proc chanflood {nick host handle type channel} {
	putlog "Muting $nick for spamming."
	putquick "mode $channel +q *!$host"	
	utimer 8 [list putquick "mode $channel -q *!$host"]
	return 1
}
