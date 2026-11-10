# `server/` — il centralino MTDesk

Scritto per chi deve rimettere mano al centralino: non è documentazione per il cliente.

Questa cartella contiene i **sorgenti dei due programmi** che girano sul VPS. Non si avviano
a mano: li costruisce e li gestisce [`../deploy/docker-compose.yml`](../deploy/docker-compose.yml).

| Programma | Cosa fa | Porte |
|---|---|---|
| **hbbs** | *Rendezvous*: trova il PC partendo dall'ID a 9 cifre e fa da intermediario per il collegamento diretto | 21115 TCP, 21116 TCP **e UDP** |
| **hbbr** | *Relay*: fa da ponte per il traffico quando il collegamento diretto non passa | 21117 TCP |
| **mtdesk-utils** | Strumento a riga di comando: genera e valida le chiavi, diagnostica la connessione | — |

Schermo, tastiera e file sono cifrati da un capo all'altro: il relay li inoltra senza poterli
leggere.

---

## Origine e licenza

Opera derivata di `rustdesk-server`, rilasciata sotto **AGPL-3.0** (testo integrale in
[`LICENSE`](LICENSE)). La licenza copre il codice, non il marchio MTDesk.

**Non comunica con il progetto di origine.** La funzione `check_software_update()` in
[`src/common.rs`](src/common.rs) inviava ogni 24 ore una richiesta al loro server di versione
con sistema, architettura e un'impronta della macchina: è stata svuotata. Le stringhe mostrate
da `--help` sono ribrandizzate.

---

## Come si costruisce

Normalmente non serve: `docker compose up -d --build` in `../deploy/` fa tutto. Il
[`Dockerfile`](Dockerfile) è a due fasi — compila con Rust e poi produce un'immagine minima
senza compilatore, che gira **senza privilegi di root**.

### Il punto che fa inciampare: serve un database per COMPILARE

`src/database.rs` usa le macro `sqlx::query!` e `sqlx::query_as!`, che verificano le query
contro un database reale **al momento della compilazione**. Senza un database raggiungibile da
`DATABASE_URL`, `cargo build` non parte.

Il Dockerfile se ne occupa da solo: crea un database vuoto da [`schema.sql`](schema.sql).
Per compilare **in locale**, invece, va preparato una volta:

```bash
cd server
sqlite3 db_v2.sqlite3 < schema.sql      # oppure: python -c "import sqlite3,pathlib; c=sqlite3.connect('db_v2.sqlite3'); c.executescript(pathlib.Path('schema.sql').read_text())"
cp .env.example .env
cargo build --release --locked
```

> `db_v2.sqlite3` e `.env` sono esclusi da git — il database conserva ID e indirizzi IP dei
> clienti e non va pubblicato. È il motivo per cui esiste `schema.sql`: contiene la struttura
> e zero dati.

### Versione di Rust

Il centralino richiede **Cargo 1.78 o superiore**, perché `Cargo.lock` è in formato versione 4.
Attenzione: il client è fermo a **Rust 1.75.0** per vincoli di ABI. Sono due catene di build
indipendenti — con la toolchain del client, qui si ottiene
`lock file version 4 was found, but this version of Cargo does not understand this lock file`.
In locale: `cargo +stable build`.

---

## Dipendenze ancora da sistemare

Due crate arrivano da repository GitHub di terzi invece che da crates.io:

```
async-speed-limit = { git = "https://github.com/open-trade/async-speed-limit" }
reqwest           = { git = "https://github.com/rustdesk-org/reqwest", ... }
```

`Cargo.lock` ne fissa il commit esatto, quindi la build è ripetibile **finché quei repository
restano online**. Per l'indipendenza completa vanno vendorizzati dentro questo repository.

---

## Dove stanno chiavi e dati

Tutto in `/data` dentro il container, che `docker-compose.yml` monta da `deploy/data/` sul VPS:

| File | Cos'è |
|---|---|
| `id_ed25519` | **Chiave privata del centralino.** Se si perde, tutti gli eseguibili MTDesk già distribuiti non si collegano più: la chiave pubblica è compilata dentro di loro. Va messa al sicuro con un backup fuori dal VPS. |
| `id_ed25519.pub` | Chiave pubblica, quella da mettere nel client |
| `db_v2.sqlite3` | ID, chiave pubblica e ultimo indirizzo IP noto di ogni PC che si è collegato |
| `blacklist.txt` | IP a cui il relay applica la banda ridotta |

### Migrazione dall'immagine precedente

L'immagine di terzi girava **come root** e usava `/root` come cartella dati; la nostra gira
come utente `mtdesk` e usa `/data`. Sul VPS, prima del primo `up` con la nuova immagine, va
riassegnata la proprietà dei file esistenti, altrimenti il centralino non riesce a scrivere:

```bash
cd ~/deploy
docker compose down
sudo chown -R 999:999 data/     # verifica l'UID reale con: docker run --rm mtdesk-server:1.1.17 id -u
docker compose up -d --build
```

Dopo l'avvio, controlla che la chiave sia la stessa di prima — se cambia, i client già
distribuiti smettono di collegarsi:

```bash
cat data/id_ed25519.pub
```

---

Guida completa all'installazione su VPS: [`../deploy/README-SERVER.md`](../deploy/README-SERVER.md)
e [`../GUIDA-MESSA-IN-OPERA.md`](../GUIDA-MESSA-IN-OPERA.md).
