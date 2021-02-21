set sfdatascript "21-Fevereiro-2021"
bind pub - "!res" futebol

proc futebol {nick host handle chan text} {
	set text [string tolower $text]
	if {[lindex $text 0]=="ajuda"} {
		putquick "privmsg $chan :Sem argumentos, mostra os jogos do dia de hoje. Argumentos disponíveis: ontem amanhã todos"
		return
	}
	catch {set webdata [exec wget -q -O - https://desporto.sapo.pt/futebol/competicao/primeira-liga-2/calendario]}
    if {$webdata==""} {
        putlog "\0034Erro ao obter html."
        return
    }
   	putlog "SAPO Futebol: Html obtido."
	set webdata [string map {" _match-has-odds" ""} $webdata]
        set equipadacasa [regexp -all -inline -- {match-team-home\" data-team-url=\"\/futebol\/equipas\/(.*?)\">  <span class=\"\[ hide-tiny hide-small \] team-name team-name-short\">(.*?)</span> <span class=\"\[ hide-medium hide-large hide-xlarge \] team-name team-name-initials\">(.*?)<\/span>  <img} $webdata]
        set resultado [regexp -all -inline -- {<span class=\"home-team-score\">(.*?)<\/span> <span> - <\/span> <span class=\"away-team-score\">(.*?)<\/span>} $webdata]
#set equipavisitante [regexp -all -inline -- {match-team-away\" data-team-url=\"\/futebol\/equipas\/(.*?)">   <img src=\"\/\/thumbs.web.sapo.io\/\?epic=(.*?)center&png=1\" alt=\"\" class=\"team-logo team-logo-away\">  <span class=\"\[ hide-tiny hide-small \] team-name team-name-short\">(.*?)<\/span> <span class=\"\[ hide-medium hide-large hide-xlarge \] team-name team-name-initials\">(.*?)<\/span>} $webdata]
set equipavisitante [regexp -all -inline -- {match-team-away\" data-team-url=\"/futebol/equipas/(.*?)\">   <img src=\"//thumbs.web.sapo.io/(.*?)\" alt=\"\" class=\"team-logo team-logo-away\">  <span class=\"\[ hide-tiny hide-small \] team-name team-name-short\">(.*?)</span>} $webdata]
		set tv [regexp -all -inline -- {match-tv-emission\">  <span>(.*?)<\/span>} $webdata]
        set horas [regexp -all -inline -- {match-date\"><span class=\"day\">(.*?)<\/span> <span class=\"month\">(.*?)<\/span> <span class=\"year\">(.*?)<\/span> <span class=\"time\">(.*?)<\/span><\/div>} $webdata]
        set estado [regexp -all -inline -- {match status-id--(.*?)  \" data-match-id} $webdata]
        set parte [regexp -all -inline -- {match-current-period">(.*?)</div>} $webdata]
        set lequipadacasa ""; set lresultados ""; set lequipavisitante ""; set ltv ""
        set lhoras ""

#       putquick "privmsg $chan :$estado"
        foreach {- - equipa equipasigla} $equipadacasa {
                lappend lequipadacasa $equipa
        }
        foreach {- p1 p2} $resultado {
                lappend lresultado "$p1-$p2"
        }
        foreach {- - - equipa} $equipavisitante {
                lappend lequipavisitante $equipa
        }
        foreach {- canal} $tv {
                lappend ltv $canal
        }
		#e porque os meses devia começar por maiúsculas... meter um totitle
        foreach {- dia mes ano hora} $horas {
                lappend lhoras "$dia/[string totitle $mes] $hora"
        }
        set lestado ""
        foreach {- idestado} $estado {
#               putquick "privmsg $chan :$idestado"
                if {$idestado==1} {set idestado "(Terminado)"}
                if {$idestado==2} {set idestado "(A decorrer)"}
                if {$idestado==3} {set idestado "(Agendado)"}
#               putquick "privmsg $chan :$idestado"
                lappend lestado "$idestado"
        }
        set lparte ""
        foreach {- parten} $parte {
                lappend lparte "$parten"
        }

		if {$text!="todos"} {		
			if {$text==""} {
				set sfdatacomp "today"
			} elseif {$text=="ontem"} {
				set sfdatacomp "yesterday"
			} elseif {$text=="amanhã"} {
				set sfdatacomp "tomorrow"
			} else {
				putquick "privmsg $chan :Não reconhecido, use ajuda."
				return
			}
			set sfdatacomp [string map {"Feb" "Fev" "Apr" "Abr" "May" "Mai" "Aug" "Ago" "Sep" "Set" "Oct" "Out" "Dec" "Dez"} [clock format [clock scan $sfdatacomp] -format "%d/%b"]]
		}

	set output ""
	
    foreach equipadacasa $lequipadacasa resultado $lresultado equipavisitante $lequipavisitante tv $ltv dmyh $lhoras estado $lestado parte $lparte {
        if {$estado!="(A decorrer)"} {
            set parte ""
        } else {
            set parte "$parte "
        }

		if {$text=="todos" || [lindex $dmyh 0]==$sfdatacomp} {
			lappend output "\002$dmyh\002 $equipadacasa $resultado $equipavisitante \0037$estado $parte\0034$tv\003"
		}
	}
	if {$output==""} {
		putquick "privmsg $chan :Não há jogos hoje."
		return
	}
	
	putquick "privmsg $chan :[string trimright "[lindex $output 0]  [lindex $output 1]  [lindex $output 2]  [lindex $output 3]  [lindex $output 4]"]"
	putquick "privmsg $chan :[string trimright "[lindex $output 5]  [lindex $output 6]  [lindex $output 7]  [lindex $output 8]"]"


}

putlog "SAPO FUTEBOL build $sfdatascript"
