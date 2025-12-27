$files = Get-ChildItem -Path "lib" -Filter "*.dart" -Recurse
foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw -Encoding UTF8
    if ($content -match "0xFF121212") {
        $newContent = $content -replace "0xFF121212", "0xFF0A1929"
        Set-Content -Path $file.FullName -Value $newContent -NoNewline -Encoding UTF8
        Write-Host "Updated: $($file.FullName)"
    }
}
Write-Host "Done!"
