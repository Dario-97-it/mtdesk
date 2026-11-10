# MTDesk — Server self-host (relay + rendezvous)

Questo è il "cervello" che permette a due MTDesk di trovarsi **su internet** tramite
l'ID numerico (di solito 9 cifre), esattamente come i server di AnyDesk. È gratis e gira su Docker.

In questi documenti lo chiamiamo anche **centralino**.

> Opera derivata di `rustdesk-server` (open source, licenza AGPL-3.0), non affiliata al
> progetto RustDesk. Container: **hbbs** (rendezvous/ID) e **hbbr** (relay).
> L'immagine Docker **la costruiamo noi** dai sorgenti della cartella
> [`../server/`](../server/README.md): l'immagine `rustdesk/rustdesk-server`, pubblicata da
> un altro progetto, **non si usa più**.

> **Stato a novembre 2026 — leggilo prima di tutto il resto.**
>
> - Il centralino su VPS **non è ancora stato messo in opera** e il nome
>   `mtdesk.marketingtools.digital` **non esiste ancora in DNS**: è esattamente il lavoro
>   descritto qui.
> - L'immagine Docker del centralino (paragrafo 2) **è stata costruita e avviata davvero** il
>   10/11/2026, sul PC Ubuntu di prova: `docker compose build` (circa 10 minuti su 2 core e
>   7 GB di memoria, immagine da 141 MB), poi avvio con `docker compose up -d` e due prove
>   superate — installazione nuova con la cartella `data` vuota, e passaggio da una `data`
>   che apparteneva a root. Quello che **non** è ancora stato fatto è il resto della catena:
>   esportare l'immagine, copiarla su un VPS vero e avviarla là.
> - Nel frattempo, per provare MTDesk fra due computer di casa c'è il centralino **in rete
>   locale** (`avvia-centralino-locale.ps1`, in questa cartella): quello è collaudato, ed è
>   spiegato in [`CLIENT-CONNESSIONE.md`](CLIENT-CONNESSIONE.md), sezione A.
>
> **È la tua prima messa in opera?** Segui
> [`../GUIDA-MESSA-IN-OPERA.md`](../GUIDA-MESSA-IN-OPERA.md): parte da zero, registrazione
> Oracle compresa, e a ogni comando dice che cosa devi vedere. Questo README è il riferimento
> più corto e più tecnico degli stessi passi, e usa la stessa cartella sul server:
> `/home/ubuntu/mtdesk`.

---

## 0) LA COSA PIÙ IMPORTANTE DI TUTTE, letta prima di iniziare

Il server ha una **coppia di chiavi** (`data/id_ed25519` privata e `data/id_ed25519.pub`
pubblica). La chiave pubblica è **già compilata dentro i client MTDesk**
(`client/libs/hbb_common/src/config.rs`, riga 119) ed è questa:

```
jc63wRwdyqs465Ndu5fP61fvB4x4CHdIAIIpw6YrQcw=
```

(Lo stesso valore è nell'appunto `CHIAVE-SERVER.txt` di questa cartella, che però esiste solo
sul PC del progetto: è escluso da git, quindi chi scarica il repository non lo trova. Per
questo in questa pagina la chiave è sempre scritta per esteso.)

Se avvii il server su un VPS nuovo **senza** portarci quei due file, hbbs al primo avvio si
genera una chiave **diversa**, e i client già compilati **non riusciranno più a
collegarsi tra loro**. Il sintomo inganna: il programma diventa comunque verde ("Pronto"),
perché il centralino gli risponde; ma appena provi a collegarti a un ID la connessione viene
rifiutata con l'errore **"La chiave non corrisponde"**.

**Quindi: copia le due chiavi sul VPS PRIMA del primissimo `docker compose up`.**
È il passo A3 della procedura qui sotto — non saltarlo e non invertire l'ordine.

L'alternativa (se preferisci ripartire da zero) è lasciar generare una chiave nuova al VPS,
rileggerla con `./mostra-chiave.sh` e **ricompilare tutti i client** con quella. Molto più
lavoro, stesso risultato. Oggi però costa meno di quanto costerà in futuro: non esiste ancora
nessuna Release pubblicata, quindi — se non hai già consegnato a mano un eseguibile a
qualcuno — cambiare chiave adesso significa una ricompilazione e nessuna reinstallazione.
La procedura è in fondo a questa pagina, in "Cambiare la chiave del centralino".

---

## 1) Dove installarlo

Il server deve stare su una macchina con **IP pubblico**, raggiungibile da internet.
Tre opzioni:

| Opzione | Costo | Note |
|---|---|---|
| **Oracle Cloud "Always Free"** | **Gratis** | Due tipi di macchina: **AMD E2.1.Micro** (1/8 OCPU, 1 GB di RAM — basta e avanza per il nostro uso) oppure **ARM Ampere A1**, la cui quota Always Free da **giugno 2026 è 2 OCPU / 12 GB** (prima era 4 OCPU / 24 GB: le guide più vecchie dicono ancora così). Consigliato. |
| VPS economico (Hetzner, Contabo, Aruba…) | ~3-5 €/mese | Semplicissimo, IP pubblico incluso, nessuna sorpresa. |
| PC/NAS di casa | Gratis | Serve **port-forwarding** sul router + IP statico o DDNS. |

RAM/CPU richieste **per farlo girare**: pochissime (gira anche su 1 vCPU / 512MB).
**Per compilarlo** invece no: una macchina così piccola non ce la fa. È il motivo per cui
l'immagine Docker si costruisce sul tuo PC e arriva sul server già fatta (paragrafo 2).

> **Attenzione all'architettura.** Un'immagine costruita su un normale PC è per processori
> **x86_64** (Intel/AMD) e gira solo su un server x86_64: su Oracle è la macchina
> **AMD E2.1.Micro**, quella indicata anche dalla guida. Su una macchina **ARM** (Ampere A1)
> quell'immagine non parte: bisognerebbe costruirne una apposta per ARM, cosa che questa
> procedura non copre.

### La regola d'oro del costo zero

