$pivTool = 'C:\Program Files\Yubico\Yubico PIV Tool\bin\yubico-piv-tool.exe'
if (!(Test-Path $pivTool)) {
    Write-Host "PIV Tool Not Detected. Downloading installer" -ForegroundColor Yellow
    cd $PSScriptRoot

    Invoke-WebRequest -Uri "https://developers.yubico.com/yubico-piv-tool/Releases/yubico-piv-tool-2.3.0-win64.msi" -Method Get -OutFile "yubico-piv-tool-2.3.0-win64.msi"
    Write-Host "Installing PIV Tool" -ForegroundColor Yellow
    
    Start-Sleep -Seconds 2

    msiexec.exe /i yubico-piv-tool-2.3.0-win64.msi /passive
}