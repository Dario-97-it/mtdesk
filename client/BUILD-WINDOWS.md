# MTDesk — Build dell'eseguibile Windows

Guida per compilare `MTDesk` (fork RustDesk 1.4.9 ribrandizzato) e produrre i due file da
distribuire: `MTDesk-windows-x86_64-install.exe` (installa) e `MTDesk-qs.exe` (assistenza rapida).
Ogni versione qui è un **vincolo di compatibilità** preso dal CI ufficiale: **non aggiornarle**.

> Scorciatoia: esegui gli script `scripts/install-toolchain.ps1` poi `scripts/build-mtdesk.ps1`.
> Sotto trovi cosa fanno, passo per passo, per capire/diagnosticare.

Come si lanciano, da PowerShell, stando nella cartella `client/`:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\install-toolchain.ps1
powershell -ExecutionPolicy Bypass -File scripts\build-mtdesk.ps1 -SkipMsi
```

Tre avvertenze, perché oggi gli script non le dicono da soli:

- **Metti sempre `-SkipMsi`.** Senza, `build-mtdesk.ps1` prova anche a costruire l'installer MSI,
  che oggi non si costruisce e non va distribuito (il perché è al passo 7).
- **La scritta finale «FATTO» non prova niente.** Lo script non controlla se `build.py` è arrivato
  in fondo: guarda soltanto che esista `MTDesk.exe` nella cartella di compilazione, e quel file può
  essere rimasto lì da una build precedente. A fine script controlla tu che i due file da
  distribuire siano stati prodotti **adesso** (i comandi sono al passo 7).
- **Due cose gli script non le fanno**, e vanno fatte a mano: attivare la Modalità sviluppatore di
  Windows, una volta sola (problema n. 4, in fondo), e svuotare la cartella di compilazione quando
  il progetto è stato spostato o l'eseguibile ha cambiato nome (problema n. 7).

## Prerequisiti (versioni ESATTE)

| Componente | Versione | Note |
|---|---|---|
| **Visual Studio 2022** | — | con workload **Desktop development with C++** (MSVC + Windows SDK). Bastano i *Build Tools 2022* |
| **Rust** | **1.75.0** | target `x86_64-pc-windows-msvc` + component `rustfmt`. **NON** 1.78+ (rompe ABI i128/sciter) |
| **Flutter** | **3.24.5** (x64) | motore UFFICIALE dello SDK + patch dropdown + patch generatore VS |
| **LLVM/Clang** | **15.0.6** | per bindgen/scrap. Serve `LIBCLANG_PATH` |
| **vcpkg** | commit `9e593bb18ea69cc5095e012465dcd675a822ed0d` | triplet `x64-windows-static`, overlay `res/vcpkg` |
| **flutter_rust_bridge_codegen** | **1.80.1** | genera il bridge FFI Dart↔Rust |
| **cargo-expand** | **1.0.95** | lo usa il generatore del bridge; va installato in questa versione (problema n. 1) |
| **Python 3** | 3.x | orchestratore `build.py` |
| **NASM** | **2.16.03** | assembler per i codec (aom, libvpx): serve a vcpkg. È la versione fissata nel workflow di GitHub e quella presente sul PC di sviluppo, in `C:\mtdesk-build\nasm`. Attenzione: `install-toolchain.ps1` prova a installarlo con `winget`, senza fissare la versione, e se non ci riesce va avanti lo stesso (vedi sotto la tabella) |
| **NuGet**, **WiX v4** | — | **facoltativi**: servono solo per l'MSI, che oggi non si costruisce (passo 7). Nessuno script li installa |

Gli script mettono Flutter, LLVM e vcpkg in `C:\mtdesk-build` (un percorso senza spazi, scelto
apposta: gli spazi rompono vcpkg, cargo e flutter). La cartella del progetto invece può contenere
spazi: la build funziona anche da `D:\2026\VISUAL STUDIO\MTDESK`.

**Se NASM manca** e vcpkg si ferma mentre costruisce i codec: si installa a mano, come fa il
workflow di GitHub (che non usa `winget` proprio perché quel pacchetto non si installa da solo
senza domande). Scarica
`https://www.nasm.us/pub/nasm/releasebuilds/2.16.03/win64/nasm-2.16.03-win64.zip`, estrai i file
in `C:\mtdesk-build\nasm` e aggiungi quella cartella al PATH dell'utente.

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

