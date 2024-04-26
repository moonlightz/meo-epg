#Este script adiciona a funcionalidade de trigger aos canais.
set ct(builddate) "18-Julho-2021"

set ct(definicoes) "scripts/chantriggers.settings"
#ficheiro com definições
if {![file exists $ct(definicoes)]} {
	putlog "CHANTRIGGERS: $ct(definicoes) está em falta! A tentar recriar o ficheiro ..."
	set fd [open $ct(definicoes) w+]
	puts $fd "\#vars do chantriggers.tcl"
	puts -nonewline $fd "\n"
	puts $fd "\#localização da db"
	puts $fd "set ct(database) \"scripts/chantriggers.db\""
	puts -nonewline $fd "\n"
	puts $fd "\#caracter usado nos canais"
	puts $fd "set ct(triggerchar) \"!\""
	puts -nonewline $fd "\n"
	puts $fd "\#lista de canais"
	puts $fd "set ct(channels) \"\#code \#guiatv\""
	close $fd
	putlog "CHANTRIGGERS: Feito. A prosseguir ..."
}
source $ct(definicoes)

if {![info exists ct(canalescolhido)]} {set ct(canalescolhido) ""}

bind pubm - "* $ct(triggerchar)*" pubmctchan
bind dcc - "seleccanal" dcc:seleccanal
bind dcc - "vertrigger" dcc:vertrigger
bind dcc - "adictrigger" dcc:adictrigger
bind dcc - "remtrigger" dcc:remtrigger
bind dcc - "listtriggers" dcc:listtriggers
bind dcc - "pesqtrig" dcc:pesqtrig
bind pub - "${ct(triggerchar)}listtriggers" publisttriggers
bind dcc - "trighelp" dcc:trighelp
bind dcc - "estadodb" dcc:estadodb
bind dcc - "moverind" dcc:moverindice
bind dcc - "copiartrig" dcc:copiartriggers

#######################################################################
proc dcc:estadodb {indx hand text} {
	global ct
	if {![file exists $ct(database)]} {
		putdcc $hand "$ct(database) não existe."
	} else {
		if {![file readable $ct(database)]} {set legivel "NÃO"} {set legivel "SIM"}
		if {![file writable $ct(database)]} {set escrevivel "NÃO"} {set escrevivel "SIM"}
		set atempo [string map {
                   "Mon" "Seg" "Tue" "Ter" "Wed" "Qua" "Thu" "Qui" "Fri" "Sex" "Sat" "Sáb" "Sun" "Dom"
                   "Feb" "Fev" "Apr" "Abr" "May" "Mai" "Aug" "Ago" "Oct" "Out" "Dec" "Dez"
                   } [clock format [file atime $ct(database)] -format "%a, %d/%b/%Y %H:%M:%S"]]
		set mtempo [string map {
                   "Mon" "Seg" "Tue" "Ter" "Wed" "Qua" "Thu" "Qui" "Fri" "Sex" "Sat" "Sáb" "Sun" "Dom"
                   "Feb" "Fev" "Apr" "Abr" "May" "Mai" "Aug" "Ago" "Oct" "Out" "Dec" "Dez"
                   } [clock format [file mtime $ct(database)] -format "%a, %d/%b/%Y %H:%M:%S"]]


		putdcc $hand "Nome da base de dados: $ct(database)  Tamanho: [file size $ct(database)] bytes  Legivel: $legivel  Escrevivel: $escrevivel"
		putdcc $hand "Último acesso a: $atempo  Última modificação a: $mtempo"
	}
}

########################################################################
proc pubmctchan {nick uhost hand chan text} {
	global ct
	if {![file exists $ct(database)]} {
		putlog "CHANTRIGGERS: $ct(database) não existe."
		set fd [open $ct(database) w+]
		close $fd
		if {![file exists $ct(database)]} {
			putlog "CHANTRIGGERS: Não foi possível criar um ficheiro vazio. Verifique se a string está bem definida ou se tem permissões suficientes."
		} else {
			putlog "CHANTRIGGERS: Um novo ficheiro vazio foi criado. Adicione um trigger pelo menos."
		}
		return
	}

	set cttemp [split $text " "]
	set cttrigpedido [string range [lindex $cttemp 0] 1 end]

	#identificadores###################################################################
    set alvo [lindex $cttemp 1]
	if {$alvo==""} {set alvo $nick}
	set hora [clock format [clock seconds] -format "%T"]
	set data [string trim [string map {
		"Feb" "Feb" "Apr" "Abr" "May" "Mai" "Aug" "Ago" "Sep" "Set" "Oct" "Out" "Dec" "Dez"
		} [clock format [clock seconds] -format "%e/%b/%Y"]]]
	##########################################################



	#ler o ficheiro para a memória
	set linhas [ctlerdb $ct(database)]

	#procurar pelo trigger pedido
	foreach linha $linhas {
		set dbtemp [split $linha " "]
		set dbchan [lindex $dbtemp 0]
		set dbtrig [lindex $dbtemp 1]
		set dbtext [string range $linha [expr [string length $dbchan]+[string length $dbtrig]+2] end]
		if {([string tolower $chan]==[string tolower $dbchan])&&($cttrigpedido==$dbtrig)} {
			putquick "privmsg $chan :[subst $dbtext]"

		}
	}

}

