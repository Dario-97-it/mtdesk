# MTDesk — Build del pacchetto Ubuntu (.deb)

Guida per compilare **a mano** `MTDesk` (fork RustDesk 1.4.9 ribrandizzato) su Ubuntu e
produrre `mtdesk-ubuntu-amd64.deb`.
È la gemella di [`client/BUILD-WINDOWS.md`](client/BUILD-WINDOWS.md).
Ogni versione qui è un **vincolo di compatibilità** preso dal CI ufficiale di RustDesk:
**non aggiornarle**.

> **A regime questa guida NON dovrebbe servirti.**
> Il `.deb` è pensato per essere compilato da GitHub, da solo e gratis, con
> [`.github/workflows/mtdesk-build.yml`](.github/workflows/mtdesk-build.yml):
> vai su **Actions → MTDesk - Build e Release → Run workflow**.
> Questa pagina serve quando la build automatica fallisce e devi capire *dove*,
> oppure quando vuoi provare una modifica senza pubblicare niente.
>
> **Oggi (novembre 2026) siamo proprio nel primo caso.** La prima esecuzione del
> workflow, partita dal tag `v1.4.9`, è **fallita** nel lavoro Ubuntu, al passo di vcpkg
> (quello che in questa guida è il passo 3). La causa non è ancora stata trovata: lo
> stesso passo, rifatto in un contenitore `ubuntu:22.04` pulito, riesce. Finché il
> workflow non viene sistemato, il `.deb` si ottiene **a mano, con questa guida**, dentro
> un contenitore Ubuntu 22.04 (riquadro al punto 0): è in un contenitore così che è
> stato compilato il pacchetto della prima prova vera fra due computer, il 10/11/2026.
> Per lo stesso motivo **non esiste ancora nessuna Release pubblicata**: i link
> `/releases/latest/download/...` oggi rispondono "404" (pagina non trovata).

---

## 0. Cosa serve prima di cominciare

| Requisito | Valore | Perché |
|---|---|---|
| **Ubuntu** | **22.04** (Jammy) | Vedi il riquadro qui sotto |
| **RAM** | 8 GB reali, oppure 4 GB + 12 GB di swap | Il compilatore Rust in *release* è famelico (se non bastano: punto 2 dei problemi, più sotto) |
| **Disco libero** | ~40 GB | ffmpeg, Rust e Flutter insieme occupano tanto |
| **Tempo** | 1–3 ore la prima volta | Poi molto meno: cargo riusa il lavoro fatto |
| **Connessione** | ~4 GB di download | Toolchain + librerie |

> ### Perché proprio Ubuntu 22.04 e non l'ultima versione
> Un programma compilato su una certa versione di Ubuntu funziona su quella e su
> **tutte le successive**, mai sulle precedenti (dipende dalla versione della libreria
> di sistema `glibc`). Compilando su 22.04 il pacchetto si installa su **Ubuntu 22.04,
> 24.04 e successive**, e anche su Debian 12. Se lo compili su 24.04, i clienti ancora
> su 22.04 non potranno installarlo. Per questo anche il workflow automatico usa
> `ubuntu-22.04` e non `ubuntu-latest`. (Riscontro del 10/11/2026: un pacchetto
> compilato così è stato installato su Ubuntu 26.04 senza che `apt` dovesse scaricare
> nessuna dipendenza in più.)
>
> Se hai solo una macchina più recente (è il caso del PC Ubuntu di prova, che ha la
> 26.04), il modo pulito è un **contenitore**: una "scatola" con dentro Ubuntu 22.04,
> che si crea e si butta via senza toccare il sistema vero. Serve Docker installato.
>
> ```bash
> docker run -it --name mtdesk-build ubuntu:22.04 bash
> ```
>
> Da questo momento sei **dentro** il contenitore. Lì dentro sei già l'amministratore
> (`root`), e il comando `sudo`, che questa guida usa spesso, di norma non è installato:
> mettilo per primo, insieme a `git`, così tutti i comandi che seguono funzionano
> esattamente come sono scritti. Poi scarica il codice **da dentro il contenitore**:
>
> ```bash
> apt-get update && apt-get install -y sudo git ca-certificates
> git clone https://github.com/Dario-97-it/mtdesk.git /src/mtdesk
> ```
>
> In questo caso, dove la guida scrive `/percorso/di/MTDESK` tu scrivi `/src/mtdesk`.
> Tre cose utili da sapere quando si lavora così:
>
> - se durante un'installazione di pacchetti compare una domanda sul fuso orario
>   ("Geographic area"), rispondi con i numeri di *Europe* e poi di *Rome*: capita nei
>   contenitori appena creati;
> - se esci (`exit`) il contenitore si ferma ma **non** perde il lavoro fatto: ci rientri
>   con `docker start -ai mtdesk-build`;
> - per provare una modifica che non è ancora sul ramo `main`, mettila in un ramo a
>   parte, caricalo su GitHub con `git push` (caricare un ramo non pubblica nessuna
>   Release) e scaricalo con `git clone --branch <nome-del-ramo> ...` al posto del
>   `git clone` qui sopra.
>
> **Non usare la cartella del progetto che sta sul PC Windows**: né "montandola" nel
> contenitore (l'opzione `-v` di Docker, che una versione precedente di questa guida
> consigliava) né copiandola su una chiavetta. Il motivo: Windows termina ogni riga di
> testo con due caratteri invisibili (CR+LF), Linux con uno solo (LF). Dentro il
> repository i file sono in formato Linux, ma nella copia di lavoro su Windows molti no,
> compresi file che Linux deve *eseguire* durante la build (per esempio
> `client/res/vcpkg/ffmpeg/build.sh.in`); e su Windows non esiste nemmeno il "permesso di
> esecuzione". Il risultato sono errori incomprensibili a metà di una compilazione che
> dura ore. Con un `git clone` fatto su Linux il problema non si pone.

