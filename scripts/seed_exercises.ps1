$ErrorActionPreference = "Stop"

function Read-EnvFile {
  param([string]$envFilePath)
  $envMap = @{}
  if (!(Test-Path $envFilePath)) {
    throw "Missing .env file. Create one in the project root."
  }
  Get-Content $envFilePath | ForEach-Object {
    $line = $_.Trim()
    if ($line -and -not $line.StartsWith('#')) {
      $parts = $line -split '=', 2
      if ($parts.Length -eq 2) {
        $envMap[$parts[0].Trim()] = $parts[1].Trim()
      }
    }
  }
  return $envMap
}

function Invoke-JsonRequest {
  param(
    [string]$Method,
    [string]$Url,
    [hashtable]$Headers = @{},
    $Body = $null
  )
  try {
    if ($Body -ne $null) {
      $jsonBody = $Body | ConvertTo-Json -Depth 8
      return Invoke-RestMethod -Method $Method -Uri $Url -Headers $Headers -Body $jsonBody -ContentType "application/json"
    }
    return Invoke-RestMethod -Method $Method -Uri $Url -Headers $Headers
  } catch {
    if ($_.Exception.Response) {
      try {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "HTTP error body: $responseBody"
      } catch {
        Write-Host "HTTP error body: (unavailable)"
      }
    }
    throw
  }
}

function Seed-ExerciseDb {
  param(
    [string]$RapidKey,
    [string]$RapidHost,
    [string]$RapidBase
  )
  $headers = @{
    "X-RapidAPI-Key" = $RapidKey
    "X-RapidAPI-Host" = $RapidHost
  }
  $endpoint = "$RapidBase/exercises"
  Write-Host "Fetching ExerciseDB data from $endpoint ..."
  $data = Invoke-JsonRequest -Method "GET" -Url $endpoint -Headers $headers
  if (-not $data) {
    throw "ExerciseDB returned no data."
  }
  return $data
}

function Seed-ApiNinjas {
  param([string]$ApiKey)
  $headers = @{
    "X-Api-Key" = $ApiKey
  }
  $muscles = @(
    "abdominals","abductors","adductors","biceps","calves","chest","forearms",
    "glutes","hamstrings","lats","lower_back","middle_back","neck","quadriceps",
    "traps","triceps"
  )

  $results = @()
  foreach ($muscle in $muscles) {
    Write-Host "Fetching API Ninjas exercises for muscle: $muscle ..."
    $safeMuscle = [System.Uri]::EscapeDataString($muscle)
    $url = "https://api.api-ninjas.com/v1/exercises?muscle=$safeMuscle"
    try {
      $page = Invoke-JsonRequest -Method "GET" -Url $url -Headers $headers
      foreach ($item in $page) {
        $name = ($item.name -as [string]).Trim()
        if (-not $name) { continue }
        $equipment = $item.equipment
        if ($equipment -is [array]) {
          $equipment = ($equipment -join ", ")
        }
        if (-not $equipment) {
          $equipment = "bodyweight"
        }
        $target = $item.muscle
        if (-not $target) {
          $target = "unknown"
        }
        $results += [pscustomobject]@{
          name = $name
          target = $target
          equipment = $equipment
          bodyPart = $item.type
        }
      }
    } catch {
      Write-Host "Skipping muscle '$muscle' due to request error."
    }
    Start-Sleep -Milliseconds 250
  }
  return $results
}

function Save-LocalCache {
  param(
    [array]$Exercises,
    [string]$Path
  )
  $folder = Split-Path $Path -Parent
  if (!(Test-Path $folder)) {
    New-Item -ItemType Directory -Path $folder | Out-Null
  }
  $payload = $Exercises | ForEach-Object {
    @{
      name = $_.name
      target = $_.target
      equipment = $_.equipment
      bodyPart = $_.bodyPart
    }
  }
  $payload | ConvertTo-Json -Depth 6 | Set-Content -Path $Path -Encoding UTF8
  Write-Host "Saved local cache to $Path"
}

function Load-LocalCache {
  param([string]$Path)
  if (!(Test-Path $Path)) {
    throw "Local cache not found at $Path"
  }
  $raw = Get-Content $Path -Raw | ConvertFrom-Json
  $items = @()
  foreach ($item in $raw) {
    $items += [pscustomobject]@{
      name = $item.name
      target = $item.target
      equipment = $item.equipment
      bodyPart = $item.bodyPart
    }
  }
  return $items
}

function Seed-Wger {
  $musclesUrl = "https://wger.de/api/v2/muscle/"
  $equipmentUrl = "https://wger.de/api/v2/equipment/"
  Write-Host "Fetching Wger muscles & equipment..."
  $muscleData = Invoke-JsonRequest -Method "GET" -Url $musclesUrl
  $equipmentData = Invoke-JsonRequest -Method "GET" -Url $equipmentUrl

  $muscleMap = @{}
  foreach ($m in $muscleData.results) {
    $muscleMap[$m.id] = $m.name
  }
  $equipmentMap = @{}
  foreach ($e in $equipmentData.results) {
    $equipmentMap[$e.id] = $e.name
  }

  $exercises = @()
  $nextUrl = "https://wger.de/api/v2/exercise/?limit=200&language=2&status=2"
  $pages = 0
  while ($nextUrl -and $pages -lt 10) {
    $pages++
    Write-Host "Fetching Wger exercises page $pages..."
    $page = Invoke-JsonRequest -Method "GET" -Url $nextUrl
    foreach ($item in $page.results) {
      $name = ($item.name -as [string]).Trim()
      if (-not $name) { continue }
      $muscleId = $item.muscles | Select-Object -First 1
      $equipmentId = $item.equipment | Select-Object -First 1
      $exercises += [pscustomobject]@{
        name = $name
        target = $muscleMap[$muscleId]
        equipment = $equipmentMap[$equipmentId]
        bodyPart = $null
      }
    }
    $nextUrl = $page.next
  }
  return $exercises
}

