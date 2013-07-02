# --------------------------------------------------------------------
# Commands
# --------------------------------------------------------------------
# Public Commands:
#   --> /msg <botnick> verify <nick/handle>
# Trainee Commands:
#   --> /msg <botnick> auth <pass>
#   --> /msg <botnick> deauth
# Regular Helper Commands:
#   --> .next              = voices next user in list
#   --> .helped <nick>     = removes voice from <nick>
#   --> .list              = notices you the list
#   --> .skip <nick>       = remove <nick> from the list
#   --> .noidle <nick>     = kickbans <nick> for idling
#   --> .put <nick>        = puts <nick> into the list
# Channel Op Commands:
#   --> .op                = ops you on the channel
#   --> .clearlist         = clear the list
#   --> .getlist           = rebuild the list with non opped/voiced users
#   --> .topic <num>       = sets topic to a preset topic
# Admin Commands:
#   --> .on                = turn script on
#   --> .off               = turn script off
#   --> /msg <botnick> add <nick> <level>
#             = add new user to the bot. The level can be 1, 2, 3 or 4
#               |- level 1 = Trainee
#               |- level 2 = Regular Helper
#               |- level 3 = Channel Op
#               |- level 4 = Administrator
#   --> /msg <botnick> del <nick>
#             = removes <nick> from the bots userlist
# --------------------------------------------------------------------
# VARIABLES
# you have to change these
# --------------------------------------------------------------------

	# The channel you will use this:
set next(chan) "#Minecrafthelp"
	# the char that marks public commands (.next, etc...)
set next(char) "."
	# topics ... k you can add as many topics as you want, just call the other next(topic3) next(topic4) ...
	# note: be carefull with special signs like [ ] " & ...
set next(topic1) "Rules: http://is.gd/zB1w9I- | For account issues see http://is.gd/mc_acct | Minecraft client & server are 1.4.5 | We do not support Classic, deprecated versions, or pre-releases | To downgrade, use MCNostalgia, a backup or Mojang-provided binaries (see ?? oldversion) | Windows 8 issues? Try disabling Metro."
set next(topic2) "Rules: http://is.gd/zB1w9I- | Due to extremely high traffic, this channel moderated for the time being.  You will be given the ability to speak when it is your turn."
	# noidle ban type: (code based on on Moretools.tcl by MC_8)
	#  0 = *!user@host.domain
	#  1 = *!*user@host.domain
	#  2 = *!*@host.domain
	#  3 = *!*user@*.domain
	#  4 = *!*@*.domain
	#  5 = nick!user@host.domain
	#  6 = nick!*user@host.domain
	#  7 = nick!*@host.domain
	#  8 = nick!*user@*.domain
	#  9 = nick!*@*.domain
	# 10 = regular eggdrop mask
set next(bantype) "2"
	# noidle kick message
set next(noidle) "This is not another idle-chan, come back later"
	# noidle bantime
set next(bantime) "5"
	# automatic rebuild the voice list with the non opped/voiced
	# users on the channel after a rehash? (1/0)
set next(rehash) "1"

#  8<-----   Cut here for code ------>8
set next(list) {}
set next(chan) [string tolower $next(chan)]
set next(version) "v2.0"
set next(status) "off"
set next(num2name) "none Trainee {Regular Helper} {Channel Op} Admin Owner"

