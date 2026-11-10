# `third_party/` — le librerie portate dentro al progetto

Scritto per chi manutiene MTDesk.

## Cosa c'è qui dentro

Librerie Rust che prima venivano **scaricate a ogni compilazione** da repository GitHub di altri,
in gran parte sotto l'organizzazione `rustdesk-org`. Adesso stanno qui, al **commit esatto** che
`Cargo.lock` già fissava: il codice compilato è identico a prima, byte per byte, ma per queste
librerie la build non contatta più nessun repository di terzi.

Sono 33 cartelle: 32 repository di librerie Rust più `libdrmtap` (una libreria C, vedi in fondo).
Altre 7 stanno in `server/third_party/`, per il centralino.

Due precisazioni, perché la prima stesura di questo file diceva più di quanto fosse vero:

- **Non tutto quello che la build scarica è stato portato qui.** Restano fuori, fra l'altro,
  9 pacchetti Flutter che arrivano ancora da repository GitHub di terzi. L'elenco completo è nella
  sezione «Cosa NON è ancora qui dentro».
- **Il file `.commit-originale` non c'è in ogni cartella.** Le cartelle `.git` sono state rimosse
  (altrimenti git le tratterebbe come sottomoduli — ed è proprio il problema che stavamo
  togliendo), e il commit di provenienza andava quindi scritto da qualche parte. Quel file però
  esiste solo in 5 cartelle (`hwcodec`, `kcp-sys`, `libdrmtap`, `rust-webm`, `tao`) e in nessuna
  delle 7 del centralino. Per questo il commit di **tutte** le cartelle è riportato qui, nella
  sezione «Da quale commit viene ogni cartella».

## Perché, in concreto

Tre ragioni, in ordine di importanza:

1. **Se quei repository spariscono, MTDesk non si compila più.** Sono repository di terzi su cui
   non abbiamo nessun controllo: possono essere rinominati, resi privati o cancellati.
2. **Non avevamo controllo su cosa contenevano.** `Cargo.lock` fissa il commit, quindi un
   cambiamento non sarebbe entrato di nascosto — ma solo finché nessuno esegue `cargo update`.
3. **È una richiesta esplicita del progetto:** MTDesk non deve dipendere dall'infrastruttura di
   RustDesk. Il codice derivato resta AGPL e gli avvisi di copyright restano intatti — quella è
   un'altra cosa, ed è un obbligo di legge.

## Come sono state prese

Per ciascuna: `git init`, `git fetch --depth 1 origin <commit>`, `git checkout <commit>`, poi
rimozione di `.git`. Quattro di esse avevano **sottomoduli con codice C** indispensabile alla
compilazione, presi con `git submodule update --init --recursive`:

| Cartella | Sottomodulo | Serve a |
|---|---|---|
| `hwcodec/externals` | `rustdesk-org/externals` | intestazioni per l'accelerazione hardware |
| `kcp-sys/kcp` | `skywind3000/kcp` | `ikcp.c`, il protocollo di trasporto |
| `rust-webm/src/sys/libwebm` | `chromium.googlesource.com/webm/libwebm` | muxer WebM |
| `tao/deps/apk-builder` | — | solo Android, non preso: non serve |

Senza quei sottomoduli `cargo check` falliva con
`failed to run custom build command for webm-sys / kcp-sys`.

**`wezterm` è stata sfoltita di proposito**: il repository originale pesa 233 MB (ha dentro
documentazione, asset e una ventina di crate), ma a MTDesk servono solo `filedescriptor` e `pty`,
che non dipendono dal resto. Ridotta a 193 KB, licenza inclusa.

## Da quale commit viene ogni cartella

I commit sono quelli che `Cargo.lock` fissava subito prima che le librerie venissero portate qui
(commit `6c4ab58` di questo repository). Si possono rileggere in qualunque momento dalla storia di
git, dalla radice del repository:

```bash
git show "6c4ab58^:client/Cargo.lock" | grep 'source = "git+'
git show "6c4ab58^:server/Cargo.lock" | grep 'source = "git+'
```

