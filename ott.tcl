###### 22-Agosto-2024

set tempoinicial [clock milliseconds]

puts "A iniciar a recolha pelo servidor da meo..."

package require json

#obter lista dos nomes dos canais

set fp [open meo.xml w+]
puts $fp "<?xml version=\"1.0\" encoding=\"utf-8\"?>"
puts $fp "<!DOCTYPE tv SYSTEM \"xmltv.dtd\">"
puts $fp "<tv generator-info-name=\"MZ\" generator-info-url=\"git\" source-info-name=\"OTT MEO\" date=\"[clock format [clock seconds] -format "%Y%m%d%H%M%S %z"]\">"

set link "http://ott.online.meo.pt/catalog/v8/Channels?UserAgent=W10&OfferId=21600543&\$orderby=ChannelPosition%20asc&\$filter=substringof('IPTV',AvailableOnChannels)%20and%20IsAdult%20eq%20false%20&\$inlinecount=allpages"
	
while {1} {
	set cjson [exec wget -q -O - $link]
	set cdict [json::json2dict $cjson]
	set cvalue   [dict get $cdict "value"]

	foreach dcanal $cvalue {
		set titulocanal [dict get $dcanal "Title"]
		set identificador [dict get $dcanal "CallLetter"]
		set posicaocanal "X[format %04d [dict get $dcanal "ChannelPosition"]]"
		puts $fp "  <channel id=\"$posicaocanal\">"
		puts $fp "    <display-name>$titulocanal</display-name>"
		puts $fp "  </channel>"
		flush stdout

		lappend canais($posicaocanal) $titulocanal
		lappend canais($posicaocanal) $identificador
		incr quant
		puts -nonewline "."
	}
	if {[catch {set link [dict get $cdict "odata.nextLink"]} erro]} {
		#Não há aquela chave, sair do loop
		puts "Feito!"
		break
	}
 
}
puts "$quant canais adicionados."
puts "A adicionar os programas de televisão..."

foreach idcanal [lsort -increasing [array names canais]] {
	set nomecanal [lindex $canais($idcanal) 0]
	set identificador [lindex $canais($idcanal) 1]
	set link "http://ott.online.meo.pt/Program/v8/Programs/LiveChannelPrograms?UserAgent=W10&\$orderby=StartDate%20asc&\$filter=CallLetter%20eq%20'$identificador'%20and%20StartDate%20ge%20datetime'[clock format [clock scan "1 day ago"] -format "%Y-%m-%d"]T01:00:00'%20and%20StartDate%20lt%20datetime'[clock format [clock scan "7 days"] -format "%Y-%m-%d"]T23:00:00'%20and%20IsEnabled%20eq%20true%20and%20IsAdultContent%20eq%20false%20and%20IsBlackout%20eq%20false"
	set numprogs 0
	set isymb 0
	set tempoprog [clock seconds]
	while {1} {
		set cjson [exec wget -q -O - $link]
		set cdict [json::json2dict $cjson]
		set cvalue [dict get $cdict "value"]

		foreach dprograma $cvalue {
			set tituloprograma [dict get $dprograma "Title"]
			set inicio [clock format [clock scan [dict get $dprograma "StartDate"] -format "%Y-%m-%dT%H:%M:%S" -gmt [expr [clock format [clock scan [dict get $dprograma "StartDate"] -format "%Y-%m-%dT%H:%M:%S"] -format "%z"]=="+0100"]] -format "%Y%m%d%H%M%S %z"]
			set fim [clock format [clock scan [dict get $dprograma "EndDate"] -format "%Y-%m-%dT%H:%M:%S" -gmt [expr [clock format [clock scan [dict get $dprograma "StartDate"] -format "%Y-%m-%dT%H:%M:%S"] -format "%z"]=="+0100"]] -format "%Y%m%d%H%M%S %z"]
			set descricao [dict get $dprograma "Synopsis"]
			set categoria [dict get $dprograma "Thematics"]

			puts $fp "  <programme channel=\"$idcanal\" start=\"$inicio\" stop=\"$fim\">"
			puts $fp "    <title lang=\"pt\">$tituloprograma</title>"
			puts $fp "    <desc lang=\"pt\">[string range $descricao 0 50]"
			puts $fp "$descricao</desc>"
			puts $fp "    <category lang=\"pt\">$categoria</category>"
			puts $fp "  </programme>"

			puts -nonewline [format " %1s %-10s  %-25s  %5s\r" [lindex "/ / - - \\\\ \\\\ | |" $isymb] $identificador $nomecanal [clock format [expr [clock seconds]-$tempoprog] -format "%M:%S"]]

			flush stdout
			incr numprogs
			incr isymb
			if {$isymb>7} {set isymb 0}
		}
		if {[catch {set link [dict get $cdict "odata.nextLink"]} erro]} {
			#Não há aquela chave, sair do loop
			puts [format " %1s %-10s  %-25s  %5s  %-22s " "√" $identificador $nomecanal [clock format [expr [clock seconds]-$tempoprog] -format "%M:%S"] "Feito! $numprogs programas"]

			break
		}
	}
	#return

}
puts $fp "</tv>"
close $fp

puts "O tamanho do ficheiro meo.xml é [file size meo.xml] bytes."
puts "A operação demorou [string map {"." ","} [expr ([clock milliseconds]-$tempoinicial)/1000.000]] segundos!"