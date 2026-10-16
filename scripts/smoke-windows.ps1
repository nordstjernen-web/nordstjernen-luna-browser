param(
    [string]$Url = "about:start",
    [int]$Seconds = 5,
    [string]$MingwBin = "",
    [string]$Exe = ""
)

$ErrorActionPreference = "Stop"

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

if (-not (Test-Path -LiteralPath $MingwBin)) {
    throw "MSYS2 bin directory not found: $MingwBin"
}

Add-Type -TypeDefinition @"
using System.Runtime.InteropServices;
public static class NsWin32ErrorMode {
    [DllImport("kernel32.dll")]
    public static extern uint SetErrorMode(uint uMode);
}
"@

[NsWin32ErrorMode]::SetErrorMode(0x8003) | Out-Null
$env:PATH = "$MingwBin;$env:PATH"

$process = Start-Process -FilePath $Exe -ArgumentList @($Url) -PassThru -WindowStyle Hidden
try {
    Start-Sleep -Seconds $Seconds
    if (Get-Process -Id $process.Id -ErrorAction SilentlyContinue) {
        Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
        "smoke-launch-ok"
    } else {
        throw "Browser exited before the smoke interval elapsed"
    }
} finally {
    $leftover = Get-Process -Id $process.Id -ErrorAction SilentlyContinue
    if ($leftover) {
        Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
    }
}
