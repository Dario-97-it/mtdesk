<#
  MTDesk - Installa la toolchain di build Windows (versioni ESATTE dal CI RustDesk 1.4.9).
  Best-effort, ri-eseguibile (salta i passi gia' completati), SENZA admin.
  Uso:   powershell -ExecutionPolicy Bypass -File scripts\install-toolchain.ps1
  Prereq: Visual Studio 2022 con workload "Desktop development with C++".
#>
[CmdletBinding()]
param(
  [string]$ToolsDir = "C:\mtdesk-build"   # niente spazi: evita rotture di vcpkg/cargo/flutter
)
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ProgressPreference = "SilentlyContinue"   # velocizza Invoke-WebRequest su PS 5.1
$ClientRoot = Split-Path $PSScriptRoot -Parent
$FlutterDir = Join-Path $ToolsDir "flutter"
$VcpkgDir   = Join-Path $ToolsDir "vcpkg"
$LlvmDir    = Join-Path $ToolsDir "LLVM"
$FLUTTER_VERSION = "3.24.5"
$RUST_VERSION    = "1.75.0"
$LLVM_VERSION    = "15.0.6"
$VCPKG_COMMIT    = "9e593bb18ea69cc5095e012465dcd675a822ed0d"
$FRB_VERSION     = "1.80.1"

function Step($m){ Write-Host "`n==== $m ====" -ForegroundColor Cyan }
New-Item -ItemType Directory -Force -Path $ToolsDir | Out-Null

# --- 0. Visual Studio C++ presente? ---
Step "Controllo Visual Studio C++"
$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
if (Test-Path $vswhere) {
  $vc = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
  if ($vc) { Write-Host "OK: $vc" } else { Write-Warning "MSVC C++ non trovato: installa il workload 'Desktop development with C++' in VS2022." }
} else { Write-Warning "vswhere non trovato: assicurati che VS2022 + C++ sia installato." }

# --- 1. Rust 1.75 ---
Step "Rust $RUST_VERSION"
$env:Path = "$env:USERPROFILE\.cargo\bin;$env:Path"
if (-not (Get-Command rustup -ErrorAction SilentlyContinue)) {
  $ri = Join-Path $env:TEMP "rustup-init.exe"
  Invoke-WebRequest -UseBasicParsing "https://win.rustup.rs/x86_64" -OutFile $ri
  & $ri -y --default-toolchain "$RUST_VERSION-x86_64-pc-windows-msvc" --profile minimal
}
rustup toolchain install "$RUST_VERSION-x86_64-pc-windows-msvc"
rustup default "$RUST_VERSION-x86_64-pc-windows-msvc"
rustup component add rustfmt
rustc --version

# --- 2. LLVM 15.0.6 (in cartella utente, senza admin) ---
Step "LLVM $LLVM_VERSION"
if (-not (Test-Path (Join-Path $LlvmDir "bin\libclang.dll"))) {
  $llvmExe = Join-Path $env:TEMP "LLVM-$LLVM_VERSION-win64.exe"
  Invoke-WebRequest -UseBasicParsing "https://github.com/llvm/llvm-project/releases/download/llvmorg-$LLVM_VERSION/LLVM-$LLVM_VERSION-win64.exe" -OutFile $llvmExe
  # NSIS: /S silenzioso, /D=dir (ultimo arg, senza virgolette, path senza spazi)
  Start-Process $llvmExe -ArgumentList "/S /D=$LlvmDir" -Wait
}
[Environment]::SetEnvironmentVariable("LIBCLANG_PATH", (Join-Path $LlvmDir "bin"), "User")
$env:LIBCLANG_PATH = Join-Path $LlvmDir "bin"
Write-Host "LIBCLANG_PATH = $env:LIBCLANG_PATH"

# --- 3. NASM ---
Step "NASM"
if (-not (Get-Command nasm -ErrorAction SilentlyContinue)) {
  try { winget install --id NASM.NASM -e --accept-source-agreements --accept-package-agreements --scope user } catch { Write-Warning "NASM: installa a mano se vcpkg fallisce sui codec ($_)" }
}

# --- 4. Flutter 3.24.5 + engine custom + patch ---
Step "Flutter $FLUTTER_VERSION"
if (-not (Test-Path (Join-Path $FlutterDir "bin\flutter.bat"))) {
  $fz = Join-Path $env:TEMP "flutter_$FLUTTER_VERSION.zip"
  Invoke-WebRequest -UseBasicParsing "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_$FLUTTER_VERSION-stable.zip" -OutFile $fz
  Expand-Archive $fz -DestinationPath $ToolsDir -Force   # crea $ToolsDir\flutter
}
$env:Path = "$FlutterDir\bin;$env:Path"
& "$FlutterDir\bin\flutter.bat" --version
& "$FlutterDir\bin\flutter.bat" config --enable-windows-desktop --no-analytics
& "$FlutterDir\bin\flutter.bat" precache --windows

Step "Motore Flutter: si usa quello UFFICIALE"
# ---------------------------------------------------------------------
#  MTDesk: il download del motore Flutter compilato da RustDesk E' STATO
#  TOLTO. Scaricava
#      github.com/rustdesk/engine/releases/download/main/windows-x64-release.zip
#  cioe' un BINARIO di terzi, da un tag mobile ("main", che cambia sotto i
#  piedi), senza alcun checksum, e lo copiava dentro la cache di Flutter.
#  Quel binario finiva dentro l'eseguibile consegnato ai clienti: era la
#  dipendenza da terzi piu' scomoda di tutto il progetto.
#
#  VERIFICATO il 10/11/2026: con il motore ufficiale dello SDK Flutter
#  3.24.5 la compilazione passa e il programma si avvia correttamente
#  (flutter_windows.dll datata 13/11/2024, quella dello SDK).
#
#  ATTENZIONE, un limite da conoscere: questo dimostra che la BUILD non ha
#  bisogno del loro motore, NON che il rendering video durante una sessione
#  sia identico. Upstream quel motore e' modificato per il percorso di
#  rendering a texture (flutter_gpu_texture_renderer). Se in una sessione
#  reale il video risultasse lento, strappato o nero, e' il primo sospetto.
#
#  COME TORNARE INDIETRO, se mai servisse: scaricare quello zip UNA volta,
#  calcolarne lo SHA-256, metterne copia in client/third_party/flutter-engine/
#  e farla copiare da qui con confronto di hash obbligatorio. Non
#  reintrodurre il download diretto.
# ---------------------------------------------------------------------
Write-Host "Nessun motore di terzi da scaricare: si usa quello dello SDK Flutter $FLUTTER_VERSION."

Step "Patch dropdown Flutter 3.24.5"
$diff = Join-Path $ClientRoot ".github\patches\flutter_3.24.4_dropdown_menu_enableFilter.diff"
Copy-Item $diff $FlutterDir -Force
Push-Location $FlutterDir
try { git apply "flutter_3.24.4_dropdown_menu_enableFilter.diff"; Write-Host "Patch applicata." }
catch { Write-Warning "Patch gia' applicata o non necessaria: $_" }
Pop-Location

Step "Patch Flutter: VS generator per VS>17 (usa 'Visual Studio 17 2022')"
# Flutter 3.24.5 mappa qualsiasi VS major != 17 su 'Visual Studio 16 2019' e fallisce
# se e' installata solo una VS piu' nuova (es. VS18/2026). Forziamo: 16->2019, resto->17 2022.
$vsDart = Join-Path $FlutterDir "packages\flutter_tools\lib\src\windows\visual_studio.dart"
$vsc = Get-Content $vsDart -Raw
if ($vsc -match "16 => 'Visual Studio 16 2019',") {
  Write-Host "Patch VS generator gia' presente."
} else {
  $vsc2 = $vsc -replace "(?m)^\s*_  => 'Visual Studio 16 2019',", "      16 => 'Visual Studio 16 2019',`r`n      _  => 'Visual Studio 17 2022',"
  Set-Content $vsDart $vsc2 -NoNewline
  Remove-Item (Join-Path $FlutterDir "bin\cache\flutter_tools.snapshot") -Force -ErrorAction SilentlyContinue
  Remove-Item (Join-Path $FlutterDir "bin\cache\flutter_tools.stamp") -Force -ErrorAction SilentlyContinue
  Write-Host "Patch VS generator applicata."
}

# --- 5. vcpkg (commit pinnato) + dipendenze ---
Step "vcpkg @ $VCPKG_COMMIT"
if (-not (Test-Path (Join-Path $VcpkgDir "vcpkg.exe"))) {
  if (-not (Test-Path $VcpkgDir)) { git clone https://github.com/microsoft/vcpkg $VcpkgDir }
  Push-Location $VcpkgDir; git fetch --all; git checkout $VCPKG_COMMIT; & .\bootstrap-vcpkg.bat; Pop-Location
}
[Environment]::SetEnvironmentVariable("VCPKG_ROOT", $VcpkgDir, "User")
$env:VCPKG_ROOT = $VcpkgDir
# IMPORTANTE (come il CI): host triplet static, altrimenti ffmpeg (dep host) finisce
# in x64-windows dinamico e hwcodec non trova libavcodec/avcodec.h
[Environment]::SetEnvironmentVariable("VCPKG_DEFAULT_HOST_TRIPLET", "x64-windows-static", "User")
$env:VCPKG_DEFAULT_HOST_TRIPLET = "x64-windows-static"
Step "vcpkg install (x64-windows-static, host static) - PUO' RICHIEDERE 30-90 MIN"
Push-Location $ClientRoot
& "$VcpkgDir\vcpkg.exe" install --triplet x64-windows-static --host-triplet x64-windows-static --x-install-root="$VcpkgDir\installed"
if ($LASTEXITCODE -ne 0) { Write-Warning "vcpkg install ha restituito $LASTEXITCODE - controlla i log sopra." }
Pop-Location

# --- 6. flutter_rust_bridge_codegen ---
Step "flutter_rust_bridge_codegen $FRB_VERSION"
if (-not (Get-Command flutter_rust_bridge_codegen -ErrorAction SilentlyContinue)) {
  cargo install flutter_rust_bridge_codegen --version $FRB_VERSION --features uuid
}

# --- 7. Python deps ---
Step "Python deps"
try { python -m pip install --upgrade pip requests argparse brotli } catch { Write-Warning "pip: $_" }
$req = Join-Path $ClientRoot "libs\portable\requirements.txt"
if (Test-Path $req) { try { python -m pip install -r $req } catch { Write-Warning "pip req: $_" } }

Write-Host "`n=========================================================" -ForegroundColor Green
Write-Host " TOOLCHAIN PRONTA in $ToolsDir" -ForegroundColor Green
Write-Host " Poi:  powershell -ExecutionPolicy Bypass -File scripts\build-mtdesk.ps1" -ForegroundColor Green
Write-Host "=========================================================" -ForegroundColor Green