Nel pannello Oracle, **non cliccare MAI "Upgrade to Pay As You Go"** (compare come banner
in alto, e come pulsante nella pagina dell'account). È un invito che sembra innocuo — "hai
più risorse!" — ma converte l'account: da quel momento tutto ciò che esce dalla quota
gratuita viene addebitato sulla carta, e la conversione **non si torna indietro**.
Finché l'account resta "Free Tier" non può generare costi: nel peggiore dei casi Oracle
rifiuta di crearti una risorsa, e basta.

### ⚠️ Il rischio vero: Oracle SPEGNE le istanze inattive

Questo è il punto che nessuno ti dice e che riguarda proprio noi. Le istanze **Always Free**
sono soggette a una politica di recupero: se per **7 giorni consecutivi** l'istanza sta
**sotto il 20% di utilizzo di CPU e di rete** (per le ARM A1 conta anche la memoria),
Oracle la considera inattiva e la **ferma**.

- L'istanza viene **fermata (stopped), non cancellata**: disco, IP e configurazione restano.
  Puoi riaccenderla dal pannello con il pulsante **Start** e riparte tutto da sola
  (i container hanno `restart: unless-stopped`).
- Ma finché è ferma, **il centralino è offline**: tutti i client MTDesk diventano rossi e
  nessuna assistenza è possibile. Te ne accorgi nel momento peggiore, cioè quando un cliente
  ti sta chiamando.

Un centralino di assistenza a basso traffico **è esattamente il profilo che Oracle spegne**:
sta fermo per giorni e consuma quasi niente. Come conviverci:

1. **Tieni d'occhio la mail** dell'account Oracle: l'avviso di istanza inattiva arriva lì.
2. **Controlla che l'istanza sia accesa prima di una sessione importante**, oppure verifica
   che il client MTDesk sia verde (è il modo più rapido: se è verde, il server risponde).
3. Se lo spegnimento diventa un fastidio ricorrente, valuta un VPS a pagamento da 3-4 €/mese:
   la politica di recupero **non si applica** alle istanze a pagamento. (In alternativa
   esistono istanze Always Free *x86* E2.1.Micro, storicamente meno colpite dai recuperi,
   ma la regola scritta nella documentazione vale per tutte le risorse Always Free.)

Non esiste una spunta "non spegnere mai" da attivare: fa parte del patto del piano gratuito.

### Piano B — se Oracle non si riesce a usare

Può succedere: la carta viene rifiutata durante la registrazione, oppure la macchina gratuita
non è disponibile. Le strade che restano sono le altre due righe della tabella qui sopra.

> **[DA DECIDERE dal proprietario: quale delle due è il piano B.]**
> Finché non è deciso, nessuna delle due è una procedura collaudata: quello che segue è
> l'elenco di che cosa cambia, non un passo-passo.

**B1 — Un VPS economico a pagamento.** È la strada più semplice. Questo README vale così
com'è dal paragrafo 2 in poi, con due sole differenze:

- non c'è il pannello Oracle: il "Firewall 1" del paragrafo 3 diventa il firewall del
  pannello del fornitore scelto, se ne ha uno (le porte da aprire sono le stesse quattro);
- dentro la macchina il firewall è spesso `ufw` invece di `iptables`: i comandi sono in fondo
  al paragrafo 3.

Il server deve essere **x86_64** (vedi "Attenzione all'architettura" più sopra), e l'utente
con cui entri può non chiamarsi `ubuntu`: in quel caso cambia il nome nei comandi e nei
percorsi (`/home/ubuntu/...`).

**B2 — Una macchina in casa (mini-PC o NAS), sempre accesa.** Costa zero ma chiede di più:

- una macchina **x86_64 accesa giorno e notte**, con Docker, su cui fare gli stessi passi del
  paragrafo 2 al posto del VPS;
- sul router di casa, l'**inoltro delle porte** (port-forwarding) verso quella macchina per
  le stesse quattro voci della tabella del paragrafo 3: 21115/TCP, 21116/TCP, 21116/UDP,
  21117/TCP;
- un nome che segua l'indirizzo di casa quando cambia (**DDNS**), perché di solito le linee
  domestiche non hanno un indirizzo fisso;
- **non toccare l'indirizzo dentro il client.** `mtdesk.marketingtools.digital` è compilato
  nel programma (`client/libs/hbb_common/src/config.rs`, riga 118): cambiarlo vuol dire
  ricompilare e ridistribuire tutto. Va invece fatto puntare a casa il record DNS `mtdesk`
  del paragrafo 4, sempre con la nuvoletta grigia.

Per questa seconda strada nel progetto **non esiste una procedura scritta né provata** (quale
servizio DDNS usare, come si configura il router, che cosa fare se il fornitore di casa non
assegna un indirizzo pubblico): se la scegli, va scritta e collaudata prima di contarci.

---

## 2) Installazione sul server (Ubuntu/Debian)

I comandi vanno dati **nell'ordine in cui sono scritti**. Sul server tutto sta nella cartella
`/home/ubuntu/mtdesk`, la stessa usata da `GUIDA-MESSA-IN-OPERA.md`.

### Prima di cominciare: l'immagine la costruisci tu, e non sul server

Il nostro `docker-compose.yml` non scarica più un'immagine fatta da altri: usa
`mtdesk-server:1.1.17`, che si costruisce dai sorgenti della cartella `server/` con la
ricetta `server/Dockerfile`.

Costruirla vuol dire **compilare** il centralino, e il VPS previsto (1/8 di CPU, 1 GB di RAM)
non è in grado di farlo: la compilazione è impostata con le ottimizzazioni più pesanti
(`lto = true` e `codegen-units = 1` in `server/Cargo.toml`). Per farlo girare basta una
macchina minuscola; per compilarlo no. Quindi la strada decisa è questa:

1. l'immagine si costruisce **sul tuo PC**;
2. si esporta in un file;
3. il file si copia sul VPS;
4. sul VPS si carica già pronta, e il centralino si avvia con `docker compose up -d`
   **senza** `--build` e **senza** `docker compose pull`.

> ℹ️ **Costruzione provata, trasferimento no.** Il 10/11/2026 l'immagine è stata costruita
> con `docker compose build` sul PC Ubuntu di prova (circa 10 minuti, 141 MB) e avviata con
> `docker compose up -d`: hbbs e hbbr sono partiti e hanno superato sia l'avvio con la
> cartella `data` vuota sia quello con una `data` che apparteneva a root. I passi 2, 3 e 4
> qui sotto — esportare l'immagine, copiarla su un VPS e caricarla là — **non** sono ancora
> stati eseguiti: la prima volta che li esegui, se un passo si ferma con un errore non è
> detto che l'errore sia tuo. Annota il messaggio e il passo in cui compare.

### Parte A — sul tuo PC: costruisci l'immagine e porta tutto sul server

Serve un PC con **Docker** e con la cartella del progetto aggiornata. Le chiavi del
centralino per costruire l'immagine **non servono**, e dentro l'immagine non finiscono.

- **PC Windows:** serve Docker Desktop, che si appoggia a WSL2. A novembre 2026 sul PC del
  progetto Docker **non è installato**, e prima c'è una cosa da sistemare: il comando
  `wsl --status` risponde che WSL2 non può partire perché la virtualizzazione non è abilitata
  (va attivato il componente di Windows "Piattaforma macchina virtuale" e/o la
  virtualizzazione nelle impostazioni del firmware, cioè nel BIOS del computer).
- **PC Ubuntu:** Docker gira direttamente, senza macchine virtuali. Serve una copia aggiornata
  del repository: è aggiornata se in `server/Dockerfile` c'è la riga
  `COPY third_party third_party` (senza quella la costruzione si ferma subito). Tieni presente
  che la configurazione, le chiavi del centralino e la chiave SSH per entrare nel VPS stanno
  sul PC Windows: l'immagine costruita su Ubuntu va quindi portata lì, oppure spedita al VPS
  dal PC Ubuntu dopo averci copiato la chiave SSH.

> **[DA DECIDERE dal proprietario: su quale dei due PC si costruisce l'immagine.]**

**A1. Costruisci l'immagine.** Apri un terminale nella cartella `deploy` del progetto (su
Windows, in PowerShell: `cd "D:\2026\VISUAL STUDIO\MTDESK\deploy"`) e dai:

```bash
docker compose build
docker image ls mtdesk-server
```

Il secondo comando deve mostrare una riga con `mtdesk-server` e, nella colonna TAG, `1.1.17`.
La prima costruzione è lunga: scarica le immagini di base e le librerie, poi compila tutto.
Quanto di preciso non è ancora stato misurato.

> Su un PC dove il file `deploy/.env` non c'è (è escluso da git, quindi in una copia appena
> scaricata manca) Docker avvisa che la variabile `MTDESK_HOST` non è impostata. Per la
> **costruzione** non conta: quel valore serve solo all'avvio, sul server.

