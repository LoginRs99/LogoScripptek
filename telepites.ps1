# Ellenorizzuk, hogy adminisztratori jogokkal fut-e a script
function Test-Admin {
    try {
        $admin = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
        return $admin.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch {
        return $false
    }
}

if (-not (Test-Admin)) {
    Write-Host "A script adminisztratori jogokkal valo futtatasa szukseges!" -ForegroundColor Red
    Start-Process powershell -ArgumentList "Start-Process PowerShell -ArgumentList '$($MyInvocation.MyCommand.Definition)' -Verb RunAs" -Verb RunAs
    exit
}

# Ellenorizzuk, hogy a winget telepitve van-e
function Test-Winget {
    try {
        winget --version > $null 2>&1
        return $true
    } catch {
        return $false
    }
}

# Ellenőrizzük, hogy a winget elérhető-e
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "Winget nem található, telepítés folyamatban..."
    
    # Winget automatikus telepítése egy külön folyamatban
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `&([ScriptBlock]::Create((irm asheroto.com/winget)))`" -Wait

    # Várunk néhány másodpercet a telepítés után
    Start-Sleep -Seconds 10

    # Újra ellenőrizzük, hogy sikeresen települt-e
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Host "Hiba történt a winget telepítése közben. A script leáll."
        exit 1
    } else {
        Write-Host "Winget sikeresen telepítve."
    }
}

# A script itt folytatódik...
Write-Host "Winget már telepítve van, folytatás..."

# Beagyazott programok es winget ID-k listaja
$programData = @"
# KATEGORIA: ALAPVETO ESZKOZOK
Winrar | RARLab.WinRAR
7zip | 7zip.7zip
Notepad ++ | Notepad++.Notepad++
Adobe Acrobat Reader | Adobe.Acrobat.Reader.64-bit
Visual C++ Redistributable Runtimes | abbodi1406.vcredist
Temurin java | EclipseAdoptium.Temurin.22.JRE
Total Commander | Ghisler.TotalCommander
UniGetUI | SomePythonThings.WingetUIStore

# KATEGORIA: INTERNET BONGESZOK
Chrome | Google.Chrome
Firefox | Mozilla.Firefox
Opera GX | Opera.OperaGX
Brave | Brave.Brave

# KATEGORIA: GAMING
EpicGames | EpicGames.EpicGamesLauncher
GOG | GOG.Galaxy
Steam | Valve.Steam
EA launcher | ElectronicArts.EADesktop
Ubisoft Connect | Ubisoft.Connect

# KATEGORIA: MEDIA
Discord | Discord.Discord
VLC | Videolan.Vlc
Potplayer | Daum.PotPlayer
Microsoft Teams(free) | Microsoft.Teams.Free
Zoom | Zoom.Zoom
Spotify | 9NCBCSZSJRSB
Deluge | DelugeTeam.Deluge
Transmission | Transmission.Transmission
Qbittorent | qBittorrent.qBittorrent

# KATEGORIA: TAVOLI ELERES
Rustdesk | RustDesk.RustDesk
Anydesk | AnyDeskSoftwareGmbH.AnyDesk
Teamviewer | TeamViewer.TeamViewer
Ultraviewer | DucFabulous.UltraViewer
"@

# Olvasd be a programokat es winget id-ket
$lines = $programData -split "`n"
$categoryOrder = @()
$categoryProgramMap = @{}
$programList = @{}
$programMap = @{}
$programStatus = @{}  # Ez a hash tabla tartja nyilvan a programok allapotat
$currentCategory = ''
$currentIndex = 1

# Olvassuk be a fajl tartalmat
foreach ($line in $lines) {
    if ($line.Trim() -eq '' -or $line -match '^\s*#') {
        # Ha a sor ures vagy kommentar
        if ($line -match '^\s*#\s*KATEGORIA:\s*(.+)') {
            $currentCategory = $matches[1]
            $categoryOrder += $currentCategory
            if (-not $categoryProgramMap.ContainsKey($currentCategory)) {
                $categoryProgramMap[$currentCategory] = @{}
            }
        }
    } else {
        # Program neve es winget id parok
        $parts = $line -split '\s*\|\s*'
        if ($parts.Length -eq 2) {
            $programName = $parts[0].Trim()
            $wingetId = $parts[1].Trim()
            $programList[$currentIndex] = $wingetId
            $programMap[$wingetId] = $programName  # Hash tabla modositva a winget id alapjan
            $programStatus[$currentIndex] = $false  # Alapertelmezetten nem telepitendo (feher)
            if ($currentCategory -ne '' -and $categoryProgramMap.ContainsKey($currentCategory)) {
                $categoryProgramMap[$currentCategory][$currentIndex] = $programName
            }
            $currentIndex++
        }
    }
}

# Vegtelen ciklus a felhasznaloi interakciohoz
while ($true) {
    # Kategoriak es programok kiirasa
    Clear-Host
    Write-Host "`nElerheto programok:`n"

    foreach ($category in $categoryOrder) {
        Write-Host "`n# Kategoria: $category" -ForegroundColor Red -BackgroundColor Black
        if ($categoryProgramMap.ContainsKey($category)) {
            foreach ($index in $categoryProgramMap[$category].Keys | Sort-Object) {
                $programName = $categoryProgramMap[$category][$index]
                $color = if ($programStatus[$index]) { "Green" } else { "White" }
                Write-Host "$index. $programName" -ForegroundColor $color
            }
        }
    }

    Write-Host ""  # Ures sor hozzaadva a programok listaja utan

    # Felhasznaloi bemenet
    $input = Read-Host "Valaszd ki a telepitendo programokat (pl. 1,2,5), vagy nyomd meg az Entert a folytatashoz"

    if ($input -eq '') {
        break
    }

    if ($input -eq 'A') {
        # Visszaallit minden programot alapertelmezett allapotba
        foreach ($key in $programStatus.Keys) {
            $programStatus[$key] = $false
        }
    } else {
        # Tobbszam bevitele vesszovel elvalasztva
        $selectedIndexes = $input -split '\s*,\s*' | ForEach-Object { [int]$_ }
        foreach ($index in $selectedIndexes) {
            if ($programStatus.ContainsKey($index)) {
                $programStatus[$index] = -not $programStatus[$index]  # Valtas igazra vagy hamisra
            } else {
                Write-Host "Ervenytelen szam: $index. Kerlek, probald ujra." -ForegroundColor Yellow
            }
        }
    }
}

$selectedPrograms = $programStatus.Keys | Where-Object { $programStatus[$_] } | ForEach-Object { $programList[$_] }
$selectedProgramNames = $selectedPrograms | ForEach-Object { $programMap[$_] }

if ($selectedPrograms.Count -gt 0) {
    Write-Host "`nKivalasztott programok a telepiteshez: $($selectedProgramNames -join ', ')`n"
    foreach ($programId in $selectedPrograms) {
        $programName = $programMap[$programId]
        Write-Host "Telepites: $programName"
        try {
            winget install --id=$programId --silent --accept-package-agreements --accept-source-agreements --disable-interactivity
        } catch {
            Write-Host "Hiba tortent a $programName telepitese kozben." -ForegroundColor Red
        }
    }
} else {
    Write-Host "Nincsenek kivalasztott programok a telepiteshez." -ForegroundColor Yellow
}

# Varakozas 5 masodpercig, mielott a PowerShell bezarul
Write-Host "A script befejezodott. A PowerShell ablak 5 masodperc mulva bezarul..." -ForegroundColor Green
Start-Sleep -Seconds 5