> ### ATTENZIONE — la cartella `client/libs/hbb_common` (che non è più un sottomodulo)
> È lì dentro che stanno le tre cose che rendono MTDesk *nostro*: il nome dell'app,
> l'indirizzo del centralino e la chiave pubblica
> (`client/libs/hbb_common/src/config.rs`, righe 72, 118 e 119).
>
> Nel progetto RustDesk quella cartella è un **sottomodulo git**, cioè un segnaposto
> che punta a un altro repository. In MTDesk **non lo è più**: da novembre 2026 è fatta
> di file normali, che stanno nel nostro repository come tutti gli altri. Quindi un
> `git clone` la scarica già completa, e **non c'è nessun comando `git submodule` da
> lanciare**. Il vecchio pericolo — un `git submodule update` che rimetteva al suo
> posto il file originale di RustDesk — non esiste più.
>
> Resta una verifica da dieci secondi, da fare **sempre** prima di compilare. Se quel
> file non fosse il nostro, la compilazione andrebbe avanti lo stesso, senza nessun
> errore, e alla fine uscirebbe un programma che si chiama "RustDesk" e cerca i server
> pubblici di RustDesk:
>
> ```bash
> grep -n "mtdesk.marketingtools.digital" client/libs/hbb_common/src/config.rs
> ```
>
> Deve stampare una riga, la 118. Se non stampa niente, **fermati**: il codice che hai
> davanti non è quello di MTDesk (copia incompleta, cartella sostituita, repository
> sbagliato). È lo stesso controllo che il workflow automatico fa nel suo lavoro 1.

---

## Prerequisiti (versioni ESATTE)

| Componente | Versione | Da dove viene |
|---|---|---|
| **Rust** | **1.75** | `RUST_VERSION` nel nostro workflow; nel CI di RustDesk è `flutter-build.yml` riga 22. **NON** 1.78+: cambia l'ABI dei numeri a 128 bit |
| **Flutter** | **3.24.5** | `FLUTTER_VERSION` nel nostro workflow; nel CI di RustDesk stesso file, riga 28. Il motore è quello **ufficiale** dello SDK: nessun motore di terzi, né qui né (da novembre 2026) su Windows |
| **vcpkg** | commit `9e593bb18ea69cc5095e012465dcd675a822ed0d` | `VCPKG_COMMIT_ID` nel nostro workflow e `baseline` in `client/vcpkg.json`; nel CI di RustDesk stesso file, riga 45. Triplet `x64-linux` |
| **flutter_rust_bridge_codegen** | **1.80.1** | `FLUTTER_RUST_BRIDGE_VERSION` nel nostro workflow (nel CI di RustDesk: `bridge.yml` riga 10), più `client/Cargo.toml` riga 74 (`flutter_rust_bridge = "=1.80"`) e `client/flutter/pubspec.yaml` riga 53 |
| **cargo-expand** | **1.0.95** | `CARGO_EXPAND_VERSION` nel nostro workflow; nel CI di RustDesk è `bridge.yml` riga 9 |
| **Python 3** | 3.x | orchestratore `build.py` |
| **LLVM/Clang** | quello di Ubuntu 22.04 (14) | serve a `bindgen`. Il CI di RustDesk chiede `libclang-10-dev`, che su 22.04 non esiste più: si usa `libclang-dev` |

> **Dove sono i file citati in questa guida.** "Il nostro workflow" è
> [`.github/workflows/mtdesk-build.yml`](.github/workflows/mtdesk-build.yml): le versioni
> stanno nel blocco `env:` in cima al file. I file del **CI di RustDesk**
> (`flutter-build.yml`, `bridge.yml`, `ci.yml`) invece **non sono più nel nostro
> repository**: stavano in `client/.github/workflows/` e sono stati tolti quando MTDesk è
> diventato un repository unico (è rimasta solo la cartella `client/.github/patches/`,
> che serve alla build). Si leggono nel repository di RustDesk,
> github.com/rustdesk/rustdesk, cartella `.github/workflows/`. I numeri di riga indicati
> in questa guida valgono per la versione da cui è partito MTDesk: ramo `master`, commit
> `cec4085238ee723b75095e94014e8595f374688b` del 25 agosto 2026 (che si dichiara 1.4.9).

---

## Passi

### 1. Librerie di sistema

