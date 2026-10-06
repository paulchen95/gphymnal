# Packs the Microsoft Store package (.msix) around the app :desktop:createDistributable built.
# Runs on Windows with the Windows SDK (GitHub's Windows runners have it):
#
#   ./gradlew :desktop:createDistributable -Phymnal.windowsBuild=N
#   pwsh desktop/msix/package.ps1 -Build N
#
# The version is major.minor from gradle.properties, then the Windows build number, then 0: the
# Store keeps the fourth number for itself. It matches the MSI's, so a build is the same 5.4.N
# everywhere. Leaves build/compose/binaries/main/msix/A2N-Hymnal-<version>.msix, unsigned: the
# Store signs it.
param([Parameter(Mandatory)][int]$Build)
$ErrorActionPreference = 'Stop'

$msix = $PSScriptRoot
$desktop = Split-Path $msix
$app = Join-Path $desktop 'build/compose/binaries/main/app/A2N Hymnal'
$out = Join-Path $desktop 'build/compose/binaries/main/msix'
if (-not (Test-Path (Join-Path $app 'A2N Hymnal.exe'))) { throw "No app at $app. Run :desktop:createDistributable first." }

$versionName = (Get-Content (Join-Path $desktop '../gradle.properties') | Where-Object { $_ -match '^hymnal\.versionName=' }) -replace '^.*=', ''
$major, $minor = $versionName.Split('.')[0, 1]
$version = "$major.$minor.$Build.0"

# The newest Windows SDK's tools.
$sdk = Get-ChildItem 'C:\Program Files (x86)\Windows Kits\10\bin\10.*\x64' -Directory |
  Sort-Object { [version]$_.Parent.Name } | Select-Object -Last 1
if (-not $sdk) { throw 'No Windows SDK found.' }
$makeappx = Join-Path $sdk.FullName 'makeappx.exe'
$makepri = Join-Path $sdk.FullName 'makepri.exe'

# The package's root: the app, its manifest and icons.
$staging = Join-Path $out 'package'
if (Test-Path $staging) { Remove-Item $staging -Recurse -Force }
New-Item $staging -ItemType Directory -Force | Out-Null
Copy-Item "$app\*" $staging -Recurse
Copy-Item (Join-Path $msix 'Assets') $staging -Recurse
(Get-Content (Join-Path $msix 'AppxManifest.xml') -Raw).Replace('@VERSION@', $version) |
  Set-Content (Join-Path $staging 'AppxManifest.xml') -Encoding utf8

# resources.pri lets Windows pick each icon's scale and size. Index only the manifest and icons,
# not the hymns and recordings.
$pri = Join-Path $out 'pri'
if (Test-Path $pri) { Remove-Item $pri -Recurse -Force }
New-Item $pri -ItemType Directory -Force | Out-Null
Copy-Item (Join-Path $staging 'AppxManifest.xml') $pri
Copy-Item (Join-Path $msix 'Assets') $pri -Recurse
& $makepri createconfig /cf (Join-Path $pri 'priconfig.xml') /dq en-US /pv 10.0.0 /o
if ($LASTEXITCODE) { throw 'makepri createconfig failed' }
# Keep every scale in the one resources.pri. The default config splits scales into separate
# .pri files meant for bundles, so a single package would show only its 100% icons.
$config = [xml](Get-Content (Join-Path $pri 'priconfig.xml') -Raw)
$config.SelectNodes('//packaging') | ForEach-Object { [void]$_.ParentNode.RemoveChild($_) }
$config.Save((Join-Path $pri 'priconfig.xml'))
& $makepri new /pr $pri /cf (Join-Path $pri 'priconfig.xml') /mn (Join-Path $pri 'AppxManifest.xml') /of (Join-Path $staging 'resources.pri') /o
if ($LASTEXITCODE) { throw 'makepri new failed' }

$package = Join-Path $out "A2N-Hymnal-$version.msix"
& $makeappx pack /d $staging /p $package /o
if ($LASTEXITCODE) { throw 'makeappx pack failed' }
Write-Host "Made $package"