(Lo script fa la stessa cosa, ma installa in `C:\mtdesk-build\LLVM`, che non richiede i permessi
di amministratore, e imposta `LIBCLANG_PATH` su `C:\mtdesk-build\LLVM\bin`.)

### 3. Flutter 3.24.5 + patch
```powershell
# scarica ed estrai flutter_windows_3.24.5-stable.zip, aggiungi <flutter>\bin al PATH
flutter --version          # deve dire 3.24.5
flutter config --enable-windows-desktop
flutter precache --windows # crea la cartella engine

# NESSUN motore di terzi: si usa quello dello SDK Flutter.
# Il download del motore compilato da RustDesk (github.com/rustdesk/engine, tag
# mobile "main", senza checksum) e' stato RIMOSSO: era un binario di altri che
# finiva dentro l'eseguibile consegnato ai clienti.
# Verificato il 10/11/2026: con il motore ufficiale la build passa e il programma
# si avvia. LIMITE DA CONOSCERE: questo non dimostra ancora che il rendering video
# in sessione sia identico, perche' upstream quel motore e' modificato per il
# percorso di rendering a texture. Se in una sessione vera il video risultasse
# lento, strappato o nero, e' il primo sospetto: la nota su come reintrodurlo in
# modo controllato sta in scripts/install-toolchain.ps1.

# PATCH dropdown (solo 3.24.5):
Copy-Item .github\patches\flutter_3.24.4_dropdown_menu_enableFilter.diff "<flutter>"
Push-Location "<flutter>"; git apply flutter_3.24.4_dropdown_menu_enableFilter.diff; Pop-Location

# PATCH generatore Visual Studio: la applica install-toolchain.ps1. A mano serve
# solo se Flutter non riconosce la tua Visual Studio: vedi il problema n. 5 in fondo.
```

**A che punto sono le prove sul motore ufficiale (10/11/2026).** Vanno tenute distinte tre cose:

- **Fatto:** la build passa e il programma si avvia. La `flutter_windows.dll` che finisce nella
  cartella compilata è quella dello SDK Flutter (data del file: 13/11/2024).
- **Fatto, ma non riguarda il punto in dubbio:** una sessione vera Ubuntu → Windows, cioè con il
  PC Windows **controllato**, è riuscita (è annotata nel messaggio del commit `84d5df3`). In quel
  verso però Windows cattura il proprio schermo e lo spedisce: il video non lo disegna Flutter.
- **Ancora da fare:** Windows come **visualizzatore**, cioè il PC Windows da cui si guarda e si
  comanda un altro computer. È lì che il motore Flutter disegna il video, ed è il caso di chi fa
  assistenza da Windows. Va provato con l'opzione «Usa rendering texture» (Impostazioni →
  Generale → Altro) sia accesa sia spenta, e l'esito va scritto qui.

### 4. vcpkg (commit pinnato) + dipendenze native
```powershell
git clone https://github.com/microsoft/vcpkg
cd vcpkg; git checkout 9e593bb18ea69cc5095e012465dcd675a822ed0d; .\bootstrap-vcpkg.bat; cd ..
$env:VCPKG_ROOT="<path>\vcpkg"
# da lanciare DENTRO la cartella client/: vcpkg legge client/vcpkg.json
& "$env:VCPKG_ROOT\vcpkg" install --triplet x64-windows-static --host-triplet x64-windows-static --x-install-root="$env:VCPKG_ROOT\installed"
# (usa gli overlay-ports in res/vcpkg: aom, libvpx, libyuv, opus, ffmpeg, mfx-dispatch)
```
`--host-triplet x64-windows-static` **non è facoltativo**: senza, ffmpeg viene costruito nella
variante sbagliata e più avanti la compilazione si ferma (problema n. 3).
`$env:VCPKG_ROOT=...` vale solo per la finestra di PowerShell in cui lo scrivi; lo script invece
salva `VCPKG_ROOT` e `VCPKG_DEFAULT_HOST_TRIPLET` fra le variabili d'ambiente dell'utente, così
restano anche dopo aver chiuso la finestra. A mano si ottiene lo stesso con
`setx VCPKG_ROOT "<path>\vcpkg"`.