> Nell'intestazione di `docker-compose.yml` è scritto `docker compose up -d --build`: quel
> comando costruisce **e** avvia, e ha senso solo su una macchina capace di compilare. Sul
> VPS non va usato: lì si avvia senza `--build`, come spiegato più sotto.

**A2. Esporta l'immagine in un file**, **fuori** dalla cartella del progetto (è un file
grosso e non deve finire per sbaglio nel repository). Il comando cambia secondo la finestra
in cui lo scrivi:

- **in PowerShell** (Windows):

  ```powershell
  docker save -o "$env:USERPROFILE\mtdesk-server-1.1.17.tar" mtdesk-server:1.1.17
  ```

- **in Git Bash, oppure su Ubuntu:**

  ```bash
  docker save mtdesk-server:1.1.17 | gzip > ~/mtdesk-server-1.1.17.tar.gz
  ```

> **Non usare la versione con la barra `|` dentro PowerShell.** Windows PowerShell tratta come
> testo tutto ciò che passa da un programma all'altro attraverso `|`, e un'immagine Docker
> non è testo: ne uscirebbe un file rovinato. Verificato su questo PC (PowerShell 5.1): dati
> non testuali passati così arrivano diversi da come sono partiti. Le due versioni qui sopra
> contengono la stessa immagine; quella con `gzip` è solo più piccola da trasferire.

Quel file **tienilo sul PC**: è la tua copia dell'immagine, e serve per rifare il server
senza ricompilare.

**A3. Copia sul server quello che serve, e solo quello:** i tre file di configurazione, le
due chiavi e l'immagine. Sostituisci `IL-TUO-IP` con l'indirizzo pubblico del VPS e
`PERCORSO-DELLA-CHIAVE-SSH` con il file `.key` scaricato quando hai creato il VPS (è la
chiave per *entrare* nel server: non c'entra con le chiavi del centralino). In PowerShell, una
riga per volta:

```powershell
cd "D:\2026\VISUAL STUDIO\MTDESK\deploy"
ssh -i "PERCORSO-DELLA-CHIAVE-SSH" ubuntu@IL-TUO-IP "mkdir -p /home/ubuntu/mtdesk/data"
scp -i "PERCORSO-DELLA-CHIAVE-SSH" docker-compose.yml .env mostra-chiave.sh ubuntu@IL-TUO-IP:/home/ubuntu/mtdesk/
scp -i "PERCORSO-DELLA-CHIAVE-SSH" data\id_ed25519 data\id_ed25519.pub ubuntu@IL-TUO-IP:/home/ubuntu/mtdesk/data/
scp -i "PERCORSO-DELLA-CHIAVE-SSH" "$env:USERPROFILE\mtdesk-server-1.1.17.tar" ubuntu@IL-TUO-IP:/home/ubuntu/
```

La seconda riga crea sul server la cartella del centralino con dentro `data`; la terza copia
la configurazione (compreso `.env`, il file col punto davanti); **la quarta è il passaggio
del paragrafo 0**: porta sul server le due chiavi; l'ultima copia l'immagine, ed è la più
lenta. (Se l'immagine l'hai esportata da Git Bash o da Ubuntu, il file dell'ultima riga è
`~/mtdesk-server-1.1.17.tar.gz`.)

Perché non si copia l'intera cartella `deploy` in un colpo solo: sul PC, dentro `data\`, oltre
alle chiavi ci sono i resti delle prove fatte in locale (un database e una cartella
`.config`), e sul server non devono arrivare.

> Se sul PC il file `deploy\.env` non c'è (in una copia appena scaricata manca, perché è
> escluso da git), crealo prima: copia `.env.example` in `.env` e scrivici il tuo indirizzo
> al posto di `mtdesk.esempio.it`.

### Parte B — sul server

```bash
# 1. Installa Docker  (il 'sudo' NON è opzionale: lo script installa pacchetti di sistema)
curl -fsSL https://get.docker.com | sudo sh

# 2. Permetti al tuo utente di usare Docker senza sudo ogni volta.
#    Su Oracle/Ubuntu l'utente si chiama 'ubuntu'; su altri VPS mettici il tuo nome utente.
sudo usermod -aG docker ubuntu
#    ORA ESCI E RIENTRA IN SSH (exit, poi ti ricolleghi): il nuovo gruppo vale
#    solo per le sessioni aperte DOPO il comando. Senza riconnetterti otterrai
#    "permission denied while trying to connect to the Docker daemon socket".
```

