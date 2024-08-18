@echo off
rem
rem     Example batch file to capture the UK Freesat EPG as an XMLTV format file
rem
DVBGuide -as -c11427830 -ph -mQPSK -s27500000 -y3002 -z3003 -g c:\ChannelLogos -o freesat_epg.xml
