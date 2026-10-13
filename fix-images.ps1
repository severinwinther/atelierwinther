# Atelier Winther — fix-images.ps1
# Legg denne filen i samme mappe som index.html
# Høyreklikk på filen → "Run with PowerShell"

$ErrorActionPreference = "Continue"
$htmlFile = "index.html"
$imgDir   = "img"

if (-not (Test-Path $htmlFile)) {
    Write-Host "FEIL: index.html ikke funnet. Legg fix-images.ps1 i samme mappe som index.html." -ForegroundColor Red
    Read-Host "Trykk Enter for å avslutte"
    exit 1
}

$html    = Get-Content $htmlFile -Raw -Encoding UTF8
$pattern = 'https://atelierwinther\.com/wp-content/uploads/[^\s"''<>]+'
$urls    = [regex]::Matches($html, $pattern) | ForEach-Object { $_.Value } | Sort-Object -Unique

Write-Host "Fant $($urls.Count) bilder å laste ned.`n"
New-Item -ItemType Directory -Force -Path $imgDir | Out-Null

$i = 0
foreach ($url in $urls) {
    $i++
    $fname = [System.IO.Path]::GetFileName(($url -split '\?')[0])
    $dest  = Join-Path $imgDir $fname

    if (Test-Path $dest) {
        Write-Host "[$i/$($urls.Count)] hopp over  $fname"
        continue
    }

    try {
        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add("User-Agent", "Mozilla/5.0")
        $wc.Headers.Add("Referer", "https://atelierwinther.com/")
        $wc.DownloadFile($url, (Resolve-Path $imgDir).Path + "\$fname")
        Write-Host "[$i/$($urls.Count)] OK    $fname"
    } catch {
        Write-Host "[$i/$($urls.Count)] FEIL  $fname  ($_)" -ForegroundColor Yellow
    }
}

Write-Host "`nSkriver om bildestiER i index.html..."
$html = [regex]::Replace($html, $pattern, {
    param($m)
    $fname = [System.IO.Path]::GetFileName(($m.Value -split '\?')[0])
    "img/$fname"
})

[System.IO.File]::WriteAllText((Resolve-Path $htmlFile).Path, $html, [System.Text.Encoding]::UTF8)

Write-Host "`n✓ Ferdig! Last nå opp img/-mappen og oppdatert index.html til GitHub." -ForegroundColor Green
Read-Host "Trykk Enter for å avslutte"
