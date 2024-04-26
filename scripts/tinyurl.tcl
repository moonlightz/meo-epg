proc tinyurl {url} {
		set result ""
		set ourl $url
		if {$url==""} {return}
package require http
        set query [http::formatQuery url $url]
		set url "http://tinyurl.com/api-create.php\?$query"
#putdcc 8 ">$url<"
        catch {
                set tok [http::geturl $url]
                set result [http::data $tok]
                ::http::cleanup $tok
        }
		if {[string range $result 0 19]!="https://tinyurl.com/"} {
			set result $ourl
		}
        return $result
}
putlog "TINYURL"
