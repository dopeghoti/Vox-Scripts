# $Id: seenster1.0.tcl 2005/05/27 04:20:00 Seanster Exp $

###############################################################################
# seenster for eggdrop bots
# Copyright (C) 2005 Sean McLaughlin
#
# This program is covered by the GPL, please refer the to LICENCE file in the
# distribution.
###############################################################################

#./configure  --with-tcl=/usr/local/lib --with-tclinclude=/usr/local/include  -with-mysql-include=/usr/local/mysql/include/mysql/ --with-mysql-lib=/usr/local/mysql/lib/mysql/

# load the extension
# most people should get away with the package command if their server is setup right
# If your main bot's server has broken TCL, you may need the line below it
# Use only one!
#
package require mysqltcl
#load /usr/local/lib/mysqltcl-3.01/libmysqltcl3.01.so
#

# connect to database
#
set db_handle [mysqlconnect -host localhost -user faqbot -password password -db vox_seen]

# IMPORTANT!  Use this bot command to enable/disable individual channels
# .chanset #channel [+/-]seenster

# maximum number of seens to show in channel when searching before switching to /msg'ing the user
set seen_seenmax 1
# maximum number of seens to report
set seen_seenmaxmax 1

# url to site CHANGE ME (use blank if you're not using the PHP script)
set php_page ""
# set php_page "http://www.xxx.ca/seenster/"


###############################################################################
### bind commands CHANGE as needed
#bind pub "m|ov" !addquote quote_add
###############################################################################

bind pub "-|-" .seen seen_seen
#bind pub "-|-" .lastseen seen_seen
#bind pub "-|-" .checkquit seen_quit
bind pub "-|-" .left seen_quit
#bind pub "-|-" .lastspoke seen_spoke
bind pub "-|-" .spoke seen_spoke
bind pub "-|-" .said seen_spoke
#bind pub "-|-" .lasttopic seen_topic
#bind pub "-|-" .topic seen_topic
#bind pub "-|-" .lastactn seen_actn
bind pub "-|-" .actn seen_actn
#bind pub "-|-" .lastbong seen_bong
bind pub "-|-" .bong seen_bong
#bind pub "-|-" .seenversion seen_version
bind pub "-|-" .seenhelp seen_help

bind join "-|-" * irc_join 
bind part "-|-" * irc_part 
bind sign "-|-" * irc_sign 
bind splt "-|-" * irc_splt 
bind rejn "-|-" * irc_rejn 
bind kick "-|-" * irc_kick 
bind nick "-|-" * irc_nick 
bind topc "-|-" * irc_topc
bind ctcp - "ACTION" irc_actn  
bind pubm  "-|-" * irc_said
#bind away "-|-" * irc_away

# a user with this flag(s) can't use the script at all
set seen_noflags "Q|Q"

###############################################################################
### code starts here (no need to edit stuff below)
###############################################################################

set seen_version "20050527"

#add setting to channel
setudef flag seenster


###############################################################################
### user commands start here
###
################################################################################


