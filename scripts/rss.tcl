#BUILD 19-OUTUBRO-2023
bind time - "* * * * *" rss
bind dcc - "rss" dccrss

proc dccrss {handle idx text} {
	set arg1 [lindex $text 0]
	if {$arg1!=""} {
		set arg2 [string range $text [string length $arg1]+1 end]
	}
	source rss.cfg

	switch $arg1 {
		"listar" {
			set nomes "itemrss canal quando link fmtdata"
			if {$arg2!=""} {
				set nomes $arg2
			}
			foreach itemrss [lsort -dictionary [array names rss]] {
				foreach {var valor} $rss($itemrss) {
					set [subst $var] $valor
				}
				foreach nome $nomes {
					if {![info exist [subst $nome]]} {
						putdcc $idx "Não existe: \002$nome\002"
						return
					}
					lappend campos($nome) [string length [subst $[subst $nome]]]
				}
			}

			foreach nome $nomes {
				lappend posicoes [lindex [lsort -dictionary $campos($nome)] end] [string totitle $nome]
			}
			putdcc $idx "❏ [format [string repeat "%-*s  " [llength $nomes]] {*}[string map {Itemrss Nome} $posicoes]]"

			foreach itemrss [lsort [array names rss]] {
				foreach {var valor} $rss($itemrss) {
					set [subst $var] $valor
				}
				set out ""
				foreach nome $nomes {
					lappend out [lindex [lsort -dictionary $campos($nome)] end] [subst $[subst $nome]]
				}
				putdcc $idx [string trimright [format "%-*s [string repeat "%-*s  " [llength $nomes]]" 1 [if {$activo=="sim"} {set a "✓"} {set a "✕"}] {*}$out]]
			}
			return
		}
	"alterar" {
			if {$arg2==""} {
				putdcc $idx "\002<id>\002 <chave> <alteração>"
				return
			}
			set id [lindex $arg2 0]
			if {[lsearch [array names rss] $id]<0} {
				putdcc $idx "Não existe esse id: $id"
				putdcc $idx "Tem de ser um de: [lsort -dictionary [array names rss]]"
				return
			}
			set chave [lindex $arg2 1]
			if {$chave==""} {
				putdcc $idx "<id> \002<chave>\002 <alteração>"
				return
			}
			if {[lsearch [dict keys $rss($id)] $chave]<0} {
				putdcc $idx "Não existe essa chave: $chave"
				putdcc $idx "Tem de ser uma de: [lsort -dictionary [dict keys $rss($id)]]"
				return
			}
			set valor [string range $arg2 [expr [string length $id]+[string length $chave]+2] end]
			if {$valor==""} {
				putdcc $idx "<id> <chave> \002<alteração>\002"
				return
			}
			set antes [dict get $rss($id) $chave]
			if {$antes==$valor} {
				putdcc $idx "São iguais."
				return
			}
			dict set rss($id) $chave $valor
			putdcc $idx "\002$chave\002 alterado de \002$antes\002 para \002$valor\002."

		}
	"adicionar" {

		}
	default {
			putdcc $idx "COMANDO NÃO RECONHECIDO: $arg1"
			return
		}
	}
	
	#fim proc
	set fp [open rss.new w+]
	foreach id [lsort -dictionary [array names rss]] {
		puts $fp "set rss($id) \{"
		foreach chave [lsort [dict keys $rss($id)]] {
			puts $fp "\t$chave\t\"[string map {\002 \\002 \003 \\003 \026 \\026 \037 \\037} [dict get $rss($id) $chave]]\""
		}
		puts $fp "\}\n"
	}
	close $fp
	putdcc $idx "Ficheiro guardado."
}


proc rss {min hor dia mes ano} {
	package require htmlparse
	global bufffeeds
	set ecache 0
	if {![info exist bufffeeds]} {
		set bufffeeds ""
		set ecache 1
	}

	if {![file exist rss.cfg]} {
		putlog "O ficheiro rss.cfg não existe."
		return
	}
	source rss.cfg
	foreach itemrss [array names rss] {
		foreach {var valor} $rss($itemrss) {
			set [subst $var] $valor
		}

		if {$activo=="nao"} {
			continue
		}
		foreach iquando [split $quando ","] {
			
			if {![string match $iquando "$hor:$min"] && $ecache==0} {
				continue
			}
			set feed [exec wget --timeout=2 -q -O - $link]
			set feed [string map {"<!\[CDATA\[" "" "]]>" ""} $feed]
			set feed [string map {\[ ( ] )} $feed]
			set contagem 0

			set allitems [lreverse [encmatches $feed "<item>" "</item>"]]

			foreach sitem $allitems {
				set titulo [::htmlparse::mapEscapes [lindex [encmatches $sitem "<title>" "</title>"] 0]]
				if {[lsearch $bufffeeds $titulo]<0} {
					set link [encmatches $sitem "<link>" "</link>"]
					set data [lindex [encmatches $sitem "<pubDate>" "</pubDate>"] 0]
putdcc 6 ">$titulo<"
#putdcc 7 ">$link<"
#putdcc 7 ">$data<"
					if {$ecache==0} {
						putquick "privmsg $canal :[subst $logo] [dehex $titulo] ([convdata $data $fmtdata]) [tinyurl $link]"
					}
					lappend bufffeeds $titulo
				}
			}
		}
	}
}

proc convdata {data formato} {
#putdcc 7 "DATA >$data<"
#putdcc 7 "FORMATO >$formato<"

	return [string map {
		Sun Dom Mon Seg Tue Ter Wed Qua Thu Qui Fri Sex Sat Sáb Feb Fev Apr Abr May Mai Aug Ago Sep Set Oct Out Dec Dez
		} [clock format [clock scan $data -format $formato] -format "%a,%d/%b/%Y %H:%M:%S"]]
}

proc encmatches {string stringA stringB} {
	set pointA 0
	set pointB -1
	set matches ""
	while {$pointA>-1} {
		set pointA [string first $stringA $string $pointB]
		if {$pointA==-1} {break}
		set pointB [string first $stringB $string $pointA]
		if {$pointB==-1} {break}
		lappend matches [string range $string $pointA+[string length $stringA] $pointB-1]
	}
	return $matches
}

putlog "RSS FEEDS"
