set datadoscript "22-Março-2024"
#by Kashinkoji 
set urldoscript "https://raw.githubusercontent.com/moonlightz/meo-epg/master/scripts/guiatv.tcl"
bind time - "34 12 * * *" scriptupdate

bind msg - "!prglista" prglista

bind pub - "!antes" tvantes
bind pub - "!agora" tvagora
bind pub - "!depois" tvdepois
bind pub - "!aseguir" tvdepois

bind pub - "!ontem" tvontem
bind pub - "!hoje" tvhoje
bind pub - "!amanha" tvamanha
bind pub - "!2dias" tv2dias
bind pub - "!3dias" tv3dias
bind pub - "!4dias" tv4dias
bind pub - "!5dias" tv5dias
bind pub - "!6dias" tv6dias
bind pub - "!7dias" tv7dias
bind pub - "!meuscanais" tvmeuscanais
bind pub - "!definir" tvdefinir
bind pub - "!guiatv" guiatvtrig
bind pub - "!tvpesq" tvpesq
bind pub - "!tvcanais" tvcanais

bind pub - "!tvlistas" tvlistas

#bind time - "03 00 * * *" tvautosync
#A hora será gerida pelos valor no ficheiro abaixo

set tvfichcfg "tvurls.cfg"
#set epglinkxml "https://raw.githubusercontent.com/f0nZ/epg-tv-portuguesa/master/guide.xml"
#set epglinkxml "https://ptiptv.tk/guia.xml"
#https://ptiptv.tk/guia.xml
set urlselec 0
set fichnicks "tvnicks.txt"

proc tvlistas {nick host handle chan text} {
	global tvfichcfg urlselec cprogramacao
#	putquick "privmsg $chan :$text"
#	"d/a/b|mm hh|link"
	set text [string trim $text]
	if {$text==""} {
		putnow "privmsg $chan :Gestão de listas de canais. As opções são:"
		putnow "privmsg $chan : \002ADICIONAR\002 -> Adiciona um link à lista.   | \002ACTIVAR\002 -> Activa um link desactivado."
		putnow "privmsg $chan : \002LISTAR\002 -> Lista os links.                | \002DESACTIVAR\002 -> Desactiva um link activado."
		putnow "privmsg $chan : \002REMOVER\002 -> Remove um link da lista.      | \002ACTUALIZAR\002 -> Força o refresh a partir dos links activados."
		putnow "privmsg $chan : \002SELEC\002 -> Selecciona um item da lista.    | \002HORA\002 -> Altera a hora da actualização automática."
		putnow "privmsg $chan : \002ESTADO\002 -> Estado da programação offline. | \002BACKUP\002 -> Prog. offline para arquivamento."
		return
	}

	set opcao [lindex $text 0]
	set opcao2 [lindex $text 1]

    if {![file exists $tvfichcfg]} {
		set f [open $tvfichcfg w+]
		puts $f "actualizar=12:00"
		puts -nonewline $f "backup=prog%Y%b%d-%H%M.tar.gz"
		close $f
		putlog "GuiaTV: $tvfichcfg vazio criado"
    }
    set f [open $tvfichcfg r]
    set linhas [split [read $f] "\n"]
    close $f
    set urlz ""
    foreach linha $linhas {
		if {[string range $linha 0 10]=="actualizar="} {
			set marcatempo [lindex [split [lindex $linha end] "="] 1]			
			continue
		}
		if {[string range $linha 0 6]=="backup="} {
            set fichbackup [lindex [split [lindex $linha end] "="] 1]
            continue
        }
        if {$linha==""} {continue}
        lappend urlz $linha
    }


	if {$opcao=="listar"} {
		set i 0
		if {[llength $urlz]==1} {set strlistar "1 link de guia xml disponível"} {set strlistar "[llength $urlz] links de guia xml disponíveis"}
		putnow "privmsg $chan :$strlistar, com actualização às [string map {"," ", "} $marcatempo]"
		foreach url $urlz {
			set url [split $url "|"]
			incr i
			set urlstatus [string map {"d" "desactivado" "a" "activado   " "b" "bloqueado  "} [lindex $url 0]]
			#set tempo "[lindex [lindex $url 1] 1]:[lindex [lindex $url 1] 0]"
			set url [lindex $url end]
			if {$i==$urlselec} {set sel "*"} {set sel " "}
			putnow "privmsg $chan :$i$sel $urlstatus  $url"
		}
		return
	} elseif {$opcao=="selec"} {
		if {$opcao2==""} {
			putnow "privmsg $chan :Seleccione um url pelo número."
			return
		} else {
			if {[isnumber $opcao2]} {
				if {$opcao2>=1 && $opcao2<=[llength $urlz]} {
					set urlselec $opcao2
					putnow "privmsg $chan :O link $opcao2 está agora seleccionado."
					return
				} else {
					putnow "privmsg $chan :O número do link que seleccionou não é válido ou não existe."
					return
				}
			} else {
				putnow "privmsg $chan :Não reconhecido."
				return
			}
		}
    } elseif {$opcao=="mover"} {
        if {$opcao2==""} {
            putnow "privmsg $chan :Não especificou um número."
            return
        } else {
            if {[isnumber $opcao2]} {
                if {$opcao2<1 && $opcao2>[llength $urlz]} {
                    putnow "privmsg $chan :Número $opcao2 não é válido."
                    return
                }
				if {[isnumber $opcao3]} {
					if {$opcao3<1 && $opcao3>[llength $urlz]} {
						putnow "privmsg $chan :Número $opcao3 não é válido."
						return
					}
				}
				if {$opcao2==$opcao3} {
					putnow "privmsg $chan :Os dois números não podem ser iguais."
					return
				}

            } else {
                putnow "privmsg $chan :Não reconhecido."
                return
            }
        }
		set urlA [lindex $urlz $opcao2]
		set urlb [lindex $urlz $opcao3]
		set urlz [lreplace $urlz $opcao2 $opcao2 $urlb]
		set urlz [lreplace $urlz $opcao3 $opcao3 $urla]
	} elseif {$opcao=="estado"} {
		putnow "privmsg $chan :A analisar..."
		set progstatus [procprogstatus]
		putnow "privmsg $chan :Canais \002[lindex $progstatus 0]\002  Início: \002[lindex $progstatus 1]\002  Fim: \002[lindex $progstatus 2]\002  Intervalo: \002[lindex $progstatus 3]\002  Entradas: \002[lindex $progstatus 4]\002 Actualizado a \002[lindex $cprogramacao 1]\002 por \002[lindex $cprogramacao 0]\002"
	} elseif {$opcao=="hora"} {
		if {$opcao2==""} {
			putquick "privmsg $chan :Insira horas válidas entre 00:00 e 23:59, separadas por vírgulas. Ex: 11:00,12:34"
	        return
		}
		set marcatempo ""
		foreach hora [split $opcao2 ","] {
			if {$hora==""} {
				continue
			}
		    if {[timevalidate "%H:%M" $hora]} {
				lappend marcatempo [clock format [clock scan $hora -format "%H:%M"] -format "%H:%M"]
	        } else {
		        putnow "privmsg $chan :'$hora' não parece ser válido."
			    return
			}        
		}
		if {$marcatempo==""} {
			putnow "privmsg $chan :Sem horas inseridas."
			return
		}
		set marcatempo [lsort -unique $marcatempo]
		set marcatempo [join $marcatempo ","]
		#set marcatempo [string trimright $marcatempo ","]
		putnow "privmsg $chan :Actualização automática alterada para: $marcatempo"
	} elseif {$opcao=="adicionar"} {
		if {$opcao2==""} {
			putquick "privmsg $chan :use \002url=link-aqui\002 para adicionar um link à lista de links."
			return
		}
		set omeuurl [lindex [split [lsearch -inline $text "url=*"] "="] 1]
		if {$omeuurl==""} {
			putnow "privmsg $chan :Insira um link para adicionar à lista."
			return
		}

		lappend urlz "a|$omeuurl"
		set urlselec [llength $urlz]

		putnow "privmsg $chan :O link foi adicionado com sucesso."
	} elseif {$opcao=="remover"} {
		if {$urlselec==0} {
			putnow "privmsg $chan :Seleccione primeiro um link da lista. Use \002LISTAR\002 para visualizar que links estão disponíveis. Use \002SELEC núm\002 para seleccionar."
			return
		}
		if {[lindex [split [lindex $urlz $urlselec-1] "|"] 0]=="b"} {
			putnow "privmsg $chan :Este link está marcado como bloqueado e não pode ser removido."
			return
		}
		set urlz [lreplace $urlz $urlselec-1 $urlselec-1]
		putnow "privmsg $chan :O link $urlselec foi removido."
		set urlselec 0
	} elseif {$opcao=="activar" || $opcao=="desactivar"} {
        if {$urlselec==0} {
            putnow "privmsg $chan :Seleccione primeiro um link da lista. Use \002LISTAR\002 para visualizar que links estão disponíveis e depois use \002SELEC núm\002 para seleccionar."
            return
        }
        if {[lindex [split [lindex $urlz $urlselec-1] "|"] 0]=="b"} {
            putnow "privmsg $chan :Este link está marcado como bloqueado e não pode ser removido."
            return
        }
#        set urlz [lreplace $urlz $urlselec-1 $urlselec-1]
		if {$opcao=="activar"} {
			set urlz [lreplace $urlz $urlselec-1 $urlselec-1 "a|[string range [lindex $urlz $urlselec-1] 2 end]"]
			putnow "privmsg $chan :O link $urlselec foi activado."
		}
		if {$opcao=="desactivar"} {
			set urlz [lreplace $urlz $urlselec-1 $urlselec-1 "d|[string range [lindex $urlz $urlselec-1] 2 end]"]
			putnow "privmsg $chan :O link $urlselec foi desactivado."
		}
    } elseif {$opcao=="actualizar"} {
		putnow "privmsg $chan :Aguarde alguns momentos enquanto a array é preenchida ..."
		putnow "privmsg $chan :[tvengine $chan]"
		set cprogramacao $nick
		lappend cprogramacao [string map {"Mon" "Seg" "Tue" "Ter" "Wed" "Qua" "Thu" "Qui" "Fri" "Sex" "Sat" "Sáb" "Sun" "Dom" "Feb" "Fev" "Apr" "Abr" "May" "Mai" "Aug" "Ago" "Sep" "Set" "Oct" "Out" "Dec" "Dez"} [clock format [clock seconds] -format "%a,%d/%b/%Y %H:%M:%S"]]
#putlog $cprogramacao
		return
	} else {
	    putnow "privmsg $chan :Opção não conhecida: $opcao"
		return
	}
	###REESCREVER O FICHEIRO
    foreach bind [binds] {
        if {[lindex $bind end]=="tvautosync"} {
	        catch {unbind time - [lindex $bind 2] tvautosync}
        }
    }
	foreach hora [split $marcatempo ","] {
		bind time - "[clock format [clock scan $hora -format "%H:%M"] -format "%M %H"] * * *" tvautosync
	}
 
	file delete $tvfichcfg

	set f [open $tvfichcfg w+]
	foreach i $urlz {
		puts $f $i
	}
    puts $f "actualizar=$marcatempo"
	puts $f "backup=$fichbackup"
    close $f	
	putlog "GuiaTV: TVLISTAS usada por $nick no canal $chan: >$text<"
}

