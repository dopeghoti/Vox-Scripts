# Vote script

# Initial version by Loki`
#
# Completely rewritten by DopeGhoti © 2011
#
#Type '/msg <botnick> vote help' for commands

#	Channel flag that must be st for this script to be active in a channel
set chanflag "votebox"
setudef flag $chanflag

###------------------------ Vote Bindings ------------------------###
bind pub - ".startvote" vote_start
bind pub o|o ".endvote" vote_results
#bind pub o|o ".seniorvote" senior_vote
bind pub o|o ".opvote" op_vote
bind pub o|o ".voicevote" voice_vote
bind pub o|o ".anyvote" any_vote
bind pub - ".vote" vote_update
bind pub - ".time" vote_timer
bind pub - ".help" vote_chanhelp
bind msg - vote vote_vote
bind join o|o * vote_reminder

###------------------------ Detect and remove old voting data on startup ------------------------###
if {![info exists voting]} {
	set voting no
	set voting_chan none
	catch {
		killutimer $voteset(t1)
		killutimer $voteset(t2)
		killutimer $voteset(t3)
		killutimer $voteset(t4)
		killutimer $voteset(t5)
	}
}

###------------------------ Start the vote ------------------------###
proc vote_start {nick mask hand chan text} {
	global chanflag voting voting_chan botnick vote_topic vote_no vote_yes vote_abstain voted_people vote_time vote_timestart vote_comments voteset
	# Make sure this is a valid channel
	if { [ channel get $chan $chanflag ] } {
		if {$voting == "yes"} {
			putserv "NOTICE $nick :\002VoteBox\002: Only one voting session is allowed at one time.  Please wait until the current poll is closed."
			return 0
		} else {
			set timeleft [lindex $text 0]
			if [string match "*m" [string tolower [lindex $text 0]]] {
				set vote_time [expr [string trimright $timeleft m] * 60]
				set vote_timestart [unixtime]
			} elseif [string match "*h" [string tolower [lindex $text 0]]] {
				set vote_time [expr [string trimright $timeleft h] * 3600]
				set vote_timestart [unixtime]
			} else {
				puthelp "NOTICE $nick :\002VoteBox\002: Please type '/msg $botnick vote help' for assistance."
				return 0
			}
			set voting yes
			set voting_chan $chan
			if [info exists vote_comments] {
				unset vote_comments
			}
			set vote_yes 0
			set vote_no 0
			set vote_abstain 0
			set vote_topic [lrange $text 1 end]
			putlog "\002VoteBox\002: $nick on $chan started voting on $vote_topic"
			puthelp "PRIVMSG $voting_chan :\002VoteBox\002: Now voting on: \002$vote_topic\002"
			puthelp "PRIVMSG $voting_chan :\002VoteBox\002: Please place your votes!  '/msg $botnick vote <yes/no/abstain> \[comments\]' or '/msg $botnick vote help' for assistance."
			puthelp "PRIVMSG $voting_chan :\002VoteBox\002  \002[duration $vote_time]\002 left!"
			set vote_timer4th [expr $vote_time / 4]
			if {$vote_time > 1200} {
				set voteset(t1) [utimer [expr $vote_timer4th + $vote_timer4th+ $vote_timer4th] vote_warning]
			}
			if {$vote_time > 2400} {
				set voteset(t2) [utimer $vote_timer4th vote_warning]
				set voteset(t3) [utimer [expr $vote_timer4th + $vote_timer4th] vote_warning]
				set voteset(t4) [utimer [expr $vote_time - 360] vote_warning]
			}
			set voteset(t5) [utimer $vote_time "vote_results 1 2 3 $voting_chan 5"]
			if {[info exists voted_people]} { unset voted_people }
			return 1
		}
	}
}

