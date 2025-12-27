$files = Get-ChildItem -Path "lib\screens" -Filter "*.dart" -Recurse
$count = 0

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw -Encoding UTF8
    $modified = $false
    
    # Replace solid black backgrounds with navy blue
    if ($content -match 'backgroundColor:\s*Colors\.black,') {
        $content = $content -replace 'backgroundColor:\s*Colors\.black,', 'backgroundColor: const Color(0xFF0A1929),'
        $modified = $true
    }
    
    # Replace color: Colors.black, (solid black) with navy blue
    if ($content -match 'color:\s*Colors\.black,') {
        $content = $content -replace 'color:\s*Colors\.black,', 'color: const Color(0xFF0A1929),'
        $modified = $true
    }
    
    # Replace Colors.black) at end of line with navy blue
    if ($content -match 'Colors\.black\)') {
        $content = $content -replace ':\s*Colors\.black\)', ': const Color(0xFF0A1929))'
        $modified = $true
    }
    
    if ($modified) {
        Set-Content -Path $file.FullName -Value $content -NoNewline -Encoding UTF8
        $count++
        Write-Host "Updated: $($file.Name)"
    }
}

Write-Host "Total files updated: $count"