(In PowerShell, al posto di `grep 'source = "git+'` si scrive
`Select-String -SimpleMatch 'source = "git+'`.)

**Client — `client/third_party/`** (32 repository; 26 sono sotto `rustdesk-org`)

| Cartella | Repository | Ramo o revisione richiesti (dal vecchio `Cargo.lock`) | Commit |
|---|---|---|---|
| `android-wakelock` | `github.com/rustdesk-org/android-wakelock` | — | `d0292e5a367e627c4fa6f1ca6bdfad005dca7d90` |
| `arboard` | `github.com/rustdesk-org/arboard` | — | `c7d5781f563176df9efd8df6287e823fb1b9bed5` |
| `cacao` | `github.com/clslaid/cacao` | ramo `feat/set-file-urls` | `05e1536b0b43aaae308ec72c0eed703e875b7b95` |
| `cidre` | `github.com/yury/cidre.git` | rev `f05c428` | `f05c4288f9870c9fab53272ddafd6ec01c7b2dbf` |
| `clipboard-master` | `github.com/rustdesk-org/clipboard-master` | — | `7762d74e38db37cfeb6ded88c964b9cdbddfb6db` |
| `confy` | `github.com/rustdesk-org/confy` | — | `83db9ec19a2f97e9718aef69e4fc5611bb382479` |
| `core-foundation-rs` | `github.com/madsmtm/core-foundation-rs.git` | rev `7d593d016175755e492a92ef89edca68ac3bd5cd` | `7d593d016175755e492a92ef89edca68ac3bd5cd` |
| `cpal` | `github.com/rustdesk-org/cpal` | ramo `osx-screencapturekit` | `6b374bcaed076750ca8fce6da518ab39b882e14a` |
| `default_net` | `github.com/rustdesk-org/default_net` | — | `78f8f70cd85151a3a2c4a3230d80d5272703c02e` |
| `evdev` | `github.com/rustdesk-org/evdev` | — | `cec616e37790293d2cd2aa54a96601ed6b1b35a9` |
| `fuser` | `github.com/rustdesk-org/fuser` | ramo `refact/tag-0.16.0-cargo-1.75.0` | `a3c0babe4a533f8dbcff5bce59ae7f2424b8d877` |
| `hwcodec` | `github.com/rustdesk-org/hwcodec` | — | `778df1f99597722473b29443bac22ae6c23946fe` |
| `impersonate-system` | `github.com/rustdesk-org/impersonate-system` | — | `2f429010a5a10b1fe5eceb553c6672fd53d20167` |
| `kcp-sys` | `github.com/rustdesk-org/kcp-sys` | — | `32a6c09fc6223f54aea83981a6aa8995931d29be` |
| `keepawake-rs` | `github.com/rustdesk-org/keepawake-rs` | — | `64d568586dd16551d02120e19668d2b0fec8e3c9` |
| `machine-uid` | `github.com/rustdesk-org/machine-uid` | — | `381ff579c1dc3a6c54db9dfec47c44bcb0246542` |
| `magnum-opus` | `github.com/rustdesk-org/magnum-opus` | — | `588c6e1f9ed50c3a01fa64f3bd3e7cdb0378a114` |
| `nokhwa` | `github.com/rustdesk-org/nokhwa.git` | ramo `fix_from_raw_parts` | `c2f74662b6ce117f7f94301693fdfadc0b1ec91a` |
| `parity-tokio-ipc` | `github.com/rustdesk-org/parity-tokio-ipc` | — | `d0ae39bffe5d5a3e8d82a1b6bcb1ca5a9b2f1c01` |
| `pulsectl` | `github.com/rustdesk-org/pulsectl` | — | `aa34dde499aa912a3abc5289cc0b547bd07dd6e2` |
| `rdev` | `github.com/rustdesk-org/rdev` | — | `23e24dd6b35452a495dae0ae6d99395e9755ab0f` |
| `rust-sciter` | `github.com/rustdesk-org/rust-sciter` | ramo `dyn` | `5322f3a755a0e6bf999fbc60d1efc35246c0f821` |
| `rust-webm` | `github.com/rustdesk-org/rust-webm` | — | `d2c4d3ac133c7b0e4c0f656da710b48391981e64` |
| `sysinfo` | `github.com/rustdesk-org/sysinfo` | ramo `rlim_max` | `90b1705d909a4902dbbbdea37ee64db17841077d` |
| `tao` | `github.com/rustdesk-org/tao` | ramo `dev` | `288c219cb0527e509590c2b2d8e7072aa9feb2d3` |
| `The-Fat-Controller` | `github.com/rustdesk-org/The-Fat-Controller` | ramo `history/rebase_upstream_20240722` | `78bb80a8e596e4c14ae57c8448f5fca75f91f2b0` |
| `tokio-socks` | `github.com/rustdesk-org/tokio-socks` | — | `bdb9aa3de5bac41602d0742b8ef6bbc6bfebd127` |
| `tray-icon` | `github.com/tauri-apps/tray-icon` | — | `0a5835b0e6828e37a1f781de9c2d671ae7a939e6` |
| `wallpaper.rs` | `github.com/rustdesk-org/wallpaper.rs` | — | `ce4a0cd3f58327c7cc44d15a63706fb0c022bacf` |
| `wezterm` | `github.com/rustdesk-org/wezterm` | ramo `rustdesk/pty_based_0.8.1` | `80174f8009f41565f0fa8c66dab90d4f9211ae16` |
| `x11-clipboard` | `github.com/clslaid/x11-clipboard` | ramo `feat/store-batch` | `5fc2e73bc01ada3681159b34cf3ea8f0d14cd904` |
| `x11-rs` | `github.com/bjornsnoen/x11-rs` | — | `c2e9bfaa7b196938f8700245564d8ac5d447786a` |