proc dcc:trighelp {indx hand text} {
	global ct
	putdcc $hand "ChanTriggers $ct(builddate)"
	putdcc $hand "  .listtriggers \[canal\]          -> Mostra os triggers. Sem canal, mostra tudo, se não mostra os desse canal."
	putdcc $hand "  .seleccanal <canal>            -> Selecciona um canal para trabalhar com os trigger."
	putdcc $hand "  .adictrigger <trigger> <texto> -> Adiciona um trigger ao canal seleccionado."
	putdcc $hand "  .vertrigger <trigger>          -> Mostra o texto relacionado com esse trigger."
	putdcc $hand "  .remtrigger <trigger> n n1 ... -> Remove um trigger ao canal seleccionado ou a(s) linha(s) que especificar."
	putdcc $hand "  .pesqtrig <termo>              -> Pesquisa o termo especificado nos triggers."
	putdcc $hand "  ${ct(triggerchar)}listtriggers                  -> Num canal, mostrará a lista de triggers desse canal."
	putdcc $hand "  ${ct(triggerchar)}trigger                       -> Num canal, mostrar o texto associado a esse trigger."
}


proc dcc:pesqtrig {indx hand text} {
	global ct
	set text [string trim $text]
	if {$text==""} {
		putdcc $hand "Use .pesqtrig <termo> para pesquisar texto nos triggers."
		putdcc $hand "A pesquisa não diferencia maiusculas de minusculas."
		return
	}
	regsub { } "*$text*" "*" text
	set linhas [ctlerdb $ct(database)]
	set contagem 0

	foreach linha $linhas {
		if {[string match $text $linha]>0} {
			putdcc $hand "No trigger \002[lindex $linha 1]\002 do canal \002[lindex $linha 0]\002:"
			putdcc $hand "  [string range $linha [expr [string length [lindex $linha 0]]+[string length [lindex $linha 1]]+2] end]"
			incr contagem
		}
	}
	if {$contagem==0} {
		putdcc $hand "Nada foi encontrado."
	}
}


proc dcc:adictrigger {indx hand text} {
	global ct
	if {$ct(canalescolhido)==""} {
		putdcc $hand "Não há um canal seleccionado. Use .seleccanal #canal para seleccionar um."
		return
	}
	set text [string trim $text]

	set trig [regsub -all {[^a-zA-Z0-9ç_-]} [string range $text 0 [string first " " $text]-1] ""]
	set text [string range $text [string first " " $text]+1 end]
	
	if {$trig=="" || $text==""} {
		putdcc $hand ".adictrigger <trig> <text>"
		putdcc $hand "Pode ser usado comandos e algumas vars para substituição"
        putdcc $hand "\$alvo -> $ct(triggerchar)trigger nick | \$chan -> canal actual"
        putdcc $hand "\$hora -> hora          | \$data -> data"
 		return
	}

	#abrir o ficheiro para leitura e escrita com posição no final do ficheiro
	set fd [open $ct(database) a+]
	puts $fd "$ct(canalescolhido) $trig $text"
	close $fd
	putdcc $hand "\002$trig\002 adicionado a $ct(canalescolhido)."
}