Elenco preso dal CI di RustDesk (`flutter-build.yml`, blocco `install:` del job
`build-rustdesk-linux`, righe 1561-1592) più le due righe in più di `ci.yml`
(`libunwind-dev` e `libvdpau-dev`): sono gli stessi pacchetti che installa il nostro
workflow nel lavoro 3 (lì c'è in più soltanto `tree`, un programmino per elencare le
cartelle che nessun passo della build usa). In più qui c'è `zip`: lo pretende lo script
di avvio di vcpkg (passo 3), che altrimenti si ferma con "Could not find zip", e in un
contenitore appena creato non è installato.
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
  nasm ninja-build pkg-config python3 unzip wget xz-utils zip

# Opus lo costruiamo noi con vcpkg: se resta anche quello di sistema,
# il linker rischia di pescare quello sbagliato. Lo fa anche il CI di RustDesk.
sudo apt-get remove -y libopus-dev || true
```

Se hai meno di 8 GB di RAM, aggiungi swap **adesso**, non dopo il primo fallimento
(se stai lavorando nel contenitore, questi comandi vanno dati sul PC vero, **fuori** dal
contenitore: la memoria è quella del PC che lo ospita):

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
sudo chown -R "$(id -un)" /opt/flutter   # id -un = il tuo nome utente (funziona anche nel contenitore)
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

> **Nessun motore di terzi.** Il "motore" è la parte di Flutter che disegna le finestre,
> e qui si usa quello **ufficiale**, già contenuto nell'SDK che hai appena scaricato: non
> c'è niente da sostituire. Il CI di RustDesk sostituisce il motore con una sua versione
> modificata soltanto nella build per Windows a 64 bit (`flutter-build.yml`, righe
> 208-217, marcata "x64 only"): su Linux non l'ha mai fatto, e nella prova del
> 10/11/2026 il client Ubuntu ha ricevuto e disegnato il video di una sessione vera.
> MTDesk non lo fa più nemmeno su Windows: da novembre 2026 anche lì si usa il motore
> ufficiale (vedi `client/BUILD-WINDOWS.md`, passo 3, dove è scritto anche che cosa di
> quella scelta resta ancora da verificare su Windows).

### 5. Bridge FFI (Dart ↔ Rust)

MTDesk è metà in Rust (cattura schermo, rete) e metà in Dart/Flutter (le finestre).
Le due metà si parlano attraverso file **generati**, che non stanno nel repository
(sono elencati in `client/.gitignore` e in `client/flutter/.gitignore`). Vanno
rigenerati qui, altrimenti la compilazione si ferma dicendo che non trova
`bridge_generated.rs`.

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
> (è scritto nel loro `bridge.yml`). Il nostro workflow fa lo stesso nel suo lavoro 2,
> per restare identico a una combinazione che gira tutte le notti da anni.
> Qui a mano invece si usa **un solo Flutter, il 3.24.5**, e quell'abbassamento non
> serve: è lo stesso metodo di `client/scripts/build-mtdesk.ps1`, quello con cui è
> stato prodotto l'eseguibile Windows che già funziona. Vanno bene entrambe: non
> mescolarle, scegline una.

### 6. Compilazione e pacchetto

```bash
cd /percorso/di/MTDESK/client

# PRIMA DI TUTTO, e non è facoltativo (la spiegazione è più sotto, dopo questo blocco):
# i 4 script che Ubuntu esegue quando installa il pacchetto devono essere "eseguibili".
chmod 755 res/DEBIAN/preinst res/DEBIAN/postinst res/DEBIAN/prerm res/DEBIAN/postrm
ls -l res/DEBIAN/        # le righe dei quattro script devono cominciare con -rwxr-xr-x

# Secondo controllo: i file che finiscono nel pacchetto devono essere in formato Linux.
# Questo comando NON deve stampare niente. Se stampa dei nomi di file, fermati.
grep -l $'\r' res/DEBIAN/preinst res/DEBIAN/postinst res/DEBIAN/prerm res/DEBIAN/postrm \
  res/rustdesk.desktop res/rustdesk-link.desktop res/rustdesk.service

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
>
> L'ultimo comando (`git status --short`) mostra che cosa è rimasto modificato. È normale
> se elenca i quattro script di `res/DEBIAN/`: è l'effetto del `chmod`, e non va
> annullato. Non deve invece comparire `Cargo.toml`.

