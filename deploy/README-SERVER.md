# MTDesk — Server self-host (relay + rendezvous)

Questo è il "cervello" che permette a due MTDesk di trovarsi **su internet** tramite
l'ID a 9 cifre, esattamente come i server di AnyDesk. È gratis e gira su Docker.

> Basato su `rustdesk-server` (open source). Container: **hbbs** (rendezvous/ID) e **hbbr** (relay).

---

## 0) LA COSA PIÙ IMPORTANTE DI TUTTE, letta prima di iniziare

Il server ha una **coppia di chiavi** (`data/id_ed25519` privata e `data/id_ed25519.pub`
pubblica). La chiave pubblica è **già compilata dentro i client MTDesk** che hai distribuito
(vedi `CHIAVE-SERVER.txt`).

Se avvii il server su un VPS nuovo **senza** portarci la cartella `data/`, hbbs al primo
avvio se ne genera una **diversa**, e i client già compilati **non si collegheranno mai**:
resteranno rossi per sempre e non ci sarà nessun messaggio di errore che ti spieghi perché.

**Quindi: copia la cartella `data/` sul VPS PRIMA del primissimo `docker compose up`.**
È il passaggio numero 3 della procedura qui sotto — non saltarlo e non invertire l'ordine.

L'alternativa (se preferisci ripartire da zero) è lasciar generare una chiave nuova al VPS,
rileggerla con `./mostra-chiave.sh` e **ricompilare tutti i client** con quella. Molto più
lavoro, stesso risultato.

---

## 1) Dove installarlo

Il server deve stare su una macchina con **IP pubblico**, raggiungibile da internet.
Tre opzioni:

| Opzione | Costo | Note |
|---|---|---|
| **Oracle Cloud "Always Free"** | **Gratis** | Due tipi di macchina: **AMD E2.1.Micro** (1/8 OCPU, 1 GB di RAM — basta e avanza per il nostro uso) oppure **ARM Ampere A1**, la cui quota Always Free da **giugno 2026 è 2 OCPU / 12 GB** (prima era 4 OCPU / 24 GB: le guide più vecchie dicono ancora così). Consigliato. |
| VPS economico (Hetzner, Contabo, Aruba…) | ~3-5 €/mese | Semplicissimo, IP pubblico incluso, nessuna sorpresa. |
| PC/NAS di casa | Gratis | Serve **port-forwarding** sul router + IP statico o DDNS. |

RAM/CPU richieste: pochissime (gira anche su 1 vCPU / 512MB).

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

---

## 2) Installazione sul server (Ubuntu/Debian)

I comandi vanno dati **nell'ordine in cui sono scritti**.

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
# 3. Copia la cartella 'deploy' sul server, COMPRESA la sottocartella 'data'
#    (è il passaggio del paragrafo 0: dentro ci sono id_ed25519 e id_ed25519.pub).
#    Dal TUO PC, non dal server:
#      scp -r deploy ubuntu@<IP-DEL-VPS>:/tmp/mtdesk
#    Poi sul server:
sudo mkdir -p /opt/mtdesk && sudo cp -r /tmp/mtdesk/. /opt/mtdesk/
sudo chown -R ubuntu:ubuntu /opt/mtdesk
cd /opt/mtdesk

# 4. Verifica di avere davvero le chiavi al posto giusto PRIMA di accendere:
ls -l data/id_ed25519 data/id_ed25519.pub
#    Devono esistere entrambi. La privata deve essere leggibile solo da te:
chmod 600 data/id_ed25519

# 5. Imposta il tuo host pubblico nel file .env
#    ATTENZIONE: se hai copiato la cartella 'deploy' dal tuo PC, il file .env
#    gia' compilato e' arrivato insieme agli altri. Il comando qui sotto crea
#    .env SOLO se non c'e' (l'opzione -n vuol dire "non sovrascrivere"):
#    copiarci sopra il modello rimetterebbe l'host di esempio e il relay
#    smetterebbe di funzionare.
cp -n .env.example .env
cat .env                # deve gia' contenere il TUO host, non 'mtdesk.esempio.it'
nano .env               # solo se c'e' da correggerlo
#   MTDESK_HOST=mtdesk.marketingtools.digital   (o il tuo IP pubblico)

# 6. Avvia
docker compose up -d

# 7. Controlla che la chiave sia quella GIUSTA (deve coincidere con CHIAVE-SERVER.txt)
./mostra-chiave.sh
#   oppure:  cat ./data/id_ed25519.pub
```

Fatto. Il server è attivo e riavvia da solo (`restart: unless-stopped`), anche dopo un
riavvio della macchina.

> Se al punto 7 la chiave **non** coincide con quella in `CHIAVE-SERVER.txt`, significa che
> hbbs se n'è generata una nuova perché `data/` era vuota. Ferma tutto (`docker compose down`),
> metti le chiavi corrette in `data/`, cancella il file `data/db_v2.sqlite3` se presente, e
> riavvia.

---

## 3) Porte da aprire — e i DUE firewall di Oracle

Queste sono le porte usate dal nostro `docker-compose.yml`:

| Porta | Protocollo | Servizio |
|---|---|---|
| 21115 | TCP | hbbs — NAT type test |
| 21116 | TCP | hbbs — rendezvous (registrazione e ricerca dell'ID) |
| 21116 | **UDP** | hbbs — heartbeat / hole-punching · **obbligatoria** |
| 21117 | TCP | hbbr — relay (quando la connessione diretta non passa) |

Le vecchie porte **21118 e 21119** (websocket del web client) **non servono più**: le abbiamo
rimosse dal `docker-compose.yml` perché il web client non lo usiamo. Meno porte aperte,
meno superficie di attacco. Se le trovi citate in guide trovate online, ignorale.

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

1. `docker compose ps` → `mtdesk-hbbs` e `mtdesk-hbbr` sono **Up**.
2. `./mostra-chiave.sh` → la chiave è quella di `CHIAVE-SERVER.txt`.
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
docker compose pull && docker compose up -d   # aggiorna all'ultima versione
docker compose logs --tail 50 hbbs            # ultime 50 righe di log
```

## Backup

Salva la cartella **`./data`**: contiene le chiavi (`id_ed25519*`) e il database.
Perderle significa che **tutti i client già distribuiti vanno ricompilati** con la chiave
nuova. Tienine una copia offline, fuori dal VPS, e **non** metterla mai in un repository
pubblico (nel nostro `.gitignore` `deploy/data/` è già escluso).
