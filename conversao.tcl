puts "Ferramenta de conversão de IDs de canal. 20-Junho-2020"

set fp [open meo.conf w+]
puts $fp "date=[clock format [clock seconds] -format "%d/%b/%Y %H:%M:%S"]"
puts $fp "url=https://raw.githubusercontent.com/moonlightz/meo-epg/master/meo-modificado.xml"
close $fp

set ficheiroxml "meo.xml"
set ficheiroxmlsaida "meo-modificado.xml"

puts "A abrir o ficheiro $ficheiroxml..."
if {![file exists $ficheiroxml]} {
	puts "O ficheiro $ficheiroxml não existe."
	return
}

set f [open $ficheiroxml r]
#fconfigure $f -encoding utf-8
set xmldata [read $f]
close $f
puts "O ficheiro $ficheiroxml tem [string length $xmldata] bytes."
##### 13/06/2024
#set xmldata [string map {ª ã Ð â Ø é Ŧ í ð ó Ŀ ç} $xmldata]


puts "A criar lista de IDs..."
set canalid [regexp -all -inline -- {<channel id=\"(.*?)\">} $xmldata]
set canalnome [regexp -all -inline -- {<display-name>(.*?)</display-name>} $xmldata]
#if {[array exists ids]} {unset ids}
#array set ids {}
set listacanais ""

#remover os canais de rádio
foreach {- id} $canalid {- nomelongo} $canalnome {
	set nomecurto [string map {
            " " "" "(" "" ")" "" "á" "a" "ú" "u"
            "ç" "c" "ã" "a" "ó" "o" "-" "" "í" "i" "â" "a"} [string tolower $nomelongo]]
        if {[lsearch "meovideoclube meodestaques sim rfm renascenca oceanopacifico megahits rfmclubbing 80srfm smoothfm radiocomercial m80 cidadefm rdpafrica zigzag lusitania antena1memoria antena1vida antena3 antena2opera antena2 antena1fado antena1" $nomecurto]<0} {
            #lappend ids($id) $nomecurto
		
            #lappend ids($id) $nomelongo
			lappend listacanais $id
			lappend listacanais $nomecurto
            #puts ">$id< >$nomecurto< >$nomelongo<"
        }
}

puts "Há [expr [llength $listacanais]/2] canais depois da filtragem."
unset canalid
unset canalnome
#set i 0
#foreach canal [array names ids] {
#	incr i
#	puts ">$i< >$canal< >$ids($canal)<"
#}

#criar e preencher o ficheiro de saida
set xmldata [string map $listacanais $xmldata]
set fo [open $ficheiroxmlsaida w+]
fconfigure $fo -encoding utf-8
set adic 1
foreach linha [split $xmldata "\n"] {
	if {[string range $linha 0 22]=="  <programme channel=\"X"} {set adic 0}
	if {[string range $linha 0 15]=="  <channel id=\"X"} {set adic 0}
	if {$adic==1} {puts $fo $linha}
	if {[string range $linha 0 13]=="  </programme>"} {set adic 1}
	if {[string range $linha 0 11]=="  </channel>"} {set adic 1}
}
close $fo

puts "Fim."