> **Perché il `chmod` in cima.** Dentro un `.deb` ci sono quattro piccoli programmi
> (`preinst`, `postinst`, `prerm`, `postrm`) che Ubuntu esegue quando installa o toglie
> il pacchetto: sono loro a creare il comando `/usr/bin/mtdesk` e ad avviare il servizio.
> Per poterli eseguire, quei file devono avere il "permesso di esecuzione", che su
> Windows non esiste. Nel nostro repository, caricato da un PC Windows, sono registrati
> **senza** quel permesso (`git ls-files -s client/res/DEBIAN/` li mostra come `100644`),
> quindi **ogni** `git clone` li consegna così. `build.py` li copia tali e quali dentro
> il pacchetto, e a quel punto lo strumento che lo confeziona (`dpkg-deb`) si rifiuta di
> lavorare: succede **all'ultimo passo, dopo ore di compilazione riuscita** (è il punto
> 11 dei problemi). Il workflow automatico fa lo stesso `chmod`, per lo stesso motivo.
> Dare il comando quando il permesso c'è già non fa nessun danno: lascialo sempre.
>
> **Perché il controllo dei fine-riga.** È il difetto più insidioso, perché non ferma la
> compilazione: il pacchetto esce, ma poi **non si installa** sul PC del cliente. Windows
> termina ogni riga con un carattere invisibile in più; se quel carattere finisce in
> fondo alla prima riga di uno degli script (`#!/bin/bash`), Ubuntu cerca un programma
> che si chiama "/bin/bash" più quel carattere, e non lo trova. Il file
> `client/.gitattributes` esiste per impedirlo, e con un `git clone` fatto su Linux non
> dovrebbe succedere mai: il controllo serve a esserne certi. Lo fa anche il workflow
> automatico.

Le tre funzionalità (`hwcodec`, `flutter`, `unix-file-copy-paste`) sono esattamente
quelle del CI di RustDesk (`flutter-build.yml`, riga 1624).

`build.py` fa tre cose in fila:

1. `cargo build --locked --release --lib` → `target/release/liblibrustdesk.so` (il doppio
   "lib" non è un errore di battitura: è al punto 2 che Flutter la copia nel pacchetto
   con il nome `librustdesk.so`)
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

Lo stesso vale se stai lavorando nel contenitore del punto 0: lì sei root, quindi i file
risultano già di root. Il passo va fatto comunque: è anche quello che dà al pacchetto il
nome definitivo, e la verifica costa un secondo.

```bash
cd /percorso/di/MTDESK/client
rm -rf /tmp/deb-riconfezionato     # via gli avanzi di un eventuale tentativo precedente
dpkg-deb --raw-extract mtdesk-1.4.9.deb /tmp/deb-riconfezionato
dpkg-deb --root-owner-group --build /tmp/deb-riconfezionato mtdesk-ubuntu-amd64.deb

# Verifica: la seconda colonna deve essere "root/root" su OGNI riga
dpkg-deb --contents mtdesk-ubuntu-amd64.deb | awk '$2 != "root/root"'   # non deve stampare niente

sha256sum mtdesk-ubuntu-amd64.deb | tee mtdesk-ubuntu-amd64.deb.sha256
```

Il nome **`mtdesk-ubuntu-amd64.deb`** è fisso e senza numero di versione: la landing
usa link del tipo `/releases/latest/download/mtdesk-ubuntu-amd64.deb`, che si
romperebbero se il nome cambiasse a ogni versione. Il rovescio della medaglia è che dal
nome non si capisce **quale versione** si ha in mano: è scritta dentro il pacchetto, e i
due comandi per leggerla sono in cima al passo 8.

Se hai compilato nel contenitore, il file è ancora lì dentro. Per portarlo sul PC vero
apri un **altro** terminale, fuori dal contenitore, e dai:

```bash
docker cp mtdesk-build:/src/mtdesk/client/mtdesk-ubuntu-amd64.deb .
```

Il punto finale vuol dire "mettilo nella cartella in cui mi trovo adesso".

### 8. Prova che funzioni davvero

La prova si fa su un **PC Ubuntu vero**, con lo schermo: non dentro il contenitore, dove
non ci sono né le finestre né i servizi di sistema. Attenzione: se su quel PC è
installato RustDesk, il comando di installazione qui sotto lo **toglie** (i due
programmi non possono convivere: vedi le Note in fondo).

```bash
# Che versione ho in mano? Il nome del file non lo dice, ma dentro c'è scritto:
dpkg-deb -f mtdesk-ubuntu-amd64.deb Version    # deve rispondere 1.4.9

sudo apt install ./mtdesk-ubuntu-amd64.deb

dpkg -s mtdesk | grep Version  # la versione installata su questo PC
systemctl status mtdesk        # deve risultare "active (running)"
which mtdesk                   # /usr/bin/mtdesk
mtdesk                         # si apre la finestra
```

Cinque controlli, in ordine:

1. La finestra si intitola **MTDesk** (non RustDesk).
2. Nel menu applicazioni di Ubuntu compare **MTDesk** con l'icona giusta
   (se resta un rettangolo vuoto, vedi il punto 7 dei problemi, più sotto).
