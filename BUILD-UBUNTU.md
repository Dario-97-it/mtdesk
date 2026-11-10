# MTDesk — Build del pacchetto Ubuntu (.deb)

Guida per compilare **a mano** `MTDesk` (fork RustDesk 1.4.9 ribrandizzato) su Ubuntu e
produrre `mtdesk-ubuntu-amd64.deb`.
È la gemella di [`client/BUILD-WINDOWS.md`](client/BUILD-WINDOWS.md).
Ogni versione qui è un **vincolo di compatibilità** preso dal CI ufficiale di RustDesk:
**non aggiornarle**.

> **Nella maggior parte dei casi questa guida NON ti serve.**
> Il `.deb` lo compila da solo GitHub, gratis, con
> [`.github/workflows/mtdesk-build.yml`](.github/workflows/mtdesk-build.yml):
> vai su **Actions → MTDesk - Build e Release → Run workflow**.
> Questa pagina serve quando la build automatica fallisce e devi capire *dove*,
> oppure quando vuoi provare una modifica senza pubblicare niente.

---

## 0. Cosa serve prima di cominciare

| Requisito | Valore | Perché |
|---|---|---|
| **Ubuntu** | **22.04** (Jammy) | Vedi il riquadro qui sotto |
| **RAM** | 8 GB reali, oppure 4 GB + 12 GB di swap | Il compilatore Rust in *release* è famelico |
| **Disco libero** | ~40 GB | ffmpeg, Rust e Flutter insieme occupano tanto |
| **Tempo** | 1–3 ore la prima volta | Poi molto meno: cargo riusa il lavoro fatto |
| **Connessione** | ~4 GB di download | Toolchain + librerie |

> ### Perché proprio Ubuntu 22.04 e non l'ultima versione
> Un programma compilato su una certa versione di Ubuntu funziona su quella e su
> **tutte le successive**, mai sulle precedenti (dipende dalla versione della libreria
> di sistema `glibc`). Compilando su 22.04 il pacchetto si installa su **Ubuntu 22.04,
> 24.04 e successive**, e anche su Debian 12. Se lo compili su 24.04, i clienti ancora
> su 22.04 non potranno installarlo. Per questo anche il workflow automatico usa
> `ubuntu-22.04` e non `ubuntu-latest`.
>
> Se hai solo una macchina più recente, il modo pulito è un contenitore:
> `docker run -it -v $PWD:/src ubuntu:22.04 bash` e poi seguire questa guida dentro.

> ### ATTENZIONE — la cartella `client/libs/hbb_common`
> Nel progetto RustDesk quella cartella è un **sottomodulo git**, cioè un segnaposto
> che punta a un altro repository. Ma è proprio lì dentro che stanno le tre cose
> che rendono MTDesk *nostro*: il nome dell'app, l'indirizzo del centralino e la
> chiave pubblica (`libs/hbb_common/src/config.rs`, righe 72, 117, 118).
>
> Se cloni il repository e quella cartella ti arriva vuota, oppure se lanci
> `git submodule update`, ti ritrovi il file **originale di RustDesk**: compili, tutto
> sembra funzionare, e il programma che ne esce si chiama "RustDesk" e si collega ai
> server pubblici di RustDesk. Prima di compilare, **verifica sempre**:
>
> ```bash
> grep -n "mtdesk.marketingtools.digital" client/libs/hbb_common/src/config.rs
> ```
>
> Se questo comando non stampa niente, **fermati**: il codice non è quello di MTDesk.

---

## Prerequisiti (versioni ESATTE)

| Componente | Versione | Da dove viene |
|---|---|---|
| **Rust** | **1.75** | `client/.github/workflows/flutter-build.yml` riga 22. **NON** 1.78+: cambia l'ABI dei numeri a 128 bit |
| **Flutter** | **3.24.5** | stesso file, riga 28. Su Linux **non** serve il motore custom di RustDesk (serve solo su Windows) |
| **vcpkg** | commit `9e593bb18ea69cc5095e012465dcd675a822ed0d` | stesso file, riga 45. Triplet `x64-linux` |
| **flutter_rust_bridge_codegen** | **1.80.1** | `client/.github/workflows/bridge.yml` riga 10, e `client/Cargo.toml` riga 74 (`flutter_rust_bridge = "=1.80"`) e `client/flutter/pubspec.yaml` riga 53 |
| **cargo-expand** | **1.0.95** | `client/.github/workflows/bridge.yml` riga 9 |
| **Python 3** | 3.x | orchestratore `build.py` |
| **LLVM/Clang** | quello di Ubuntu 22.04 (14) | serve a `bindgen`. Il CI di RustDesk chiede `libclang-10-dev`, che su 22.04 non esiste più: si usa `libclang-dev` |