A queste si aggiunge `libdrmtap`: `github.com/rustdesk-org/libdrmtap`, commit
`5da68a3a368db569716d0d0f11cefacbb11b2290` (vedi la sezione in fondo).

**Centralino — `server/third_party/`** (7 repository)

| Cartella | Repository | Ramo richiesto (dal vecchio `Cargo.lock`) | Commit |
|---|---|---|---|
| `async-speed-limit` | `github.com/open-trade/async-speed-limit` | — | `f89f702ae01d4016429543d2f0dda1086157e420` |
| `confy` | `github.com/rustdesk-org/confy` | — | `83db9ec19a2f97e9718aef69e4fc5611bb382479` |
| `default_net` | `github.com/rustdesk-org/default_net` | — | `78f8f70cd85151a3a2c4a3230d80d5272703c02e` |
| `machine-uid` | `github.com/rustdesk-org/machine-uid` | — | `381ff579c1dc3a6c54db9dfec47c44bcb0246542` |
| `reqwest` | `github.com/rustdesk-org/reqwest` | — | `9cb758c9fb2f4edc62eb790acfd45a6a3da21ed3` |
| `sysinfo` | `github.com/rustdesk-org/sysinfo` | ramo `rlim_max` | `90b1705d909a4902dbbbdea37ee64db17841077d` |
| `tokio-socks` | `github.com/rustdesk-org/tokio-socks` | — | `94e97c6d7c93b0bcbfa54f2dc397c1da0a6e43d3` |

Attenzione a un dettaglio: cinque librerie stanno **sia** nel client **sia** nel centralino, come
copie separate. Quattro sono allo stesso commit; `tokio-socks` no (client `bdb9aa3d…`, centralino
`94e97c6d…`). Aggiornarne una non aggiorna l'altra.

## Come si collegano al progetto

Con i blocchi `[patch]` in fondo a `client/Cargo.toml` e `server/Cargo.toml`, che reindirizzano
ogni sorgente git al percorso locale. In `[workspace]` la cartella è dichiarata in `exclude`,
altrimenti Cargo pretenderebbe che ogni crate qui dentro sia un membro del workspace.

Verifica che non sia rimasto nulla da scaricare:

