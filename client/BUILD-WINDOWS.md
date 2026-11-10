# MTDesk — Build dell'eseguibile Windows

Guida per compilare `MTDesk` (fork RustDesk 1.4.9 ribrandizzato) e produrre l'installer.
Ogni versione qui è un **vincolo di compatibilità** preso dal CI ufficiale: **non aggiornarle**.

> Scorciatoia: esegui gli script `scripts/install-toolchain.ps1` poi `scripts/build-mtdesk.ps1`.
> Sotto trovi cosa fanno, passo per passo, per capire/diagnosticare.

## Prerequisiti (versioni ESATTE)

| Componente | Versione | Note |
|---|---|---|
| **Visual Studio 2022** | — | con workload **Desktop development with C++** (MSVC + Windows SDK) |
| **Rust** | **1.75.0** | target `x86_64-pc-windows-msvc` + component `rustfmt`. **NON** 1.78+ (rompe ABI i128/sciter) |
| **Flutter** | **3.24.5** (x64) | + **engine custom RustDesk** (vedi sotto) + patch dropdown |
| **LLVM/Clang** | **15.0.6** | per bindgen/scrap. Serve `LIBCLANG_PATH` |
| **vcpkg** | commit `9e593bb18ea69cc5095e012465dcd675a822ed0d` | triplet `x64-windows-static`, overlay `res/vcpkg` |
| **flutter_rust_bridge_codegen** | **1.80.1** | genera il bridge FFI Dart↔Rust |
| **Python 3** | 3.x | orchestratore `build.py` |
| **NASM**, **NuGet**, **WiX v4** | — | NASM per codec; NuGet+WiX per l'MSI |

## Passi

### 1. Rust 1.75
```powershell
rustup toolchain install 1.75.0-x86_64-pc-windows-msvc
rustup default 1.75.0-x86_64-pc-windows-msvc
rustup component add rustfmt
```

### 2. LLVM 15.0.6
Installa da https://github.com/llvm/llvm-project/releases/tag/llvmorg-15.0.6 (`LLVM-15.0.6-win64.exe`).
Poi: `setx LIBCLANG_PATH "C:\Program Files\LLVM\bin"`

### 3. Flutter 3.24.5 + engine custom + patch
```powershell
# scarica ed estrai flutter_windows_3.24.5-stable.zip, aggiungi <flutter>\bin al PATH
flutter --version          # deve dire 3.24.5
flutter config --enable-windows-desktop
flutter precache --windows # crea la cartella engine

# ENGINE CUSTOM RustDesk (obbligatorio per il rendering video):
Invoke-WebRequest https://github.com/rustdesk/engine/releases/download/main/windows-x64-release.zip -OutFile eng.zip
Expand-Archive eng.zip -DestinationPath eng
Copy-Item eng\* "<flutter>\bin\cache\artifacts\engine\windows-x64-release\" -Force

# PATCH dropdown (solo 3.24.5):
Copy-Item .github\patches\flutter_3.24.4_dropdown_menu_enableFilter.diff "<flutter>"
cd "<flutter>"; git apply flutter_3.24.4_dropdown_menu_enableFilter.diff; cd -
```

### 4. vcpkg (commit pinnato) + dipendenze native
```powershell
git clone https://github.com/microsoft/vcpkg
cd vcpkg; git checkout 9e593bb18ea69cc5095e012465dcd675a822ed0d; .\bootstrap-vcpkg.bat; cd ..
$env:VCPKG_ROOT="<path>\vcpkg"
& "$env:VCPKG_ROOT\vcpkg" install --triplet x64-windows-static --x-install-root="$env:VCPKG_ROOT\installed"
# (usa gli overlay-ports in res/vcpkg: aom, libvpx, libyuv, opus, ffmpeg, mfx-dispatch)
```

### 5. Bridge FFI
```powershell
cargo install flutter_rust_bridge_codegen --version 1.80.1 --features "uuid"
# la generazione vera è invocata da build.py / flutter build
```

### 6. Build (dalla root `client/`)
```powershell
python build.py --portable --flutter --hwcodec
```
Internamente: `cargo build --release --features flutter,hwcodec` → `librustdesk.dll`;
`flutter build windows --release` → `flutter/build/windows/x64/runner/Release/` con l'exe;
copia dei driver/dll. L'app si chiamerà **MTDesk** (APP_NAME hardcoded).

### 7. Installer
- **Portable (self-extracting):**
  ```powershell
  (Get-Content res/manifest.xml) -replace '.*dpiAware.*','' | Set-Content res/manifest.xml
  cd libs/portable; pip install -r requirements.txt
  python generate.py -f ../../flutter/build/windows/x64/runner/Release/ -o . -e ../../<...>/rustdesk.exe
  ```
- **MSI (consigliato, applica il brand):**
  ```powershell
  cd res/msi
  python preprocess.py --arp -d <cartella Release> --app-name MTDesk --manufacturer "Marketing Tools"
  nuget restore msi.sln
  msbuild msi.sln -p:Configuration=Release -p:Platform=x64 /p:TargetVersion=Windows10
  # output: Package/bin/x64/Release/en-us/Package.msi  ->  rinomina MTDesk-1.4.9-x86_64.msi
  ```

## Note
- **Icona/nome:** già applicati nel sorgente (APP_NAME=MTDesk, res/icon.*, Runner.rc). Non serve altro.
- **Server:** già hardcoded in `libs/hbb_common/src/config.rs` (host + chiave). Per cambiarlo, edita L117-118 e ricompila.
- **Firma:** l'exe non è firmato → Windows SmartScreen mostrerà un avviso "editore sconosciuto". Per rimuoverlo serve un certificato Code Signing (~200-400€/anno) — opzionale, non necessario per uso interno/clienti.
- **Exe file:** internamente resta `rustdesk.exe` (BINARY_NAME non rinominato per sicurezza build); l'utente vede "MTDesk" ovunque. Puoi rinominare il file finale a mano se vuoi.

---

## Problemi reali risolti durante la prima build (già corretti negli script)

Se ricompili da zero, gli script li gestiscono già. Documentati qui per riferimento:

1. **frb codegen non compila** (`failed to parse manifest / crates-io`) → installare con `--locked` + `cargo-expand 1.0.95`.
2. **ffigen: "Couldn't find libclang.dll"** → passare `--llvm-path <LLVM_dir>` al `flutter_rust_bridge_codegen`.
3. **hwcodec: `libavcodec/avcodec.h` No such file** → vcpkg va lanciato con `--host-triplet x64-windows-static` (ffmpeg è dip. host e senza questo finisce in x64-windows dinamico).
4. **flutter build: "Building with plugins requires symlink support"** → abilitare **Developer Mode** di Windows (registry `AllowDevelopmentWithoutDevLicense=1`, richiede admin/UAC una volta).
5. **CMake: generator "Visual Studio 16 2019" could not find any instance** → con VS 18/2026 installata, Flutter 3.24.5 mappa male; patchare `flutter_tools/.../visual_studio.dart` (16→2019, resto→"Visual Studio 17 2022") e rimuovere `flutter_tools.snapshot`. Richiede **VS 2022 Build Tools con C++** installata.
6. **packer portable: `pip3` non trovato** → usare `python -m pip install brotli` e lanciare `libs/portable/generate.py`.