---

## Passi

### 1. Librerie di sistema

Elenco preso dal CI di RustDesk (`flutter-build.yml`, blocco `install:` del job
`build-rustdesk-linux`, righe ~1561-1580) più le due righe in più di `ci.yml`.
I nomi `libclang-10-dev` / `llvm-10-dev` del CI sono sostituiti dai generici, perché i
pacchetti con il `-10` non esistono su 22.04.

```bash
sudo apt-get update
sudo apt-get install -y \
  build-essential clang cmake curl gcc git g++ \
  libasound2-dev libayatana-appindicator3-dev libclang-dev \
  libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
  libgtk-3-dev libpulse-dev libssl-dev libunwind-dev \
  libva-dev libvdpau-dev \
  libxcb-randr0-dev libxcb-shape0-dev libxcb-xfixes0-dev \
  libxdo-dev libxfixes-dev llvm-dev \
  nasm ninja-build pkg-config python3 unzip wget xz-utils

# Opus lo costruiamo noi con vcpkg: se resta anche quello di sistema,
# il linker rischia di pescare quello sbagliato. Lo fa anche il CI di RustDesk.
sudo apt-get remove -y libopus-dev || true
```

Se hai meno di 8 GB di RAM, aggiungi swap **adesso**, non dopo il primo fallimento:

```bash
sudo fallocate -l 12G /swapfile && sudo chmod 600 /swapfile
sudo mkswap /swapfile && sudo swapon /swapfile
free -h        # deve mostrare lo swap attivo
```

### 2. Rust 1.75

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"
rustup toolchain install 1.75.0-x86_64-unknown-linux-gnu
rustup default 1.75.0-x86_64-unknown-linux-gnu
rustup component add rustfmt
rustc --version        # deve dire 1.75.0
```

### 3. vcpkg (commit pinnato) + librerie native

Qui si costruiscono ffmpeg, aom, libvpx, libyuv, opus: è il passo **più lungo**
(30–60 minuti) e quello che consuma più disco.

```bash
git clone https://github.com/microsoft/vcpkg ~/vcpkg
cd ~/vcpkg
git checkout 9e593bb18ea69cc5095e012465dcd675a822ed0d
./bootstrap-vcpkg.sh
export VCPKG_ROOT="$HOME/vcpkg"
echo 'export VCPKG_ROOT="$HOME/vcpkg"' >> ~/.bashrc   # così non te lo dimentichi

# Si lancia DENTRO client/: vcpkg lavora in "manifest mode", cioè legge
# client/vcpkg.json, che indica da solo gli overlay (le ricette modificate
# in res/vcpkg e i triplet in res/vcpkg-triplets).
cd /percorso/di/MTDESK/client
"$VCPKG_ROOT/vcpkg" install --triplet x64-linux --x-install-root="$VCPKG_ROOT/installed"

