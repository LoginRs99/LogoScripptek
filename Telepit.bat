@echo off
:: Ellenorzi, hogy a script rendszergazdai jogosultsagokkal fut-e
:: openfiles parancsot hasznalunk, mert ha nem rendszergazdai, nem fog mukodni
openfiles >nul 2>&1
if '%errorlevel%' NEQ '0' (
    :: A script nem fut rendszergazdai jogosultsagokkal
    :: Rendszergazdai jogosultsagokkal ujrainditjuk a scriptet
    echo Az ujrainditas folyamatban...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:MENU
cls
echo Valassz egy opciot:
echo 1. Programok/winget telepitese(winget)
echo 2. Szamitogep informacioi legyujtese(sajat)
echo 3. Chris Titus Tech Script(https://github.com/ChrisTitusTech/winutil)
echo 4. Microsoft Activation Scripts (MAS)
echo 5. Kilepes
set /p option=Valasztas:

if "%option%"=="1" goto DownloadAndRun
if "%option%"=="2" goto DownloadToDesktop
if "%option%"=="3" goto ChrisTitusTech
if "%option%"=="4" goto MAS
if "%option%"=="5" exit
goto MENU

:DownloadAndRun
:: Letoltes es futtatas
echo Letoltes folyamatban...
powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/LoginRs99/LogoScripptek/main/telepites.ps1' -OutFile '%TEMP%\telepites.ps1'"

:: Ellenorzi, hogy a letoltes sikeres volt-e
if exist "%TEMP%\telepites.ps1" (
    echo A script letoltese sikeres volt.
    echo A script futtatasa...
    powershell -Command "Start-Process powershell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File %TEMP%\telepites.ps1' -Verb RunAs"
) else (
    echo Hiba tortent a script letoltese soran.
)
pause
goto MENU

:DownloadToDesktop
:: Letoltes az asztalra
echo Letoltes folyamatban...
set "desktop=%USERPROFILE%\Desktop"
powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/LoginRs99/LogoScripptek/main/Informaciok.bat' -OutFile '%desktop%\Informaciok.bat'"

:: Ellenorzi, hogy a letoltes sikeres volt-e
if exist "%desktop%\Informaciok.bat" (
    echo A batch file letoltese sikeres volt az asztalra.
) else (
    echo Hiba tortent a batch file letoltese soran.
)
pause
goto MENU

:ChrisTitusTech
:: Letoltes es futtatas
echo Letoltes folyamatban...
powershell -Command "irm 'https://christitus.com/win' | iex"
pause
goto MENU

:MAS
:: Microsoft Activation Scripts letoltese es futtatasa
echo Microsoft Activation Scripts letoltese es futtatasa...
powershell -Command "irm https://get.activated.win | iex"
pause
goto MENU