### 5. Bridge FFI
```powershell
cargo install cargo-expand --version 1.0.95 --locked
cargo install flutter_rust_bridge_codegen --version 1.80.1 --features "uuid" --locked
```
`--locked` e `cargo-expand 1.0.95` servono entrambi: senza, il generatore non si compila
(problema n. 1).

Il "bridge" sono i file con cui la parte Rust e la parte Dart/Flutter del programma si parlano.
Non stanno nel repository (sono generati, e `.gitignore` li esclude), quindi vanno creati **prima**
di compilare. Attenzione: su Windows **`build.py` non li genera**. Li genera `build-mtdesk.ps1`;
a mano, dalla root `client/`:

```powershell
# 1) i pacchetti Dart: senza, gli strumenti Dart non trovano nulla
cd flutter; flutter pub get; cd ..

# 2) la generazione vera (--llvm-path e' la cartella di LLVM, NON la sua sottocartella bin:
#    C:\mtdesk-build\LLVM se hai usato lo script, C:\Program Files\LLVM se hai seguito il passo 2)
flutter_rust_bridge_codegen --rust-input ./src/flutter_ffi.rs --dart-output ./flutter/lib/generated_bridge.dart --c-output ./flutter/macos/Runner/bridge_generated.h --llvm-path C:\mtdesk-build\LLVM

# 3) la correzione che build.py applica da solo soltanto su Linux
#    (funzione ffi_bindgen_function_refactor): il generatore scrive un tipo sbagliato
$gb = ".\flutter\lib\generated_bridge.dart"
(Get-Content $gb -Raw) -replace 'ffi\.NativeFunction<ffi\.Bool Function\(DartPort','ffi.NativeFunction<ffi.Uint8 Function(DartPort' | Set-Content $gb -NoNewline
```

`flutter pub get` va ripetuto ogni volta che la cache dei pacchetti Dart è vuota (PC appena
preparato, PC formattato). Nota: 9 di quei pacchetti arrivano ancora da repository GitHub di
terzi, 8 dei quali sotto `rustdesk-org`; l'elenco è in `third_party/LEGGIMI.md`.

### 6. Build (dalla root `client/`)
```powershell
# Solo se "cargo" o "flutter" non vengono trovati: build-mtdesk.ps1 li aggiunge da solo al
# PATH della finestra in cui gira; lanciando build.py a mano va fatto in ogni nuova finestra.
$env:Path = "$env:USERPROFILE\.cargo\bin;C:\mtdesk-build\flutter\bin;$env:Path"

python build.py --flutter --hwcodec
```
`build.py` fa quattro cose in fila:

1. compila la libreria dello schermo virtuale (`cargo build --locked --release` dentro
   `libs/virtual_display/dylib`) → `target/release/deps/dylib_virtual_display.dll`;
2. `cargo build --locked --features hwcodec,flutter --lib --release` → `target/release/librustdesk.dll`,
   che contiene il cuore del programma (la parte scritta in Rust);
3. `flutter build windows --release` → la cartella `flutter/build/windows/x64/runner/Release/` con
   `MTDesk.exe`, `librustdesk.dll` e le altre dll;
4. impacchetta quella cartella in un unico file autoestraente e produce i due file da distribuire
   (passo 7).

L'app si chiamerà **MTDesk** (APP_NAME hardcoded).

Da sapere:

- **`--flutter` va messo sempre.** Senza, `build.py` prende la strada della vecchia interfaccia
  "Sciter" (`src/ui/`), che non è mai stata ribrandizzata.
- **`--portable` non serve.** Lo script lo passa ancora
  (`python build.py --portable --flutter --hwcodec`) e `build.py` lo accetta, ma non lo legge da
  nessuna parte: l'impacchettamento parte comunque. Il workflow di GitHub infatti non lo usa.
