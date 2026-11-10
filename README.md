<div align="center">

# MTDesk

**Controllo remoto del desktop, gratuito e senza account.**
Serve a far vedere il proprio schermo a un tecnico — o a prenderne il controllo per dare
assistenza — senza configurazioni complicate e senza passare dai server di terzi.

[![Licenza: AGPL v3](https://img.shields.io/badge/Licenza-AGPL--3.0-00BCD4.svg)](LICENSE)
![Piattaforme](https://img.shields.io/badge/Piattaforme-Windows%20%7C%20Ubuntu-2196F3.svg)

**[Scarica l'ultima versione](https://github.com/Dario-97-it/mtdesk/releases/latest)**

</div>

---

> **A che punto siamo (10 novembre 2026) — da leggere prima del resto.**
> Il programma si compila e una prima sessione vera fra due computer è riuscita (da un PC
> Ubuntu verso un PC Windows, in rete locale), ma la messa in opera non è finita. Oggi mancano
> ancora tre cose e, finché mancano, alcune parti di questa pagina descrivono come MTDesk
> *funzionerà*, non come funziona adesso:
>
> - **Nessuna versione è stata ancora pubblicata.** Il collegamento qui sopra porta a una
>   pagina Releases vuota, e i link di download qui sotto rispondono "pagina non trovata"
>   (errore 404).
> - **Il centralino non è ancora acceso.** È il nostro server, quello che fa incontrare i due
>   computer. L'indirizzo scritto dentro il programma, `mtdesk.marketingtools.digital`, in
>   internet non esiste ancora: un MTDesk appena aperto non riesce a collegarsi (il pallino di
>   stato in basso non diventa verde) finché non gli si indica a mano un centralino di prova.
> - **Le pagine di aiuto e l'avviso di aggiornamento non funzionano ancora**, perché GitHub
>   Pages, il servizio che deve pubblicarle, non è stato attivato.
>
> Che cosa resta da fare, in che ordine e dove è spiegato: sezione
> **[Dal codice al cliente](#dal-codice-al-cliente)**, più sotto. Man mano che un punto viene
> sistemato, la riga corrispondente di questo riquadro va tolta.

---

## Scarica

Tutti i file vengono pubblicati nella pagina **[Releases → latest](https://github.com/Dario-97-it/mtdesk/releases/latest)**.
Non serve registrarsi, non serve una licenza, non ci sono limiti di tempo.
(Finché la prima versione non è stata pubblicata, i link di questa tabella danno errore 404:
vedi il riquadro qui sopra.)

| Sistema | File da scaricare | Quando usarlo |
|---|---|---|
| **Windows** 10/11 (64 bit) | [`MTDesk-windows-x86_64-install.exe`](https://github.com/Dario-97-it/mtdesk/releases/latest/download/MTDesk-windows-x86_64-install.exe) | Versione completa: al doppio clic propone l'installazione; una volta installata resta sul PC e si avvia da sola all'accensione. È quella per l'assistenza che si ripete nel tempo, ed è quella che usa il tecnico quando lavora da Windows. |
| **Windows** — assistenza veloce | [`MTDesk-qs.exe`](https://github.com/Dario-97-it/mtdesk/releases/latest/download/MTDesk-qs.exe) | "Quick Support": si apre e basta, **non installa niente**. Ideale per il cliente che ha bisogno di aiuto una volta sola. Serve solo a *ricevere* assistenza. |
| **Ubuntu / Debian** (64 bit) | [`mtdesk-ubuntu-amd64.deb`](https://github.com/Dario-97-it/mtdesk/releases/latest/download/mtdesk-ubuntu-amd64.deb) | Si installa da terminale: `sudo apt install ./mtdesk-ubuntu-amd64.deb`. Per Linux c'è solo questo pacchetto, da installare: una versione "apri e usa" come quella per Windows non esiste. Se sul PC c'è già RustDesk, l'installazione lo toglie: i due programmi non possono convivere. |

**I due file per Windows sono lo stesso programma con due nomi diversi**, ed è il nome a
decidere come si comporta: un nome che finisce in `install.exe` fa comparire la schermata di
installazione, un nome che contiene `-qs.exe` apre l'assistenza rapida. Per questo **non
vanno rinominati**: con un altro nome il programma si comporterebbe in un altro modo.

Che cosa fa, di preciso, `MTDesk-qs.exe`:

- apre una **finestra compatta** con il logo, l'ID, la password monouso, lo stato del
  collegamento e il pulsante **Esci**. Chi lo apre può solo farsi assistere: i collegamenti
  verso altri computer vengono rifiutati;
- **non installa niente**: non crea servizi di Windows, non parte da solo all'accensione del
  PC e non compare fra i programmi installati;
- all'avvio **chiede i privilegi di amministratore**: compare la finestra di Windows che
  domanda il permesso di apportare modifiche al dispositivo (in gergo, UAC) e, siccome il
  file non è firmato, lì l'autore risulta sconosciuto. Il motivo è lo stesso spiegato
  [più sotto](#avviso-per-chi-usa-windows-editore-sconosciuto);
- per funzionare **scompatta i propri file**, circa 72 MB, nella cartella
  `%LOCALAPPDATA%\MTDesk` del profilo utente, e **quando viene chiuso non li cancella**. Non
  è un'installazione, ma è giusto saperlo: chi vuole togliere ogni traccia cancella, a
  programma chiuso, sia il file scaricato sia quella cartella. (Nella stessa cartella si
  scompatta anche l'altro file, prima di mostrare la schermata di installazione.)

> **macOS non è supportato.** Il progetto viene compilato e collaudato solo per Windows e Ubuntu.

Più in generale, MTDesk esiste soltanto per PC Windows e per PC Ubuntu/Debian a 64 bit con
processore Intel o AMD. Questi sono i casi che capitano, ognuno con la frase pronta da dire
al cliente:

| Il cliente ha… | Situazione | Frase pronta |
|---|---|---|
| un **Mac** | Non supportato: il programma non viene compilato per macOS. | "MTDesk per Mac non esiste: funziona solo su computer con Windows o con Ubuntu." |
| un **telefono o un tablet** (Android, iPhone, iPad) | Non supportati, né per ricevere assistenza né per darla. | "Da telefono o da tablet MTDesk non si può usare: serve un computer con Windows o con Ubuntu." |
| un PC **Windows con processore ARM** (alcuni portatili recenti) | Il progetto non compila e non collauda una versione per questi processori. | "Per il tipo di processore del suo computer MTDesk non ha una versione." |
| un computer **Linux con processore ARM** (per esempio un Raspberry Pi) | Il pacchetto `.deb` è solo per processori Intel/AMD: su ARM non si installa. | "Per il suo computer MTDesk non ha una versione." |

---

## Come si usa (in pratica)

Nel controllo remoto ci sono sempre **due ruoli**, e servono due copie di MTDesk: una per parte.

```
  ┌─────────────────────────┐                        ┌─────────────────────────┐
  │   CHI CHIEDE AIUTO      │                        │   CHI DA ASSISTENZA     │
  │   (il cliente)          │                        │   (il tecnico)          │
  │                         │                        │                         │
  │   Apre MTDesk e legge   │      ID + password     │   Scrive quell'ID nel   │
  │   a schermo:            │  ───────────────────>  │   riquadro "Controlla   │
  │     - un ID numerico    │   (telefono / chat)    │   desktop remoto" e     │
  │     - una password      │                        │   preme Connetti        │
  │                         │                        │                         │
  │   CONDIVIDE lo schermo  │  <───────────────────  │   VEDE e COMANDA        │
  └─────────────────────────┘    il tuo server       └─────────────────────────┘
                              (relay / rendezvous)
```

1. Il cliente apre MTDesk. In alto vede il suo **ID** (un numero, di solito di 9 cifre) e una
   **password** temporanea.
2. Li comunica al tecnico: telefono, WhatsApp, email, come è più comodo.
3. Il tecnico scrive quell'ID, preme **Connetti** e inserisce la password: da quel momento
   vede lo schermo del cliente e può usare mouse e tastiera.
4. Chiusa la sessione, il collegamento finisce. La password temporanea cambia ad ogni
   riavvio del programma, quindi non resta nessuna porta aperta.

Dalla parte del tecnico serve la versione completa (su Windows
`MTDesk-windows-x86_64-install.exe`, su Ubuntu il pacchetto `.deb`): `MTDesk-qs.exe` è fatto
solo per ricevere assistenza e rifiuta i collegamenti in uscita.

**Assistenza ricorrente, senza chiedere conferma ogni volta.** Sul PC del cliente si può
impostare una *password di accesso permanente* (Impostazioni → Sicurezza → riquadro
**Password** → **Imposta password permanente**; nella versione installata bisogna prima
premere **Sblocca impostazioni sicurezza**). Il cliente la comunica una sola volta e il
tecnico può entrare quando serve, anche a schermo bloccato.
Su Windows questo richiede la versione installata: è l'installazione a creare il servizio che
tiene MTDesk attivo fin dall'accensione del PC. Con `MTDesk-qs.exe` non si può fare: chiuso il
programma, nessuno può più entrare.

> **Su Ubuntu c'è un limite, da conoscere prima di promettere questa funzione a un cliente.**
> Le versioni recenti di Ubuntu usano un sistema grafico chiamato *Wayland* che, per
> sicurezza, non permette a un programma di leggere lo schermo senza il consenso di chi è
> seduto davanti al computer. In pratica: quando il tecnico si collega a un PC Ubuntu, sul PC
> del cliente compare una richiesta di condivisione dello schermo e **deve accettarla qualcuno
> sul posto**; la schermata di accesso (quella dove si scrive la password dopo l'accensione)
> non si può vedere. Quindi su Ubuntu con Wayland entrare "quando serve, senza nessuno
> davanti" **oggi non è possibile**: nella prova del 10 novembre 2026, su Ubuntu 26.04, il
> collegamento è arrivato fino a quella richiesta e lì si è fermato, com'era previsto.
>
> - Su **Ubuntu 22.04 e 24.04** si può far usare al PC il sistema grafico precedente, X11, che
>   questo limite non ce l'ha. La procedura è nella pagina di aiuto
>   [`docs/aiuto.html`](docs/aiuto.html), sezioni "Serve X11, non Wayland" e "Schermata di
>   accesso".
> - Da **Ubuntu 25.10** in poi (26.04 compresa) la sessione "Ubuntu su Xorg" non esiste più:
>   resta solo Wayland. Per questi PC nel codice è prevista una variante del pacchetto pensata
>   apposta, `mtdesk-unattended-wayland` (si ottiene compilando con l'opzione `--drm` di
>   `client/build.py`), ma **non è ancora stata né costruita né provata**: fino ad allora, su
>   questi PC serve qualcuno davanti allo schermo.
>
> Nel verso opposto il limite non c'è: da un PC Ubuntu si dà assistenza a un PC Windows
> normalmente (provato lo stesso giorno).

Come si dice a MTDesk a quale centralino collegarsi (serve per le prove, e finché quello
predefinito non è acceso) è descritto in
**[`deploy/CLIENT-CONNESSIONE.md`](deploy/CLIENT-CONNESSIONE.md)**. Per provare tutto in casa,
fra due computer della stessa rete e senza VPS, c'è lo script
`deploy/avvia-centralino-locale.ps1`: avvia il centralino sul PC Windows e stampa i valori da
scrivere nei due MTDesk. Le risposte ai problemi più comuni dal lato del cliente sono nella
pagina di aiuto [`docs/aiuto.html`](docs/aiuto.html), la stessa che il programma apre dai suoi
avvisi (sarà leggibile come pagina web, all'indirizzo
<https://dario-97-it.github.io/mtdesk/aiuto.html>, quando GitHub Pages sarà attivo).

---

## Avviso per chi usa Windows: "editore sconosciuto"

L'eseguibile **non è firmato digitalmente**. Un certificato di firma del codice costa
alcune centinaia di euro all'anno e MTDesk è un progetto a costo zero: abbiamo scelto di
non comprarlo e di dirlo chiaramente, invece di far finta che il problema non esista.

Quindi la prima volta che si apre il file, Windows mostra una schermata blu
**"Windows ha protetto il PC"** (SmartScreen) in cui si legge *editore sconosciuto*.
Non è un virus rilevato: è Windows che avvisa di non riconoscere chi ha firmato il file.

Per procedere:

1. Nella finestra blu clicca su **Ulteriori informazioni**.
2. Compare il pulsante **Esegui comunque**: cliccalo.

Con `MTDesk-qs.exe` subito dopo compare una seconda finestra di Windows, quella che chiede il
permesso di apportare modifiche al dispositivo (UAC): il programma chiede i privilegi di
amministratore a ogni avvio e, per lo stesso motivo di prima, anche lì l'autore risulta
sconosciuto. Si risponde **Sì**. La stessa richiesta può comparire durante l'installazione
dell'altro file.

Se è il browser a bloccare il download ("file scaricato raramente"), apri il menu accanto
al download e scegli **Conserva** / **Mantieni comunque**.

**Come assicurarsi che il file sia quello giusto.** Scaricalo *soltanto* dalla pagina
[Releases](https://github.com/Dario-97-it/mtdesk/releases/latest) di questo repository.

Ogni file ha un'**impronta digitale** (SHA-256): un codice che cambia se anche un solo byte
del file è diverso. Confrontare l'impronta è il modo per essere sicuri di aver scaricato il
file originale e non una copia manomessa.

- **Ubuntu**: accanto al pacchetto trovi il file `mtdesk-ubuntu-amd64.deb.sha256`, generato
  da GitHub Actions durante la compilazione. Scarica entrambi nella stessa cartella e dai:
  ```bash
  sha256sum -c mtdesk-ubuntu-amd64.deb.sha256
  ```
  La risposta deve finire con `OK`.
- **Windows**: accanto a ognuno dei due eseguibili viene pubblicato un file con lo stesso
  nome più `.sha256` (`MTDesk-windows-x86_64-install.exe.sha256` e `MTDesk-qs.exe.sha256`):
  contiene l'impronta calcolata da GitHub Actions subito dopo la compilazione. Scarica
  l'eseguibile e il suo `.sha256` nella stessa cartella, apri PowerShell lì dentro e dai:
  ```powershell
  Get-FileHash .\MTDesk-windows-x86_64-install.exe -Algorithm SHA256
  Get-Content .\MTDesk-windows-x86_64-install.exe.sha256
  ```
  Il primo comando calcola l'impronta del file che hai scaricato, il secondo mostra quella
  pubblicata (è la lunga sequenza di lettere e cifre all'inizio della riga). Le due stringhe
  devono coincidere (maiuscole/minuscole non contano). Per `MTDesk-qs.exe` i comandi sono gli
  stessi, con l'altro nome di file.

---

## Licenza e origine

MTDesk è un'**opera derivata di [RustDesk](https://github.com/rustdesk/rustdesk)**, basata
sul codice sorgente che porta il numero di versione **1.4.9**. Per la precisione:

- il **programma** (cartella `client/`) parte dal codice di RustDesk così com'era il
  **25 agosto 2026** nel ramo principale `master`, commit
  `cec4085238ee723b75095e94014e8595f374688b`. Quel codice dichiara la versione 1.4.9, ma non
  coincide con la 1.4.9 pubblicata da RustDesk (etichetta `1.4.9`, del 6 luglio 2026): è più
  recente di 120 modifiche (*commit*);
- la libreria comune **`hbb_common`**, che in RustDesk è un repository separato, è stata
  presa al commit `b2b1ac453d1d694046f63be20d792d608dac1c93` e copiata qui dentro come file
  normali;
- il **centralino** (cartella `server/`) parte da
  [rustdesk-server](https://github.com/rustdesk/rustdesk-server), ramo `master`, commit
  `a7736be5e40f85bfc141120dce587e836e5d4b80`, che dichiara la versione 1.1.17.

Conoscere il punto di partenza esatto serve il giorno in cui RustDesk pubblica una correzione
di sicurezza: per capire se riguarda anche MTDesk, e per riportarla qui, va confrontata con
questi commit.

Il codice è stato **modificato da Marketing Tools (marketingtools.digital) a partire da
agosto 2026**. Le modifiche riguardano il nome e l'aspetto dell'applicazione, i colori, le
icone, il pacchetto per Linux e l'indirizzo del server di appoggio predefinito; da novembre
2026 anche l'eliminazione di ogni chiamata verso i server di RustDesk (controllo degli
aggiornamenti, server di amministrazione) e della registrazione del dispositivo, un controllo
degli aggiornamenti nostro che si limita a mostrare un avviso, la finestra compatta
dell'assistenza rapida e le librerie esterne portate dentro al repository. Il documento che le
descrive è **[`client/REBRAND-CHANGES.md`](client/REBRAND-CHANGES.md)**: è una descrizione per
argomenti, non un registro garantito completo, e se lì manca qualcosa fa fede il codice. Per
verificarle una per una: le
modifiche successive alla creazione di questo repository (novembre 2026) si leggono nella sua
cronologia (`git log`); tutte quante, comprese le prime, si vedono confrontando la cartella
`client/` con il commit di RustDesk indicato qui sopra.

MTDesk è distribuito sotto **GNU Affero General Public License versione 3 (AGPL-3.0)**, la
stessa licenza di RustDesk. Il testo integrale è nel file **[`LICENSE`](LICENSE)**.
Questo significa che chiunque riceve il programma ha diritto a ottenerne il codice
sorgente: è esattamente il motivo per cui questo repository è pubblico.
Le librerie di terzi portate dentro al repository (`client/third_party` e
`server/third_party`) restano ciascuna sotto la propria licenza: i file di licenza e gli
avvisi di copyright che contengono non vanno rimossi.

> **MTDesk non è affiliato a RustDesk e non è approvato né sostenuto dal progetto RustDesk
> o dai suoi autori.** "RustDesk" e gli altri nomi e loghi citati sono marchi dei rispettivi
> titolari. Il nome "MTDesk", il logo e i colori Marketing Tools non fanno parte della
> licenza AGPL, che copre il codice sorgente e non i marchi.

Per qualsiasi problema riscontrato con MTDesk **non contattare il progetto RustDesk**:
apri una [issue qui](https://github.com/Dario-97-it/mtdesk/issues).

---

## Struttura del repository

```
mtdesk/
├─ GUIDA-MESSA-IN-OPERA.md  → la guida passo per passo per accendere il centralino su un VPS
├─ client/     → il programma MTDesk: fork di RustDesk 1.4.9 ribrandizzato
│   ├─ BUILD-WINDOWS.md     → come compilare la versione Windows
│   ├─ REBRAND-CHANGES.md   → le modifiche fatte a RustDesk
│   ├─ LICENCE              → AGPL-3.0 (testo originale ereditato da RustDesk)
│   ├─ build.py             → lo script che compila e confeziona i file da distribuire
│   ├─ scripts/             → install-toolchain.ps1 + build-mtdesk.ps1 (Windows)
│   ├─ libs/hbb_common/     → qui stanno nome dell'app, indirizzo e chiave del centralino
│   └─ third_party/         → le librerie che prima si scaricavano da repository di terzi
├─ BUILD-UBUNTU.md  → come compilare il pacchetto .deb per Ubuntu
├─ server/     → i sorgenti del centralino (hbbs e hbbr), da cui si costruisce la nostra immagine
│   ├─ README.md            → come è fatto, come si compila, dove stanno chiavi e dati
│   ├─ Dockerfile           → la ricetta dell'immagine Docker mtdesk-server
│   ├─ docker-entrypoint.sh → lo script di avvio dentro il container (permessi dei dati)
│   ├─ LICENSE              → AGPL-3.0
│   ├─ libs/hbb_common/     → copia di quella del client: le due vanno tenute uguali
│   └─ third_party/         → le librerie portate dentro, come per il client
├─ deploy/     → la messa in opera del server di appoggio, in Docker (relay + rendezvous)
│   ├─ README-SERVER.md       → guida all'installazione su un VPS
│   ├─ CLIENT-CONNESSIONE.md  → come far puntare i client al server
│   ├─ docker-compose.yml     → i due container: hbbs (ID) e hbbr (relay)
│   ├─ .env.example           → modello di configurazione da copiare in .env
│   ├─ mostra-chiave.sh       → stampa la chiave pubblica del server
│   └─ avvia-centralino-locale.ps1 → centralino di prova sul PC Windows, per la rete di casa
├─ brand/      → identità visiva: BRAND-MTDESK.md (palette, font) + icons/
├─ landing/    → la pagina di download per i clienti (index.html); non è ancora online
├─ docs/       → la cartella che GitHub Pages deve pubblicare (va ancora attivato):
│                index.html, aiuto.html (la pagina di aiuto che il programma apre dai suoi
│                avvisi), privacy.html (trattamento dei dati) e version.json, il file che fa
│                comparire l'avviso "è disponibile una versione nuova" dentro il programma
├─ .github/workflows/ → mtdesk-build.yml: la compilazione automatica per Ubuntu e per Windows
│                       e la pubblicazione della Release (GitHub Actions)
└─ LICENSE     → AGPL-3.0
```

**Nota sulla cartella `server/`.** Fino a novembre 2026 questa cartella non era pubblicata:
era una copia non modificata del progetto upstream
[rustdesk-server](https://github.com/rustdesk/rustdesk-server), tenuta solo come riferimento,
e la messa in opera in `deploy/` usava l'immagine Docker già pronta
`rustdesk/rustdesk-server`. **Non è più così.** Oggi `server/` è codice nostro, pubblicato in
questo repository: contiene i sorgenti dei due programmi del centralino, modificati perché
non contattino più i server di RustDesk, e il `Dockerfile` con cui si costruisce la nostra
immagine `mtdesk-server:1.1.17`. L'immagine di RustDesk non si usa più. I dettagli sono in
[`server/README.md`](server/README.md).

**Che cosa non trovi su GitHub, di proposito.** Nella copia di lavoro locale la cartella
`deploy/` contiene anche `data/` (le chiavi e il database del centralino), `.env` (la
configurazione) e `CHIAVE-SERVER.txt` (un promemoria della chiave pubblica). Non vengono
pubblicati: dentro `data/` c'è la chiave privata del centralino, che non deve uscire dal PC e
dal VPS.

---

## Compilare dai sorgenti

I file destinati alle Release — i due eseguibili per Windows e il pacchetto per Ubuntu — li
compila **GitHub Actions**: la procedura è quindi leggibile e ripetibile da chiunque, ed è
scritta per intero in
[`.github/workflows/mtdesk-build.yml`](.github/workflows/mtdesk-build.yml).
Il workflow è fatto di quattro lavori:

1. **controllo del brand** — verifica che nel codice ci siano davvero il nome MTDesk,
   l'indirizzo del nostro centralino e la sua chiave; se mancano si ferma subito, invece di
   sfornare un programma che si chiama RustDesk e si collega ai server di RustDesk;
2. **bridge** — genera i file che fanno parlare fra loro le due metà del programma (le
   finestre e i bottoni, scritti in Dart, e la parte che cattura lo schermo e parla in rete,
   scritta in Rust);
3. **Ubuntu** — compila `mtdesk-ubuntu-amd64.deb`;
4. **Windows** — compila `MTDesk-windows-x86_64-install.exe` e `MTDesk-qs.exe`.

I lavori 3 e 4 calcolano l'impronta SHA-256 di ogni file e allegano tutto alla Release: tre
file più i loro tre `.sha256`. Sono indipendenti l'uno dall'altro: se uno dei due fallisce,
l'altro pubblica lo stesso i propri file. Il workflow si avvia a mano (scheda **Actions** →
**MTDesk - Build e Release** → **Run workflow**) oppure spingendo un tag che comincia per `v`.

**Com'è andata finora (10 novembre 2026).** Questo percorso non ha ancora prodotto una
Release. La prima esecuzione, partita dal tag `v1.4.9`, si è fermata nel lavoro Ubuntu, al
passo che prepara le librerie native con vcpkg; la causa non è stata ancora trovata (lo
stesso passo, rifatto in un contenitore `ubuntu:22.04` pulito, riesce). Il lavoro Windows non
è mai stato eseguito: è stato aggiunto al workflow dopo quel tag. I file che esistono oggi
sono stati compilati in locale: i due `.exe` su un PC Windows, il `.deb` su un PC Ubuntu
dentro un contenitore `ubuntu:22.04`.

**Il motore Flutter è quello ufficiale.** L'interfaccia di MTDesk è costruita con Flutter.
RustDesk, per la versione Windows, sostituisce il motore di Flutter con uno modificato da
loro, che si scarica già compilato; MTDesk non lo fa più e usa il motore che arriva con lo
SDK ufficiale di Flutter 3.24.5, così dentro l'eseguibile non finisce più un componente
compilato da RustDesk e scaricato senza alcuna verifica. **Limite da conoscere:** è
verificato che con il motore ufficiale la compilazione passa e il programma si avvia, e
nella sessione di prova del 10 novembre 2026 un PC Windows è stato controllato senza problemi
da un PC Ubuntu. **Non è ancora stato provato** il caso opposto, quello in cui è il PC
Windows a *guardare* lo schermo remoto: cioè il video durante una sessione dalla parte del
tecnico, che è proprio il punto in cui il motore modificato interveniva. Se lì il video
risultasse nero, lento o a strappi, il motore è il primo sospetto: la nota su come
reintrodurlo in modo controllato è in `client/scripts/install-toolchain.ps1`.

Per compilare sul proprio PC:

- **Windows** → **[`client/BUILD-WINDOWS.md`](client/BUILD-WINDOWS.md)**
  Attenzione: le versioni di Rust (1.75.0), Flutter (3.24.5), LLVM (15.0.6) e il commit di
  vcpkg indicati in quella guida sono **vincoli di compatibilità**, non suggerimenti: con
  versioni più recenti la build non passa.
  Alla fine `client/build.py` lascia nella cartella `client/` i due file da distribuire,
  `MTDesk-windows-x86_64-install.exe` e `MTDesk-qs.exe`, già con i nomi giusti.
- **Ubuntu** → **[`BUILD-UBUNTU.md`](BUILD-UBUNTU.md)**
  Produce il pacchetto `.deb` installabile con `apt`. Gli stessi comandi, già pronti, sono
  quelli eseguiti dal workflow citato sopra.
- **Centralino** → **[`server/README.md`](server/README.md)**
  Si compila a parte, con una versione di Rust diversa e più recente di quella del programma:
  sono due catene di compilazione indipendenti, e gli strumenti dell'una non vanno bene per
  l'altra.

**Che cosa si scarica ancora da internet mentre si compila.** Le librerie Rust che RustDesk
prendeva da repository git di terzi oggi stanno dentro questo repository, in
`client/third_party` e `server/third_party` (vedi
[`client/third_party/LEGGIMI.md`](client/third_party/LEGGIMI.md)): la compilazione non dipende
più dal fatto che quei repository restino online. Non tutto, però, è in casa. Durante la
compilazione arrivano ancora da fuori:

- i pacchetti Rust del registro pubblico crates.io (le versioni esatte sono fissate nei file
  `Cargo.lock`);
- lo SDK di Flutter e i pacchetti Dart, fra cui **nove pacchetti presi da repository git, otto
  dei quali dell'organizzazione `rustdesk-org`** (sono elencati in
  `client/flutter/pubspec.yaml`): è la dipendenza da terzi che resta ancora da portare in casa;
- vcpkg, al commit fissato, con i sorgenti delle librerie audio e video (fra le altre ffmpeg,
  aom, opus, libvpx, libyuv);
- su Windows anche LLVM e NASM;
- gli strumenti di compilazione stessi (Rust; su Ubuntu i pacchetti di sistema installati con
  `apt`) e, per l'immagine del centralino, le due immagini Docker di partenza indicate in
  `server/Dockerfile` (`rust:1.99.1-bookworm` e `debian:bookworm-slim`) con i pacchetti Debian
  che vi si installano sopra.

---

## Server self-host

> **Prima messa in opera, partendo da zero:** la guida da seguire è
> **[`GUIDA-MESSA-IN-OPERA.md`](GUIDA-MESSA-IN-OPERA.md)**, scritta passo per passo per chi
> non ha mai messo piede in un server.

MTDesk, per far incontrare i due computer, non usa i server di RustDesk né quelli di altri
fornitori: usa un **server proprio** (in questi documenti lo chiamiamo *centralino*), che
serve solo a questo: trova il PC partendo dall'ID e, se la connessione diretta non passa, fa
da ponte. Schermo e tasti viaggiano cifrati end-to-end: il server vede transitare i dati, non
li può leggere.

Nel programma non è rimasta nessuna chiamata verso i server di RustDesk. A fornitori esterni
il programma si rivolge ancora in due casi, ed è giusto dichiararli tutti e due:

- **il file degli aggiornamenti**: all'avvio scarica `version.json` da GitHub Pages e, se ci
  trova un numero di versione più alto del proprio, mostra un avviso. Non manda dati e non
  scarica né installa niente da solo;
- **la domanda "qual è il mio indirizzo pubblico?"**, ereditata dal codice di RustDesk e non
  ancora tolta: quando si avvia, il programma prova a scoprire il proprio indirizzo IPv6
  chiedendolo a tre servizi pubblici fatti apposta (in gergo, server *STUN*): uno di Google,
  uno di Cloudflare e uno di Nextcloud. L'elenco è in `client/src/common.rs` (`STUNS_V6`).
  Non vengono mandati né l'ID, né la password, né altro; ma quei servizi, come qualunque sito
  a cui ci si collega, vedono l'indirizzo IP del computer che fa la domanda. Se il computer
  non ha un collegamento IPv6 la domanda non può arrivare a destinazione.
  `[DA DECIDERE: togliere questa richiesta dal codice, oppure dichiararla nella pagina sul
  trattamento dei dati (docs/privacy.html)]`

**Oggi il centralino non è ancora in funzione**: non è mai stato installato su un VPS, e il
nome `mtdesk.marketingtools.digital` non è ancora stato creato nel DNS (l'elenco pubblico che
traduce i nomi in indirizzi).

Il centralino è fatto di due programmi, `hbbs` (trova i computer) e `hbbr` (fa da ponte), che
girano in due container Docker. **Non si usa più l'immagine già pronta di RustDesk**
(`rustdesk/rustdesk-server`): l'immagine è nostra, si chiama `mtdesk-server:1.1.17` e si
costruisce dai sorgenti della cartella `server/` con [`server/Dockerfile`](server/Dockerfile).
Così si sa esattamente che cosa gira sul VPS, e un aggiornamento fatto da altri non può
cambiarlo.

**Dove si costruisce l'immagine: sul PC, non sul VPS.** Il VPS gratuito previsto dalla guida
(1/8 di processore e 1 GB di memoria) basta e avanza per far *girare* il centralino, ma non è
in grado di *compilarlo*: compilare un programma in Rust richiede molta più memoria. La
procedura decisa è quindi questa:

1. sul PC, dove deve essere installato Docker, si costruisce l'immagine: `docker compose build`,
   dalla cartella `deploy/`;
2. la si esporta in un file con `docker save`;
3. si copia il file sul VPS con `scp`;
4. sul VPS la si carica con `docker load`;
5. si avvia il centralino con `docker compose up -d`, **senza** `--build` e **senza**
   `docker compose pull`: sul VPS non c'è niente da compilare, e l'immagine non sta in nessun
   archivio online da cui scaricarla.

> **Attenzione: questa procedura è decisa, ma non è collaudata.**
> Dell'immagine esiste finora una sola prova, annotata nella cronologia del repository: il
> 10 novembre 2026 è stata avviata da zero su un PC Ubuntu, e quell'avvio **è fallito** per un
> difetto nei permessi della cartella dei dati (`hbbs` ripartiva in continuazione). Il difetto
> è stato corretto nel codice, con lo script `server/docker-entrypoint.sh`, ma un avvio
> riuscito *dopo* la correzione non è annotato da nessuna parte: va controllato alla prima
> occasione (dopo `docker compose up -d`, il comando `docker compose ps` deve mostrare tutti e
> due i container con la scritta `healthy`). I passaggi successivi — esportare l'immagine,
> copiarla sul VPS, caricarla e avviarla lì — non sono mai stati eseguiti. La prima volta va
> quindi considerata una prova: se qualcosa si ferma con un errore, la causa va cercata nella
> procedura, non in chi la sta seguendo.

Tutto il resto — porte, firewall, DNS, chiavi, verifica finale — è in
[`GUIDA-MESSA-IN-OPERA.md`](GUIDA-MESSA-IN-OPERA.md) e, scritto per un lettore più tecnico, in
**[`deploy/README-SERVER.md`](deploy/README-SERVER.md)**.

L'indirizzo del server e la sua chiave pubblica sono **già compilati dentro il programma**:
il cliente scarica, apre e vede solo ID e password. Nessuna configurazione da parte sua.
Questo vale dal momento in cui il centralino è acceso a quell'indirizzo. La chiave compilata
nel programma è quella della coppia di chiavi conservata nella cartella `deploy/data/`: quella
cartella va portata sul VPS **prima** del primo avvio, altrimenti il centralino si crea una
chiave nuova e i programmi già compilati non riescono più a collegarsi. Dei permessi di quei
file non c'è da occuparsi a mano: a ogni avvio il container assegna da solo la cartella
all'utente senza privilegi, di nome `mtdesk`, con cui poi girano i due programmi (lo fa lo
script `server/docker-entrypoint.sh`: è la correzione di cui parla il riquadro qui sopra, e
vale anche per i file lasciati da un centralino precedente). Com'è fatto il centralino e dove
tiene chiavi e dati è spiegato in [`server/README.md`](server/README.md).

**Per provare adesso, senza VPS.** Finché il centralino predefinito non è acceso, il
centralino da usare si indica a mano in ogni MTDesk: **Impostazioni → Rete → Server
ID/Relay** (nella versione installata bisogna prima premere **Sblocca impostazioni di
rete**). Nei campi **ID server** e **Server relay** va l'indirizzo del centralino, in **Key**
la sua chiave pubblica; **Server API** resta vuoto. Per avere un centralino di prova c'è lo
script `deploy/avvia-centralino-locale.ps1`: lo avvia sul PC Windows, per la sola rete
locale, e stampa proprio quei valori (nel testo che stampa, i primi due campi sono chiamati
"Server ID" e "Server inoltro": sono gli stessi). Se i due programmi del centralino non sono
ancora stati compilati sul PC, lo script si ferma e dice come farlo. È stato collaudato (la
sessione di prova del 10 novembre 2026 è passata da lì), ma non è un modo per lavorare con i
clienti: spento il PC, il centralino si ferma.

---

## Dal codice al cliente

Questa è la catena completa: tutto quello che deve esistere perché un cliente possa scaricare
MTDesk, aprirlo e farsi assistere. Per ogni anello è indicato dove è spiegato e a che punto è
oggi (10 novembre 2026). I primi tre anelli non dipendono l'uno dall'altro e si possono fare
nell'ordine che si preferisce, ma **devono essere a posto tutti e tre prima di dare il
programma a un cliente**.

1. **Il centralino acceso su internet**, all'indirizzo `mtdesk.marketingtools.digital`.
   - *Dove è spiegato:* [`GUIDA-MESSA-IN-OPERA.md`](GUIDA-MESSA-IN-OPERA.md) e la sezione
     [Server self-host](#server-self-host) qui sopra.
   - *A che punto è:* **da fare.** Il nome non esiste ancora in internet, il centralino non è
     mai stato installato su un VPS e dell'immagine Docker esiste una sola prova di avvio, fallita
     e poi corretta nel codice (vedi il riquadro in [Server self-host](#server-self-host)).
     In rete locale, con lo script di prova, il centralino funziona.
2. **GitHub Pages attivo** sulla cartella `docs/`. Serve a tre cose: l'avviso di aggiornamento
   (`version.json`), la pagina di aiuto che il programma apre dai suoi avvisi (`aiuto.html`) e
   la pagina sul trattamento dei dati (`privacy.html`).
   - *Dove è spiegato:* [`docs/README.md`](docs/README.md). In breve: nel repository su
     GitHub, **Settings → Pages**, ramo `main`, cartella `/docs`.
   - *A che punto è:* **da fare.** Oggi <https://dario-97-it.github.io/mtdesk/version.json>
     risponde 404. Il programma non dà errori: semplicemente non mostra l'avviso di
     aggiornamento, e i suoi collegamenti alle pagine di aiuto e di privacy non portano da
     nessuna parte.
3. **La Release su GitHub**, con i tre file da scaricare e i loro tre `.sha256`.
   - *Dove è spiegato:* sezione [Compilare dai sorgenti](#compilare-dai-sorgenti) e
     [`.github/workflows/mtdesk-build.yml`](.github/workflows/mtdesk-build.yml).
   - *A che punto è:* **da fare.** Nessuna Release è stata pubblicata. Attenzione a un
     dettaglio: il tag `v1.4.9` che esiste già è fermo a un punto in cui nel workflow non
     c'era ancora il lavoro Windows, quindi rispingerlo così com'è non compilerebbe i due
     `.exe`. La prima Release va fatta partire dal ramo `main` con il bottone manuale, oppure
     dopo aver spostato il tag sul codice attuale.
4. **I dati che solo il titolare può scrivere**, nelle pagine che legge il cliente: email e
   telefono dell'assistenza, ragione sociale, partita IVA, contatto per la privacy.
   - *Dove vanno:* `landing/index.html` e `docs/privacy.html`. I punti da riempire sono
     segnati in modo riconoscibile (`[INSERIRE …]`, `[DA COMPLETARE: …]`) e devono restare
     così, visibili, finché il dato vero non c'è: non vanno riempiti con dati di fantasia.
   - *A che punto è:* **mancano tutti.**
5. **La pagina di download online** (`landing/index.html`): è l'indirizzo da dare ai clienti.
   - *A che punto è:* **da decidere dove pubblicarla.** Oggi non è online da nessuna parte:
     non sta nella cartella `docs/`, quindi GitHub Pages non la pubblicherà, e nessun workflow
     la carica altrove. Le strade sono due: copiarla dentro `docs/`, così esce insieme alle
     altre pagine, oppure metterla sul sito aziendale.
     `[DA COMPLETARE: indirizzo web a cui sarà pubblicata la pagina di download]`
6. **La prova finale**, da fare per ultima: da un computer collegato a un'altra rete (non
   quella dell'ufficio), aprire la pagina di download, scaricare il programma come farebbe un
   cliente, aprirlo e collegarsi.
   - *Dove è spiegato:* i controlli di collaudo di
     [`GUIDA-MESSA-IN-OPERA.md`](GUIDA-MESSA-IN-OPERA.md).
   - *A che punto è:* **da fare**, quando i cinque anelli precedenti sono a posto.

**Per le versioni successive alla prima** ci sono due cose in più a cui badare. La prima: il
numero di versione va alzato anche nei sorgenti (oggi è 1.4.9, ed è scritto in più file, a
partire da `client/Cargo.toml` e `client/flutter/pubspec.yaml`), altrimenti il programma nuovo
continuerebbe a dichiararsi 1.4.9 e l'avviso di aggiornamento non sparirebbe mai. La seconda
è l'ordine: prima la Release nuova con i file dentro, e solo dopo il numero di versione in
`docs/version.json`. Se si fa il contrario, i clienti vedono l'avviso di aggiornamento ma il
pulsante li porta ancora al file della versione vecchia: lo scaricano, lo riaprono, e l'avviso
è ancora lì. La procedura di pubblicazione è in [`docs/README.md`](docs/README.md).

---

## Brand

Palette, gradiente, font e icone sono documentati in
**[`brand/BRAND-MTDESK.md`](brand/BRAND-MTDESK.md)**; i file grafici stanno in
`brand/icons/`. Colore principale ciano `#00BCD4` su base scura `#0A0A14`, font Inter.

---

<div align="center">

**[Marketing Tools](https://marketingtools.digital)** · MTDesk · AGPL-3.0
Opera derivata di [RustDesk](https://github.com/rustdesk/rustdesk) 1.4.9 — non affiliata a RustDesk

</div>
