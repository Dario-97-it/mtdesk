# MTDesk - Guida alla messa in opera del centralino

**Per chi e' questa guida:** per te, che non hai mai messo piede in un server.
Ogni passo dice **cosa scrivere** e soprattutto **cosa devi vedere** per sapere che e' andata bene.
Se quello che vedi non corrisponde, **fermati** e vai alla sezione 12 ("Se non funziona").

**Cosa otterrai:** un "centralino" tuo su internet, a costo zero, che permette a due MTDesk
di trovarsi tramite l'ID a 9 cifre, esattamente come fanno i server di AnyDesk.

**Quanto ci vuole:** circa 2 ore la prima volta, di cui 30 minuti di attesa per Oracle.

**Nomi che userai sempre, tieniteli a mente:**

| Cosa | Valore |
|---|---|
| Indirizzo del centralino | `mtdesk.marketingtools.digital` |
| Chiave pubblica attesa | `jc63wRwdyqs465Ndu5fP61fvB4x4CHdIAIIpw6YrQcw=` |
| Porte | 21115/TCP, 21116/TCP, 21116/UDP, 21117/TCP |
| Cartella da copiare sul server | `D:\2026\VISUAL STUDIO\MTDESK\deploy` |

---

> **Nota sui percorsi.** In questa guida la cartella del progetto è
> `D:6\VISUAL STUDIO\MTDESK`. Fino a novembre 2026 era su `H:`, e tutti i comandi
> qui dentro puntavano a quel disco: dopo la formattazione del PC il progetto è su `D:` e i
> comandi sono stati corretti. **Se un giorno sposti la cartella, i comandi con il percorso
> scritto per esteso vanno aggiornati**, altrimenti falliscono con
> `No such file or directory`.

## REGOLA D'ORO (leggila due volte)

