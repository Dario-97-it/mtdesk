# `server/` — il centralino MTDesk

Scritto per chi deve rimettere mano al centralino: non è documentazione per il cliente.

Questa cartella contiene i **sorgenti dei due programmi** che girano sul VPS. Non si avviano
a mano: li costruisce e li gestisce [`../deploy/docker-compose.yml`](../deploy/docker-compose.yml).

Per le prove in rete locale, senza Docker e senza VPS, c'è invece
[`../deploy/avvia-centralino-locale.ps1`](../deploy/avvia-centralino-locale.ps1): avvia
direttamente i due programmi compilati per Windows.

| Programma | Cosa fa | Porte |
|---|---|---|
| **hbbs** | *Rendezvous*: trova il PC partendo dall'ID numerico (di solito 9 cifre) e fa da intermediario per il collegamento diretto | 21115 TCP, 21116 TCP **e UDP** |
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

A mano normalmente non serve: l'immagine Docker la costruisce `docker compose build`, dato
nella cartella `../deploy/`. Il [`Dockerfile`](Dockerfile) è a due fasi — compila con Rust e
poi produce un'immagine minima senza compilatore, che gira **senza privilegi di root** (come
utente `mtdesk`). Il file [`.dockerignore`](.dockerignore) tiene fuori dalla costruzione la
cartella `target/` (diversi GB), il file `.env` e i database.

**Dove si costruisce: sul PC, non sul VPS.** Il VPS previsto (1/8 di CPU, 1 GB di RAM) non è
in grado di compilare Rust, tanto meno con `lto = true` e `codegen-units = 1` (sezione
`[profile.release]` di [`Cargo.toml`](Cargo.toml)). L'immagine si costruisce sul PC, si
esporta in un file, si copia sul VPS e lì si carica già pronta; sul VPS il centralino si
avvia con `docker compose up -d`, **senza** `--build`. I comandi, uno per uno, sono in
[`../deploy/README-SERVER.md`](../deploy/README-SERVER.md), paragrafo 2.

> ℹ️ **Costruita e avviata davvero.** Il 10/11/2026 questa immagine è stata costruita sul PC
> Ubuntu di prova con `docker compose build` (circa 10 minuti su 2 core e 7 GB, 141 MB) e
> avviata con `docker compose up -d`: hbbs e hbbr sono partiti. Prima di arrivarci il
> Dockerfile aveva tre difetti, trovati due a tavolino e uno solo provando: non copiava
> `third_party/`, fissava una versione di Rust troppo vecchia, e lasciava la cartella dati a
> root, cosa che faceva ripartire hbbs all'infinito con «unable to open database file». Da
> allora i permessi li sistema `docker-entrypoint.sh` a ogni avvio. Non è ancora stata
> esportata e caricata su un VPS. Anche i tre programmi per Windows sono compilati e usati
> davvero (`cargo +stable build --release`, vedi sotto): con quelli gira il centralino di
> prova in rete locale.

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
cargo +stable build --release --locked      # perché +stable: vedi "Versione di Rust" qui sotto
```

> `db_v2.sqlite3` e `.env` sono esclusi da git — il database conserva ID e indirizzi IP dei
> clienti e non va pubblicato. È il motivo per cui esiste `schema.sql`: contiene la struttura
> e zero dati.

### Versione di Rust

Il centralino richiede **Rust 1.88 o superiore**. "Cargo 1.78", come diceva la prima stesura
di questa pagina, basta soltanto a *leggere* `Cargo.lock` (che è in formato versione 4): le
librerie bloccate in quel file chiedono di più — `time 0.3.54` vuole Rust 1.88, `uuid 1.24.0`
la 1.85, le `icu_*` 2.2.0 la 1.86. La versione con cui è stato compilato e provato davvero è
la **1.99.1**, ed è quella fissata nel Dockerfile (`rust:1.99.1-bookworm`).

Attenzione: il client è fermo a **Rust 1.75.0** per vincoli di ABI. Sono due catene di build
indipendenti — con la toolchain del client, qui si ottiene
`lock file version 4 was found, but this version of Cargo does not understand this lock file`.
In locale: `cargo +stable build` (sul PC del progetto la toolchain predefinita è la 1.75.0
del client, mentre `stable` è la 1.99.1).

---

## Dipendenze: tutte dentro il repository

Sette librerie non arrivavano da crates.io ma da repository GitHub di terzi (sei sotto
`rustdesk-org`). Adesso sono **copiate nella cartella [`third_party/`](third_party/)**, al
commit esatto che `Cargo.lock` già fissava, e i blocchi `[patch]` in fondo a
[`Cargo.toml`](Cargo.toml) le fanno prendere da lì. In `Cargo.toml` e in
`libs/hbb_common/Cargo.toml` le righe `git = "https://github.com/..."` ci sono ancora, ma non
vengono più usate: in `Cargo.lock` non resta nessuna sorgente `git+`, quindi la compilazione
non contatta più quei repository.

| Libreria | Da dove veniva | Commit copiato |
|---|---|---|
| `async-speed-limit` | `github.com/open-trade/async-speed-limit` | `f89f702ae01d4016429543d2f0dda1086157e420` |
| `confy` | `github.com/rustdesk-org/confy` | `83db9ec19a2f97e9718aef69e4fc5611bb382479` |
| `default_net` | `github.com/rustdesk-org/default_net` | `78f8f70cd85151a3a2c4a3230d80d5272703c02e` |
| `machine-uid` | `github.com/rustdesk-org/machine-uid` | `381ff579c1dc3a6c54db9dfec47c44bcb0246542` |
| `reqwest` | `github.com/rustdesk-org/reqwest` | `9cb758c9fb2f4edc62eb790acfd45a6a3da21ed3` |
| `sysinfo` | `github.com/rustdesk-org/sysinfo` (ramo `rlim_max`) | `90b1705d909a4902dbbbdea37ee64db17841077d` |
| `tokio-socks` | `github.com/rustdesk-org/tokio-socks` | `94e97c6d7c93b0bcbfa54f2dc397c1da0a6e43d3` |

I commit non sono scritti dentro le cartelle: si rileggono dal `Cargo.lock` di prima della
copia, con `git show 6c4ab58^:server/Cargo.lock` (cerca le righe `source = "git+`). Le sette
cartelle sono state confrontate con le copie che cargo aveva scaricato a quei commit: stesso
contenuto, cambiano solo i caratteri di fine riga.