3. In alto a sinistra compare un **ID** numerico (di solito di 9 cifre) e in basso c'è
   un **pallino** con una scritta accanto. Verde con la scritta "Pronto" vuol dire che
   il programma ha trovato il centralino.
   **Oggi (novembre 2026) da solo non può diventare verde**: il centralino scritto dentro
   il programma, `mtdesk.marketingtools.digital`, non esiste ancora (il nome non è
   registrato e il server non è mai stato messo in opera). Finché è così il pallino resta
   arancione ("Connessione alla rete MTDesk...") oppure diventa rosso ("Non pronto.
   Verifica la connessione"): il problema è il centralino, **non** la build. Per provare
   adesso, vedi "Come provare oggi" qui sotto.
4. In *Impostazioni → Rete → Server ID/Relay* i campi sono **vuoti**: è normale.
   Centralino e chiave sono compilati dentro il programma, e quei campi servono solo a
   indicarne uno diverso (come nella prova qui sotto); svuotandoli si torna ai valori
   compilati. Per aprire quella finestra bisogna prima premere **Sblocca impostazioni di
   rete**, che chiede la password.
5. Da un altro PC con MTDesk, collegati a quell'ID: devi vedere lo schermo e muovere
   il mouse. Su Ubuntu questo richiede un consenso dato sul posto: leggi prima "Da
   sapere su Wayland", qui sotto.

> ### Come provare oggi, senza il centralino definitivo
> Nel progetto c'è uno script già collaudato che accende un centralino di prova sul PC
> Windows: `deploy/avvia-centralino-locale.ps1`. Vale solo dentro la rete di casa e solo
> finché quel PC resta acceso, ma per una prova basta: è con quello che è stata fatta la
> prima sessione vera, il 10/11/2026. Alla fine lo script stampa le due cose che
> servono: l'**indirizzo** del PC Windows e la **chiave**.
>
> Poi, su **ogni** computer che partecipa alla prova, bisogna dire a MTDesk di usare quel
> centralino. I modi sono due, equivalenti.
>
> **Dalla finestra:** *Impostazioni → Rete*, premi **Sblocca impostazioni di rete**, poi
> **Server ID/Relay**. Scrivi l'indirizzo sia in *ID server* sia in *Server relay*, la
> chiave in *Key*, e lascia vuoto *Server API*. Due avvertenze: il pulsante **Sblocca**
> compare solo dove MTDesk è installato (se non lo vedi, la voce *Server ID/Relay* è già
> cliccabile); e nel suo messaggio finale lo script chiama la stessa finestra "Server
> ID/Inoltro" e i primi due campi "Server ID" e "Server inoltro": sono questi, nel
> programma i nomi sono quelli scritti qui.
>
> **Dal terminale, su Ubuntu** (funziona solo a programma installato, e solo con `sudo`):
>
> ```bash
> sudo mtdesk --option custom-rendezvous-server <indirizzo>
> sudo mtdesk --option relay-server <indirizzo>
> sudo mtdesk --option key <chiave>
> ```
>
> Chiudi e riapri MTDesk: il pallino deve diventare **verde**, con la scritta "Pronto".
> Se resta arancione, quel computer non raggiunge il PC Windows: devono essere sulla
> stessa rete, e il firewall di Windows deve lasciar passare le porte del centralino (lo
> script se ne occupa: le apre lui, oppure ti scrive i comandi da dare).
>
> Quando il centralino definitivo sarà attivo questi valori vanno **tolti**, altrimenti
> quel computer continuerà a cercare il centralino di prova: basta svuotare i campi
> (dal terminale: gli stessi tre comandi, con `""` al posto del valore).
>
> Oggi quei campi li può cambiare chiunque abbia la password di amministratore del PC,
> ed è proprio questo che rende possibili le prove. Bloccarli è una scelta separata, da
> fare quando il centralino definitivo sarà in funzione, e richiede una modifica al
> codice.

> ### Da sapere su Wayland (riguarda il controllo 5)
> Ubuntu usa per default un sistema grafico che si chiama **Wayland**. Per scelta di
> sicurezza Wayland non lascia che un programma legga lo schermo senza il consenso di chi
> è seduto davanti al PC. Con il pacchetto prodotto da questa guida le conseguenze sono
> tre, tutte previste dal codice (non sono difetti della tua build):
>
> - nella finestra di MTDesk compare un cartellino **Avviso** ("Il supporto Wayland è in
>   fase sperimentale, se vuoi un accesso stabile usa X11") con un collegamento **Aiuto**;
> - quando qualcuno si collega, sul PC Ubuntu il sistema chiede a chi è lì davanti se e
>   quale schermo condividere, e chi si collega legge "Seleziona lo schermo da
>   condividere (opera sul lato dispositivo remoto)". Finché qualcuno, sul posto, non dà
>   il consenso, lo schermo non arriva. La prova del 10/11/2026 (PC Windows che si
>   collega al PC Ubuntu 26.04) è arrivata esattamente fin qui: collegamento e password a
>   posto, poi la richiesta di consenso;
> - la schermata di accesso, cioè quella in cui si scrive la password dopo un riavvio,
>   non è supportata: non si può né vedere né comandare.
>
> In pratica: **con questo pacchetto, su Wayland, l'accesso senza nessuno davanti al PC
> non esiste.** Qualcuno deve dare il consenso a ogni sessione.
>
> I rimedi dal lato del cliente sono spiegati in `docs/aiuto.html`, sezioni "Serve X11,
> non Wayland" e "Schermata di accesso". È la pagina che si apre dal collegamento Aiuto
> del cartellino; finché GitHub Pages non viene attivato quel collegamento non funziona,
> ma il file nel repository si legge lo stesso. Attenzione però: quei rimedi consistono
> nel far usare a Ubuntu il vecchio sistema grafico X11 ("Ubuntu su Xorg"), e **da Ubuntu
> 25.10 quella possibilità non c'è più**. Sul PC di prova (Ubuntu 26.04, GNOME 50, solo
> Wayland) non sono applicabili. Su quelle versioni l'unica strada prevista dal codice è
> la variante descritta più sotto, in "La variante per entrare senza nessuno davanti".

Per disinstallare: `sudo apt remove mtdesk`. Con `sudo apt purge mtdesk` viene tolta anche
la configurazione del servizio di sistema (`/root/.config/mtdesk`).

In nessuno dei due casi vengono cancellati i dati che il programma ha scritto nella
cartella personale di chi l'ha usato. È voluto, perché un pacchetto non deve mai toccare
le cartelle personali, ma va saputo se devi lasciare il PC pulito:

- `~/.config/mtdesk` — la configurazione dell'utente: ID, password e chiavi del
  programma, elenco dei computer a cui ci si è collegati;
- `~/.local/share/logs/MTDesk` — i registri (i "log").

Attenzione a maiuscole e minuscole, che su Linux contano: `mtdesk` nella prima,
`MTDesk` nella seconda. Per cancellarle a mano, per ogni utente che ha aperto il
programma: `rm -rf ~/.config/mtdesk ~/.local/share/logs/MTDesk`. I registri del servizio
di sistema stanno invece in `/root/.local/share/logs/MTDesk` e restano anche dopo il
`purge`: si tolgono con `sudo rm -rf /root/.local/share/logs/MTDesk`.

---

## La variante per entrare senza nessuno davanti: `mtdesk-unattended-wayland`

> **Stato a novembre 2026: esiste nel codice, ma non è mai stata costruita né provata.
> E prima di costruirla serve una decisione del proprietario** (riquadro "DA DECIDERE"
> più sotto). Finché non è presa, l'unico pacchetto Ubuntu del progetto è quello dei
> passi 1-8.

**Che cos'è.** `build.py` ha un'opzione in più, `--drm`. Con quella il pacchetto cambia
natura: il servizio di MTDesk, che gira con i privilegi di amministratore, legge lo
schermo direttamente dalla scheda video (il meccanismo si chiama DRM/KMS) invece di
chiederlo a Ubuntu. Per farlo usa una piccola libreria in C, `libdrmtap`, che sta già
dentro il repository (`client/third_party/libdrmtap`, versione 0.5.4). Stando al codice,
le conseguenze sono tre:

- **non compare la richiesta di consenso** di Ubuntu: si entra anche se davanti al PC
  non c'è nessuno;
- è pensata per funzionare anche sulla **schermata di accesso**, cioè dopo un riavvio;
- se lo schermo si è spento per inattività, il programma prova a **risvegliarlo**.

**Che pacchetto esce.** Non `mtdesk-1.4.9.deb` ma `mtdesk-unattended-wayland-1.4.9.deb`.
Il nome è diverso **apposta**: installare la versione che non chiede il consenso deve
essere una scelta consapevole, non un caso. Prende il posto del pacchetto normale: sullo
stesso PC si installa **uno o l'altro**, mai tutti e due.

**Quale pacchetto per quale situazione.**

| Situazione | Pacchetto | A che punto siamo |
|---|---|---|
| Assistenza con il cliente davanti al PC, che dà il consenso | `mtdesk` (passi 1-8 di questa guida) | compilato, installato e provato il 10/11/2026, fino alla richiesta di consenso |
| Entrare senza nessuno davanti su un Ubuntu che può ancora usare X11 (fino alla 25.04) | `mtdesk`, più i passaggi di `docs/aiuto.html` | descritto in quella pagina; la prova del 10/11/2026 non lo ha riguardato, perché il PC di prova è solo Wayland |
| Entrare senza nessuno davanti dove X11 non c'è più (da Ubuntu 25.10) | `mtdesk-unattended-wayland` | solo nel codice: mai costruito, mai provato, **da decidere** |

> ### DA DECIDERE (proprietario) — decisione non ancora presa
> **La variante si consegna ai clienti? A quali? Con che nome di file?**
> Non è una scelta tecnica. Questa variante cattura lo schermo **senza** la richiesta con
> cui Ubuntu domanda il permesso a chi è seduto davanti al PC, mentre la pagina di
> download (`landing/index.html`) oggi promette al cliente che il controllo resta suo e
> che vede tutto quello che succede. Se si decide di consegnarla, il cliente deve saperlo
> e volerlo, e vanno aggiornati insieme: il workflow (oggi il lavoro 3 lancia `build.py`
> senza `--drm`, quindi GitHub non la compila), la landing, `docs/aiuto.html` e
> `docs/privacy.html`. Se si decide di no, basta scriverlo qui, al posto di questo
> riquadro.

**Come si costruirebbe, stando al codice.** Sono gli stessi passi 1-8 con due
differenze. **Nessuno li ha ancora eseguiti su MTDesk**: sono un punto di partenza, non
una procedura collaudata.

```bash
# 1) In più rispetto al passo 1: quello che serve a compilare libdrmtap
sudo apt-get install -y meson libdrm-dev libegl1-mesa-dev libgles2-mesa-dev

# 2) Al passo 6, al posto della riga "python3 ./build.py ...":
python3 ./build.py --flutter --drm --hwcodec --unix-file-copy-paste
```

Il risultato è `client/mtdesk-unattended-wayland-1.4.9.deb`. Al passo 7 va usato quel
nome al posto di `mtdesk-1.4.9.deb`; il nome finale **non** può essere
`mtdesk-ubuntu-amd64.deb`, che è quello del pacchetto normale, e fa parte della decisione
qui sopra. Una volta installato, il pacchetto si chiama `mtdesk-unattended-wayland`
anche per i comandi del passo 8: `dpkg -s mtdesk-unattended-wayland`,
`sudo apt remove mtdesk-unattended-wayland`.

Tre cose che `build.py` fa da solo, utili da sapere se qualcosa va storto:

- accetta `--drm` solo su Linux e solo dove il pacchetto è un `.deb` (Ubuntu, Debian):
  altrove si ferma subito con un messaggio;
- controlla che la libreria appena compilata contenga davvero la parte che usa la scheda
  video (si chiama EGL). Senza i pacchetti `libegl1-mesa-dev` e `libgles2-mesa-dev` la
  libreria uscirebbe "monca" senza nessun errore: per questo il controllo ferma la build
  e dice di installarli;
- lascia una cartella di lavoro, `client/third_party/libdrmtap/build-pkg`, che non va
  aggiunta a un commit.

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

Se non basta nemmeno lo swap (o non puoi aggiungerlo), c'è una seconda strada: spegnere
l'ottimizzazione finale di Rust, che si chiama **LTO** ed è il momento in cui la
compilazione chiede più memoria. Si fa con una variabile, senza toccare nessun file:
nello stesso terminale, prima di rilanciare `build.py`, dai

```bash
export CARGO_PROFILE_RELEASE_LTO=off
```

Con questa variabile cargo ricompila da capo anche le librerie che aveva già finito: è
normale. Il programma che esce funziona allo stesso modo: è solo un po' più grande e un
po' meno ottimizzato. Non è una strada teorica: il pacchetto della prova del 10/11/2026
è stato compilato con l'LTO spento, proprio per mancanza di memoria (in un contenitore
`ubuntu:22.04` su un PC con 2 core: 25 minuti). Per un pacchetto da pubblicare è meglio
lasciare l'LTO acceso, come fa il workflow.

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

