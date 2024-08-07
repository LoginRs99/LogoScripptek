@echo off
chcp 1250 >nul

setlocal

echo ----------------------------------------
echo Rendszerinform�ci�k
echo ----------------------------------------

echo.
echo [Alaplap]
for /f "tokens=2 delims==" %%a in ('wmic baseboard get manufacturer /format:list') do set Manufacturer=%%a
for /f "tokens=2 delims==" %%a in ('wmic baseboard get product /format:list') do set Product=%%a
echo Gy�rt�: %Manufacturer%
echo Modell: %Product%

echo.
echo [Processzor]
for /f "tokens=2 delims==" %%a in ('wmic cpu get name /format:list') do set CPU=%%a
echo CPU: %CPU%

echo.
echo [Mem�ria]
wmic memorychip get capacity,manufacturer,speed

echo.
echo [Merevlemezek]
wmic diskdrive get model,size,caption

echo.
echo [Oper�ci�s Rendszer]
for /f "tokens=2 delims==" %%a in ('wmic os get caption /format:list') do set OS=%%a
for /f "tokens=2 delims==" %%a in ('wmic os get version /format:list') do set OSVersion=%%a
echo Oper�ci�s rendszer: %OS%
echo Verzi�: %OSVersion%

echo.
echo [Videok�rtya]
wmic path win32_videocontroller get name

echo.
echo [H�l�zati Adapterek]
wmic nic where "NetEnabled=true" get name, macaddress

echo.
echo [IP-c�mek]
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4"') do echo IP-c�m: %%a

echo.
echo ----------------------------------------
echo Az inform�ci�k lek�r�se befejez�d�tt.
echo ----------------------------------------

endlocal
pause
