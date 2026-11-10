# MTDesk — Come collegare i client al tuo server

Nei file MTDesk che si distribuiscono **non c'è niente da configurare**: l'indirizzo del
centralino (`mtdesk.marketingtools.digital`) e la sua chiave pubblica sono compilati dentro
il programma (`client/libs/hbb_common/src/config.rs`, righe 118 e 119). Il cliente apre il
file e vede solo ID e password.

Questo documento serve per tutto il resto: provare MTDesk in rete locale prima che il
centralino su internet esista (sezione A), sapere che cosa cambia su internet (B), scegliere
come il cliente ti fa entrare (C) e far puntare un programma a un centralino diverso da
quello compilato (D).

> **Stato a novembre 2026.** Il centralino su internet **non è ancora attivo**: il nome
> `mtdesk.marketingtools.digital` non esiste ancora in DNS (la messa in opera è descritta in
> `README-SERVER.md`). Fino ad allora un MTDesk appena aperto **non arriva a "Pronto"**: non è
> un guasto del programma, è che dall'altra parte non risponde ancora nessuno. Per provarlo
> oggi serve il centralino in rete locale della sezione A.

---

## A) TEST SUBITO in rete locale (senza VPS e senza DNS)

Il centralino gira sul PC Windows del progetto; un secondo computer collegato alla stessa
rete (per esempio il PC Ubuntu) lo raggiunge al suo indirizzo locale. Serve a vedere due
MTDesk che si trovano e si controllano **prima** di avere un server su internet.

**Che cosa serve**

- I due programmi del centralino già compilati per Windows:
  `server\target\release\hbbs.exe` e `hbbr.exe`. Se mancano, lo script qui sotto si ferma e
  ti scrive il comando per compilarli; i dettagli sono in
  [`../server/README.md`](../server/README.md), "Come si costruisce".
