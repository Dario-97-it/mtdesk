# MTDesk — Modifiche di rebrand applicate (fork RustDesk 1.4.9)

Elenco preciso delle modifiche fatte al sorgente RustDesk per ottenere **MTDesk**.
Utile per manutenzione e per re-applicarle dopo un aggiornamento upstream.

**Origine e paternità delle modifiche** (è la dichiarazione richiesta dall'art. 5(a) AGPL-3.0):
MTDesk è un'opera derivata di [RustDesk](https://github.com/rustdesk/rustdesk), basata sulla
versione **1.4.9**, modificata da **Marketing Tools** (marketingtools.digital) **a partire da
agosto 2026**. Questo file è l'elenco delle modifiche. MTDesk non è affiliato né sostenuto
dal progetto RustDesk.

## 1. Nome app (leva principale)
- `libs/hbb_common/src/config.rs` L72 — `APP_NAME` default `"RustDesk"` → **`"MTDesk"`**
  → rinomina automaticamente ~250 stringhe UI (tray, menu, titoli, About, ~52 lingue) a runtime.

## 2. Server hardcoded (self-host, connessione automatica)
- `libs/hbb_common/src/config.rs`
  - L117 `RENDEZVOUS_SERVERS` → `&["mtdesk.marketingtools.digital"]`  ← **CAMBIA con il tuo host/VPS**
  - L118 `RS_PUB_KEY` → `"jc63wRwdyqs465Ndu5fP61fvB4x4CHdIAIIpw6YrQcw="`  ← chiave del tuo server

## 3. Stringhe UI hardcoded (non coperte dalla sostituzione automatica)
- `flutter/lib/desktop/widgets/tabbar_widget.dart` — title bar `"RustDesk"` → `"MTDesk"`
- `src/auth_2fa.rs` — `ISSUER` TOTP → `"MTDesk"`
- `src/platform/windows.rs` — caption MessageBox → `"MTDesk Output"`
- `src/whiteboard/windows.rs` — titolo finestra → `"MTDesk whiteboard"`
- `flutter/windows/runner/main.cpp` — fallback `app_name` → `L"MTDesk"`
- `src/lang/*.rs` (40 file) — `powered_by_me`: "Powered by RustDesk" → **"Powered by MTDesk"**

## 4. Metadati eseguibile (proprietà file Windows)
- `flutter/windows/runner/Runner.rc`
  - ProductName → `MTDesk`
  - FileDescription → `MTDesk Remote Desktop`
  - CompanyName → `Marketing Tools`
  - LegalCopyright → `© 2026 Marketing Tools - basato su RustDesk (AGPL-3.0)`
  - (InternalName/OriginalFilename `rustdesk`/`rustdesk.exe` lasciati invariati = tecnici)

## 5. Tema / colori brand (glassmorphism marketingtools.digital)
- `flutter/lib/common.dart` (classe MyTheme)
  - accent `#0071FF` → **`#00BCD4`** (ciano brand) + varianti accent50/accent80
  - button `#2C8CFF` → `#00BCD4`
  - idColor `#00B6F0` → `#22D3EE`
  - scaffold/dialog dark base `#18191E` → **`#0A0A14`**

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
  `build_flutter_deb`), a partire dai PNG in `res/` e da `brand/icons/`.
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
  `/usr/share/rustdesk` a `/usr/share/mtdesk` (e aggiornare `src/ui.rs` e
  `libs/scrap/src/common/drmtap_dl.rs`, che contengono quel percorso scritto a mano).

> Perché serve anche lato cliente: l'assistenza si fa da PC Windows **e** Ubuntu, e ci sono
> clienti su Ubuntu. Quindi il pacchetto Linux deve essere presentabile come quello Windows,
> non un ripiego per sviluppatori. macOS è fuori dal progetto.

## 8. Controllo aggiornamenti (banner)

RustDesk di serie interroga il **server degli aggiornamenti di RustDesk**
(`api.rustdesk.com`) per sapere se esiste una versione più recente, e in caso mostra un
avviso che porta a scaricare **RustDesk**, non MTDesk. In un fork questo è doppiamente
sbagliato: manda l'utente su un programma diverso e fa uscire una chiamata di rete verso un
servizio di terzi che non è il nostro.

La categoria di modifica riguarda la funzione di controllo versione nel core Rust
(`src/common.rs`, funzioni `check_software_update` / `do_check_software_update`, esposte alla
UI da `src/flutter_ffi.rs` e mostrate dal banner lato Flutter in `flutter/lib/`):
il controllo va **ripuntato sulle Release di MTDesk** — cioè sul repository
`https://github.com/Dario-97-it/mtdesk` — oppure disattivato del tutto, così che il banner
proponga l'aggiornamento corretto (`MTDesk-windows-x86_64.exe`, `MTDesk-qs.exe`,
`mtdesk-ubuntu-amd64.deb`) e nessun dato esca verso `api.rustdesk.com`.

Nota tecnica utile per chi rimette mano al codice: `check_software_update` esce subito se
`is_custom_client()` è vero, quindi il comportamento del banner dipende anche da come il
client è stato compilato, non solo dall'URL.

## NON modificato di proposito (rischio/tecnico)
- Nomi crate/pacchetto: `rustdesk`, `librustdesk`, `flutter_hbb`, bundle id `com.carriez.*`,
  la cartella `/usr/share/rustdesk` e il nome dell'eseguibile su **Windows**
  (`flutter/windows/CMakeLists.txt` riga 7, ancora `rustdesk`).
  Sono nomi interni che l'utente non vede: rinominarli tutti = alto rischio, non necessario.
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
