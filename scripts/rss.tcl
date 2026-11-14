
set rssbuild "14-Novembro-2026"
#moonlight

bind pubm - "* .*" rsstrig
bind dcc - "rss" dccrss
bind pub - ".rss" chrss

#################
################

proc rssminfo {idx texto} {
	catch {putdcc $idx " (i) $texto"}
}

proc rssmerro {idx texto} {
    putdcc $idx " (x) $texto"
}

proc rssmaviso {idx texto} {
    putdcc $idx " /!\\ $texto"
}

######
######

# devolve 0 se a string não está no ficheiro, devolve 1 se estiver
proc rsspesqlinha {filename searchString} {
    if {![file exists $filename]} {
        set fh [open $filename w+]
		close $fh
    }
	set fh [open $filename r]
    set found 0
    while {[gets $fh line] >= 0} {
        if {[string first $searchString $line] != -1} {
            set found 1
            break
        }
    }
    close $fh
    return $found
}

proc search {filename pattern {max_matches 5} {chunk_size 4096}} {
    set matches [list]
    
    if {![file exists $filename]} {
        return -code error "File not found: $filename"
    }
    
    set fd [open $filename r]
    set file_size [file size $filename]
    set pos $file_size
    set leftover ""
    
    # Loopa para trás pelo ficheiro aos bocados
    while {$pos > 0 && [llength $matches] < $max_matches} {
        # Calcula o avanço e comprimento para bocado seguinte a partir do fim
        if {$pos >= $chunk_size} {
            incr pos -$chunk_size
            set read_len $chunk_size
        } else {
            set read_len $pos
            set pos 0
        }
        
        # Move o ponteiro do ficheiro e lê o bocado
        seek $fd $pos start
        set chunk [read $fd $read_len]
        
        # Combina com quaisquer fragmentos de restos a partir do bocado anterior
        set data "$chunk$leftover"
        set lines [split $data "\n"]
        
        if {$pos > 0} {
            set leftover [lindex $lines 0]
            set lines [lrange $lines 1 end]
        } else {
            set leftover ""
        }
        
        set num_lines [llength $lines]
        for {set i [expr {$num_lines - 1}]} {$i >= 0} {incr i -1} {
            set line [lindex $lines $i]
            set line [string trimright $line "\r"]
            
            if {[string match "*$pattern*" $line]} {
                lappend matches $line
                if {[llength $matches] >= $max_matches} {
                    break
                }
            }
        }
    }
    
    if {[llength $matches] < $max_matches && $leftover ne ""} {
        set line [string trimright $leftover "\r"]
        if {[string match "*$pattern*" $line]} {
            lappend matches $line
        }
    }
    
    close $fd
    return $matches
}

####

package require tls
package require http

