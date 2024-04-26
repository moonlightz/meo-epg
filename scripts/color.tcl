bind pub - "!cores" testedecores

proc testedecores {nick host handle chan text} {
	set cortexto {
		1 0 0 0 0 0 0 1
		1 1 0 1 0 0 0 1
		0 0 0 0 0 0 0 0 0 0 0 0
		0 0 0 0 0 0 0 0 0 0 0 0
		0 0 1 1 0 0 0 0 0 0 0 0
		0 1 1 1 1 1 1 0 0 0 0 0
		1 1 1 1 1 1 1 1 0 1 1 1
		1 1 1 1 1 1 1 1 1 1 1 1
		0 0 0 0 0 0 1 1 1 1 1
	}
	set linha ""
    for {set ncor 0} {$ncor<=98} {incr ncor} {
        append linha [format "\003[lindex $cortexto $ncor],$ncor      %*s " 2 $ncor]
		if {$ncor==7||$ncor==15||$ncor==27||$ncor==39||$ncor==51||$ncor==63||$ncor==75||$ncor==87||$ncor==98} {
			putnow "privmsg $chan :$linha"
			set linha ""
		}
    }
}

#proc testedecores {nick host handle chan text} {
#	for {set i 0} {$i<=9} {incr i} {
#		set linha ""
#		for {set j 0} {$j<=9} {incr j} {
#			append linha [format "\0030,$i$j      %*s " 2 [expr $i*10+$j]]
#		}
#		putnow "privmsg $chan :$linha"
#	}
#}
putlog "Teste de cores. Usar !cores"
