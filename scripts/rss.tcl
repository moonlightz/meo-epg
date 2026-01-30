
set rssbuild "26-Janeiro-2026"
#moonlight

bind pubm - "* .*" rsstrig
bind dcc - "rss" dccrss
bind pub - ".rss" chrss


proc rsstrig {nick uhost handle chan text} {
	if {[string index $text 0]!="."} {
		return
	}
	set rsspedido [string range [lindex [split $text] 0] 1 end]
	set nvezes [lindex [split $text] 1]
	if {$nvezes==""} {
		set nvezes 0
	}
	if {![string is integer $nvezes]} {
		set nvezes 0
	}
	if {$rsspedido==""} {
		return
	}

	if {![file exist rss.cfg]} {
		putlog "O ficheiro rss.cfg não existe."
		return
	}
	source rss.cfg

	if {!$opcoes(listchantrig)} {
		return
	}
	foreach itemrss [array names rss] {
		if {$rsspedido==$itemrss} {
			foreach {var valor} $rss($itemrss) {
				set [subst $var] $valor
			}
			if {!$activo} {
				return
			}
			if {$chan!=$canal} {
				return
			}
			if {$nvezes>0} {
				set vezes $nvezes
			}
			set ffeeds [obtertdl $link $logo $itemrss $fmtdata $opcoes(urldebug) $opcoes(usartinyurl)]
			set contagem 0
			set vezes2 [expr $vezes-1]
			foreach iffeed [lrange $ffeeds end-$vezes2 end] {
				incr contagem
				putquick "privmsg $chan :$iffeed"
				if {$vezes==$contagem} {
					return
				}
			}
		}
	}
 #-----------------
}