proc procprogstatus {} {
	global programacao
	if {![info exists programacao]} {
		return "0 N/A N/A"
	}
	set ncanais [llength [array names programacao]]
	set inicio "N/A"
	set fim "N/A"
	set intervalo "intervalo"
	set entradas 0
	foreach canal [array names programacao] {
		foreach itemcanal [lrange $programacao($canal) 1 end] {
			incr entradas
			set aitem [split $itemcanal "|"]
			set ainicio [lindex $aitem 0]
			set afim [lindex $aitem 1]
			if {$inicio=="N/A"} {
				set inicio $ainicio
                set fim $afim
            }

			if {$ainicio<$inicio} {set inicio $ainicio}
            if {$afim>$fim} {set fim $afim}
 
		}

	}
#atum
    set intervalo [string trimright [string map {"d" "d " "h" "h " "m" "m "} [conv_segs_tempo [expr [clock scan $fim -format "%Y%m%d%H%M%S %z"]-[clock scan $inicio -format "%Y%m%d%H%M%S %z"]]]]]
    set inicio [string map {"Mon" "Seg" "Tue" "Ter" "Wed" "Qua" "Thu" "Qui" "Fri" "Sex" "Sat" "Sáb" "Sun" "Dom" "Feb" "Fev" "Apr" "Abr" "May" "Mai" "Aug" "Ago" "Sep" "Set" "Oct" "Out" "Dec" "Dez"} [clock format [clock scan $inicio -format "%Y%m%d%H%M%S %z"] -format "%a,%d/%b/%Y %H:%M"]]
    set fim [string map {"Mon" "Seg" "Tue" "Ter" "Wed" "Qua" "Thu" "Qui" "Fri" "Sex" "Sat" "Sáb" "Sun" "Dom" "Feb" "Fev" "Apr" "Abr" "May" "Mai" "Aug" "Ago" "Sep" "Set" "Oct" "Out" "Dec" "Dez"} [clock format [clock scan $fim -format "%Y%m%d%H%M%S %z"] -format "%a,%d/%b/%Y %H:%M"]]
	set mensagem "$ncanais"
	lappend mensagem $inicio $fim $intervalo $entradas
	return $mensagem
}

