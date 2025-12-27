$files = Get-ChildItem -Path "lib" -Filter "*.dart" -Recurse
$count = 0
foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw -Encoding UTF8
    $modified = $false
    
    if ($content -match "0xFF1E1E1E") {
        $content = $content -replace "0xFF1E1E1E", "0xFF0F2137"
        $modified = $true
    }
    
    if ($content -match "0xFF2C2C2C") {
        $content = $content -replace "0xFF2C2C2C", "0xFF0F2137"
        $modified = $true
    }
    
    if ($modified) {
        Set-Content -Path $file.FullName -Value $content -NoNewline -Encoding UTF8
        $count++
        Write-Host "Updated: $($file.Name)"
    }
}
Write-Host "Total files updated: $count"