- **Hai spostato la cartella del progetto, o è cambiato il nome dell'eseguibile?** Prima di
  ricompilare cancella `flutter\build\windows` (problema n. 7).

### 7. I due file da distribuire
Non c'è nessun comando da dare a mano: il passo 6 finisce impacchettando da solo
(`libs/portable/generate.py`, chiamato da `build.py`). Nella cartella `client/` trovi:

| File | Cosa succede quando ci si fa doppio clic |
|---|---|
| `MTDesk-windows-x86_64-install.exe` | compare la **schermata di installazione**: il programma resta sul PC. Serve per l'assistenza che si ripete nel tempo |
| `MTDesk-qs.exe` | **assistenza rapida**: una finestra compatta con logo, ID, password monouso, pulsante «Esci» e stato del collegamento. Non installa, e rifiuta le connessioni in uscita: chi lo apre può farsi assistere, non controllare altri PC |

Sono **lo stesso identico file con due nomi**: `build.py` produce il primo e lo copia nel secondo.
A decidere il comportamento è il **nome del file**, con due controlli scritti nel codice:

- un nome che **finisce** in `install.exe` fa comparire la schermata di installazione
  (`is_setup()` in `src/common.rs`; lo stesso controllo è in `libs/portable/src/main.rs`);
- un nome che **contiene** `-qs.exe`, `_qs.exe` oppure `-qs-` avvia l'assistenza rapida
  (`is_quick_support_exe()`, in `src/core_main.rs` e in `libs/portable/src/main.rs`).

Per questo **non vanno rinominati**: un file chiamato in un altro modo (per esempio
`MTDesk-1.4.9-x86_64.exe`) non installa e non apre la finestra compatta. I nomi inoltre non
contengono il numero di versione di proposito: così i link `/releases/latest/download/<nome>` non
si rompono a ogni rilascio.

**Controllo obbligato a fine build**, da PowerShell nella cartella `client/`:

```powershell
Get-Item .\MTDesk-windows-x86_64-install.exe, .\MTDesk-qs.exe | Format-Table Name, Length, LastWriteTime
Get-FileHash .\MTDesk-windows-x86_64-install.exe, .\MTDesk-qs.exe -Algorithm SHA256 | Format-List Path, Hash
```

Devi vedere: tutti e due i file, con data e ora di **adesso**; la stessa dimensione (nella build
del 10/11/2026: 23.788.032 byte, circa 22,7 MB; il workflow considera incompleto un file sotto i
10 MB); la stessa impronta SHA-256, perché sono lo stesso file. Se uno manca o è vecchio, la build
non è riuscita, qualunque cosa abbia stampato lo script.

**Cosa lasciano sul PC del cliente.** Al primo avvio il file scompatta il programma (96 file,
circa 72 MB) in `%LOCALAPPDATA%\MTDesk` e lo avvia da lì. Quando il programma si chiude quella
cartella **resta**: «non installa» vuol dire nessun servizio e nessuna voce nel menu Start, non
«nessuna traccia sul disco». `MTDesk-qs.exe` inoltre chiede subito i privilegi di amministratore
(la finestra UAC di Windows) e, non essendo firmato, quella finestra riporta un autore sconosciuto.

**Come arrivano nella Release.** Li allega da solo il lavoro 4 («Compila per Windows») di
`../.github/workflows/mtdesk-build.yml`, insieme a un file `.sha256` per ciascuno. Quel lavoro però
**non è ancora mai stato eseguito** su GitHub e nessuna Release è stata pubblicata: fino ad allora
i link `/releases/latest/download/...` rispondono 404.

**File vecchi da non confondere con questi.** Nella radice del progetto e in `client/` sono rimasti
due `MTDesk-1.4.9-x86_64.exe` del 25 agosto 2026 (git non li traccia). Sono la build vecchia:
contengono ancora il vecchio nome interno, si scompattano in `%LOCALAPPDATA%\rustdesk` e hanno un
nome che non attiva né l'installazione né l'assistenza rapida. Non vanno dati a nessuno: vanno
cancellati.

#### MSI: facoltativo, e oggi NON pronto

