# YouTube (Eggdrop/Tcl), Version 1.4
#
# (-) speechles(Efnet - #roms-isos), 31. Jul. 2012
#
# Example:
# <nick> anybody seen this vid >> www.youtu.be/sMHui1TGDxA
# <bot> Pineapple Express (Rated) | A new comedy from the creative genius of Judd Apatow (40 Year Old Virgin, Knocked Up,
#       Talladega Nights) follows a pair of druggie losers as they reach the top of the hit-list when one witnesses a mob
#       murder and drags his buddy into a crazy flight from mobsters bent on silencing both of them permanently. The film
#       stars new sensation Seth Rogen (Knocked Up, Superbad, 40 Year Old Virgin) and James Franco
# <bot> (Spider-Man 1-3) and it co-stars Rosie Perez (Do The Right Thing) and Gary Cole (The Brady Bunch Movie). Movie is
#       directed by David Gordon Green. MPAA Rating: R © 2008 Columbia Pictures Industries, Inc. and Beverly Blvd LLC. All
#       Rights Reserved. ( by Crackle | 1:52:19 | 4.87 rating | 2,053 comments | 670,488 views | 4w 3d 21h 6m 11s ago )
#
# >> original script credits below <<
# (c) creative (QuakeNet - #computerbase), 15. Feb. 2012
#
# This program is free software: you can redistribute it and / or modify it under the
# terms of the GNU General Public License, see http://www.gnu.org/licenses/gpl.html.
#
# Example:
# <bo2000> like her new video https://www.youtu.be/kfVsfOSbJY0
# <eggbert> [Y] Rebecca Black - Friday - Official Music Video, 17.09.2011 (O 1.8)

# For those without partyline access:
# !youtube (on|off) enables or disables script for active channel (flags "mno" only)

# THE ONE CONFIG SETTING LIES BELOW..
# What length should we cut descriptions to?
# a setting of 0 will leave them complete.
set youtubeCut 250

setudef flag youtube

