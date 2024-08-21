del meo.xml
del channelinfo.xml
del meo.xml.gz
del meo-modificado.xml.gz
REM DVBGuide.exe -aT -c474000 -d -e600 -w -fX -omeo 
copy meo2.xml meo.xml
tclsh -encoding utf-8 conversao.tcl