Due cose restano da sapere:

- **Che cosa si scarica ancora quando si costruisce.** Le librerie pubblicate su crates.io
  (565 voci in `Cargo.lock`, ognuna con versione e impronta bloccate), i pacchetti Debian
  installati dal Dockerfile e le due immagini di base (`rust:1.99.1-bookworm` e
  `debian:bookworm-slim`), indicate per nome e non per impronta.
- **Le licenze.** Sei cartelle su sette conservano il proprio file di licenza (MIT e/o
  Apache-2.0). `default_net` no: nella sua cartella non c'è né un file di licenza né il campo
  `license` del suo `Cargo.toml`. **[DA CHIARIRE dal proprietario]**, ora che quel codice sta
  in un repository pubblico nostro.

Per aggiornarne una serve una ragione precisa (per esempio una correzione di sicurezza): si
rifà la copia della singola cartella al nuovo commit e, se cambia il numero di versione, si
aggiorna `Cargo.lock`.

---

## Dove stanno chiavi e dati

Tutto in `/data` dentro il container, che `docker-compose.yml` monta dalla cartella `data/`
che ha accanto: `deploy/data/` nel progetto, `/home/ubuntu/mtdesk/data/` sul VPS.

| File | Cos'è |
|---|---|
| `id_ed25519` | **Chiave privata del centralino.** Se si perde, tutti gli eseguibili MTDesk già distribuiti non si collegano più: la chiave pubblica è compilata dentro di loro. Va messa al sicuro con un backup fuori dal VPS. |
| `id_ed25519.pub` | Chiave pubblica, quella da mettere nel client |
| `db_v2.sqlite3` | ID, identificativo della macchina, chiave pubblica e ultimo indirizzo IP noto di ogni PC che si è registrato. Senza scadenza: il codice non cancella mai niente |
| `blocklist.txt` | Facoltativo. IP che il relay **rifiuta**, uno per riga |
| `blacklist.txt` | Facoltativo. IP a cui il relay applica la banda ridotta, uno per riga |

I due file di lista li legge hbbr, e solo all'avvio ([`src/relay_server.rs`](src/relay_server.rs)):
dopo una modifica va riavviato. Come si usano, come si fa il backup della chiave e come si
cancellano i dati di un PC è scritto in
[`../deploy/README-SERVER.md`](../deploy/README-SERVER.md).

### Permessi: la cartella dati deve appartenere all'utente del container

L'immagine di terzi usata in passato girava **come root** e usava `/root` come cartella dati;
la nostra gira come utente `mtdesk` e usa `/data`. Quindi i file in `data/` devono
appartenere a quell'utente, altrimenti il centralino non riesce a leggere la chiave né a
scrivere il database. Vale in due casi:

- **prima installazione:** i file copiati dal PC arrivano sul VPS come proprietà di `ubuntu`;
- **migrazione da un centralino che usava la vecchia immagine:** i file esistenti sono di
  root. (A novembre 2026 un centralino del genere non esiste, perché il VPS non è mai stato
  messo in opera: la nota resta per chi dovesse trovarsi in quella situazione.)

Sul VPS, con l'immagine già caricata e **prima** di avviare:

```bash
cd /home/ubuntu/mtdesk
docker compose down
docker compose up -d
# I permessi non si danno a mano: a ogni avvio il contenitore assegna 'data' all'utente
# mtdesk e impone 600 alla chiave privata (docker-entrypoint.sh), poi cede i privilegi.
```

Il numero dell'utente va letto dall'immagine, come fanno la terza e la quarta riga. La
stesura precedente di questa pagina scriveva direttamente `999:999`: è il valore che ci si
aspetta, ma finché l'immagine non viene costruita davvero non è un dato verificato.

**Perché non è un dettaglio.** Se hbbr non riesce a leggere la chiave non si ferma e non
segnala errori: parte **senza controllare la chiave** di chi si collega, cioè con il relay
aperto (funzione `get_server_sk` in [`src/relay_server.rs`](src/relay_server.rs)). Dopo
l'avvio controlla quindi che la riga `Key:` compaia nei log di **tutti e due** i programmi:

```bash
docker compose logs hbbs | grep "Key:"
docker compose logs hbbr | grep "Key:"
```

E controlla che la chiave sia la stessa di prima — se cambia, i client già distribuiti
smettono di collegarsi:

```bash
cat data/id_ed25519.pub
```

---

Guida completa all'installazione su VPS: [`../deploy/README-SERVER.md`](../deploy/README-SERVER.md)
e [`../GUIDA-MESSA-IN-OPERA.md`](../GUIDA-MESSA-IN-OPERA.md).
