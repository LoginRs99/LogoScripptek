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

# MediCat v21.12 meghajtó keresése és Office telepítése
$medicatDriveLetter = Get-WmiObject Win32_Volume | Where-Object { $_.Label -eq 'MediCat v21.12' } | Select-Object -ExpandProperty DriveLetter
if ($medicatDriveLetter) {
    $officeInstallScript = "$medicatDriveLetter\Office\install.cmd"
    if (Test-Path $officeInstallScript) {
        Write-Host "Microsoft Office telepítése a MediCat v21.12 USB meghajtóról..."
        Start-Process -FilePath $officeInstallScript -WorkingDirectory "$medicatDriveLetter\Office" -Wait
        Write-Host "Microsoft Office telepítése befejeződött."
    } else {
        Write-Host "Nem található az Office telepítési parancsfájl a MediCat v21.12 USB meghajtón."
    }
} else {
    Write-Host "Nem található MediCat v21.12 USB meghajtó."
}


# Office aktiválása
Write-Host "Windows és Office aktiválása..."
powershell "irm https://get.activated.win | iex"

# NuGet provider telepítése
Write-Host "NuGet provider telepítése..."
Install-PackageProvider -Name NuGet -Force -Confirm:$false

# Windows frissítések indítása
Write-Host "Windows frissítések keresése és telepítése..."
Install-Module PSWindowsUpdate -Force -SkipPublisherCheck
Import-Module PSWindowsUpdate
Get-WindowsUpdate -AcceptAll -Install -AutoReboot

Write-Host "Windows frissítések telepítése folyamatban..."