# --------------------------------------------------------------------
# auth/deauth ... based on multi 3.3 by OUTsider
# --------------------------------------------------------------------
bind msg - auth next.msg:auth
bind msg - deauth next.msg:deauth
proc next.msg:auth {nick uhost hand rest} {
  global botnick
  set pw [lindex $rest 0]
  set op [lindex $rest 1]
  if {$pw == ""} {
  putnotc $nick "Usage: /msg $botnick auth <password> \[recover\]"
  return 0 }
  if {[matchattr $hand Q]} {
  if {[string tolower $op] == "recover"} {
  if {[passwdok $hand $pw]} {
  setuser $hand XTRA SECNICK $nick
  setuser $hand XTRA SECHOST $uhost
  putnotc $nick "New Identity confirmed. Recover Successful" }
  if {![passwdok $hand $pw]} {
  putnotc $nick "Wrong password. Recover failed !"
  return 0 }
  return 0 }
  putnotc $nick "You are already Authenticated."
  putnotc $nick "Nick: [getuser $hand XTRA SECNICK]"
  putnotc $nick "Host: [getuser $hand XTRA SECHOST]"
  putnotc $nick "Try to login with /msg $botnick auth <pass> recover"
  return 0 }
  if {[passwdok $hand $pw] == 1} {
  chattr $hand +Q
  putnotc $nick "Authentication successful!"
  setuser $hand XTRA SECNICK $nick
  setuser $hand XTRA SECHOST $uhost }
  if {[passwdok $hand $pw] == 0} {
  putnotc $nick "Authentication failed!" }}

proc next.msg:deauth {nick uhost hand rest} {
  if {[getuser $hand XTRA SECNICK] == $nick} {
  chattr $hand -Q
  setuser $hand XTRA SECNICK $nick
  setuser $hand XTRA SECHOST $nick
  putnotc $nick "DeAuthentication successful!" }}

# --------------------------------------------------------------------
# procs
# --------------------------------------------------------------------
proc next.check:authed {nick host hand} {
  global botnick
  if {![matchattr $hand +Q]} {
  putnotc $nick "You are not authenticated."
  putnotc $nick "Please do so with /msg $botnick auth <password>."
  return 0}
  if {[getuser $hand XTRA SECNICK] != $nick} {
  putnotc $nick "Sorry. But I think I missed one of your nickchanges"
  return 0}
  if {[getuser $hand XTRA SECHOST] != $host} {
  putnotc $nick "Sorry. But you don't have the correct host right now."
  return 0}
  return 1}

proc next.addflags {handle level} {
  global next
  switch $level {
  4 { chattr $handle +h|+vfgom $next(chan); return 1 }
  3 { chattr $handle +h|+vfgo $next(chan); return 1 }
  2 { chattr $handle +h|+vfg $next(chan); return 1 }
  1 { chattr $handle +h|+fg $next(chan); return 1 }
  }
}

proc next.getlevel {handle} {
  global next
  if {[matchattr $handle n|n $next(chan)]} { return 5
  } elseif {[matchattr $handle m|m $next(chan)]} { return 4
  } elseif {[matchattr $handle o|o $next(chan)]} { return 3
  } elseif {[matchattr $handle v|v $next(chan)]} { return 2
  } elseif {[matchattr $handle f|f $next(chan)]} { return 1
  } else { return 0 }
}

