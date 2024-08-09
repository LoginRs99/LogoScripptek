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
    Write-Host "A script adminisztratori jogokkal valo futtatasa szukseges!"
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

if (-not (Test-Winget)) {
    Write-Host "A winget nincs telepitve."
    $installWinget = Read-Host "Szeretne telepiteni a winget-et? (i/n)"
    if ($installWinget -eq 'i') {
        try {
            Write-Host "Winget telepitese..."
            &([ScriptBlock]::Create((irm asheroto.com/winget))) -Force
            Write-Host "A winget telepitese sikeres volt."
        } catch {
            Write-Host "Hiba tortent a winget telepitese kozben."
            exit
        }
    } else {
        Write-Host "A winget telepitese kihagyva. A script nem tudja folytatni a futast winget nelkul."
        exit
    }
}

# Az aktualis konyvtar eleresi utja
$scriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Path -Parent

# Alapertelmezett fajl: programok.txt
$selectedChoice = "$scriptDirectory\programok.txt"

# Olvasd be a programokat es winget id-ket
if (Test-Path $selectedChoice) {
    Write-Host "Fajl megtalalva: $selectedChoice"
    $lines = Get-Content $selectedChoice
    $categoryOrder = @()
    $categoryProgramMap = @{}
    $programList = @{}
    $programMap = @{}
    $programStatus = @{}  # Ez a hash tabla tartja nyilvan a programok allapotat
    $currentCategory = ''
    $currentIndex = 1

    # Olvassuk be a fajl tartalmat
    foreach ($line in $lines) {
        Write-Host "Beolvasott sor: $line"  # Hibakereso info
        if ($line.Trim() -eq '' -or $line -match '^\s*#') {
            # Ha a sor ures vagy kommentar
            if ($line -match '^\s*#\s*KATEGÓRIA:\s*(.+)') {
                $currentCategory = $matches[1]
                Write-Host "Aktualis kategoria: $currentCategory"  # Hibakereso info
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
                Write-Host "Program: $programName, ID: $wingetId"  # Hibakereso info
                $programList[$currentIndex] = $wingetId
                $programMap[$wingetId] = $programName  # Hash tabla modositva a winget id alapjan
                $programStatus[$currentIndex] = $false  # Alapertelmezetten nem telepitendo
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
            Write-Host "`n# Kategoria: $category"
            if ($categoryProgramMap.ContainsKey($category)) {
                foreach ($index in $categoryProgramMap[$category].Keys | Sort-Object) {
                    $programName = $categoryProgramMap[$category][$index]
                    $color = if ($programStatus[$index]) { "Green" } else { "White" }
                    Write-Host "$index. $programName" -ForegroundColor $color
                }
            }
        }

        Write-Host ""  # Ures sor hozzaadasa a programok listaja utan

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
                    Write-Host "Ervenytelen szam: $index. Kerlek, probald ujra."
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
                Write-Host "Hiba tortent a $programName telepitese kozben."
            }
        }
    } else {
        Write-Host "Nincsenek kivalasztott programok a telepiteshez."
    }
} else {
    Write-Host "A kivalasztott fajl nem talalhato: $selectedChoice"
}

# Varakozas 5 masodpercig, mielott a PowerShell bezarul
Write-Host "A script befejezodott. A PowerShell ablak 5 masodperc mulva bezarul..."
Start-Sleep -Seconds 5
