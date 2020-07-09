bind pub - "!cores" testedecores

proc testedecores {nick host handle chan text} {
	for {set i 0} {$i<=9} {incr i} {
		set linha ""
		for {set j 0} {$j<=9} {incr j} {
			append linha [format "\0030,$i$j      %*s " 2 [expr $i*10+$j]]
		}
		putnow "privmsg $chan :$linha"
	}
}
putlog "Teste de cores. Usar !cores"