# --------------------------------------------------------------------
# mode handlers
# --------------------------------------------------------------------
#### join / rejoin
proc next.add {nick uhost handle chan} {
	global botnick next
	if {$nick == $botnick || [string tolower $chan] != $next(chan) || [matchattr $handle g|g $next(chan)]} { return }
	lappend next(list) $nick
	set num [lsearch -exact $next(list) $nick]
	incr num
	putserv "NOTICE $nick :Please be patient and wait for your turn as we are busy right now. You are number $num in line. Thank you!"
}
#### part & sign
proc next.purge {nick uhost handle chan msg} {
	global botnick next
	if {$nick == $botnick || [string tolower $chan] != $next(chan) || [matchattr $handle g|g $next(chan)]} { return }
	set index [lsearch -exact $next(list) $nick]
	if {$index >= 0} {
	set next(list) [lreplace $next(list) $index $index ]
	} else { return }
}
#### nick
proc next.replace {nick uhost handle chan newnick} {
	global botnick next
	if {$nick == $botnick || [string tolower $chan] != $next(chan) || [matchattr $handle g|g $next(chan)]} { return }
	set index [lsearch -exact $next(list) $nick]
	if {$index >= 0} {
	set next(list) [lreplace $next(list) $index $index $newnick]
	} else { return }
}
#### kick
proc next.kick {nick uhost handle chan vict reason} {
	global botnick next
	if {$vict == $botnick || [string tolower $chan] != $next(chan) || [matchattr [nick2hand $vict $next(chan)] g|g $next(chan)]} { return }
	set index [lsearch -exact $next(list) $vict]
	set next(list) [lreplace $next(list) $index $index ]
}
#### split
proc next.splt {nick uhost handle chan} { 
	global botnick next
	if {$nick == $botnick || [string tolower $chan] != $next(chan) || [matchattr $handle g|g $next(chan)]} { return }
	set index [lsearch -exact $next(list) $nick]
	set next(list) [lreplace $next(list) $index $index ]
}
#### voiced / opped
proc next.voiced {nick host hand chan mdechg dnick} {
	global botnick next
	if {[string tolower $chan] == $next(chan) && $dnick != $botnick} {
	set index [lsearch -exact $next(list) $dnick]
	set next(list) [lreplace $next(list) $index $index ]
	} else { return }
}
#### rehash
proc next.rehash {type} {
	global botnick next
	if {$next(rehash) && [botonchan $next(chan)]} {
	set llength [llength $next(list)]
	foreach user [chanlist $next(chan)] {
		if {![isvoice $user $next(chan)] && ![isop $user $next(chan)] && [onchan $user $next(chan)] && $user != $botnick && ![matchattr [nick2hand $user $next(chan)] g $next(chan)]} {
			set index [lsearch -exact $next(list) [lindex $user 0]]
			if {$index < 0} {
			set next(list) [linsert $next(list) $llength $user ]
			}
		}
	}
	}
}

# --------------------------------------------------------------------
# public commands
# --------------------------------------------------------------------
bind msg - version next.msg:version
bind msg - verify next.msg:verify
#### version
proc next.msg:version {nick uhost handle arg} {
	global version next
	putserv "NOTICE $nick :\002.next $next(version) \002[lindex $version 0]."
}
#### verify
proc next.msg:verify {nick uhost handle arg} {
	global botnick next
	set helper [lindex [split $arg] 0]
	set notice ""
	set service [string range $next(chan) 1 end]
	if {$helper == ""} { putserv "NOTICE $nick :Usage: /msg $botnick verify <nick>"; return }
  if {[onchan $helper $next(chan)]} {
	if {[next.getlevel [nick2hand $helper $next(chan)]]} {
		putnotc $nick "\[\002$service\002\] $helper is a(n)\002 [lindex $next(num2name) [next.getlevel [nick2hand $helper $next(chan)]]] \002of $next(chan)"
	} else { putnotc $nick "\[\002$service\002\] I could not find any results matching $helper" }
  } else {
	if {[next.getlevel $helper]} {
		putnotc $nick "\[\002$service\002\] $helper is a(n)\002 [lindex $next(num2name) [next.getlevel $helper]] \002of $next(chan)"
	} else { putnotc $nick "\[\002$service\002\] I could not find any results matching $helper" }
  }

}

