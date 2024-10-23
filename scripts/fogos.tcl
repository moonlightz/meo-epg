#bind dcc - fogos dcc:fogos
#proc dcc:fogos {handle idx text} {}


bind time - "*0 * * * *" fptbuff
bind time - "* * * * *" fptchan

proc fptchan {min hor dia mes ano} {
	global fogosptbuff
	if {![info exists fogosptbuff]} {set fogosptbuff ""}
	set contadorl 0
	set contadori 0
	foreach linha $fogosptbuff {
		if {[isnumber [lindex $linha 0]]} {
			incr contadori
			if {$contadori>3} {
				break
			}
		}
		putquick "privmsg #fogos.pt :$linha"
		incr contadorl
	}
	set fogosptbuff [lrange $fogosptbuff $contadorl end]
}

proc fptbuff {min hor dia mes ano} {
	global fogosptbuff
	if {![info exists fogosptbuff]} {set fogosptbuff ""}
	set html [string map {".-" ", -" "\n" ""} [exec wget -q -O - https://fogos.pt/lista]]
	set compcol "11 11 10 20 20 22 12 3 3 3"
	set sformat ""
	foreach icompcol $compcol {
		append sformat " %-${icompcol}s "
	}

	lappend fogosptbuff "\037\0030,3[format $sformat ID Início Distrito Concelho Freguesia Localidade Estado 👨‍ 🚒 🚁]"

	#$id $data $distrito $concelho $freguesia $localidade $estado $oper $meiosterrestres $meiosaereos
	set cor ""
	foreach {match link id data distrito concelho freguesia localidade idestado estado oper meiosterrestres meiosaereos} [regexp -all -inline {<tr><td><a href="(.*?)">(.*?)</a></td><td>(.*?)</td><td>(.*?)</td><td>(.*?)</td><td>(.*?)</td><td>(.*?)</td><td><div><span class="dot status-(.*?)" style="display:inline-block;position:relative"></span> <span class="status-label">(.*?)</span></div></td><td>(.*?)</td><td>(.*?)</td><td>(.*?)</td></tr>} $html] {
		set oid ""; set odata ""; set odistrito ""; set oconcelho ""; set ofreguesia ""; set olocalidade ""; set oestado ""; set ooper ""; set omeiosterrestres ""; set omeiosaereos ""
		foreach ivar {id data distrito concelho freguesia localidade estado oper meiosterrestres meiosaereos} indx {0 1 2 3 4 5 6 7 8 9} {
			set buff ""
			foreach palavra [subst $$ivar] {
				if {[string length [string trim "$buff $palavra"]]>[lindex $compcol $indx]} {
					lappend o$ivar $buff
					set buff $palavra
				} else {
					if {$buff eq ""} {
						set buff $palavra
					} else {
						set buff "$buff $palavra"
					}
				}
				
			}
			if {$buff != ""} {
				lappend o$ivar $buff
			}
			if {$ivar=="estado"} {
				lappend oestado  [switch $idestado {
					4 {set a "⏰"}
					6 {set a "📍"}
					7 {set a "\00310🔥"}
					8 {set a "\00312🔥"}
					9 {set a "👁"}
					default {set idestado}
					}]
			}
		}

		foreach a $oid b $odata c $odistrito d $oconcelho e $ofreguesia f $olocalidade g $oestado h $ooper i $omeiosterrestres j $omeiosaereos {
			lappend fogosptbuff "$cor[format $sformat $a $b $c $d $e $f $g $h $i $j]"
		}
		if {$cor==""} {
			set cor ""
		} else {
			set cor ""
		}
	}
}
