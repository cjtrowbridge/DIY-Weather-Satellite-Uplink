param(
  [Parameter(Mandatory = $true)]
  [string] $BaseConfig,

  [Parameter(Mandatory = $false)]
  [string] $PartName,

  [Parameter(Mandatory = $false)]
  [string] $RevisionsDir = "cad/revisions",

  [Parameter(Mandatory = $false)]
  [string] $ConfigsDir = "cad/configs",

  [Parameter(Mandatory = $false)]
  [string] $MainScad = "cad/src/main.scad",

  [Parameter(Mandatory = $false)]
  [string] $OpenScadPath,

  [switch] $DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Info([string] $Message) { Write-Host "[rev] $Message" }

if (-not (Test-Path $BaseConfig)) { throw "BaseConfig not found: $BaseConfig" }

New-Item -ItemType Directory -Force -Path $RevisionsDir | Out-Null
New-Item -ItemType Directory -Force -Path $ConfigsDir | Out-Null

function Get-RevisionNumber([string] $Name) {
  if ($Name -match '^rev_(\d+)$') { return [int]$Matches[1] }
  if ($Name -match '^rev_(\d+)\.json$') { return [int]$Matches[1] }
  return 0
}

$max = 0
$existingDirs = Get-ChildItem -Path $RevisionsDir -Directory -Filter "rev_*" -ErrorAction SilentlyContinue
foreach ($dir in $existingDirs) {
  $n = Get-RevisionNumber -Name $dir.Name
  if ($n -gt $max) { $max = $n }
}

$existingConfigs = Get-ChildItem -Path $ConfigsDir -File -Filter "rev_*.json" -ErrorAction SilentlyContinue
foreach ($file in $existingConfigs) {
  $n = Get-RevisionNumber -Name $file.Name
  if ($n -gt $max) { $max = $n }
}

$next = $max + 1
$revName = "rev_{0:d4}" -f $next

$revDir = Join-Path $RevisionsDir $revName
$configPath = Join-Path $ConfigsDir "$revName.json"
$paramsPath = Join-Path $revDir "params.json"

if (Test-Path $revDir) { throw "Revision directory already exists: $revDir" }
if (Test-Path $configPath) { throw "Revision config already exists: $configPath" }

function ConvertTo-Hashtable {
  param([object] $Object)

  if ($Object -is [hashtable]) { return $Object }
  $h = @{}
  foreach ($p in $Object.PSObject.Properties) {
    $h[$p.Name] = $p.Value
  }
  return $h
}

$configObj = Get-Content $BaseConfig -Raw | ConvertFrom-Json
$configData = ConvertTo-Hashtable -Object $configObj
if (-not $PartName) {
  if ($configData.ContainsKey("part")) {
    $PartName = [string]$configData["part"]
  } else {
    throw "No -PartName provided and base config missing 'part'."
  }
}

Write-Info "Creating $revName"
Write-Info "BaseConfig: $BaseConfig"

if (-not $DryRun) {
  # DryRun affects only the OpenSCAD invocation below; we still write revision files
  # so the iteration pipeline can be verified without OpenSCAD installed.
}

New-Item -ItemType Directory -Force -Path $revDir | Out-Null
$json = ($configData | ConvertTo-Json -Depth 10)
Set-Content -Path $configPath -Value $json -Encoding UTF8
Set-Content -Path $paramsPath -Value $json -Encoding UTF8

$buildScript = Join-Path $PSScriptRoot "scad_build.ps1"
$buildArgs = @(
  "-Config", $configPath,
  "-PartName", $PartName,
  "-OutDir", $revDir,
  "-MainScad", $MainScad
)
if ($OpenScadPath) {
  $buildArgs += @("-OpenScadPath", $OpenScadPath)
}
if ($DryRun) { $buildArgs += "-DryRun" }

Write-Info "Building artifacts into: $revDir"
& powershell -ExecutionPolicy Bypass -File $buildScript @buildArgs

Write-Info "Revision ready: $revDir"
