@echo off

set "CURRENT_DIR=%~dp0"
:: Check for Administrator privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ========================================================
    echo AVISO:
    echo     Isto precisa de ser corrido como Administrador.
    echo ========================================================
    echo.
	pause
	exit
)
:: Set the GitHub raw URL and target filename
set "URL=https://raw.githubusercontent.com/moonlightz/meo-epg/refs/heads/master/antigo/comandos.txt"
set "OUTPUT_NAME=comandos.txt"

:: %~dp0 automatically resolves to the folder containing this .bat file
set "DESTINATION=%~dp0%OUTPUT_NAME%"
goto SALTO
echo Downloading file from GitHub...

:: Execute curl.exe
curl.exe -sSL "%URL%" -o "%DESTINATION%"

:: Verify download status
if exist "%DESTINATION%" (
    echo Descarregado para: %DESTINATION%
) else (
    echo O download falhou. Não há net.
	pause
	exit /b

)

:SALTO
echo .
echo --------------------------------------------------------

for /f "usebackq delims=" %%A in ("%DESTINATION%") do (
    set "LINE=%%A"
	cd "%CURRENT_DIR%"
    if "!LINE:~0,1!" neq "#" if "!LINE:~0,2!" neq "::" (
        echo A executar %%A
        
        :: Using 'start /wait' ensures Batch stops and waits for completion
        start /wait "" /min cmd /c "%%A"
        
        
        echo --------------------------------------------------------
    )
)

echo ======= FIM =========
pause