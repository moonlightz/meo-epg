set olinkdoeggdrop "https://www.eggheads.org/downloads"
#set olinkdoeggdrop "https://web.archive.org/web/20181217050523/http://www.eggheads.org:80/downloads"
bind time - "00 * * * *" verificarversao

proc verificarversao {minuto hora dia mes ano} {
	global olinkdoeggdrop
    package require tls
    package require http
    http::register https 443 [list tls::socket -tls1 1]
    set token [::http::geturl $olinkdoeggdrop]
    set data [string map {"\n" "" "  " ""} [::http::data $token]]
    ::http::cleanup $token
#	putdcc 9 $data
	
	regexp {<h2>Complete Source Code \(Latest Stable Release\)</h2></div><div>(.*?)<\!--} $data -> match
	set matches [regexp -all -inline -- {<li><a href=\"(.*?)\">Eggdrop (.*?) \(tar.gz\)</a>\[(.*?)\].*signature</a>] - (.*?)<br/>\(SHA256 Sum: .*\)</li>} $match]
	set count 0
	set novotopico "Canal dedicado a scripts, bots e afins. | https://github.com/moonlightz/meo-epg | A última versão do eggdrop é "
	foreach {- link versao kb datav} $matches {
		set datav [string map {
			"Feb" "Feb" "Apr" "Abr" "May" "Mai" "Aug" "Ago" "Sep" "Set" "Oct" "Out" "Dec" "Dez"
			} [clock format [clock scan $datav -format "%Y-%m-%d"] -format "%d/%B/%Y"]]
		if {$count==0} {
			append novotopico "\002$versao\002 ($datav, $kb, $link) "
		}
		if {$count==1} {
			append novotopico "TESTING: \002$versao\002 ($datav, $kb) "
		}
		incr count 
	}
	append novotopico "| Usar o pastebin para grandes quantidades de linha de código"
	if {[topic #code]!=$novotopico} {putserv "TOPIC #CODE :$novotopico"}
	#putdcc 9 $matches
}
putlog "Detector de última versão do eggdrop."