###------------------------ Process vote triggers (yes/no/comment) ------------------------###
proc vote_vote {nick mask hand text} {
	global chanflag vote_yes vote_no vote_abstain voted_people voting vote_comments botnick voting_chan
	if {[string tolower [lindex $text 0]] == "help"} {
		vote_helplist $nick
		return 0
	}
	set mask [maskhost $mask]
	if {$voting == "no"} {
		puthelp "NOTICE $nick :\002VoteBox\002: The polls are currently closed.  Try again when there's a question on the table."
		return 0
	} elseif [matchattr $hand b] {
		puthelp "NOTICE $nick :\002VoteBox\002: Whoever's controlling this bot, nice try!"
		puthelp "PRIVMSG $voting_chan :\002VoteBox\002: Someone's trying to vote using $nick!"
		return 0
	} elseif {[string tolower [lindex $text 0]] == "comments"} {
		vote_commentlist $nick
		return 0
	} elseif {[string tolower [lindex $text 0]] == "stats"} {
		vote_statlist $nick
		return 0
	} elseif {[info exists voted_people($mask)]} {
		puthelp "NOTICE $nick :\002VoteBox\002: Sorry, you already voted."
		return 0
	} elseif {[string tolower [lindex $text 0]] == "yes"} {
		puthelp "NOTICE $nick :\002VoteBox\002: Your vote has been counted!  Thanks for participating in our fake democracy, $nick!"
		set vote_yes [incr vote_yes]
		if {[lrange $text 1 end] != ""} {
			set vote_comments($nick) [lrange $text 1 end]
		}
		set voted_people($mask) 1
		return 0
	} elseif {[string tolower [lindex $text 0]] == "no"} {
		puthelp "NOTICE $nick :\002VoteBox\002: Your vote has been counted!  Thanks for participating in our fake democracy, $nick!"
		set vote_no [incr vote_no]
		if {[lrange $text 1 end] != ""} {
			set vote_comments($nick) [lrange $text 1 end]
		}
		set voted_people($mask) 1
		return 0
	} elseif {[string tolower [lindex $text 0]] == "abstain"} {
		puthelp "NOTICE $nick :\002VoteBox\002: Your lack of a vote has been counted!  Thanks for not really participating in our fake democracy, $nick!"
		set vote_abstain [incr vote_abstain]
		if {[lrange $text 1 end] != ""} {
			set vote_comments($nick) [lrange $text 1 end]
		}
		set voted_people($mask) 1
		return 0
	} else {
		puthelp "NOTICE $nick :\002\VoteBox\002: Please type '/msg $botnick vote help' for assistance."
	}
}

###------------------------ Seniorvote Trigger ------------------------###
#proc senior_vote {nick mask hand chan text} {
#	global chanflag voting_chan vote_yes vote_no vote_topic voting botnick
#	# Make sure this is a valid channel
#	if { [ channel get $chan $chanflag ] } {
#		vote_unbind
#		bind pub S|S ".vote" vote_update
#		bind pub S|S ".time" vote_timer
#		bind msg S|S vote vote_vote
#		bind join S|S * vote_reminder
#		puthelp "PRIVMSG $voting_chan :\002VoteBox\002: \002Voting now open for group seniors ONLY!!\002"
#		puthelp "PRIVMSG $voting_chan :\002VoteBox\002: '/msg $botnick vote <yes/no> \[comments\]' or '/msg $botnick vote help' for more commands"
#	}
#}

###------------------------ Opvote Trigger ------------------------###
proc op_vote {nick mask hand chan text} {
	global chanflag voting_chan vote_yes vote_no vote_abstain vote_topic voting botnick
	# Make sure this is a valid channel
	if { [ channel get $chan $chanflag ] } {
		vote_unbind
		bind pub o|o ".vote" vote_update
		bind pub o|o ".time" vote_timer
		bind msg o|o vote vote_vote
		bind join o|o * vote_reminder
		puthelp "PRIVMSG $voting_chan :\002VoteBox\002: \002Voting now open for ops only!! \(Make up your mind, already!\)\002"
		puthelp "PRIVMSG $voting_chan :\002VoteBox\002: '/msg $botnick vote <yes/no/abstain> \[comments\]' or '/msg $botnick vote help' for more commands"
	}
}

###------------------------ Voicevote Trigger ------------------------###
proc voice_vote {nick mask hand chan text} {
	global chanflag voting_chan vote_yes vote_no vote_abstain vote_topic voting botnick
	# Make sure this is a valid channel
	if { [ channel get $chan $chanflag ] } {
		vote_unbind
		bind pub vo|vo ".vote" vote_update
		bind pub vo|vo ".time" vote_timer
		bind msg vo|vo vote vote_vote
		bind join vo|vo * vote_reminder
		puthelp "PRIVMSG $voting_chan :\002VoteBox\002: \002Voting now open for all +v people!!\002"
		puthelp "PRIVMSG $voting_chan :\002VoteBox\002: '/msg $botnick vote <yes/no/abstain> \[comments\]' or '/msg $botnick vote help' for more commands"
	}
}

