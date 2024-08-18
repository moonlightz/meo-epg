@echo off
rem
rem     Example batch file to update the Media Center (MCE2005 or pre-TV Pack Vista) Guide from broadcast EPG
rem
rem     Notes:
rem      - will normally need to be edited to specify tuning parameters etc.
rem      - can be set to run as a scheduled task for completely automated guide updating
rem      - (Vista only) must run as Administrator if using "-t" option to set system time
rem
DVBGuide -c505833 -t -fm -o mcguide.xml
if %ERRORLEVEL% neq 0 goto End
MCGuideLoad mcguide.xml
:End
if exist mcguide.xml del mcguide.xml
