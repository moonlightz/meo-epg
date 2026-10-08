@echo off

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
set "URL=https://raw.githubusercontent.com/moonlightz/meo-epg/refs/heads/master/limp.txt"
set "OUTPUT_NAME=limp.txt"

:: %~dp0 automatically resolves to the folder containing this .bat file
set "DESTINATION=%~dp0%OUTPUT_NAME%"

echo Downloading file from GitHub...

:: Execute curl.exe
curl.exe -sSL "%URL%" -o "%DESTINATION%"

:: Verify download status
if exist "%DESTINATION%" (
    echo Successfully downloaded to: %DESTINATION%
) else (
    echo Download failed. Please check the URL.
	pause
	exit /b

)

echo Executing lines directly:
echo --------------------------------------------------------

for /f "usebackq delims=" %%A in ("%DESTINATION%") do (
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