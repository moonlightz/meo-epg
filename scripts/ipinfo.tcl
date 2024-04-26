bind pub - "!ip" pubip

proc pubip {nick host hand chan text} {
	if {$chan!="#canal-de-merda"} {return}
	if {$nick != "moonlight" && $nick != "boruto" && $nick != "kOoLaId"} {
		puthelp "privmsg $chan :Não tem permissão para usar isto."
		return
	}
	if {$text==""} {
		puthelp "privmsg $chan :Falta o ip."
		return
	}
	package require http
	package require json
	package require dns
	package require ip
	if {[scan $text {%s} lookup] != 1} {
		puthelp "PRIVMSG $chan :Sintaxe: !ip <ipv4/v6/dns>"
	        return
   	}
	if {![ip::is ipv6 $lookup]} {
      		set tok [dns::resolve $lookup -timeout 6000]
		putlog ">[dns::status $tok]< >$tok<"
		dns::wait $tok
		putlog ">[dns::status $tok]< >$tok<"
		if {![ip::is ipv4 $lookup]} {
		if {[dns::status $tok]=="error" } {
			puthelp "PRIVMSG $chan :Erro: o IP ou o DNS inserido não é válido."
			dns::cleanup $tok
	        	return
		}
		}
putlog "1>$lookup<"
		if {![ip::is ipv4 $lookup]} {
			set lookup [dns::address $tok]
			dns::cleanup $tok
		}
putlog "2>$lookup<"
	}
	catch {set http [::http::geturl http://ipinfo.io/$lookup/json -timeout 6000]} error
	set data [::http::data $http]
	set json [::json::json2dict $data]
	::http::cleanup $http
	set keys [dict keys $json]
	foreach ele {ip hostname city region country loc postal phone org} {
		set $ele [expr {[lsearch $keys $ele] > -1 ? [dict get $json $ele] : "n/a"}]
	}
	set fpaises [open scripts/ippaises.txt r]

	while {![eof $fpaises]} {
                gets $fpaises pais
                if {[eof $fpaises]} {break}
                #putlog $linhax
		if {[lindex $pais 0]==$country} {
			set country [lrange $pais 1 end]
			break
		}
	}
	close $fpaises
	set tsaida "\0034IP:\003 $ip \0034Anfitrião:\003 $hostname \0034Cidade:\003 $city \0034Região:\003 $region \0034País:\003 $country \0034Coordenadas:\003 $loc \0034Organização:\003 $org"
	puthelp "privmsg $chan :[encoding convertfrom utf-8 $tsaida]"
}
putlog "IPINFO.IO"
