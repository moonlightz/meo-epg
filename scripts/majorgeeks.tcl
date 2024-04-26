set mg(bdata) "27-Dez-2020"
set mg(url) "https://www.majorgeeks.com/files/rss"
set mg(alvo1) "/media/pi/3C86-5BF7/progs"
set mg(alvo2) "/home/pi/progs"
set mg(db) "majorgeeks-db.txt"
set mg(channels) "#majorgeeks"

bind time - "07 * * * *" majorgeeks
bind time - "37 * * * *" majorgeeks
bind time - "20 * * * *" majorgeeks
bind time - "54 * * * *" majorgeeks



proc majorgeeks {m h dia mes ano} {
	global mg
	#putlog "Majorgeeks: A iniciar tarefa..."
	if {![file exists $mg(db)]} {
		set mgf [open $mg(db) w+]
		close $mgf
		putlog "Majorgeeks: Ficheiro $mg(db) vazio criado."
	}
	catch {set mgc [exec wget -q -O - $mg(url)]}
	#putlog "Majorgeeks: RSS tem [string length $mgc] bytes"
	set mgc [string map { "&#039;" "'" "&amp;" "\&"
		" \]" "\]" "\n" "" "\"" "" "  " " "} $mgc]
	set mgc [string range $mgc [string first "<item>" $mgc] end]
	
	set mgtitulos [regexp -all -inline -- {<title>(.*?)</title>} $mgc]
	set mgdatas [regexp -all -inline -- {<pubDate>(.*?)</pubDate>} $mgc]
	set mglinks [regexp -all -inline -- {<link>(.*?)</link>} $mgc]
	set mgdesc [regexp -all -inline -- {<description>(.*?)</description>} $mgc]

	set mgitems ""
	foreach {- titulo} $mgtitulos {- link} $mglinks {- data} $mgdatas {- desc} $mgdesc {
		set data [string map {
                   "Mon" "Seg" "Tue" "Ter" "Wed" "Qua" "Thu" "Qui" "Fri" "Sex" "Sat" "Sáb" "Sun" "Dom"
                   "Feb" "Fev" "Apr" "Abr" "May" "Mai" "Aug" "Ago" "Oct" "Out" "Dec" "Dez"
                   } [clock format [clock scan $data -format "%a, %d %b %Y %H:%M:%S %z"] -format "%a, %d/%b/%Y %H:%M:%S"]]
		lappend mgitems "[string trimright $titulo]«$data«$link«$desc"
	}

	set mgitems [lreverse $mgitems]
	if {[file size $mg(db)]==0} {
		#nada no ficheiro, despejar o conteudo noficheiro
		set mgf [open $mg(db) w+]
		foreach mgitem $mgitems {
			puts $mgf $mgitem
		}
		close $mgf
		#putlog "Majorgeeks: Despejo feito. A sair."
		return
	}

	set mgf [open $mg(db) r]
    set mgfc [read $mgf]
    close $mgf
	set mgultimo [lindex [split $mgfc "\n"] end-1]
	set mgultimotitulo [lindex [split $mgultimo "«"] 0]
#putlog "ultimo: >$mgultimotitulo<"
	set mgf [open $mg(db) a+]

	set mgencontrado 0
	set mgcontador 0
	set mgchanitems ""
	foreach mgitem $mgitems {
		set mgsplitem [split $mgitem "«"]
		if {$mgultimotitulo==[lindex $mgsplitem 0]} {
			set mgencontrado 1
			continue
		}
		if {$mgencontrado==1} {
			incr mgcontador
			puts $mgf $mgitem
			lappend mgchanitems $mgitem
		}
	}
	#se não foi encontrado no rss, adicionar o rss todo
	if {$mgencontrado==0} {
		putlog "Majorgeeks: O último título não foi encontrado. A adicionar todos ao ficheiro..."
		foreach $mgitem $mgitems {
			incr mgcontador
			puts $mgf $mgitem
		}
	} else {
		#set mgcontador 0
		foreach mgitem [lreverse $mgchanitems] {
			set mgsplitem [split $mgitem "«"]
			#incr mgcontador
            foreach canal $mg(channels) {
                puthelp "privmsg $canal :\00314\002🎖🎖🎖\002\003 \002[lindex $mgsplitem 0]\002 ([lindex $mgsplitem 1]) \037[lindex $mgsplitem 2]\037"
            }
		}
	}
	close $mgf
	#putlog "Majorgeeks: Itens adicionados: $mgcontador"
	#putlog "Majorgeeks: Feito."
}
putlog "MajorGeeks $mg(bdata)"

proc mgurl {url} {
	global mg
	#putlog "A obter $url"
	set site [exec wget -q -O - $url]
	#putlog "[string length $site] bytes descarregados"




}
