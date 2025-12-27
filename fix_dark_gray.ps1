$files = Get-ChildItem -Path "lib" -Filter "*.dart" -Recurse
$count = 0

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw -Encoding UTF8
    
    if ($content -match '0xFF2A2A2A') {
        # Replace with navy blue for borders and backgrounds
        $content = $content -replace '0xFF2A2A2A', '0xFF0F2137'
        Set-Content -Path $file.FullName -Value $content -NoNewline -Encoding UTF8
        $count++
        Write-Host "Updated: $($file.Name)"
    }
}

Write-Host "Total files updated: $count"