ls "$VCPKG_ROOT/installed/x64-linux/lib"   # devi vedere libavcodec.a, libaom.a, libopus.a...
```

A cose fatte puoi recuperare diversi GB:
`rm -rf "$VCPKG_ROOT/buildtrees" "$VCPKG_ROOT/packages" "$VCPKG_ROOT/downloads"`
(ma **solo dopo** che il comando è riuscito: dentro `buildtrees` ci sono i log degli errori).

### 4. Flutter 3.24.5 + patch obbligatoria

```bash
cd /opt
sudo wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.5-stable.tar.xz
sudo tar xf flutter_linux_3.24.5-stable.tar.xz
sudo chown -R $USER /opt/flutter
export PATH="/opt/flutter/bin:$PATH"
echo 'export PATH="/opt/flutter/bin:$PATH"' >> ~/.bashrc
git config --global --add safe.directory /opt/flutter
flutter --version      # deve dire 3.24.5
flutter doctor -v
```

Poi la patch. **Non saltarla.** Corregge un difetto *dentro* Flutter 3.24.5, nel menu a
tendina con ricerca (`DropdownMenu`): senza, l'elenco dei PC resta filtrato anche dopo
che hai scelto una voce o svuotato la casella. Il programma **compila lo stesso**, quindi
se la dimentichi non vedi nessun errore rosso: te ne accorgi solo usando l'app.

```bash
cd /opt/flutter
git apply /percorso/di/MTDESK/client/.github/patches/flutter_3.24.4_dropdown_menu_enableFilter.diff
git status --short       # deve mostrare modificato packages/flutter/lib/src/material/dropdown_menu.dart
```

> Su Linux **non** serve il motore custom di RustDesk, che invece su Windows è
> obbligatorio (vedi `client/BUILD-WINDOWS.md`, passo 3). Lo dice il CI stesso alla
> riga 208 di `flutter-build.yml`: quella sostituzione è marcata "x64 only", cioè
> solo Windows x64.

### 5. Bridge FFI (Dart ↔ Rust)

MTDesk è metà in Rust (cattura schermo, rete) e metà in Dart/Flutter (le finestre).
Le due metà si parlano attraverso file **generati**, che non stanno nel repository
(sono elencati in `client/.gitignore`). Vanno rigenerati qui, altrimenti la
compilazione si ferma dicendo che non trova `bridge_generated.rs`.

```bash
cd /percorso/di/MTDESK/client
cargo install cargo-expand --version 1.0.95 --locked
cargo install flutter_rust_bridge_codegen --version 1.80.1 --features "uuid" --locked

cd flutter && flutter pub get && cd ..

~/.cargo/bin/flutter_rust_bridge_codegen \
  --rust-input ./src/flutter_ffi.rs \
  --dart-output ./flutter/lib/generated_bridge.dart \
  --c-output ./flutter/macos/Runner/bridge_generated.h

# Correzione che build.py applica sempre (funzione ffi_bindgen_function_refactor):
# il generatore scrive un tipo sbagliato per il valore di ritorno di una callback.
sed -i 's/ffi.NativeFunction<ffi.Bool Function(DartPort/ffi.NativeFunction<ffi.Uint8 Function(DartPort/g' \
  flutter/lib/generated_bridge.dart

ls -l src/bridge_generated.rs src/bridge_generated.io.rs flutter/lib/generated_bridge.dart flutter/lib/generated_bridge.freezed.dart
```

> Devono uscire **quattro** file, non tre. `generated_bridge.freezed.dart` non e' un
> accessorio: `generated_bridge.dart` lo richiama alla sua riga 14
> (`part 'generated_bridge.freezed.dart';`). Se manca, la compilazione non si ferma
> subito: si ferma un'ora dopo, dentro Flutter, con un errore che non dice il perche'.

> **Differenza voluta rispetto al workflow automatico.** Il CI di RustDesk genera il
> bridge con **Flutter 3.22.3** in un lavoro a parte, e per riuscirci deve abbassare la
> dipendenza `extended_text` da 14 a 13 dentro `pubspec.yaml`
> (`client/.github/workflows/bridge.yml`). Il nostro workflow fa lo stesso, per restare
> identico a una combinazione che gira tutte le notti da anni.
> Qui a mano invece si usa **un solo Flutter, il 3.24.5**, e quell'abbassamento non
> serve: è lo stesso metodo di `client/scripts/build-mtdesk.ps1`, quello con cui è
> stato prodotto l'eseguibile Windows che già funziona. Vanno bene entrambe: non
> mescolarle, scegline una.

### 6. Compilazione e pacchetto

```bash
cd /percorso/di/MTDESK/client
export VCPKG_ROOT="$HOME/vcpkg"
export PATH="/opt/flutter/bin:$HOME/.cargo/bin:$PATH"
export DEB_ARCH=amd64
export CARGO_INCREMENTAL=0

# Opzionale ma consigliato: su Linux serve solo la libreria dinamica.
# Fa risparmiare parecchi minuti e qualche GB. Lo fa anche il CI.
sed -i 's/\["cdylib", "staticlib", "rlib"\]/["cdylib"]/g' Cargo.toml

