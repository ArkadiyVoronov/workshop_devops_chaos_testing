# Генератор трафика для тестирования
param(
    [int]$Count = 30,
    [string]$Url = "http://localhost:5000/api/balance",
    [int]$DelayMs = 200
)

$success = 0
$errors = 0

for ($i = 1; $i -le $Count; $i++) {
    try {
        $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 5
        if ($response.StatusCode -eq 200) {
            $success++
        } else {
            $errors++
        }
        Write-Host "$i/$Count - $($response.StatusCode)" -NoNewline:$($i -lt $Count)
        Write-Host " " -NoNewline
    } catch {
        $errors++
        Write-Host "$i/$Count - ERR: $($_.Exception.Message)" -NoNewline
        Write-Host " " -NoNewline
    }
    if ($i -lt $Count) { Start-Sleep -Milliseconds $DelayMs }
}

Write-Host ""
Write-Host "Results: Success=$success, Errors=$errors"
