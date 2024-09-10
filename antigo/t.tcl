set f [open meo.xml r]
set dados [read $f]
close $f

set c 0
foreach linha [split $dados \n] {
	puts "$linha"
	incr c
	if {$c>30} {break}
}