```bash
# 3. Carica l'immagine arrivata dal PC (passo A3).
#    Se l'hai esportata da Git Bash o da Ubuntu il file finisce in .tar.gz: scrivi quel
#    nome, 'docker load' legge allo stesso modo l'uno e l'altro.
docker load -i /home/ubuntu/mtdesk-server-1.1.17.tar
docker image ls mtdesk-server
#    DEVE comparire una riga 'mtdesk-server' con TAG '1.1.17'. Se non c'è, fermati qui:
#    senza l'immagine il punto 7 non può funzionare (Docker proverebbe a costruirla dalla
#    cartella ../server, che sul server non esiste).
#    Dopo averla caricata, il file .tar sul server non serve più e lo puoi cancellare.

# 4. Verifica che sia arrivato tutto, e soprattutto le chiavi, PRIMA di accendere:
cd /home/ubuntu/mtdesk
ls -la                  # devono esserci .env, docker-compose.yml, mostra-chiave.sh e la cartella data
find data -type f       # deve elencare ESATTAMENTE due file: data/id_ed25519 e data/id_ed25519.pub

# 5. I permessi della cartella 'data' NON si sistemano a mano: li sistema il contenitore
#    a ogni avvio.
#    COME FUNZIONA: dentro i container i due programmi non girano come amministratore ma
#    come un utente senza privilegi, 'mtdesk'. I file che hai appena copiato appartengono
#    invece a 'ubuntu', e cosi' 'mtdesk' non potrebbe leggere la chiave privata ne'
#    scrivere il database. Per questo il contenitore parte come amministratore, assegna
#    'data' all'utente mtdesk, impone 600 alla chiave privata e solo dopo cede i privilegi
#    (server/docker-entrypoint.sh). Vale sia all'installazione nuova sia al passaggio da
#    una 'data' che apparteneva a root: entrambe provate il 10/11/2026.
#    L'unico permesso che devi dare tu e' quello di esecuzione dello script di servizio,
#    che si perde copiando da Windows:
chmod +x mostra-chiave.sh

# 6. Controlla l'host pubblico nel file .env (e' arrivato dal PC insieme agli altri file)
cat .env                # deve contenere il TUO host, non 'mtdesk.esempio.it':
#   MTDESK_HOST=mtdesk.marketingtools.digital   (o il tuo IP pubblico)
nano .env               # solo se c'e' da correggerlo

# 7. Avvia. Cosi' com'e' scritto: SENZA '--build' (qui non c'e' niente da costruire,
#    l'immagine e' gia' caricata) e senza 'docker compose pull' (l'immagine non sta in
#    nessun archivio online: esiste solo sul tuo PC e, da adesso, su questo server).
docker compose up -d

# 8. Controlla che siano partiti tutti e due
docker compose ps

# 9. Controlla che TUTTI E DUE abbiano letto la chiave
docker compose logs hbbs | grep "Key:"
docker compose logs hbbr | grep "Key:"
#    Ognuno dei due comandi deve stampare una riga che finisce cosi':
#        Key: jc63wRwdyqs465Ndu5fP61fvB4x4CHdIAIIpw6YrQcw=

# 10. Controlla che la chiave su disco sia quella GIUSTA (quella del paragrafo 0)
./mostra-chiave.sh
#   oppure:  cat ./data/id_ed25519.pub
```

Fatto. Il server è attivo e riavvia da solo (`restart: unless-stopped`), anche dopo un
riavvio della macchina.

> **Se al punto 9 la riga `Key:` manca per hbbr, spegni subito** (`docker compose down`).
> Vuol dire che hbbr non è riuscito a leggere la chiave, e in quello stato **non si ferma e
> non segnala errori**: lavora senza controllare la chiave di chi si collega, cioè con il
> relay aperto. La causa è quasi sempre il punto 5 saltato o sbagliato: rifallo e riavvia.
> Se manca per hbbs, o se al punto 8 uno dei due risulta `Restarting`, il primo sospettato è
> lo stesso punto 5.

> Se al punto 10 la chiave **non** coincide con quella del paragrafo 0, significa che hbbs
> se n'è generata una nuova perché in `data/` le chiavi non c'erano. Ferma tutto
> (`docker compose down`), rimetti le chiavi corrette in `data/` (i comandi sono più sotto, in
> "Rimettere la chiave su un server"), cancella il file `data/db_v2.sqlite3` se presente, e
> riavvia. Dopo il punto 5 i file in `data/` appartengono all'utente del container: per
> spostarli o cancellarli serve `sudo`.

> Dal punto 5 in poi, elencando la cartella con `ls -l data`, il proprietario dei file
> comparirà come un numero, oppure con il nome di un utente del server che ha per caso lo
> stesso numero: è normale. E per leggere o copiare la chiave privata dal server servirà
> `sudo` (vedi "Backup").

### Aggiornare il centralino, e tornare indietro se va male

Non esiste più un "aggiorna all'ultima versione" in un comando solo: l'immagine nuova va
costruita, come la prima. Anche questa sequenza, come il resto del paragrafo, **non è ancora
stata provata**.

1. **Sul PC:** prima rinomina il file `.tar` dell'immagine precedente (per esempio
   aggiungendo la data al nome), così non viene sovrascritto. Poi aggiorna i sorgenti, rifai
   i passi A1 e A2 e copia sul server il file nuovo (ultima riga del passo A3).
2. **Sul server**, prima di caricare l'immagine nuova, metti da parte quella che funziona:

   ```bash
   cd /home/ubuntu/mtdesk
   docker tag mtdesk-server:1.1.17 mtdesk-server:precedente
   docker load -i /home/ubuntu/mtdesk-server-1.1.17.tar
   docker compose up -d --force-recreate
   ```

   Il primo comando dà un secondo nome all'immagine in uso: quando carichi la nuova, il nome
   `1.1.17` passa a lei, ma la vecchia resta sul server con il nome `precedente`. Poi rifai i
   controlli dei punti 8, 9 e 10.
3. **Se la nuova non va, torna indietro:**

   ```bash
   cd /home/ubuntu/mtdesk
   docker tag mtdesk-server:precedente mtdesk-server:1.1.17
   docker compose up -d --force-recreate
   ```

   Chiavi e database, in `data/`, non vengono toccati né dall'aggiornamento né dal ritorno
   indietro. Seconda rete di sicurezza: il file `.tar` vecchio che hai tenuto sul PC, da
   ricopiare e ricaricare.

`1.1.17` è la versione del centralino scritta in `server/Cargo.toml` e nelle due righe
`image:` di `docker-compose.yml`. Il giorno in cui cambia, cambia anche in tutti i comandi di
questa pagina.

---

## 3) Porte da aprire — e i DUE firewall di Oracle

Queste sono le porte usate dal nostro `docker-compose.yml`:

| Porta | Protocollo | Servizio |
|---|---|---|
| 21115 | TCP | hbbs — NAT type test |
| 21116 | TCP | hbbs — rendezvous (registrazione e ricerca dell'ID) |
| 21116 | **UDP** | hbbs — heartbeat / hole-punching · **obbligatoria** |
| 21117 | TCP | hbbr — relay (quando la connessione diretta non passa) |

Le porte **21118 e 21119** restano **chiuse di proposito**, ma è bene sapere che cosa sono:
non servono "solo al client via browser", come diceva la prima versione di questo paragrafo.
Sono il trasporto **WebSocket** di hbbs e hbbr, e anche il programma MTDesk per PC ha
un'opzione per usarlo (Impostazioni → Rete → "Usa WebSocket"). L'idea sarebbe farlo passare
dalla porta 443 per un cliente chiuso dietro una rete aziendale che blocca le porte alte
21115-21117: da lì, oggi, MTDesk non si collega, e dal lato del cliente non c'è rimedio.

Perché non le apriamo, e perché aprirle non basterebbe:

- pubblicate così come sono resterebbero senza HTTPS e sempre su porte alte, quindi quel caso
  non lo risolverebbero: servirebbe davanti a loro un reverse proxy HTTPS sulla 443, che oggi
  in `deploy/` **non c'è**;
- su quelle porte i due programmi si fidano dell'indirizzo IP dichiarato da chi si collega (lo
  dicono i commenti in `server/src/relay_server.rs` e `server/src/rendezvous_server.rs`),
  quindi vanno raggiunte solo attraverso un proxy che lo riscriva, mai direttamente;
