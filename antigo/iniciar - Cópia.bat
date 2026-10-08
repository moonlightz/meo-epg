@echo off
set "CURRENT_DIR=%~dp0"
set "OUTPUT_NAME=limp.txt"

:: %~dp0 automatically resolves to the folder containing this .bat file
set "DESTINATION=%~dp0%OUTPUT_NAME%"



echo Executing lines directly:
echo --------------------------------------------------------

for /f "usebackq delims=" %%A in ("%DESTINATION%") do (
	cd "%CURRENT_DIR%"
    set "LINE=%%A"
    if "!LINE:~0,1!" neq "#" if "!LINE:~0,2!" neq "::" (
        echo A executar %%A
        
        :: Using 'start /wait' ensures Batch stops and waits for completion
        start /wait "" /min cmd /c "%%A"
        
        
        echo --------------------------------------------------------
    )
)

echo Done executing all commands.
pause