proc dcc:vertrigger {indx hand text} {
    global ct
    if {$ct(canalescolhido)==""} {
        putdcc $hand "Não há um canal seleccionado. Use .seleccanal #canal para seleccionar um."
        return
    }
	set text [string trim $text]
	if {$text==""} {
		putdcc $hand "Use .vertrigger <trigger> para ver o conteúdo de um trigger."
		return
	}


    if {![file exists $ct(database)]} {
        putlog "CHANTRIGGERS: $ct(database) não existe."
        set fd [open $ct(database) w+]
        close $fd
        if {![file exists $ct(database)]} {
            putlog "CHANTRIGGERS: Não foi possível criar um ficheiro vazio. Verifique se a string está bem definida ou se tem permissões suficientes."
        } else {
            putlog "CHANTRIGGERS: Um novo ficheiro vazio foi criado. Adicione um trigger pelo menos."
        }
        return
    }

    set cttemp [split $text " "]
    set cttrigpedido [lindex [split $cttemp " "] 0]


    #ler o ficheiro para a memória
    set linhas [ctlerdb $ct(database)]

    #procurar pelo trigger pedido
	set contagem 0
	set corfundo 2
    foreach linha $linhas {
        set dbtemp [split $linha " "]
        set dbchan [lindex $dbtemp 0]
        set dbtrig [lindex $dbtemp 1]
        set dbtext [string range $linha [expr [string length $dbchan]+[string length $dbtrig]+2] end]
        if {([string tolower $ct(canalescolhido)]==[string tolower $dbchan])&&($cttrigpedido==$dbtrig)} {
			incr contagem
			if {$corfundo==2} {set corfundo 6} {set corfundo 2}
            putdcc $hand [format "\0038,$corfundo %+*s \003 $dbtext" 3 $contagem]

        }
    }
}

proc dcc:seleccanal {indx hand text} {
	global ct


	if {$ct(channels)==""} {
		putdcc $hand "Defina a lista de canais no topo deste script."
		return
	}
	set text [string tolower [string trim $text]]
	if {$ct(canalescolhido)!=""} {
		putdcc $hand "O canal escolhido actualmente é: \002$ct(canalescolhido)\002"
	}

	if {$text==""} {
		putdcc $hand "Pode escolher um dos seguintes canais: $ct(channels)"
		return
	}

	if {[lsearch -exact [string tolower $ct(channels)] $text]<0} {
		putdcc $hand "Esse canal que digitou não está na lista. Tem de ser um destes: $ct(channels)"
	} else {
		if {$ct(canalescolhido)!=$text} {
			putdcc $hand "O canal \002$text\002 está agora seleccionado."
			set ct(canalescolhido) $text
		} else {
			putdcc $hand "Esse canal já está escolhido."
		}
	}
}

proc dcc:remtrigger {indx hand text} {
    global ct
    if {$ct(canalescolhido)==""} {
        putdcc $hand "Não há um canal seleccionado. Use .seleccanal #canal para seleccionar um."
        return
    }
    set text [string trim $text]
    #set trig [string tolower [lindex [split $text " "] 0]]
	set trig [lindex $text 0]
    #set indice [lindex [split $text " "] 1]
	

	 if {$trig==""} {
        putdcc $hand ".remtrigger <trig> \[indice1\] \[indice2\]..."
        return
    }
	
	set linhas [ctlerdb $ct(database)]
	set ctbk ""
 	set ctbk2 ""   
	set indices [lsort -unique -decreasing [lrange $text 1 end]]

    set trem "nao"
    foreach linha $linhas {
        set dbtemp [split $linha " "]
        set dbchan [lindex $dbtemp 0]
        set dbtrig [lindex $dbtemp 1]
        #set dbtext [string range $linha [expr [string length $dbchan]+[string length $dbtrig]+2] end]
        if {$dbchan==""} {continue}
        if {$dbchan==$ct(canalescolhido) && $dbtrig==$trig} {
			#todas as linhas com canal e trig encontrados vao para a segunda lista
			lappend ctbk2 $linha
			set trem "sim"
		} else {
			#caso contrario, adicionar à primeira lista
			lappend ctbk $linha
		}
    }

	if {$trem=="nao"} {
		putdcc $hand "'$trig' não foi encontrado no canal $ct(canalescolhido). Certifique-se que o nome do trigger está bem escrito. Nada será alterado."
		return
	}


	if {$indices!=""} {
		set tctbk2 [llength $ctbk2]

		foreach indice $indices {
			if {![isnumber $indice]} {
				putdcc $hand "'$indice' não é um número."
				return
			}
			if {$indice>$tctbk2} {
				putdcc $hand "'$indice' é maior que o número de elementos ($tctbk2) do trigger $trig do canal $ct(canalescolhido)."
				return
			}
			if {$indice==0} {
				putdcc $hand "'$indice' não é um indice válido."
				return
			}
		}	
		set ctbk3 ""
		foreach indice $indices {
			set linha [lindex $ctbk2 $indice-1]
			lappend ctbk3 ".adictrigger [string range $linha [string first " " $linha]+1 end]"
		}
		foreach linha [lreverse $ctbk3] {
			putdcc $hand $linha
		}
		foreach indice $indices {
			set ctbk2 [lreplace $ctbk2 $indice-1 $indice-1]
		}
		foreach linha $ctbk2 {		
			lappend ctbk $linha
		}
	} else {
		foreach linha $ctbk2 {
			putdcc $hand ".adictrigger [string range $linha [string first " " $linha]+1 end]"
		}
	}

	#putdcc $hand "-----"
	#foreach linha $ctbk {
	#	putdcc $hand "*** $linha"
	#}
	#putdcc $hand "-----"
	set fd [open $ct(database) w+] 
	foreach linha $ctbk {
		puts $fd $linha
	}
	close $fd
	putdcc $hand "Actualização do ficheiro concluída."
}