- **soprattutto: attraverso WebSocket un PC non riesce a registrarsi sul nostro centralino.**
  Quando la richiesta di registrazione arriva da una connessione TCP o WebSocket invece che
  dall'UDP, hbbs risponde "non supportato" (`NOT_SUPPORT`, funzione `handle_tcp` in
  `server/src/rendezvous_server.rs`), e un PC che non si registra non è raggiungibile. È ciò
  che dice anche l'avviso mostrato dal programma accanto a "Usa WebSocket" (nell'originale
  inglese: il server open source non include questa funzione; la traduzione italiana è
  imprecisa).

Quindi oggi quel ripiego **non si attiva con la sola configurazione**: oltre al proxy
richiederebbe una modifica al codice del centralino. Meno porte aperte, meno superficie di
attacco: se le trovi citate in guide trovate online, non aprirle.

> **[DA DECIDERE dal proprietario: se investire in questo ripiego]** (modifica al centralino,
> reverse proxy HTTPS, prova da una rete che blocca le porte alte) **oppure accettare che da
> quelle reti MTDesk non funzioni.**

> **21116 TCP e 21116 UDP sono DUE regole distinte.** Hanno lo stesso numero ma sono due
> protocolli diversi e vanno aperte separatamente, in entrambi i firewall. È l'errore più
> comune: si apre solo il TCP, il client sembra collegarsi ma poi le sessioni non partono
> o cadono, perché l'heartbeat viaggia in UDP.

### Su Oracle Cloud i firewall sono DUE, in serie

Il traffico deve passare **due controlli indipendenti**. Aprire solo uno dei due non serve
a niente: il pacchetto viene bloccato dall'altro, e senza messaggi d'errore utili.

**Firewall 1 — Security List (o Network Security Group) nel pannello Oracle**
Networking → Virtual Cloud Networks → la tua VCN → Subnets → la subnet → Security Lists →
la default → **Add Ingress Rules**. Per ognuna delle righe della tabella sopra:

| Campo | Valore |
|---|---|
| Stateless | No |
| Source Type | CIDR |
| Source CIDR | `0.0.0.0/0` |
| IP Protocol | TCP (oppure UDP per la riga UDP) |
| Destination Port Range | `21115`, `21116`, `21117` (una regola per porta/protocollo) |

**Firewall 2 — iptables dentro Ubuntu**
Le immagini Ubuntu di Oracle arrivano con **iptables già attivo e già popolato**, e di
fabbrica **blocca tutto in ingresso tranne la porta 22** (SSH). Va aperto a mano:

```bash
sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 21115 -j ACCEPT
sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 21116 -j ACCEPT
sudo iptables -I INPUT 6 -m state --state NEW -p udp --dport 21116 -j ACCEPT
sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 21117 -j ACCEPT

# Rendi le regole permanenti, altrimenti al riavvio spariscono:
sudo netfilter-persistent save
# (se il comando non esiste:  sudo apt install -y iptables-persistent  e conferma "yes")

# Controlla il risultato:
sudo iptables -L INPUT -n --line-numbers
```

> **Una cosa che queste regole NON fanno.** Le quattro porte sono pubblicate da **Docker**, e
> Docker le fa arrivare ai container con regole sue (le catene `DOCKER` e `FORWARD`), che non
> passano dalla catena `INPUT`. Quindi le regole qui sopra non fanno danni e restano dove
> sono, ma **non sono loro a decidere chi entra** su quelle porte, e lo stesso vale per `ufw`
> più sotto: non puoi usarle per tenere fuori qualcuno.
>
> Se un giorno serve davvero bloccare un indirizzo (per esempio uno che abusa del
> centralino), il posto giusto è la catena **`DOCKER-USER`**, quella che Docker lascia apposta
> a chi amministra la macchina:
>
> ```bash
> sudo iptables -I DOCKER-USER -s 203.0.113.45 -j DROP    # 203.0.113.45 = l'indirizzo da bloccare
> sudo netfilter-persistent save
> ```
>
> Tutte le regole di questa pagina sono **IPv4**. Il record DNS che creiamo al paragrafo 4 è
> di tipo A, quindi i client arrivano in IPv4; se un giorno attivi IPv6 sul server servono
> regole a parte (`ip6tables`), che qui non sono trattate.
>
> È il comportamento documentato di Docker; su un nostro VPS non è ancora stato osservato,
> perché il VPS non esiste ancora. La prova, quando ci sarà, è il controllo 4 del paragrafo 5.

**Non usare `ufw` su Oracle** se non sai già cosa stai facendo: convive male con le regole
iptables preesistenti e un `ufw enable` dato senza prima aver permesso la porta 22 ti
chiude fuori dal server. Su altri VPS (Hetzner, Contabo…) dove ufw è il firewall standard,
l'equivalente è:

```bash
sudo ufw allow 22/tcp          # PRIMA di tutto, o ti chiudi fuori
sudo ufw allow 21115:21117/tcp
sudo ufw allow 21116/udp
sudo ufw enable
```

---

## 4) DNS col tuo dominio (Cloudflare)

Serve per scrivere `mtdesk.marketingtools.digital` nei client invece di un IP, e per poter
cambiare VPS in futuro senza ricompilare niente.

Su Cloudflare: dominio `marketingtools.digital` → **DNS** → **Add record**, esattamente così:

| Campo | Valore da mettere |
|---|---|
| **Type** | `A` |
| **Name** | `mtdesk` |
| **IPv4 address** | l'IP pubblico del VPS (es. `130.61.xx.xx`) |
| **Proxy status** | **DNS only** — la nuvoletta deve essere **GRIGIA**, non arancione |
| **TTL** | `Auto` |

Il risultato è il nome completo `mtdesk.marketingtools.digital`, che è esattamente quello
compilato dentro i client.

### Perché la nuvoletta GRIGIA (e non l'arancione)