(È lo stesso problema che compare fra quelli risolti elencati in fondo a
`client/BUILD-WINDOWS.md`, alla voce su `libclang.dll`: su Windows si passa
`--llvm-path` alla cartella di LLVM.)

### 7. Il pacchetto si installa, ma nel menu di Ubuntu l'icona è un rettangolo vuoto
Le icone vengono cercate per **nome** nel tema di sistema, e il nome deve combaciare
in tre posti: il file installato in `/usr/share/icons/hicolor/*/apps/mtdesk.png`, il
campo `Icon=` del file `.desktop`, e la stringa in
`client/flutter/linux/my_application.cc`. Se ne cambi uno, cambiali tutti. Dopo
l'installazione il sistema aggiorna la cache da solo (lo fa
`client/res/DEBIAN/postinst`), ma a volte serve un logout/login.

### 8. `dpkg: dependency problems` durante l'installazione
Le dipendenze del pacchetto sono scritte in `build.py`, funzione `generate_control_file`,
e includono alternative per Ubuntu 24.04 (`libgtk-3-0t64 | libgtk-3-0`). Se manca
qualcosa sul PC di destinazione: `sudo apt --fix-broken install`.

### 9. Il programma parte ma il pallino non diventa verde (resta arancione o rosso)
Non è la build: è il centralino. **Oggi è la situazione normale**, perché il centralino
scritto dentro il programma, `mtdesk.marketingtools.digital`, non esiste ancora: per
provare lo stesso, vedi "Come provare oggi" al passo 8.