################################################################################
# seen_seen
# !seen <nick> [max_history]
#   Find the last database entry for nick
#   The first 2 (seen_seenmax) are listed in the channel. The rest are /msg'd to
#   you up to 20 (seen_seenmaxmax).
#
#   Note this is a SQL search, so use % as the wildcard (instead of *)
#   The script automatically puts %s around your text when searching.
################################################################################
proc seen_seen { nick host handle channel text } { 
 
	global db_handle php_page seen_noflags seen_seenmax seen_seenmaxmax

	set output ""

	# check that seenster is enabled for the channel
	if {![channel get $channel seenster]} {
    	return 0
	}

# check if the user is denied seen rights
#  if [matchattr $handle $seen_noflags] { 
#    return 0 
#  }

  
	if {$text == ""} {
		puthelp "PRIVMSG $channel :Use: !seen <nick>"
		return 0
	}

	set where_clause "AND channel='$channel'"

#  if [regexp -- "--?all " $text matches skip1] 
#  {
#    set where_clause ""
#    regsub -- $matches $text "" text
#  }

#  if [regexp -- {--?c(hannel)?( |=)([^ ]+)} $text matches skip1 skip2 newchan] 
#  {
#    set where_clause "AND channel='[mysqlescape $newchan]'"
#    regsub -- $matches $text "" text
#  }

	set limit [mysqlescape $seen_seenmaxmax]
  
#  if [regexp -- {--?count( |=)([^ ]+)} $text matches skip1 count] 
#  {
#    set limit [mysqlescape $count]
#    regsub -- $matches $text "" text
#  }

#  if [regexp -- {-n( )?([^ ]+)} $text matches skip1 count] 
#  {
#    set limit [mysqlescape $count]
#    regsub -- $matches $text "" text
#  }

	set sql "SELECT * FROM vox_seen.seen WHERE nick LIKE '%[mysqlescape $text]%' $where_clause ORDER BY ts DESC LIMIT $limit"

	putloglev d * "seenster: executing $sql"

	if {[mysqlsel $db_handle $sql] > 0} {
		
		set count 0

		mysqlmap $db_handle {m_id m_nick m_host m_ts m_channel m_action m_text} {

			if {$count == $seen_seenmaxmax} {
        		break
			}
      
			if {$count == $seen_seenmax } {
        		puthelp "PRIVMSG $nick :Rest of matches for your search '$text' follow in private:"
      		}

#			set details $m_text
			
#			if {$details == ""} { 
#				set details "." 
#			}
			
#			[format_record $m_id $m_nick $m_host $m_ts $m_channel $m_action $m_text]
#			set output [format_record 10 sean hereathtere 9922343 #cutlass join reason]
#			set output "$m_id $m_nick $m_host $m_ts $m_channel $m_action $details"

			set output [format_record $m_id $m_nick $m_host $m_ts $m_channel $m_action $m_text]

			if {$count < $seen_seenmax} {
        		puthelp "PRIVMSG $channel :\[\002$nick\002\] $output"
      		} else {
        		puthelp "PRIVMSG $nick :\[\002$nick\002\] $output"
      		}

      		incr count
    	}

# with LIMIT set, there will never be any remaining records to count
# according to my tests anyway

##    set remaining [mysqlresult $db_handle rows?]
##    if {$remaining > 0}  {
##      regsub "#" $channel "" chan
##      if {$php_page != ""}  {
##        puthelp "PRIVMSG $channel :(Plus $remaining more matches: $php_page?filter=${text}&channel=${chan}&search=search)"
##      } else {
##        puthelp "PRIVMSG $channel :Plus $remaining other matches"
##      }
##    }  else  {}

		if {$count == 1} {
        	#puthelp "PRIVMSG $channel :(All of 1 match)"
    	} else {
        	puthelp "PRIVMSG $nick :(All of $count matches)"
    	}
  	} else {
    	puthelp "PRIVMSG $channel :No matches"
	}
}


