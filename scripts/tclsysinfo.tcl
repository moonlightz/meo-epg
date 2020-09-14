bind pub - !sysinfo2 sysinfo2
proc sysinfo2 {nick host hand chan arg} {
	if {$nick != "moonlight" && $nick!="boruto"} {return}
	
	set uname [exec uname -snrm]
	set msgout "\002Nome:\002 [lindex $uname 1]  \002SO:\002 [lindex $uname 0] [lindex $uname 2]/[lindex $uname 3]" 
	if {[file exist "/etc/debian_version"] && [file exist "/etc/os-release"]} {
		set infile [open "/etc/os-release" r]
		gets $infile tdistro
		gets $infile tdistro
		close $infile
		set tdistro [string range $tdistro 6 13]
                set infile [open "/etc/debian_version" r]
                gets $infile tversion
                close $infile
                set msgout "$msgout  \002Distro:\002 $tdistro $tversion"
        }
	if {[file exists "/proc/cpuinfo"]} {
		set cpu1lista [exec lscpu]
		set ncpus "[lindex $cpu1lista [lsearch $cpu1lista "CPU(s):"]+1]x"

		set infile [open "/sys/bus/cpu/devices/cpu0/cpufreq/scaling_cur_freq"]
		gets $infile thz
		close $infile
		set thz "[format "%.2f" [expr double([lindex $thz 0])/1000]] Mhz"
		
		set infile [open "/proc/cpuinfo" r]
                set tcpuinfo [read $infile]
                close $infile
                set tcpu [lindex $tcpuinfo [lsearch $tcpuinfo "Hardware"]+2]
		set tmodelo [lrange $tcpuinfo [lsearch $tcpuinfo "Model"]+2 end]
                

		set cpu "$ncpus $tcpu ($thz)"

		if {[file exists "/sys/class/thermal/thermal_zone0/temp"]} {
			set fcputemp [open "/sys/class/thermal/thermal_zone0/temp" r]
			gets $fcputemp tcputemp
			close $fcputemp
			set cpu "$cpu [format "%.1f" [expr double($tcputemp)/1000]]°C"
		}		
		set msgout "$msgout  \002CPU:\002 $cpu"
	}
	set msgout "$msgout  \002Processos:\002 [exec ps -e | wc -l]"

	set infile [open "/proc/uptime" r]
	gets $infile ttempo
	close $infile
	set ttempo [lindex [split $ttempo "."] 0]

	set msgout "$msgout  \002Activo:\002 [sys_segs $ttempo]"
	set msgout "$msgout  \002Utilizadores:\002 [exec who | wc -l]"
	set tcarga [exec uptime]
	set msgout "$msgout  \002Carga Média:\002 [string range [lindex $tcarga [llength $tcarga]-2] 0 end-1]"

	set meminfo [open "/proc/meminfo"]
	gets $meminfo ttotal
	gets $meminfo tfreemem
	gets $meminfo 5memavail
	gets $meminfo tbuffers
	gets $meminfo tcached
	close $meminfo
	
	set ttotal [lindex $ttotal 1]
	set tfreemem [lindex $tfreemem 1]
	set tbuffers [lindex $tbuffers 1]
	set tcached [lindex $tcached 1]

	set ttotal [format "%.2f" [expr double($ttotal)/1024]]
	set tfreemem [format "%.2f" [expr double($tfreemem)/1024]]
	set tbuffers [format "%.2f" [expr double($tbuffers)/1024]]
	set tcached [format "%.2f" [expr double($tcached)/1024]]
#putlog "$ttotal $tfreemem $tbuffers $tcached"
set tfreemem [format "%.2f" [expr $ttotal-$tfreemem-$tbuffers-$tcached]]

	set tmemoria "[string range $tfreemem 0 end]MB/[string range $ttotal 0 end]MB ([format "%.2f" [expr double($tfreemem)/$ttotal*100]]%)"
	set msgout "$msgout  \002Memória:\002 $tmemoria"

	set tdf [exec df]
	set tdfusado [expr [lindex $tdf 9]*1000]
	set tdftotal [expr [lindex $tdf 8]*1000]
	set msgout "$msgout  \002Uso disco:\002 [string map {" " ""} "[formatarbytes $tdfusado]/[formatarbytes $tdftotal]"] ([format "%.2f" [expr double($tdfusado)/$tdftotal*100]]%)"

	set trede [exec /sbin/ifconfig wlan0]
	set tbrecebidos [string map {"(" "" ")" "" "i" "" " " ""} [lrange $trede [lsearch $trede "RX"]+5 [lsearch $trede "RX"]+6]]
	set tbenviados [string map {"(" "" ")" "" "i" "" " " ""} [lrange $trede [lsearch $trede "TX"]+5 [lsearch $trede "TX"]+6]]

	set trede2 [exec /sbin/iwconfig wlan0]
	set tquality [lindex [split [lindex $trede2 [lsearch $trede2 "Quality*"]] "="] 1]
	set tsinal [lindex [split [lindex $trede2 [lsearch $trede2 "level*"]] "="] 1]
    set trate [lindex [split [lindex $trede2 [lsearch $trede2 "Rate*"]] "="] 1]

	set trede3 [exec /sbin/iwlist wlan0 channel]
	set tfreq [lsearch $trede3 "Frequency*"]
	set tfreq [string map {"Frequency:" "" "Channel" "Canal"} [lrange $trede3 $tfreq $tfreq+4]]
#	putlog ">$tfreq<"
	
	set msgout "$msgout  \002Rede:\002 $tbrecebidos▼/$tbenviados▲ $trate Mb/s LQ:$tquality SL:$tsinal dBm Fq:$tfreq"

	if {[file exist "/sys/class/power_supply/battery/capacity"]} {
		set infile [open "/sys/class/power_supply/battery/capacity" r]
		gets $infile bcapacity
		close $infile
		set infile [open "/sys/class/power_supply/battery/batt_temp" r]
                gets $infile btemp
                close $infile
                set infile [open "/sys/class/power_supply/ac/online" r]
		gets $infile bcarregar
		close $infile
		
		
		set msgout "$msgout  \002Bateria:\002 $bcapacity% [expr $btemp/10]°C [string map {"1" "⚡" "0" "⭘"} $bcarregar]"
	}
	if {[file exist "/sys/class/leds/lcd-backlight/brightness"]} {
                set infile [open "/sys/class/leds/lcd-backlight/brightness" r]
                gets $infile becra
                close $infile
		if {$becra==0} {
			set becra "Desligado"
		} else {
			set becra "$becra/255"
		}
		set msgout "$msgout  \002Ecrã:\002 $becra"
	}
	if {$tmodelo!=""} {set msgout "$msgout  \002Modelo:\002 $tmodelo"}
	putquick "privmsg $chan :$msgout"
}