bind pubm - *youtu.be/* YouTube
bind pubm - *youtube.com/watch*v=* YouTube
bind pubm - *youtube.ie/watch*v=* YouTube
bind pubm - *youtube.de/watch*v=* YouTube
bind pubm - *youtube.co.uk/watch*v=* YouTube
bind pubm - *youtube.ca/watch*v=* YouTube
bind pub mno|mno .yt YouTube-Settings

# main procedure
proc YouTube {nick host hand chan text} {
	if {[channel get $chan youtube]} {
		set y_api "http://gdata.youtube.com/feeds/api/videos/"
		if {[catch {package require http 2.5}]} {
			putlog "YouTube: package http 2.5 or above required"
		} else {
			if {[regexp -nocase {(^|[ ]{1})(https{0,1}:\/\/(www\.){0,1}|www\.)(youtu\.be\/|youtube\.com\/watch[^ ]{1,}v=)([A-Za-z0-9_-]{11})} $text - - - - - y_vid]} {
				if {[catch {set y_con [::http::geturl $y_api$y_vid -headers [list {GData-Version} {2}] -timeout 5000]}]} {
					putlog "YouTube: connection error (e. g. host not found / reachable)"
				} elseif {[::http::status $y_con] == "ok"} {
					set y_data [::http::data $y_con]
					catch {::http::cleanup $y_con}
				} else {
					putlog "YouTube: connection error (e. g. time out / no data received)"
					catch {::http::cleanup $y_con}
				}

			}

		}

	}
	if {[info exists y_data]} {
		if {![regexp -- {<title.*?>(.*?)</title>} $y_data -> n]} {
			if {![regexp -- {<media:title type='plain'>(.*?)</media:title>} $y_data -> n]} {
				regexp -- {<internalReason>(.*?)</internalReason>} $y_data -> reply
				youtubeMsg privmsg $chan $reply
				return
			}
		}
		if {![regexp -- {<media:description.*?>(.*?)</media:description>} $y_data -> de]} { set de "" } { set de "| [string map [list "\r" " " "\n" " " "\v" " " "\a" " "] $de] " }
		if {[string length $de] && $::youtubeCut > 0} { set de "[string range $de 0 $::youtubeCut]..." }
		if {[string equal -nocase "| $n " $de]} { set de "" }
		if {![regexp -- {<author><name>(.*?)</name>} $y_data -> a]} { set a "???" }
		if {![regexp -- {countHint='(.*?)'} $y_data -> c]} { set c "???" }
		if {![regexp -- {duration='(.*?)'} $y_data -> d]} { set d "0" }
		if {![regexp -- {viewCount='(.*?)'} $y_data -> v]} { set v "???" }
		if {![regexp -- {average='(.*?)'} $y_data -> r]} { set r "???" } { set r [format "%.2f" $r] }
		foreach {z -} [split [duration $d]] {
			if {[set len [string length $z]] != 0 && $len < 2 } { append rd "0$z:" } { append rd "$z:" }
		}
		if {[regexp -all {\:} $rd] < 2} {
			set rd "00:[string trimleft [string trimright $rd :] 0]"
		} else {
			set rd [string trimleft [string trimright $rd :] 0]
		}
		if {![regexp -- {<published>(.*?)</published>} $y_data -> p]} {
			set p "???"
		} { 
			set ago "[string map {" years " "y " " year" "y " " weeks " "w " " week " "w " " days " "d " " day " "d " " hours " "h " " hour " "h " " minutes " "m " " minute " "m " " seconds" "s " " second" "s "} [duration [expr {[clock seconds] - [clock scan [string map [list "T" " "] [lindex [split $p .] 0]] -gmt 1]}]]] ago"
		}
		#youtubeMsg privmsg $chan "[youtubeMap $n] [youtubeMap ${de}]( by $a | $rd | $r rating | [youtubeCommify $c] comments | [youtubeCommify $v] views | $ago )"
		youtubeMsg privmsg $chan "\"[youtubeMap $n]\" ( by $a )"
	}
}

# add commas to numbers
proc youtubeCommify number {regsub -all {\d(?=(\d{3})+($|\.))} $number {\0,}}

proc youtubeMsg {type dest data} {
   set len [expr {500-[string len ":$::botname $type $dest :\r\n"]}]
   foreach line [youtubeWordwrap $data $len] {
      putserv "$type $dest :$line"
   }
}

# wrap long lines cleanly
proc youtubeWordwrap {data len} {
   set out {}
   foreach line [split [string trim $data] \n] {
      set curr {}
      set i 0
      foreach word [split [string trim $line]] {
         if {[incr i [string len $word]]>$len} {
            lappend out [join $curr]
            set curr [list $word]
            set i [string len $word]
         } {
            lappend curr $word
         }
         incr i
      }
      if {[llength $curr]} {
         lappend out [join $curr]
      }
   }
   set out
}

# map special characters
proc youtubeMap {data} {
	set escapes {
		&nbsp; \xa0 &iexcl; \xa1 &cent; \xa2 &pound; \xa3 &curren; \xa4
		&yen; \xa5 &brvbar; \xa6 &sect; \xa7 &uml; \xa8 &copy; \xa9
		&ordf; \xaa &laquo; \xab &not; \xac &shy; \xad &reg; \xae
		&macr; \xaf &deg; \xb0 &plusmn; \xb1 &sup2; \xb2 &sup3; \xb3
		&acute; \xb4 &micro; \xb5 &para; \xb6 &middot; \xb7 &cedil; \xb8
		&sup1; \xb9 &ordm; \xba &raquo; \xbb &frac14; \xbc &frac12; \xbd
		&frac34; \xbe &iquest; \xbf &Agrave; \xc0 &Aacute; \xc1 &Acirc; \xc2
		&Atilde; \xc3 &Auml; \xc4 &Aring; \xc5 &AElig; \xc6 &Ccedil; \xc7
		&Egrave; \xc8 &Eacute; \xc9 &Ecirc; \xca &Euml; \xcb &Igrave; \xcc
		&Iacute; \xcd &Icirc; \xce &Iuml; \xcf &ETH; \xd0 &Ntilde; \xd1
		&Ograve; \xd2 &Oacute; \xd3 &Ocirc; \xd4 &Otilde; \xd5 &Ouml; \xd6
		&times; \xd7 &Oslash; \xd8 &Ugrave; \xd9 &Uacute; \xda &Ucirc; \xdb
		&Uuml; \xdc &Yacute; \xdd &THORN; \xde &szlig; \xdf &agrave; \xe0
		&aacute; \xe1 &acirc; \xe2 &atilde; \xe3 &auml; \xe4 &aring; \xe5
		&aelig; \xe6 &ccedil; \xe7 &egrave; \xe8 &eacute; \xe9 &ecirc; \xea
		&euml; \xeb &igrave; \xec &iacute; \xed &icirc; \xee &iuml; \xef
		&eth; \xf0 &ntilde; \xf1 &ograve; \xf2 &oacute; \xf3 &ocirc; \xf4
		&otilde; \xf5 &ouml; \xf6 &divide; \xf7 &oslash; \xf8 &ugrave; \xf9
		&uacute; \xfa &ucirc; \xfb &uuml; \xfc &yacute; \xfd &thorn; \xfe
		&yuml; \xff &fnof; \u192 &Alpha; \u391 &Beta; \u392 &Gamma; \u393 &Delta; \u394
		&Epsilon; \u395 &Zeta; \u396 &Eta; \u397 &Theta; \u398 &Iota; \u399
		&Kappa; \u39A &Lambda; \u39B &Mu; \u39C &Nu; \u39D &Xi; \u39E
		&Omicron; \u39F &Pi; \u3A0 &Rho; \u3A1 &Sigma; \u3A3 &Tau; \u3A4
		&Upsilon; \u3A5 &Phi; \u3A6 &Chi; \u3A7 &Psi; \u3A8 &Omega; \u3A9
		&alpha; \u3B1 &beta; \u3B2 &gamma; \u3B3 &delta; \u3B4 &epsilon; \u3B5
		&zeta; \u3B6 &eta; \u3B7 &theta; \u3B8 &iota; \u3B9 &kappa; \u3BA
		&lambda; \u3BB &mu; \u3BC &nu; \u3BD &xi; \u3BE &omicron; \u3BF
		&pi; \u3C0 &rho; \u3C1 &sigmaf; \u3C2 &sigma; \u3C3 &tau; \u3C4
		&upsilon; \u3C5 &phi; \u3C6 &chi; \u3C7 &psi; \u3C8 &omega; \u3C9
		&thetasym; \u3D1 &upsih; \u3D2 &piv; \u3D6 &bull; \u2022
		&hellip; \u2026 &prime; \u2032 &Prime; \u2033 &oline; \u203E
		&frasl; \u2044 &weierp; \u2118 &image; \u2111 &real; \u211C
		&trade; \u2122 &alefsym; \u2135 &larr; \u2190 &uarr; \u2191
		&rarr; \u2192 &darr; \u2193 &harr; \u2194 &crarr; \u21B5
		&lArr; \u21D0 &uArr; \u21D1 &rArr; \u21D2 &dArr; \u21D3 &hArr; \u21D4
		&forall; \u2200 &part; \u2202 &exist; \u2203 &empty; \u2205
		&nabla; \u2207 &isin; \u2208 &notin; \u2209 &ni; \u220B &prod; \u220F
		&sum; \u2211 &minus; \u2212 &lowast; \u2217 &radic; \u221A
		&prop; \u221D &infin; \u221E &ang; \u2220 &and; \u2227 &or; \u2228
		&cap; \u2229 &cup; \u222A &int; \u222B &there4; \u2234 &sim; \u223C
		&cong; \u2245 &asymp; \u2248 &ne; \u2260 &equiv; \u2261 &le; \u2264
		&ge; \u2265 &sub; \u2282 &sup; \u2283 &nsub; \u2284 &sube; \u2286
		&supe; \u2287 &oplus; \u2295 &otimes; \u2297 &perp; \u22A5
		&sdot; \u22C5 &lceil; \u2308 &rceil; \u2309 &lfloor; \u230A
		&rfloor; \u230B &lang; \u2329 &rang; \u232A &loz; \u25CA
		&spades; \u2660 &clubs; \u2663 &hearts; \u2665 &diams; \u2666
		&quot; \x22 &amp; \x26 &lt; \x3C &gt; \x3E O&Elig; \u152 &oelig; \u153
		&Scaron; \u160 &scaron; \u161 &Yuml; \u178 &circ; \u2C6
		&tilde; \u2DC &ensp; \u2002 &emsp; \u2003 &thinsp; \u2009
		&zwnj; \u200C &zwj; \u200D &lrm; \u200E &rlm; \u200F &ndash; \u2013
		&mdash; \u2014 &lsquo; \u2018 &rsquo; \u2019 &sbquo; \u201A
		&ldquo; \u201C &rdquo; \u201D &bdquo; \u201E &dagger; \u2020
		&Dagger; \u2021 &permil; \u2030 &lsaquo; \u2039 &rsaquo; \u203A
		&euro; \u20AC &apos; \u0027 &lrm; "" &rlm; ""
	};
      set data [string map $escapes $data]
}

# settings
proc YouTube-Settings {nick host hand chan text} {

	if {![channel get $chan youtube] && $text == "on"} {
		catch {channel set $chan +youtube}
		putserv "notice $nick :YouTube: enabled for $chan"
		putlog "YouTube: script enabled (by $nick for $chan)"
	} elseif {[channel get $chan youtube] && $text == "off"} {
		catch {channel set $chan -youtube}
		putserv "notice $nick :YouTube: disabled for $chan"
		putlog "YouTube: script disabled (by $nick for $chan)"
	} else {
		putserv "notice $nick :YouTube: !youtube (on|off) enables or disables script for active channel"
	}

}

putlog "YouTube 1.4 loaded"
