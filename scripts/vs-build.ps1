param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Build", "Rebuild", "Clean")]
    [string]$Action,
    [string]$BuildDir = "builddir",
    [string]$BuildType = ""
)

$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$msysRoot = "C:\msys64"
$bash = Join-Path $msysRoot "usr\bin\bash.exe"
$cygpath = Join-Path $msysRoot "usr\bin\cygpath.exe"

if (-not (Test-Path -LiteralPath $bash) -or
    -not (Test-Path -LiteralPath $cygpath)) {
    throw "MSYS2 was not found at $msysRoot. Install it there, or update scripts\vs-build.ps1."
}

$unixRepo = (& $cygpath -u $repo).Trim()
if ($LASTEXITCODE -ne 0 -or -not $unixRepo) {
    throw "Could not convert the repository path for MSYS2: $repo"
}

function Invoke-Msys([string]$Command) {
    & $bash -lc $Command
    if ($LASTEXITCODE -ne 0) {
        throw "MSYS2 command failed with exit code $LASTEXITCODE."
    }
}

function Quote-Sh([string]$Value) {
    "'" + $Value.Replace("'", "'\''") + "'"
}

$quotedRepo = Quote-Sh $unixRepo
$quotedBuildDir = Quote-Sh $BuildDir
$setupArgs = ""
if ($BuildType) {
    $setupArgs = Quote-Sh "-Dbuildtype=$BuildType -Db_lto=false"
}
$build = "cd $quotedRepo && BUILDDIR=$quotedBuildDir NS_MESON_SETUP_ARGS=$setupArgs bash scripts/_msys_build.sh"
$clean = "cd $quotedRepo && if [ -f $quotedBuildDir/build.ninja ]; then ninja -C $quotedBuildDir -t clean; fi"

if ($Action -ne "Clean") {
    Get-Process -Name northstar -ErrorAction SilentlyContinue | Stop-Process -Force
}

switch ($Action) {
    "Build"   { Invoke-Msys $build }
    "Clean"   { Invoke-Msys $clean }
    "Rebuild" {
        Invoke-Msys $clean
        Invoke-Msys $build
    }
}
