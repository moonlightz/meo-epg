REM del meo.xml
REM del channelinfo.xml
DVBGuide.exe -aT -c474000 -d -e600  -fX -omeo
tclsh -encoding utf-8 conversao.tcl
