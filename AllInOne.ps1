# Először telepítjük a Winget-et
Write-Host "Winget telepitése..."
powershell "&([ScriptBlock]::Create((irm asheroto.com/winget))) -Force" 

# Programok telepítése Winget segítségével
$programs = @(
    "Google.Chrome",
    "Mozilla.Firefox",
    "Adobe.Acrobat.Reader.64-bit",
    "VideoLAN.VLC",
    "Notepad++.Notepad++",
    "WinRAR.WinRAR",
    "EclipseAdoptium.Temurin.22.JRE",
    "abbodi1406.vcredist"
)

$totalPrograms = $programs.Count
$currentProgram = 0

foreach ($program in $programs) {
    $currentProgram++
    Write-Host "Program telepitese: $program..."
    winget install --id $program --silent --accept-package-agreements --accept-source-agreements

    # Progress bar frissítése
    $progress = [math]::round(($currentProgram / $totalPrograms) * 100)
    Write-Progress -Activity "Programok telepitese" -Status "$currentProgram / $totalPrograms" -PercentComplete $progress
}

# Progress bar eltávolítása
Write-Progress -Activity "Programok telepitese" -Completed

Write-Host "Sikeresen feltelepultek a programok."

# MediCat v21.12 meghajtó keresése és Office telepítése
$medicatDriveLetter = Get-WmiObject Win32_Volume | Where-Object { $_.Label -eq 'MediCat v21.12' } | Select-Object -ExpandProperty DriveLetter
if ($medicatDriveLetter) {
    $officeInstallScript = "$medicatDriveLetter\Office\install.cmd"
    if (Test-Path $officeInstallScript) {
        Write-Host "Microsoft Office telepítése a MediCat v21.12 USB meghajtorol..."
        Start-Process -FilePath $officeInstallScript -WorkingDirectory "$medicatDriveLetter\Office" -Wait
        Write-Host "Microsoft Office telepitese befejezodott."
    } else {
        Write-Host "Nem található az Office telepitesi parancsfajl a MediCat v21.12 USB meghajtón."
    }
} else {
    Write-Host "Nem található MediCat v21.12 USB meghajto."
}


# Fájlok letöltése és futtatása
$fileUrls = @{
    "winactivator.cmd" = "https://raw.githubusercontent.com/LoginRs99/LogoScripptek/main/winactivator.cmd"
    "Officeactivator.cmd" = "https://raw.githubusercontent.com/LoginRs99/LogoScripptek/main/Officeactivator.cmd"
}

foreach ($file in $fileUrls.GetEnumerator()) {
    $fileName = $file.Key
    $url = $file.Value
    $outputPath = "$env:TEMP\$fileName"

 # Letöltés
    Write-Host "Letöltés: $url"
    Invoke-WebRequest -Uri $url -OutFile $outputPath

 # Futtatás
    if (Test-Path $outputPath) {
        Write-Host "Futtatás: $outputPath"
        Start-Process -FilePath $outputPath -Wait -NoNewWindow
        Write-Host "$fileName futtatása befejeződött."

 # Fájl törlése
        Remove-Item -Path $outputPath -Force
        Write-Host "$fileName törölve lett a TEMP mappából."
    } else {
        Write-Host "Nem sikerült letölteni a $fileName fájlt."
    }
}

# NuGet provider telepítése
Write-Host "NuGet provider telepitese..."
Install-PackageProvider -Name NuGet -Force -Confirm:$false

# Windows frissítések indítása
Write-Host "Windows frissítések keresése és telepítése..."
Install-Module PSWindowsUpdate -Force -SkipPublisherCheck
Import-Module PSWindowsUpdate
Write-Host "Windows frissítések telepítése folyamatban..."
Get-WindowsUpdate -AcceptAll -Install -AutoReboot