```bash
grep -c 'source = "git+' client/Cargo.lock   # deve dare 0
grep -c 'source = "git+' server/Cargo.lock   # deve dare 0
```

(In PowerShell: `(Select-String -Path client\Cargo.lock -SimpleMatch 'source = "git+').Count`, e
lo stesso per `server\Cargo.lock`. Devono dare 0.)

## Come si aggiorna una libreria

Serve solo se c'è una ragione precisa — tipicamente una correzione di sicurezza. Non esiste più un
`cargo update` che lo faccia da solo, ed è voluto.

```bash
cd client/third_party
rm -rf <nome>
mkdir <nome> && cd <nome>
git init && git remote add origin <url-dal-blocco-patch>
git fetch --depth 1 origin <nuovo-commit>
git checkout <nuovo-commit>
git submodule update --init --recursive --depth 1   # solo se ha sottomoduli
find . -name .git -prune -exec rm -rf {} +          # toglie .git, anche dentro i sottomoduli
rm -f .gitmodules
echo <nuovo-commit> > .commit-originale
cd ../.. && cargo check --release --features flutter,hwcodec
```

Quattro cose da non dimenticare, che i comandi qui sopra non fanno da soli:

1. **Tutti i `.git`, non solo il primo.** Un sottomodulo lascia nella propria cartella un piccolo
   *file* che si chiama `.git`: se resta, git tratta quella cartella come un sottomodulo. Per
   questo il comando è `find ... -name .git`, e non un semplice `rm -rf .git`. Prima di fare
   commit controlla, dalla radice del repository, che
   `find client/third_party server/third_party -name .git` non stampi niente.
2. **Controlla che `.gitignore` non scarti file che servono.** A decidere che cosa git pubblica
   sono sia le regole del progetto (che escludono, fra l'altro, `*.dll`, `*.lib`, `*.so`, `*.exe`,
   `*.zip` e qualunque cosa si chiami `rustdesk`) sia i file `.gitignore` che ogni libreria si
   porta dietro. Dalla radice del repository:
   ```bash
   git status --short --ignored client/third_party/<nome>
   ```
   Le righe che cominciano con `!!` sono file presenti sul disco ma che git **non** pubblicherà.
   Oggi sono 24 nel client e 1 nel centralino: cartelle di editor, file `Cargo.lock` di
   sotto-progetti, binari di esempio (`hwcodec/externals/SDL/lib`), file di prova e di
   costruzione di `libwebm` e, dentro `libdrmtap`, `AGENTS.md` e due cartelle chiamate `rustdesk`.
   Dalla lettura degli script di compilazione (`build.rs`, `meson.build`) nessuno di questi serve
   a compilare.
3. **Aggiorna la tabella dei commit** in questo file, e ricorda che la stessa libreria può avere
   una seconda copia in `server/third_party/`.
4. **`Cargo.lock` può cambiare.** Se la libreria nuova ha un numero di versione o delle dipendenze
   diverse, `cargo check` aggiorna `Cargo.lock`: va messo nello stesso commit, perché `build.py`
   compila con `--locked` e si ferma se il lock non corrisponde.

Per `wezterm`, dopo il clone vanno tenute solo le cartelle `filedescriptor` e `pty` e il file
`LICENSE.md`, come adesso.

## Licenze

I file di licenza presenti **non vanno rimossi**: distribuire questo codice senza i suoi avvisi di
licenza è violazione di copyright, indipendentemente dal fatto che il repository sia nostro.

La prima stesura di questo file diceva: «Ogni cartella conserva il proprio file di licenza. Sono
licenze permissive (MIT, Apache-2.0) o AGPL-3.0». Controllando cartella per cartella
(10/11/2026) risulta vero per la maggior parte, ma non per tutte. Lo stato reale:

- **28 cartelle su 33** del client e **6 su 7** del centralino hanno il proprio file di licenza.
  Sono quasi tutte MIT, Apache-2.0 o entrambe a scelta. Nessuna è AGPL.
