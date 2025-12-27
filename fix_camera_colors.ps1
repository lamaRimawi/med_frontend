$file = "lib\screens\camera_upload_screen.dart"
$content = Get-Content $file -Raw -Encoding UTF8

# Replace Colors.black with navy blue, but keep .withOpacity() calls
$content = $content -replace 'Colors\.black\.withOpacity', 'const Color(0xFF0A1929).withOpacity'
$content = $content -replace 'Colors\.black,', 'const Color(0xFF0A1929),'
$content = $content -replace ': Colors\.black\)', ': const Color(0xFF0A1929))'

Set-Content -Path $file -Value $content -NoNewline -Encoding UTF8
Write-Host "Updated camera_upload_screen.dart"