################################################################################
# seen_quit
# !seen <nick> [max_history]
#   Find the last database entry for nick
#   The first 2 (seen_seenmax) are listed in the channel. The rest are /msg'd to
#   you up to 20 (seen_seenmaxmax).
#
#   Note this is a SQL search, so use % as the wildcard (instead of *)
#   The script automatically puts %s around your text when searching.
################################################################################
proc seen_quit { nick host handle channel text } { 
 
	global db_handle php_page seen_noflags seen_seenmax seen_seenmaxmax

	set output ""

	# check that seenster is enabled for the channel
	if {![channel get $channel seenster]} {
    	return 0
	}

# check if the user is denied seen rights
#  if [matchattr $handle $seen_noflags] { 
#    return 0 
#  }

	set qnick $text
  
	if {$text == ""} {
		set qnick $nick
	}

	set where_clause "AND channel='$channel' AND (action='part' OR action='quit' OR action='kick' OR action='splt') "

#  if [regexp -- "--?all " $text matches skip1] 
#  {
#    set where_clause ""
#    regsub -- $matches $text "" text
#  }

#  if [regexp -- {--?c(hannel)?( |=)([^ ]+)} $text matches skip1 skip2 newchan] 
#  {
#    set where_clause "AND channel='[mysqlescape $newchan]'"
#    regsub -- $matches $text "" text
#  }

	set limit [mysqlescape $seen_seenmaxmax]
  
#  if [regexp -- {--?count( |=)([^ ]+)} $text matches skip1 count] 
#  {
#    set limit [mysqlescape $count]
#    regsub -- $matches $text "" text
#  }

#  if [regexp -- {-n( )?([^ ]+)} $text matches skip1 count] 
#  {
#    set limit [mysqlescape $count]
#    regsub -- $matches $text "" text
#  }

	set sql "SELECT * FROM vox_seen.seen WHERE nick LIKE '%[mysqlescape $qnick]%' $where_clause ORDER BY ID DESC LIMIT $limit"

	putloglev d * "seenster: executing $sql"

	if {[mysqlsel $db_handle $sql] > 0} {
		
		set count 0

		mysqlmap $db_handle {m_id m_nick m_host m_ts m_channel m_action m_text} {

			if {$count == $seen_seenmaxmax} {
        		break
			}
      
			if {$count == $seen_seenmax } {
        		puthelp "PRIVMSG $nick :Rest of matches for your search '$text' follow in private:"
      		}

#			set details $m_text
			
#			if {$details == ""} { 
#				set details "." 
#			}
			
#			[format_record $m_id $m_nick $m_host $m_ts $m_channel $m_action $m_text]
#			set output [format_record 10 sean hereathtere 9922343 #cutlass join reason]
#			set output "$m_id $m_nick $m_host $m_ts $m_channel $m_action $details"

			set output [format_record $m_id $m_nick $m_host $m_ts $m_channel $m_action $m_text]

			if {$count < $seen_seenmax} {
        		puthelp "PRIVMSG $channel :\[\002$nick\002\] $output"
      		} else {
        		puthelp "PRIVMSG $nick :\[\002$nick\002\] $output"
      		}

      		incr count
    	}

# with LIMIT set, there will never be any remaining records to count
# according to my tests anyway

##    set remaining [mysqlresult $db_handle rows?]
##    if {$remaining > 0}  {
##      regsub "#" $channel "" chan
##      if {$php_page != ""}  {
##        puthelp "PRIVMSG $channel :(Plus $remaining more matches: $php_page?filter=${text}&channel=${chan}&search=search)"
##      } else {
##        puthelp "PRIVMSG $channel :Plus $remaining other matches"
##      }
##    }  else  {}

		if {$count == 1} {
        	#puthelp "PRIVMSG $channel :(All of 1 match)"
    	} else {
        	puthelp "PRIVMSG $nick :(All of $count matches)"
    	}
  	} else {
    	puthelp "PRIVMSG $channel :No matches"
	}
}


################################################################################
# seen_spoke
# !seen <nick> [max_history]
#   Find the last database entry for nick
#   The first 2 (seen_seenmax) are listed in the channel. The rest are /msg'd to
#   you up to 20 (seen_seenmaxmax).
#
#   Note this is a SQL search, so use % as the wildcard (instead of *)
#   The script automatically puts %s around your text when searching.
################################################################################
proc seen_spoke { nick host handle channel text } { 
 
	global db_handle php_page seen_noflags seen_seenmax seen_seenmaxmax

	set output ""

	# check that seenster is enabled for the channel
	if {![channel get $channel seenster]} {
    	return 0
	}

	set qnick $text
  
	if {$text == ""} {
		set qnick $nick
	}

	set where_clause "AND channel='$channel' AND (action='said' OR action='actn' OR action='topc') "

	set limit [mysqlescape $seen_seenmaxmax]
  
	set sql "SELECT * FROM vox_seen.seen WHERE nick LIKE '%[mysqlescape $qnick]%' $where_clause ORDER BY ID DESC LIMIT $limit"

	putloglev d * "seenster: executing $sql"

	if {[mysqlsel $db_handle $sql] > 0} {
		
		set count 0

		mysqlmap $db_handle {m_id m_nick m_host m_ts m_channel m_action m_text} {

			if {$count == $seen_seenmaxmax} {
        		break
			}
      
			if {$count == $seen_seenmax } {
        		puthelp "PRIVMSG $nick :Rest of matches for your search '$text' follow in private:"
      		}

			set output [format_record $m_id $m_nick $m_host $m_ts $m_channel $m_action $m_text]

			if {$count < $seen_seenmax} {
        		puthelp "PRIVMSG $channel :\[\002$nick\002\] $output"
      		} else {
        		puthelp "PRIVMSG $nick :\[\002$nick\002\] $output"
      		}

      		incr count
    	}

		if {$count == 1} {
        	#puthelp "PRIVMSG $channel :(All of 1 match)"
    	} else {
        	puthelp "PRIVMSG $nick :(All of $count matches)"
    	}
  	} else {
    	puthelp "PRIVMSG $channel :No matches"
	}
}