- **Licenze diverse da MIT/Apache**, da conoscere:
  - `pulsectl` — GPL versione 3 o successiva (`LICENSE.md`);
  - `cacao` — MIT oppure MPL-2.0, a scelta (ci sono entrambi i file);
  - `rust-webm` — MPL-2.0 secondo il suo `Cargo.toml`, ma senza file di licenza proprio; la
    libreria `libwebm` che contiene ha il suo (`src/sys/libwebm/LICENSE.TXT`, di Google, più
    `PATENTS.TXT`);
  - `wallpaper.rs` — Unlicense, cioè pubblico dominio (file `unlicense`).
- **Cartelle senza nessun file di licenza:**
  - `evdev` — nessun file, ma il suo `Cargo.toml` dichiara «Apache-2.0 OR MIT»;
  - `default_net` (sia nel client sia nel centralino), `hwcodec`, `impersonate-system` — nessun
    file e nessuna licenza dichiarata nel `Cargo.toml`. Sono repository di `rustdesk-org`.
- **`hwcodec/externals`** merita un discorso a parte. Contiene materiale di altri produttori:
  AMD (`AMF_v1.4.35`), Intel (`MediaSDK_22.5.4`), NVIDIA (`Video_Codec_SDK_12.1.14`,
  `nv-codec-headers_n12.1.14.0`, `nvEncDXGIOutputDuplicationSample`) e SDL. In nessuna di quelle
  sei cartelle c'è un file di licenza a sé; 346 file su 359 portano però un avviso di copyright
  scritto in testa al file stesso, in molti casi insieme al testo della licenza.

Che cosa comporti tutto questo per un repository **pubblico** come il nostro non è una
valutazione che si possa fare leggendo il codice: **[DA DECIDERE dal proprietario: far valutare a
chi ha competenza legale le cartelle senza licenza e il contenuto di `hwcodec/externals`]**.
Finché la valutazione non c'è, la regola resta quella in cima: non togliere e non modificare
nessun avviso.

## `libdrmtap`

Caso a parte. Serve solo alla variante Linux per l'accesso non presidiato su Wayland
(`build.py --drm`) e non è un crate Rust ma una libreria C costruita con meson. Prima `build.py` la
scaricava da `rustdesk-org/libdrmtap` a ogni build e `.gitignore` la escludeva.

Adesso è qui, al commit `5da68a3a36` (libdrmtap 0.5.4), come albero **non-git**: `build.py` in quel
caso salta sia il download sia la verifica del commit e usa quello che trova, quindi non serve
nessuna modifica al codice di build. Il commit è registrato in `.commit-originale`.

Due avvertenze:

- **Il vecchio download è ancora scritto in `build.py`.** Se questa cartella venisse tolta, o le
  mancasse il file `meson.build`, `build.py --drm` tornerebbe a scaricarla da
  `github.com/rustdesk-org/libdrmtap` senza avvisare (funzione `build_libdrmtap_so`).
- **La variante `--drm` non è ancora stata costruita né provata.** Il pacchetto che produrrebbe si
  chiama `mtdesk-unattended-wayland`.

## Cosa NON è ancora qui dentro

Portare qui le librerie Rust ha tolto la dipendenza più scomoda, non tutte. Una compilazione
scarica ancora:

**1. Nove pacchetti Flutter da repository GitHub di terzi** (8 sotto `rustdesk-org`). Sono
dichiarati in `client/flutter/pubspec.yaml` con `git:` e li scarica `flutter pub get`. Vale lo
stesso discorso fatto sopra per le librerie Rust: se quei repository spariscono, il programma non
si compila più.

