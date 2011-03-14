#Selective Flood Control
#(c) Copyright 2006 Daniel Milstein
#Version 0.1
#Ignores the user if they give too many commands to the bot

#To use, add the following line as the first line of the proc for commands whose usage you want limited:
#if {![checkUser $nick $chan]} {return}
#Where $nick is the nick of the person who give the command and $chan is the channel that they give the command on

#The user is allowed to send $floodMessages public messages to the bot within $floodTime _seconds_. If s/he exceeds that, the user will be banned from using commands that the above line of code has been added to for $banLength _minutes_
set floodTime 60
set floodMessages 10
set banLength 10

#Data structure for users:
#Users is an associative array
#Keys are {{a} {b}}
#If the user is set on ignore, a is the time when the user will be able to talk to the bot again; otherwise, a is 0
#b is the list of times that the user has given commands to the bot; it is cleaned of old entries when checkUser is called

proc initUser {host time} {
	#add the user to the array
	global users
	set users($host) [list 0 [list $time]]
	return
}

proc checkUser {nick chan} {
	#Get the user's host
	set host [getchanhost $nick $chan]

	#Return 1 if the user can give bot commands; otherwise, return 0
	global users banLength floodTime floodMessages
	set time [unixtime]

	#check if the array exists yet
	if {![array exists users]} {
		#the array doesn't exist; therefore, the user isn't in the array
		initUser $host $time
		return 1
	}

	#check if the user is in the array
	set seenNick 0
	foreach user [array names users] {
		if {$user == $host} {set seenNick 1; break}
	}
	if {$seenNick == 0} {
		#user is not in the array yet
		initUser $host $time
		return 1
	}

	#The user is in the array

	#Check if the user is banned

	if {[lindex $users($host) 0] != 0} {
		#User is banned; check if the ban has expired
		if {[lindex $users($host) 0] <= $time} {
			#Ban has expired; unset the ban, add $time to the record of the user giving bot commands, and have the bot listen
			array set users [list $host [list 0 [list $time]]]
			return 1
		}
		#The ban has not expired; ignore the user
		return 0
	}

	#	Sort through the times that the user has sent a message;
	#	If the message happend within the last $floodTime seconds,
	#	the time is put into messages. Also, put the latest time in messages
	set messages {}
	foreach m [lindex $users($host) 1] {
		if {[expr $time-$m] <= $floodTime} {
			lappend messages $m
		}
	}
	lappend messages $time
	array set users [list $host [list 0 $messages]]

	#Check to see if the size of messages has exceeded $floodMessages
	if {[llength $messages] > $floodMessages} {
		#The user is flooding the channel with bot commands; ban him/her!
		putchan $chan "$nick: I am tired of waiting on you. I'm going to ignore your public commands for $banLength minutes. In the future, please do not flood the channel with bot commands."
		array set users [list $host [list [expr $time+($banLength*60)] {}]]
		return 0
	}

	#All is well; update the user status and let the user have his/her bot fun
	return 1
}

putlog "Flood control in place."