# --------------------------------------------------------------------
# Regular command handlers
# --------------------------------------------------------------------
#### next
proc next.pub:voice {nick uhost handle chan arg} {
	global next
	if {[string tolower $chan] != $next(chan)} { return 0 }
	if {![next.check:authed $nick $uhost $handle]} { return 0 }
	if {[next.getlevel $handle] >= 2} {
	if {$next(list) == ""} { putserv "NOTICE $nick :Queue is currently empty." ; return }
	if {[botisop $chan]} {
	foreach voice $next(list) {
	putserv "MODE $chan +v $voice"
	set index [lsearch -exact $next(list) $voice]
	set next(list) [lreplace $next(list) $index $index ]
	putserv "PRIVMSG $chan :$voice: please ask your question now. You will be helped by $nick"
	break }; return }
	putserv "NOTICE $nick :I can't do my job, because I'm not oped on $chan."
	return
	} else { return 0 }
}
#### helped
proc next.pub:helped {nick uhost handle chan arg} {
	global botnick next
	if {[string tolower $chan] != $next(chan)} { return 0 }
	if {![next.check:authed $nick $uhost $handle]} { return 0 }
	if {[next.getlevel $handle] >= 2} {
	if {[botisop $chan] && [isvoice [lindex [split $arg] 0] $chan]} {
	putserv "MODE $chan -v :[lindex [split $arg] 0]"
	putserv "NOTICE [lindex [split $arg] 0] :You have been helped. Feel free to stick around; if you have another question, please rejoin the channel to get back in line."
	return }
	} else { return 0 }
}
#### noidle #### bantype code based on Moretools.tcl by MC_8
proc next.pub:noidle {nick uhost handle chan arg} {
	#
	#	Yeah, we're not doing this.  At least, not yet.
	#
	#	global botnick botname next
	#	if {[string tolower $chan] != $next(chan)} { return 0 }
	#	if {![next.check:authed $nick $uhost $handle]} { return 0 }
	#	if {[next.getlevel $handle] >= 2} {
	#	if {[lindex [split $arg] 0] == ""} {putserv "NOTICE $nick :Usage: .noidle <nick>"
	#	return}
	#	if {[next.getlevel [nick2hand [lindex [split $arg] 0] $next(chan)]] >= 1} {
	#	  putnotc $nick "[lindex [split $arg] 0] is allowed to idle on $next(chan)!"; return}
	#	if {[onchan [lindex [split $arg] 0] $next(chan)]} {set index [lsearch -exact $next(list) [lindex [split $arg] 0]]
	#	if {$index >= 0} {
	#	set next(list) [lreplace $next(list) $index $index ]
	#	}
	#		switch $next(bantype) {
	#		  0 {set ban "*![string range [getchanhost [lindex [split $arg] 0] $next(chan)] [string first ! [getchanhost [lindex [split $arg] 0] $next(chan)]] e]"}
	#		  1 {set ban "*!*[string trimleft [string range [getchanhost [lindex [split $arg] 0] $next(chan)] [expr [string first ! [getchanhost [lindex [split $arg] 0] $next(chan)]]+1] e] "~"]"}
	#		  2 {set ban "*!*[string range [getchanhost [lindex [split $arg] 0] $next(chan)] [string first @ [getchanhost [lindex [split $arg] 0] $next(chan)]] e]"}
	#		  3 {set ident [string range [getchanhost [lindex [split $arg] 0] $next(chan)] [expr [string first ! [getchanhost [lindex [split $arg] 0] $next(chan)]]+1] [expr [string last @ [getchanhost [lindex [split $arg] 0] $next(chan)]]-1]] ; set ban "*!*[string trimleft $ident "~"][string range [maskhost [getchanhost [lindex [split $arg] 0] $next(chan)]] [string first @ [maskhost [getchanhost [lindex [split $arg] 0] $next(chan)]]] e]"}
	#		  4 {set ban "*!*[string range [maskhost [getchanhost [lindex [split $arg] 0] $next(chan)]] [string last "@" [maskhost [getchanhost [lindex [split $arg] 0] $next(chan)]]] e]"}
	#		  5 {set ban "[lindex [split $arg] 0]![string range [getchanhost [lindex [split $arg] 0] $next(chan)] [string first ! [getchanhost [lindex [split $arg] 0] $next(chan)]] e]"}
	#		  6 {set nick [string range [getchanhost [lindex [split $arg] 0] $next(chan)] 0 [expr [string first "!" [getchanhost [lindex [split $arg] 0] $next(chan)]]-1]] ; set ident [string range [getchanhost [lindex [split $arg] 0] $next(chan)] [expr [string first "!" [getchanhost [lindex [split $arg] 0] $next(chan)]]+1] [expr [string last "@" [getchanhost [lindex [split $arg] 0] $next(chan)]]-1]] ; set ban "[lindex [split $arg] 0]!*[string trimleft $ident "~"][string range [getchanhost [lindex [split $arg] 0] $next(chan)] [string last "@" [getchanhost [lindex [split $arg] 0] $next(chan)]] e]"}
	#		  7 {set nick [string range [getchanhost [lindex [split $arg] 0] $next(chan)] 0 [expr [string first "!" [getchanhost [lindex [split $arg] 0] $next(chan)]]-1]] ; set ban "[lindex [split $arg] 0]!*[string range [getchanhost [lindex [split $arg] 0] $next(chan)] [string last "@" [getchanhost [lindex [split $arg] 0] $next(chan)]] e]"}
	#		  8 {set nick [string range [getchanhost [lindex [split $arg] 0] $next(chan)] 0 [expr [string first "!" [getchanhost [lindex [split $arg] 0] $next(chan)]]-1]] ; set ident [string range [getchanhost [lindex [split $arg] 0] $next(chan)] [expr [string first "!" [getchanhost [lindex [split $arg] 0] $next(chan)]]+1] [expr [string last "@" [getchanhost [lindex [split $arg] 0] $next(chan)]]-1]] ; set ban "[lindex [split $arg] 0]!*[string trimleft $ident "~"][string range [maskhost [getchanhost [lindex [split $arg] 0] $next(chan)]] [string last "@" [maskhost [getchanhost [lindex [split $arg] 0] $next(chan)]]] e]"}
	#		  9 {set nick [string range [getchanhost [lindex [split $arg] 0] $next(chan)] 0 [expr [string first "!" [getchanhost [lindex [split $arg] 0] $next(chan)]]-1]] ; set ban "[lindex [split $arg] 0]!*[string range [maskhost [getchanhost [lindex [split $arg] 0] $next(chan)]] [string last "@" [maskhost [getchanhost [lindex [split $arg] 0] $next(chan)]]] e]"}
	#		  default {set ban "*!*[string range [getchanhost [lindex [split $arg] 0] $next(chan)] [string first "@" [getchanhost [lindex [split $arg] 0] $next(chan)]] e]"}
	#		}
	#		set nnick [lindex [split $ban !] 0]
	#		set iident [string range $ban [expr [string first ! $ban]+1] [expr [string last @ $ban]-1]]
	#		set hhost [string range $ban [expr [string last @ $ban]+1] e]
	#		if {$iident != [set temp [string range $iident [expr [string length $iident]-9] e]]} {set iident *[string trimleft $temp *]}
	#		if {$hhost != [set temp [string range $hhost [expr [string length $hhost]-63] e]]} {set hhost *[string trimleft $temp *]}
	#		set next(ban) "$nnick!$iident@$hhost"
	#	if {[string match "$next(ban)" "$botname"]} {putserv "NOTICE $nick :The ban ( $next(ban) ) matches me ..."
	#	return }
	#	newchanban $next(chan) $next(ban) $nick "$next(noidle)" $next(bantime)
	#	pushmode $chan -o [lindex [split $arg] 0]
	#	pushmode $chan +b $next(ban)
	#	putkick $chan [lindex [split $arg] 0] "$next(noidle)"
	#	return }
	#	putserv "NOTICE $nick :[lindex [split $arg] 0] isn't on $next(chan)"
	#	return }
	return
}
#### list
proc next.pub:list {nick uhost handle chan arg} {
	global next
	if {[string tolower $chan] != $next(chan)} { return 0 }
	if {![next.check:authed $nick $uhost $handle]} { return 0 }
	if {[next.getlevel $handle] >= 2} {
	if {$next(list) == ""} { putserv "NOTICE $nick :The queue is curently empty."
	return }
	putserv "NOTICE $nick :\002List\002: $next(list)"; return
	} else { return 0 }
}
#### put
proc next.pub:put {nick uhost handle chan arg} {
	global botnick next
	if {[string tolower $chan] != $next(chan)} { return 0 }
	if {![next.check:authed $nick $uhost $handle]} { return 0 }
	if {[next.getlevel $handle] >= 2} {
	if {[lindex [split $arg] 0] == ""} {putserv "NOTICE $nick :usage: .put <nick>"
	return }
	if {[lindex [split $arg] 0] == $botnick} {putserv "NOTICE $nick :Come again?"
	return }
	if {[onchan [lindex [split $arg] 0] $next(chan)]} {lappend next(list) [lrange $arg 0 end]
	putserv "NOTICE $nick :[lindex [split $arg] 0] has been added to the queue."
	return }
	putserv "NOTICE $nick :[lindex [split $arg] 0] isn't on $next(chan)"
	return
	} else { return }
}
#### skip
proc next.pub:skip {nick uhost handle chan arg} {
	global botnick next
	if {[string tolower $chan] != $next(chan)} { return 0 }
	if {![next.check:authed $nick $uhost $handle]} { return 0 }
	if {[next.getlevel $handle] >= 2} {
	if {[lindex [split $arg] 0] == ""} {putserv "NOTICE $nick :\002Usage:\002 skip <nick>"
	return}
	if {[lindex [split $arg] 0] == $botnick} {putserv "NOTICE $nick :Come again?"
	return}
	set index [lsearch -exact $next(list) [lindex [split $arg] 0]]; set next(list) [lreplace $next(list) $index $index ]
	putserv "NOTICE $nick :[lindex [split $arg] 0] has been removed from the queue."
	return
	} else { return }
}

