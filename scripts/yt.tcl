bind pubm - "* *https://www.youtube.com/watch?v=*" youtube
bind pubm - "* *https://youtu.be/*" youtube
bind PUBM - * youtube:pubm

package require json
package require http
package require tls

#set youtube(api) "AIzaSyCxMgZ1FHsKunxzfZg_Fy2HqoM77e5a3g0"
set youtube(api) "AIzaSyAzyur_d2hTp8L1rK_pQsRKKqAJ8TwQz-o"

proc youtube:pubm {nick uhost hand chan arg} {
   global temp

   if {[string index $arg 0] in {! . `}} {
      set temp(cmd) [string range $arg 1 end]
      set temp(cmd) [lindex [split $temp(cmd)] 0]
      set arg [join [lrange [split $arg] 1 end]]
   } elseif {[isbotnick [lindex [split $arg] 0]]} {
      set temp(cmd) [lindex [split $arg] 1]
      set arg [join [lrange [split $arg] 2 end]]
   } else { return 0 }

   if {[info commands ytpubm:$temp(cmd)] ne ""} { ytpubm:$temp(cmd) $nick $uhost $hand $chan $arg }
}

proc ytpubm:youtube {nick uhost hand chan arg} {

   switch -exact -- [lindex [split $arg] 0] {
      on {
         if {[isop $nick $chan]} {
            channel set $chan +youtube

            putserv "PRIVMSG $chan :[stripcodes bcruag "\002$nick\002 - Set channel mode +youtube on $chan"]"
         }
      }
      off {
         if {[isop $nick $chan]} {
            channel set $chan -youtube

            putserv "PRIVMSG $chan :[stripcodes bcruag "\002$nick\002 - \00307Set channel mode -youtube on $chan"]"
         }
      }
   }
}
proc youtube {nick uhost hand chan arg} {
   global ytignore youtube

#   if {![channel get $chan youtube]} { return 0 }
   if {![string match -nocase *yout* $arg]} { return 0 }

   ## ++
   set floodtime 10

   ## ++
   if {![info exists ytignore($nick)]} {
      set ytignore($nick) [unixtime]
      utimer $floodtime [list unset -nocomplain ytignore($nick)]
   }

   ## ++
   if {[expr [unixtime]-$ytignore($nick)]>$floodtime} { putlog "ignoram"; return 0 }

   set youtubecheck [regexp -all -nocase {(?:\/watch\?v=|youtu\.be\/)([\d\w-]{11})} $arg match youtubeid]
if {![info exists youtubeid]} {
        putserv "privmsg $chan :O link do vídeo é inválido."
return
}
#   ::http::register https 443 [list ::tls::socket -tls1 1]
::http::register https 443 [list ::tls::socket -ssl2 0 -ssl3 0 -tls1 1]
   if {[catch {http::geturl "https://www.googleapis.com/youtube/v3/videos?[http::formatQuery id $youtubeid key $youtube(api) part snippet,contentDetails,statistics,status]"} tok]} {
      putlog "Socket error: $tok"
      return 0
   }
   if {[http::status $tok] ne "ok"} {
      set status [http::status $tok]

      putlog "TCP error: $status"
      return 0
   }
putlog [http::data $tok]
   if {[http::ncode $tok] != 200} {
      set code [http::code $tok]
      http::cleanup $tok

      putlog "HTTP Error: $code"
      return 0
   }

   set data [http::data $tok]

   set parse [::json::json2dict $data]
#putlog "[string range $parse 0 400]"
#putlog "[string range $parse 398 900]"
#putlog "[string range $parse 900 1400]"


#  if {![info exists snippet]} {
#   putquick "privmsg $chan :O vídeo não existe ou não está disponível."
#   return
#}
   set playtime [lindex [dict get [lindex [dict get $parse items] 0] snippet] 1]
   set title [encoding convertfrom identity [lindex [dict get [lindex [dict get $parse items] 0] snippet] 5]]
   set viewCount [lindex [dict get [lindex [dict get $parse items] 0] statistics] 1]
   set likeCount [lindex [dict get [lindex [dict get $parse items] 0] statistics] 3]
   set dislikeCount [lindex [dict get [lindex [dict get $parse items] 0] statistics] 5]
   set commentCount [lindex [dict get [lindex [dict get $parse items] 0] statistics] 9]
        foreach {itemA itemB} [dict get [lindex [dict get $parse items] 0] snippet] {
                if {$itemA=="channelTitle"} {
                        set channelTitle [encoding convertfrom identity $itemB]
                        break
                }
        }
   set publishedAt [lindex [dict get [lindex [dict get $parse items] 0] snippet] 1]
   set publishedAt [string map {"T" " " ".000Z" "" "Z" ""} $publishedAt]
#putlog $publishedAt
   set publishedAt [clock format [clock scan $publishedAt -format "%Y-%m-%d %H:%M:%S"] -format "%H:%M:%S de %a,%d/%b/%Y"]
   set publishedAt [string map {"Sun" "Dom" "Mon" "Seg" "Tue" "Ter" "Wed" "Qua" "Thu" "Qui" "Fri" "Sex" "Sat" "Sáb" "Feb" "Fev" "Apr" "Abr" "May" "May" "Aug" "Ago" "Sep" "Set" "Oct" "Out" "Dec" "Dez"} $publishedAt]

   set duration [lindex [dict get [lindex [dict get $parse items] 0] contentDetails] 1]
   set duration [string map [list "PT" "" "P" "" "W" "semanas " "DT" "d " "H" "h " "M" "m " "S" "s"] $duration]
   set definition [string toupper [lindex [dict get [lindex [dict get $parse items] 0] contentDetails] 5]]

   if {$likeCount==""} {set likeCount "0"}
   if {$dislikeCount==""} {set dislikeCount "0"}
   if {$commentCount==""} {set commentCount "0"}


   set saida "\002\00300,04 ► \00301,00YouTube\003\002\017 $title \002$definition\002 ✽ [youtube:convert $viewCount] visualizações ✽ [youtube:convert $likeCount] gostos ✽ [youtube:convert $dislikeCount] não-gostos ✽ [youtube:convert $commentCount] comentários ✽ Duração: $duration ✽ Publicado: $publishedAt por $channelTitle"

  putserv "PRIVMSG $chan :$saida"

}
proc youtube:convert {num} { while {[regsub {^([-+]?\d+)(\d\d\d)} $num "\\1 \\2" num]} {}; return $num }

putlog "Succesfully loaded: \00303YouTUBE TCL Script"
