proc tvcanais {nick host handle chan text} {
	global programacao
	putquick "privmsg $chan :A despejar a lista no privado de $nick..."
	set linha "Número de canais: [llength [array names programacao]]  A lista: "
	foreach canal [lsort [array names programacao]] {
	
		append linha "\0030,3\002$canal\002\003 ([lindex $programacao($canal) 0])  "
		if {[string length $linha]>400} {
			putnow "privmsg $nick :$linha"
			set linha ""
		}
	}
	putnow "privmsg $nick :$linha"
	
}

proc guiatvtrig {nick host handle chan text} {
	global datadoscript programacao
	putnow "privmsg $chan :GuiaTV build $datadoscript com [llength [array names programacao]] canais, opções disponíveis:"
	putnow "privmsg $chan :!agora/!antes/!depois <canal1> <canal2> <canaln> » Mostra o programa que está ser exibido."
	putnow "privmsg $chan :!agora/!antes/!depois rtp* *cine* » O uso do asterisco mostra nomes de canais disponíveis."
	putnow "privmsg $chan :!ontem !hoje !amanha !2dias !3dias !4dias !5dias !6dias !7dias <canal> » Mostra a programação para um canal apenas."
	putnow "privmsg $chan :!meuscanais !definir <c1> <c2> ... » Gerir canais quando usa o !agora"
	putnow "privmsg $chan :!tvcanais » Mostra uma lista de canais"
	putnow "privmsg $chan :!tvpesq » Pesquisar por um nome de programa"
	putnow "privmsg $chan :!tvlistas » Gerir listas"
}

proc tvpesq {nick host handle chan text} {
	global programacao
	set text [string trim $text]

	if {$text==""} {
        putnow "privmsg $chan :Introduza o nome do programa e/ou pesquise por data/hora (formato ddmeshhmm) e/ou pesquise por canal e/ou na descrição."
        putnow "privmsg $chan :Exs:!tvpesq jornal !tvpesq c:rtp1 jornal !tvpesq t:31dez0759 !tvpesq -desc fernando mendes"
        return
    }


	#Verificar a presença de c:canal1,canal2,canaln
	set cindex [lsearch -nocase $text "c:*"]
	set clista [string range [string map {"," " "} [lindex $text $cindex]] 2 end]
	if {$clista!=""} {
		foreach element $clista {dict set tmp $element c1ista}
		set clista [dict keys $tmp]
	}
	
	####pesquisa por data
	set ttempo ""
	set tindex [lsearch -nocase $text "d:*"]
	set tdata [string tolower [string range [lindex $text $tindex] 2 end]]
	if {$tdata!=""} {
		set tdata [string map {"fev" "feb" "abr" "apr" "mai" "may" "ago" "aug" "set" "sep" "out" "oct" "dez" "dec"} $tdata]
		if {[timevalidate "%d%b" $tdata]==0} {
			putquick "privmsg $chan :A data inserida não é válida. Use o formato ddmes, como 31jan ou 28Fev"
			return
		}
		set tdata [clock format [clock scan $tdata -format "%d%b"] -format "%Y%m%d%H%M%S %z"]
	}

	set actdesc ""
	set dindex [lsearch -nocase $text "-desc"]
	if {$dindex==-1} {set actdesc ""} {set actdesc "desc"}
	
	set text [string trim [lreplace $text $dindex $dindex]]
    set text [string trim [lreplace $text $cindex $cindex]]
	set text [string trim [lreplace $text $tindex $tindex]]
	#putquick "privmsg $chan :>$text< >$cindex< >$tindex<"

	set text [string map {" " "*"} $text]

	set inicio [clock milliseconds]
	set nres 0
	set resmax 3
	set cres ""
	if {$clista!=""} {
		foreach i $clista {
		
			if {[lsearch -nocase [array names programacao] $i]==-1} {
				putquick "privmsg $chan :Não conheço $i."
				return
			}
		}
	} else {
		set clista [array names programacao]
	}
	foreach canal $clista {
		set resultados ""
		if {$tdata!=""} {
			foreach itemx [lrange $programacao($canal) 1 end] {
                if {[string range [lindex [split $itemx "|"] 0] 0 7]==[string range $tdata 0 7] && [string match -nocase *$text* [lindex [split $itemx "|"] 2]]} {
	                #putlog "$itemx"
                    lappend resultados $itemx
                    #break
                }
            }
		} else {
			if {$actdesc=="desc"} {
				set ssquery "*|*|*$text*"
			} else {
				set ssquery "*|*|*$text*|*"
			}
			set resultados [lsearch -all -inline -nocase [lrange $programacao($canal) 1 end] $ssquery]
			
        }
		if {$resultados!=""} {
			incr nres
			set progencmost 0
			if {$nres<=$resmax} { 
				set linha "\037[lindex $programacao($canal) 0] ($canal)\037 "
				foreach res $resultados {
					set pinicio [string map {"Feb" "Fev" "Apr" "Abr" "May" "Mai" "Aug" "Ago" "Sep" "Set" "Oct" "Out" "Dec" "Dez"} [clock format [clock scan [lindex [split $res "|"] 0] -format "%Y%m%d%H%M%S %z"] -format "%d/%b %H:%M"]]
					set pprog [lindex [split $res "|"] 2]
					set novoprog "\002$pinicio\002 $pprog "
					if {[expr [string length $linha]+[string length $novoprog]]<=400} {
						incr progencmost
						append linha $novoprog
					}
				}
				if {[llength $resultados]==$progencmost} {
					putnow "privmsg $chan :$linha"
				} else {
					set progencmost [expr [llength $resultados]-$progencmost]
					if {$progencmost==1} {
						set sprog "1 programa"
					} else {
						set sprog "$progencmost programas"
					}
					putnow "privmsg $chan :$linha (e mais $sprog)"
				}
			} else {
				lappend cres $canal
			}
		}
	}
			 if {$nres==1} {
                set sres "1 resultado"
            } else {
                set sres "$nres resultados"
            }
	if {$nres==0} {
		putnow "privmsg $chan :Não foram encontrados resultados."
	} else {
		if {$nres<=$resmax} {
			putnow "privmsg $chan :$sres ([expr (double([clock milliseconds])-$inicio)/1000] segundos)"	
		} else {
			if {[llength $cres]>20} {set sreticencias "..."} {set sreticencias ""}
			putnow "privmsg $chan :Mostrado $resmax de $sres (mais em: [lrange $cres 0 19]$sreticencias) ([expr (double([clock milliseconds])-$inicio)/1000] segundos)"
		}
	}
}