proc dcc:listtriggers {indx hand text} {
	#mostra os triggers dos canais numa lista, especificar um canal para só ver os desse canal
    global ct
	set linhas [ctlerdb $ct(database)]
	set text [string trim $text]
	if {[string index $text 0]=="#"} {set ctwchan [string tolower [lindex [split $text " "] 0]]} {set ctwchan ""}

	array set ltriggers {}
	foreach linha $linhas {
		set dbtemp [split $linha " "]
        set dbchan [string tolower [lindex $dbtemp 0]]
        set dbtrig [string tolower [lindex $dbtemp 1]]
		if {$dbchan!=""} {
			if {$ctwchan=="" || $dbchan==$ctwchan} {
				lappend ltriggers($dbchan) $dbtrig
			}
		}
	}

	set ltrigunique ""
	foreach ctchan [array names ltriggers] {
		set ltrigunique [lsort -unique -dictionary $ltriggers($ctchan)]	
		set ltrigs ""
		foreach litem $ltrigunique {
			lappend ltrigs "${litem}([llength [lsearch -all $ltriggers($ctchan) $litem]])"
		}

		set ctchantitulo " $ctchan - Triggers: [llength $ltrigs] "
		set cttl [expr 40-[string length $ctchantitulo]/2]
		putdcc $hand [string replace [string repeat "=" 80] $cttl [expr $cttl+[string length $ctchantitulo]+1] $ctchantitulo]
		
		foreach {t1 t2 t3 t4 t5 t6 t7 t8} $ltrigs {
			putdcc $hand "     $t1  $t2  $t3  $t4  $t5  $t6  $t7  $t8"
		}
	}
	if {$ltrigunique==""} {putdcc $hand "Não há triggers para esse canal."}
	

}

proc publisttriggers {nick uhost hand chan text} {
    #mostra os triggers disponivel do canal em notice
    global ct
    set linhas [ctlerdb $ct(database)]
    set text [string trim $text]

    array set ltriggers {}
    foreach linha $linhas {
        set dbtemp [split $linha " "]
        set dbchan [string tolower [lindex $dbtemp 0]]
        set dbtrig [string tolower [lindex $dbtemp 1]]
        if {$dbchan!=""} {
            if {$dbchan==$chan} {
                lappend ltriggers($dbchan) $dbtrig
            }
        }
    }

    set ltrigunique ""
    foreach ctchan [array names ltriggers] {
        set ltrigunique [lsort -unique -dictionary $ltriggers($ctchan)]
        set ltrigs ""
        foreach litem $ltrigunique {
            lappend ltrigs "${litem}([llength [lsearch -all $ltriggers($ctchan) $litem]])"
        }

        set ctchant "Triggers: [llength $ltrigs] -->"

        foreach {t1 t2 t3 t4 t5 t6 t7 t8} $ltrigs {
            puthelp "NOTICE $nick :$ctchant $t1  $t2  $t3  $t4  $t5  $t6  $t7  $t8"
			set ctchant ""
        }
    }
    if {$ltrigunique==""} {
		puthelp "NOTICE $nick :Não há triggers para este canal."
	}



}


proc ctlerdb {ficheiro} {
	#lê o ficheiro e devolve separado por linhas
    set fd [open $ficheiro r]
    set fdc [split [read -nonewline $fd] "\n"]
    close $fd
	return $fdc

}


putlog "ChanTriggers $ct(builddate) por moonlight, use .trighelp para saber os comandos"
putlog "Bugs, comentários, sugestões... visite o canal #CODE da rede de irc PTchat em irc.ptchat.org"
#fin