Quando il centralino definitivo sarà in funzione, le porte da controllare sono
**21115, 21116 e 21117 in TCP, più la 21116 in UDP** (la tabella è in
`deploy/README-SERVER.md`, sezione 3, "Porte da aprire"). Le porte 21118 e 21119, che si
trovano citate in molte guide in rete, da noi sono **chiuse per scelta**
(`deploy/docker-compose.yml` non le pubblica): non risponderanno mai, ed è giusto così.

Prova da terminale, una porta alla volta:
`nc -vz mtdesk.marketingtools.digital 21115`, poi lo stesso con `21116` e `21117`.

Questo comando prova solo il TCP. Per la 21116 in UDP una prova altrettanto semplice non
c'è: la prova è il pallino stesso, perché il programma si registra al centralino
proprio in UDP su quella porta. Quindi, se le tre porte TCP rispondono ma il pallino non
diventa mai verde, quasi sempre manca la regola **UDP 21116** in uno dei firewall del
server.

### 10. Hai compilato tutto e il programma si chiama "RustDesk"
Il caso descritto nel riquadro all'inizio: il file `config.rs` dentro
`client/libs/hbb_common` non è il nostro (cartella sostituita con quella originale di
RustDesk, oppure stai compilando il repository sbagliato). Ricontrolla con il `grep` del
riquadro e **non pubblicare quel pacchetto**.

