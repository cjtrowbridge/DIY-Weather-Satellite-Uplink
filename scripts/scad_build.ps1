param(
  [Parameter(Mandatory = $false)]
  [string] $Design = "helical",

  [Parameter(Mandatory = $true)]
  [string] $Config,

  [Parameter(Mandatory = $false)]
  [string] $PartName,

  [Parameter(Mandatory = $false)]
  [string] $OutDir,

  [Parameter(Mandatory = $false)]
  [string] $MainScad,

  [Parameter(Mandatory = $false)]
  [string] $OpenScadPath,

  [switch] $DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Info([string] $Message) { Write-Host "[scad] $Message" }

if (-not $OutDir) { $OutDir = Join-Path "cad/out" $Design }
if (-not $MainScad) { $MainScad = Join-Path (Join-Path (Join-Path "cad/designs" $Design) "src") "main.scad" }

function Resolve-OpenScadExe {
  param([string] $ExplicitPath)

  if ($ExplicitPath) {
    if (-not (Test-Path $ExplicitPath)) { throw "OpenSCAD not found at -OpenScadPath: $ExplicitPath" }
    return $ExplicitPath
  }

  $cmd = Get-Command openscad -ErrorAction SilentlyContinue
  if ($cmd -and $cmd.Source) { return $cmd.Source }

  $known = @(
    "C:\Program Files\OpenSCAD\openscad.exe",
    "C:\Program Files (x86)\OpenSCAD\openscad.exe"
  )
  foreach ($p in $known) {
    if (Test-Path $p) { return $p }
  }

  $appPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\openscad.exe",
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\openscad.exe"
  )
  foreach ($k in $appPaths) {
    if (Test-Path $k) {
      try {
        $p = (Get-ItemProperty $k)."(default)"
        if ($p -and (Test-Path $p)) { return $p }
      } catch {
      }
    }
  }

  throw "OpenSCAD CLI not found. Install OpenSCAD or pass -OpenScadPath."
}

function ConvertTo-OpenScadValue {
  param([object] $Value)

  if ($null -eq $Value) { return "undef" }

  if ($Value -is [string]) {
    $escaped = $Value.Replace('\', '\\').Replace('"', '\"')
    return '"' + $escaped + '"'
  }

  if ($Value -is [bool]) {
    if ($Value) { return "true" }
    return "false"
  }

  if ($Value -is [int] -or $Value -is [long]) {
    return $Value.ToString([System.Globalization.CultureInfo]::InvariantCulture)
  }

  if ($Value -is [double] -or $Value -is [float] -or $Value -is [decimal]) {
    return ([double]$Value).ToString([System.Globalization.CultureInfo]::InvariantCulture)
  }

  throw "Unsupported config value type: $($Value.GetType().FullName)"
}

function ConvertTo-OpenScadDefines {
  param([hashtable] $ConfigData)

  $args = @()
  foreach ($key in ($ConfigData.Keys | Sort-Object)) {
    if ($key -eq "part") { continue } # string quoting is fragile on Windows; use part_id
    $val = ConvertTo-OpenScadValue -Value $ConfigData[$key]
    $args += @("-D", "$key=$val")
  }
  return $args
}

if (-not (Test-Path $Config)) { throw "Config not found: $Config" }
if (-not (Test-Path $MainScad)) { throw "Main SCAD not found: $MainScad" }

function ConvertTo-Hashtable {
  param([object] $Object)

  if ($Object -is [hashtable]) { return $Object }
  $h = @{}
  foreach ($p in $Object.PSObject.Properties) {
    $h[$p.Name] = $p.Value
  }
  return $h
}

$configObj = Get-Content $Config -Raw | ConvertFrom-Json
$configData = ConvertTo-Hashtable -Object $configObj

function Resolve-PartId {
  param([hashtable] $ConfigData)

  if ($ConfigData.ContainsKey("part_id")) { return [int]$ConfigData["part_id"] }
  if ($ConfigData.ContainsKey("part")) {
    $p = [string]$ConfigData["part"]
    if ($p -eq "feed_mount") { return 0 }
    if ($p -eq "helical_former") { return 1 }
    if ($p -eq "fit_sleeve") { return 1 } # legacy alias
    if ($p -eq "yagi_mount") { return 0 }
    throw "Unknown part name '$p'. Add 'part_id' to the config."
  }
  return 0
}

$configData["part_id"] = Resolve-PartId -ConfigData $configData
if (-not $PartName) {
  if ($configData.ContainsKey("part")) {
    $PartName = [string]$configData["part"]
  } else {
    throw "No -PartName provided and config missing 'part'."
  }
}

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$outStl = Join-Path $OutDir "$PartName.stl"
$outPng = Join-Path $OutDir "$PartName.png"

$defines = ConvertTo-OpenScadDefines -ConfigData $configData

Write-Info "Config: $Config"
Write-Info "Design: $Design"
Write-Info "PartName: $PartName"
Write-Info "OutDir: $OutDir"

if ($DryRun) {
  Write-Info "DryRun enabled; not invoking OpenSCAD."
  Write-Info "Would run: openscad -o `"$outStl`" `"$MainScad`" $($defines -join ' ')"
  Write-Info "Would run: openscad -o `"$outPng`" `"$MainScad`" --imgsize=1200,900 --viewall $($defines -join ' ')"
  exit 0
}

$openscadExe = Resolve-OpenScadExe -ExplicitPath $OpenScadPath
Write-Info "OpenSCAD: $openscadExe"

Write-Info "Exporting STL -> $outStl"
& $openscadExe @("-o", $outStl, $MainScad) @defines | Out-Host

Write-Info "Rendering PNG -> $outPng"
& $openscadExe @("-o", $outPng, $MainScad, "--imgsize=1200,900", "--viewall") @defines | Out-Host

Write-Info "Done."