La nuvoletta arancione attiva il **proxy** di Cloudflare: il traffico non va più al tuo VPS
ma ai server Cloudflare, che lo inoltrano. Funziona solo per **HTTP e HTTPS** (porte 80 e
443). MTDesk usa porte proprie (21115-21117) e anche l'UDP: con il proxy attivo quel
traffico **non passa e basta**, e in più il DNS risponderebbe con un IP di Cloudflare
invece del tuo, quindi i client tenterebbero di collegarsi a una macchina che non è la tua.

Con la nuvoletta grigia Cloudflare fa solo da anagrafe DNS: risponde con il tuo IP vero e
il traffico va diretto al VPS. È quello che serve.

> Conseguenza: l'IP del VPS è pubblicamente visibile. Per un centralino di relay è normale
> e non è un problema — è comunque una macchina che deve accettare connessioni da internet.

Dopo aver salvato, verifica dal tuo PC (il risultato deve essere l'IP del VPS):

```bash
nslookup mtdesk.marketingtools.digital
```

---

## 5) Verifica che funzioni

```bash
docker compose ps            # entrambi i container 'Up'
docker compose logs -f hbbs  # nei log vedrai i client che si registrano
```

Cinque controlli in ordine, dal più vicino al più lontano:

1. `docker compose ps` → `mtdesk-hbbs` e `mtdesk-hbbr` sono **Up**. Accanto c'è lo stato del
   controllo di salute definito nel `docker-compose.yml` (ogni 30 secondi prova la porta di
   ciascun programma): `(health: starting)` all'inizio, poi `(healthy)` se la porta risponde,
   `(unhealthy)` se no.
2. `./mostra-chiave.sh` → la chiave è quella del paragrafo 0 (`jc63w…`), e la riga `Key:`
   compare nei log di **entrambi** i container (punto 9 del paragrafo 2).
3. `nslookup mtdesk.marketingtools.digital` → risponde con l'IP del VPS.
4. Dal tuo PC, prova ad aprire la porta 21116 da fuori:
   - Windows (PowerShell): `Test-NetConnection mtdesk.marketingtools.digital -Port 21116`
     → deve rispondere `TcpTestSucceeded : True`.
   - Ubuntu (terminale): `nc -vz mtdesk.marketingtools.digital 21116`
     → deve rispondere `succeeded!` (se manca il comando: `sudo apt install netcat-openbsd`).

   Se il risultato è negativo è quasi sempre un firewall: ricontrolla **entrambi** quelli
   del punto 3, e ricorda che la 21116 va aperta sia in TCP sia in UDP.
5. Dal client MTDesk: se in basso l'indicatore diventa **verde** ("Pronto/Ready"),
   sei connesso al tuo server. ✅

---

## Comandi utili

```bash
docker compose restart       # riavvia
docker compose down          # ferma (i dati/chiavi restano in ./data)
docker compose up -d         # riaccende (senza --build: sul server non si costruisce niente)
docker compose logs --tail 50 hbbs            # ultime 50 righe di log
```

Per **aggiornare** non c'è un comando solo, e `docker compose pull` non serve (l'immagine
non sta in nessun archivio online da cui scaricarla): la procedura è nel paragrafo 2,
"Aggiornare il centralino, e tornare indietro se va male".

## Chi può usare il centralino: la chiave è pubblica, i freni sono altri

È facile farsi un'idea sbagliata, quindi va detto una volta sola e chiaramente.

**La chiave `jc63w…` è pubblica per progetto.** È compilata dentro ogni programma MTDesk ed è
scritta in chiaro in questo repository. Non è una password: serve ai client per
**riconoscere il centralino vero** (che firma le sue risposte con la chiave *privata*, quella
sì segreta), non a tenere fuori qualcuno.

Che cosa fa l'opzione `-k _` con cui partono hbbs e hbbr (`docker-compose.yml`): rifiuta le
richieste di collegamento e di relay che non riportano quella chiave. Tiene quindi fuori un
programma generico configurato a caso, **non** chi ha in mano un MTDesk o ha letto questa
pagina. In più, la semplice **registrazione** di un PC sul centralino (porta 21116) non
controlla nessuna chiave: lì l'unico freno è un limite di frequenza per indirizzo IP.

Quello che protegge davvero la banda del relay sono **i tetti e le liste**.

**I tetti di banda** sono tre righe del servizio hbbr in `docker-compose.yml`:

| Impostazione | Valore oggi | Che cosa limita |
|---|---|---|
| `SINGLE_BANDWIDTH` | 16 | Mb/s massimi per una singola sessione |
| `TOTAL_BANDWIDTH` | 32 | Mb/s massimi per tutte le sessioni messe insieme |
| `LIMIT_SPEED` | 8 | Mb/s per le sessioni "declassate" e per gli indirizzi in `blacklist.txt` |

Una sessione viene declassata da sola quando, passata la prima mezz'ora, ha viaggiato in
media oltre i due terzi del suo tetto: il nostro uso normale ne resta lontanissimo (il
commento nel `docker-compose.yml` lo stima in 1-3 Mb/s per sessione).

Fai però il conto: con `TOTAL_BANDWIDTH=32` un abuso continuo, giorno e notte per un mese,
arriverebbe a circa 10,9 TB di traffico in uscita, cioè poco sopra i 10 TB al mese compresi
nel piano gratuito di Oracle. Per questo conviene **guardare una volta al mese**, nel
pannello Oracle, il traffico di rete in uscita dell'istanza. Se cresce senza motivo, i tre
valori si abbassano in `docker-compose.yml` e poi si dà `docker compose up -d`.

**Le due liste** sono file di testo, con un indirizzo IP per riga, da mettere in `data/` sul
server (`/home/ubuntu/mtdesk/data/`, che dentro il container è `/data`). Occhio ai nomi, che
si somigliano:

| File | Effetto |
|---|---|
| `blocklist.txt` | gli indirizzi elencati vengono **rifiutati** dal relay |
| `blacklist.txt` | gli indirizzi elencati vengono **rallentati** a `LIMIT_SPEED` |

Li legge **hbbr**, e **solo all'avvio**: dopo averli creati o modificati serve riavviarlo.
Per esempio, per rifiutare l'indirizzo `203.0.113.45`:

```bash
cd /home/ubuntu/mtdesk
echo "203.0.113.45" | sudo tee -a data/blocklist.txt
docker compose restart hbbr
docker compose logs --tail 30 hbbr | grep "#blocklist"
```

