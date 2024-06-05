# Először telepítjük a Winget-et
Write-Host "Winget telepitese..."
powershell "irm asheroto.com/winget | iex" 

# Programok telepítése Winget segítségével
$programs = @(
    "Google.Chrome",
    "Mozilla.Firefox",
    "Adobe.Acrobat.Reader.64-bit",
    "VideoLAN.VLC",
    "Notepad++.Notepad++",
    "WinRAR.WinRAR",
    "EclipseAdoptium.Temurin.20.JRE",
    "abbodi1406.vcredist",
    "Microsoft.DotNet.Framework.DeveloperPack_4"
)

$totalPrograms = $programs.Count
$currentProgram = 0

foreach ($program in $programs) {
    $currentProgram++
    Write-Host "Program telepitese: $program..."
    winget install --id $program --silent --accept-package-agreements --accept-source-agreements

    # Progress bar frissítése
    $progress = [math]::round(($currentProgram / $totalPrograms) * 100)
    Write-Progress -Activity "Programok telepítése" -Status "$currentProgram / $totalPrograms" -PercentComplete $progress
}

Write-Host "Sikeresen feltelepültek a programok."

# Office telepítése az USB meghajtóról
$usbDriveLetter = Get-WmiObject Win32_Volume | Where-Object { $_.Label -eq 'USB_DRIVE_LABEL' } | Select-Object -ExpandProperty DriveLetter
if ($usbDriveLetter) {
    $officeInstallScript = "$usbDriveLetter\Office\install.cmd"
    if (Test-Path $officeInstallScript) {
        Write-Host "Microsoft Office telepítése az USB meghajtóról..."
        Start-Process -FilePath $officeInstallScript -WorkingDirectory "$usbDriveLetter\Office" -Wait
        Write-Host "Microsoft Office telepítése befejeződött."
    } else {
        Write-Host "Nem található az Office telepítési parancsfájl az USB meghajtón."
    }
} else {
    Write-Host "Nem található USB meghajtó."
}

# Office aktiválása
Write-Host "Windows és Office aktiválása..."
powershell "irm https://get.activated.win | iex"

# Windows frissítések indítása
Write-Host "Windows frissítések keresése és telepítése..."
Install-Module PSWindowsUpdate -Force -SkipPublisherCheck
Import-Module PSWindowsUpdate
Get-WindowsUpdate -AcceptAll -Install -AutoReboot

Write-Host "Windows frissítések telepítése folyamatban..."