# --------------------------------------------------------------------
# Channel Op command handlers
# --------------------------------------------------------------------
bind pub - ${next(char)}op next.pub:op
#### op
proc next.pub:op {nick uhost handle chan arg} {
	global next
	if {[string tolower $chan] != $next(chan)} { return 0 }
	if {![next.check:authed $nick $uhost $handle]} { return 0 }
	if {[next.getlevel $handle] >= 3} {
	if {[botisop $chan]} {
	putserv "MODE $chan +o $nick"
	} else {
	putserv "NOTICE $nick :I can't op you in $chan because I'm not opped myself!"
	}
	return
	} else { return }
}
#### getlist
proc next.pub:getlist {nick uhost handle chan arg} {
	global botnick next
	if {[string tolower $chan] != $next(chan)} { return 0 }
	if {![next.check:authed $nick $uhost $handle]} { return 0 }
	if {[next.getlevel $handle] >= 3} {
	set llength [llength $next(list)]
	foreach user [chanlist $chan] {
		if {![isvoice $user $chan] && ![isop $user $chan] && [onchan $user $chan] && $user != $botnick && ![matchattr [nick2hand $nick $chan] o]} {
			set index [lsearch -exact $next(list) [lindex $user 0]]
			if {$index < 0} {
			set next(list) [linsert $next(list) $llength $user ]
			}
		}
	}
	if {$next(list) == ""} { putserv "NOTICE $nick :No users added to queue; the queue is empty."
	} else {
	putserv "NOTICE $nick :\002getlist copmleted\002. ( $next(list) )"
	}
	return
	} else { return }
}
#### clearlist
proc next.pub:clearlist {nick uhost handle chan arg} {
	global botnick next
	if {[string tolower $chan] != $next(chan)} { return 0 }
	if {![next.check:authed $nick $uhost $handle]} { return 0 }
	if {[next.getlevel $handle] >= 3} {
		if {[llength $next(list)] == "0"} {
		putserv "NOTICE $nick :The queue is already empty. No users to remove."
		return
		} else {
		set next(list) {}
		putserv "NOTICE $nick :The queue has been cleared."
		return
		}
	} else { return }
}
#### topic
proc next.pub:topic {nick uhost handle chan arg} {
	global botnick next
	if {[string tolower $chan] != $next(chan)} { return 0 }
	if {![next.check:authed $nick $uhost $handle]} { return 0 }
	if {[next.getlevel $handle] >= 3} {
	if {[lindex [split $arg] 0] == ""} {putserv "NOTICE $nick :\002Usage:\002 .topic <number>"
	return}
	if {[botisop $chan]} {
	set num "[lindex [split $arg] 0]"
		if {[info exists next(topic$num)]} {
		putserv "TOPIC $next(chan) :$next(topic$num)"
		} else {
		putserv "NOTICE $nick :\002.topic $num \002 is not a valid topic"
		}
	} else {
	putserv "NOTICE $nick :I can't change the topic because I'm not opped on $chan"
	}
	return
	} else { return }
	return
}

