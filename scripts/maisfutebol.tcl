#bind dcc - "fut" dcc:fut
set mfscriptdata "27-Junho-2021"
if {![info exists mfcache]} {set mfcache ""}
if {![info exists relatos]} {set relatos ""}

#proc dcc:fut {indx handle text} {}

#minuto a minuto por defeito
bind time - "* * * * *" maisfutebol

proc maisfutebol {min hora dia mes ano} {
	global mfcache relatos
	#set mfjm $mfcache

#	putlog "A obter página principal..."
 	set mfjm [string map {
		"  " "" "\n\n" "\n" "\}" ")" "\{" "(" "\&nbsp\;" "" "\;" "-" \" \' "\&\#039\;" "'"
		} [exec wget -q -O- https://maisfutebol.iol.pt/jogo/aominuto]]
	set mfjm [string map {"\n\n" "\n"  } $mfjm]
#	putlog "[string length $mfjm] bytes obtidos."
	set mfcache $mfjm

	if {[string first "aovivoList" $mfjm]==-1} {
		putlog "Não foi encontrado aovivoList no html"
		return
	}
	set mfsplit [split $mfjm "\n"]
	set mfsplit [lrange $mfsplit [lsearch $mfsplit *aovivoList*]+2 end]

	set mftipodados ""
	array set jogos {}
	set mfn 0

	foreach linha $mfsplit {
#	putdcc 9 $linha
        if {$linha=="<li class='dateRow'>"} {
            set mftipodados "data"
            incr mfn
        }
		if {[string first "title=" $linha]>0} {
			set mfeqpos [expr [string first "title=" $linha]+7]
			lappend jogos($mfn) [string range $linha $mfeqpos [string first "'" $linha $mfeqpos]-1]
			continue
		}
		if {[string first "<span class='middleCell resultCell'>" $linha]>=0} {
			set mfrespos [expr [string first "<span class='middleCell resultCell'>" $linha]+36]
			set mfrescell [string range $linha $mfrespos [string first "<" $linha $mfrespos]-1]
			if {$mftipodados==""} {
				set mftipodados $mfrescell
				continue
			} else {
				lappend jogos($mfn) "$mftipodados-$mfrescell"
				set mftipodados ""
			}
		}
		if {[string first "<span class='middleCell dateCell'>" $linha]>=0} {
            set mfrespos [expr [string first "<span class='middleCell dateCell'>" $linha]+34]
            lappend jogos($mfn) [string range $linha $mfrespos [string first "<" $linha $mfrespos]-1]
        }


        if {$mftipodados=="data1"} {set jogos($mfn) $linha; set mftipodados ""; continue }
        if {$mftipodados=="data"} {
            if {$linha=="<div class=''>"} {set mftipodados "data1"}
            if {$linha=="<div class='minuto'>"} {set mftipodados "data1"}
            if {$linha=="<div class='minuto'>LIVE</div>"} {
                set jogos($mfn) "LIVE"; set mftipodados ""
            }
			continue
        }

		if {[string range $linha 0 8]=="<a href='" } {
			lappend jogos($mfn) "https://maisfutebol.iol.pt[string range $linha 9 end-3]\?tab=aominuto"
			continue
		}

		if {$linha=="</ul>"} {
			break
		}
	}
#	putlog "-----------------------------"
	set listajogos ""
	foreach linha [array names jogos] {
	#	putdcc 9 "$jogos($linha)"
		if {[lindex $jogos($linha) 0]=="HOJE"} {
			if {[string first "-" [lindex $jogos($linha) 3]]>0} {
				lappend listajogos "[lindex $jogos($linha) 2] \002[lindex $jogos($linha) 3]\002 [lindex $jogos($linha) 4]"
			} else {
				lappend listajogos "\002[string map {"h" ":"} [lindex $jogos($linha) 3]]\002 [lindex $jogos($linha) 2] vs [lindex $jogos($linha) 4]"
			}
			foreach itemx [lreverse [obterrelato [lindex $jogos($linha) 1] [lindex $jogos($linha) 2] [lindex $jogos($linha) 3] [lindex $jogos($linha) 4]]] {
    	  		if {[lsearch $relatos $itemx]==-1} {
					putquick "privmsg #futebol :$itemx"
					lappend relatos $itemx
				}
			}
		}
		if {[lindex $jogos($linha) 0]=="LIVE"} {
            lappend listajogos "\0034\002>LIVE>\002 [lindex $jogos($linha) 2] \002[lindex $jogos($linha) 3]\002 [lindex $jogos($linha) 4]\003"
#			putquick "privmsg #futebol :[lindex [obterrelato [lindex $jogos($linha) 1] [lindex $jogos($linha) 2] [lindex $jogos($linha) 3] [lindex $jogos($linha) 4]] 0]"
            foreach itemx [lreverse [obterrelato [lindex $jogos($linha) 1] [lindex $jogos($linha) 2] [lindex $jogos($linha) 3] [lindex $jogos($linha) 4]]] {
                if {[lsearch $relatos $itemx]==-1} {
                    putquick "privmsg #futebol :$itemx"
                    lappend relatos $itemx
                }
            }

        }
	}
	set listajogos [lsort -increasing $listajogos]
	set listajogos2 ""
	foreach linha $listajogos {
		append listajogos2 "$linha, "
	}
	set listajogos [string trimright $listajogos2 ", "]
#putdcc 9 ">$listajogos<"	
	if {$listajogos==""} {
		set listajogos "Não há jogos ainda."
		set relatos ""
		catch {unbind time - "* * * * *" maisfutebol}
		catch {bind time - "*0 * * * *" maisfutebol}
	} else {
		catch {unbind time - "*0 * * * *" maisfutebol}
		catch {bind time - "* * * * *" maisfutebol}
	}
	if {[topic #futebol]!="JOGOS: $listajogos"} {
		set novotopico "JOGOS: $listajogos"
		#1) o bot muda o topic, 2) o bot usa o chanserv para mudar o topico
		putserv "topic #futebol :$novotopico"
		#putserv "chanserv topic #futebol $novotopico"
        
		putlog "A alterar o tópico para: $novotopico"
	}
	#putlog "FIM"
}

#########
proc obterrelato {url equipaA resultado equipaB} {
#putlog ">$url<"
	set jrelato ""
	package require tls
	package require http
	package require uri::urn
    http::register https 443 [list tls::socket -tls1 1]
	set token [::http::geturl $url]
       set data [string map {
		"  " "" "\n" ""
		"<small class='minuto-extra' style='font-size:14px; display:inline;'>" ""
		"</small>" ""
			} [::http::data $token]]
       ::http::cleanup $token          
#       set f [open f.txt w+]
#		puts $f $data
#	close $f


		set mfcespeciais [regexp -all -inline {\&\#(.*?)\;} $data]
		#putdcc 9 ">$mfcespeciais<"
		set mfksymb ""
		foreach {mfm1 mfm2} $mfcespeciais {
			if {[lsearch $mfksymb $mfm1]<0} {lappend mfksymb $mfm1} {continue}
			set mfm2 [format "%c" [string trimleft $mfm2 "0"]]
			set data [string map [list $mfm1 $mfm2] $data]
		}



		set count 0
		set amarelo ""; set amareloeq ""
		set entra ""; set entraeq ""; set sai ""; set saieq ""
		set goleador ""; set goleadoreq ""
		foreach {match -} [regexp -all -inline -- {<li class=\"\" id=\"evento(.*?)</script></li>} $data] {
			#incr count
			regexp {<div class=\"minuto\">(.*?)<} $match -> minuto
			regexp {<div class=\"evento-texto\">(.*?)</div>} $match -> eventotexto
			set eventotexto [string replace $eventotexto [string first "<" $eventotexto] [string first ">" $eventotexto]]			
			
			regexp {'YELLOW_CARD'\,.*\,.*\,'(.*)','(.*?)','(.*?)'} $match -> amarelo amareloeq
			regexp {'SUB_IN'\,.*\,.*\,'(.*)','(.*?)','(.*?)',} $match -> entra entraeq
			regexp {'SUB_OUT'\,.*\,.*\,'(.*)','(.*?)','(.*?)',} $match -> sai saieq
			regexp {'GOAL'\,.*\,.*\,'(.*)','(.*?)','(.*?)',} $match -> goleador goleadoreq


			if {$amarelo!=""} {
				set eventotexto "\0038,8+\003 Cartão amarelo para $amarelo ($amareloeq)"
				set amarelo ""; set amareloeq ""
			}
			if {$entra!=""} {
				set eventotexto "\002\0039<==\003\002 Entra $entra ($entraeq)"
				set entra ""; set entraeq ""
			}
			if {$sai!=""} {
                set eventotexto "\002\0034==>\003\002 Sai $sai ($saieq)"
                set sai ""; set saieq ""
            }
			if {$goleador!=""} {
				set eventotexto "\002\0034GOOOOOLO!!!\003\002 de $goleador ($goleadoreq) - $eventotexto"
				set goleador ""; set goleadoreq ""
			}
			if {[string first "'BEGIN_2ND_OVERTIME'" $match]>0} {set eventotexto "Começa a 2ª parte do prolongamento do $equipaA-$equipaB."}
			if {[string first "'END_1ST_OVERTIME'" $match]>0} {set eventotexto "Fim da 1ª parte do prolongamento do $equipaA-$equipaB."}
			if {[string first "'BEGIN_1ST_OVERTIME'" $match]>0} {set eventotexto "Início da 1ª parte do prolongamento do $equipaA-$equipaB."}

			if {[string first "'BEGIN_2ND_HALF'" $match]>0} {set eventotexto "Início da 2ª parte do $equipaA-$equipaB."}
            if {[string first "'END_1ST_HALF'" $match]>0} {set eventotexto "Fim da 1ª parte do $equipaA-$equipaB"}
			if {[string first "'END'" $match]>0} {set eventotexto "Fim do jogo. $equipaA\([lindex [split $resultado "-"] 0]) - $equipaB\([lindex [split $resultado "-"] 1]). $eventotexto"}
			if {[string first "'BEGIN'" $match]>0} {set eventotexto "Início do $equipaA-$equipaB. $eventotexto"}

			if {[string first "'VIDEO_EMBEDDED'" $match]>0} {
				set match [uri::urn::unquote $match]
				set linkvideo "maisfutebol.iol.pt"
				 regexp {'VIDEO_EMBEDDED'\,.*\,.*\,'.*','.*','.*','.*www\.(.*?)\".*'} $match -> linkvideo
				if {$linkvideo=="maisfutebol.iol.pt"} {
					regexp {'VIDEO_EMBEDDED'\,.*\,.*\,'.*','.*','.*','.*https://(.*?)\".*'} $match -> linkvideo
					#putdcc 10 "$match"
				}
				if {$eventotexto==""} {set eventotexto "Vídeo"}
                set eventotexto "$eventotexto - www.$linkvideo"
            
			}

			if {[string first "'OUTRO_EMBEDDED'" $match]>0} {
                set match [uri::urn::unquote $match]
                set linkvideo "maisfutebol.iol.pt"
                 regexp {'OUTRO_EMBEDDED'\,.*\,.*\,'.*','.*','.*','.*www\.(.*?)\".*'} $match -> linkvideo
                if {$linkvideo=="maisfutebol.iol.pt"} {
                    regexp {'OUTRO_EMBEDDED'\,.*\,.*\,'.*','.*','.*','.*https://(.*?)\?.*'} $match -> linkvideo

#                    putdcc 9 "$match"
                }
				
                if {$eventotexto==""} {set eventotexto "Vídeo"}
                set eventotexto "$eventotexto - www.[lindex [split $linkvideo "\&"] 0]"

            }

			
			if {[string first "'MULTIMEDIA_FOTO'" $match]>0} {
				set match [uri::urn::unquote $match]
				regexp {'MULTIMEDIA_FOTO'\,.*\,.*\,'.*','.*','.*','.*https://(.*?)\".*'} $match -> linkphoto
				set eventotexto "$eventotexto - $linkphoto"
			}

			if {$minuto=="0'"} {set minuto ""} {set minuto "$minuto: "}


			set textofinal "$minuto$eventotexto"

			lappend jrelato $textofinal
			#putdcc 9 $textofinal
			#if {$count>100} {break}
		}
		
	return $jrelato
}
putlog "mais futebol $mfscriptdata by moonlight"