- Le chiavi del centralino in `deploy\data\` (`id_ed25519` e `id_ed25519.pub`).
- **MTDesk completo** su tutti e due i computer. Non `MTDesk-qs.exe`: quello è il file di
  assistenza rapida per il cliente e **rifiuta le connessioni in uscita**, quindi da lì non
  puoi controllare l'altro PC. Sul PC del progetto va bene il programma appena compilato
  (`client\flutter\build\windows\x64\runner\Release\MTDesk.exe`); su Ubuntu il pacchetto
  `.deb` installato.

**1. Avvia il centralino sul PC Windows.** Apri PowerShell nella cartella del progetto
(`D:\2026\VISUAL STUDIO\MTDESK`) e dai:

```powershell
powershell -ExecutionPolicy Bypass -File deploy\avvia-centralino-locale.ps1
```

Lo script fa i controlli al posto tuo, e a ogni passo scrive `OK` oppure `!!`:

- controlla che i due programmi e le chiavi ci siano, e che la chiave pubblica in
  `deploy\data\` sia **la stessa compilata nel client**;
- trova l'indirizzo di questo PC nella rete locale (del tipo `192.168.1.x`);
- controlla il firewall di Windows: servono aperte le porte 21115, 21116 (TCP **e** UDP) e
  21117. Se non lo sono e PowerShell non è stata aperta **come amministratore**, lo script
  non può aprirle: te lo dice e stampa i quattro comandi `New-NetFirewallRule` da dare, una
  volta sola, in una PowerShell aperta come amministratore (dopo, puoi rilanciarlo
  aggiungendo `-SaltaFirewall`);
- avvia hbbr e hbbs e prova che le tre porte TCP rispondano;
- alla fine stampa il riquadro **CENTRALINO ATTIVO**, con l'indirizzo e la chiave da scrivere
  nei client.

**Lascia quella finestra aperta**: chiuderla (o premere Ctrl+C) ferma il centralino.

**2. Imposta il centralino in MTDesk, su OGNI computer** (anche su quello dove gira il
centralino). Nella finestra principale clicca i **tre puntini (⋮)** accanto al tuo ID: si
aprono le **Impostazioni**. Vai su **Rete** → **Server ID/Relay** e compila:

| Campo | Che cosa scrivere |
|---|---|
| **ID server** | l'indirizzo stampato dallo script (per esempio `192.168.1.20`) |
| **Server relay** | lo stesso indirizzo |
| **Server API** | lascia vuoto |
| **Key** | la chiave stampata dallo script: `jc63wRwdyqs465Ndu5fP61fvB4x4CHdIAIIpw6YrQcw=` |

Premi **OK**. Due avvertenze:

- se MTDesk è **installato**, la pagina Rete è bloccata finché non premi **Sblocca
  impostazioni di rete** e confermi la richiesta da amministratore;
- nel riquadro dello script i due campi sono chiamati "Server ID" e "Server inoltro": sono gli
  stessi, che nel programma si chiamano "ID server" e "Server relay".

Su **Ubuntu**, a programma installato, le stesse tre impostazioni si possono dare dal
terminale. Serve `sudo`: senza, il programma risponde
`Installation and administrative privileges required!`.

```bash
sudo mtdesk --option custom-rendezvous-server 192.168.1.20
sudo mtdesk --option relay-server 192.168.1.20
sudo mtdesk --option key jc63wRwdyqs465Ndu5fP61fvB4x4CHdIAIIpw6YrQcw=
```

**3. Chiudi e riapri MTDesk.** In basso il pallino deve diventare **verde**, con la scritta
**Pronto**. Se resta arancione o rosso, quel computer non raggiunge il PC del centralino:
ricontrolla il firewall del punto 1 e che i due computer siano sulla stessa rete.

**4. Collegati.** Sul PC-A leggi l'**ID** e la **password**. Sul PC-B scrivi quell'ID nel
riquadro **Controlla desktop remoto**, premi **Connetti**, digita la password → **controlli il
PC-A**. ✅

**5. Finita la prova, rimetti tutto com'era.** Finché quei campi restano compilati il
programma cerca il centralino all'indirizzo locale e **ignora quello compilato**: al
centralino vero non arriverebbe mai. Riapri **Rete → Server ID/Relay**, svuota i quattro
campi e premi **OK**; oppure, su Ubuntu:

```bash
sudo mtdesk --option custom-rendezvous-server ""
sudo mtdesk --option relay-server ""
sudo mtdesk --option key ""
```

Se funziona in rete locale, i due programmi del centralino, le chiavi e i client sono a
posto. Su internet cambiano due cose: l'indirizzo, e il fatto che lì il centralino gira
dentro Docker — una prova a parte, ancora da fare (vedi `README-SERVER.md`).

---

## B) USO SU INTERNET (come AnyDesk)

Quando il centralino sarà in opera su un VPS pubblico (vedi `README-SERVER.md`), nei client
**non ci sarà niente da impostare**.

> Nel **client MTDesk compilato** indirizzo e chiave **sono già dentro** (hardcoded):
> il cliente scarica l'exe, lo apre, e vede solo ID + password. Zero configurazione.

I valori compilati sono questi. Sono anche quelli che scriveresti a mano in
**Impostazioni → Rete → Server ID/Relay** se un giorno servisse, per esempio per usare l'IP
pubblico del VPS mentre il DNS non è ancora pronto:

- **ID server:**  `mtdesk.marketingtools.digital`  *(o l'IP pubblico del VPS)*
- **Key:** `jc63wRwdyqs465Ndu5fP61fvB4x4CHdIAIIpw6YrQcw=`
  *(è la chiave pubblica del centralino: sul server la stampa `./mostra-chiave.sh`. Se lì
  esce una chiave diversa, fermati e leggi il paragrafo 0 di `README-SERVER.md`.)*

---

## C) Come il cliente ti fa entrare

### Quale file ha in mano il cliente

| File | Che cosa fa | Per che cosa usarlo |
|---|---|---|
| `MTDesk-qs.exe` (Windows) | **Assistenza rapida.** Finestra piccola con ID, password monouso, stato del collegamento e pulsante per uscire. Non si installa e non può controllare altri PC. | L'aiuto "adesso, una volta" |
| `MTDesk-windows-x86_64-install.exe` (Windows) | **Si installa.** Apre la schermata di installazione; una volta installato resta sul PC come servizio di Windows ("MTDesk Service"), che parte da solo a ogni accensione. | L'assistenza che si ripete |
| pacchetto `.deb` (Ubuntu) | Si installa e attiva il servizio `mtdesk`. | Tutti e due i casi |

I due file per Windows sono **lo stesso programma con due nomi**: è il nome del file a
decidere come si comporta (lo spiega il commento in `client/build.py`, dove vengono creati).

Tre cose da sapere sul file di assistenza rapida, per non promettere al cliente più di quello
che è vero:

- **All'avvio Windows chiede il permesso di amministratore** (la finestra UAC) e, poiché il
  file non è firmato, in quella finestra l'autore risulta sconosciuto. Avvisa il cliente
  prima, altrimenti si spaventa e chiude.
- **"Non si installa" non vuol dire "non lascia niente".** Non crea servizi; ma per
  funzionare si scompatta in `%LOCALAPPDATA%\MTDesk` (circa 72 MB), e quella cartella resta
  sul disco anche dopo la chiusura. Si può cancellare a mano.
- **Funziona solo finché la finestra è aperta.** Chiusa quella, da fuori non entra più
  nessuno. Alla riapertura la password monouso è diversa; l'ID invece è lo stesso di prima.

Per sapere se su un PC Windows MTDesk è **installato**: apri l'elenco dei Servizi di Windows
e cerca **MTDesk Service**. Se c'è, il programma è installato e si avvia da solo. Si toglie
come ogni altro programma, dall'elenco delle app installate di Windows (voce **MTDesk**).

### Di fabbrica: password oppure clic

Senza toccare niente, MTDesk accetta una sessione in **due modi**, e ne basta uno:

- il tecnico scrive la **password** che il cliente gli detta; oppure
- il tecnico preme Connetti e il cliente, nella finestrella che gli compare, preme
  **Accetta**.

Per l'aiuto al volo va bene così: il cliente ti detta l'ID e poi o ti legge la password, o
preme Accetta. La password monouso di fabbrica è di 6 caratteri; si può portare a 8 o a 10 da
**Impostazioni → Sicurezza**, riquadro **Password**, voce **Lunghezza password monouso**.

### Profilo A — cliente presente: si entra solo con il suo clic

Sul PC del cliente: **Impostazioni → Sicurezza**, riquadro **Password**, e nel menu a tendina
in cima scegli **Accetta sessioni via clic**. Da quel momento la password non basta più a
nessuno: ogni collegamento deve essere confermato con **Accetta** da chi è davanti allo
schermo. Il cliente ti detta solo l'ID.

### Profilo B — computer non presidiato: si entra con una password fissa

Serve per entrare quando vuoi, senza che qualcuno confermi ogni volta. Richiede MTDesk
**installato** (il file `…-install.exe`, oppure il `.deb`): solo così c'è un servizio attivo
anche quando nessuno ha aperto il programma.

1. Sul PC del cliente: **Impostazioni → Sicurezza**, riquadro **Password**. Nel menu a
   tendina scegli **Accetta sessioni via password**, poi seleziona **Usa password
   permanente**: se non ce n'è ancora una, il programma ti chiede subito di sceglierla (per
   cambiarla in seguito c'è il pulsante **Imposta password permanente**).
2. Il cliente ti comunica **ID + quella password** una volta sola.
3. Tu ti colleghi quando serve, anche a schermo bloccato.

Se la pagina Sicurezza è bloccata, premi prima **Sblocca impostazioni sicurezza**.

> **Su Ubuntu questo profilo non è ancora stato provato.** Dalla versione 25.10 il desktop di
> Ubuntu usa solo Wayland, e per l'accesso non presidiato su Wayland nel codice esiste una
> variante apposita del pacchetto (`mtdesk-unattended-wayland`, che si ottiene con
> `build.py --drm`): non è ancora stata costruita né provata. Fino a prova fatta, a un cliente
> Ubuntu non promettere l'accesso senza nessuno davanti allo schermo.

---

## D) Deploy "zero-config" dal nome del file (avanzato, solo Windows)

Su **Windows** MTDesk può leggere la configurazione anche dal **nome del proprio file .exe**:
se nel nome compare `host=` (ed eventualmente, dopo una virgola, `key=`), quell'indirizzo e
quella chiave vincono sia su quelli compilati sia su quelli scritti nelle impostazioni. Su
Ubuntu questo meccanismo non c'è.

```
MTDesk-host=192.168.1.20,key=jc63wRwdyqs465Ndu5fP61fvB4x4CHdIAIIpw6YrQcw=.exe
```

Con i file MTDesk distribuiti **non serve**: indirizzo e chiave del nostro centralino sono
già compilati dentro. Può servire per far puntare un programma a un centralino diverso (per
esempio quello in rete locale della sezione A) senza aprire le impostazioni.

Prima di usarlo, due avvertenze:

- **Il nome decide anche il comportamento.** Un nome che finisce in `install.exe` fa
  comparire la schermata di installazione; un nome che contiene `-qs.exe`, `_qs.exe` o `-qs-`
  apre la finestra di assistenza rapida. Rinominando il file come nell'esempio qui sopra si
  perdono tutte e due le cose: si apre il programma completo, che non si installa da solo.
- **Non è ancora stato provato con i file MTDesk attuali.** Il meccanismo è nel codice
  (`client/src/custom_server.rs`), ma prima di consegnare a qualcuno un file rinominato così,
  provalo.

---

## Nota: e un RustDesk "originale" come banco di prova?

Le prime versioni di questa pagina suggerivano di scaricare RustDesk dal sito del progetto
originale per provare il server. **Non serve più e non è consigliato:** la prova si fa con due
MTDesk (sezione A), che è esattamente ciò che useranno i clienti. In più, su Ubuntu i due
programmi non possono stare insieme: il pacchetto `mtdesk` dichiara `Conflicts: rustdesk` e
`Replaces: rustdesk` (`client/build.py`), quindi installarne uno fa togliere l'altro.
