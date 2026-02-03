$envFile = Join-Path (Split-Path $PSScriptRoot -Parent) ".env"
if (!(Test-Path $envFile)) {
  Write-Host "Missing .env file. Create one from .env.example" -ForegroundColor Red
  exit 1
}

$envMap = @{}
Get-Content $envFile | ForEach-Object {
  $line = $_.Trim()
  if ($line -and -not $line.StartsWith('#')) {
    $parts = $line -split '=', 2
    if ($parts.Length -eq 2) {
      $envMap[$parts[0].Trim()] = $parts[1].Trim()
    }
  }
}

$apiKey = $envMap['GEMINI_API_KEY']
if (-not $apiKey) {
  Write-Host "Missing GEMINI_API_KEY in .env" -ForegroundColor Red
  exit 1
}

$uri = "https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey"
try {
  $resp = Invoke-RestMethod -Method Get -Uri $uri
} catch {
  Write-Host "Failed to list models: $($_.Exception.Message)" -ForegroundColor Red
  exit 1
}

$models = $resp.models | Where-Object { $_.supportedGenerationMethods -contains "generateContent" }
if (-not $models -or $models.Count -eq 0) {
  Write-Host "No models with generateContent found for this key." -ForegroundColor Red
  exit 1
}

# Prefer flash models if available, otherwise first generateContent model.
$preferred = $models | Where-Object { $_.name -match "flash" } | Select-Object -First 1
if (-not $preferred) {
  $preferred = $models | Select-Object -First 1
}

$selectedModel = $preferred.name
Write-Host "Selected model: $selectedModel"

# Update/insert GEMINI_MODEL in .env
$lines = Get-Content $envFile
$updated = $false
for ($i = 0; $i -lt $lines.Length; $i++) {
  if ($lines[$i].TrimStart().StartsWith('GEMINI_MODEL=')) {
    $lines[$i] = "GEMINI_MODEL=$selectedModel"
    $updated = $true
    break
  }
}
if (-not $updated) {
  $lines += "GEMINI_MODEL=$selectedModel"
}

Set-Content -Path $envFile -Value $lines
Write-Host "Updated GEMINI_MODEL in .env"