Prima questa guida lo chiamava «consigliato». Non lo è: l'installer vero è
`MTDesk-windows-x86_64-install.exe`, e l'MSI oggi non si costruisce e, se anche si costruisse,
**non andrebbe dato ai clienti**. I motivi, tutti verificati sul codice:

1. **Dalla cartella attuale del progetto non parte nemmeno.** `res/msi/preprocess.py` legge
   versione e data di compilazione lanciando `MTDesk.exe --version` e `MTDesk.exe --build-date`,
   ma scrive il percorso senza virgolette. Il percorso `D:\2026\VISUAL STUDIO\MTDESK` contiene uno
   spazio: Windows cerca un programma chiamato `D:\2026\VISUAL`, non lo trova, e `preprocess.py` si
   ferma con un errore (riprodotto il 10/11/2026). `build-mtdesk.ps1` non se ne accorge, perché non
   controlla l'esito del comando.
2. **Manca NuGet**, che serve a scaricare i pacchetti WiX 4.0.5 (`res/msi/CustomActions/packages.config`,
   `res/msi/Package/Package.wixproj`). Nessuno script lo installa; se non c'è, `build-mtdesk.ps1`
   salta il passaggio senza dirlo.
3. **Il testo che il cliente dovrebbe accettare non è nostro.** `res/msi/Package/License.rtf` è
   l'informativa sulla privacy di un'altra società (Purslane Tech Pte. Ltd., riferita al sito
   rustdesk.com). `preprocess.py` non la sostituisce: ci rimpiazza dentro «RustDesk» e il nome di
   quella società con «MTDesk», cioè presenta come nostro un testo scritto da altri per altri.
   Serve un testo proprio: **[DA FORNIRE dal titolare: licenza d'uso e informativa di MTDesk]**.
4. **È solo in inglese e non è ribrandizzato.** I testi dell'installer esistono solo in inglese
   (`res/msi/Package/Language/Package.en-us.wxl`) e contengono ancora «RustDesk», «RustDesk
   Service» e frasi segnaposto di un altro programma («LAV Filters»).
5. **Non conosce il nuovo nome del processo di appoggio.** `res/msi/CustomActions/CustomActions.cpp`
   e `res/msi/Package/Components/RustDesk.wxs` cercano ancora `RuntimeBroker_rustdesk.exe`, mentre
   il programma ora usa `RuntimeBroker_mtdesk.exe`.
6. **Sporca il repository.** `preprocess.py` riscrive file tracciati da git (`License.rtf` e gli
   identificativi dentro i file `.wxs`).

Per chi volesse riprendere il lavoro, questi sono i comandi che `build-mtdesk.ps1` tenta quando
**non** gli si passa `-SkipMsi`. Sono riportati per documentazione: **non usarli per produrre
qualcosa da consegnare**.

```powershell
cd res/msi
python preprocess.py --arp -d <cartella Release> --app-name MTDesk --manufacturer "Marketing Tools"
nuget restore msi.sln
msbuild msi.sln -p:Configuration=Release -p:Platform=x64 /p:TargetVersion=Windows10
# output: Package/bin/x64/Release/en-us/Package.msi
# lo script lo copierebbe in client/ come MTDesk-1.4.9-x86_64.msi: il numero di versione
# nel nome e' scritto a mano nello script, non letto da Cargo.toml
```

Decidere se l'MSI fa parte del prodotto spetta al proprietario. Finché la decisione non c'è, la
regola pratica è una sola: `-SkipMsi` sempre.

## Note
- **Icona/nome:** applicati nel sorgente: nome dell'app (`APP_NAME` = MTDesk, in
  `libs/hbb_common/src/config.rs` L72), icone (`res/icon.*`), proprietà del file (`Runner.rc`) e,
  da novembre 2026, nome dell'eseguibile. Due cose però portano ancora un segno del progetto
  d'origine, ed è giusto saperlo: la libreria `librustdesk.dll`, che sta accanto a `MTDesk.exe`
  nella cartella del programma (è uno dei nomi interni lasciati di proposito: vedi
  `REBRAND-CHANGES.md`); e le proprietà dei due file distribuiti, dove il campo `CompanyName` è
  vuoto, perché il pacchetto autoestraente prende i suoi dati da `libs/portable/Cargo.toml` e lì
  quel campo non è dichiarato (dentro, `MTDesk.exe` ce l'ha: «Marketing Tools»).
- **Server:** già hardcoded in `libs/hbb_common/src/config.rs` (host + chiave). Per cambiarlo, edita
  le due righe `RENDEZVOUS_SERVERS` e `RS_PUB_KEY` (L118-119 al commit `0f8c020`; il numero di riga
  si sposta se il file cambia) e ricompila; la stessa modifica va fatta in
  `../server/libs/hbb_common/src/config.rs`,
  perché le due copie di `hbb_common` devono restare uguali. **Attenzione:** l'host compilato,
  `mtdesk.marketingtools.digital`, oggi non esiste ancora in DNS e il centralino su VPS non è mai
  stato messo in opera. Un MTDesk appena compilato quindi si apre, ma non si collega a nessun
  centralino. Per le prove c'è `../deploy/avvia-centralino-locale.ps1` (avvia il centralino su
  questo PC, in rete locale); nei client lo si indica da Impostazioni → Rete → «Server ID/Relay».