# --------------------------------------------------------------------
# Admin command handlers
# --------------------------------------------------------------------
bind pub m|m ${next(char)}on next.pub:on
bind pub m|m ${next(char)}off next.pub:off
bind msg m|m add next.msg:add
bind msg m|m del next.msg:del
#### add
proc next.msg:add {nick uhost handle arg} {
	global next botnick
	if {![next.check:authed $nick $uhost $handle]} { return 0 }
	set who [lindex [split $arg] 0]
	set lvl [lindex [split $arg] 1]
	if {$who == "" || $lvl == ""} {putnotc $nick "Usage: /msg $botnick add <nick> <level>"; return 0}
	if {![onchan $who $next(chan)]} { putnotc $nick "Sorry, but I can't find $who on $next(chan)"; return 0 }
	if {[nick2hand $who $next(chan)] != "" && [nick2hand $who $next(chan)] != "*"} {
	  putnotc $nick "$who is allready known in the bot as [nick2hand $who $next(chan)], level [lindex $next(num2name) [next.getlevel $who]]"
	  if {[next.getlevel $who] < 4} {
	    if {$lvl == 4 || $lvl == 3 || $lvl == 2 || $lvl == 1} {
	      next.addflags $who $lvl
	      putnotc $nick "Added\002 $who \002as a(n)\002 [lindex $next(num2name) $lvl] \002of $next(chan) to the bot."
	      putnotc $who "You have been added as a(n)\002 [lindex $next(num2name) $lvl] \002of $next(chan) to the bot."
	      return 1
	    } else {
	      putnotc $nick "the level can be 1, 2, 3 or 4"
	      putnotc $nick "- level 1 = Trainee"
	      putnotc $nick "- level 2 = Regular Helper"
	      putnotc $nick "- level 3 = Channel Op"
	      putnotc $nick "- level 4 = Administrator"
	      return 0
	    }
	  }
	}
	if {[validuser $who]} { putnotc $nick "I was unable to add $who to the userlist. There is already a user with that handle"; return 0}
	if {$lvl == 1 || $lvl == 2 || $lvl == 3 || $lvl == 4} {
	    set host "[maskhost $who![getchanhost $who $next(chan)]]"
	    adduser $who $host
	    putnotc $who "You have been added to the bot. Please set your pass: type /msg $botnick pass <your_pass>"
	    putnotc $who "To authenticate, type /msg $botnick auth <password>"
	    next.addflags $who $lvl
	    putnotc $nick "Added\002 $who \002as a(n)\002 [lindex $next(num2name) $lvl] \002of $next(chan) to the bot."
	    return 1
	} else {
	    putnotc $nick "the level can be 1, 2, 3 or 4"
	    putnotc $nick "- level 1 = Trainee"
	    putnotc $nick "- level 2 = Regular Helper"
	    putnotc $nick "- level 3 = Channel Op"
	    putnotc $nick "- level 4 = Administrator"
	    return 0
	}
}
#### del
proc next.msg:del {nick uhost handle arg} {
global next botnick
  if {![next.check:authed $nick $uhost $handle]} { return 0 }
  set who [lindex [split $arg] 0]
  if {$who == ""} {putnotc $nick "Usage: /msg $botnick del <nick>"; return 0}
  if {![onchan $who $next(chan)]} {putnotc $nick "Sorry. But I can't find\002 $who \002on $next(chan)"; return 0}
  if {[nick2hand $who $next(chan)] == "" || [nick2hand $who $next(chan)] == "*"} {
  	putnotc $nick "Sorry. But I can't find\002 $who \002 in the userlist"
  return 0 }
  if {[next.getlevel [nick2hand $who $next(chan)]] >= [next.getlevel [nick2hand $nick $next(chan)]]} {
  	putnotc $nick "Sorry. But you can't delete a user with an eqaul or higher level then yourself"
  return 0 }
  deluser [nick2hand $who $next(chan)]
  putnotc $nick "Deleted\002 $who \002from the userlist"
}
#### on
proc next.pub:on {nick uhost handle chan arg} {
global next botnick
	if {![next.check:authed $nick $uhost $handle]} { return 0 }
	if {$next(status) == "on"} {
		putserv "NOTICE $nick :Queue-based mode is already on."
	} else {
		next.status on
		putserv "NOTICE $nick :Enabling queue-based mode.  Setting channel mode +m ..."
		putserv "MODE $next(chan) +m"
		set next(status) "on"
	}
}
#### off
proc next.pub:off {nick uhost handle chan arg} {
global next botnick
	if {![next.check:authed $nick $uhost $handle]} { return 0 }
	if {$next(status) == "off"} {
		putserv "NOTICE $nick :Queue-based mode ia already off."
	} else {
		next.status off
		putserv "NOTICE $nick :Disabling queue-based mode.  Setting channel mode -m ..."
		putserv "MODE $next(chan) -m"
		set next(status) "off"
	}
}