################################################################################
# seen_topic
# !seen <nick> [max_history]
#   Find the last database entry for nick
#   The first 2 (seen_seenmax) are listed in the channel. The rest are /msg'd to
#   you up to 20 (seen_seenmaxmax).
#
#   Note this is a SQL search, so use % as the wildcard (instead of *)
#   The script automatically puts %s around your text when searching.
################################################################################
proc seen_topic { nick host handle channel text } { 
 
	global db_handle php_page seen_noflags seen_seenmax seen_seenmaxmax

	set output ""

	# check that seenster is enabled for the channel
	if {![channel get $channel seenster]} {
    	return 0
	}

	set qnick $text
  
	if {$text == ""} {
		set where_clause "WHERE "
	} else {
		set where_clause "WHERE nick LIKE '%[mysqlescape $qnick]%' AND "
	}

	set where_clause [concat $where_clause "channel='$channel' AND action='topc' "]

	set limit [mysqlescape $seen_seenmaxmax]
  
	set sql "SELECT * FROM vox_seen.seen $where_clause ORDER BY ID DESC LIMIT $limit"

	putloglev d * "seenster: executing $sql"

	if {[mysqlsel $db_handle $sql] > 0} {
		
		set count 0

		mysqlmap $db_handle {m_id m_nick m_host m_ts m_channel m_action m_text} {

			if {$count == $seen_seenmaxmax} {
        		break
			}
      
			if {$count == $seen_seenmax } {
        		puthelp "PRIVMSG $nick :Rest of matches for your search '$text' follow in private:"
      		}

			set output [format_record $m_id $m_nick $m_host $m_ts $m_channel $m_action $m_text]

			if {$count < $seen_seenmax} {
        		puthelp "PRIVMSG $channel :\[\002$nick\002\] $output"
      		} else {
        		puthelp "PRIVMSG $nick :\[\002$nick\002\] $output"
      		}

      		incr count
    	}

		if {$count == 1} {
        	#puthelp "PRIVMSG $channel :(All of 1 match)"
    	} else {
        	puthelp "PRIVMSG $nick :(All of $count matches)"
    	}
  	} else {
    	puthelp "PRIVMSG $channel :No matches"
	}
}


