#moonlight 1-agosto-2021
#26-Outubro-2023
#script title fetch usando o curl

bind pubm - "* *://*" urltitle

proc urltitle {nick host hand chan text} {
	if {$nick=="GuiaTV" || $nick=="TP-Link" || $nick=="Twitter"} {return}
	if {[string tolower $chan]=="#portugal"} {return}
	package require htmlparse
	set url [lindex $text [lsearch $text *://*]]
	set dados [exec /usr/bin/curl --silent -L $url]
	#regexp {<title>(.*?)</title>} $dados -> resultado
	set resultado [string trim [string range $dados [string first "<title>" $dados]+7 [string first "</title>" $dados]-1]]
	if {$resultado!=""} {
		putquick "PRIVMSG $chan :Título: [::htmlparse::mapEscapes $resultado]"
		return
	}
	if {[string range $dados 1 3]=="PNG"} {
		unset dados
		putquick "PRIVMSG $chan :[string map {"PNG image data" "Imagem PNG" "color" "cor" "non-interlaced" "não-interlaçado"} [lrange [exec curl --silent $url | file -] 1 end]]"
		return

	}
	if {[binary encode hex [string range $dados 0 2]]=="ffd8ff"} {
		#ficheiro jpg
	        unset dados
        putquick "PRIVMSG $chan :[string map {"PNG image data" "Imagem PNG" "color" "cor" "non-interlaced" "não-interlaçado"} [lrange [exec curl --silent $url | file -] 1 end]]"
        return

	}
#putdcc 10 ">[binary encode hex $dados]<"
}
putlog "CURL FETCH"
