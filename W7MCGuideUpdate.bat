@echo off
rem
rem     Example batch file to update the Windows 7 Media Center Guide from broadcast EPG
rem
rem     Notes:
rem      - will normally need to be edited to specify tuning parameters etc.
rem      - can be set to run as a scheduled task for completely automated guide updating
rem      - must run as Administrator if using "-t" option to set system time
rem
DVBGuide -c505833 -ft -o mcguide.mxf
if %ERRORLEVEL% neq 0 goto End
%windir%\ehome\loadmxf -v -i mcguide.mxf
:End
if exist mcguide.mxf del mcguide.mxf