################################################################################
# seen_actn
# !seen <nick> [max_history]
#   Find the last database entry for nick
#   The first 2 (seen_seenmax) are listed in the channel. The rest are /msg'd to
#   you up to 20 (seen_seenmaxmax).
#
#   Note this is a SQL search, so use % as the wildcard (instead of *)
#   The script automatically puts %s around your text when searching.
################################################################################
proc seen_actn { nick host handle channel text } { 
 
	global db_handle php_page seen_noflags seen_seenmax seen_seenmaxmax

	set output ""

	# check that seenster is enabled for the channel
	if {![channel get $channel seenster]} {
    	return 0
	}

	if {$text == ""} {
		set where_clause "WHERE "
	} else {
		set where_clause "WHERE text LIKE '%[mysqlescape $text]%' AND "
	}

	set where_clause [concat $where_clause "channel='$channel' AND action='actn' "]

	set limit [mysqlescape $seen_seenmaxmax]
  
	set sql "SELECT * FROM vox_seen.seen $where_clause ORDER BY ID DESC LIMIT $limit"

	putloglev d * "seenster: executing $sql"

	if {[mysqlsel $db_handle $sql] > 0} {
		
		set count 0

		mysqlmap $db_handle {m_id m_nick m_host m_ts m_channel m_action m_text} {

			if {$count == $seen_seenmaxmax} {
        		break
			}
      
			if {$count == $seen_seenmax } {
        		puthelp "PRIVMSG $nick :Rest of matches for your search '$text' follow in private:"
      		}

			set output [format_record $m_id $m_nick $m_host $m_ts $m_channel $m_action $m_text]

			if {$count < $seen_seenmax} {
        		puthelp "PRIVMSG $channel :\[\002$nick\002\] $output"
      		} else {
        		puthelp "PRIVMSG $nick :\[\002$nick\002\] $output"
      		}

      		incr count
    	}

		if {$count == 1} {
        	#puthelp "PRIVMSG $channel :(All of 1 match)"
    	} else {
        	puthelp "PRIVMSG $nick :(All of $count matches)"
    	}
  	} else {
    	puthelp "PRIVMSG $channel :No matches"
	}
}


################################################################################
# seen_bong
# !seen <nick> [max_history]
#   Find the last database entry for nick
#   The first 2 (seen_seenmax) are listed in the channel. The rest are /msg'd to
#   you up to 20 (seen_seenmaxmax).
#
#   Note this is a SQL search, so use % as the wildcard (instead of *)
#   The script automatically puts %s around your text when searching.
################################################################################
proc seen_bong { nick host handle channel text } { 
 
	global db_handle php_page seen_noflags seen_seenmax seen_seenmaxmax

	set output ""

	# check that seenster is enabled for the channel
	if {![channel get $channel seenster]} {
    	return 0
	}

	set qnick $text
  
	if {$text == ""} {
		set where_clause "WHERE "
	} else {
		set where_clause "WHERE nick LIKE '%[mysqlescape $qnick]%' AND "
	}

	set where_clause [concat $where_clause "channel='$channel' AND action='actn' AND text like '%bong%' "]

	set limit [mysqlescape $seen_seenmaxmax]
  
	set sql "SELECT * FROM vox_seen.seen $where_clause ORDER BY ID DESC LIMIT $limit"

	putloglev d * "seenster: executing $sql"

	if {[mysqlsel $db_handle $sql] > 0} {
		
		set count 0

		mysqlmap $db_handle {m_id m_nick m_host m_ts m_channel m_action m_text} {

			if {$count == $seen_seenmaxmax} {
        		break
			}
      
			if {$count == $seen_seenmax } {
        		puthelp "PRIVMSG $nick :Rest of matches for your search '$text' follow in private:"
      		}

			set output [format_record $m_id $m_nick $m_host $m_ts $m_channel $m_action $m_text]

			if {$count < $seen_seenmax} {
        		puthelp "PRIVMSG $channel :\[\002$nick\002\] $output"
      		} else {
        		puthelp "PRIVMSG $nick :\[\002$nick\002\] $output"
      		}

      		incr count
    	}

		if {$count == 1} {
        	#puthelp "PRIVMSG $channel :(All of 1 match)"
    	} else {
        	puthelp "PRIVMSG $nick :(All of $count matches)"
    	}
  	} else {
    	puthelp "PRIVMSG $channel :No matches"
	}
}


################################################################################
# seen_version
# !seenversion
#   Gives the version of the script
################################################################################
proc seen_version { nick host handle channel text } {
  global seen_version seen_noflags

 # if [matchattr $handle $seen_noflags] { return 0 }

  puthelp "PRIVMSG $channel :This is seenster version $seen_version by Seanster http://www.Seanster.com/seenster "
  return 0
}