proc ytduration {url} {
  # Extrai os 11 caracteres do id do video
  if {![regexp -nocase -- {(?:youtube\.com\/(?:[^\/\n\s]+\/\S+\/|(?:v|e(?:mbed)?)\/|\S*?[?&]v=)|youtu\.be\/)([a-zA-Z0-9_-]{11})} $url match youtubeid]} {
    return "Invalid YouTube URL"
  }

  ::http::register https 443 [list tls::socket -servername "www.youtube.com"]
  
  set watch_url "https://www.youtube.com/watch?v=${youtubeid}"
  if {[catch {set tok [::http::geturl $watch_url -headers {User-Agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"} -timeout 5000]} err]} {
    ::http::unregister https
    return "Error: $err"
  }
  
  set watch_data [::http::data $tok]
  ::http::cleanup $tok
  ::http::unregister https

  
  if {[regexp {"isLiveContent"\s*:\s*true} $watch_data] || [regexp {"isLive"\s*:\s*true} $watch_data]} {
    return "LIVE"
  }

  # Extrai a duração em segundos e formata-os
  if {[regexp {"lengthSeconds"\s*:\s*"(\d+)"} $watch_data match secs]} {
    set h [expr {$secs / 3600}]
    set m [expr {($secs % 3600) / 60}]
    set s [expr {$secs % 60}]
    
    set res ""
    if {$h > 0} { lappend res "${h}h" }
    if {$m > 0} { lappend res "${m}m" }
    if {$s > 0 || ($h == 0 && $m == 0)} { lappend res "${s}s" }
    return [join $res " "]
  }

  return "N/A"
}
#####
#####

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
				if {[string match *https://www.youtube.com/watch* $iffeed]} {
					set iffeed "$iffeed  \[[ytduration [lindex $iffeed end]]\]"
				}
				putquick "privmsg $chan :> $iffeed"
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
	set opcoes(dirrss) "rss/"
	set opcoes(canaisignorartopico) ""
	set opcoes(canaistinyurlforcado) ""

	#analisar o input
	set arg1 [lindex [split $text] 0]
	if {$arg1!=""} {
		set arg2 [string trim [string range $text [string length $arg1]+1 end]]
	}

	if {![file exists rss.cfg]} {
		set fp [open rss.cfg w+]
		close $fp
	}

	source rss.cfg

	switch [string tolower $arg1] {
		"novo" {
			putlog "RSS: Regenerar rss.cfg ..."
			# Deixado propositadamente vazio de comandos
		}
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
			#>listar \[campos:campo1,campo2,...\] \[id:id\] \[act:act\] \[link:link\] \[dmt:fmt\] \[quando:quando\]
			set defcampos "activo,id,canal,quando,link"
			if {[array names rss]==""} {
				rssmerro $idx "Não há nada para mostrar."
				return
			}

			set idsel [lindex [split [lsearch -inline $text id:*] :] 1]
			if {$idsel==""} {set idsel "*"}
			set activosel [lindex [split [lsearch -inline $text act:*] :] 1]
			if {$activosel==""} {set activosel "*"}
			set canalsel [lindex [split [lsearch -inline $text canal:*] :] 1]
			if {$canalsel==""} {set canalsel "*"}
			set fmtdatasel [lindex [split [lsearch -inline $text fmt:*] :] 1]
			if {$fmtdatasel==""} {set fmtdatasel "*"}
			set linksel [lindex [split [lsearch -inline $text link:*] :] 1]
			if {$linksel==""} {set linksel "*"}
			set logosel [lindex [split [lsearch -inline $text logo:*] :] 1]
			if {$logosel==""} {set logosel "*"}
			set quandosel [lindex [split [lsearch -inline $text quando:*] :] 1]
			if {$quandosel==""} {set quandosel "*"}
			set vezessel [lindex [split [lsearch -inline $text vezes:*] :] 1]
			if {$vezessel==""} {set vezessel "*"}

			set campossel [lindex [split [lsearch -inline $text campos:*] :] 1]
			if {$campossel==""} {set campossel $defcampos}

			set lid [list {Nome do ID}]
			set lactivo "☐"
			set lcanal "Canal"
			set llink "Link"
			set llogo "Logo"
			set lquando "Quando"
			set lvezes "Vezes"

			foreach itemrss [lsort -dictionary [array names rss]] {
				foreach {var valor} $rss($itemrss) {
					set [subst $var] $valor
				}
				if {[string match *$idsel* $itemrss] && \
					[string match *$activosel* $activo] && \
					[string match *$canalsel* $canal] && \
					[string match *$fmtdatasel* $fmtdata] && \
					[string match *$linksel* $link] && \
					[string match *$logosel* $logo] && \
					[string match *$quandosel* $quando] && \
					[string match *$vezessel* $vezes]} {
					lappend lid $itemrss
					lappend lactivo [if {$activo} {set a "✓"} {set a "✕"}]
					lappend lcanal $canal
					lappend lfmtdata $fmtdata
					lappend llink $link
					lappend llogo $logo
					lappend lquando $quando
					lappend lvezes $vezes 
				}
			}
			if {[llength $lid]==1} {
				rssmerro $idx "Não há resultados para apresentar."
				return
			}
			set compid [expr max([join [lmap word [split $lid] {string length $word}] ","])]
			set compactivo [expr max([join [lmap word [split $lactivo] {string length $word}] ","])]
			set compcanal [expr max([join [lmap word [split $lcanal] {string length $word}] ","])]
			set compfmtdata [expr max([join [lmap word [split $lfmtdata] {string length $word}] ","])]
			set complink [expr max([join [lmap word [split $llink] {string length $word}] ","])]
			set complogo [expr max([join [lmap word [split $llogo] {string length $word}] ","])]
			set compquando [expr max([join [lmap word [split $lquando] {string length $word}] ","])]
			set compvezes [expr max([join [lmap word [split $lvezes] {string length $word}] ","])]

			set sformat " "
			set aformat [list]
			foreach campo [split $campossel ,] {
				append sformat "%-\$\{comp$campo\}s  "
				lappend aformat "\[lindex \$l${campo} \$indx\]"
			}

			for {set indx 0} {$indx<[llength $lid]} {incr indx } {
				putdcc $idx "[if {$indx==0} {set a \037}][format [subst $sformat]  {*}[subst $aformat] ]"
			}

			return
		}
		"agendado" {
			#>agendado [h:hora] [c:canal]
			if {[array names rss]==""} {
				rssmerro $idx "Não há nada para mostrar."
				return
			}
			set horasel [lindex [split [lsearch -inline $text h:*] :] 1]
			set canalsel [lindex [split [lsearch -inline $text c:*] :] 1] 
			if {$horasel!=""} {
				scan $horasel %d horasel 
			}
			if {$canalsel!=""} {
				if {[lsearch -nocase [channels] $canalsel]<0} {
					rssmerro $idx "Não estou no $canalsel. Tenta um destes: [channels]"
					return
				}
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
					if {!$activo} {
						continue
					}
					foreach iquando [split $quando ,] {
						if {[string match $iquando $ihm]} {
							if {$canalsel=="" || [string tolower $canal]==[string tolower $canalsel]} {
								lappend hm($ihm) $itemrss\xA0->\xA0$canal
							}
						}
					}
				}
			}

			if {$horasel==""} {
				lappend hmrange [clock format [clock scan "3 minutes ago"] -format %H:%M]
				lappend hmrange [clock format [clock scan "2 minutes ago"] -format %H:%M]
				lappend hmrange [clock format [clock scan "1 minutes ago"] -format %H:%M]
				lappend hmrange [clock format [clock seconds] -format %H:%M]
				lappend hmrange [clock format [clock scan "1 minutes"] -format %H:%M]
				lappend hmrange [clock format [clock scan "2 minutes"] -format %H:%M]
				lappend hmrange [clock format [clock scan "3 minutes"] -format %H:%M]
				lappend hmrange [clock format [clock scan "4 minutes"] -format %H:%M]
			} else {
				if {$horasel<0 || $horasel>23} {
					rssmerro $idx "A hora tem de ser entre 0 e 23 inclusivé."
					return
				}
				for {set m 0} {$m<=59} {incr m} {
					lappend hmrange [format "%02d:%02d" $horasel $m]
				}
			}
			set ccol "9 0 0 0 0 0 0 0 0 0"
			foreach ihmrange $hmrange {
				set indx 0
				foreach item $hm($ihmrange) {
					incr indx
					if {[string length $item]>[lindex $ccol $indx]} {
						lset ccol $indx 0 [string length $item]
					}
				}
			}
			foreach iccol $ccol {
				if {$iccol!=0} {
					append tformat "%-${iccol}s  "
				}
			}
			set nelems [llength $tformat]
#putdcc $idx $tformat
			foreach ihmrange $hmrange {
				set cols [string trim "$hm($ihmrange) [string repeat "- " [expr $nelems-[llength $hm($ihmrange)]-1]]"]
				set out [string trimright [format $tformat [if {$ihmrange==[strftime %H:%M]} {set a "<\[$ihmrange\]>"} {set a "  $ihmrange  "}] {*}$cols]]
				if {[string match -nocase *#YouTube*#YouTube* $out]} {
					set out [string replace $out 0 0 !]
				}
				putdcc $idx $out
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
			rssminfo $idx "\002$chave\002 alterado de \002$antes\002 para \002$valor\002."

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
					   		rssminfo $idx "\002$opcao\002 está desactivado."
					   	} else {
						   	rssminfo $idx "\002opcao\002 está activado."
					   	}
					   	return
				   	} else {
						if {![string is boolean $valopcao]} {
							rssmaviso $idx ".rss opções $opcao <0|1>"
							return
						} else {
							set valorantigo $opcoes($opcao)
							if {$valorantigo==$valopcao} {
								rssminfo $idx "$opcao já é $valorantigo"
								return
							}
							set opcoes($opcao) $valopcao
							rssminfo $idx "$opcao alterada de $valorantigo para $opcoes(urldebug)"
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
				   	rssmerro $idx "Não conheço -> $opcao"
				   	return
				}
			
			#putdcc $idx "OK"
		}
		"adicionar" {
			#>adicionar <link> <id> <canal> <quando> <logo>
			if {$arg2==""} {
				rssminfo $idx "Síntaxe: <link> \[id\] \[canal\] \[quando\] \[logo\]"
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
				rssmaviso $idx "A alterar link para \002$link\002"
				regexp {<title>(.*?) - YouTube</title>} $yhtml -> ologo
				set logo "\002$ologo\002"
				rssmaviso $idx "A definir logo para $logo"
			}

			if {![string match *:* $quando]} {
				rssmerro $idx "'quando' tem de ter o formato hh:mm, como 12:34 *:34 1*:34 12:*4 12:* ou 12:34,23:45"
				return
			}

			if {[catch {set feed [exec links -source $link]} erro]} {
				rssmerro $idx "$erro"
				return
			}

			if {$id==""} {
				regexp {www\.(.*?)\.} $link -> id
				if {$id==""} {
					regexp {\://\.(.*?)\.} $link -> id
				}
			}

			if {[string first "<item>" $feed]>0} {
				rssminfo $idx "É um feed rss."
				set allitems [encmatches $feed "<item" "</item>"]
				if {[llength $allitems]>0} {
					set data [lindex [encmatches [lindex $allitems 0] "<pubDate>" "</pubDate>"] 0]
					if {$data==""} {
						rssmaviso $idx "Parece que não há um único <pubDate>. Vou utilizar o formato pré-definido na mesma."
						set formato "%a, %d %b %Y %H:%M:%S %Z"
					} else {
						set encontradoformato 0
						foreach formato [list "%Y-%m-%d %H:%M:%S" "%a, %d %b %Y %H:%M:%S %Z" "%Y-%m-%dT%H:%M:%S+00:00"] {
#putdcc $idx ">$data<"
							if {[catch {clock scan $data -format $formato} erro]} {
								#putdcc $idx "Este não serve: $formato"
								continue
							}
							rssminfo $idx "O formato da data é: $formato"
							set encontradoformato 1
							break
						}
						if {$encontradoformato==0} {
							rssminfo $idx "O formato apropriado não foi encontrado. O formato genérico irá ser adicionado e é preciso alterar o formato mais tarde."
							set formato "%a, %d %b %Y %H:%M:%S %Z"
						}
					}
					lappend rss($id) "activo" 1 "canal" [if {$canal==""} {set canal "#code"} {set canal}] "fmtdata" $formato "link" "$link" "logo" [if {$logo==""} {set logo "\002$id\002"} {set logo $logo}] "quando" [if {$quando==""} {set quando "*:00"} {set quando}] "vezes" "3"
				}
			}
			
			if {[string first "<entry>" $feed]>0} {
				rssminfo $idx "É um feed Atom."
				set allitems [encmatches $feed "<entry" "</entry>"]
				if {[llength $allitems]>0} {
					set formato ""
					foreach campodata {published updated} {
						set data [lindex [encmatches [lindex $allitems 0] "<$campodata>" "</$campodata>"] 0]
						if {$data!=""} {
							foreach formato [list "%Y-%m-%dT%H:%M:%SZ" "%Y-%m-%d %H:%M:%S" "%a, %d %b %Y %H:%M:%S %Z" "%Y-%m-%dT%H:%M:%S+00:00"] {
								if {[catch {clock scan $data -format $formato} erro]} {
									#putdcc $idx "Este não serve: $formato"
									continue
								}
								break
							}
							if {$formato==""} {
								rssmaviso $idx "O formato apropriado não foi encontrado. O formato pré-definido irá ser adicionado e é preciso alterar o formato mais tarde."
								set formato "%Y-%m-%dT%H:%M:%SZ"
							}
							rssminfo $idx "O campo <$campodata>> foi encontrado. O formato é $formato."
							break
						}
					}
					if {$formato==""} {
						rssmaviso $idx "Não foi possível determinar o formato. Vou utilizar o formato por defeito na mesma."
						set formato "%Y-%m-%dT%H:%M:%SZ"
					}
					lappend rss($id) "activo" 1 "canal" [if {$canal==""} {set canal "#code"} {set canal}] "fmtdata" $formato "link" "$link" "logo" [if {$logo==""} {set logo "\002$id\002"} {set logo $logo}] "quando" [if {$quando==""} {set quando "*:00"} {set quando}] "vezes" "3"
				}
			}


			rssminfo $idx "\002$id\002 adicionado com sucesso."
		}
		"eliminar" {
			#>eliminar <feed>
			if {$arg2==""} {
				rssminfo $idx "Síntaxe: eliminar <id>"
				return
			}
			if {[array names rss]==""} {
				rssmerro $idx "Não é possível eliminar seja o que for porque não há itens para serem eliminados."
				return
			}
			if {[lsearch [array names rss] $arg2]<0} {
				rssmerro $idx "Esse id não existe."
				rssmerro $idx "Tem de ser um destes: [lsort -dictionary [array names rss]]"
				return
			}
			unset rss($arg2)
			rssminfo $idx "\002$arg2\002 eliminado."
		}
		default {
			rssmerro $idx "COMANDO NÃO RECONHECIDO: $arg1"
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
	set compopt [expr 13+max([join [lmap word [split [array names opcoes]] {string length $word}] ","])]

	puts $fp "#Secção das opções\n"
	set copt 0
	set crss 0

	foreach opcao [lsort -dictionary [array names opcoes]] {
		switch $opcoes($opcao) {
			0 - 1   {puts $fp [format "%-*s %-*s" $compopt "set opcoes($opcao)" 0 $opcoes($opcao)]}
            default {puts $fp [format "%-*s %-*s" $compopt "set opcoes($opcao)" 0 \"$opcoes($opcao)\"]}
		}
		incr copt
	}

	puts $fp "\n#Secção dos feeds rss\n"

	#grupo do array rss
	foreach id [lsort -dictionary [array names rss]] {
		puts $fp "set rss($id) \{"
		foreach chave [lsort [dict keys $rss($id)]] {
			puts $fp "\t$chave\t\"[string map {\002 \\002 \003 \\003 \026 \\026 \037 \\037} [dict get $rss($id) $chave]]\""
		}
		puts $fp "\}\n"
		incr crss
	}
	puts $fp "\n# Fim do ficheiro rss.cfg"

	close $fp
	rssminfo $idx "Ficheiro rss.cfg guardado. $copt opções e $crss feeds rss."
}


proc convdata {data formato {itemrss "N/A"}} {
#putlog ">$data< >$fomato<"
	#workaround para o "aberto até de madrugada"
	#2024-09-06T17:30:00.114+01:00
	if {[string match "*-*-*T*:*:*.*+*:*" $data]} {
		set data [string replace $data 26 26]
		set data [string replace $data 19 22 " "]
	}
	#
	if {[catch {set novadataformatada [string map {Sun Dom Mon Seg Tue Ter Wed Qua Thu Qui Fri Sex Sat Sáb Feb Fev Apr Abr May Mai Aug Ago Sep Set Oct Out Dec Dez} [clock format [clock scan $data -format $formato] -format "%a,%d/%b/%Y %H:%M:%S"]]} erro]} {
		putlog "\0038O formato da data do feed $itemrss tem de ser alterado."
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

	if {$::rssencher} {
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
			
			if {![string match $iquando "$hor:$min"] && !$::rssencher} {
				continue
			}

			set ffeeds [obtertdl $link $logo $itemrss $fmtdata $opcoes(urldebug) $opcoes(usartinyurl) [if {$::rssencher} {set a "[format "%4s | " "[expr round((double($posicaorss)/$totalrss)*100)]%"]"}]]
			foreach iffeed $ffeeds {
				if {[string match *https://www.youtube.com/watch* $iffeed]} {
					for {set a 1} {$a<6} {incr a} {
						set duracao [ytduration [string range $iffeed [string last " " $iffeed]+1 end]]
						if {$duracao!="N/A"} {
							break
						}
					}
					set iffeed "$iffeed  \[$duracao\]"
				}
				if {![rsspesqlinha $opcoes(dirrss)$itemrss $iffeed]} {
					if {!$::rssencher} {
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
					#lappend bu#fffeeds $iffeed
					# novo
					set ifilerss [open $opcoes(dirrss)$itemrss a]
					puts $ifilerss $iffeed
					close $ifilerss
				}
			}
		}

		foreach ichannel [split $canal ","] {
			if {[lsearch -nocase $opcoes(canaisignorartopico) $ichannel]<0} {
				if {![info exists topic($ichannel)]} {
					set topic($ichannel) "Bem-vindo/a ao \002$ichannel\002 || Feeds: "
				}
				if {[lsearch $topic($ichannel) $itemrss]<0} {
					lappend topic($ichannel) ".$itemrss"
				}
			}
		}

	}
	bind time - "* * * * *" rss
	if {$::rssencher} {
		putlog "Operação de recriação demorou [expr (double([clock milliseconds])-$ttime)/1000] segundos."
		set ::rssencher 0
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

######

if {![info exist rssencher]} {
	set rssencher 1

	# criar o ficheiro rss.cfg na raiz do bot se não existir
	dccrss 0 0 "novo"

	# Fprçar descarregar os feeds
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
		foreach {campo1 campo2} {<link> </link> "<link rel='alternate' type='text/html' href='" "' title=" "<link " /> <id> </id>} {
			set link [lindex [encmatches $sitem $campo1 $campo2] 0]
			if {$link!=""} {
				if {$campo1=="<link "} {
					regexp {href="([^"]+)"} $link -> link
				}
				break
			}
		}

		#Excepção. Links não começam com tag:
		if {[string match "tag:*" $link]} {
			regexp {<link rel='alternate' type='text/html' href='(.*?)' } $sitem -> link
		}

		#Excepção: substituir yt:: pela parte inicial do link deixado pelo <id>
		set link [string map {yt:video: https://youtu.be/} $link]
		#excepção para o github
		#if {[string match * $link]} {}
		#######################################

		foreach campodata {pubDate published updated} {
			set data [lindex [encmatches $sitem "<$campodata>" "</$campodata>"] 0]
			if {$data!=""} {
				break
			}
		}
		

#putdcc 5 ">$titulo<"
#putdcc 5 ">$link<"
#putdcc 5 ">$data<"

		lappend outfeed "[subst $logo] [string map {"<em>" "\035" "</em>" "\035"} $titulo] \017[if {$data!=""} {set a "([convdata $data $fmtdata $itemrss]) "}][if {$usartinyurl} {set a [tinyurl $link]} {set link}]"

	}
	putserv "PONG :[lindex [split $::server ":"] 0]"
	if {$urldebug} {
		putlog "Terminou:[if {[llength $outfeed]==0} {set a "\00314"}] [llength $outfeed] elemento[if {[llength $outfeed]!=1} {set a "s"}]; [expr (double([clock milliseconds])-$ttime)/1000] segundos "
	}
	set outfeed
}


proc chrss {nick host handle chan text} {
	source rss.cfg
	set arg1 [lindex $text 0]
	set arg2 [lindex $text 1]
	set arg3 [lindex $text 2]

	set lids ""
	foreach itemrss [lsort [array names rss]] {
		if {[dict get $rss($itemrss) activo]} {
			if {[lsearch -nocase [dict get $rss($itemrss) canal] $chan]!=-1} {
				lappend lids $itemrss
			}
		}
	}
	set swlids [string map {" " " - "} $lids]

	switch $arg1 \
		{*}$swlids {
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
			return
		} \
		"status" - "estado" {
			putquick "privmsg $chan :RSS $::rssbuild | Nº de feeds: [llength [array names rss]]"
			putquick "privmsg $chan :Localização dos ficheiros: $opcoes(dirrss)"
			set total 0
			foreach fich [glob $opcoes(dirrss)*] {
				set total [expr $total+[file size $fich]]
			}
			putquick "privmsg $chan :Espaço ocupado em disco: $total bytes."
			return
		} \
		"pesq" {
			set pesq " [string range $text 5 end] "
			#putquick "privmsg $chan :q:>$pesq<"

			set idpedido ""
			set pagina 1
			set pagpedida 1
			set resporpag 5

			regexp {rss:(.*?) } $pesq -> idpedido 
			regexp {pag:(.*?) } $pesq -> pagpedida
			regsub -all {\s*rss:\S+} $pesq "" pesq
			regsub -all {\s*pag:\S+} $pesq "" pesq

			set pesq [string trim $pesq]
			if {$pesq==""} {
				putquick "privmsg $chan :Tenta .rss pesq termo1 termo2..."
				return
			}
			#putquick "privmsg $chan :$pesq"
			#putquick "privmsg $chan :$idpedido"
			if {$idpedido==""} {
				set lidspedidos $lids
			} else {
				set lidspedidos $idpedido
			}

			set pesq [string map {" " *} $pesq]
			set lista ""

			foreach id $lidspedidos {
				if {[lsearch -nocase $lids $id]<0} {
					putquick "privmsg $chan :\002$id\002 não é deste canal. Vê .rss"
					return
				}
				foreach strfound [search $opcoes(dirrss)$id $pesq 200000] {
					lappend lista $strfound
				}
			}
			if {$lista==""} {
				putquick "privmsg $chan : :(  Nada foi encontrado."
			} else {
				set cont 0

				if {$pagpedida==""} {
					set pagpedida $pagina
				} else {
					if {![string is digit $pagpedida]} {
						putquick "privmsg $chan :A página tem de ser um número."
						return
					}
					if {$pagpedida<1 || $pagpedida>[expr 1+[llength $lista]/$resporpag]} {
						putquick "privmsg $chan :A página que estás a pedir, tem de ser entre 1 e [expr 1+[llength $lista]/$resporpag]."
						return
					}
				}
				#foreach elemlista $lista {}

				if {[llength $lista]<$resporpag} {
					set nres [llength $lista]
				} elseif {[expr [llength $lista]-($resporpag*$pagpedida-$resporpag)]<$resporpag } {
					set nres [expr [llength $lista]-($resporpag*$pagpedida-$resporpag)]
				} else {
					set nres $resporpag
				}

				for {set ilista [expr $nres*$pagpedida-$nres]} {$ilista<[expr $nres*$pagpedida]} {incr ilista} {
					putquick "privmsg $chan :🔍 [lindex $lista $ilista]"
				}
				putquick "privmsg $chan :Mostrado[if {$nres!=1} {set a "s"}] $nres de [llength $lista] resultado[if {[llength $lista]!=1} {set a "s"}]. Página $pagpedida de [expr 1+[llength $lista]/5]."
			}

			return
		} \
		"" {
			if {$lids==""} {
				putquick "privmsg $chan :Nenhum feed está definido para este canal."
			} else {
				putquick "privmsg $chan :IDs de feeds disponíveis: $lids"
			}
			return
		} \
		"ajuda" - "help" {
		} \
		default {
		}
	if {$arg1!="help" && $arg1!="ajuda"} {
		putquick "privmsg $chan :Comando não conhecido: $arg1"
	}
	putquick "privmsg $chan :  Comandos disponíveis:"
	putquick "privmsg $chan :    status estado   Mostra o estado"
	putquick "privmsg $chan :    pesq search     Efectua uma pesquisa. rss:id-do-feed"


}

#####

proc adividata {datestr} {
	# Common patterns
	set patterns {
		{%a, %d %b %Y %H:%M:%S %z}
		{%a, %d %b %y %H:%M:%S %z}
		{^[A-Z][a-z][a-z], \d{1,2} [A-Z][a-z][a-z] \d{4} \d{2}:\d{2}:\d{2} [+-]\d{4}$}
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
putlog "RSS FEEDS $rssbuild carregado"
#002 bold
#003 cor
#017 texto normal
#026 reverse
#037 underline
#035 italico