python3 ./build.py --flutter --hwcodec --unix-file-copy-paste

# A build finita RIMETTI Cargo.toml com'era, altrimenti quella riga modificata
# resta sul tuo PC e finisce nel prossimo commit (la build di Windows usa anche
# le altre due varianti della libreria).
cd /percorso/di/MTDESK/client && git checkout -- Cargo.toml && git status --short
```

> Sul runner di GitHub questa riga non da' fastidio, perche' la macchina viene
> buttata via a fine lavoro. Sul **tuo** computer invece la modifica resta:
> ricordati il `git checkout -- Cargo.toml` qui sopra.

Le tre funzionalità (`hwcodec`, `flutter`, `unix-file-copy-paste`) sono esattamente
quelle del CI di RustDesk (`flutter-build.yml`, riga 1624).

`build.py` fa tre cose in fila:

1. `cargo build --locked --release --lib` → `target/release/librustdesk.so`
2. `flutter build linux --release` → `flutter/build/linux/x64/release/bundle/`
3. `dpkg-deb` → **`client/mtdesk-1.4.9.deb`**

### 7. Metti i file a nome di root e dai il nome definitivo

**Passo importante, non estetico.** Un `.deb` si porta dietro anche l'elenco di *chi
possiede* ogni file. Se compili con il tuo utente normale, il pacchetto dice "questi
file appartengono all'utente numero 1000", cioè al primo utente del PC. Su un computer
di un cliente, quell'utente potrebbe sostituire il programma di MTDesk, che il sistema
avvia con i privilegi di amministratore: diventerebbe amministratore senza password.
(Il CI di RustDesk non ha questo problema per caso, perché compila dentro un contenitore
Docker dove si è già root.)

```bash
cd /percorso/di/MTDESK/client
dpkg-deb --raw-extract mtdesk-1.4.9.deb /tmp/deb-riconfezionato
dpkg-deb --root-owner-group --build /tmp/deb-riconfezionato mtdesk-ubuntu-amd64.deb

# Verifica: la seconda colonna deve essere "root/root" su OGNI riga
dpkg-deb --contents mtdesk-ubuntu-amd64.deb | awk '$2 != "root/root"'   # non deve stampare niente

sha256sum mtdesk-ubuntu-amd64.deb | tee mtdesk-ubuntu-amd64.deb.sha256
```

Il nome **`mtdesk-ubuntu-amd64.deb`** è fisso e senza numero di versione: la landing
usa link del tipo `/releases/latest/download/mtdesk-ubuntu-amd64.deb`, che si
romperebbero se il nome cambiasse a ogni versione.

### 8. Prova che funzioni davvero

```bash
sudo apt install ./mtdesk-ubuntu-amd64.deb