proc tvengine {{ctext ""}} {
	global programacao tvfichcfg 
	putlog "GuiaTV: A iniciar a tarefa..."
	set tarefainiciada [clock milliseconds]
	if {![file exists $tvfichcfg]} {
		set f [open $tvfichcfg w+]
		puts $f "actualizar=12:00"
		puts -nonewline $f "backup=prog%Y%b%d-%H%M.tar.gz"
		close $f
		putlog "GuiaTV: Ficheiro vazio criado."
		return "Erro: Ficheiro vazio. Adicione um link."
	}
	#limpar os antigos bind time que pertence ao tvautosync
	foreach bind [binds] {
		if {[lindex $bind end]=="tvautosync"} {
			catch {unbind time - [lindex $bind 2] tvautosync}
		}
	}
	

	set furls [open $tvfichcfg r+]
	set turls [split [read $furls] "\n"]
	close $furls

	if {[array exists programacao]} {unset programacao}
	array set programacao {}
	set contador 0
	set lcontador ""
#	set ltotalcanais ""
#	set ltamanholista ""
	foreach url $turls {
		
		if {$url==""} {break}
		#	package require http
		#	package require tls
		#	http::register https 443 [list ::tls::socket -tls1 true -ssl2 false -ssl3 false]
	
		#	http::config -useragent "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:76.0) Gecko/20100101 Firefox/76.0"
		if {[string range $url 0 6]=="backup="} {continue}
		if {[string range $url 0 10]=="actualizar="} {
			set marcatempo [lindex [split $url "="] 1]
	        #criar o bind -> 12:00 -> 00 12
			foreach hora [split $marcatempo ","] {
				bind time - "[clock format [clock scan $hora -format "%H:%M"] -format "%M %H"] * * *" tvautosync
			}
			continue
		}
		incr contador
		set estado [lindex [split $url "|"] 0]
		if {$estado=="d"} {continue}

		set url [lindex [split $url "|"] end]
		set xmlc ""
		putlog "GuiaTV: Hit $url ..."
		set nomedoficheiro [lindex [split $url "/"] end]

		#	set web [http::geturl $epglinkxml -timeout 10000 ]
		#	http::wait $web
		#	http::wait $web
		#	set xmlc [http::data $web]
		#	http::cleanup $web
		if {[string match "*.gz" $url]} {
			catch {set xmlc [exec wget -q -O - $url | gunzip -c]}
		} else {
			catch {set xmlc [exec wget -q -O - $url]}
		}
		if {$xmlc==""} {
			putlog "GuiaTV: Falhou."
			lappend lcontador $contador
			continue
		}
		set tamanho [string length $xmlc]
#		if {$tamanho<500000} {set taviso "\00304\002"} {set taviso ""}
		#append ltamanholista "$taviso$contador=$tamanho bytes\003\002 "
		putlog "GuiaTV: OK. O $nomedoficheiro tem $tamanho bytes."
	
		set xmlc [split $xmlc "\n"]

	    putlog "GuiaTV: A remover lixo do xml..."
	    set xmlc [string map {
	        " lang=\"pt\"" "" " lang=\"en\"" "" "&amp;" "&" "&quot;" "\"" "&apos;" "'"
	        ".pt" "" ".PT" "" ".nws" "" " (\?)" "" "(n)" "" "  " "" "    " ""} $xmlc]
	    putlog "GuiaTV: [string length $xmlc] bytes após a limpeza."

		set nomecurtodoscanais [regexp -all -inline {<channel id=\"(.*?)\">} $xmlc]
		set nomelongodoscanais [regexp -all -inline {<display-name>(.*?)</display-name>} $xmlc]
		set numcanais [expr [llength $nomecurtodoscanais]/2]
		putlog "GuiaTV: O ficheiro $nomedoficheiro contém $numcanais canais."
		foreach {- nc} $nomecurtodoscanais {- nl} $nomelongodoscanais {
			set nc [string tolower [string map {" " ""} $nc]]
			catch {unset programacao($nc)}
			lappend programacao($nc) $nl
		}
#		set numerocanais [llength [array names programacao]]
#		putlog "GuiaTV: O ficheiro contém $numerocanais canais."

		#	putlog "GuiaTV: A criar array..."
		#	for {set linha 1} {$linha<=$numerocanais} {incr linha} {
		#		 for {set coluna 0} {$coluna<500} {incr coluna} {
		#			  set programacao($linha,$coluna) ""
		#		 }
		#	 }
		#	 putlog "GuiaTV: Array criado. [array size programacao] elementos."



		putlog "GuiaTV: Aguarde alguns momentos enquanto a array é preenchida ..."
		set nprog 0
#		set ainicio [clock format [clock seconds] -format "%Y%m%d%H%M%S %z"]
#		set afim [clock format [clock seconds] -format "%Y%m%d%H%M%S %z"]
		set ainicio ""
		set afim ""
		putlog "GuiaTV: Stage antes do processamento dos dados do xml"
		foreach linha $xmlc {
			set linha [string trim $linha]
			if {[string range $linha 0 10] == "<programme "} {
				set progsec [regexp -all -inline {<programme start="(.*?)" stop="(.*?)" channel="(.*?)">} $linha]
				#set inicio [clock format [clock scan [lindex [regexp -inline -- {start=\"(.*?)\"} $linha] 1] -format "%Y%m%d%H%M%S %z"] -format "%Y%m%d%H%M%S %z"]
				#set fim [clock format [clock scan [lindex [regexp -inline -- {stop=\"(.*?)\"} $linha] 1] -format "%Y%m%d%H%M%S %z"] -format "%Y%m%d%H%M%S %z"]
				set inicio [lindex [regexp -inline -- {start=\"(.*?)\"} $linha] 1] 
				set fim [lindex [regexp -inline -- {stop=\"(.*?)\"} $linha] 1]
				set canal [string tolower [string map {" " ""} [lindex [regexp -inline -- {channel=\"(.*?)\"} $linha] 1]]]
				set programa "$inicio|$fim|"
				set pepnum ""
				set pdesc ""
				if {$ainicio==""} {
					set ainicio $inicio
					set afim $fim
				}
			}
			if {[string range $linha 0 6] == "<title>"} {
				append programa "[string range $linha 7 end-8]"
			}
			if {[string range $linha 0 5] == "<desc>"} {
				if {[string range $linha end-6 end] == "</desc>"} {
					set pdesc [string range $linha 6 end-7]
				} else {
		        #if {[string range $linha 0 5] == "<desc>"} {}
		            set pdesc [string range $linha 6 end]
				}
			}
	            if {[string range $linha 0 5] == "<desc "} {
					putlog "-----> excepcao descricao >$linha<"
	                set pdesc [string range $linha [string first ">" $linha] end]
		        }
			if {[string range $linha end-6 end]=="</desc>" && [string range $linha 0 5] != "<desc>"} {
			    set pdesc2 [string range $linha 0 end-7]
#           if {[lsearch -nocase $pdesc2 *mcs*]>=0} {
#               putlog ">$pdesc< >$pdesc2"
#           }
				if {[string length $pdesc]<[string length $pdesc2]} {
					set pdesc $pdesc2
		        } else {
		             append pdesc $pdesc2
			    }
				unset pdesc2
			}
			if {[string range $linha 0 11] == "<episode-num"} {
				set pepnum " [lindex [regexp -all -inline {<episode-num system="onscreen">(.*?)</episode-num>} $linha] 1]"
				set pepnum [string trimright $pepnum]
			}
			if {$linha=="</programme>"} {
#				append programa "$pepnum|$pdesc"
				lappend programacao($canal) [string trimright "$programa$pepnum|$pdesc"]
				incr nprog
				if {$inicio<$ainicio} {set ainicio $inicio}
				if {$fim>$afim} {set afim $fim}
			}
		}
		putlog "GuiaTV: Stage após processamento dos dados do xml"
		if {$ctext!=""} {
			putlog "GUiaTV: Output para >$ctext<\; ainicio=>$ainicio<\; afim=>$afim<"
			set aagora [clock format [clock seconds] -format "%Y%m%d%H%M%S %z"]
			set msgdesactualizado ""
			if {$afim<$aagora} {
				set msgdesactualizado "\; Link parece desactualizado"
			}
			set aintervalo [string trimright [string map {"d" "d " "h" "h " "m" "m "} [conv_segs_tempo [expr [clock scan $afim -format "%Y%m%d%H%M%S %z"]-[clock scan $ainicio -format "%Y%m%d%H%M%S %z"]]]]]
		    set ainicio [string map {"Mon" "Seg" "Tue" "Ter" "Wed" "Qua" "Thu" "Qui" "Fri" "Sex" "Sat" "Sáb" "Sun" "Dom" "Feb" "Fev" "Apr" "Abr" "May" "Mai" "Aug" "Ago" "Sep" "Set" "Oct" "Out" "Dec" "Dez"} [clock format [clock scan $ainicio -format "%Y%m%d%H%M%S %z"] -format "%a,%d/%b/%Y %H:%M"]]
		    set afim [string map {"Mon" "Seg" "Tue" "Ter" "Wed" "Qua" "Thu" "Qui" "Fri" "Sex" "Sat" "Sáb" "Sun" "Dom" "Feb" "Fev" "Apr" "Abr" "May" "Mai" "Aug" "Ago" "Sep" "Set" "Oct" "Out" "Dec" "Dez"} [clock format [clock scan $afim -format "%Y%m%d%H%M%S %z"] -format "%a,%d/%b/%Y %H:%M"]]

            if {$tamanho<500000} {set taviso "\00304\002"} {set taviso ""}
            putnow "privmsg $ctext :Link \002$contador\002 => Canais: $numcanais\;$taviso Tamanho: [formatbytes $tamanho] ($tamanho bytes)\; Entradas: $nprog\; Início: $ainicio\; Fim: $afim\; Intervalo: $aintervalo$msgdesactualizado"
        }
	}
	if {$lcontador!=""} {set lcontador " IDs dos links que falharam: $lcontador" }
	set numerototalcanais [llength [array names programacao]]
	set tentradas 0
	foreach nc [array names programacao] {
		incr tentradas [expr [llength $programacao($nc)]-1]
	}

    set tempodecorrido [expr (double([clock milliseconds])-$tarefainiciada)/1000]
 
	set estadofinal "Tarefa terminada em $tempodecorrido segundos. Total canais obtidos: $numerototalcanais. Total entradas: $tentradas. $lcontador"
	putlog "GuiaTV: $estadofinal"
	return $estadofinal
}


proc tvagora {nick host handle chan text} {
	tvsched "agora" $nick $chan $text
}
proc tvantes {nick host handle chan text} {
    tvsched "antes" $nick $chan $text
}
proc tvdepois {nick host handle chan text} {
    tvsched "depois" $nick $chan $text
}


proc tvsched {quando nick chan text} {
	global fichnicks programacao
	set nickencontrado "nao"
	set text [string trim [string tolower $text]]
	if {$text==""} {
		if {![file exists $fichnicks]} {
			set f [open $fichnicks w+]
			close $f
			putlog "GuiaTV: Ficheiro de nicks vazio criado."
		}
		set ficnicks [open $fichnicks r]
		while {![eof $ficnicks]} {
			gets $ficnicks linhax
			if {[eof $ficnicks]} {break}
			if {[lindex $linhax 0]==$nick} {
				set text [lrange $linhax 1 end]
				set nickencontrado "sim"
				break
			}
		}
		close $ficnicks
		if {$nickencontrado=="nao"} {
			putnow "privmsg $chan :Introduza pelo menos uma sigla de canal ou uma palavra-chave."
			return
		}
	}
	#set lcanais [lsort [glob -directory $epgtargetdir/$epgtargetsubdir -type d -tails -- *]]
	set lcanais ""
#	foreach i [array names programacao] {
#		lappend lcanais $i
#	}
	set lcanais [lsort [array names programacao]]
#putlog "$lcanais"
	
	set listaescolhida ""
	foreach itemtexto $text {
		set mlista [lsearch -all -inline $lcanais $itemtexto]
		set msgerro ""
		if {$mlista==""} {
			#tentar procurar por itens se returnar 0
			set mlista [lsearch -all -inline $lcanais *$itemtexto*]
		}

		if {$mlista==""} {
			set msgerro "O termo \002$itemtexto\002 não retornou nada. Verifique o critério de procura."
		}

		if {[llength $mlista]>1} {
			if {[llength $mlista]>20} {
				set mlista "[lrange $mlista 0 19]\002..."
			} else {
				set mlista "$mlista\002."
			}
			set msgerro "O termo \002$itemtexto\002 retornou \002$mlista Escolha um canal da lista."

		}

		if {$msgerro!=""} {
			putnow "privmsg $chan :⚠ ️$msgerro"
#			return
			continue
		}
		set listaescolhida "$listaescolhida $mlista"

	}
	set text [lsort -unique $listaescolhida]
#	set datahoje "[strftime "%Y-%m-%d"]"
	set programasencontradosi ""
	set programasencontrados ""
	set exflag ""
#AQUI
	foreach itemtext $text {
#putquick "privmsg $chan :>$itemtext<"
		set conteudo [lrange $programacao($itemtext) 1 end]
		if {$conteudo==""} {
			putquick "privmsg $chan :Aviso: Não há programação para \002$itemtext\002. Causa: O guia de tv de origem não continha dados para este canal (e talvez mais canais)."
			continue
			#return
		}
		set logocanal [lindex $programacao($itemtext) 0]

		set i 0
		foreach linhax $conteudo {
			set linha [split $linhax "|"]
#putlog ">$ilinha,$cindice< >$linha<"
#			if {$linha==""} {break}
			set inicio [clock scan [lindex $linha 0] -format "%Y%m%d%H%M%S %z"]
			set fim [clock scan [lindex $linha 1] -format "%Y%m%d%H%M%S %z"]
			set tempo [clock seconds]
			if {$inicio<$tempo && $tempo<=$fim} {
				if {$quando=="antes" || $quando=="depois"} {
					if {$quando=="antes"} {incr i -1}
					if {$quando=="depois"} {incr i}
					set linhax [lindex $conteudo $i]
					if {$linhax==""} {
						putquick "privmsg $chan :Não existe programa para mostrar."
						return
					}
					set linha [split $linhax "|"]
					set inicio [clock scan [lindex $linha 0] -format "%Y%m%d%H%M%S %z"]
					
				}

				set desc [lindex $linha 3]
				set iniciohm [clock format $inicio -format "%H:%M"]
				set programasencontradosi "$programasencontradosi\0030,3\002$logocanal\003\002 \002$iniciohm\002"
				if {[llength $text]==1 || $exflag!=""} {
					if {$quando=="agora"} {
						set duracao [expr $fim-$inicio]
						set posicao [expr $tempo-$inicio]
						set percentagem [expr 100*$posicao/$duracao]
						set programasencontradosi "$programasencontradosi [pbardraw 20 $percentagem 12 14 0 "-[conv_segs_tempo [expr $fim-$tempo]]/[conv_segs_tempo $duracao]"] \002[clock format $fim -format "%H:%M"]\002"
					}
				}
				set programasencontradosi "$programasencontradosi [lindex $linha 2] "
				if {$exflag!="" || [llength $text]==1} {
					#if {$quando=="agora"} {}
						if {[string length $desc]>325} {set desc "[string range $desc 0 324]\u2026"}
						set programasencontradosi "$programasencontradosi \035$desc\035"
					#{}
				}
				set lpencontradosi [string length $programasencontradosi]
				set lpencontrados [string length $programasencontrados]
				if {[expr $lpencontrados+$lpencontradosi]>400 || $exflag!=""} {
					putnow "privmsg $chan :$programasencontrados"
					set programasencontrados "$programasencontradosi"
					set programasencontradosi ""
				} else {
					set programasencontrados "$programasencontrados$programasencontradosi"
					set programasencontradosi ""
				}
			}
			incr i
		}
	}
	putnow "privmsg $chan :[string trimright $programasencontrados " "]"

#####fim de kagora
}

proc tvontem {nick host handle chan arg} {
	motortv $chan $arg [clock format [clock scan "yesterday"] -format "%Y%m%d"]
}
proc tvhoje {nick host handle chan arg} {
	motortv $chan $arg [clock format [clock scan "today"] -format "%Y%m%d"]
}
proc tvamanha {nick host handle chan arg} {
	motortv $chan $arg [clock format [clock scan "tomorrow"] -format "%Y%m%d"]
}
proc tv2dias {nick host handle chan arg} {
	motortv $chan $arg [clock format [clock scan "2 days"] -format "%Y%m%d"]
}
proc tv3dias {nick host handle chan arg} {
    motortv $chan $arg [clock format [clock scan "3 days"] -format "%Y%m%d"]
}
proc tv4dias {nick host handle chan arg} {
    motortv $chan $arg [clock format [clock scan "4 days"] -format "%Y%m%d"]
}
proc tv5dias {nick host handle chan arg} {
    motortv $chan $arg [clock format [clock scan "5 days"] -format "%Y%m%d"]
}
proc tv6dias {nick host handle chan arg} {
    motortv $chan $arg [clock format [clock scan "6 days"] -format "%Y%m%d"]
}
proc tv7dias {nick host handle chan arg} {
    motortv $chan $arg [clock format [clock scan "7 days"] -format "%Y%m%d"]
}





proc motortv {chan canal quando} {
	global programacao
	set canal [string tolower [lindex $canal 0]]
	if {$canal==""} {
		putnow "privmsg $chan :Introduza um canal, por exemplo: rtp1"
		return
	}
	set lcanais ""
	#foreach i [array names programacao] {
	#	lappend lcanais $i
	#}
	set lcanais [lsort [array names programacao]]

	set listaescolhida ""
	set mlista [lsearch -all -inline $lcanais $canal]
	set msgerro ""
	if {$mlista==""} {
			#tentar procurar por itens se returnar 0
		set mlista [lsearch -all -inline $lcanais *$canal*]
	}

	if {$mlista==""} {
		set msgerro "O termo \002$canal\002 não retornou nada. Verifique o critério de procura."
	}

	if {[llength $mlista]>1} {
		if {[llength $mlista]>20} {
			set mlista "[lrange $mlista 0 19]\002..."
		} else {
			set mlista "$mlista\002."
		}
		set msgerro "O termo \002$canal\002 retornou \002$mlista Escolha um canal da lista."

	}

	if {$msgerro!=""} {
		putnow "privmsg $chan :⚠ ️$msgerro"
		return
	}
	set canal "$mlista"
#	putnow "privmsg $chan :$canal"

	set progpedida [lrange $programacao($canal) 1 end]
	if {$progpedida==""} {
		putquick "privmsg $chan :Impossível mostrar o conteúdo. Este canal (ou mais canais) não tinha dados quando foi feita a obtenção do guia de tv."
		return
	}
	set logocanal [lindex $programacao($canal) 0]
	set prog "\0038,12\002[string map {"Mon" "Seg" "Tue" "Ter" "Wed" "Qua" "Thu" "Qui" "Fri" "Sex" "Sat" "Sáb" "Sun" "Dom" "Feb" "Fev" "Apr" "Abr" "May" "Mai" "Aug" "Ago" "Sep" "Set" "Oct" "Out" "Dec" "Dez"} [clock format [clock scan $quando -format "%Y%m%d"] -format "%a,%d/%b"]]\002\003 \0030,4\002$logocanal\002\003 "
	set agora [clock seconds]
	foreach linhax $progpedida {
#putlog $linhax
		set inicio [clock scan [lindex [split $linhax "|"] 0] -format "%Y%m%d%H%M%S %z"]
		set inicio2 [clock format $inicio -format "%H:%M"]
		set inicio3 [clock format $inicio -format "%Y%m%d"]

		set fim [clock scan [lindex [split $linhax "|"] 1] -format "%Y%m%d%H%M%S %z"]
		set fim2 [clock format $fim -format "%Y%m%d"]
		if {$inicio3==$quando || $fim2==$quando} { 
			set titulo "[lindex [split $linhax "|"] 2]"
			if {$inicio<=$agora && $agora<$fim} {
				set programa "\0038,6\002\037$inicio2\037 $titulo \[-[conv_segs_tempo [expr $fim-$agora]]\]\002\003 "
			} else {
				set programa "\002$inicio2\002 $titulo "
			}
			if {[string length $prog]+[string length $programa]>400} {
				putnow "privmsg $chan :$prog"
				set prog "$programa"
			} else {
				set prog "$prog$programa"
			}
		}
	}
	if {$prog!=""} { putnow "privmsg $chan :$prog" }
	
#	putlog "GuiaTV: Fim"
}

proc conv_segs_tempo {xnumber} {
		global outputtext zw zd zh zm zs
		set outputtext ""
		#set zw [expr $xnumber/604800]
		#set xnumber [expr $xnumber-$zw*604800]
		set zd [expr $xnumber/86400]
		set xnumber [expr $xnumber-$zd*86400]
		set zh [expr $xnumber/3600]
		set xnumber [expr $xnumber-$zh*3600]
		set zm [expr $xnumber/60]
		set xnumber [expr $xnumber-$zm*60]
		set zs $xnumber
		#if {$zw == 1} {append outputtext $zw "w"}
		#if {$zw > 1} {append outputtext $zw "w"}
		if {$zd == 1} {append outputtext $zd "d"}
		if {$zd > 1} {append outputtext $zd "d"}
		if {$zh == 1} {append outputtext $zh "h"}
		if {$zh > 1} {append outputtext $zh "h"}
		if {$zm == 1} {append outputtext $zm "m"}
		if {$zm > 1} {append outputtext $zm "m"}
		if {$zs == 1} {append outputtext $zs "s"}
		if {$zs > 1} {append outputtext $zs "s"}
		if {$outputtext == ""} {set outputtext "0s"}
		return $outputtext

}

proc tvmeuscanais {nick host handle chan text} {
	global fichnicks
	set text ""
	if {![file exists $fichnicks]} {
		set f [open $fichnicks w+]
		close $f
		putlog "GuiaTV: Ficheiro de nicks vazio criado."
	}

	set ficnicks [open $fichnicks r]
	while {![eof $ficnicks]} {
		gets $ficnicks linhax
		if {[eof $ficnicks]} {break}
		if {[lindex $linhax 0]==$nick} {
			set text [lrange $linhax 1 end]
			putnow "privmsg $chan :Os seus canais são: $text"
			putnow "privmsg $chan :Para gerir os seus canais, use \002!definir\002 para obter ajuda."
			break
		}
	}
	close $ficnicks
	if {$text=="nao"} {
		 putnow "privmsg $chan :Não tem canais memorizados. Use \002!definir\002 para obter ajuda."
	}
}


putlog "TV carregado - $datadoscript"
if {![array exists programacao]} {
	set cprogramacao {{bot ao iniciar}}
	lappend cprogramacao [string map {"Mon" "Seg" "Tue" "Ter" "Wed" "Qua" "Thu" "Qui" "Fri" "Sex" "Sat" "Sáb" "Sun" "Dom" "Feb" "Fev" "Apr" "Abr" "May" "Mai" "Aug" "Ago" "Sep" "Set" "Oct" "Out" "Dec" "Dez"} [clock format [clock seconds] -format "%a,%d/%b/%Y %H:%M:%S"]]
 #criar um delay 60 segundos
	utimer 90 tvengine
}


proc tvautosync {minuto hora dia mes ano} {
	global cprogramacao
    set cprogramacao {{tarefa automática}}
    lappend cprogramacao [string map {"Mon" "Seg" "Tue" "Ter" "Wed" "Qua" "Thu" "Qui" "Fri" "Sex" "Sat" "Sáb" "Sun" "Dom" "Feb" "Fev" "Apr" "Abr" "May" "Mai" "Aug" "Ago" "Sep" "Set" "Oct" "Out" "Dec" "Dez"} [clock format [clock seconds] -format "%a,%d/%b/%Y %H:%M:%S"]]
 
	tvengine
}


proc tvdefinir {nick host handle chan text} {
	global programacao fichnicks
	set forcar "nao"
	set text [string trim [string tolower $text] " "]
	if {[string tolower [lindex $text 0]]=="-f"} {
		set text [lreplace $text 0 0]
		set forcar "sim"
	}
	if {$text==""} {
		putnow "privmsg $chan :Use este comando para definir os canais que mais usa com o \002!agora\002."
		putnow "privmsg $chan :Use \002!tvcanais\002 para obter uma lista completa de canais disponiveis."
		putnow "privmsg $chan :Use \002!definir <canal1> <canal2> <canalx> ...\002 para definir os canais pela ordem que lhe convier."
		putnow "privmsg $chan :Use \002!definir -\002 (1 traço) para remover todos os canais. O seu nick e os seus canais serão removidos."
		putnow "privmsg $chan :Exemplo: \002!definir rtp1 rtp2 sic tvi\002"
		putnow "privmsg $chan :Use \002!definir -f <lista>\002 para forçar o registo. O \002-f\002 tem de estar logo a seguir a \002!definir\002."
		return
	}
	set nomescanais ""
	foreach canal [lsort [array names programacao]] {
		lappend nomescanais $canal [lindex $programacao($canal) 0]
	}
	set text2 ""
	set exflag ""
	set eliminartudo ""
	foreach item $text {
		set flag ""
		if {$item=="-"} {
			set eliminartudo "sim"
			set flag "sim"
		}
		if {$flag==""} {
			lappend text2 $item
		}
	}
	if {$eliminartudo=="sim"} {
		set nickencontrado "nao"
		set naoadicionar ""
		set fnicks [open $fichnicks r]
		set fnicksnew [open $fichnicks.new w+]
		while {![eof $fnicks]} {
			gets $fnicks linhax
			if {[eof $fnicks]} {break}
			if {$nick==[lindex $linhax 0]} {
				set nickencontrado "sim"
				set naoadicionar "naoadicionar"
			}
			if {$naoadicionar!=""} {
				set naoadicionar ""
			} else {
				puts $fnicksnew $linhax
			}
		}
		close $fnicks
		close $fnicksnew
		file delete -force $fichnicks
		file rename -force $fichnicks.new $fichnicks
		if {$nickencontrado=="sim"} {
			putnow "privmsg $chan :O seu nick e os seus canais foram eliminados do registo. :("
		} else {
			putnow "privmsg $chan :O seu nick não está registado. Tente adicionar canais com \002!definir <canal1> <canal2> ...\002 ou, se estiver a definir canais, remova o \002-\002 (traço) da lista que pretende registar."
		}
		return
	}
	if {$text2==""} {
		putnow "privmsg $chan :Não especificou canais."
		return
	}
	set listanaoreconhecida ""
	foreach itext2 $text2 {
		set itemencontrado ""
		foreach {s n} $nomescanais {
			if {[string tolower $s]==[string tolower $itext2]} {
				set itemencontrado "sim"
				break
			}
		}
		if {$itemencontrado==""} {
			lappend listanaoreconhecida $itext2
		}
	}
	if {$forcar=="nao"} {
		if {$listanaoreconhecida!=""} {
			putnow "privmsg $chan :Não conheço: $listanaoreconhecida"
			foreach canaldesc $listanaoreconhecida {
				set canalpesq [lsort [lsearch -all -inline [array names programacao] *$canaldesc*]]
				if {[llength $canalpesq]==0} {
					putnow "privmsg $chan :Não encontrei nada para \002$canaldesc\002."
				} else {
					if {[llength $canalpesq]==1} {
						putnow "privmsg $chan :Para \002$canaldesc\002, você queria dizer...? \002$canalpesq\002"
					} else {
						putnow "privmsg $chan :Para \002$canaldesc\002, encontrei \002$canalpesq\002"
					}
				}
			}
			return
		}
	} else {
		putquick "privmsg $chan :Modo FORÇAR activado."
	}
	
	set nickencontrado "nao"
	set fnicks [open $fichnicks r]
	set fnicksnew [open $fichnicks.new w+]
	while {![eof $fnicks]} {
		gets $fnicks linhax
		if {[eof $fnicks]} {break}
						#putlog $linhax
		if {$nick==[lindex $linhax 0]} {
			set nickencontrado "sim"
			puts $fnicksnew "$nick $text2 $exflag"
		} else {
			puts $fnicksnew $linhax
		}
	}
	if {$nickencontrado=="nao"} {
		puts $fnicksnew "$nick $text2 $exflag"
	}
	close $fnicks
	close $fnicksnew
	file delete -force $fichnicks
	file rename -force $fichnicks.new $fichnicks
	if {$nickencontrado=="sim"} {
		putnow "privmsg $chan :Alterações registadas."
	} else {
		if {[llength $text2]==1} {
			putnow "privmsg $chan :O seu nick foi adicionado e o seu canal foi registado."
		} else {
			putnow "privmsg $chan :O seu nick foi adicionado e os seus canais foram registados."
		}
	}
}

proc scriptupdate {min hora dia mes ano} {
	global urldoscript datadabuild
	putlog "GuiaTV: A verificar por actualização do script ..."
	set gitfile [exec wget -q -O - $urldoscript]
	putlog [lindex [split $gitfile "\n"] 0]
}

 proc timevalidate {format str} {
     # Start with a simple check: If the string cannot be parsed against
     # the specified format at all it's definitely wrong
     if {[catch {clock scan $str -format $format} time]} {return 0}

     # Create a table for translating the supported clock format specifiers
     # to scan format specifications
     set map {%a %3s %A %s %b %3s %B %s %d %2d %D %2d/%2d/%4d
        %e %2d %g %2d %G %4d %h %s %H %2d %I %2d %j %3d
        %J %d %k %2d %l %2d %m %2d %M %2d %N %2d %p %2s
        %P %2s %s %d %S %2d %t \t %T %2d:%2d:%2d %u %1d
        %V %2d %w %1d %W %2d %y %2d %Y %4d %z %4d %Z %s
     }

     # Build the scan format string out of the clock format string
     set scanfmt [string map $map $format]

     # Recreate the time string from the seconds value
     set tmp [clock format $time -format $format]

     # Scan both versions of the string representation
     set list1 [scan $str $scanfmt]
     set list2 [scan $tmp $scanfmt]

     # Compare all elements as numbers and strings
     foreach n1 $list1 n2 $list2 {
        if {$n1 != $n2 && ![string equal -nocase $n1 $n2]} {return 0}
     }

     # Declare the time string valid since all elements matched
     return 1
}

proc formatbytes {value} {
    if {$value < 1000} {
      return [format "%s B" $value]
    } else {
		set len [string length $value]
        set unit [expr {($len - 1) / 3}]
		return [format "%.2f %s" [expr {$value / pow(1024,$unit)}] [lindex [list B KB MB GB TB PB EB ZB YB] $unit]]
    }
}

proc prglista {nick uhost handle text} {
	if {![file exist tvprogs.txt]} {
		set fp [open tvprogs.txt w+]
		close $fp
		putlog "GuiaTV: novo ficheiro tvprogs.txt criado."
	}

	set fp [open tvprogs.txt]
	set content [read -nonewline $fp]
	close $fp

	foreach linha [split $content "\n"] {
		if {$nick==[lindex [split $linha "|"] 0]} {
			foreach {a b c d e f g h} [lrange [split $linha "|"] 1 end] {
				putquick "privmsg $nick :[format "%-*s %-*s %-*s %-*s %-*s %-*s %-*s %-*s" 20 $a 20 $b 20 $c 20 $d 20 $e 20 $f 20 $g 20 $h]"
			}
			return
		}
	}
	putquick "privmsg $nick :O seu nick não está na lista de nicks."
}

########END END END END END END END END END END