################################################################################
# seen_help
# !seenhelp
#   Handle help requests
################################################################################
 proc seen_help { nick host handle channel text } {
  global seen_noflags

#  if [matchattr $handle $seen_noflags] { return 0 }

  puthelp "PRIVMSG $nick :Commands for the seenster script:"
  puthelp "PRIVMSG $nick :  !seen  <nick> - looks up the last record for a nickname"
  puthelp "PRIVMSG $nick :  !quit  {nick} - fetches the last part/quit/split, nick optional"
  puthelp "PRIVMSG $nick :  !spoke {nick} - fetches the last said/actn/topc, nick optional"
  puthelp "PRIVMSG $nick :  !topic {nick} - fetches the last topc, nick optional"
  puthelp "PRIVMSG $nick :  !actn  {nick} - fetches the last actn, nick optional"
  puthelp "PRIVMSG $nick :  !seenversion - version information"
  puthelp "PRIVMSG $nick :  !seenhelp    - this help text"
  puthelp "PRIVMSG $nick :  (End of help)"
  return 0
}


################################################################################
### irc notices start here
################################################################################

proc irc_join {nick uhost hand chan} {seen_add $nick [list $uhost] [unixtime] $chan "join" ""}

proc irc_part {nick uhost hand chan reason} {seen_add $nick [list $uhost] [unixtime] $chan "part" "[split $reason]"}

proc irc_sign {nick uhost hand chan reason} {seen_add $nick [list $uhost] [unixtime] $chan "quit" "[split $reason]"}

proc irc_splt {nick uhost hand chan} {seen_add $nick [list $uhost] [unixtime] $chan "splt" ""}

proc irc_rejn {nick uhost hand chan} {seen_add $nick [list $uhost] [unixtime] $chan "rejn" ""}

proc irc_kick {nick uhost hand chan knick reason} {seen_add $knick [getchanhost $knick $chan] [unixtime] $chan "kick" "[list $nick] [list $reason]"}

proc irc_nick {nick uhost hand chan newnick} {set time [unixtime] ; seen_add $nick [list $uhost] [expr $time -1] $chan "nick" "[list $newnick]" ; seen_add $newnick [list $uhost] $time $chan "rnck" "[list $nick]"}

proc irc_topc {nick uhost hand chan topic} {seen_add $nick [list $uhost] [unixtime] $chan "topc" $topic}

proc irc_actn { nick uhost hand dest keyword text } {
	if {[string index $dest 0] != "#"} { 
		return 0 
	} 

	seen_add $nick [list $uhost] [unixtime] $dest "actn" [string trim $text {}]
}

proc irc_said {nick uhost hand chan text} {seen_update $nick [list $uhost] [unixtime] $chan "said" $text}

#proc irc_away {bot idx msg} {seen_update $hand [join [string trim [lindex $old 1] ()]] [unixtime] $bot away [bs_filt [join $msg]]}


################################################################################
# seen_update
#   {id nick host ts channel action text } 
################################################################################
proc seen_update { nick host ts channel action text } {
  global db_handle seen_noflags

  # check that seenster is enabled for the channel
  if {![channel get $channel seenster]} {
    return 0
  }

  set sql "UPDATE vox_seen.seen SET "
  append sql "host='$host', "
  append sql "ts='$ts', "
  set text [mysqlescape $text]
  append sql "text='$text' "
  append sql "WHERE nick='$nick' AND channel='$channel' AND action='said' ORDER BY ID DESC LIMIT 1"
  
  putloglev d * "seenster: executing $sql"

  set result [mysqlexec $db_handle $sql]
  if {$result < 1} {
	# no rows affected, insert instead
	seen_add $nick $host $ts $channel $action $text
  } else {
    #puthelp "PRIVMSG $channel :seen said updated"
  }
}

################################################################################
# seen_add
#   {id nick host ts channel action text } 
################################################################################
proc seen_add { nick host ts channel action text } {
  global db_handle seen_noflags

  # check that seenster is enabled for the channel
  if {![channel get $channel seenster]} {
    return 0
  }

  # check if the user is denied seen rights
#  if [matchattr $handle $seen_noflags] { 
#    return 0 
#  }

  set sql "INSERT INTO vox_seen.seen VALUES(null, "
  append sql "'$nick', "
  append sql "'$host', "
  append sql "'$ts', "
  append sql "'$channel', "
  append sql "'$action', "
  set text [mysqlescape $text]
  append sql "'$text')"
  
  putloglev d * "seenster: executing $sql"

  set result [mysqlexec $db_handle $sql]
  if {$result != 1} {
    putloglev d *  "seenster: An error occurred with the sql : $result"
  } else {
    #set id [mysqlinsertid $db_handle]
    #puthelp "PRIVMSG $channel :seen added"
  }
}

