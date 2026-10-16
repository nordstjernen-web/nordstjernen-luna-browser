param(
    [string]$Url = "about:start",
    [string]$MingwBin = "",
    [string]$Exe = ""
)

if (-not $MingwBin) {
    $MingwBin = "C:\msys64\ucrt64\bin"
    if (-not (Test-Path -LiteralPath "$MingwBin\libgtk-4-1.dll") -and
        (Test-Path -LiteralPath "C:\msys64\mingw64\bin\libgtk-4-1.dll")) {
        $MingwBin = "C:\msys64\mingw64\bin"
    }
}

if (-not $Exe) {
    $root = Resolve-Path (Join-Path $PSScriptRoot "..")
    $Exe = Join-Path $root "builddir\src\gtk\northstar.exe"
}

if (-not (Test-Path -LiteralPath $Exe)) {
    throw "Browser binary not found: $Exe"
}

if (Test-Path -LiteralPath $MingwBin) {
    $env:PATH = "$MingwBin;$env:PATH"
}

Start-Process -FilePath $Exe -WorkingDirectory (Split-Path $Exe) -ArgumentList @($Url)