L'ultimo comando mostra la riga che hbbr scrive all'avvio, `#blocklist(blocklist.txt):`
seguita da un numero (ce n'è una uguale per `#blacklist`): se il numero è 0, il file non è
stato letto. Il `sudo` serve perché la cartella `data/` appartiene all'utente del container.

Le liste valgono **solo per il relay**. Per impedire a un indirizzo di raggiungere anche
hbbs serve la regola `DOCKER-USER` descritta nel paragrafo 3.

## Dati personali: che cosa resta sul centralino

Serve saperlo per rispondere a un cliente che lo chiede e per tenere allineata l'informativa
(`docs/privacy.html`).

| Dove | Che cosa | Per quanto |
|---|---|---|
| `data/db_v2.sqlite3`, tabella `peer` | Per ogni PC che si è registrato: l'ID, un identificativo della macchina (`uuid`), la chiave pubblica di quel PC (`pk`), la data della **prima** registrazione (`created_at`) e l'ultimo indirizzo IP noto (dentro il campo `info`) | **Senza scadenza**: nel codice del centralino non esiste nessuna cancellazione |
| Registri (log) di Docker dei due container | Righe che riportano ID e indirizzi IP: in hbbs le registrazioni (`update_pk …`) e i cambi di indirizzo (`IP change of …`), in hbbr le richieste di relay con l'indirizzo di chi le fa | Fino a 3 file da 10 MB per container (blocco `x-logging` di `docker-compose.yml`); oltre, Docker elimina i più vecchi |

Due conseguenze da conoscere:

- **Può registrarsi chiunque** raggiunga la porta 21116, anche senza la chiave e anche se non
  è un nostro cliente (vedi il paragrafo precedente): nella tabella possono quindi finire
  anche PC di estranei.
- **Non c'è una data di "ultima attività".** `created_at` viene scritto solo alla prima
  registrazione e poi non cambia più: dal database non si capisce quali PC siano ancora in
  uso.

> **[DA DECIDERE dal proprietario: per quanto tempo si conservano questi dati e ogni quanto
> si fa pulizia.]** È lo stesso punto rimasto aperto in `docs/privacy.html`. Finché non è
> deciso **non esiste nessuna cancellazione automatica**: quello che segue si fa a mano.

**Cancellare a mano** (su richiesta di un cliente, o per fare pulizia). Va fermato hbbs,
perché tiene in memoria una copia dei dati, e serve lo strumento `sqlite3`:

```bash
cd /home/ubuntu/mtdesk
sudo apt install -y sqlite3            # solo la prima volta
docker compose stop hbbs               # il centralino resta fermo finché non lo riaccendi

# guarda che cosa c'è
sudo sqlite3 data/db_v2.sqlite3 "select id, created_at, info from peer order by created_at;"

# cancella UN PC (metti il suo ID al posto di 123456789)
sudo sqlite3 data/db_v2.sqlite3 "delete from peer where id = '123456789';"

# oppure: cancella tutto ciò che si è registrato più di GIORNI giorni fa.
# GIORNI è il numero ancora da decidere: sostituiscilo con una cifra prima di dare il comando.
sudo sqlite3 data/db_v2.sqlite3 "delete from peer where created_at < datetime('now', '-GIORNI days');"

# riaccendi: i permessi lasciati da sqlite3 (usato come amministratore) li rimette a posto
# il contenitore stesso, che a ogni avvio riassegna 'data' all'utente mtdesk
docker compose start hbbs
```

Da sapere:

- un PC cancellato su cui MTDesk è ancora in uso **si registra di nuovo da solo** alla prima
  occasione: la cancellazione toglie davvero un PC solo se il programma lì non gira più;
- i registri di Docker non si puliscono riga per riga: scorrono da soli per via del limite di
  dimensione. Per svuotarli subito: `docker compose down` e poi `docker compose up -d` (i
  registri appartengono ai container, e `down` li elimina insieme a loro);
- le tre istruzioni `sqlite3` sono state provate su un database di prova creato da
  `server/schema.sql`; l'intera sequenza su un VPS vero non ancora.

## Backup

### Che cosa va salvato davvero

**I due file delle chiavi**, `id_ed25519` (la privata, 88 caratteri) e `id_ed25519.pub` (la
pubblica, 44 caratteri). Perderli significa che **tutti i client già distribuiti vanno
ricompilati** con la chiave nuova e riconsegnati. Il database invece si ricrea da solo: i PC
ancora in uso si registrano di nuovo.

**Dove sono oggi (novembre 2026): per quanto risulta dal progetto, in un posto solo**, la
cartella `deploy\data\` sul PC. Il VPS non esiste ancora, quindi lì non c'è una seconda
copia; e GitHub **non** è un backup, perché quella cartella è esclusa da git di proposito
(`deploy/data/` è nel nostro `.gitignore`): la chiave privata nel repository non c'è, e non
deve finirci mai. Se non esistono altre copie e quel disco si rompe oggi, la chiave è persa.

> **[DA FARE dal proprietario, e da annotare qui quando è fatto: due copie della chiave
> fuori da questo PC.]** Per esempio una su una chiavetta tenuta in un altro posto, dentro un
> archivio protetto da password, e una nel gestore di password (sono due righe di testo: si
> possono incollare in una nota protetta). Se una copia fuori dal PC esiste già, oggi non è
> annotata da nessuna parte. Finché questa riga non viene sostituita con "copie fatte il …,
> conservate in …", la chiave va considerata **non al sicuro**.

### Rimettere la chiave su un server (ripristino)

Serve quando sul server la chiave è stata persa o sovrascritta. (Per un VPS nuovo non serve:
basta rifare il paragrafo 2, dove il passo A3 porta già le chiavi.) Anche questa sequenza è
scritta sul codice e **non ancora provata**.

1. Sul server, ferma il centralino:

   ```bash
   cd /home/ubuntu/mtdesk
   docker compose down
   ```

2. Dal PC, copia i due file in una cartella di passaggio del server. Non direttamente in
   `data/`: quella cartella appartiene all'utente del container e non ti lascerebbe scrivere.

   ```powershell
   cd "D:\2026\VISUAL STUDIO\MTDESK\deploy"
   scp -i "PERCORSO-DELLA-CHIAVE-SSH" data\id_ed25519 data\id_ed25519.pub ubuntu@IL-TUO-IP:/home/ubuntu/
   ```

   (Se riparti da una delle copie di riserva invece che dal PC, i file da ricreare sono gli
   stessi due, ciascuno con dentro la sua riga di testo.)

3. Sul server, mettili al loro posto e ridai i permessi giusti, come al punto 5 del
   paragrafo 2:

   ```bash
   cd /home/ubuntu/mtdesk
   sudo mv /home/ubuntu/id_ed25519 /home/ubuntu/id_ed25519.pub data/
   # i permessi non si toccano: li riassegna il contenitore al prossimo avvio
   sudo chmod 600 data/id_ed25519
   sudo chmod 644 data/id_ed25519.pub
   ```

4. Riaccendi (`docker compose up -d`) e rifai i controlli dei punti 8, 9 e 10 del
   paragrafo 2: tutti e due i container devono scrivere la riga `Key:` con la chiave giusta.

### Una copia della cartella `data/` dal server al PC

Quando il VPS sarà in funzione, la sua cartella `data/` conterrà anche il database. Per
portarne una copia sul PC, **sul server**:

```bash
cd /home/ubuntu/mtdesk
sudo tar czf /home/ubuntu/mtdesk-data-$(date +%F).tar.gz data
sudo chown ubuntu:ubuntu /home/ubuntu/mtdesk-data-*.tar.gz
chmod 600 /home/ubuntu/mtdesk-data-*.tar.gz
ls -lh /home/ubuntu/mtdesk-data-*.tar.gz
```

Il `sudo` serve perché la chiave privata è leggibile solo dall'utente del container.
L'ultimo comando ti mostra il nome esatto del file, che contiene la data di oggi. Poi,
**sul PC** (metti quel nome al posto di `mtdesk-data-AAAA-MM-GG.tar.gz`):

```powershell
scp -i "PERCORSO-DELLA-CHIAVE-SSH" ubuntu@IL-TUO-IP:/home/ubuntu/mtdesk-data-AAAA-MM-GG.tar.gz "$env:USERPROFILE"
```

Infine cancella l'archivio dal server (`rm /home/ubuntu/mtdesk-data-*.tar.gz`): contiene la
chiave privata in una forma che l'utente `ubuntu` può leggere. Sul PC quell'archivio va
trattato come la chiave stessa: dentro un backup cifrato, non in una cartella sincronizzata
in chiaro.

> **Non ancora fatto.** Una copia **automatica e periodica** (per esempio una volta alla
> settimana) non esiste: si potrà preparare solo quando il VPS ci sarà. Fino ad allora questa
> copia va fatta a mano e messa in calendario. E una **prova di ripristino** vera, su una
> macchina usa-e-getta, non è mai stata fatta: finché non la fai, non sai se il backup serve.

### Non solo il server: la rubrica del tecnico

L'elenco dei PC a cui ti sei collegato **non sta sul centralino**: sta nella cartella di
configurazione di MTDesk sul **tuo** PC. MTDesk non ha una rubrica condivisa né una console
di gestione: se quel PC si rompe, l'elenco dei clienti (e le password di accesso che hai
fatto ricordare al programma) va perso, e nessun server te lo ridà.

| Sistema | Cartella |
|---|---|
| Windows | `%APPDATA%\MTDesk\` (i file sono nella sottocartella `config`) |
| Ubuntu | `~/.config/MTDesk/` |

Mettila nel backup del PC, e che sia un backup **cifrato**: lì dentro ci sono i dati di
accesso ai computer dei clienti.

## Cambiare la chiave del centralino (rotazione)

Si fa se la chiave privata è finita, o potrebbe essere finita, in mani sbagliate; oppure se
vuoi ripartire con una chiave nata direttamente sul server. **Non esiste revoca:** il
centralino conosce una sola chiave alla volta, e ai programmi già in giro non si può dire
"quella vecchia non vale più" se non sostituendoli.

> **[DA DECIDERE dal proprietario, e il momento giusto è adesso.]** La chiave privata attuale
> vive dal 25 agosto 2026 nella cartella del progetto su un PC Windows, ed è usata per le
> prove in rete locale. Non esiste ancora nessuna Release pubblicata: rigenerarla oggi,
> direttamente sul VPS, costa una ricompilazione dei client e nessuna reinstallazione presso i
> clienti. Dopo la prima distribuzione costerà la sostituzione di ogni programma consegnato.

La procedura qui sotto è scritta sul codice e **non è ancora stata provata**: prima di
usarla sul centralino vero, va provata una volta su una macchina di prova.

1. **Sul server, fai nascere la coppia nuova.** A centralino fermo sposta via le chiavi
   vecchie (non cancellarle subito) e riaccendi: non trovando la chiave, il centralino ne
   crea una nuova da solo.

   ```bash
   cd /home/ubuntu/mtdesk
   docker compose down
   sudo mkdir -p /home/ubuntu/chiavi-vecchie
   sudo mv data/id_ed25519 data/id_ed25519.pub /home/ubuntu/chiavi-vecchie/
   docker compose up -d
   docker compose down          # spegni e riaccendi una seconda volta: così TUTTI E DUE
   docker compose up -d         # i programmi rileggono la stessa chiave dal file appena creato
   sudo chmod 600 data/id_ed25519
   ./mostra-chiave.sh           # questa è la chiave pubblica NUOVA: copiala
   docker compose logs hbbs | grep "Key:"
   docker compose logs hbbr | grep "Key:"
   ```

   Le due righe `Key:` devono riportare la stessa chiave stampata da `mostra-chiave.sh`.

2. **Scrivi la chiave nuova nel codice**, in tutti e due i punti (le due copie di
   `hbb_common` devono restare uguali):
   - `client/libs/hbb_common/src/config.rs`, riga 119 (`RS_PUB_KEY`);
   - `server/libs/hbb_common/src/config.rs`, riga 119.

   Poi negli altri file che la riportano. Per trovarli tutti, dalla cartella del progetto:

   ```bash
   git grep -n "jc63wRwdyqs465Ndu5fP61fvB4x4CHdIAIIpw6YrQcw="
   ```

   Uno conta più degli altri: `.github/workflows/mtdesk-build.yml` contiene un controllo che
   **ferma di proposito la compilazione automatica** se in `config.rs` non trova esattamente
   la chiave attesa, quindi va aggiornato insieme al codice. Gli altri sono documenti (questa
   pagina, `CLIENT-CONNESSIONE.md`, la guida) e l'appunto `CHIAVE-SERVER.txt`, che non essendo
   in git quel comando non trova.

3. **Ricompila i client** (`client/BUILD-WINDOWS.md` per Windows, `BUILD-UBUNTU.md` per
   Ubuntu) e distribuiscili.

4. **Porta la coppia nuova sul PC**, in `deploy\data\` al posto della vecchia (per copiarla
   dal server usa "Una copia della cartella `data/` dal server al PC", qui sopra), e rifai le
   copie di sicurezza: quelle della chiave vecchia non servono più. Lo script del centralino
   in rete locale confronta la chiave in `deploy\data\` con quella scritta in `config.rs` e
   ti avvisa se non combaciano.

5. **Il passaggio dai programmi vecchi ai nuovi.** Non c'è un periodo in cui valgono tutte e
   due le chiavi. Dal punto 1 in poi un programma con la chiave vecchia diventa ancora verde,
   ma quando prova a collegarsi a un altro PC riceve "La chiave non corrisponde". A un
   programma vecchio che non puoi sostituire subito si può scrivere la chiave nuova a mano
   (Impostazioni → Rete → "Server ID/Relay" → campo **Key**): quella scritta lì vince su
   quella compilata.
