bind time - "00 01 * * *" pubecom
bind time - "00 14 * * *" pubecom

proc pubecom {min hora dia mes ano} {
	set html [exec wget -q -O -  https://www.calendarr.com/portugal/]
	#set fp [open ca.txt r]
	#set html [read $fp]
	#close $fp
	
	set html [string map {"\n" "" "    " ""} $html]
	set html2 [string range $html [string first "list-holiday-box simplified" $html] [string first "</li>" $html [string first "list-holiday-box simplified" $html]]]
	set out "[string map {Mon Seg Tue Ter Wed Qua Thu Qui Fri Sex Sat Sáb Sun Dom Feb Fev Apr Abr May Mai Aug Ago Sep Set Oct Out Dec Dez} [clock format [clock seconds] -format "%a %d/%b"]]: "
	foreach {match link dcom} [regexp -all -inline -- {<a class='list-holiday-name' href='(.*?)'>(.*?)</a>} $html2] {
		append out "$dcom, "
	}
	foreach {match dcom} [regexp -all -inline -- {<span class='holiday-name'>(.*?)</span>} $html2] {
        append out "$dcom, "
    }
	putquick "PRIVMSG #portugal :[string trimright $out ", "]"
}
