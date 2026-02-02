param(
  [Parameter(Mandatory = $true)]
  [string] $Config,

  [Parameter(Mandatory = $false)]
  [string] $PartName,

  [Parameter(Mandatory = $false)]
  [string] $OutDir = "cad/out",

  [Parameter(Mandatory = $false)]
  [string] $MainScad = "cad/src/main.scad",

  [switch] $DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Info([string] $Message) { Write-Host "[scad] $Message" }

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
Write-Info "PartName: $PartName"
Write-Info "OutDir: $OutDir"

if ($DryRun) {
  Write-Info "DryRun enabled; not invoking OpenSCAD."
  Write-Info "Would run: openscad -o `"$outStl`" `"$MainScad`" $($defines -join ' ')"
  Write-Info "Would run: openscad -o `"$outPng`" `"$MainScad`" --imgsize=1200,900 --viewall $($defines -join ' ')"
  exit 0
}

if (-not (Get-Command openscad -ErrorAction SilentlyContinue)) {
  throw "OpenSCAD CLI not found on PATH. Install OpenSCAD and ensure 'openscad' is available."
}

Write-Info "Exporting STL -> $outStl"
& openscad @("-o", $outStl, $MainScad) @defines | Out-Host

Write-Info "Rendering PNG -> $outPng"
& openscad @("-o", $outPng, $MainScad, "--imgsize=1200,900", "--viewall") @defines | Out-Host

Write-Info "Done."
