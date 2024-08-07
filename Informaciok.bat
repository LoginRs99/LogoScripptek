@echo off
chcp 1250 >nul

setlocal

echo ----------------------------------------
echo Rendszerinformációk
echo ----------------------------------------

echo.
echo [Alaplap]
for /f "tokens=2 delims==" %%a in ('wmic baseboard get manufacturer /format:list') do set Manufacturer=%%a
for /f "tokens=2 delims==" %%a in ('wmic baseboard get product /format:list') do set Product=%%a
echo Gyártó: %Manufacturer%
echo Modell: %Product%

echo.
echo [Processzor]
for /f "tokens=2 delims==" %%a in ('wmic cpu get name /format:list') do set CPU=%%a
echo CPU: %CPU%

echo.
echo [Memória]
wmic memorychip get capacity,manufacturer,speed

echo.
echo [Merevlemezek]
wmic diskdrive get model,size,caption

echo.
echo [Operációs Rendszer]
for /f "tokens=2 delims==" %%a in ('wmic os get caption /format:list') do set OS=%%a
for /f "tokens=2 delims==" %%a in ('wmic os get version /format:list') do set OSVersion=%%a
echo Operációs rendszer: %OS%
echo Verzió: %OSVersion%

echo.
echo [Videokártya]
wmic path win32_videocontroller get name

echo.
echo [Hálózati Adapterek]
wmic nic where "NetEnabled=true" get name, macaddress

echo.
echo [IP-címek]
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4"') do echo IP-cím: %%a

echo.
echo ----------------------------------------
echo Az információk lekérése befejezõdött.
echo ----------------------------------------

endlocal
pause