> Nel pannello Oracle, **non cliccare MAI** su **"Upgrade to Pay As You Go"** (o "Esegui upgrade
> ad account a pagamento"). E' l'unico interruttore che trasforma il tuo account gratuito in un
> account che puo' generare fatture. Oracle te lo proporra' in continuazione, in alto nella pagina,
> nelle email e dentro le finestre di creazione: **ignoralo sempre**.
>
> Se resti sul piano "Always Free" e usi solo le risorse contrassegnate come **"Always Free
> Eligible"**, il conto e' zero. Se sfori, Oracle **blocca** la risorsa, non ti manda il conto.

Secondo avviso: non cancellare la riga di budget/limiti se Oracle te ne propone uno. Al contrario,
al punto 1.6 ti faccio impostare un avviso di spesa a 1 euro come rete di sicurezza.

---

## 0. Cosa avere sotto mano prima di iniziare

1. **Una carta**. Serve solo per la verifica dell'identita'.
   - **Funzionano**: carte di credito Visa/Mastercard, e nella maggior parte dei casi le
     **carte di debito Visa/Mastercard** (quelle delle banche tradizionali, con il numero a 16 cifre
     e il CVV sul retro).
   - **Non funzionano**: PostePay e altre **prepagate**, carte **virtuali** o usa-e-getta (Revolut
     virtuali, Hype in certi casi), carte di sola erogazione. Oracle le rifiuta in fase di
     registrazione con un errore generico che non spiega niente.
   - Oracle fa una **preautorizzazione di circa 1 euro** (a volte 1 dollaro). **Non e' un addebito**:
     e' un blocco temporaneo che serve a verificare che la carta esista, e sparisce da solo in
     pochi giorni. Nell'app della banca lo vedrai come "autorizzazione" o "impegno", non come spesa.
2. **Un numero di cellulare** dove ricevere un SMS.
3. **Un indirizzo email** che controlli subito (serve confermare un link).
4. **Accesso al pannello Cloudflare** del dominio `marketingtools.digital`.
5. **Il PC Windows** con la cartella `D:\2026\VISUAL STUDIO\MTDESK\` (contiene le chiavi del
   centralino: senza quelle, l'exe che hai gia' compilato non si collega piu').
6. **Un secondo dispositivo** per il collaudo finale: un portatile che collegherai
   all'hotspot 4G del telefono. Serve al punto 10.5 e non e' rimandabile.

---

## 1. Registrazione su Oracle Cloud

### 1.1 Apri la pagina giusta
Vai su **https://www.oracle.com/cloud/free/** e clicca **"Start for free"**.

### 1.2 Paese e nome
Metti **Italy** come paese, nome e cognome veri, e la tua email. Poi verifica l'email:
Oracle ti manda un link, cliccalo.

**DEVI VEDERE:** il modulo di registrazione lungo (password, indirizzo, carta).

### 1.3 LA SCELTA IRREVERSIBILE: la Home Region
Nel modulo c'e' un campo **"Home Region"** (o "Regione di residenza").

> **Scegli `Germany Central (Frankfurt)` — cioe' `eu-frankfurt-1`.**
>
> Questa scelta **non si puo' piu' cambiare** dopo. Non esiste un pulsante, non esiste un
> supporto che te la cambia: se sbagli, devi cancellare l'account e ricominciare da un'altra
> email. Controlla due volte prima di andare avanti.

Perche' Francoforte: e' vicina (latenza bassa verso l'Italia, circa 25-35 ms), e' dentro l'Unione
Europea (i dati restano in UE, cosa che ti semplifica la vita lato GDPR), ed e' una delle regioni
con maggiore disponibilita' di macchine gratuite.

Non scegliere Milano: e' una regione piccola e le macchine gratuite sono quasi sempre esaurite.

### 1.4 La carta
Inserisci i dati della carta. Oracle fa la preautorizzazione da ~1 euro di cui sopra.

**SE LA CARTA VIENE RIFIUTATA**, nell'ordine:
1. Controlla che i pagamenti online e internazionali siano abilitati nell'app della banca.
2. Prova un'altra carta di debito **di una banca tradizionale** (non prepagata, non virtuale).
3. Se hai due rifiuti, **non insistere**: Oracle a volte blocca l'email dopo piu' tentativi.
   Fermati e dimmelo: si passa al piano B (mini-PC in casa con DDNS, anche quello a costo zero),
   che e' descritto in `deploy/README-SERVER.md`.

### 1.5 Attesa
Dopo l'invio, Oracle prepara l'account. Puo' volerci da 2 minuti a 25 minuti.

**DEVI VEDERE:** una email con oggetto tipo "Your Oracle Cloud Account is ready" o simile, e
poi il pannello (si chiama **Console OCI**) che si apre su una dashboard blu scuro.

### 1.6 Rete di sicurezza: avviso di spesa
Nella Console, in alto a sinistra clicca il menu a tre linee -> **Billing & Cost Management**
-> **Budgets** -> **Create Budget**. Metti importo **1** (euro) e la soglia di avviso al **100%**,
con la tua email. Salva.

A cosa serve: se per qualsiasi motivo iniziasse a maturare anche 1 euro di spesa, ti arriva
un'email **subito**, invece di scoprirlo dopo un mese.

---

## 2. Creare la macchina (l'istanza)

### 2.1 Vai alla creazione
Menu a tre linee -> **Compute** -> **Instances** -> pulsante **Create instance**.

### 2.2 Nome
Chiamala `mtdesk-server`. Lascia il compartimento proposto (si chiama come il tuo account, va bene).

### 2.3 Immagine e shape: il passaggio da non sbagliare
Nella sezione **Image and shape** clicca **Edit**, poi **Change image**:
scegli **Canonical Ubuntu** versione **22.04** (o 24.04, vanno bene entrambe). Conferma.

Poi clicca **Change shape** -> scheda **Ampere** / **Specialty and previous generation** in base a
cosa ti mostra -> ti serve la voce:

> **`VM.Standard.E2.1.Micro`** — processore **AMD**, 1/8 di OCPU, 1 GB di RAM.
> Dev'esserci scritto accanto **"Always Free Eligible"**.

**Perche' l'AMD E2.1.Micro e non l'ARM (`VM.Standard.A1.Flex`)**, anche se l'ARM sulla carta e'
molto piu' potente (piu' core e molta piu' RAM; la quota gratuita ARM e' stata ridotta nel
tempo, quindi non fidarti dei numeri che trovi nelle guide vecchie):
1. L'ARM gratuito e' **sempre esaurito** nelle regioni europee. Ti risponde
   `Out of host capacity` e possono volerci settimane di tentativi per averla.
2. Il nostro centralino consuma **quasi niente**: due processi che smistano pacchetti.
   1 GB di RAM e' abbondante, non e' un compromesso.
3. L'AMD e' **x86_64**, la stessa architettura del tuo PC: l'immagine Docker
   `rustdesk/rustdesk-server` su x86_64 e' quella piu' usata e collaudata al mondo.
4. Del piano gratuito hai **due** macchine AMD Micro: se un giorno rompi questa, ne accendi
   un'altra senza pagare.

**DEVI VEDERE:** nel riquadro riassuntivo, "VM.Standard.E2.1.Micro" e l'etichetta verde/blu
"Always Free Eligible" o "Always free".

### 2.4 Rete
Nella sezione **Networking** lascia che crei una nuova VCN (rete virtuale) per te.
Verifica solo che **"Assign a public IPv4 address"** sia su **Yes**. Senza indirizzo pubblico la
macchina non e' raggiungibile da internet e tutto il resto e' inutile.

### 2.5 LA CHIAVE SSH: si scarica UNA SOLA VOLTA
Sezione **Add SSH keys**. Lascia selezionato **"Generate a key pair for me"** e clicca
**"Save private key"**: il browser scarica un file tipo `ssh-key-2026-09-26.key`.

> Questo file e' **l'unica** chiave d'ingresso alla macchina. Oracle **non** te lo ridara' mai piu':
> non esiste un "scaricalo di nuovo". Se lo perdi, l'unico modo per rientrare e' buttare la
> macchina e rifarla da zero.

Fai adesso, non dopo:
1. Crea la cartella `D:\2026\VISUAL STUDIO\MTDESK\chiavi-vps\` (fuori da GitHub: la riga
   `*.key` e' gia' in `.gitignore`, quindi non finira' mai pubblicata).
2. Spostaci il file e rinominalo `mtdesk-oracle.key`.
3. **Fanne una seconda copia** su una chiavetta USB o nel tuo gestore di password.

Scarica anche la chiave pubblica ("Save public key") se te lo propone: costa zero e un giorno
puo' servire.

### 2.6 Crea
Clicca **Create**. La macchina passa da **PROVISIONING** (arancione) a **RUNNING** (verde) in
1-2 minuti.

**DEVI VEDERE:** stato **RUNNING** e, nella scheda dell'istanza, un **Public IP address**
(un numero tipo `130.61.x.x` o `141.147.x.x`). **Scrivilo su un foglio.**

### 2.7 Rendere l'IP definitivo (IP riservato)
Di default l'indirizzo pubblico e' **"ephemeral"**: se un giorno spegni e riaccendi la macchina,
Oracle te ne da' uno **nuovo** e il tuo DNS punta nel vuoto. Va reso riservato.

Dalla pagina dell'istanza: scorri in basso fino a **Resources** -> **Attached VNICs** -> clicca
il nome della VNIC -> **IPv4 Addresses** -> sui tre puntini della riga -> **Edit** -> alla voce
**Public IP Type** scegli **"Reserved public IP"** -> dagli il nome `mtdesk-ip` -> **Update**.

> **Attenzione:** in molti casi Oracle, passando a "riservato", ti assegna un indirizzo
> **DIVERSO** da quello di prima. E' normale. Per questo facciamo questo passo **ora**,
> prima di scrivere il DNS.
>
> **Torna sulla pagina dell'istanza, rileggi il Public IP address e usa QUELLO** per tutto
> il resto della guida. Se e' cambiato, cancella il numero che avevi scritto sul foglio.

**DEVI VEDERE:** nella riga IPv4, il tipo indicato come "Reserved".

---

## 3. Aprire le porte nel pannello Oracle (Security List)

Ci sono **due** firewall in serie, e li devi aprire entrambi. Questo e' il primo: quello del
pannello Oracle. Il secondo, dentro Ubuntu, e' al punto 5. Se ne apri solo uno, non funziona
niente e non capisci perche'.

### 3.1 Arriva alla Security List
Dalla pagina dell'istanza clicca sul nome della **Subnet** (sotto "Primary VNIC") -> poi, in
**Security Lists**, clicca **"Default Security List for ..."**.

### 3.2 Aggiungi le 4 regole
Clicca **Add Ingress Rules**. Per **ognuna** delle 4 righe qui sotto compila cosi':

- **Stateless**: casella **NON** spuntata (cioe' regola *stateful*)
- **Source Type**: `CIDR`
- **Source CIDR**: `0.0.0.0/0`
- **IP Protocol**: TCP oppure UDP, come da tabella
- **Destination Port Range**: il numero della porta
- **Description**: il testo suggerito (serve a te fra sei mesi)

| # | Protocollo | Porta | Description | A cosa serve |
|---|---|---|---|---|
| 1 | **TCP** | 21115 | MTDesk hbbs - test tipo NAT | capire che tipo di rete ha il cliente |
| 2 | **TCP** | 21116 | MTDesk hbbs - rendezvous | trovare il PC dall'ID a 9 cifre |
| 3 | **UDP** | 21116 | MTDesk hbbs - heartbeat | tenere il client "verde" e collegato |
| 4 | **TCP** | 21117 | MTDesk hbbr - relay | far passare il video quando il P2P non passa |

> **IL PUNTO CHE SBAGLIANO TUTTI:** le righe 2 e 3 hanno lo **stesso numero (21116)** ma sono
> **DUE REGOLE SEPARATE**, una TCP e una UDP. Non esiste una scelta "TCP e UDP insieme".
> Se ne metti una sola, il client sembra funzionare per qualche secondo e poi torna grigio.
> Prima di andare avanti, **conta le righe: devono essere quattro.**

Scorciatoia, se preferisci: puoi fare **una** regola TCP con Destination Port Range `21115-21117`
al posto delle righe 1, 2 e 4 — ma la regola **UDP 21116** resta comunque da fare a parte.

Non aprire 21118 e 21119: sono per il client via browser, che nel nostro `docker-compose.yml`
e' stato **volutamente rimosso**. Meno porte aperte, meno superficie d'attacco.

**DEVI VEDERE:** nella tabella delle Ingress Rules, le tue 4 righe nuove (piu' quella
preesistente della porta 22, che serve per SSH: **non toccarla**).

---

## 4. Primo accesso SSH da Windows

### 4.1 Apri PowerShell
Tasto Windows, scrivi `powershell`, Invio. Si apre una finestra blu/nera. Da qui in avanti,
quando scrivo "in PowerShell", intendo questa finestra **sul tuo PC**, non sul server.

### 4.2 Metti a posto i permessi della chiave (fallo PRIMA di collegarti)
Windows assegna ai file scaricati permessi "larghi", e SSH rifiuta di usare una chiave che
potrebbero leggere altri utenti. Preveniamolo. Incolla queste tre righe, una per volta:

```powershell
cd "D:\2026\VISUAL STUDIO\MTDESK\chiavi-vps"
icacls "mtdesk-oracle.key" /inheritance:r
icacls "mtdesk-oracle.key" /grant:r "$($env:USERNAME):(R)"
```

Cosa fanno: la seconda taglia i permessi ereditati dalla cartella, la terza dice "solo io,
e in sola lettura".

**DEVI VEDERE:** `Elaborazione completata per 1 file` (oppure `Successfully processed 1 files`).

### 4.3 Collegati
Sostituisci `IL-TUO-IP` con il numero che hai scritto sul foglio al punto 2.7:

```powershell
ssh -i "D:\2026\VISUAL STUDIO\MTDESK\chiavi-vps\mtdesk-oracle.key" ubuntu@IL-TUO-IP
```

L'utente e' **`ubuntu`** (non `root`, non il tuo nome).

La prima volta ti chiede:
`The authenticity of host ... can't be established. Are you sure you want to continue connecting?`
Rispondi scrivendo **`yes`** per intero e Invio. E' normale e succede una volta sola.

**DEVI VEDERE:** qualche riga di benvenuto Ubuntu e infine un prompt cosi':

```
ubuntu@mtdesk-server:~$
```

Da questo momento **tutto quello che scrivi finisce sul server**, non sul tuo PC. Per uscire:
`exit`.

### 4.4 Se qualcosa non va

| Errore a schermo | Cosa significa | Cosa fare |
|---|---|---|
| `WARNING: UNPROTECTED PRIVATE KEY FILE!` / `bad permissions` | permessi della chiave troppo larghi | rifai il punto 4.2; se resiste, copia la chiave in `C:\Users\<tuonome>\.ssh\` e ripeti `icacls` la' |
| `Permission denied (publickey)` | chiave sbagliata o utente sbagliato | verifica di aver scritto `ubuntu@`, e che il file `.key` sia quello scaricato per **questa** istanza |
| Resta appeso e poi `Connection timed out` | la regola porta 22 nella Security List non c'e' piu', o l'IP e' sbagliato | ricontrolla l'IP sulla pagina dell'istanza (potrebbe essere cambiato al punto 2.7) |
| `Connection refused` | l'IP e' raggiungibile ma SSH non risponde | la macchina sta ancora avviandosi: aspetta 2 minuti e riprova |
| `ssh: command not found` | manca il client SSH di Windows | Impostazioni -> App -> Funzionalita' opzionali -> Aggiungi -> "Client OpenSSH" |

---

## 5. Il firewall INTERNO di Ubuntu (prima di Docker)

Questo e' il punto dove si perdono tutti, per un motivo preciso: **le immagini Ubuntu di Oracle
arrivano con un firewall interno gia' attivo** che blocca tutto tranne SSH. Tu apri le porte nel
pannello, sei convinto di aver finito, e invece i pacchetti vengono buttati dentro la macchina.

### 5.1 Guarda com'e' adesso
Sul server (prompt `ubuntu@...$`):

```bash
sudo iptables -L INPUT -n --line-numbers
```

**DEVI VEDERE** qualcosa di simile (i numeri possono variare):

```
Chain INPUT (policy ACCEPT)
num  target     prot opt source     destination
1    ACCEPT     all  --  0.0.0.0/0  0.0.0.0/0    state RELATED,ESTABLISHED
2    ACCEPT     icmp --  0.0.0.0/0  0.0.0.0/0
3    ACCEPT     all  --  0.0.0.0/0  0.0.0.0/0
4    ACCEPT     tcp  --  0.0.0.0/0  0.0.0.0/0    tcp dpt:22
...
6    REJECT     all  --  0.0.0.0/0  0.0.0.0/0    reject-with icmp-host-prohibited
```

Quella riga **REJECT** in fondo e' il muro: dice "tutto il resto, rifiutalo".

### 5.2 Fai una copia di sicurezza delle regole attuali

```bash
sudo mkdir -p /etc/iptables
sudo iptables-save | sudo tee /etc/iptables/rules.v4.ORIGINALE > /dev/null
```

Ti servira' se vuoi tornare indietro (sezione 13). Non salta questo passo: costa 3 secondi.

### 5.3 Aggiungi le 4 porte

```bash
sudo iptables -I INPUT -p tcp --dport 21115 -j ACCEPT
sudo iptables -I INPUT -p tcp --dport 21116 -j ACCEPT
sudo iptables -I INPUT -p udp --dport 21116 -j ACCEPT
sudo iptables -I INPUT -p tcp --dport 21117 -j ACCEPT
```

`-I INPUT` (I maiuscola, sta per *Insert*) mette la regola **in cima** alla lista, quindi
**prima** del muro REJECT. Se usassi `-A` (Append) la metterebbe **dopo** il muro e non
servirebbe a niente: il pacchetto sarebbe gia' stato rifiutato.

Di nuovo: **21116 due volte**, una `-p tcp` e una `-p udp`.

### 5.4 Controlla

```bash
sudo iptables -L INPUT -n --line-numbers | head -12
```

**DEVI VEDERE** le tue 4 righe ACCEPT in cima (ai numeri 1-4), con `dpt:21115`, `dpt:21116`
(due volte, una tcp e una udp) e `dpt:21117`, e la riga REJECT **sotto** di loro.

### 5.5 Rendile permanenti
Le regole di `iptables` vivono in memoria: **al primo riavvio spariscono** e il centralino
smette di funzionare senza motivo apparente. Installiamo il pezzo che le risalva:

```bash
sudo apt update
sudo DEBIAN_FRONTEND=noninteractive apt install -y iptables-persistent
sudo netfilter-persistent save
```

**DEVI VEDERE:** `run-parts: executing /usr/share/netfilter-persistent/plugins.d/15-ip4tables save`
e nessun errore rosso.

(`DEBIAN_FRONTEND=noninteractive` evita che l'installazione si blocchi su una finestra blu che
chiede "vuoi salvare le regole attuali?" e resti la' ad aspettare una risposta.)

### 5.6 NON usare `ufw`

> **Non scrivere `sudo ufw enable`.** Su Oracle, `ufw` non conosce le regole che ci sono gia' e,
> attivandosi, in molti casi **chiude anche la porta 22**: perdi SSH e l'unico modo per rientrare
> e' la console seriale del pannello Oracle (roba da sistemisti) o buttare la macchina.
>
> Le regole `iptables` che hai appena messo fanno esattamente lo stesso lavoro, e le hai messe
> guardando in faccia quelle esistenti. Va bene cosi'.

### 5.7 Come si riconosce QUALE firewall ti sta bloccando

Questa tabella e' oro: imparala, ti fa risparmiare ore. Da PowerShell **sul tuo PC**, quando
proverai una porta, la risposta ti dice **dove** si e' fermato il pacchetto:

| Cosa vedi dal tuo PC | Dove e' il blocco |
|---|---|
| Resta appeso 20 secondi, poi **timeout** / nessuna risposta | **Pannello Oracle**: manca la regola nella Security List (il pacchetto viene buttato via in silenzio, prima di arrivare alla macchina) |
| Risposta **immediata** di rifiuto: `No route to host` / `host prohibited` | **Firewall interno di Ubuntu**: la macchina c'e' e ti risponde "vietato". Manca un comando del punto 5.3 |
| `Connection refused` | **Nessun firewall**: sei arrivato fino in fondo, ma **non c'e' nessun programma in ascolto** su quella porta. I container sono spenti -> vedi punto 8 |
| Funziona | tutto a posto |

Nota: la porta **22** (SSH) risponde `Connection refused` solo se il servizio SSH e' spento, che
non e' il nostro caso. Se SSH funziona ma le porte 2111x no, il problema e' per forza in una
delle prime due righe della tabella.

---

## 6. Installare Docker

### 6.1 Installa
Sul server:

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
```

Ci vogliono 1-3 minuti e scorrono molte righe: e' normale.

**DEVI VEDERE**, in fondo, un riquadro di testo di Docker e nessun `E:` rosso.

### 6.2 Dai il permesso al tuo utente
Senza questo, ogni comando Docker va scritto con `sudo` davanti e la vita e' peggiore:

```bash
sudo usermod -aG docker ubuntu
```

### 6.3 Riconnettiti (obbligatorio)
Il permesso appena dato vale solo dalla **prossima** sessione. Quindi:

```bash
exit
```

e poi, da PowerShell, ricollegati con lo stesso comando del punto 4.3.

### 6.4 Verifica

```bash
docker --version
docker compose version
docker ps
```

**DEVI VEDERE:** due numeri di versione e poi una tabella **vuota** con le intestazioni
`CONTAINER ID   IMAGE   COMMAND ...`.

Se `docker ps` risponde `permission denied while trying to connect to the Docker daemon socket`,
non ti sei riconnesso davvero: rifai il punto 6.3.

---

## 7. Copiare la cartella `deploy/` sul server (IL PASSO PIU' IMPORTANTE)

### 7.1 Perche' e' il piu' importante
Dentro `deploy\data\` ci sono i due file `id_ed25519` e `id_ed25519.pub`: sono **l'identita'
criptografica del tuo centralino**.

L'exe MTDesk che hai gia' compilato ha quella chiave pubblica **scritta dentro**
(`client/libs/hbb_common/src/config.rs`, riga 118). Se avvii il server **senza** copiare
`data/`, il server se ne genera una **nuova e diversa**, e allora:

- l'exe gia' compilato **non si collega piu'**;
- ti tocca correggere `config.rs` e **ricompilare tutto**;
- e ogni exe gia' dato a un cliente diventa carta straccia.

Quindi: **prima copi `data/`, poi accendi.** Mai il contrario.

### 7.2 Cosa c'e' davvero nella cartella (verificato)

```
D:\2026\VISUAL STUDIO\MTDESK\deploy\
  .env                    <- inizia con un PUNTO: contiene MTDESK_HOST
  .env.example            <- solo il modello, per chi clona il progetto
  CHIAVE-SERVER.txt       <- appunto con la chiave pubblica
  CLIENT-CONNESSIONE.md   <- documentazione
  README-SERVER.md        <- documentazione
  docker-compose.yml      <- la ricetta dei due container
  docker-compose.yml.bak  <- vecchia versione, innocua, si copia e si ignora
  mostra-chiave.sh        <- stampa la chiave pubblica
  data\
    id_ed25519            <- CHIAVE PRIVATA (mai su GitHub, mai per email)
    id_ed25519.pub        <- chiave pubblica
    db_v2.sqlite3         <- database interno del server
```

### 7.3 Copia (da PowerShell, sul tuo PC)
Apri una finestra PowerShell **nuova** (se sei ancora collegato al server, quella e' occupata:
scrivi `exit` o apri una seconda finestra). Sostituisci `IL-TUO-IP`:

```powershell
scp -i "D:\2026\VISUAL STUDIO\MTDESK\chiavi-vps\mtdesk-oracle.key" -r "D:\2026\VISUAL STUDIO\MTDESK\deploy" ubuntu@IL-TUO-IP:/home/ubuntu/
```

Le **virgolette** attorno ai percorsi sono obbligatorie: `VISUAL STUDIO` contiene uno spazio e
senza virgolette il comando si spezza in due e da' errore.

**DEVI VEDERE:** una riga per ogni file con una barra di avanzamento e `100%`.
Deve comparire anche `.env` e i file dentro `data`.

### 7.4 Verifica che i file nascosti siano arrivati (non saltarlo)
Sul server:

```bash
mv /home/ubuntu/deploy /home/ubuntu/mtdesk
cd /home/ubuntu/mtdesk
ls -la
ls -la data/
```

**DEVI VEDERE** nel primo elenco il file **`.env`** (i file che iniziano col punto si vedono solo
con `ls -la`, ecco perche' uso quello) e nel secondo i tre file `db_v2.sqlite3`, `id_ed25519`,
`id_ed25519.pub`.

**SE `.env` NON C'E'**, copialo da solo, nominandolo esplicitamente (da PowerShell):

```powershell
scp -i "D:\2026\VISUAL STUDIO\MTDESK\chiavi-vps\mtdesk-oracle.key" "D:\2026\VISUAL STUDIO\MTDESK\deploy\.env" ubuntu@IL-TUO-IP:/home/ubuntu/mtdesk/.env
```

**SE `data/` E' VUOTA O MANCA:**

```powershell
scp -i "D:\2026\VISUAL STUDIO\MTDESK\chiavi-vps\mtdesk-oracle.key" -r "D:\2026\VISUAL STUDIO\MTDESK\deploy\data" ubuntu@IL-TUO-IP:/home/ubuntu/mtdesk/
```

### 7.5 Controlla il contenuto di `.env`

```bash
cat /home/ubuntu/mtdesk/.env
```

**DEVI VEDERE**, in fondo, esattamente:

```
MTDESK_HOST=mtdesk.marketingtools.digital
```

### 7.6 Proteggi la chiave privata e rendi eseguibile lo script

```bash
chmod 600 /home/ubuntu/mtdesk/data/id_ed25519
chmod +x /home/ubuntu/mtdesk/mostra-chiave.sh
```

Il primo comando dice "questo file lo legge solo il proprietario". Il secondo serve perche' il
permesso di esecuzione si perde nel passaggio da Windows (Windows non ha questo concetto).

### 7.7 Solo se in futuro modifichi questi file con il Blocco note
Ho controllato: **oggi `.env`, `docker-compose.yml` e `mostra-chiave.sh` hanno le interruzioni
di riga in formato Unix (LF)**, quindi vanno bene cosi' come sono e non devi fare niente.

Ma se un domani apri uno di questi file con il **Blocco note di Windows** e lo risalvi, Windows
puo' aggiungere dei caratteri invisibili (CR) a fine riga. Il sintomo e' bizzarro: il server parte
ma il relay non funziona, oppure `./mostra-chiave.sh` risponde
`/usr/bin/env: bash\r: No such file or directory`. La cura, sul server:

```bash
cd /home/ubuntu/mtdesk
sed -i 's/\r$//' .env docker-compose.yml mostra-chiave.sh
docker compose up -d --force-recreate
```

Consiglio: per modificare quei file usa **Visual Studio Code** o `nano` direttamente sul server,
non il Blocco note.

---

## 8. Accendere il centralino

### 8.1 Avvia

```bash
cd /home/ubuntu/mtdesk
docker compose up -d
```

La prima volta scarica l'immagine (circa 30-60 secondi di righe che scorrono).

**DEVI VEDERE**, in fondo:

```
 Container mtdesk-hbbr  Started
 Container mtdesk-hbbs  Started
```

### 8.2 Controlla che siano vivi

```bash
docker compose ps
```

**DEVI VEDERE** due righe, `mtdesk-hbbs` e `mtdesk-hbbr`, con STATUS che inizia per **`Up`**
(per esempio `Up 30 seconds`).

Se vedi `Restarting` o `Exited`, guarda il perche':

```bash
docker compose logs --tail 40
```

### 8.3 Controlla che stiano ascoltando sulle porte giuste

```bash
sudo ss -tulpn | grep 2111
```

**DEVI VEDERE** quattro righe: `tcp ... :21115`, `tcp ... :21116`, `udp ... :21116`,
`tcp ... :21117`.

Se manca la riga **udp**, il problema e' nel `docker-compose.yml` (deve contenere la riga
`"21116:21116/udp"`): controlla di aver copiato il file giusto e non il `.bak`.

### 8.4 LA VERIFICA DECISIVA: la chiave e' quella giusta?

```bash
cat /home/ubuntu/mtdesk/data/id_ed25519.pub
```

oppure, piu' leggibile:

```bash
cd /home/ubuntu/mtdesk && ./mostra-chiave.sh
```

**DEVE uscire ESATTAMENTE questa riga:**

```
jc63wRwdyqs465Ndu5fP61fvB4x4CHdIAIIpw6YrQcw=
```

**SE LA CHIAVE E' DIVERSA**, significa che il server e' partito **prima** che `data/` fosse al
suo posto, e si e' generato una chiave nuova, sovrascrivendo la tua. Non e' un dramma, si ripara
in 4 comandi:

```bash
cd /home/ubuntu/mtdesk
docker compose down
rm -f data/id_ed25519 data/id_ed25519.pub
# adesso torna su PowerShell e ricopia data/ (comando del punto 7.4), poi:
docker compose up -d
./mostra-chiave.sh
```

Ricontrolla: ora deve uscire `jc63wRwdyqs...`. La copia buona e originale delle chiavi resta
sempre sul tuo PC in `D:\2026\VISUAL STUDIO\MTDESK\deploy\data\`, quindi non puoi perderle.

**Se invece la chiave e' quella giusta**, il centralino e' in piedi e parla la stessa lingua
dell'exe che hai gia' compilato. Il piu' e' fatto.

---

## 9. Il record DNS su Cloudflare

Ora diamo un nome all'indirizzo numerico, cosi' l'exe che cerca
`mtdesk.marketingtools.digital` trova la macchina.

### 9.1 Crea il record
Entra su **https://dash.cloudflare.com** -> clicca il dominio **marketingtools.digital** ->
menu **DNS** -> **Records** -> **Add record**. Compila cosi':

| Campo | Valore |
|---|---|
| Type | **A** |
| Name | **mtdesk** (solo questo: Cloudflare aggiunge da solo il dominio) |
| IPv4 address | l'IP pubblico del punto 2.7 |
| Proxy status | **DNS only** -> la nuvoletta deve diventare **GRIGIA** |
| TTL | Auto |

Clicca **Save**.

### 9.2 Perche' la nuvoletta DEVE essere grigia

> Con la nuvoletta **arancione** (proxy attivo) Cloudflare si mette in mezzo: nasconde il tuo IP
> e fa passare il traffico attraverso i suoi server. Ma Cloudflare, nel piano gratuito, gira
> **solo traffico HTTP/HTTPS sulle porte web**. Le nostre porte 21115-21117, e in particolare
> **tutto l'UDP**, non passano: vengono semplicemente buttate.
>
> Il risultato e' subdolo: il nome si risolve, i comandi di rete sembrano fare qualcosa, ma il
> client MTDesk resta **grigio** per sempre e tu cerchi il problema dalla parte sbagliata per
> mezza giornata.
>
> **Nuvoletta grigia = "DNS only" = Cloudflare fa solo da elenco telefonico.** E' quello che
> serve a noi.

### 9.3 Verifica (dal tuo PC, PowerShell)
Aspetta 1-2 minuti, poi:

```powershell
Resolve-DnsName mtdesk.marketingtools.digital -Type A
```

**DEVI VEDERE**, nella colonna `IPAddress`, **l'IP della tua macchina Oracle** (`130.61.x.x`,
`141.147.x.x`, `143.47.x.x` o simili).

**SEGNALE D'ALLARME:** se invece ti risponde un indirizzo che inizia per **`104.`**, **`172.67.`**,
**`188.114.`** o **`162.159.`**, quelli sono **server di Cloudflare**: la nuvoletta e' ancora
arancione. Torna al punto 9.1, clicca sulla nuvoletta per spegnerla e riprova fra un minuto.

Se il comando risponde `DNS name does not exist`, il record non e' stato salvato oppure hai
scritto il nome sbagliato: ricontrolla che il campo Name sia `mtdesk` e non
`mtdesk.marketingtools.digital.marketingtools.digital`.

---

## 10. COLLAUDO: i 5 controlli

Fai i cinque controlli **in ordine**. Se uno fallisce, fermati e risolvi quello: i successivi
non possono funzionare.

### Controllo 1 - I container sono in piedi (sul server)

```bash
cd /home/ubuntu/mtdesk && docker compose ps
```

**DEVI VEDERE:** `mtdesk-hbbs` e `mtdesk-hbbr`, entrambi `Up`.

### Controllo 2 - Il nome punta alla macchina giusta (dal tuo PC)

```powershell
Resolve-DnsName mtdesk.marketingtools.digital -Type A
```

**DEVI VEDERE:** l'IP di Oracle. Non un 104.x.

### Controllo 3 - Le porte TCP rispondono da internet (dal tuo PC)

```powershell
Test-NetConnection mtdesk.marketingtools.digital -Port 21115
Test-NetConnection mtdesk.marketingtools.digital -Port 21116
Test-NetConnection mtdesk.marketingtools.digital -Port 21117
```

**DEVI VEDERE**, per tutte e tre, la riga:

```
TcpTestSucceeded : True
```

Se una dice `False`, usa la tabella del punto 5.7 per capire **quale** dei due firewall ti sta
bloccando: la differenza fra "resta appeso e poi fallisce" e "fallisce subito" ti dice tutto.

> **Nota importante e onesta:** `Test-NetConnection` sa provare **solo il TCP**. La porta
> **UDP 21116 non e' verificabile con questo comando** (ne' con nessun comando semplice da
> Windows). L'unica prova che l'UDP passa e' il **Controllo 4**: l'indicatore del client diventa
> verde proprio grazie al battito (heartbeat) che viaggia su UDP 21116. Se i tre TCP vanno ma il
> client resta grigio, la regola UDP e' quasi sempre la colpevole.

### Controllo 4 - Il client diventa verde
Apri **MTDesk** sul tuo PC Windows. Va bene uno qualsiasi di questi due file:

- `D:\2026\VISUAL STUDIO\MTDESK\MTDesk-1.4.9-x86_64.exe` (la versione portatile, quella che
  darai ai clienti);
- oppure `D:\2026\VISUAL STUDIO\MTDESK\client\flutter\build\windows\x64\runner\Release\rustdesk.exe`
  — **si', si chiama ancora `rustdesk.exe`**: e' il file appena compilato e il nome del file non e'
  stato cambiato, ma la finestra che si apre e' MTDesk e usa il tuo centralino.

**DEVI VEDERE:** in basso a sinistra, un **pallino/indicatore VERDE** con la scritta **"Pronto"**.

Se e' rosso o grigio: aspetta 30 secondi (il primo contatto puo' tardare), poi chiudi e riapri
il programma. Se resta grigio, e' la regola UDP 21116 (vedi nota qui sopra) oppure la nuvoletta
Cloudflare arancione.

**Nota:** l'indirizzo e la chiave sono **compilati dentro l'exe**, non devi impostare niente
nelle opzioni. Se in Impostazioni -> Rete vedi campi vuoti e' normale: significa "sto usando i
valori di fabbrica", che sono i tuoi.

### Controllo 5 - La prova del nove: due reti DIVERSE
Questo e' il solo controllo che dimostra davvero che il centralino funziona su internet.
**Non e' rimandabile.**

Perche': se provi con due PC collegati **allo stesso Wi-Fi di casa**, i due MTDesk si trovano
dentro la rete locale e la connessione riesce **anche con il server mezzo rotto**. Ti convinci
che funzioni e poi il primo cliente vero non si collega.

Come si fa:
1. Sul **telefono**, attiva l'**hotspot 4G/5G** (Impostazioni -> Router Wi-Fi / Hotspot).
   Importante: il telefono deve usare la **rete dati**, non il Wi-Fi di casa.
2. Collega il **portatile** a quell'hotspot, e stacca il Wi-Fi di casa.
3. Sul portatile apri MTDesk. Anche lui deve diventare **verde**.
4. Dal PC di casa (rete di casa), inserisci **l'ID a 9 cifre** del portatile e premi
   **Connetti**, poi la password mostrata dal portatile.

**DEVI VEDERE:** lo schermo del portatile dentro una finestra sul PC di casa, e il mouse che
risponde.

5. **Prova anche il relay** (il pezzo che serve ai clienti dietro reti difficili): rifai la
   connessione scrivendo l'ID **seguito da `/r`**, per esempio `123456789/r`. Il suffisso `/r`
   dice a MTDesk "passa per forza dal server relay", invece di tentare il collegamento diretto.
   In alternativa c'e' l'opzione **"Collegati sempre tramite relay"** nella scheda della
   connessione.

**DEVI VEDERE:** la connessione riesce comunque, e nella barra della sessione l'indicazione
**"Connessione tramite relay e cifrata"**.

Se questa dicitura dice **"non cifrata"**, fermati e dimmelo: significa che la verifica della
chiave non e' andata a buon fine e va indagato prima di dare l'exe ai clienti.

Se il relay non funziona mentre il collegamento diretto si', il sospettato e' la porta
**21117/TCP** (punto 3.2 riga 4, e punto 5.3 quarta riga).

**Se tutti e 5 i controlli passano, il centralino e' in produzione.** Segnati la data.

---

## 11. Sorveglianza gratuita con UptimeRobot

### 11.1 Perche' serve davvero
Due motivi concreti:

1. **Oracle puo' spegnere le macchine gratuite inattive.** Nelle condizioni del piano Always Free
   c'e' scritto che le istanze considerate "idle" (poco carico per giorni) possono essere
   **recuperate**. Una mattina il centralino non c'e' piu' e tu lo scopri mentre un cliente
   ti aspetta al telefono.
2. **Un riavvio silenzioso.** Se le regole del firewall non fossero state salvate bene (punto 5.5),
   il guasto compare solo dopo il primo riavvio, cioe' settimane dopo, quando hai dimenticato
   tutto questo.

Un controllo esterno ogni 5 minuti ti avverte per email **prima** del cliente.

### 11.2 Come si imposta
1. Vai su **https://uptimerobot.com** e registrati con il piano **Free** (50 controlli, verifica
   ogni 5 minuti, nessuna carta richiesta).
2. **Add New Monitor**:
   - **Monitor Type**: `Port` (in alcune versioni si chiama `TCP Port`)
   - **Friendly Name**: `MTDesk centralino`
   - **Host / IP**: `mtdesk.marketingtools.digital`
   - **Port**: `21116`
   - **Monitoring Interval**: 5 minuti
   - **Alert Contacts**: spunta la tua email
3. Salva.

Perche' la 21116: e' la porta del rendezvous, quella indispensabile. Se risponde lei, il
centralino sta lavorando. (UptimeRobot prova il **TCP**; la parte UDP non e' controllabile da
fuori, quindi questo controllo ti dice "il server e' vivo", non "tutto perfetto". E' comunque
il 90% di quello che serve sapere.)

**DEVI VEDERE:** dopo qualche minuto, il monitor **verde** con scritto `Up`.

### 11.3 In piu': una prova di connessione ogni tanto
Il controllo di UptimeRobot e' leggerissimo e **non garantisce** che Oracle consideri la macchina
"attiva". La cosa piu' semplice e sicura e' **usare il sistema**: fai una connessione di prova
una volta ogni tanto (una al mese e' piu' che sufficiente) e segnatelo in calendario.

Se in futuro Oracle ti spegnesse la macchina nonostante tutto, dimmelo: si aggiunge un piccolo
compito automatico che tiene occupata la CPU qualche minuto al giorno. Non lo metto adesso
perche' aggiunge un pezzo in piu' da capire, per un problema che potrebbe non presentarsi.

---

## 12. Se non funziona: i 5 guasti piu' probabili, in ordine

Prima di tutto, il **percorso diagnostico in 3 mosse**, che vale per qualunque sintomo:

1. **Il server e' vivo?** -> `docker compose ps` (dal server)
2. **Il nome punta all'IP giusto?** -> `Resolve-DnsName` (dal tuo PC)
3. **Le porte rispondono?** -> `Test-NetConnection` (dal tuo PC)

La prima che risponde male e' il tuo problema. Poi:

### Guasto 1 - Nuvoletta Cloudflare arancione (il piu' frequente in assoluto)
- **Sintomo:** tutto sembra a posto, il client resta **grigio**, `Test-NetConnection` fallisce.
- **Controllo:** `Resolve-DnsName mtdesk.marketingtools.digital -Type A`.
  Se risponde `104.x`, `172.67.x`, `188.114.x` o `162.159.x` -> e' Cloudflare, non te.
- **Cura:** Cloudflare -> DNS -> clicca la nuvoletta arancione accanto al record `mtdesk`
  finche' diventa **grigia** ("DNS only"). Attendi 2 minuti.

### Guasto 2 - Manca la regola UDP 21116
- **Sintomo:** il client lampeggia verde per un istante e poi torna **grigio**; oppure risulta
  collegato ma il cliente "non viene trovato" quando cerchi il suo ID.
- **Controllo:** pannello Oracle -> Security List -> **conta le regole: devono essere 4**, e una
  deve avere IP Protocol **UDP**. Poi, sul server: `sudo iptables -L INPUT -n | grep udp`
  deve mostrare `udp dpt:21116`.
- **Cura:** aggiungi la regola mancante (punto 3.2 riga 3 e/o punto 5.3 terza riga).
- Ricorda: `Test-NetConnection` **non** puo' scoprire questo guasto, perche' prova solo il TCP.
  E' esattamente per questo che e' il guasto che fa perdere piu' tempo.

### Guasto 3 - Firewall interno di Ubuntu non configurato (o sparito dopo un riavvio)
- **Sintomo:** `Test-NetConnection` fallisce **subito**, o l'errore dice `No route to host`.
  Tipico: funzionava e dopo un riavvio del server non funziona piu'.
- **Controllo:** `sudo iptables -L INPUT -n --line-numbers | head -12` -> le 4 righe ACCEPT
  devono stare **sopra** la riga REJECT.
- **Cura:** ridai i comandi del punto 5.3, poi **`sudo netfilter-persistent save`**
  (se salti quest'ultimo, al prossimo riavvio ci risiamo).

### Guasto 4 - La chiave del server non e' quella compilata nell'exe
- **Sintomo:** il client e' **verde** (il server risponde!) ma la connessione a un ID non va in
  porto, oppure compare un errore che parla di **chiave** / `key mismatch` / la sessione
  risulta **non cifrata**.
- **Controllo:** sul server `cd /home/ubuntu/mtdesk && ./mostra-chiave.sh`. Deve uscire
  **esattamente** `jc63wRwdyqs465Ndu5fP61fvB4x4CHdIAIIpw6YrQcw=`.
- **Cura:** la procedura di riparazione e' al punto **8.4**. In sintesi: spegni, cancella le due
  chiavi generate a sproposito, ricopia `data/` dal tuo PC, riaccendi.
- **Da non fare:** cambiare la chiave dentro `config.rs` per farla combaciare con quella nuova.
  Funzionerebbe solo dopo aver ricompilato **e ridistribuito** l'exe a tutti i clienti.

### Guasto 5 - I container non sono in esecuzione
- **Sintomo:** `Connection refused` immediato su tutte le porte, oppure `docker compose ps`
  mostra `Exited` / `Restarting`.
- **Controllo:** `cd /home/ubuntu/mtdesk && docker compose logs --tail 50`.
  Cerca le righe che iniziano con `Error` o `panic`.
- **Cure, in ordine:**
  - `docker compose up -d` (magari non sono mai stati avviati)
  - manca `.env`: `cat .env` -> se non esiste, `docker compose` ti avverte con
    `The "MTDESK_HOST" variable is not set. Defaulting to a blank string.` e il comando
    del container diventa `hbbs -r :21117`: l'indirizzo del relay che hbbs comunica ai client
    e' vuoto, quindi le connessioni che avrebbero bisogno del relay non riescono mai
    ad andare a buon fine (il client prova, non trova il relay, e la sessione non parte).
    Ricopialo (punto 7.4) e poi `docker compose up -d --force-recreate`
  - `docker ps` da `permission denied`: non ti sei riconnesso dopo il punto 6.2
  - dopo un riavvio del server i container tornano su da soli (`restart: unless-stopped`):
    se non lo fanno, `docker compose up -d`

### Se non e' nessuno dei cinque
Raccogli queste quattro cose e mandamele: con queste si capisce sempre dov'e' il problema.

```bash
# sul server
docker compose ps
docker compose logs --tail 60
sudo iptables -L INPUT -n --line-numbers
sudo ss -tulpn | grep 2111
```

```powershell
# sul tuo PC
Resolve-DnsName mtdesk.marketingtools.digital -Type A
Test-NetConnection mtdesk.marketingtools.digital -Port 21116
```

---

## 13. Piano di ritirata (come tornare indietro)

Regola generale: **prima di cambiare qualcosa che funziona, salva il modo di rimetterla come era.**

### 13.1 La cosa che non devi perdere mai
Le chiavi in `deploy/data/`. Ne esistono due copie: quella sul server e **l'originale sul tuo PC**
in `D:\2026\VISUAL STUDIO\MTDESK\deploy\data\`. Non cancellare quella sul PC per nessun motivo,
ed escludila dai "riordini". E' l'unica cosa in tutto questo progetto che non si puo' ricreare.

Copia di sicurezza in piu', dal server:

```bash
cd /home/ubuntu/mtdesk
tar czf ~/mtdesk-data-$(date +%F).tar.gz data
ls -lh ~/mtdesk-data-*.tar.gz
```

### 13.2 Se una modifica al `docker-compose.yml` peggiora le cose
Prima di modificarlo, sempre:

```bash
cd /home/ubuntu/mtdesk
cp docker-compose.yml docker-compose.yml.funzionante
```

Per tornare indietro:

```bash
cd /home/ubuntu/mtdesk
cp docker-compose.yml.funzionante docker-compose.yml
docker compose up -d --force-recreate
docker compose ps
```

### 13.3 Se una modifica al firewall peggiora le cose
Hai la copia fatta al punto 5.2. Per rimettere le regole di partenza:

```bash
sudo iptables-restore < /etc/iptables/rules.v4.ORIGINALE
sudo iptables -L INPUT -n --line-numbers
```

Nota: cosi' torni alla situazione **iniziale**, quindi le porte di MTDesk si richiudono e
il centralino smette di essere raggiungibile: e' un ritorno al punto di partenza, non una
riparazione. Dopo, ridai i comandi del punto 5.3.

Non ti puoi chiudere fuori con `iptables-restore`: la regola della porta 22 e' dentro quel file
di backup. **Puoi** chiuderti fuori con `ufw enable`: vedi il punto 5.6.

### 13.4 Se un aggiornamento dell'immagine rompe tutto
Il nostro `docker-compose.yml` usa `rustdesk/rustdesk-server:latest`, cioe' "l'ultima versione".
Comodo, ma significa che un `docker compose pull` puo' portarti una versione nuova che si
comporta diversamente.

**Prima** di aggiornare, prenditi il "numero di serie" della versione che funziona:

```bash
docker image ls --digests | grep rustdesk-server
```

Copia la stringa che inizia con `sha256:` e mettila da parte (incollala anche in un tuo appunto
sul PC). Se dopo l'aggiornamento qualcosa non va, torni indietro sostituendo nel
`docker-compose.yml` le **due** righe `image:` con:

```yaml
    image: rustdesk/rustdesk-server@sha256:LA-STRINGA-CHE-HAI-SALVATO
```

e poi `docker compose up -d --force-recreate`.

### 13.5 Ritirata totale: rifare la macchina da zero
Se ti sei incartato al punto di non capire piu' cosa hai toccato, **non e' un dramma**: la
macchina e' usa-e-getta. Nel pannello Oracle: istanza -> **More actions** -> **Terminate**
(spunta anche "delete the attached boot volume"), poi rifai dal punto 2.

Ci vogliono circa 20 minuti e non perdi niente, perche':
- l'IP e' **riservato** (punto 2.7), quindi lo riassegni alla macchina nuova e **il DNS su
  Cloudflare non va toccato**;
- le chiavi sono sul tuo PC;
- tutta la configurazione e' nella cartella `deploy/`, che e' sul tuo PC.

Sapere che puoi rifare tutto in 20 minuti e' la cosa che ti fa lavorare tranquillo.

### 13.6 Se perdi l'accesso SSH (chiave smarrita)
Non c'e' recupero: Oracle non conserva la tua chiave privata. Unica strada, il punto 13.5.
E' esattamente per questo che al punto 2.5 ti ho fatto fare **due** copie della chiave.

---

## Appendice - I comandi che userai sempre

### Sul server (dopo essere entrato in SSH)

```bash
cd /home/ubuntu/mtdesk

docker compose ps                  # sono vivi?
docker compose logs -f hbbs        # guarda i client che si registrano (Ctrl+C per uscire)
docker compose logs --tail 50      # ultime 50 righe di entrambi
docker compose restart             # riavvia
docker compose down                # spegni (le chiavi in data/ restano)
docker compose up -d               # riaccendi
./mostra-chiave.sh                 # ristampa la chiave pubblica
sudo ss -tulpn | grep 2111         # chi sta ascoltando sulle porte
df -h /                            # spazio su disco rimasto
free -m                            # memoria
```

### Dal tuo PC (PowerShell)

```powershell
# entrare nel server
ssh -i "D:\2026\VISUAL STUDIO\MTDESK\chiavi-vps\mtdesk-oracle.key" ubuntu@IL-TUO-IP

# controlli di rete
Resolve-DnsName mtdesk.marketingtools.digital -Type A
Test-NetConnection mtdesk.marketingtools.digital -Port 21116
```

### Glossario minimo

| Parola | Cosa vuol dire, in pratica |
|---|---|
| **istanza** | la macchina virtuale, il "computer" che affitti (qui: gratis) |
| **shape** | la taglia di quella macchina (quanta CPU e RAM) |
| **hbbs** | il pezzo che, dato un ID a 9 cifre, trova il computer giusto |
| **hbbr** | il pezzo che fa passare video e comandi quando i due PC non riescono a parlarsi diretto |
| **relay** | appunto quel "passaggio dal server"; costa banda, ma salva le reti difficili |
| **rendezvous** | l'appuntamento: il momento in cui i due PC si scambiano gli indirizzi |
| **container** | un programma impacchettato con tutto cio' che gli serve; Docker li accende e spegne |
| **Security List** | il firewall del pannello Oracle (il primo dei due muri) |
| **iptables** | il firewall dentro Ubuntu (il secondo muro) |
| **stateful** | una regola firewall che si ricorda le conversazioni gia' aperte; e' quello che vogliamo |
| **SSH** | il modo per scrivere comandi su un computer lontano |
| **scp** | copiare file su un computer lontano, usando SSH |

---

## Riferimenti nel progetto

| File | Cosa contiene |
|---|---|
| `D:\2026\VISUAL STUDIO\MTDESK\deploy\docker-compose.yml` | la ricetta dei due container e le porte |
| `D:\2026\VISUAL STUDIO\MTDESK\deploy\.env` | l'indirizzo pubblico del centralino |
| `D:\2026\VISUAL STUDIO\MTDESK\deploy\data\` | **le chiavi**: la cosa da non perdere |
| `D:\2026\VISUAL STUDIO\MTDESK\deploy\README-SERVER.md` | note tecniche sul server |
| `D:\2026\VISUAL STUDIO\MTDESK\deploy\CLIENT-CONNESSIONE.md` | come si configura un client a mano |
| `D:\2026\VISUAL STUDIO\MTDESK\deploy\CHIAVE-SERVER.txt` | promemoria della chiave pubblica |
| `D:\2026\VISUAL STUDIO\MTDESK\landing\index.html` | la pagina di download per i clienti |
| `client\libs\hbb_common\src\config.rs` righe 117-118 | indirizzo e chiave **compilati dentro l'exe** |

**Due note di allineamento**, cosi' non ti confondi leggendo anche gli altri file:

1. `deploy/README-SERVER.md` dice le stesse cose di questa guida (le **4** porte, `iptables`
   e non `ufw` su Oracle), ma le scrive per un lettore piu' tecnico e con un comando
   `iptables` leggermente diverso: `-I INPUT 6` invece di `-I INPUT`. Il risultato e' lo
   stesso, cioe' mettere le regole **sopra** la riga REJECT; la versione di questa guida
   (`-I INPUT`, che significa "in cima a tutto") funziona anche se un domani l'elenco delle
   regole di Oracle cambia numerazione. Se hai gia' seguito questa guida, non rifare niente.
   Quello che trovi in fondo a quel README come esempio `ufw` vale **solo per altri VPS**
   (Hetzner, Contabo...), non per Oracle: qui `ufw` non si tocca (punto 5.6).
2. Lo stesso README parla di installare in `/opt/mtdesk`. Questa guida usa
   `/home/ubuntu/mtdesk` perche' e' la cartella dove `scp` puo' scrivere **senza** dover
   inventare permessi da amministratore. Funziona identico: se un giorno leggi `/opt/mtdesk`
   in quel file, per te la cartella e' `/home/ubuntu/mtdesk`.