- **Firma:** l'exe non è firmato → Windows SmartScreen mostrerà un avviso "editore sconosciuto". Per rimuoverlo serve un certificato Code Signing (~200-400€/anno) — opzionale, non necessario per uso interno/clienti. Per lo stesso motivo la finestra UAC che `MTDesk-qs.exe` apre all'avvio riporta un autore sconosciuto.
- **Exe file:** il programma si chiama `MTDesk.exe` (BINARY_NAME in `flutter/windows/CMakeLists.txt`). Fino a novembre 2026 era `rustdesk.exe`: compariva cosi' in Gestione attivita' e sfuggiva ai `taskkill` che cercano `<nome app>.exe`. I due file da distribuire li produce `build.py` con i nomi giusti, e NON vanno rinominati a mano: e' il nome a decidere se il programma installa o fa assistenza rapida.
  Il nome non è una questione estetica: l'installazione (`install_me()` in
  `src/platform/windows.rs`) copia la cartella del programma così com'è, senza rinominare nulla, e
  poi crea collegamenti, voce di disinstallazione e servizio che puntano a
  `<cartella>\<nome app>.exe`, cioè `C:\Program Files\MTDesk\MTDesk.exe`. Con il file chiamato
  `rustdesk.exe` quel percorso non esisteva. **La correzione è nel codice, ma l'installazione non è
  ancora stata provata su un Windows pulito**: prima di dare `MTDesk-windows-x86_64-install.exe` a
  un cliente va installato su un PC di prova, controllando che esista
  `C:\Program Files\MTDesk\MTDesk.exe`, che il servizio «MTDesk» parta, che i collegamenti
  funzionino e che la disinstallazione tolga tutto.
- **Processo di appoggio:** accanto a `MTDesk.exe` compare `RuntimeBroker_mtdesk.exe`. È una copia
  di un programma di Windows (`C:\Windows\System32\RuntimeBroker.exe`) che MTDesk usa per la
  modalità privacy; il nome è scritto in due punti che devono restare uguali
  (`libs/portable/src/main.rs` e `src/privacy_mode/win_topmost_window.rs`).
- **Residui delle build vecchie:** sui PC dove ha girato una build precedente a novembre 2026 è
  rimasta la cartella `%LOCALAPPDATA%\rustdesk` (circa 72 MB). Non la usa più nessuno: si può
  cancellare a mano.

---

## Problemi reali incontrati durante le build (e chi li gestisce oggi)

Non è vero che «gli script li gestiscono già» tutti, come diceva la prima stesura di questa
guida. Per ognuno è scritto **chi** lo gestisce oggi; il n. 4 e il n. 7 vanno fatti a mano. I
primi sei sono quelli della prima build; il 7 e l'8 sono emersi dopo.

