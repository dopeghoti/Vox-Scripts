# config starts 
# which method should be used when shortening the url? 
# (0-3) will only use the one you've chosen. 
# (4-5) will use them all. 
# 0 --> http://tinyurl.com 
# 1 --> http://u.nu 
# 2 --> http://is.gd 
# 3 --> http://cli.gs 
# 4 --> randomly select one of the four above ( 2,0,0,3,1..etc ) 
# 5 --> cycle through the four above ( 0,1,2,3,0,1..etc ) 
# --- 
variable lmgtfyShortType 2 

# script starts 
package require http 
setudef flag lmgtfy 
bind pub - ?find pub:lmgtfy 

proc pub:lmgtfy {nick uhost hand chan text} { 
  if {[channel get $chan lmgtfy]} { 
    if {[llength [split $text]] < 2} { 
      putserv "privmsg $chan :?find <nick> <search terms here>" 
      return 
    } elseif {![onchan [lindex [split $text] 0] $chan]} { 
      putserv "privmsg $chan :[lindex [split $text] 0] isn't on this channel. If you're trying to be funny, consider this a failure to impress me with your wit." 
      return 
    } else { 
      putserv "privmsg $chan :[lindex [split $text] 0], [webbytin "http://lmgtfy.com/?l=1&[http::formatQuery q [join [lrange [split $text] 1 end]]]" $::lmgtfyShortType]" 
      #putserv "privmsg $chan :[lindex [split $text] 0] -> [webbytin "http://lmgtfy.com/?[http::formatQuery q [join [lrange [split $text] 1 end]]]" $::lmgtfyShortType]" 
    } 
  } 
} 

proc webbytin {url type} { 
   set ua "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.9.0.5) Gecko/2008120122 Firefox/3.0.5" 
   set http [::http::config -useragent $ua] 
   switch -- $type { 
     4 { set type [rand 4] } 
     5 { if {![info exists ::webbyCount]} { 
           set ::webbyCount 0 
           set type 0 
         } else { 
           set type [expr {[incr ::webbyCount] % 4}] 
         } 
       } 
   } 
   switch -- $type { 
     0 { set query "http://tinyurl.com/api-create.php?[http::formatQuery url $url]" } 
     1 { set query "http://u.nu/unu-api-simple?[http::formatQuery url $url]" } 
     2 { set query "http://is.gd/api.php?[http::formatQuery longurl $url]" } 
     3 { set query "http://cli.gs/api/v1/cligs/create?[http::formatQuery url $url]&title=&key=&appid=webby" } 
   } 
   set token [http::geturl $query -timeout 3000] 
   upvar #0 $token state 
   if {[string length $state(body)]} { return [string map {"\n" ""} $state(body)] } 
   return $url 
}
