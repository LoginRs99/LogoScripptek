[System.Console]::OutputEncoding = New-Object System.Text.UTF8Encoding $true;
Set-ExecutionPolicy Bypass -Scope Process -Force;

# Ellenőrizzük, hogy adminisztrátori jogokkal fut-e a script
function Test-Admin {
    try {
        $admin = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
        return $admin.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch {
        return $false
    }
}

if (-not (Test-Admin)) {
    Write-Host "A script adminisztrátori jogokkal való futtatása szükséges!" -ForegroundColor Red
    Start-Process powershell -ArgumentList "Start-Process PowerShell -ArgumentList '$($MyInvocation.MyCommand.Definition)' -Verb RunAs" -Verb RunAs
    exit
}

# Ellenőrizzük, hogy a winget telepítve van-e
function Test-Winget {
    try {
        winget --version > $null 2>&1
        return $true
    } catch {
        return $false
    }
}

if (-not (Test-Winget)) {
    Write-Host "A winget nincs telepítve." -ForegroundColor Yellow
    $installWinget = Read-Host "Szeretné telepíteni a winget-et? (i/n)"
    if ($installWinget -eq 'i') {
        try {
            Write-Host "Winget telepítése..."
            &([ScriptBlock]::Create((irm asheroto.com/winget))) -Force
            Write-Host "A winget telepítése sikeres volt." -ForegroundColor Green
        } catch {
            Write-Host "Hiba történt a winget telepítése közben." -ForegroundColor Red
            exit
        }
    } else {
        Write-Host "A winget telepítése kihagyva. A script nem tudja folytatni a futást winget nélkül." -ForegroundColor Red
        exit
    }
}

# Az aktuális könyvtár elérési útja
$scriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Path -Parent

# Alapértelmezett fájl: programok.txt
$selectedChoice = "$scriptDirectory\programok.txt"

# Olvasd be a programokat és winget id-ket
if (Test-Path $selectedChoice) {
    $lines = Get-Content $selectedChoice
    $categoryOrder = @()
    $categoryProgramMap = @{}
    $programList = @{}
    $programMap = @{}
    $programStatus = @{}  # Ez a hash tábla tartja nyilván a programok állapotát
    $currentCategory = ''
    $currentIndex = 1

    # Olvassuk be a fájl tartalmát
    foreach ($line in $lines) {
        if ($line.Trim() -eq '' -or $line -match '^\s*#') {
            # Ha a sor üres vagy kommentár
            if ($line -match '^\s*#\s*Kategória:\s*(.+)') {
                $currentCategory = $matches[1]
                $categoryOrder += $currentCategory
                if (-not $categoryProgramMap.ContainsKey($currentCategory)) {
                    $categoryProgramMap[$currentCategory] = @{}
                }
            }
        } else {
            # Program neve és winget id párok
            $parts = $line -split '\s*\|\s*'
            if ($parts.Length -eq 2) {
                $programName = $parts[0].Trim()
                $wingetId = $parts[1].Trim()
                $programList[$currentIndex] = $wingetId
                $programMap[$wingetId] = $programName  # Hash tábla módosítva a winget id alapján
                $programStatus[$currentIndex] = $false  # Alapértelmezés szerint nem telepítendő (fehér)
                if ($currentCategory -ne '' -and $categoryProgramMap.ContainsKey($currentCategory)) {
                    $categoryProgramMap[$currentCategory][$currentIndex] = $programName
                }
                $currentIndex++
            }
        }
    }

    # Végtelen ciklus a felhasználói interakcióhoz
    while ($true) {
        # Kategóriák és programok kiírása
        Clear-Host
        Write-Host "`nElérhető programok:`n"

        foreach ($category in $categoryOrder) {
            Write-Host "`n# Kategória: $category" -ForegroundColor Red -BackgroundColor Black
            if ($categoryProgramMap.ContainsKey($category)) {
                foreach ($index in $categoryProgramMap[$category].Keys | Sort-Object) {
                    $programName = $categoryProgramMap[$category][$index]
                    $color = if ($programStatus[$index]) { "Green" } else { "White" }
                    Write-Host "$index. $programName" -ForegroundColor $color
                }
            }
        }

        Write-Host ""  # Üres sor hozzáadása a programok listája után

        # Felhasználói bemenet
        $input = Read-Host "Válaszd ki a telepítendő programokat (pl. 1,2,5), vagy nyomd meg az Entert a folytatáshoz"

        if ($input -eq '') {
            break
        }

        if ($input -eq 'A') {
            # Visszaállít minden programot alapértelmezett állapotba
            foreach ($key in $programStatus.Keys) {
                $programStatus[$key] = $false
            }
        } else {
            # Több szám bevitele vesszővel elválasztva
            $selectedIndexes = $input -split '\s*,\s*' | ForEach-Object { [int]$_ }
            foreach ($index in $selectedIndexes) {
                if ($programStatus.ContainsKey($index)) {
                    $programStatus[$index] = -not $programStatus[$index]  # Váltás igazra vagy hamisra
                } else {
                    Write-Host "Érvénytelen szám: $index. Kérlek, próbáld újra." -ForegroundColor Yellow
                }
            }
        }
    }

    $selectedPrograms = $programStatus.Keys | Where-Object { $programStatus[$_] } | ForEach-Object { $programList[$_] }
    $selectedProgramNames = $selectedPrograms | ForEach-Object { $programMap[$_] }

    if ($selectedPrograms.Count -gt 0) {
        Write-Host "`nKiválasztott programok a telepítéshez: $($selectedProgramNames -join ', ')`n"
        foreach ($programId in $selectedPrograms) {
            $programName = $programMap[$programId]
            Write-Host "Telepítés: $programName"
            try {
                winget install --id=$programId --silent --accept-package-agreements --accept-source-agreements --disable-interactivity
            } catch {
                Write-Host "Hiba történt a $programName telepítése közben." -ForegroundColor Red
            }
        }
    } else {
        Write-Host "Nincsenek kiválasztott programok a telepítéshez." -ForegroundColor Yellow
    }
} else {
    Write-Host "A kiválasztott fájl nem található: $selectedChoice" -ForegroundColor Red
}

# Várakozás 5 másodpercig, mielőtt a PowerShell bezárul
Write-Host "A script befejeződött. A PowerShell ablak 5 másodperc múlva bezárul..." -ForegroundColor Green
Start-Sleep -Seconds 5
