#bind dcc - "yts" dcc:yts

set ytscanais "#torrents"
set ytsdatadoscript "06-Fevereiro-2021"
set ytslinhalimite 400

#proc dcc:yts {indx handle text} {}
bind time - "20 00 * * *" ytscheck
bind time - "20 06 * * *" ytscheck
bind time - "10 12 * * *" ytscheck
bind time - "10 14 * * *" ytscheck
bind time - "10 18 * * *" ytscheck
bind time - "10 20 * * *" ytscheck
bind time - "10 22 * * *" ytscheck


proc ytscheck {min hora dia mes ano} {
	global ytscanais ytslinhalimite
	
set tempostring {
    "Feb" "Fev" "Apr" "Abr" "May" "Mai" "Aug" "Ago" "Sep" "Set" "Oct" "Out" "Dec" "Dez"
    "Mon" "Seg" "Tue" "Ter" "Wed" "Qua" "Thu" "Qui" "Fri" "Sex" "Sat" "Sáb" "Sun" "Dom"}
set tipoconteudo {
    "Horror" "Terror" "Adventure" "Aventura"
    "Sport" "Desporto" "Fantasy" "Fantasia"
    "Action" "Acção" "Family" "Família"
    "Documentary" "Documentário"
    "Music " "Música "
    "Sci-Fi" "Ficção Científica" "Biography" "Biografia"
    "Animation" "Animação"
    "Comedy" "Comédia" "War" "Guerra"
}



    #putlog "YTS: A obter o feed..."

	catch {set ytsdata [exec wget -q -O - https://yts.lt/rss]}
        if {![info exists ytsdata]} {
            putlog "YTS: Não foi possivel descarregar dados."
            return
        }
	#putlog "YTS: [string length $ytsdata] bytes recebidos. A analisar..."
	set latest ""

	set fyts [open "yts.txt" r]
	while {1} {
    	set linha [gets $fyts]
	    if {[eof $fyts] || $linha==""} {
    	    close $fyts
        	break
	    }
		set latest $linha
	}

	set ytsdata [string map {"<![CDATA[" "" "[YTS.LT]" "" "[YTS.MX]" "" "\n" "" "\t" "" "  " ""} $ytsdata]]

	set listafeed ""

	set entradas [regexp -all -inline -- {<item>(.*?)<\/item>} $ytsdata]
	foreach {- entrada} $entradas {

		set eitems [regexp -all -inline -- {<title>(.*?)]]></title><description>(.*?)</description>.*<pubDate>(.*?)</pubDate>} $entrada]
		set titulo [string trimright [lindex $eitems 1]]
		set desc [regexp -all -inline -- {<a href="(.*?)"><img src=".*" alt=".*" /></a><br />IMDB Rating: (.*?)<br />Genre: (.*?)<br />Size: (.*?)<br />Runtime: (.*?)<br /><br />(.*?)]]>} [lindex $eitems 2]]
		set link [lindex $desc 1]
		set imdb [lindex $desc 2]
		set genero [lindex $desc 3]
		set tamanho [lindex $desc 4]
		set tempo [lindex $desc 5]
		if {[lindex $desc 6]==""} {set desc "N/A"} {set desc [lindex $desc 6]}
		set datacr [clock scan [lindex $eitems 3] -format "%a, %d %b %Y %H:%M:%S %z"]
		set crfeed "$datacr|$titulo|$link|$imdb|$genero|$tamanho|$tempo|$desc"
		lappend listafeed $crfeed
	}

	set listafeed [lsort -decreasing $listafeed]
 
	set listafeed2 ""
	foreach ifeed $listafeed {
		if {$ifeed==$latest} {break}
		lappend listafeed2 $ifeed
	}
	set listafeed [lreverse $listafeed2]
    #putlog "YTS: Novos torrents: [llength $listafeed]"
 
 	set fyts [open yts.txt a+]
	foreach ilistafeed $listafeed {
		set eitems [split $ilistafeed "|"]
		foreach ytscanal $ytscanais {
			set chanoutput "\0039,1[encoding convertfrom identity 🎬]\035YTS\003\035 \002[lindex $eitems 1]\002 \0037\037[lindex $eitems 2]\037\003 ([string map $tempostring [clock format [lindex $eitems 0] -format "%a, %d/%b/%Y %H:%M:%S"]]) \002IMDB:\002[lindex $eitems 3] \002Género:\002[string map $tipoconteudo [lindex $eitems 4]] \002Tamanho:\002[lindex $eitems 5] \002Duração:\002[lindex $eitems 6]"
			#if {[string length $chanoutput]+[string length [lindex $eitems 7]]>450} {
			#	puthelp "privmsg $ytscanal :$chanoutput"
			#	set desc [lindex $eitems 7]
			#	if {[string length [lindex $eitems 7]]<$ytslinhalimite} {
			#		puthelp "privmsg $ytscanal :\002(CONT.)\002 \035[lindex $eitems 7]\035"
			#	} else {
			#		set pdesc [split $desc " "]
			#		set odesc ""
			#		foreach idesc $pdesc {
			#			set odesc "$odesc$idesc "
			#			if {[string length $odesc]>$ytslinhalimite} {
			#				puthelp "privmsg $ytscanal :\002(CONT.)\002 \035$odesc\035"
			#				set odesc ""
			#			}
			#		}
			#		puthelp "privmsg $ytscanal :\002(CONT.)\002 \035$odesc\035"
			#	}
			#} else {}
				puthelp "privmsg $ytscanal :$chanoutput"
				# \035[lindex $eitems 7]\035
			
		}
		puts $fyts $ilistafeed
	}
	
	close $fyts
	#putlog "YTS: Fim da actualização do ficheiro."
}

putlog "YTS.LT $ytsdatadoscript"