proc next.status {arg} {
global next
  switch $arg {
	on {
		bind join - * next.add
		bind rejn - * next.add
		bind part - * next.purge
		bind sign - * next.purge
		bind nick - * next.replace
		bind kick - * next.kick
		bind splt - * next.splt
		bind mode - *+v* next.voiced
		bind mode - *+o* next.voiced
		bind evnt - rehash next.rehash

		bind pub - ${next(char)}next next.pub:voice
		bind pub - ${next(char)}helped next.pub:helped
		bind pub - ${next(char)}list next.pub:list
		bind pub - ${next(char)}skip next.pub:skip
		#bind pub - ${next(char)}noidle next.pub:noidle
		bind pub - ${next(char)}put next.pub:put
		bind pub - ${next(char)}clearlist next.pub:clearlist
		bind pub - ${next(char)}getlist next.pub:getlist
		bind pub - ${next(char)}topic next.pub:topic
	return 1}
	off {
		catch { unbind join - * next.add }
		catch { unbind rejn - * next.add }
		catch { unbind part - * next.purge }
		catch { unbind sign - * next.purge }
		catch { unbind nick - * next.replace }
		catch { unbind kick - * next.kick }
		catch { unbind splt - * next.splt }
		catch { unbind mode - *+v* next.voiced }
		catch { unbind mode - *+o* next.voiced }
		catch { unbind evnt - rehash next.rehash }

		catch { unbind pub - ${next(char)}next next.pub:voice }
		catch { unbind pub - ${next(char)}helped next.pub:helped }
		catch { unbind pub - ${next(char)}list next.pub:list }
		catch { unbind pub - ${next(char)}skip next.pub:skip }
		catch { unbind pub - ${next(char)}noidle next.pub:noidle }
		catch { unbind pub - ${next(char)}put next.pub:put }
		catch { unbind pub - ${next(char)}clearlist next.pub:clearlist }
		catch { unbind pub - ${next(char)}getlist next.pub:getlist }
		catch { unbind pub - ${next(char)}topic next.pub:topic }
	return 1}
  }
}

next.status off
putlog "Queue-based support system loaded"