function Insert-Exercises {
  param(
    [string]$SupabaseUrl,
    [string]$ServiceRoleKey,
    [array]$Exercises
  )
  $deduped = @()
  $seen = @{}
  foreach ($item in $Exercises) {
    $key = ($item.name -as [string]).Trim().ToLower()
    if (-not $key) { continue }
    if (-not $seen.ContainsKey($key)) {
      $seen[$key] = $true
      $deduped += $item
    }
  }
  $Exercises = $deduped

  $headers = @{
    "apikey" = $ServiceRoleKey
    "Authorization" = "Bearer $ServiceRoleKey"
    "Prefer" = "resolution=merge-duplicates"
  }
  $endpoint = "$SupabaseUrl/rest/v1/exercises?on_conflict=name"

  $batchSize = 200
  $count = 0
  for ($i = 0; $i -lt $Exercises.Count; $i += $batchSize) {
    $batch = $Exercises[$i..([Math]::Min($i + $batchSize - 1, $Exercises.Count - 1))]
    $payload = $batch | ForEach-Object {
      @{
        name = $_.name
        equipment = $_.equipment
        target_muscle = $_.target
        body_part = $_.bodyPart
      }
    }
    Invoke-JsonRequest -Method "POST" -Url $endpoint -Headers $headers -Body $payload | Out-Null
    $count += $batch.Count
    Write-Host "Inserted $count / $($Exercises.Count)"
  }
}

Set-Location (Split-Path $PSScriptRoot -Parent)
Write-Host "Loading environment..."
$envMap = Read-EnvFile ".env"

$supabaseUrl = $envMap["SUPABASE_URL"]
$serviceRoleKey = $envMap["SUPABASE_SERVICE_ROLE_KEY"]
$seedSource = $envMap["EXERCISE_SEED_SOURCE"]
$rapidKey = $envMap["EXERCISEDB_RAPIDAPI_KEY"]
$rapidHost = $envMap["EXERCISEDB_RAPIDAPI_HOST"]
$rapidBase = $envMap["EXERCISEDB_RAPIDAPI_BASE"]
$apiNinjasKey = $envMap["API_NINJAS_KEY"]
$cachePath = $envMap["EXERCISE_CACHE_PATH"]
if (-not $cachePath) {
  $cachePath = "data\exercises_api_ninjas.json"
}

if (-not $supabaseUrl -or -not $serviceRoleKey) {
  throw "Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in .env"
}

if (-not $seedSource) {
  if ($apiNinjasKey) {
    $seedSource = "api_ninjas"
  } elseif ($rapidKey) {
    $seedSource = "exercisedb"
  } else {
    $seedSource = "wger"
  }
}

if ($seedSource -eq "api_ninjas") {
  if (-not $apiNinjasKey) {
    throw "Missing API_NINJAS_KEY. Set it or switch seed source."
  }
  $raw = Seed-ApiNinjas -ApiKey $apiNinjasKey
  Save-LocalCache -Exercises $raw -Path $cachePath
  Insert-Exercises -SupabaseUrl $supabaseUrl -ServiceRoleKey $serviceRoleKey -Exercises $raw
} elseif ($seedSource -eq "api_ninjas_cache") {
  $raw = Load-LocalCache -Path $cachePath
  Insert-Exercises -SupabaseUrl $supabaseUrl -ServiceRoleKey $serviceRoleKey -Exercises $raw
} elseif ($seedSource -eq "exercisedb") {
  if (-not $rapidKey) {
    throw "Missing EXERCISEDB_RAPIDAPI_KEY. Set it or switch to Wger."
  }
  if (-not $rapidHost) { $rapidHost = "exercisedb.p.rapidapi.com" }
  if (-not $rapidBase) { $rapidBase = "https://exercisedb.p.rapidapi.com" }

  $raw = Seed-ExerciseDb -RapidKey $rapidKey -RapidHost $rapidHost -RapidBase $rapidBase
  $exercises = @()
  foreach ($item in $raw) {
    $name = ($item.name -as [string]).Trim()
    if (-not $name) { continue }
    $exercises += [pscustomobject]@{
      name = $name
      target = $item.target
      equipment = $item.equipment
      bodyPart = $item.bodyPart
    }
  }
  Insert-Exercises -SupabaseUrl $supabaseUrl -ServiceRoleKey $serviceRoleKey -Exercises $exercises
} elseif ($seedSource -eq "wger") {
  $raw = Seed-Wger
  Insert-Exercises -SupabaseUrl $supabaseUrl -ServiceRoleKey $serviceRoleKey -Exercises $raw
} else {
  throw "Unknown EXERCISE_SEED_SOURCE. Use exercisedb or wger."
}

Write-Host "Done."