proc dccrss {handle idx text} {
	
	#inicializar vars por defeito
	set opcoes(urldebug) 0
	set opcoes(listchantrig) 1
	set opcoes(activarchantrig) 1
	set opcoes(usartinyurl) 0
	set opcoes(canaisignorartopico) ""
	set opcoes(canaistinyurlforcado) ""

	#analisar o input
	set arg1 [lindex $text 0]
	if {$arg1!=""} {
		set arg2 [string trim [string range $text [string length $arg1]+1 end]]
	}
	source rss.cfg

	switch [string tolower $arg1] {
		"" - "ajuda" {
			#>ajuda
			putdcc $idx "RSS $::rssbuild"
			foreach linha [split [info body dccrss] \n] {
				if {[string range [string trim $linha] 0 1]=="#>"} {
					putdcc $idx "\ \ \ \ [string range $linha [string first "#>" $linha]+2 end]"
				}
			}
			return
		}
		"listar" {
			#>listar [campos]
			if {[array names rss]==""} {
				putdcc $idx "Não há itens para listar. Adicione um feed usando .rss adicionar"
				return
			}
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
			putdcc $idx "\037❏ [format [string repeat "%-*s  " [llength $nomes]] {*}[string map {Itemrss Nome} $posicoes]]"

			foreach itemrss [lsort [array names rss]] {
				foreach {var valor} $rss($itemrss) {
					set [subst $var] $valor
				}
				set out ""
				foreach nome $nomes {
					lappend out [lindex [lsort -dictionary $campos($nome)] end] [subst $[subst $nome]]
				}
				#putdcc $idx ">$campos<"
				putdcc $idx [string trimright [format "%-*s [string repeat "%-*s  " [llength $nomes]]" 1 [if {$activo} {set a "✓"} {set a "✕"}] {*}$out]]
				#return
			}
			return
		}
		"agendado" {
			#>agendado [hora]
			if {[array names rss]==""} {
				putdcc $idx "Não há nada para mostrar."
				return
			}
			for {set h 0} {$h<=23} {incr h} {
				for {set m 0} {$m<=59} {incr m} {
					set hm([format "%02d:%02d" $h $m]) ""
				}
			}
			foreach ihm [array names hm] {
				foreach itemrss [lsort [array names rss]] {
					foreach {var valor} $rss($itemrss) {
						set [subst $var] $valor
					}
					foreach iquando [split $quando ,] {
						if {[string match $iquando $ihm]} {
							lappend hm($ihm) $itemrss➤\0038$canal\003
						}
					}
				}
			}
			if {$arg2==""} {
				lappend hmrange [clock format [clock scan "3 minutes ago"] -format %H:%M]
				lappend hmrange [clock format [clock scan "2 minutes ago"] -format %H:%M]
				lappend hmrange [clock format [clock scan "1 minutes ago"] -format %H:%M]
				lappend hmrange [clock format [clock seconds] -format %H:%M]
				lappend hmrange [clock format [clock scan "1 minutes"] -format %H:%M]
				lappend hmrange [clock format [clock scan "2 minutes"] -format %H:%M]
				lappend hmrange [clock format [clock scan "3 minutes"] -format %H:%M]
				lappend hmrange [clock format [clock scan "4 minutes"] -format %H:%M]
			} else {
				scan $arg2 %d arg2
				if {$arg2<0 || $arg2>23} {
					putdcc $idx "Tem de ser entre 0 e 23 inclusivé."
					return
				}
				for {set m 0} {$m<=59} {incr m} {
					lappend hmrange [format "%02d:%02d" $arg2 $m]
				}
			}
			foreach ihmrange $hmrange {
				putdcc $idx [string trimright [format "%9s %-100s" [if {$ihmrange==[strftime %H:%M]} {set a "<\[$ihmrange\]>"} {set a "  $ihmrange  "}] $hm($ihmrange)]]
			}
			return
		}
		"alterar" {
			#>alterar <feed> <chave> <novo-valor>
			if {$arg2==""} {
				putdcc $idx "\002<id>\002 <chave> <alteração>"
				return
			}
			if {[array names rss]==""} {
				putdcc $idx "Não é possível alterar seja o que for porque não há itens para serem alterados. Tem de adicionar um feed primeiro."
				return
			}
			set id [lindex $arg2 0]
			if {[lsearch [array names rss] $id]<0} {
				putdcc $idx "Não existe o id: $id"
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
		"opcoes" - "opções" {
			#>opcoes [opção] [novo_valor]
			set opcao [lindex $arg2 0]
			set valopcao [lindex $arg2 1]
			foreach ioptlista [array names opcoes] {
   				lappend optlista $ioptlista "-"
	   		}
		   	set optlista [lrange $optlista 0 end-1]
			switch $opcao \
				{*}$optlista {
				   	if {$valopcao==""} {
					   	if {!$opcoes($opcao)} {
					   		putdcc $idx "\002$opcao\002 está desactivado."
					   	} else {
						   	putdcc $idx "\002opcao\002 está activado."
					   	}
					   	return
				   	} else {
						if {![string is boolean $valopcao]} {
							putdcc $idx ".rss opções $opcao <0|1>"
							return
						} else {
							set valorantigo $opcoes($opcao)
							if {$valorantigo==$valopcao} {
								putdcc $idx "$opcao já é $valorantigo"
								return
							}
							set opcoes($opcao) $valopcao
							putdcc $idx "$opcao alterada $valorantigo para $opcoes(urldebug)"
						}
					}
				} \
				"" {
					foreach opcao [lsort -dictionary [array names opcoes]] {
						putdcc $idx [format "  %-*s  %-*s %-*s" \
							[expr max([join [lmap word [split [array names opcoes]] {string length $word}] ","])] $opcao \
							1 $opcoes($opcao) \
							11 [if {[string is boolean $opcoes($opcao)]} {set a "([if {!$opcoes($opcao)} {set a "desactivado"} {set a "activado"}])"} {set a ""}]]
					}
					return
				} \
				default {
				   	putdcc $idx "Não conheço -> $opcao"
				   	return
				}
			
			#putdcc $idx "OK"
		}
		"adicionar" {
			#>adicionar <link> <id> <canal> <quando> <logo>
			if {$arg2==""} {
				putdcc $idx "<link> \[id\] \[canal\] \[quando\] \[logo\]"
				return
			}

			set link	[lindex $arg2 0]
			set id		[lindex $arg2 1]
			set canal	[lindex $arg2 2]
			set quando	[lindex $arg2 3]
			set logo	[lrange $arg2 4 end]

			if {[string match https://www.youtube.com/@* $link]} {
				if {$id=="" || $id=="-"} {
					regexp {@([^/]+)} $link -> id
				}
				set yhtml [exec wget -qO - $link]
				regexp {channel/([A-Za-z0-9_-]+)">} $yhtml -> UCid
				set link "https://www.youtube.com/feeds/videos.xml?channel_id=$UCid"
				putdcc $idx "A alterar link para \002$link\002"
				regexp {<title>(.*?) - YouTube</title>} $yhtml -> ologo
				set logo "\002$ologo\002"
				putdcc $idx "A definir logo para $logo"
			}

			if {![string match *:* $quando]} {
				putdcc $idx "'quando' tem de ter o formato hh:mm, como 12:34 *:34 1?:34 12:*4 12:* ou 12:34,23:45"
				return
			}

			if {[catch {set feed [exec links -source $link]} erro]} {
				putdcc $idx "ERRO: $erro"
				return
			}

			if {$id==""} {
				regexp {www\.(.*?)\.} $link -> id
				if {$id==""} {
					regexp {\://\.(.*?)\.} $link -> id
				}
			}

			if {[string first "<item>" $feed]>0} {
				putdcc $idx "É um feed rss."
				set allitems [encmatches $feed "<item" "</item>"]
				if {[llength $allitems]>0} {
					set data [lindex [encmatches [lindex $allitems 0] "<pubDate>" "</pubDate>"] 0]
					if {$data==""} {
						putdcc $idx "Parece que não há um único <pubDate>. Vou utilizar o formato pré-definido na mesma."
						set formato "%a, %d %b %Y %H:%M:%S %Z"
					} else {
						set encontradoformato 0
						foreach formato [list "%Y-%m-%d %H:%M:%S" "%a, %d %b %Y %H:%M:%S %Z" "%Y-%m-%dT%H:%M:%S+00:00"] {
putdcc $idx ">$data<"
							if {[catch {clock scan $data -format $formato} erro]} {
								#putdcc $idx "Este não serve: $formato"
								continue
							}
							putdcc $idx "O formato da data é: $formato"
							set encontradoformato 1
							break
						}
						if {$encontradoformato==0} {
							putdcc $idx "O formato apropriado não foi encontrado. O formato genérico irá ser adicionado e é preciso alterar o formato mais tarde."
							set formato "%a, %d %b %Y %H:%M:%S %Z"
						}
					}
					lappend rss($id) "activo" 1 "canal" [if {$canal==""} {set canal "#code"} {set canal}] "fmtdata" $formato "link" "$link" "logo" [if {$logo==""} {set logo "\002$id\002"} {set logo $logo}] "quando" [if {$quando==""} {set quando "*:00"} {set quando}] "vezes" "3"
				}
			}
			
			if {[string first "<entry>" $feed]>0} {
				putdcc $idx "É um feed Atom."
				set allitems [encmatches $feed "<entry" "</entry>"]
				if {[llength $allitems]>0} {
					set data [lindex [encmatches [lindex $allitems 0] "<published>" "</published>"] 0]
					if {$data==""} {
						putdcc $idx "Parece que não há um único <published>. Vou utilizar o formato pré-definido na mesma."
						set formato "%Y-%m-%dT%H:%M:%SZ"
					} else {
						set encontradoformato 0
						foreach formato [list "%Y-%m-%dT%H:%M:%SZ" "%Y-%m-%d %H:%M:%S" "%a, %d %b %Y %H:%M:%S %Z" "%Y-%m-%dT%H:%M:%S+00:00"] {
							if {[catch {clock scan $data -format $formato} erro]} {
								#putdcc $idx "Este não serve: $formato"
								continue
							}
							putdcc $idx "O formato da data é: $formato"
							set encontradoformato 1
							break
						}
						if {$encontradoformato==0} {
							putdcc $idx "O formato apropriado não foi encontrado. O formato pré-definido irá ser adicionado e é preciso alterar o formato mais tarde."
							set formato "%Y-%m-%dT%H:%M:%SZ"
						}
					}
					lappend rss($id) "activo" 1 "canal" [if {$canal==""} {set canal "#code"} {set canal}] "fmtdata" $formato "link" "$link" "logo" [if {$logo==""} {set logo "\002$id\002"} {set logo $logo}] "quando" [if {$quando==""} {set quando "*:00"} {set quando}] "vezes" "3"
				}
			}


			putdcc $idx "\002$id\002 adicionado com sucesso."
		}
		"eliminar" {
			#>eliminar <feed>
			if {$arg2==""} {
				putdcc $idx "<id>"
				return
			}
			if {[array names rss]==""} {
				putdcc $idx "Não é possível eliminar seja o que for porque não há itens para serem eliminados."
				return
			}
			if {[lsearch [array names rss] $arg2]<0} {
				putdcc $idx "Esse id não existe."
				putdcc $idx "Tem de ser um de: [lsort -dictionary [array names rss]]"
				return
			}
			unset rss($arg2)
			putdcc $idx "\002$arg2\002 eliminado."
		}
		default {
			putdcc $idx "COMANDO NÃO RECONHECIDO: $arg1"
			return
		}
	}

	file mkdir rsscfgbackups
	file copy -force rss.cfg rsscfgbackups/rss.cfg.[strftime "%d-%b-%Y-%H-%M-%S"]

	set fp [open rss.cfg w+]

	#o cabeçalho do ficheiro a informar quando foi o ficheiro criado
	puts $fp "#Este ficheiro foi gerado às [string map {
		January Janeiro February Fevereiro March Março April Abril May Maio June Junho
		July Julho August Agosto September Setembro October Outubro November Novembro December Dezembro
		} [strftime "%d/%B/%Y %H:%M:%S"]]\n"
	
	#grupo do array opcoes
	set copt [expr max([join [lmap word [split [array names opcoes]] {string length $word}] ","])]
	foreach opcao [lsort -dictionary [array names opcoes]] {
		puts $fp [format "%-*s %-*s" \
			[expr 12+$copt] "set opcoes($opcao)" \
			[string length $opcoes($opcao)] [if {[string is boolean $opcoes($opcao)]} {set a $opcoes($opcao)} {set a "\"$opcoes($opcao)\""}]]
	}

	puts $fp ""

	#grupo do array rss
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


proc convdata {data formato} {
#putlog ">$data< >$fomato<"
	#workaround para o "aberto até de madrugada"
	#2024-09-06T17:30:00.114+01:00
	if {[string match "*-*-*T*:*:*.*+*:*" $data]} {
		set data [string replace $data 26 26]
		set data [string replace $data 19 22 " "]
	}
	#
	if {[catch {set novadataformatada [string map {Sun Dom Mon Seg Tue Ter Wed Qua Thu Qui Fri Sex Sat Sáb Feb Fev Apr Abr May Mai Aug Ago Sep Set Oct Out Dec Dez} [clock format [clock scan $data -format $formato] -format "%a,%d/%b/%Y %H:%M:%S"]]} erro]} {
		putlog "\0038Erro! A data fornecida não pode coincide com o formato de data indicado. Tem de fazer alteração manual."
		putlog "\0038  DATA:     >$data<"
		putlog "\0038  FORMATO:  >$formato<"
		putlog "\0038  SUGERIDO: >[adividata $data]<"
		set novadataformatada "N/A"
	}
	return $novadataformatada
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



proc rss {min hor dia mes ano} {
	global bufffeeds

	set enchercache 0
	if {![info exist bufffeeds]} {
		set bufffeeds ""
		set enchercache 1
		set ttime [clock milliseconds]
	}

	if {![file exist rss.cfg]} {
		putlog "O ficheiro rss.cfg não existe."
		return
	}

	source rss.cfg

	set totalrss [llength [array names rss]]
	set posicaorss 0
	foreach itemrss [array names rss] {
		incr posicaorss
		foreach {var valor} $rss($itemrss) {
			set [subst $var] $valor
		}

		if {[lsearch -nocase [channels] $canal]==-1} {
			channel add $canal
			update
		}

		if {!$activo} {
			continue
		}
		foreach iquando [split $quando ","] {
			
			if {![string match $iquando "$hor:$min"] && !$enchercache} {
				continue
			}

			set ffeeds [obtertdl $link $logo $itemrss $fmtdata $opcoes(urldebug) $opcoes(usartinyurl) [if {$enchercache} {set a "[format "%4s | " "[expr round((double($posicaorss)/$totalrss)*100)]%"]"}]]
			foreach iffeed $ffeeds {
				if {[lsearch $bufffeeds [string map {\[ \\\[ \] \\\]} $iffeed]]<0} {
					if {!$enchercache} {
						foreach ichannel [split $canal ","] {
							if {[lsearch -nocase $opcoes(canaistinyurlforcado) $ichannel]>=0} {
								if {[string first "https://tinyurl.com" $iffeed]<0} {
									putquick "privmsg $ichannel :[string range $iffeed 0 [string last " " $iffeed]][tinyurl [lindex $iffeed end]]"
								} else {
									putquick "privmsg $ichannel :$iffeed"
								}
							} else {
								putquick "privmsg $ichannel :$iffeed"
							}
						}
					}
					lappend bufffeeds $iffeed
				}
			}
		}

		foreach ichannel [split $canal ","] {
			if {[lsearch -nocase $opcoes(canaisignorartopico) $ichannel]<0} {
				if {![info exists topic($ichannel)]} {
					set topic($ichannel) "Bem-vindo ao \002$ichannel\002 || Triggers disponíveis: "
				}
				if {[lsearch $topic($ichannel) $itemrss]<0} {
					lappend topic($ichannel) "\037.$itemrss\037"
				}
			}
		}

	}
	bind time - "* * * * *" rss
	if {$enchercache} {
		putlog "Operação de recriação demorou [expr (double([clock milliseconds])-$ttime)/1000] segundos."
	}
	foreach canal [array names topic] {
		if {[topic $canal]!=$topic($canal)} {
			if {![isop $::botnick $canal]} {
				putlog "#!# Não tenho op no canal $canal e não me é possível mudar o tópico."
				continue
			}
			#putlog "comando topic >[topic $canal]<"
			#putlog "topico gerado >$topic($canal)<"
			#putlog "comparacao    >[string match [topic $canal] $topic($canal)]<"
			putserv "TOPIC $canal :$topic($canal)"
		}
	}

}

if {![info exist bufffeeds]} {
	utimer 60 {rss 0 0 0 0 0}
}

proc obtertdl {link logo itemrss fmtdata urldebug usartinyurl {progress ""}} {
	set ttime [clock milliseconds]
	package require htmlparse

	set feed ""
	set outfeed ""
	if {$urldebug} {
		putlog "$progress\017ID: $itemrss | Obter $link ..."
	}
	if {[catch {set feed [exec links -source $link]} erro]} {
		putlog "\00307RSS: Ocorreu um erro a aceder a $link: $erro"
		return
	}

	if {[string length $feed]==0} {
		putlog "\00307RSS: Parece que $link náo tem nada."
		return
	}

	if {[string first "encoding=\"ISO-8859-1\"" $feed]>0} {
		#Visto que ainda não se conhece maneira de converter iso8859-1 para utf-8 no tcl9, usar iconv
		set feed [exec links -source $link | iconv -f iso8859-1 -t utf-8]
	}

	#set feed [string map {"<!\[CDATA\[" "" "]]>" ""} $feed]
	regsub -all {<title\s*[^>]*>} $feed "<title>" feed
	set feed [htmlparse::mapEscapes $feed]

	set feed [string map {"<!\[CDATA\[" "" "]]>" ""} $feed]

	set allitems [lreverse [encmatches $feed "<item" "</item>"]]
	#atom
	if {$allitems==""} {
		set allitems [lreverse [encmatches $feed "<entry" "</entry>"]]
	}
	foreach sitem $allitems {
		set titulo [string trim [htmlparse::mapEscapes [lindex [encmatches $sitem "<title>" "</title>"] 0]]]
		if {[string match "*POKÉMON FULL EPISODE*Season*" $titulo]} {
			regexp {<media:description>(.*?)\n\n} $sitem -> descep
			set descep [string map {\n ""} $descep]
			set titulo "\0038,12\002\002 $titulo \003 $descep"
		}
		set link [lindex [encmatches $sitem "<link>" "</link>"] 0]
		if {$link==""} {
			set link [lindex [encmatches $sitem "<id>" "</id>"] 0]
		}
		
		#Excepção. Links não começam com tag:
		if {[string match "tag:*" $link]} {
			regexp {<link rel='alternate' type='text/html' href='(.*?)' } $sitem -> link
		}

		#Excepção: substituir yt:: pela parte inicial do link deixado pelo <id>
		set link [string map {yt:video: https://youtu.be/} $link]
		#######################################

		set data [lindex [encmatches $sitem "<pubDate>" "</pubDate>"] 0]
		if {$data==""} {
			set data [lindex [encmatches $sitem "<published>" "</published>"] 0]
		}

#putdcc 5 ">$titulo<"
#putdcc 5 ">$link<"
#putdcc 5 ">$data<"

		lappend outfeed "[subst $logo] [string map {"<em>" "\035" "</em>" "\035"} $titulo] \017[if {$data!=""} {set a "([convdata $data $fmtdata]) "}][if {$usartinyurl} {set a [tinyurl $link]} {set link}]"

	}
	putserv "PONG :[lindex [split $::server ":"] 0]"
	if {$urldebug} {
		putlog "Terminou:[if {[llength $outfeed]==0} {set a "\00314"}] [llength $outfeed] elemento[if {[llength $outfeed]!=1} {set a "s"}]; [expr (double([clock milliseconds])-$ttime)/1000] segundos "
	}
	set outfeed
}


proc chrss {nick host handle chan text} {
	global bufffeeds
	source rss.cfg
	set arg1 [lindex $text 0]
	set arg2 [lindex $text 1]
	set arg3 [lindex $text 2]

	set out ""
	foreach itemrss [lsort [array names rss]] {
		if {[dict get $rss($itemrss) activo]} {
			if {[lsearch -nocase [dict get $rss($itemrss) canal] $chan]!=-1} {
				lappend out $itemrss
			}
		}
	}
	set swout [string map {" " " - "} $out]

	switch $arg1 \
		{*}$swout {
			set chaves $arg2
			if {$arg2=="*"} {
				set chaves [dict keys $rss($arg1)]
			}
			foreach chave $chaves {
				if {[catch {set result [dict get $rss($arg1) $chave]} erro]} {
					if {[string match "key \"*\" not known in dictionary" $erro]} {
						putquick "privmsg $chan :A chave \002$chave\002 não é conhecida no dicionário."
						return
					}
					#outro erro
					putquick "privmsg $chan :>$erro"
					return
				}
				putquick "privmsg $chan :$chave = $result"
			}
		} \
		"status" - "estado" {
			putquick "privmsg $chan :RSS $::rssbuild | Tamanho da cache: [llength $bufffeeds] ite[if {[llength $bufffeeds]==1} {set a "m"} {set a "ns"}] ([string bytelength $bufffeeds] bytes); Nº de feeds: [llength [array names rss]]"
		} \
		"guardar" - "guardarordenado" {
			set fich "bufffeeds[strftime "%Y%m%d-%H%M%S"].txt"
			set gbufffeeds bufffeeds
			if {$arg1=="guardarordenado"} {
				set gbufffeeds [lsort -dictionary $bufffeeds]
			}
			set fp [open $fich w+]
			foreach ifeed $gbufffeeds {
				puts $fp $ifeed
			}
			close $fp
			putquick "privmsg $chan :$fich criado."
		} \
		"" {
			if {$out==""} {
				set out "Nada definido."
			} else {
				putquick "privmsg $chan :$out"
			}
		} \
		default {
			putquick "privmsg $chan :Comando não conhecido: $arg1"
			putquick "privmsg $chan :Comandos disponíveis: status estado guardar guardarordenado"
		}
	
}

proc adividata {datestr} {
    # Common patterns
    set patterns {
		{%a, %d %b %Y %H:%M:%S %z} {^[A-Z][a-z][a-z], \d{1,2} [A-Z][a-z][a-z] \d{4} \d{2}:\d{2}:\d{2} [+-]\d{4}$}
        {%Y-%m-%d} {^\d{4}-\d{2}-\d{2}$}
        {%d/%m/%Y} {^\d{1,2}/\d{1,2}/\d{4}$}
	}
        #{%H:%M} {^\d{1,2}:\d{2}$}
        #{%H:%M:%S} {^\d{1,2}:\d{2}:\d{2}$}

    foreach {fmt regex} $patterns {
        if {[regexp $regex $datestr]} {
            return $fmt
        }
    }

    return "Desconhecido"
}
putlog "RSS FEEDS"
#002 bold
#003 cor
#017 texto normal
#026 reverse
#037 underline
#035 italico