###------------------------ Anyvote Trigger ------------------------###
proc any_vote {nick mask hand chan text} {
	global chanflag voting_chan vote_yes vote_no vote_abstain vote_topic voting botnick
	# Make sure this is a valid channel
	if { [ channel get $chan $chanflag ] } {
		vote_unbind
		bind pub - ".vote" vote_update
		bind pub - ".time" vote_timer
		bind msg - vote vote_vote
		bind join - * vote_reminder
		puthelp "PRIVMSG $voting_chan :\002VoteBox\002: \002Voting now open for anyone!!\002"
		puthelp "PRIVMSG $voting_chan :\002VoteBox\002: '/msg $botnick vote <yes/no/abstain> \[comments\]' or '/msg $botnick vote help' for more commands"
	}
}

###------------------------ Mass Unbind ------------------------###
proc vote_unbind {} {
	catch {
		unbind pub S|S ".vote" vote_update
		unbind pub S|S ".time" vote_timer
		unbind msg S|S vote vote_vote
		unbind join S|S * vote_reminder
		unbind pub o|o ".vote" vote_update
		unbind pub o|o ".time" vote_timer
		unbind msg o|o vote vote_vote
		unbind join o|o * vote_reminder
		unbind pub v|v ".vote" vote_update
		unbind pub v|v ".time" vote_timer
		unbind msg v|v vote vote_vote
		unbind join v|v * vote_reminder
		unbind pub - ".vote" vote_update
		unbind pub - ".time" vote_timer
		unbind msg - vote vote_vote
		unbind join - * vote_reminder
	}
	return
}

###------------------------ Display Results ------------------------###
proc vote_results {nick mask hand chan text} {
	global chanflag voting_chan vote_yes vote_no vote_abstain vote_topic voting voteset
	# Make sure this is a valid channel
	if { [ channel get $chan $chanflag ] } {
		if {$voting == "yes"} {
			if {$vote_yes == $vote_no && $nick == 1} {
				tie_breaker
				putlog "Vote has resulted in a tie: extending time"
				return 0
			}
			set voting no
			catch {
				killutimer $voteset(t1)
				killutimer $voteset(t2)
				killutimer $voteset(t3)
				killutimer $voteset(t4)
				killutimer $voteset(t5)
			}
			putlog "\002VoteBox\002:  Vote finished: $vote_topic Yes: $vote_yes  No: $vote_no"
			puthelp "PRIVMSG $voting_chan :\002VoteBox\002: Voting results for: \002$vote_topic\002"
			puthelp "PRIVMSG $voting_chan :\002VoteBox\002: Yeas: \002$vote_yes\002"
			puthelp "PRIVMSG $voting_chan :\002VoteBox\002: Nays: \002$vote_no\002"
			puthelp "PRIVMSG $voting_chan :\002VoteBox\002: Abstentions: \002$vote_abstain\002"
		}
	}
}

###------------------------ Display Current/Last Vote ------------------------###
proc vote_update {nick mask hand chan text} {
	global chanflag voting_chan vote_yes vote_no vote_abstain vote_topic voting voteset vote_timestart vote_time
	# Make sure this is a valid channel
	if { [ channel get $chan $chanflag ] } {
		if {[string match "yes" $voting] == 1 && [string match $chan $voting_chan] == 1} {
			puthelp "PRIVMSG $chan :\002VoteBox\002: Voting in session for: \002$vote_topic\002"
#			puthelp "PRIVMSG $chan :\002VoteBox\002: Yes: \002$vote_yes\002"
#			puthelp "PRIVMSG $chan :\002VoteBox\002: No: \002$vote_no\002"
			puthelp "PRIVMSG $chan :\002VoteBox\002: [duration [expr (([unixtime] - $vote_timestart) - $vote_time) * -1]] left to vote"
		} elseif {[string match "no" $voting] == 1 && [info exists vote_topic] == 1} {
			puthelp "PRIVMSG $chan :\002VoteBox\002: Last vote was for: $vote_topic"
			puthelp "PRIVMSG $chan :\002VoteBox\002: Final tally was: Yes: $vote_yes | No: $vote_no | Abstain: $vote_abstain"
		} else {
			puthelp "PRIVMSG $chan :\002VoteBox\002: No prior votes recorded for this channel"
		}
	}
}


###------------------------ Asking for help ----------------------###
proc vote_chanhelp {nick mask hand chan test} {
	global chanflag
	# Make sure this is a valid channel
	if { [ channel get $chan $chanflag ] } {
		vote_helplist $nick
		return 0
	}
}