################################################################################
# format_record
################################################################################
proc format_record { m_id m_nick m_host m_ts m_channel m_action m_text } {

	set output ""

	switch -- $m_action {
    
    	part { 
        	#set reason $m_text
        	#if {$reason == ""} {set reason "."} {set reason " stating \"$reason\"."}
        	set output [concat $m_nick ($m_host) was last seen parting $m_channel [stamp_to_string $m_ts] ago ($m_text)] 
	  		if {[validchan $m_channel]} {
	    		if {[onchan $m_nick $m_channel]} {
	      			set output [concat $output  - $m_nick is currently on the channel]
	    		}
	  		}
    	}
    
    	quit { 
        	set output [concat $m_nick ($m_host) was last seen quitting from $m_channel [stamp_to_string $m_ts] ago stating ($m_text)] 
	  		if {[validchan $m_channel]} {
	    		if {[onchan $m_nick $m_channel]} {
	      			set output [concat $output  - $m_nick is currently on the channel]
	    		}
	  		}
    	}
	
    	kick { 
        	set output [concat $m_nick ($m_host) was last seen being kicked from $m_channel by [lindex $m_text 0] [stamp_to_string $m_ts] ago with the reason ([join [lrange $m_text 1 end]])] 
	  		if {[validchan $m_channel]} {
	    		if {[onchan $m_nick $m_channel]} {
	      			set output [concat $output  - $m_nick is currently on the channel]
	    		}
	  		}
    	}
	
		rnck {
	  		set output [concat $m_nick ($m_host) was last seen changing nicks from $m_text on $m_channel [stamp_to_string $m_ts] ago] 
	  		if {[validchan $m_channel]} {
	    		if {[onchan $m_nick $m_channel]} {
	      			set output [concat $output  - $m_nick is still there]
	    		} {
	      			set output [concat $output  - I don't see $m_nick now, though]
	    		}
	  		}
		}
    
		nick { 
        	set output [concat $m_nick ($m_host) was last seen changing nicks to $m_text on $m_channel [stamp_to_string $m_ts] ago] 
	  		if {[validchan $m_channel]} {
	    		if {[onchan $m_text $m_channel]} {
	      			set output [concat $output  - $m_text is still there]
	    		} {
	      			set output [concat $output  - I don't see $m_text now, though]
	    		}
	  		}
    	}
	
    	splt { 
        	set output [concat $m_nick ($m_host) was last seen parting $m_channel due to a split [stamp_to_string $m_ts] ago ($m_text)] 
	  		if {[validchan $m_channel]} {
	    		if {[onchan $m_nick $m_channel]} {
	      			set output [concat $output  - $m_nick is currently on the channel]
	    		}
	  		}
    	}
	
    	rejn { 	  
        	set output [concat $m_nick ($m_host) was last seen rejoining $m_channel from a split [stamp_to_string $m_ts] ago ($m_text)] 
            if {[validchan $m_channel]} {
                if {[onchan $m_nick $m_channel]} {
                    #set output [concat $output  - $m_nick is still there]
                } {
                    set output [concat $output  - I don't see $m_nick now, though]
                }
            }
    	}
	
    	join { 
			set output [concat $m_nick ($m_host) was last seen joining $m_channel [stamp_to_string $m_ts] ago]
            if {[validchan $m_channel]} {
                if {[onchan $m_nick $m_channel]} {       
                    #set output [concat $output  - $m_nick is still there]      
                } {      
                    set output [concat $output  - I don't see $m_nick now, though]        
                }        
            }        
		}
		
		away {
	  		set reason $m_text]
        	if {$reason == ""} {
	    		set output [concat $m_nick ($m_host) was last seen returning to life on $m_channel [stamp_to_string $m_ts] ago]
	            if {[validchan $m_channel]} {
    	            if {[onchan $m_nick $m_channel]} {
        	            #set output [concat $output  - $m_nick is still there]
	                } {      
	                    set output [concat $output  - I don't see $m_nick now, though]        
    	            }        
				}
	  		} {
	    		set output [concat $m_nick ($m_host) was last seen being marked as away ($reason) on $m_channel [stamp_to_string $m_ts] ago]
            	if {[validchan $m_channel]} {
                	if {[onchan $m_nick $m_channel]} {
	                    #set output [concat $output  - $m_nick is still there]
	                } {      
	                    set output [concat $output  - I don't see $m_nick now, though]        
    	            }        
				}
	  		}
		}

		back {
	    	set output [concat $m_nick ($m_host) was last seen returning to life on $m_channel [stamp_to_string $m_ts] ago stating ($m_text)]
            if {[validchan $m_channel]} {
                if {[onchan $m_nick $m_channel]} {
                    #set output [concat $output  - $m_nick is still there]
                } {      
                    set output [concat $output  - I don't see $m_nick now, though]        
                }        
			}
		}

		topc {
	    	set output [concat $m_nick ($m_host) was seen on $m_channel [stamp_to_string $m_ts] ago changing the topic to ($m_text)]
            if {[validchan $m_channel]} {
                if {[onchan $m_nick $m_channel]} {
                    #set output [concat $output  - $m_nick is still there]
                } {      
                    set output [concat $output  - I don't see $m_nick now, though]        
                }        
			}
		}

		actn {
			if { [string first bong [string tolower $m_text]] >= 0 } {
	    		set output [concat $m_nick ($m_host) was seen taking a bong hit on $m_channel [stamp_to_string $m_ts] ago saying ($m_nick $m_text)]    
    		} else { 
	    		set output [concat $m_nick ($m_host) was seen acting out on $m_channel [stamp_to_string $m_ts] ago saying ($m_nick $m_text)]
			}
            if {[validchan $m_channel]} {
                if {[onchan $m_nick $m_channel]} {
                    #set output [concat $output  - $m_nick is still there]
                } {      
                    set output [concat $output  - I don't see $m_nick now, though]        
                }        
			}
		}

		said {
	    	set output [concat $m_nick ($m_host) was seen on $m_channel [stamp_to_string $m_ts] ago stating ($m_text)]
            if {[validchan $m_channel]} {
                if {[onchan $m_nick $m_channel]} {
                    #set output [concat $output  - $m_nick is still there]
                } {      
                    set output [concat $output  - I don't see $m_nick now, though]        
                }        
			}
		}
	}
	return $output
}

################################################################################
#	This is equiv to mIRC's $duration() function
################################################################################
proc stamp_to_string { stamp } {

  	set years 0 ; set days 0 ; set hours 0 ; set mins 0
 
	set time [expr [unixtime] - $stamp]

  
	if {$time < 60} {return "only $time seconds"}
        
    if {$time >= 31536000} {set years [expr int([expr $time/31536000])] ; set time [expr $time - [expr 31536000*$years]]}
          
    if {$time >= 86400} {set days [expr int([expr $time/86400])] ; set time [expr $time - [expr 86400*$days]]}
            
    if {$time >= 3600} {set hours [expr int([expr $time/3600])] ; set time [expr $time - [expr 3600*$hours]]}
              
    if {$time >= 60} {set mins [expr int([expr $time/60])]}
                
    if {$years == 0} {set output ""} elseif {$years == 1} {set output "1 year,"} {set output "$years years,"}
    
    if {$days == 1} {lappend output "1 day,"} elseif {$days > 1} {lappend output "$days days,"}
                    
    if {$hours == 1} {lappend output "1 hour,"} elseif {$hours > 1} {lappend output "$hours hours,"}
                     
    if {$mins == 1} {lappend output "1 minute"} elseif {$mins > 1} {lappend output "$mins minutes"}
    
    return [string trimright [join $output] ", "]
}
                        
putlog "seenster $seen_version loaded"
