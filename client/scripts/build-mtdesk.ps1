<#
  MTDesk - Genera il bridge FFI, compila l'exe Windows e crea l'installer MSI brandizzato.
  Esegui DOPO install-toolchain.ps1.
  Uso:  powershell -ExecutionPolicy Bypass -File scripts\build-mtdesk.ps1
#>
[CmdletBinding()]
param(
  [string]$ToolsDir = "C:\mtdesk-build",
  [switch]$SkipMsi
)
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ClientRoot = Split-Path $PSScriptRoot -Parent
$FlutterDir = Join-Path $ToolsDir "flutter"
$VcpkgDir   = Join-Path $ToolsDir "vcpkg"
$FLUTTER_RUST_BRIDGE_VERSION = "1.80.1"
$CARGO_EXPAND_VERSION        = "1.0.95"
function Step($m){ Write-Host "`n==== $m ====" -ForegroundColor Cyan }

# Ambiente
$env:Path = "$env:USERPROFILE\.cargo\bin;$FlutterDir\bin;$env:Path"
if (-not $env:VCPKG_ROOT)     { $env:VCPKG_ROOT = $VcpkgDir }
if (-not $env:LIBCLANG_PATH)  { $env:LIBCLANG_PATH = Join-Path $ToolsDir "LLVM\bin" }
$FLUTTER = Join-Path $FlutterDir "bin\flutter.bat"
Set-Location $ClientRoot

Step "Verifica strumenti"
rustc --version
& $FLUTTER --version
python --version
Write-Host "VCPKG_ROOT=$env:VCPKG_ROOT   LIBCLANG_PATH=$env:LIBCLANG_PATH"

Step "Dipendenze Dart (flutter pub get)"
Push-Location (Join-Path $ClientRoot "flutter")
& $FLUTTER pub get
Pop-Location

# ---- BRIDGE FFI (obbligatorio: il flow Windows di build.py NON lo genera) ----
Step "Bridge FFI: install codegen (frb $FLUTTER_RUST_BRIDGE_VERSION + cargo-expand $CARGO_EXPAND_VERSION, --locked)"
if (-not (Get-Command flutter_rust_bridge_codegen -ErrorAction SilentlyContinue)) {
  cargo install cargo-expand --version $CARGO_EXPAND_VERSION --locked
  cargo install flutter_rust_bridge_codegen --version $FLUTTER_RUST_BRIDGE_VERSION --features uuid --locked
}
Step "Bridge FFI: generazione (rust-input flutter_ffi.rs)"
& flutter_rust_bridge_codegen --rust-input ./src/flutter_ffi.rs --dart-output ./flutter/lib/generated_bridge.dart --c-output ./flutter/macos/Runner/bridge_generated.h --llvm-path (Join-Path $ToolsDir "LLVM")
if (-not (Test-Path (Join-Path $ClientRoot "flutter\lib\generated_bridge.dart"))) {
  Write-Error "Bridge NON generato (flutter/lib/generated_bridge.dart mancante). Controlla i log del codegen sopra."
}
Copy-Item ".\flutter\macos\Runner\bridge_generated.h" ".\flutter\ios\Runner\bridge_generated.h" -Force -ErrorAction SilentlyContinue
# refactor ffigen (equivalente a build.py ffi_bindgen_function_refactor)
$gb = Join-Path $ClientRoot "flutter\lib\generated_bridge.dart"
(Get-Content $gb -Raw) -replace 'ffi\.NativeFunction<ffi\.Bool Function\(DartPort','ffi.NativeFunction<ffi.Uint8 Function(DartPort' | Set-Content $gb -NoNewline
Write-Host "Bridge generato: $gb"

Step "BUILD (cargo + flutter) - PUO' RICHIEDERE 30-60 MIN"
python build.py --portable --flutter --hwcodec

$ReleaseDir = Join-Path $ClientRoot "flutter\build\windows\x64\runner\Release"
if (-not (Test-Path (Join-Path $ReleaseDir "mtdesk.exe"))) {
  Write-Error "Build non riuscita: mtdesk.exe non trovato in $ReleaseDir. Controlla i log sopra."
}
Write-Host "OK: eseguibile in $ReleaseDir" -ForegroundColor Green

if (-not $SkipMsi) {
  Step "Installer MSI (WiX v4) - brand MTDesk"
  $msiDir = Join-Path $ClientRoot "res\msi"
  Push-Location $msiDir
  try {
    python preprocess.py --arp -d $ReleaseDir --app-name MTDesk --manufacturer "Marketing Tools"
    if (Get-Command nuget -ErrorAction SilentlyContinue) { nuget restore msi.sln }
    $msbuild = & "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe" -latest -requires Microsoft.Component.MSBuild -find MSBuild\**\Bin\MSBuild.exe | Select-Object -First 1
    if ($msbuild) {
      & $msbuild msi.sln -p:Configuration=Release -p:Platform=x64 /p:TargetVersion=Windows10
      $msi = Get-ChildItem "Package\bin\x64\Release\en-us\Package.msi" -ErrorAction SilentlyContinue
      if ($msi) {
        $out = Join-Path $ClientRoot "MTDesk-1.4.9-x86_64.msi"
        Copy-Item $msi.FullName $out -Force
        Write-Host "`nINSTALLER PRONTO: $out" -ForegroundColor Green
      }
    } else { Write-Warning "MSBuild non trovato: apri res\msi\msi.sln in VS2022 e compila in Release x64." }
  } catch { Write-Warning "MSI fallito ($_). L'exe/cartella in $ReleaseDir e' comunque utilizzabile." }
  Pop-Location
}

Write-Host "`n=========================================================" -ForegroundColor Green
Write-Host " FATTO. App: MTDesk" -ForegroundColor Green
Write-Host " - Eseguibile/cartella: $ReleaseDir" -ForegroundColor Green
Write-Host " - Installer MSI (se creato): MTDesk-1.4.9-x86_64.msi" -ForegroundColor Green
Write-Host "=========================================================" -ForegroundColor Green
