bind pub -|- "pbar" pbar 

proc pbar { nick host handle chan text } {
	if {$nick != "moonlight" && $nick != "boruto"} {return}
	putquick "privmsg $chan :[pbardraw [lindex $text 0] [lindex $text 1] [lindex $text 2] [lindex $text 3] [lindex $text 4] [lrange $text 5 end]]"
}

proc pbardraw {plength pval pbcol1 pbcol2 ptcol ptext} {
	set mypbarpbcol1 [expr $plength * $pval /100 ]
	set mypbarpbcol2 [expr $plength - $mypbarpbcol1]
	set mypbart "-"
	for {set i 1} {$i <= $plength} {incr i} {lappend mypbart "_"}
	set mypbartlength [string length $ptext]
	if {$mypbartlength > $plength} {
		set ptext [lrange $ptext 0 [expr $plength-2]]
		set mypbartlength [string length $ptext]
	}
	#posicao do texto na barra
	set mypbarpos [expr {round($plength/2)-round($mypbartlength/2)+1}]

	if {$mypbarpos<=1} {set mypbarpos "1"}
	for {set i 0} {$i < $mypbartlength} {incr i} {
		set j [expr $mypbarpos + $i]
		if {$j>$plength} {break}
		lset mypbart $j "[string range $ptext $i $i]"
	}
	for {set i 1} {$i <= $plength} {incr i} {
		if {[lindex $mypbart $i] =="_"} {
			if {$i <= $mypbarpbcol1} {
				lset mypbart $i "\003$pbcol1,$pbcol1[lindex $mypbart $i]"
			} else {
				lset mypbart $i "\003$pbcol2,$pbcol2[lindex $mypbart $i]"
			}
		} else {  
			if {$i <= $mypbarpbcol1} {
				lset mypbart $i "\003$ptcol,$pbcol1\026\026[lindex $mypbart $i]"
			} else {
				lset mypbart $i "\003$ptcol,$pbcol2\026\026[lindex $mypbart $i]"
			}
		}
	}
	for {set i $plength} {$i > 1} {set i [expr $i -1]} {
		set mypbarcase1 [lindex $mypbart [expr $i-1]]
		set mypbarcase2 [lindex $mypbart $i]
		if {[string range $mypbarcase1 0 end-1]==[string range $mypbarcase2 0 end-1]} {
			lset mypbart $i [string range $mypbarcase2 end end]
		}
	}
	return "[string range [join $mypbart ""] 1 end]\003"
}
putlog "Exemplo de barra de progresso"
