@echo off
:: Verificar privilegios de Administrador e elevar se necessario
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    echo A solicitar privilegios de Administrador...
    goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"
    "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
    pushd "%CD%"
    CD /D "%~dp0"

cls
echo ========================================================
echo  A instalar o pacote de idioma pt-PT e layout de teclado...
echo ========================================================

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
"^^^
    Write-Host 'A descarregar e a instalar o pacote de idioma pt-PT (requer ligacao a internet)...' -ForegroundColor Cyan; ^
    Install-Language pt-PT -Force; ^
    ^^^
    Write-Host 'A definir pt-PT como idioma principal do utilizador e teclado...' -ForegroundColor Cyan; ^
    \$LangList = New-WinUserLanguageList pt-PT; ^
    Set-WinUserLanguageList \$LangList -Force; ^
    ^^^
    Write-Host 'A configurar o idioma do sistema (ecra de boas-vindas e novos utilizadores)...' -ForegroundColor Cyan; ^
    Set-WinSystemLocale pt-PT; ^
    Set-WinUILanguageOverride pt-PT; ^
    Copy-UserInternationalSettingsToSystem -WelcomeScreen \$true -NewUser \$true; ^
    ^^^
    Write-Host 'Concluido com sucesso! Reinicie o PC para aplicar todas as alteracoes.' -ForegroundColor Green; ^
"

echo.
pause