| Pacchetto | Repository | Fissato in `pubspec.yaml`? | Commit usato (da `pubspec.lock`) |
|---|---|---|---|
| `dash_chat_2` | `github.com/rustdesk-org/Dash-Chat-2` | **no** | `bd6b5b41254e57c5bcece202ebfb234de63e6487` |
| `desktop_multi_window` | `github.com/rustdesk-org/rustdesk_desktop_multi_window` | **no** | `533883bcb0ffe91a9afdb13b8bac9b14b3e054ba` |
| `window_manager` | `github.com/rustdesk-org/window_manager` | **no** | `cf4aef0512092fad9344a27ffe1c47ad83269dfc` |
| `dynamic_layouts` | `github.com/rustdesk-org/dynamic_layouts.git` | sì | `24cb88413fa5181d949ddacbb30a65d5c459e7d9` |
| `flutter_custom_cursor` | `github.com/rustdesk-org/flutter_custom_cursor` | sì | `db63b785c38153603e9fb84b50d3ec46f0d7e05e` |
| `flutter_gpu_texture_renderer` | `github.com/rustdesk-org/flutter_gpu_texture_renderer` | sì | `08a471bb8ceccdd50483c81cdfa8b81b07b14b87` |
| `texture_rgba_renderer` | `github.com/rustdesk-org/flutter_texture_rgba_renderer` | sì | `42797e0f03141dc2b585f76c64a13974508058b4` |
| `uni_links` | `github.com/rustdesk-org/uni_links` (sottocartella `uni_links`) | sì | `f416118d843a7e9ed117c7bb7bdc2deda5a9e86f` |
| `window_size` | `github.com/21pages/flutter-desktop-embedding.git` (sottocartella `plugins/window_size`) | sì | `51e67ce047c72b26810b99e8473ddb44612fe356` |

I tre segnati «no» non hanno la riga `ref:` in `pubspec.yaml`: a tenerli fermi è soltanto
`pubspec.lock`. Finché quel file resta com'è, `flutter pub get` prende sempre lo stesso commit; un
`flutter pub upgrade` invece li porterebbe all'ultima versione pubblicata da altri. Il rimedio
definitivo è lo stesso usato per le librerie Rust: copiare i 9 pacchetti nel repository e passare
in `pubspec.yaml` da `git:` a `path:`. **Non è ancora stato fatto.**

**2. Le librerie native, tramite vcpkg.** Il programma `vcpkg` viene clonato da
`github.com/microsoft/vcpkg` al commit `9e593bb18ea69cc5095e012465dcd675a822ed0d`, e a sua volta
scarica e compila i sorgenti di ffmpeg, aom, libvpx, opus, libyuv, libjpeg-turbo e mfx-dispatch
(l'elenco è in `client/vcpkg.json`).

**3. I pacchetti dei registri pubblici:** 992 crate da crates.io per il client e 565 per il
centralino (versione e impronta fissate nei due `Cargo.lock`), e 199 pacchetti da pub.dev
(versione e impronta fissate in `client/flutter/pubspec.lock`).

**4. Gli strumenti:** Rust, l'SDK di Flutter, LLVM, NASM (vedi `client/BUILD-WINDOWS.md` e
`BUILD-UBUNTU.md` nella radice del repository) e, per la compilazione su GitHub, le 11 "action"
usate dal workflow (`.github/workflows/mtdesk-build.yml`): 4 di GitHub e 7 di terzi, ciascuna
fissata a un commit preciso.

I punti 2, 3 e 4 riguardano registri pubblici e fornitori degli strumenti, con versioni fissate: è
una dipendenza di natura diversa da quella dai repository di `rustdesk-org`, di cui ci si è
liberati per le librerie Rust. Ma è giusto sapere che ci sono: la frase «la build non contatta più
nessuno», che stava in cima a questo file, non era esatta.

## A che punto sono le prove

- **Compilazione con queste librerie su Windows:** riuscita sul PC di sviluppo il 10/11/2026.
- **Compilazione su Ubuntu:** riuscita il 10/11/2026 in un contenitore `ubuntu:22.04`, con
  successiva installazione del pacchetto (lo riporta il messaggio del commit `84d5df3`).
- **Compilazione su GitHub Actions: non ancora.** L'unica esecuzione del workflow si è fermata nel
  lavoro Ubuntu al passo di vcpkg, cioè prima di arrivare a compilare queste librerie, e il lavoro
  Windows non è mai partito. Una esecuzione che arriva in fondo sarà la conferma definitiva che un
  clone pulito del repository contiene tutto quello che serve.
