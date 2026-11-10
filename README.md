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

## Scarica

Tutti i file si trovano nella pagina **[Releases → latest](https://github.com/Dario-97-it/mtdesk/releases/latest)**.
Non serve registrarsi, non serve una licenza, non ci sono limiti di tempo.

| Sistema | File da scaricare | Quando usarlo |
|---|---|---|
| **Windows** 10/11 (64 bit) | [`MTDesk-windows-x86_64-install.exe`](https://github.com/Dario-97-it/mtdesk/releases/latest/download/MTDesk-windows-x86_64-install.exe) | Versione completa: si installa e resta sul PC. |
| **Windows** — assistenza veloce | [`MTDesk-qs.exe`](https://github.com/Dario-97-it/mtdesk/releases/latest/download/MTDesk-qs.exe) | "Quick Support": si apre e basta, **non installa niente**. Ideale per il cliente che ha bisogno di aiuto una volta sola. |
| **Ubuntu / Debian** (64 bit) | [`mtdesk-ubuntu-amd64.deb`](https://github.com/Dario-97-it/mtdesk/releases/latest/download/mtdesk-ubuntu-amd64.deb) | Doppio clic sul file, oppure da terminale: `sudo apt install ./mtdesk-ubuntu-amd64.deb` |

> **macOS non è supportato.** Il progetto viene compilato e collaudato solo per Windows e Ubuntu.

---

## Come si usa (in pratica)

Nel controllo remoto ci sono sempre **due ruoli**, e servono due copie di MTDesk: una per parte.

```
  ┌─────────────────────────┐                        ┌─────────────────────────┐
  │   CHI CHIEDE AIUTO      │                        │   CHI DA ASSISTENZA     │
  │   (il cliente)          │                        │   (il tecnico)          │
  │                         │                        │                         │
  │   Apre MTDesk e legge   │      ID + password     │   Scrive quell'ID nel   │
  │   a schermo:            │  ───────────────────>  │   campo "Controlla il   │
  │     - ID a 9 cifre      │   (telefono / chat)    │   computer remoto" e    │
  │     - una password      │                        │   preme Connetti        │
  │                         │                        │                         │
  │   CONDIVIDE lo schermo  │  <───────────────────  │   VEDE e COMANDA        │
  └─────────────────────────┘    il tuo server       └─────────────────────────┘
                              (relay / rendezvous)
```

1. Il cliente apre MTDesk. In alto vede il suo **ID a 9 cifre** e una **password** temporanea.
2. Li comunica al tecnico: telefono, WhatsApp, email, come è più comodo.
3. Il tecnico scrive quell'ID, preme **Connetti** e inserisce la password: da quel momento
   vede lo schermo del cliente e può usare mouse e tastiera.
4. Chiusa la sessione, il collegamento finisce. La password temporanea cambia ad ogni
   riavvio del programma, quindi non resta nessuna porta aperta.

**Assistenza ricorrente, senza chiedere conferma ogni volta.** Sul PC del cliente si può
impostare una *password di accesso permanente* (Impostazioni → Sicurezza → Accesso non
presidiato). Il cliente la comunica una sola volta e il tecnico può entrare quando serve,
anche a schermo bloccato.

Il flusso completo, compreso il collaudo in rete locale, è descritto in
**[`deploy/CLIENT-CONNESSIONE.md`](deploy/CLIENT-CONNESSIONE.md)**.

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
- **Windows**: l'impronta è riportata nelle note della release. Per calcolare quella del file
  che hai scaricato, apri PowerShell nella cartella dei download:
  ```powershell
  Get-FileHash .\MTDesk-windows-x86_64-install.exe -Algorithm SHA256
  ```
  Le due stringhe devono coincidere (maiuscole/minuscole non contano).

---

## Licenza e origine

MTDesk è un'**opera derivata di [RustDesk](https://github.com/rustdesk/rustdesk)**, basata
sulla versione **1.4.9** del suo codice sorgente.

Il codice è stato **modificato da Marketing Tools (marketingtools.digital) a partire da
agosto 2026**. Le modifiche riguardano il nome e l'aspetto dell'applicazione, i colori, le
icone, il pacchetto per Linux e l'indirizzo del server di appoggio predefinito; l'elenco
completo e verificabile è in **[`client/REBRAND-CHANGES.md`](client/REBRAND-CHANGES.md)**.

MTDesk è distribuito sotto **GNU Affero General Public License versione 3 (AGPL-3.0)**, la
stessa licenza di RustDesk. Il testo integrale è nel file **[`LICENSE`](LICENSE)**.
Questo significa che chiunque riceve il programma ha diritto a ottenerne il codice
sorgente: è esattamente il motivo per cui questo repository è pubblico.

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
├─ client/     → il programma MTDesk: fork di RustDesk 1.4.9 ribrandizzato
│   ├─ BUILD-WINDOWS.md     → come compilare la versione Windows
│   ├─ REBRAND-CHANGES.md   → elenco puntuale di TUTTE le modifiche fatte a RustDesk
│   ├─ LICENCE              → AGPL-3.0 (testo originale ereditato da RustDesk)
│   └─ scripts/             → install-toolchain.ps1 + build-mtdesk.ps1 (Windows)
├─ BUILD-UBUNTU.md  → come compilare il pacchetto .deb per Ubuntu
├─ deploy/     → il server di appoggio, in Docker (relay + rendezvous)
│   ├─ README-SERVER.md       → guida all'installazione su un VPS
│   ├─ CLIENT-CONNESSIONE.md  → come far puntare i client al server
│   ├─ docker-compose.yml     → i due container: hbbs (ID) e hbbr (relay)
│   ├─ .env.example           → modello di configurazione da copiare in .env
│   └─ mostra-chiave.sh       → stampa la chiave pubblica del server
├─ brand/      → identità visiva: BRAND-MTDESK.md (palette, font) + icons/
├─ landing/    → la pagina web da pubblicare sul sito (index.html), con i pulsanti di download
├─ docs/       → pubblicata da GitHub Pages: version.json, il file che fa comparire
│                l'avviso "è disponibile una versione nuova" dentro il programma
├─ .github/workflows/ → la compilazione automatica del pacchetto Ubuntu (GitHub Actions)
└─ LICENSE     → AGPL-3.0
```

**Nota sulla cartella `server/`.** Nella copia di lavoro locale esiste anche una cartella
`server/`: è un clone *non modificato* del progetto upstream
[rustdesk-server](https://github.com/rustdesk/rustdesk-server), tenuto solo come
riferimento. **Non è pubblicata in questo repository**, perché non contiene nostre
modifiche e perché il deploy in `deploy/` usa direttamente l'immagine Docker ufficiale
`rustdesk/rustdesk-server`.

---

## Compilare dai sorgenti

Il **pacchetto Ubuntu** pubblicato nelle Release è compilato da **GitHub Actions**: la
procedura è quindi leggibile e ripetibile da chiunque, ed è scritta per intero in
[`.github/workflows/mtdesk-build.yml`](.github/workflows/mtdesk-build.yml).
I **file Windows** sono compilati su un PC Windows e caricati nella Release a mano (la
compilazione Windows richiede un motore Flutter modificato che oggi non è automatizzabile
in modo affidabile; il motivo è spiegato in fondo a quel workflow).

Per compilare sul proprio PC:

- **Windows** → **[`client/BUILD-WINDOWS.md`](client/BUILD-WINDOWS.md)**
  Attenzione: le versioni di Rust (1.75.0), Flutter (3.24.5), LLVM (15.0.6) e il commit di
  vcpkg indicati in quella guida sono **vincoli di compatibilità**, non suggerimenti: con
  versioni più recenti la build non passa.
- **Ubuntu** → **[`BUILD-UBUNTU.md`](BUILD-UBUNTU.md)**
  Produce il pacchetto `.deb` installabile con `apt`. Gli stessi comandi, già pronti, sono
  quelli eseguiti dal workflow citato sopra.

---

## Server self-host

MTDesk non usa i server di RustDesk né quelli di altri fornitori: usa un **server proprio**,
che serve solo a far incontrare i due computer (trova il PC partendo dall'ID a 9 cifre e,
se la connessione diretta non passa, fa da ponte). Schermo e tasti viaggiano cifrati
end-to-end: il server vede transitare i dati, non li può leggere.

Sono due container Docker, girano su qualunque VPS anche minuscolo, e tutta la
configurazione — porte, firewall, DNS, chiavi, verifica finale — è in
**[`deploy/README-SERVER.md`](deploy/README-SERVER.md)**.

L'indirizzo del server e la sua chiave pubblica sono **già compilati dentro il programma**:
il cliente scarica, apre e vede solo ID e password. Nessuna configurazione da parte sua.

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