systemctl status mtdesk        # deve risultare "active (running)"
which mtdesk                   # /usr/bin/mtdesk
mtdesk                         # si apre la finestra
```

Cinque controlli, in ordine:

1. La finestra si intitola **MTDesk** (non RustDesk).
2. Nel menu applicazioni di Ubuntu compare **MTDesk** con l'icona giusta
   (se resta un rettangolo vuoto, vedi il punto 7 dei problemi qui sotto).
3. In alto a sinistra compare un **ID a 9 cifre** e la spia diventa **verde**:
   vuol dire che il client ha trovato `mtdesk.marketingtools.digital`.
   Se resta rossa/gialla, il problema è il centralino o la rete, **non** la build.
4. In *Impostazioni → Rete* il server deve essere già compilato e non modificabile.
5. Da un altro PC con MTDesk, collegati a quell'ID: devi vedere lo schermo e muovere
   il mouse.

Per disinstallare: `sudo apt remove mtdesk`.

---

## Punti di fallimento più probabili

In ordine di quanto è facile incapparci.

### 1. `Couldn't find VCPKG_ROOT` (oppure `libavcodec/avcodec.h: No such file`)
La variabile `VCPKG_ROOT` non è arrivata a `cargo`. Succede quasi sempre perché l'hai
esportata in un terminale e poi ne hai aperto un altro, o perché hai usato `sudo`
(che ripulisce l'ambiente). Rimedio: `export VCPKG_ROOT="$HOME/vcpkg"` nello stesso
terminale in cui lanci `build.py`, e **non** lanciare `build.py` con `sudo`.

### 2. Il compilatore viene ucciso: `signal: 9, SIGKILL` o `Killed`
Finita la RAM. Non è un errore del codice. Aggiungi swap (passo 1) e rilancia:
cargo riparte da dove era arrivato.

### 3. `No space left on device`
ffmpeg + Rust + Flutter sfiorano i 40 GB. Cancella le cartelle di lavoro di vcpkg
(`buildtrees`, `packages`, `downloads`) **dopo** che vcpkg è riuscito, e controlla con
`df -h`.

### 4. vcpkg fallisce su `aom` o `ffmpeg` con "patch does not apply"
Non sei al commit giusto di vcpkg. Le ricette in `client/res/vcpkg` contengono patch
scritte per **quel** commit esatto. Rifai il `git checkout 9e593bb...` e ribootstrappa.

### 5. `error: package requires rustc 1.8x or newer` — oppure crash strani a runtime
Stai usando un Rust diverso da 1.75. Controlla con `rustc --version` **nella cartella
client/**: potrebbe esserci un file `rust-toolchain` che sovrascrive il default.

### 6. `flutter_rust_bridge_codegen` non trova libclang
Il generatore cerca `libclang.so` da solo e a volte non la trova. Passagli la strada:

```bash
~/.cargo/bin/flutter_rust_bridge_codegen ... --llvm-path /usr/lib/llvm-14
```

(È lo stesso problema del punto 2 di `client/BUILD-WINDOWS.md`, dove su Windows si
passa `--llvm-path` alla cartella di LLVM.)

### 7. Il pacchetto si installa, ma nel menu di Ubuntu l'icona è un rettangolo vuoto
Le icone vengono cercate per **nome** nel tema di sistema, e il nome deve combaciare
in tre posti: il file installato in `/usr/share/icons/hicolor/*/apps/mtdesk.png`, il
campo `Icon=` del file `.desktop`, e la stringa in
`client/flutter/linux/my_application.cc`. Se ne cambi uno, cambiali tutti. Dopo
l'installazione il sistema aggiorna la cache da solo (lo fa `res/DEBIAN/postinst`), ma
a volte serve un logout/login.

### 8. `dpkg: dependency problems` durante l'installazione
Le dipendenze del pacchetto sono scritte in `build.py`, funzione `generate_control_file`,
e includono alternative per Ubuntu 24.04 (`libgtk-3-0t64 | libgtk-3-0`). Se manca
qualcosa sul PC di destinazione: `sudo apt --fix-broken install`.

### 9. Il programma parte ma la spia resta rossa
Non è la build: è il centralino. Verifica che `mtdesk.marketingtools.digital` risponda
sulle porte 21115-21119 (TCP) e 21116 (UDP). Prova da terminale:
`nc -vz mtdesk.marketingtools.digital 21116`.

### 10. Hai compilato tutto e il programma si chiama "RustDesk"
Il caso descritto nel riquadro all'inizio: `libs/hbb_common` è tornato quello originale.
Ricontrolla con il `grep` del riquadro e **non pubblicare quel pacchetto**.

---

## Note

- **Firma digitale:** su Linux non serve. Un `.deb` non firmato si installa senza
  avvisi, al contrario di Windows che mostra "editore sconosciuto".
- **Nomi tecnici rimasti `rustdesk`:** la cartella `/usr/share/rustdesk`, il nome del
  crate Rust e lo schema dei link `rustdesk://` non sono stati rinominati di proposito
  (rinominare tutto è ad alto rischio e non serve). L'utente vede "MTDesk" ovunque:
  eseguibile `mtdesk`, servizio `mtdesk`, voce di menu MTDesk. Dettagli in
  `client/REBRAND-CHANGES.md`, sezione 7.
- **Architetture:** questa guida produce solo **amd64** (PC Intel/AMD a 64 bit), che
  copre praticamente tutti i clienti. Per ARM64 (Raspberry Pi, alcuni portatili) il CI
  di RustDesk usa una macchina diversa (`ubuntu-22.04-arm`): non è previsto nel
  progetto MTDesk.
- **macOS:** fuori dal progetto, per scelta.