### 11. `dpkg-deb: error: maintainer script 'postinst' has bad permissions 644 (must be >=0555 and <=0775)`
Compare **all'ultimo momento**, dopo che Rust e Flutter hanno finito con successo, quando
`build.py` confeziona il pacchetto. (Fra gli apici può esserci `preinst`, `prerm` o
`postrm` al posto di `postinst`: è lo stesso problema.) Vuol dire che è stato saltato il
`chmod` in cima al passo 6: i quattro script del pacchetto non hanno il permesso di
esecuzione, perché nel repository sono registrati senza. Non serve ricompilare tutto.
Nello stesso terminale del passo 6:

```bash
cd /percorso/di/MTDESK/client
chmod 755 res/DEBIAN/preinst res/DEBIAN/postinst res/DEBIAN/prerm res/DEBIAN/postrm
rm -rf flutter/tmpdeb        # gli avanzi del tentativo fallito
python3 ./build.py --flutter --hwcodec --unix-file-copy-paste --skip-cargo
```

`--skip-cargo` dice a `build.py` di non rifare la parte Rust, che è già pronta in
`target/release/`, e di ripartire da Flutter e dal confezionamento: minuti invece di ore.

La cura definitiva è registrare il permesso dentro il repository, una volta sola, così
ogni futuro `git clone` lo porta con sé. Dalla cartella principale del progetto:

```bash
git update-index --chmod=+x client/res/DEBIAN/preinst client/res/DEBIAN/postinst client/res/DEBIAN/prerm client/res/DEBIAN/postrm
```

seguito da un commit e da `git push`. **A novembre 2026 non è ancora stato fatto**: finché
`git ls-files -s client/res/DEBIAN/` mostra `100644` invece di `100755`, il `chmod` del
passo 6 resta obbligatorio.

---

## Note

- **Firma digitale:** su Linux non serve. Un `.deb` non firmato si installa senza
  avvisi, al contrario di Windows che mostra "editore sconosciuto".
- **Nomi tecnici rimasti `rustdesk`:** la cartella `/usr/share/rustdesk`, in cui il
  pacchetto installa i suoi file, e il nome del crate Rust non sono stati rinominati
  (rinominare tutto è ad alto rischio). L'utente vede "MTDesk" ovunque: eseguibile
  `mtdesk`, servizio `mtdesk`, voce di menu MTDesk. Anche i link cliccabili sono
  `mtdesk://` e non `rustdesk://`: il programma li ricava da solo dal nome dell'app.
  Dettagli in `client/REBRAND-CHANGES.md`, sezione 7.
  **Conseguenza da sapere prima di installare da un cliente:** proprio perché usa ancora
  quella cartella, il pacchetto dichiara `Conflicts: rustdesk` e `Replaces: rustdesk`
  (`client/build.py`, funzione `generate_control_file`). MTDesk e RustDesk quindi **non
  possono convivere** sullo stesso PC: installando MTDesk, `apt` toglie RustDesk. Per
  farli convivere bisogna prima spostare tutto in `/usr/share/mtdesk` e solo dopo
  togliere quelle due righe. È una modifica al codice **non ancora fatta** (riguarda
  `client/build.py`, `client/res/DEBIAN/postinst` e `client/src/ui.rs`; per la variante
  Wayland anche la cartella `/usr/lib/rustdesk` e
  `client/libs/scrap/src/common/drmtap_dl.rs`). Quando verrà fatta, questa nota e il
  passo 8 andranno aggiornati.
- **Cosa si scarica ancora da internet durante questa build:** le librerie Rust che
  prima arrivavano da repository git di altri ora stanno dentro il progetto
  (`client/third_party`, spiegato in `client/third_party/LEGGIMI.md`), e il motore di
  Flutter è quello ufficiale. Restano, e servono tutti: i pacchetti di Ubuntu (`apt`),
  Rust (`rustup`), le librerie Rust pubblicate su crates.io, vcpkg con i sorgenti di
  ffmpeg e degli altri codec, l'SDK di Flutter e i pacchetti Dart/Flutter che scarica
  `flutter pub get`. Fra questi ultimi, 9 arrivano da repository git e 8 di quei 9
  stanno sotto `github.com/rustdesk-org` (`client/flutter/pubspec.yaml`): quindi la
  compilazione dipende ancora dal fatto che quei repository restino in linea.
- **Architetture:** questa guida produce solo **amd64** (PC Intel/AMD a 64 bit), che
  copre praticamente tutti i clienti. Per ARM64 (Raspberry Pi, alcuni portatili) il CI
  di RustDesk usa una macchina diversa (`ubuntu-22.04-arm`): non è previsto nel
  progetto MTDesk.
- **macOS:** fuori dal progetto, per scelta.