###------------------------ Voting Stats ------------------------###
proc vote_statlist {nick} {
	global chanflag voting_chan vote_yes vote_no vote_abstain vote_topic voting botnick
	# Make sure this is a valid channel
#	if { [ channel get $chan $chanflag ] } {
		puthelp "PRIVMSG $nick :\002VoteBox\002: Current Voting Stats for: \002$vote_topic\002"
		puthelp "PRIVMSG $nick :\002VoteBox\002: Yes: \002$vote_yes\002"
		puthelp "PRIVMSG $nick :\002VoteBox\002: No:  \002$vote_no\002"
		puthelp "PRIVMSG $nick :\002VoteBox\002: Abstain:  \002$vote_abstain\002"
		puthelp "PRIVMSG $nick :Type '/msg $botnick vote comments' to view current voter comments"
#	}
}

###------------------------ Voting Comments ------------------------###
proc vote_commentlist {nick} {
	global chanflag voting_chan vote_yes vote_no vote_topic voting vote_comments
	if {![info exists vote_comments]} {
		puthelp "NOTICE $nick :\002VoteBox\002: No comments made."
		return 0
	}
	foreach comment [array names vote_comments] {
		puthelp "PRIVMSG $nick :\002\| $comment \|\002 $vote_comments($comment)"
	}
}

###------------------------ Voting Help ------------------------###
proc vote_helplist {nick} {
	global chanflag voting_chan vote_yes vote_no vote_topic voting botnick
	if {[string match "yes" $voting] == 1 } {
		#	Commands valid while poll is open
		puthelp "PRIVMSG $nick :\002VoteBox\002: \002Voting Commands \(For during a voting session\)\002:"
		puthelp "PRIVMSG $nick :\002VoteBox\002: Type: '/msg $botnick vote yes \[comment\]' for a 'yes' vote."
		puthelp "PRIVMSG $nick :\002VoteBox\002: Type: '/msg $botnick vote no \[comment\]' for a 'no' vote."
		puthelp "PRIVMSG $nick :\002VoteBox\002: Type: '/msg $botnick vote abstain \[comment\]' for an 'abstain' vote."
		puthelp "PRIVMSG $nick :\002VoteBox\002: Type: '/msg $botnick vote stats' for current tallied votes."
		puthelp "PRIVMSG $nick :\002VoteBox\002: Type: '/msg $botnick vote comments' to view current comments."
		puthelp "PRIVMSG $nick :\002VoteBox\002: Type: '.endvote' to end a voting session early."
		puthelp "PRIVMSG $nick :\002VoteBox\002: Type: '.vote' to display current vote in session."
		puthelp "PRIVMSG $nick :\002VoteBox\002: Type: '.time' to display voting time remaining."
#		puthelp "PRIVMSG $nick :\002VoteBox\002: Type: '!seniorvote' to limit voting to seniors only (+S users on bot)."
	} else {
		#	Commands valid while poll is closed
		puthelp "PRIVMSG $nick :\002VoteBox\002: \002Voting Commands \(For outside a voting session\)\002:"
		puthelp "PRIVMSG $nick :\002VoteBox\002: Type: '.startvote <timespan> <topic>' to begin a voting session."
		puthelp "PRIVMSG $nick :\002VoteBox\002: Timespans is set as follows:"
		puthelp "PRIVMSG $nick :\002VoteBox\002: XXm \= xxMinutes"
		puthelp "PRIVMSG $nick :\002VoteBox\002: XXh \= xxHours"
		puthelp "PRIVMSG $nick :\002VoteBox\002: Example: .startvote 24h Should we play a game? for a 24 hour vote."
		puthelp "PRIVMSG $nick :\002VoteBox\002: Example: .startvote 200m Should we play a game? for a 200 minute vote."
		puthelp "PRIVMSG $nick :\002VoteBox\002: !!!NOT VALID!!!: .startvote 24h 20m Should we play a game?."
		puthelp "PRIVMSG $nick :\002VoteBox\002: Type: '.vote' to display previous voting session's outcome."
	}
	#	Commands valid at all times
	puthelp "PRIVMSG $nick :\002VoteBox\002: Type: '.opvote' to limit voting to bot-ops only (+o or above on bot)."
	puthelp "PRIVMSG $nick :\002VoteBox\002: Type: '.voicevote' to limit voting to bot-voice users (+v or above on bot)."
	puthelp "PRIVMSG $nick :\002VoteBox\002: Type: '.anyvote' to allow anyone to vote."
}