1. **frb codegen non compila** (`failed to parse manifest / crates-io`) → installare con `--locked` + `cargo-expand 1.0.95`.
   *Chi lo gestisce:* `build-mtdesk.ps1`, che installa entrambi in quel modo se non trova già il
   generatore. (`install-toolchain.ps1`, al passo 6, lo installa ancora senza `--locked` e non
   controlla l'esito.)
2. **ffigen: "Couldn't find libclang.dll"** → passare `--llvm-path <LLVM_dir>` al `flutter_rust_bridge_codegen`.
   *Chi lo gestisce:* `build-mtdesk.ps1`, che passa `C:\mtdesk-build\LLVM`.
3. **hwcodec: `libavcodec/avcodec.h` No such file** → vcpkg va lanciato con `--host-triplet x64-windows-static` (ffmpeg è dip. host e senza questo finisce in x64-windows dinamico).
   *Chi lo gestisce:* `install-toolchain.ps1`, che passa l'opzione e salva
   `VCPKG_DEFAULT_HOST_TRIPLET` fra le variabili dell'utente.
4. **flutter build: "Building with plugins requires symlink support"** → abilitare **Developer Mode** di Windows (registry `AllowDevelopmentWithoutDevLicense=1`, richiede admin/UAC una volta).
   *Chi lo gestisce:* **nessuno script.** `install-toolchain.ps1` gira senza permessi di
   amministratore e questa chiave non la tocca. Va fatto a mano, una volta: nelle Impostazioni di
   Windows cerca «Per sviluppatori» e attiva «Modalità sviluppatore»; oppure, da una PowerShell
   aperta come amministratore, gli stessi comandi che usa il workflow di GitHub:
   ```powershell
   $k = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock'
   New-Item -Path $k -Force | Out-Null
   New-ItemProperty -Path $k -Name AllowDevelopmentWithoutDevLicense -Value 1 -PropertyType DWord -Force | Out-Null
   ```
   Per controllare se è già attiva (deve rispondere `0x1`):
   `reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" /v AllowDevelopmentWithoutDevLicense`
5. **CMake: generator "Visual Studio 16 2019" could not find any instance** → con VS 18/2026 installata, Flutter 3.24.5 mappa male; patchare `flutter_tools/.../visual_studio.dart` (16→2019, resto→"Visual Studio 17 2022") e rimuovere `flutter_tools.snapshot`. Richiede **VS 2022 Build Tools con C++** installata.
   *Chi lo gestisce:* `install-toolchain.ps1`, che applica la patch. Sulla presenza di Visual
   Studio con C++ lo script si limita però a un avviso: non si ferma.
6. **packer portable: `pip3` non trovato** → usare `python -m pip install brotli` e lanciare `libs/portable/generate.py`.
   *Chi lo gestisce:* `build.py` stesso, da novembre 2026: non chiama più `pip3` e `python3` (che
   su Windows non esistono) ma l'interprete Python che lo sta eseguendo. Non c'è più niente da
   lanciare a mano.
7. **CMake: "does not match the source used to generate cache"**, oppure un vecchio eseguibile che
   finisce dentro il pacchetto → cancellare la cartella `flutter\build\windows` e ricompilare.
   Succede in due casi: quando la cartella del progetto viene spostata (fino a novembre 2026 era
   sul disco `H:`, ora è `D:\2026\VISUAL STUDIO\MTDESK`), perché lì dentro sono memorizzati i
   percorsi completi; e quando cambia il nome dell'eseguibile, perché il file con il nome vecchio
   può restare nella cartella `Release`, e l'ultima fase di `build.py` (l'impacchettamento)
   mette nel pacchetto tutto quello che trova lì dentro.
   *Chi lo gestisce:* **nessuno script.** Va fatto a mano.
8. **Gli strumenti Dart non trovano i pacchetti** (errori "Target of URI doesn't exist") →
   eseguire `flutter pub get` dentro `flutter/`. Succede su un PC appena preparato o formattato,
   quando la cache dei pacchetti è vuota.
   *Chi lo gestisce:* `build-mtdesk.ps1`, che lo esegue all'inizio, prima di generare il bridge.
   Lanciando `build.py` a mano va fatto prima (passo 5).
