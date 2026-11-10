# MTDesk — Modifiche di rebrand applicate (fork RustDesk 1.4.9)

Elenco preciso delle modifiche fatte al sorgente RustDesk per ottenere **MTDesk**.
Utile per manutenzione e per re-applicarle dopo un aggiornamento upstream.

**Origine e paternità delle modifiche** (è la dichiarazione richiesta dall'art. 5(a) AGPL-3.0):
MTDesk è un'opera derivata di [RustDesk](https://github.com/rustdesk/rustdesk), basata sul suo
codice sorgente con numero di versione **1.4.9**, modificata da **Marketing Tools**
(marketingtools.digital) **a partire da agosto 2026**. Questo file è l'elenco ragionato delle
modifiche; l'elenco riga per riga lo dà git (vedi «Come verificare questo elenco», più sotto).
MTDesk non è affiliato né sostenuto dal progetto RustDesk.

### Da quale codice si è partiti, esattamente

Il numero di versione scritto nel codice è **1.4.9** (`Cargo.toml`), ma il punto di partenza
**non è la versione 1.4.9 ufficiale**: è il ramo principale di RustDesk com'era il 25 agosto 2026,
cioè **120 commit dopo** quella versione. Dentro MTDesk ci sono quindi anche le correzioni e le
novità che RustDesk ha aggiunto fra il 6 luglio e il 25 agosto 2026.

| Parte di MTDesk | Repository di origine | Commit di partenza | Data del commit |
|---|---|---|---|
| `client/` | `github.com/rustdesk/rustdesk`, ramo `master` | `cec4085238ee723b75095e94014e8595f374688b` | 25/08/2026 |
| `client/libs/hbb_common/` e la sua copia `server/libs/hbb_common/` | `github.com/rustdesk/hbb_common` | `b2b1ac453d1d694046f63be20d792d608dac1c93` | 14/08/2026 |
| `server/` | `github.com/rustdesk/rustdesk-server`, ramo `master` | `a7736be5e40f85bfc141120dce587e836e5d4b80` | 07/08/2026 |

Per confronto: la versione 1.4.9 ufficiale di RustDesk è il commit
`6c578292e8ebbbec708b76986ba8c4bc7c509747`, del 6 luglio 2026.

**Come lo sappiamo.** Quando il codice è stato portato in questo repository (commit `9006c66`) il
commit di partenza non era stato annotato da nessuna parte. È stato ricostruito il 10/11/2026
confrontando, file per file, il contenuto importato con quello pubblico su GitHub:

- `client/`: 834 file su 928 identici; i 74 diversi sono i file toccati dal rebrand (sezioni 1-8)
  più tre file di servizio (`.gitignore`, `.gitattributes`, `flutter/pubspec.lock`); i 20 che
  mancano sono quelli tolti di proposito o esclusi da `.gitignore` (i workflow e i file di
  progetto di RustDesk, vedi sezione 11);
- `hbb_common`: 32 file su 33 identici; l'unico diverso è `src/config.rs` (sezioni 1 e 2);
- `server/`: 104 file su 111 identici e nessuno diverso; i 7 che mancano sono file esclusi da
  `.gitignore` o tolti di proposito.

Un dettaglio che serve a chi aggiorna: per il centralino RustDesk usava un'altra versione di
`hbb_common` (commit `69cea8dafee147848ae88702029f4bf7df7224c3`). MTDesk ha messo anche lì la
copia del client, quella della tabella.

Per ripetere il confronto: il contenuto di ciascun commit si sfoglia su GitHub all'indirizzo
`https://github.com/rustdesk/rustdesk/tree/<commit>` (e allo stesso modo per gli altri due
repository).

## 1. Nome app (leva principale)
- `libs/hbb_common/src/config.rs` L72 — `APP_NAME` default `"RustDesk"` → **`"MTDesk"`**
  → rinomina automaticamente ~250 stringhe UI (tray, menu, titoli, About, ~52 lingue) a runtime.

## 2. Server hardcoded (self-host, connessione automatica)
- `libs/hbb_common/src/config.rs`
  - L118 `RENDEZVOUS_SERVERS` → `&["mtdesk.marketingtools.digital"]`  ← **CAMBIA con il tuo host/VPS**
  - L119 `RS_PUB_KEY` → `"jc63wRwdyqs465Ndu5fP61fvB4x4CHdIAIIpw6YrQcw="`  ← chiave del tuo server

(I numeri di riga di questa sezione e della precedente valgono al commit `0f8c020`. Si spostano
ogni volta che qualcuno aggiunge righe più in alto nel file: a fare fede è il nome della costante.)

Da sapere:

- **La chiave è quella giusta:** combacia con `../deploy/data/id_ed25519.pub`, la chiave pubblica
  del centralino (quella cartella è esclusa da git perché contiene anche la chiave privata).
- **L'indirizzo, a novembre 2026, non porta ancora da nessuna parte:**
  `mtdesk.marketingtools.digital` non esiste in DNS e il centralino su VPS non è mai stato messo in
  opera. Finché è così, un MTDesk appena installato non si collega: il centralino va indicato a
  mano, da Impostazioni → Rete → «Server ID/Relay». Per le prove in rete locale c'è
  `../deploy/avvia-centralino-locale.ps1`.
- **Queste due righe esistono in due copie**, `client/libs/hbb_common` e `server/libs/hbb_common`,
  che devono restare identiche (sezione 11).

## 3. Stringhe UI hardcoded (non coperte dalla sostituzione automatica)
- `flutter/lib/desktop/widgets/tabbar_widget.dart` — title bar `"RustDesk"` → `"MTDesk"`
- `src/auth_2fa.rs` — `ISSUER` TOTP → `"MTDesk"`
- `src/platform/windows.rs` — caption MessageBox → `"MTDesk Output"`
- `src/whiteboard/windows.rs` — titolo finestra → `"MTDesk whiteboard"`
- `flutter/windows/runner/main.cpp` — fallback `app_name` → `L"MTDesk"`
- `src/lang/*.rs` (40 file) — `powered_by_me`: "Powered by RustDesk" → **"Powered by MTDesk"**

## 4. Metadati eseguibile (proprietà file Windows)
- `flutter/windows/runner/Runner.rc` — sono le proprietà di `MTDesk.exe`, l'eseguibile del programma
  - ProductName → `MTDesk`
  - FileDescription → `MTDesk Remote Desktop`
  - CompanyName → `Marketing Tools`
  - LegalCopyright → `© 2026 Marketing Tools - basato su RustDesk (AGPL-3.0)`
  - InternalName → `MTDesk` e OriginalFilename → `MTDesk.exe` (fino a novembre 2026 erano rimasti
    `rustdesk` / `rustdesk.exe`)
- `libs/portable/Cargo.toml`, sezione `[package.metadata.winres]` — sono le proprietà dei **due
  file che si distribuiscono** (`MTDesk-windows-x86_64-install.exe` e `MTDesk-qs.exe`)
  - ProductName → `MTDesk`, FileDescription → `MTDesk Remote Desktop`, LegalCopyright come sopra,
    OriginalFilename → `MTDesk.exe`
  - **Non dichiarati:** CompanyName e InternalName. Nelle proprietà dei due file distribuiti quei
    due campi risultano vuoti (controllato sui file prodotti il 10/11/2026).

## 5. Tema / colori brand (glassmorphism marketingtools.digital)
- `flutter/lib/common.dart` (classe MyTheme)
  - accent `#0071FF` → **`#00BCD4`** (ciano brand) + varianti accent50/accent80
  - button `#2C8CFF` → `#00BCD4`
  - idColor `#00B6F0` → `#22D3EE`
  - sfondo scuro della finestra `#18191E` → **`#0A0A14`**
  - (novembre 2026) scala completa delle superfici scure, dichiarata in testa alla classe: `bgDeep`
    `#0A0A14` (sfondo finestra), `bgSurface` `#0F0F1E` (pannelli e dialoghi), `bgElevated` `#161628`
    (campi di testo, pulsanti con bordo), `bgCard` `#1A1A2E` (card), `bgHover` `#1F1F38`,
    `brandBorder` (bianco al 10%). Sostituiscono il grigio-bruno di RustDesk (`#24252B`), che era
    rimasto su tutto ciò che sta sopra lo sfondo
  - (novembre 2026) gradiente firma `brandGradient` / `brandGradientVertical` (verde `#2ECC71`,
    ciano `#00BCD4`, blu `#2196F3`, viola `#9C27B0`, arancio `#FF9800`) e `brandGradientWarm` per
    gli avvisi
  - (novembre 2026) tema **scuro per default**: `defaultOptionTheme` da `'system'` a `'dark'`.
    L'utente può comunque cambiarlo dalle impostazioni
- `flutter/lib/desktop/pages/desktop_home_page.dart` — barrette accanto a ID e password con il
  gradiente del brand; card di avviso ridisegnata nei colori del brand
- `flutter/windows/runner/win32_window.cpp` — sfondo nativo della finestra `#0A0A14`: prima la
  finestra restava bianca finché Flutter non disegnava il primo fotogramma
- **Non fatto:** il font Inter del brand. Non è fra i font dichiarati in `flutter/pubspec.yaml`.

## 6. Icone / logo
- `res/icon.png`, `res/mac-icon.png` (master 1024) → icona MTDesk
- `res/icon.ico`, `flutter/windows/runner/resources/app_icon.ico`, `res/tray-icon.ico` → .ico MTDesk
- `flutter/assets/icon.svg` → mark MTDesk (due schermi connessi, gradiente brand)
- `flutter/assets/logo.png` (+ logo_dark/logo_light) → wordmark "MTDesk" (NUOVI)

## 7. Linux / Ubuntu — pacchetto e integrazione con il desktop

Su Windows basta il nome dell'app dentro l'exe; su Linux il nome del programma è scritto in
**più file separati**, che il sistema legge in momenti diversi (menu applicazioni, avvio
automatico, gestore pacchetti). Vanno ribrandizzati tutti, altrimenti l'utente installa
"MTDesk" e nel menu gli compare "RustDesk".

Le categorie di file toccate (i percorsi sono quelli della cartella `client/`):

- **Voce del menu applicazioni** — i file `.desktop` in `res/`
  (`rustdesk.desktop` per l'app, `rustdesk-link.desktop` per l'associazione ai link
  `mtdesk://`). I **nomi dei file sorgente restano quelli di upstream**: e' il pacchetto
  che li installa con il nome nuovo (vedi la tabella qui sotto), perche' lo stesso file
  sorgente e' usato anche dalle ricette per Arch/Fedora/SUSE in `res/`, che non vanno rotte.
  Qui si cambiano i campi `Name`, `GenericName`, `Comment`, `Icon` e il nome delle azioni:
  è il testo che Ubuntu mostra nel menu, nella barra delle applicazioni e nel titolo della
  finestra "Apri con".
- **Servizio di sistema (systemd)** — il file `.service` in `res/`.
  È il servizio che tiene MTDesk attivo anche prima del login, cioè quello che rende
  possibile l'accesso non presidiato. Si aggiornano la `Description` e i percorsi/nomi
  coerenti con il pacchetto.
- **Control file del pacchetto Debian** — generato da `build.py`
  (funzione `generate_control_file`, che scrive `res/DEBIAN/control`) più gli script
  `res/DEBIAN/postinst`, `prerm`, `postrm`, `preinst`.
  Sono i metadati che `apt` mostra durante l'installazione: `Package`, `Maintainer`,
  `Description`. Il nome del pacchetto è anche quello che si digita per disinstallare.
- **Titoli delle finestre GTK** — `flutter/linux/my_application.cc`.
  Contiene il titolo impostato sulla barra della finestra e il nome con cui l'app cerca la
  propria icona nel tema di sistema: se questo nome non combacia con quello dei file
  installati (punto seguente), la finestra resta con l'icona generica.
- **Icone nel tema hicolor** — le icone installate dal `.deb` sotto
  `/usr/share/icons/hicolor/<misura>/apps/` (lo staging avviene in `build.py`, funzione
  `build_flutter_deb`), a partire dai PNG in `res/` e da `../brand/icons/`.
  È lo standard freedesktop: senza queste, il menu di Ubuntu mostra un rettangolo vuoto.
- **Artefatto di rilascio** — il `.deb` prodotto viene pubblicato come
  **`mtdesk-ubuntu-amd64.deb`** (nome stabile, senza numero di versione, così i link
  `/releases/latest/download/...` non si rompono a ogni release).
  `build.py` lo produce come `mtdesk-<versione>.deb`: la rinomina al nome stabile la fa
  il workflow di GitHub Actions al momento della pubblicazione.

### Come il file sorgente diventa il file installato

Il nome a sinistra è quello nel repository, quello a destra è il nome che finisce sul PC
del cliente. La colonna di destra **non è cosmetica**: quei nomi sono esattamente quelli
che il programma si va a cercare da solo (vedi la nota "due cose che SONO cambiate").

| file nel repository | dove finisce sul PC del cliente |
|---|---|
| `res/rustdesk.desktop` | `/usr/share/applications/mtdesk.desktop` |
| `res/rustdesk-link.desktop` | `/usr/share/applications/mtdesk-link.desktop` |
| `res/rustdesk.service` | `/usr/lib/systemd/system/mtdesk.service` |
| `res/128x128@2x.png` | `/usr/share/icons/hicolor/256x256/apps/mtdesk.png` |
| `res/scalable.svg` | `/usr/share/icons/hicolor/scalable/apps/mtdesk.svg` |
| eseguibile compilato | `/usr/share/rustdesk/mtdesk` + collegamento `/usr/bin/mtdesk` |

- **Convivenza con RustDesk ufficiale** — il control file dichiara `Conflicts: rustdesk` e
  `Replaces: rustdesk`. Serve perché MTDesk usa ancora la cartella interna
  `/usr/share/rustdesk`: senza queste due righe, su un PC con RustDesk già installato
  `apt` si fermerebbe con un errore del tipo *"trying to overwrite ..."*. Con queste righe
  invece `apt` disinstalla RustDesk e installa MTDesk al suo posto.
  **Conseguenza da sapere prima di installare da un cliente:** i due programmi non possono
  convivere. Se un cliente usa RustDesk con un altro fornitore, installare MTDesk glielo
  rimuove. Per permettere la convivenza bisognerebbe spostare tutto da
  `/usr/share/rustdesk` a `/usr/share/mtdesk`. Quel percorso è scritto a mano in `build.py`
  (in più punti), in `res/DEBIAN/postinst` e in `src/ui.rs` (quest'ultimo vale solo per la
  vecchia interfaccia Sciter). La variante per l'accesso non presidiato su Wayland
  (`build.py --drm`) usa in più la cartella `/usr/lib/rustdesk`, scritta in `build.py` e in
  `libs/scrap/src/common/drmtap_dl.rs`. Le due righe `Conflicts`/`Replaces` si possono togliere
  **solo dopo** lo spostamento, e con un'attenzione: la funzione
  `retarget_control_to_drm_variant` di `build.py` riscrive proprio quelle due righe e si ferma con
  un errore se non le trova.

> Perché serve anche lato cliente: l'assistenza si fa da PC Windows **e** Ubuntu, e ci sono
> clienti su Ubuntu. Quindi il pacchetto Linux deve essere presentabile come quello Windows,
> non un ripiego per sviluppatori. macOS è fuori dal progetto.

## 8. Controllo aggiornamenti (banner)

RustDesk di serie interroga il **server degli aggiornamenti di RustDesk**
(`api.rustdesk.com`) per sapere se esiste una versione più recente, e in caso mostra un
avviso che porta a scaricare **RustDesk**, non MTDesk. In un fork questo è doppiamente
sbagliato: manda l'utente su un programma diverso e fa uscire una chiamata di rete verso un
servizio di terzi che non è il nostro.

Questa sezione, fino a novembre 2026, descriveva il lavoro come ancora da fare. **È stato
fatto**, in due mosse: spento il controllo di RustDesk, aggiunto uno nostro.

**Il controllo di RustDesk è spento.**

- `src/common.rs`, funzione `do_check_software_update` — non contatta più nessuno: azzera
  l'indirizzo dell'aggiornamento e termina subito con un errore. È il punto di blocco unico: da
  lì passano tutti i chiamanti (`check_software_update` nello stesso file, `src/updater.rs`,
  `src/flutter_ffi.rs`, `src/ui.rs`).
- `libs/hbb_common/src/lib.rs`, funzione `version_check_request` — restituisce una richiesta vuota
  e un indirizzo vuoto. Prima costruiva una richiesta verso `api.rustdesk.com` con sistema
  operativo, versione, architettura e un'impronta del PC del cliente.
- `flutter/lib/desktop/pages/desktop_setting_page.dart` — tolta la casella «Auto update». Su
  Windows installato era visibile, e attivarla avviava l'aggiornatore di RustDesk
  (`src/updater.rs`), che avrebbe scaricato e installato RustDesk al posto di MTDesk.

**MTDesk ha un controllo suo**, che avvisa e basta.

- `flutter/lib/mtdesk_update.dart` (file nuovo) — pochi secondi dopo l'avvio legge
  `https://dario-97-it.github.io/mtdesk/version.json`, cioè il file `../docs/version.json` di
  questo repository pubblicato da GitHub Pages. Se il numero di versione scritto lì è più recente di
  quello in uso, nella schermata principale compare un cartellino con il pulsante «Download», che
  apre il browser. Il programma **non scarica e non installa niente da solo, e non invia nessun
  dato**. Se il file non si riesce a leggere non succede nulla: nessun errore a schermo.
- È agganciato in `flutter/lib/main.dart` (`runMainApp` chiama `mtdeskCheckUpdate()`) e mostrato
  da `flutter/lib/desktop/pages/desktop_home_page.dart` (funzione `buildHelpCards`).
- Come si pubblica una versione nuova è spiegato in `../docs/README.md`: si cambia un numero in
  `../docs/version.json`, questo codice non va toccato.

**Stato attuale e limiti, da conoscere:**

- **GitHub Pages non è ancora attivo**, quindi oggi quell'indirizzo risponde 404 e il cartellino
  non compare mai. Il programma lo gestisce in silenzio. Si attiva una volta sola dal sito di
  GitHub: Settings → Pages → ramo `main`, cartella `/docs` (vedi `../docs/README.md`).
- **Chi usa `MTDesk-qs.exe` e preme «Download» riceve l'installer.** Su Windows il programma legge
  solo il campo `download.windows` di `version.json`; il campo `download.windows_qs` esiste nel
  file ma oggi non lo legge nessuno.
- **L'aggiornatore di RustDesk è ancora nel codice, fermo.** `src/updater.rs` non è stato
  modificato, e su Windows installato viene ancora avviato (`src/rendezvous_mediator.rs`, chiamata
  a `start_auto_update()`): si ferma al primo passo perché `do_check_software_update` fallisce
  sempre. Tutta la protezione poggia quindi su quella sola funzione di `src/common.rs`: va
  ricontrollata ogni volta che si porta dentro codice di RustDesk (vedi «Come portare dentro una
  correzione di RustDesk»).

Nota tecnica utile per chi rimette mano al codice: `check_software_update` esce subito se
`is_custom_client()` è vero, e per MTDesk lo è sempre (il nome dell'app non è "RustDesk"). Questo
però non bastava: `src/updater.rs` chiama `do_check_software_update` direttamente, saltando quel
controllo. Per questo il blocco è stato messo dentro `do_check_software_update`.

## 9. Rete: nessuna chiamata e nessun link verso RustDesk

Oltre al controllo aggiornamenti (sezione 8), il programma aveva altri punti da cui partivano
dati o link verso l'infrastruttura di RustDesk. Sono stati chiusi a novembre 2026.

- `src/common.rs`, funzione `get_api_server_` — quando nessun server era impostato ripiegava su
  `https://admin.rustdesk.com`: il pulsante di accesso («Accedi») avrebbe mandato lì le
  credenziali. Ora
  restituisce una stringa vuota: MTDesk **non ha un server API**, il centralino fa solo
  rendezvous e relay.
- `src/common.rs`, funzione `using_public_server` — ora risponde sempre `false`. Prima rispondeva
  `true`, e la schermata principale avvisava di essere "sul server pubblico" offrendo un link al
  listino prezzi di RustDesk.
- `src/common.rs`, funzione `is_public` — confronta con `PUBLIC_API_HOSTS`, una lista vuota. Prima
  riconosceva `rustdesk.com` e i suoi sottodomini.
- `libs/hbb_common/src/config.rs`, funzione `Config::no_register_device` — il default passa da
  `false` a `true`: **il dispositivo non si registra da nessuna parte**. Prima, con un centralino
  personalizzato impostato, il programma spediva le informazioni della macchina a un indirizzo
  ricavato da quello del centralino (porta meno 2), dove MTDesk non ha nessun servizio. Le uniche
  funzioni che questo spegne sono `--assign`, `--deploy` e `deploy_device()`, che richiedono un
  server API e quindi non erano comunque utilizzabili.
- **Link mostrati all'utente** — puntavano a `rustdesk.com`; ora puntano a pagine nostre:
  `https://dario-97-it.github.io/mtdesk/` (le pagine `aiuto.html` e `privacy.html` della cartella
  `../docs/`), `https://marketingtools.digital` e la pagina delle Release di questo repository.
  File toccati: `libs/hbb_common/src/config.rs` (`LINK_DOCS_HOME`, `LINK_DOCS_X11_REQUIRED`),
  `src/client.rs`, `src/lang/en.rs`, `flutter/lib/common.dart`,
  `flutter/lib/desktop/pages/connection_page.dart`, `desktop_home_page.dart`,
  `desktop_setting_page.dart`, `install_page.dart`, e in `flutter/lib/mobile/pages/`
  `connection_page.dart` e `settings_page.dart`.
- **Test** — negli unit test `rustdesk.com` era usato come indirizzo di prova: sostituito con
  `esempio.test` (`libs/hbb_common/src/socket_client.rs`, `websocket.rs`).

Da sapere:

- Finché **GitHub Pages non è attivo** (vedi sezione 8), i link ad aiuto e informativa aprono una
  pagina di errore 404. Fra questi c'è il link che compare nella schermata di installazione.
- `../docs/privacy.html` è una bozza: contiene segnaposto `[DA COMPLETARE]` per i dati del
  titolare, che solo il proprietario può fornire. Nella schermata di installazione il link che la
  apre è ancora etichettato «Contratto di licenza utente finale».
- La vecchia interfaccia Sciter (`src/ui/`) **non** è stata toccata e contiene ancora indirizzi
  `rustdesk.com`: vedi «NON modificato di proposito».

## 10. Windows: nome dell'eseguibile, pacchetto autoestraente, assistenza rapida

- `flutter/windows/CMakeLists.txt` — `BINARY_NAME` da `rustdesk` a **`MTDesk`**: il programma su
  disco e in Gestione attività si chiama `MTDesk.exe`. Non è estetica. L'installazione
  (`install_me` in `src/platform/windows.rs`) copia la cartella del programma così com'è e poi
  crea collegamenti, voce di disinstallazione e servizio che puntano a
  `<cartella>\<nome app>.exe`: con il file chiamato `rustdesk.exe` quel percorso non esisteva.
  **L'installazione non è ancora stata provata su un Windows pulito.**
- `build.py`, funzione `build_flutter_windows` — tre correzioni: passa all'impacchettatore
  `MTDesk.exe`; lo lancia con l'interprete Python in uso invece che con `pip3` e `python3`, che su
  Windows non esistono (la build si fermava subito prima di impacchettare); produce i due file
  con nomi stabili, `MTDesk-windows-x86_64-install.exe` e `MTDesk-qs.exe`. Sono lo stesso file: è
  il nome a decidere se il programma installa o fa assistenza rapida (dettagli in
  `BUILD-WINDOWS.md`, passo 7).
- `libs/portable/src/main.rs` (l'impacchettatore) — tre nomi cambiati:
  - `APP_PREFIX` da `rustdesk` a `MTDesk`: è la cartella in cui il file si scompatta sul PC del
    cliente, `%LOCALAPPDATA%\MTDesk`;
  - la variabile d'ambiente con cui passa al programma il proprio nome di file diventa
    `MTDESK_APPNAME`. Deve restare **identica in tre punti**: qui, in `src/common.rs`
    (`PORTABLE_APPNAME_RUNTIME_ENV_KEY`) e in `flutter/lib/consts.dart`
    (`kEnvPortableExecutable`). Se non combaciano, l'assistenza rapida non si attiva più;
  - il processo di appoggio della modalità privacy diventa `RuntimeBroker_mtdesk.exe`. Deve
    restare **identico in due punti**: qui e in `src/privacy_mode/win_topmost_window.rs`.
- `src/core_main.rs` — **assistenza rapida con finestra compatta.** Quando il programma parte come
  `MTDesk-qs.exe` e non è installato, attiva da solo la modalità "solo connessioni in ingresso"
  che RustDesk ha già (`conn-type=incoming`) e spegne l'invito a installare
  (`disable-installation=Y`). Risultato: finestra piccola con logo, ID, password monouso, «Esci»
  e stato del collegamento, e connessioni in uscita rifiutate.
- `scripts/install-toolchain.ps1` e `scripts/build-mtdesk.ps1` — file nostri, non di RustDesk:
  preparano gli strumenti e compilano (vedi `BUILD-WINDOWS.md`).

Non fatto: l'installer MSI (`res/msi/`) non è stato ribrandizzato e oggi non si costruisce; i
motivi sono in `BUILD-WINDOWS.md`, passo 7.

## 11. Dipendenze e struttura del repository

- **`hbb_common` non è più un sottomodulo git.** In RustDesk la cartella `libs/hbb_common` è un
  puntatore a un altro repository; qui sono file normali, tracciati da questo repository. È lì
  che stanno nome dell'app, indirizzo del centralino e chiave (sezioni 1 e 2): finché era un
  sottomodulo, bastava un `git submodule update` per ritrovarsi il file originale di RustDesk.
  Ne esistono **due copie**, `client/libs/hbb_common` e `server/libs/hbb_common`, che vanno tenute
  uguali a mano. Per controllare, dalla radice del repository:
  ```
  git diff --no-index --stat client/libs/hbb_common server/libs/hbb_common
  ```
  Se non stampa niente, sono identiche.
- **Librerie Rust portate dentro al repository.** Tutti i crate che `Cargo.toml` prendeva da
  repository git (32 repository per il client, 7 per il centralino) ora stanno in
  `third_party/` e in `../server/third_party/`, collegati dai blocchi `[patch]` in fondo ai due
  `Cargo.toml`; in `[workspace]` la cartella è in `exclude`. I due `Cargo.lock` non contengono più
  sorgenti git. Dettagli, elenco dei commit e licenze: `third_party/LEGGIMI.md`.
- **Motore Flutter: quello ufficiale.** `scripts/install-toolchain.ps1` non scarica più il motore
  compilato da RustDesk (`github.com/rustdesk/engine`): si usa quello dello SDK Flutter 3.24.5.
  Limite noto: è verificato che la build passa e che il programma si avvia, non ancora che su
  Windows il video di una sessione si veda bene (`BUILD-WINDOWS.md`, passo 3).
- **File di progetto di RustDesk tolti da `client/`:** i workflow di GitHub Actions, i modelli
  per le segnalazioni, `FUNDING.yml` (raccoglieva donazioni per RustDesk), `.gitmodules`, e i file
  guida `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`. Resta `.github/patches/`, che serve alla build.
- **Cosa arriva ancora da fuori:** 9 pacchetti Flutter dichiarati in `flutter/pubspec.yaml`
  vengono ancora scaricati da repository GitHub di terzi (8 sotto `rustdesk-org`) a ogni
  `flutter pub get`. L'elenco è in `third_party/LEGGIMI.md`.

## 12. Il centralino (`server/`)

Non fa parte del client, ma è anch'esso codice derivato da RustDesk e modificato da noi. Le
modifiche, in breve (il resto è in `../server/README.md`). In questa sezione i percorsi partono
dalla radice del repository, non da `client/`:

- `server/src/common.rs`, funzione `check_software_update` — svuotata. Ogni 24 ore inviava a
  `api.rustdesk.com` sistema, versione, architettura e un'impronta della macchina.
- Testi mostrati da `--help` ribrandizzati (`server/src/common.rs`, `server/src/hbbr.rs`,
  `server/src/main.rs`, `server/src/utils.rs`); lo strumento a riga di comando si chiama
  `mtdesk-utils` (prima `rustdesk-utils`). Nell'autore resta scritto «opera derivata di
  rustdesk-server (AGPL-3.0)».
- Immagine Docker **costruita da questi sorgenti** (`server/Dockerfile`, usato da
  `deploy/docker-compose.yml`) al posto dell'immagine di terzi `rustdesk/rustdesk-server`.
  Tolti i file di impacchettamento di RustDesk (`server/debian/`, `server/docker/`,
  `server/docker-classic/`).
  Stato: una prima prova di costruzione e avvio, fatta il 10/11/2026, ha fatto emergere un
  difetto, corretto nel commit `0f8c020` (lo racconta il messaggio di quel commit). Il centralino
  non è mai stato messo in opera su un VPS: l'immagine non va considerata collaudata.
- 7 librerie portate in `server/third_party/` (sezione 11).

## Come verificare questo elenco

Questo file descrive le modifiche per argomento. Chi vuole la prova riga per riga ha due
strumenti, e conviene dirlo chiaramente perché nessun elenco scritto a mano è completo per
definizione.

- **Tutto ciò che è cambiato dopo l'arrivo del codice in questo repository** (commit `9006c66`,
  10/11/2026) è nella storia di git. Dalla radice del repository:
  ```
  git log --oneline 9006c66..HEAD -- client server
  git diff --stat 9006c66 HEAD -- client ":(exclude)client/third_party"
  ```
  Il primo comando elenca i commit, ognuno con la sua spiegazione (`git show <commit>` per
  leggerla); il secondo elenca i file del client cambiati da allora.
- **Le modifiche fatte prima** (da agosto 2026 al commit `9006c66`: sono le sezioni 1-7 e parte
  della 8) non hanno una storia in git, perché il codice è arrivato in un commit solo. Si vedono
  confrontando il contenuto di quel commit con i commit di partenza della tabella in cima a questo
  file: è il confronto da cui vengono i numeri riportati lì.

## Come portare dentro una correzione di RustDesk

Il codice di partenza è fermo al 25 agosto 2026. RustDesk nel frattempo è andato avanti (il 1°
settembre 2026 il suo ramo principale è passato alla numerazione 1.5.0), e le sue correzioni,
comprese quelle di sicurezza, **non arrivano da sole**: vanno portate dentro una alla volta. Non
esiste più un `git pull` da RustDesk: dal commit `9006c66` questo repository non è più collegato
al loro.

1. **Trova il commit della correzione** su `github.com/rustdesk/rustdesk` (per `hbb_common` e per
   il centralino i repository sono quelli della tabella in cima). Deve essere successivo al
   commit di partenza.
2. **Scaricalo come patch.** Basta aggiungere `.patch` all'indirizzo del commit:
   `https://github.com/rustdesk/rustdesk/commit/<commit>.patch`. Salva il file **fuori** dalla
   cartella del progetto, per esempio come `correzione.patch`: così non rischia di finire in un
   commit per sbaglio.
3. **Prova senza modificare niente.** Dalla radice del repository (al posto di `<percorso>` metti
   la cartella in cui hai salvato il file):
   ```
   git apply --directory=client --check <percorso>/correzione.patch
   ```
   Se non stampa niente, la correzione si applica pulita. Se stampa errori, tocca righe che
   abbiamo modificato noi oppure dipende da altri commit venuti prima: serve qualcuno che sappia
   leggere il codice, non va forzata.
4. **Applicala** togliendo `--check`:
   ```
   git apply --directory=client <percorso>/correzione.patch
   ```
   Per una correzione di `hbb_common` il comando va dato **due volte**, perché le copie sono due:
   una con `--directory=client/libs/hbb_common` e una con `--directory=server/libs/hbb_common`.
   Per una correzione del centralino: `--directory=server`.
5. **Controlla che il rebrand sia ancora al suo posto.** Sono i punti che una correzione di
   RustDesk può riscrivere senza che nessuno se ne accorga:
   ```
   git grep -n -e "APP_NAME: RwLock" -e "pub const RENDEZVOUS_SERVERS" -e "pub const RS_PUB_KEY" -- client/libs/hbb_common/src/config.rs server/libs/hbb_common/src/config.rs
   git grep -n "MTDesk: controllo aggiornamenti di RustDesk disattivato" -- client/src/common.rs
   git grep -n "rustdesk\.com" -- client/src client/flutter/lib client/libs/hbb_common/src server/src server/libs/hbb_common/src ":(exclude)client/src/ui"
   git diff --no-index --stat client/libs/hbb_common server/libs/hbb_common
   ```
   Il primo deve stampare sei righe, tre per ciascuna delle due copie, con i valori delle sezioni 1
   e 2 (`"MTDesk"`, il nostro indirizzo, la nostra chiave): se vi compare `"RustDesk"`, il rebrand
   è stato sovrascritto. Il secondo deve trovare una riga: è il blocco del vecchio controllo
   aggiornamenti (sezione 8). Il terzo oggi trova 9 righe e sono **tutte commenti** che raccontano
   cosa faceva RustDesk: se ne compare una che non è un commento, è un indirizzo di RustDesk
   tornato nel programma. Il quarto non deve stampare niente: vuol dire che le due copie di
   `hbb_common` sono uguali. Il controllo su nome, indirizzo e chiave lo ripete da solo anche il
   lavoro 1 («Controllo brand e centralino») del workflow `../.github/workflows/mtdesk-build.yml`,
   a ogni esecuzione, ma solo sulla copia del client.
6. **Ricompila e prova** (`BUILD-WINDOWS.md`, `../BUILD-UBUNTU.md`), poi **annota qui sotto** il
   commit portato dentro: altrimenti fra qualche mese nessuno saprà più a che punto è il codice
   rispetto a RustDesk.

Correzioni di RustDesk portate dentro dopo il commit di partenza: **nessuna**, al 10/11/2026.

Passare in blocco a una versione più nuova di RustDesk è un lavoro diverso e molto più grosso:
significa ripartire dal loro codice nuovo e rifare tutte le modifiche di questo file, usandolo
come lista di controllo.

## NON modificato di proposito (rischio/tecnico)
- Nomi crate/pacchetto: `rustdesk`, `librustdesk`, `flutter_hbb`, bundle id `com.carriez.*`,
  la cartella `/usr/share/rustdesk`.
  (Il nome dell'eseguibile su Windows NON e' piu' in questo elenco: da novembre 2026 e'
  `MTDesk.exe`, vedi `flutter/windows/CMakeLists.txt`.)
  Sono nomi interni: rinominarli tutti = alto rischio, non necessario. Usando il programma
  l'utente non li incontra, ma chi apre la cartella del programma li vede: su Windows c'è
  `librustdesk.dll` accanto a `MTDesk.exe`, su Linux la cartella `/usr/share/rustdesk`.
- **La vecchia interfaccia "Sciter" (`src/ui/`)**: è l'interfaccia che RustDesk usava prima di
  Flutter. Non entra nel programma che distribuiamo (con l'opzione `flutter` il modulo `ui` è
  escluso dalla compilazione, `src/lib.rs`), quindi non è stata ribrandizzata: contiene ancora
  link a `rustdesk.com` e il copyright «Purslane Tech Pte. Ltd.» (`src/ui/index.tis`,
  `src/ui/install.tis`). Lo stesso vale per i metadati `[package.metadata.winres]` e
  `[package.metadata.bundle]` di `Cargo.toml`, che servono solo a quella build. **Conseguenza
  pratica: `build.py` va lanciato sempre con `--flutter`.** Senza, prende la strada dell'interfaccia
  Sciter, cioè di un programma non ribrandizzato.
- **L'installer MSI (`res/msi/`)**: non ribrandizzato e oggi non costruibile. Mostrerebbe al
  cliente l'informativa privacy di un'altra società. Non va distribuito (`BUILD-WINDOWS.md`,
  passo 7).
- **`src/updater.rs`**, l'aggiornatore automatico di RustDesk: lasciato com'era, ma reso
  inoffensivo bloccando la funzione da cui dipende (sezione 8).
- Note di licenza AGPL nei sorgenti: mantenute (obbligo di legge).

### Attenzione: due cose che invece SONO cambiate
Erano elencate qui sopra come "non modificate", ma non e' vero. Vanno sapute, perche' se
si rimette mano al pacchetto Linux e si torna ai vecchi nomi il programma smette di partire.

- **Su Linux l'eseguibile si chiama `mtdesk`**, non piu' `rustdesk`
  (`flutter/linux/CMakeLists.txt` riga 7). E' proprio quel nome che lo script di installazione
  `res/DEBIAN/postinst` collega a `/usr/bin/mtdesk`, ed e' il comando che le voci di menu
  (`res/rustdesk.desktop`) lanciano con `Exec=mtdesk`.
- **I link cliccabili sono `mtdesk://`, non piu' `rustdesk://`.** Non e' stata una scelta
  fatta a mano: il programma costruisce da solo quel prefisso a partire dal nome dell'app
  (`src/common.rs`, funzione `get_uri_prefix`), quindi e' cambiato nel momento in cui
  `APP_NAME` e' diventato "MTDesk". Per questo `res/rustdesk-link.desktop` dichiara
  `x-scheme-handler/mtdesk`: i due valori devono restare uguali, altrimenti Ubuntu non sa
  quale programma aprire quando si clicca un link di assistenza.

## Licenza
Fork AGPL-3.0. Distribuendo MTDesk ai clienti devi poter fornire il sorgente su richiesta:
per questo il repository <https://github.com/Dario-97-it/mtdesk> è pubblico, ed è l'assolvimento
dell'obbligo. Il testo integrale della licenza è in `LICENCE` (qui) e in `LICENSE` nella radice
del repository: sono lo stesso file.
Il badge UI "Powered by" è stato ribrandizzato (lecito: l'AGPL tutela il sorgente, non il badge).
