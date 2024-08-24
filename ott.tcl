###### 22-Agosto-2024

proc format_time {milliseconds} {
    set total_seconds [expr {$milliseconds / 1000}]
    set minutes [expr {$total_seconds / 60}]
    set seconds [expr {$total_seconds % 60}]
    set millis [expr {$milliseconds % 1000}]
    return [format "%02d:%02d.%03d" $minutes $seconds $millis]
}

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
		set identificador [dict get $dcanal "CallLetter"]
		set titulocanal "[dict get $dcanal "Title"][if {[string range $identificador end-1 end]=="SD"} {set a " SD"}]"
		
		set posicaocanal "X[format %04d [dict get $dcanal "ChannelPosition"]]"
		puts $fp "  <channel id=\"$posicaocanal\">"
		puts $fp "    <display-name>$titulocanal</display-name>"
		puts $fp "  </channel>"


		lappend canais($posicaocanal) $titulocanal
		lappend canais($posicaocanal) $identificador
		incr quant
		puts -nonewline "$quant cana[if {$quant==1} {set a "l"} {set a "is"}] ... \r"
		flush stdout
	}
	if {[catch {set link [dict get $cdict "odata.nextLink"]} erro]} {
		#Não há aquela chave, sair do loop
		puts "$quant cana[if {$quant==1} {set a "l"} {set a "is"}] ... Feito!"
		break
	}
 
}

puts "A adicionar os programas de televisão ..."

foreach idcanal [lsort -increasing [array names canais]] {
	set nomecanal [lindex $canais($idcanal) 0]
	set identificador [lindex $canais($idcanal) 1]

	set link "http://ott.online.meo.pt/Program/v8/Programs/LiveChannelPrograms?UserAgent=W10&\$orderby=StartDate%20asc&\$filter=CallLetter%20eq%20'$identificador'%20and%20StartDate%20ge%20datetime'[clock format [clock scan "1 day ago"] -format "%Y-%m-%d"]T01:00:00'%20and%20StartDate%20lt%20datetime'[clock format [clock scan "7 days"] -format "%Y-%m-%d"]T23:00:00'%20and%20IsEnabled%20eq%20true%20and%20IsAdultContent%20eq%20false%20and%20IsBlackout%20eq%20false"

	set numprogs 0
	set isymb 0
	set tempoprog [clock milliseconds]
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

			incr numprogs
			incr isymb
			if {$isymb>7} {set isymb 0}

			
			puts -nonewline [format " %1s | %5s | %-10s | %-25s | %9s | %-15s\r" [lindex "/ / ─ ─ \\\\ \\\\ │ │" $isymb] $idcanal $identificador $nomecanal [format_time [expr [clock milliseconds]-$tempoprog]] "$numprogs programas"]
			flush stdout
			
		}
		if {[catch {set link [dict get $cdict "odata.nextLink"]} erro]} {
			#Não há aquela chave, sair do loop

			puts [format " %1s | %5s | %-10s | %-25s | %9s | %-15s - Feito!" "√" $idcanal $identificador $nomecanal [format_time [expr [clock milliseconds]-$tempoprog]] "$numprogs programas"]

			break
		}
	}
	#return

}
puts $fp "</tv>"
close $fp

puts "O tamanho do ficheiro meo.xml é [file size meo.xml] bytes."
puts "A operação demorou [format_time [expr [clock milliseconds]-$tempoinicial]] segundos!"