proc sys_segs {xnumber} {
        global outputtext zw zd zh zm zs
        set outputtext ""
        set zw [expr $xnumber/604800]
        set xnumber [expr $xnumber-$zw*604800]
        set zd [expr $xnumber/86400]
        set xnumber [expr $xnumber-$zd*86400]
        set zh [expr $xnumber/3600]
        set xnumber [expr $xnumber-$zh*3600]
        set zm [expr $xnumber/60]
        set xnumber [expr $xnumber-$zm*60]
        set zs $xnumber
        if {$zw == 1} {append outputtext $zw "w "}
        if {$zw > 1} {append outputtext $zw "w "}
        if {$zd == 1} {append outputtext $zd "d "}
        if {$zd > 1} {append outputtext $zd "d "}
        if {$zh == 1} {append outputtext $zh "h "}
        if {$zh > 1} {append outputtext $zh "h "}
        if {$zm == 1} {append outputtext $zm "m "}
        if {$zm > 1} {append outputtext $zm "m "}
        if {$zs == 1} {append outputtext $zs "s "}
        if {$zs > 1} {append outputtext $zs "s "}
        if {$outputtext == ""} {set outputtext "0s"}
        return [string trimright $outputtext]

}
proc formatarbytes {value} {
    set len [string length $value]
    if {$value < 1000} {
      return [format "%s B" $value]
    } else {
      set unit [expr {($len - 1) / 3}]
      return [format "%.2f %s" [expr {$value / pow(1000,$unit)}] [lindex \
        [list B KB MB GB TB PB EB ZB YB] $unit]]
    }
}


putlog "TCLSYSINFO"