###------------------------ Time Remaining Warning ------------------------###
proc tie_breaker {} {
	global chanflag voting_chan vote_topic botnick vote_timestart vote_time
	# Make sure this is a valid channel
	if { [ channel get $voting_chan $chanflag ] } {
		if {$vote_time > 7200} {
			set vote_time 7200
			set vote_timestart [unixtime]
			puthelp "PRIVMSG $voting_chan :\002VoteBox\002: Tie Detected! Extending voting time two hours. Type .endvote to end this vote early"
			puthelp "PRIVMSG $voting_chan :\002VoteBox\002: Vote open on: \002$vote_topic\002"
			puthelp "PRIVMSG $voting_chan :\002VoteBox\002: '/msg $botnick vote <yes/no> \[comments\]' or '/msg $botnick vote help' for more commands"
			puthelp "PRIVMSG $voting_chan :\002VoteBox\002: [duration $vote_time] left to vote"
			set voteset(t4) [utimer [expr $vote_time - 1200] vote_warning]
		} else {
			set vote_time 1800
			set vote_timestart [unixtime]
			puthelp "PRIVMSG $voting_chan :\002VoteBox\002: Tie Detected! Extending voting time thirty minutes. Type .endvote to end this vote early"
			puthelp "PRIVMSG $voting_chan :\002VoteBox\002: Vote open on: \002$vote_topic\002"
			puthelp "PRIVMSG $voting_chan :\002VoteBox\002: '/msg $botnick vote <yes/no> \[comments\]' or '/msg $botnick vote help' for more commands"
			puthelp "PRIVMSG $voting_chan :\002VoteBox\002: [duration $vote_time] left to vote"
			set voteset(t4) [utimer [expr $vote_time - 900] vote_warning]
		}
		set voteset(t5) [utimer $vote_time "vote_results 1 2 3 $voting_chan 5"]
	}
}

###------------------------ Time Remaining Warning ------------------------###
proc vote_warning {} {
	global chanflag voting_chan vote_topic botnick voting vote_timestart vote_time voted_people
	if {$voting == "yes"} {
		puthelp "PRIVMSG $voting_chan :\002VoteBox\002: Voting polls are still open on: \002$vote_topic\002"
		puthelp "PRIVMSG $voting_chan :\002VoteBox\002: '/msg $botnick vote <yes/no> \[comments\]' or '/msg $botnick vote help' for more commands"
		puthelp "PRIVMSG $voting_chan :\002VoteBox\002: [duration [expr (([unixtime] - $vote_timestart) - $vote_time) * -1]] left to vote"
	}
}

###------------------------ Time Remaining Onjoin Reminder ------------------------###
proc vote_reminder {nick mask hand chan} {
	global chanflag voting_chan vote_topic botnick voting vote_timestart vote_time voted_people
	# Make sure this is a valid channel
	if { [ channel get $chan $chanflag ] } {
		set mask [maskhost $mask]
		if {[string match $chan $voting_chan] == 1 && [info exists voted_people($mask)] == 0 && [string match "yes" $voting] == 1} {
			puthelp "NOTICE $nick :\002VoteBox\002: Vote open on: \002$vote_topic\002"
			puthelp "NOTICE $nick :\002VoteBox\002: '/msg $botnick vote <yes/no/abstain> \[comments\]' or '/msg $botnick vote help' for more assistance."
			puthelp "NOTICE $nick :\002VoteBox\002: [duration [expr (([unixtime] - $vote_timestart) - $vote_time) * -1]] left to vote"
		}
	}
}

###------------------------ Time Remaining Channel Trigger ------------------------###
proc vote_timer {nick mask hand chan text} {
	global chanflag voting_chan vote_topic botnick voting vote_timestart vote_time voted_people
	# Make sure this is a valid channel
	if { [ channel get $chan $chanflag ] } {
		if {$voting == "yes"} {
			puthelp "PRIVMSG $chan :\002VoteBox\002: [duration [expr (([unixtime] - $vote_timestart) - $vote_time) * -1]] left to vote."
		}
	}
}


###------------------------ Write Votes to Temp File ------------------------###
proc setvote {chan topic begintime endtime} { global chanflag peak
	set chan [string tolower $chan]
	set peak($chan) "$curnum $unixtime"
	set fid [open "vote.$chan.txt" "WRONLY CREAT"]
	puts $fid $chan
	puts $fid $topic
	puts $fid $begintime
	puts $fid $endtime
	puts $fid "Voting Comments:"
}

###------------------------ Write Comments to Temp File ------------------------###
proc setcomment {comment} { global chanflag peak
	set chan [string tolower $chan]
	set peak($chan) "$curnum $unixtime"
	set fid [open "vote.$chan.txt" "WRONLY CREAT"]
	puts $fid $curnum
	puts $fid $unixtime
	close $fid
}

###------------------------ Host Masking Process ------------------------###
proc getmask {nick chan} {
	set mask [string trimleft [maskhost [getchanhost $nick $chan]] *!]
	set mask *!*$mask
	return $mask
}

putlog "\002Vote Script\002 Loaded Succesfully"
