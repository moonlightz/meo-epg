bind pub n "!xshzreset" resetexpire
bind pub - "!xshzfalta" contagemexpirar
#lista de canais para anúncio, um espaço separa o nome dos canais
set canaisexpirar "#bons_amigos #canal-de-merda"
set ficheiroexpirar "batatasdoces.txt"

proc contagemexpirar {nick host handle chan text} {
	set ultimotimebomb [lindex [lsearch -all -inline [binds] *timebomb] 0]
	if {$ultimotimebomb==""} {
		putquick "privmsg $chan :Os binds não foram encontrados."
		return
	} else {
		set ultimotimebomb [lindex $ultimotimebomb 2]
putlog "1>$ultimotimebomb<"		
set ultimotimebomb [lreplace $ultimotimebomb 3 3 [format "%0*s" 2 [expr [scan [lindex $ultimotimebomb 3] %d]+1]]]
putlog "2>$ultimotimebomb<"	

		set expirarsec [clock scan $ultimotimebomb -format "%M %H %d %m %Y"]
		set expirarsecmaisumahora [clock add $expirarsec 1 hour]
		set temporestante [expr $expirarsecmaisumahora - [clock seconds]]
putlog ">[clock format $expirarsecmaisumahora -format "%H:%M %d/%m/%Y"]< >[clock format [clock seconds] -format "%H:%M %d/%m/%Y"]<"
putlog ">$expirarsecmaisumahora< >[clock seconds]< >$temporestante<"
		set horasrestantes [expr round(double($temporestante) / 3600)]
		if {$horasrestantes==1} {set shrestantes "hora"} {set shrestantes "horas"}
		set percentagem [expr $horasrestantes*100/336]
		putquick "privmsg $chan :Restam $horasrestantes $shrestantes. [pbardraw 20 $percentagem 47 14 0 "$percentagem%"]"
	}
}

proc resetexpire {nick host handle chan text} {
	global ficheiroexpirar 
	putlog "A remover os binds antigos (se houver algum)..."
	foreach bind [binds] {
        	if {[lindex $bind end]=="timebomb"} {
            		catch {unbind time - [lindex $bind 2] timebomb}
        	}
 	}
	putlog "A adicionar os novos binds..."
	set fexpirar [open $ficheiroexpirar w+]
	foreach listadehoras {"312 hours" "324 hours" "335 hours"} {
		set marcatempo [clock format [clock scan $listadehoras] -format "%M %H %d %m %Y"]
		set marcatempo [lreplace $marcatempo 3 3 [format "%0*s" 2 [expr [scan [lindex $marcatempo 3] %d] - 1]]]
		putlog ">$listadehoras -> $marcatempo<"
		bind time - $marcatempo timebomb
		puts $fexpirar $marcatempo
	}
	close $fexpirar
	putnow "privmsg $chan :A shell deve expirar daqui a 336 horas."

}

proc timebomb {o1 o2 o3 o4 o5} {
	global canaisexpirar
	foreach canalexp $canaisexpirar {
		putquick "privmsg $canalexp :A shell está prestes a expirar!"
	}
}

if {[lsearch [binds] *timebomb]<0} {
	putlog "EXPIRAR: A recarregar os tempos de expiração..."
	if {![file exists $ficheiroexpirar]} {
		putlog "AVISO: O ficheiro $ficheiroexpirar não existe. O bot irá continuar a re/iniciar normalmente."
		putlog "Num canal, faça !xshzreset para criar um ficheiro novo enquanto faz reset ao timer da shell."
		
	} else {
		putlog "EXPIRAR: O ficheiro $ficheiroexpirar foi encontrado."
		set fexpirar [open $ficheiroexpirar r]
		set cexpirar [read $fexpirar]
		close $fexpirar
		putlog "EXPIRAR: [string length $cexpirar] bytes."
		set contador 0
		foreach linha [split $cexpirar "\n"] {
			if {$linha!=""} {
				incr contador
				bind time - $linha timebomb
				putlog "EXPIRAR: $contador -> $linha" 
			}
		}
		putlog "Bind time carregados a partir do ficheiro $ficheiroexpirar ok."
	}
}
putlog "Script de Aviso DE EXPIRAÇÃO da xshellz - 14/Set/2020"
