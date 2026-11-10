# =====================================================================
#  MTDesk - Immagine Docker del centralino (hbbs + hbbr)
#  Marketing Tools - marketingtools.digital
# ---------------------------------------------------------------------
#  PERCHE' QUESTO FILE ESISTE
#
#  Prima il deploy usava l'immagine "rustdesk/rustdesk-server:latest",
#  cioe' un binario costruito e pubblicato da un altro progetto, su un tag
#  mobile. Significava tre cose: non sapevamo cosa stesse girando sul nostro
#  VPS, un loro aggiornamento ci cambiava il centralino sotto i piedi, e se
#  avessero smesso di pubblicarla il deploy si sarebbe rotto.
#
#  Questa immagine la costruiamo noi dai sorgenti in questa cartella.
#
#  COME SI USA
#  Non va lanciata a mano: ci pensa deploy/docker-compose.yml, che la
#  costruisce una volta e la usa per entrambi i container (hbbs e hbbr),
#  scegliendo quale programma avviare con la riga "command:".
#
#  Costruzione manuale, se serve:
#      docker build -t mtdesk-server:1.1.17 .
# =====================================================================

# ---------------------------------------------------------------------
#  FASE 1 - compilazione
# ---------------------------------------------------------------------
#  Versione di Rust fissata di proposito: una build che cambia compilatore
#  da sola non e' ripetibile.
#
#  PERCHE' PROPRIO QUESTA: e' la versione con cui il centralino e' stato
#  compilato e provato davvero (rustc 1.99.1). Il minimo non e' "Cargo 1.78"
#  come diceva la prima stesura di questo file: quello basta a LEGGERE
#  Cargo.lock (formato versione 4), ma le dipendenze bloccate nel lock
#  chiedono di piu' - time 0.3.54 vuole Rust 1.88, uuid 1.24 vuole 1.85,
#  icu_* 2.2 vuole 1.86. Con l'1.83 scritta qui in origine la build si
#  fermava subito. (Il client invece e' fermo a Rust 1.75.0 per vincoli di
#  ABI: sono due catene di build indipendenti.)
FROM rust:1.99.1-bookworm AS compilazione

#  Librerie di sistema necessarie alla compilazione:
#  - pkg-config, clang: usati dai crate che compilano codice C
#  - libsodium-dev: richiesto da sodiumoxide (cifratura)
#  Nessun pacchetto di rete: reqwest su Linux usa rustls, quindi non serve
#  OpenSSL.
#  - sqlite3: serve a creare il database VUOTO di compilazione, vedi sotto
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
        pkg-config \
        clang \
        libsodium-dev \
        sqlite3 \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /sorgenti

#  Prima solo i file che descrivono le dipendenze: cosi' Docker riusa la
#  cache delle dipendenze finche' non cambiano, e una modifica al nostro
#  codice non ricompila tutto da zero.
COPY Cargo.toml Cargo.lock build.rs ./
COPY libs/hbb_common/Cargo.toml libs/hbb_common/Cargo.toml

#  Poi il codice vero.
COPY src src
COPY libs libs
#  Le sette librerie portate dentro al repository (vedi i blocchi [patch] in
#  fondo a Cargo.toml). SENZA questa riga la build si ferma con
#  "patch location ... does not contain packages matching ...": la prima
#  stesura di questo file la dimenticava, perche' third_party e' arrivata in
#  un commit successivo e l'immagine non era mai stata costruita davvero.
COPY third_party third_party
COPY schema.sql schema.sql

#  DATABASE DI COMPILAZIONE
#  src/database.rs usa le macro `sqlx::query!` e `sqlx::query_as!`, che
#  verificano le query contro un database VERO al momento della compilazione.
#  Senza, `cargo build` si ferma. Qui ne creiamo uno VUOTO dallo schema
#  versionato: nessun dato di clienti entra nell'immagine, e la build funziona
#  da un clone pulito del repository (prima funzionava solo sul PC che aveva
#  per caso un db_v2.sqlite3 locale, escluso da git).
RUN sqlite3 /tmp/build.sqlite3 < schema.sql
ENV DATABASE_URL=sqlite:///tmp/build.sqlite3

#  --locked: usa esattamente le versioni in Cargo.lock e si ferma se il
#  lock dovesse risultare incoerente, invece di aggiornarlo di nascosto.
RUN cargo build --release --locked \
 && strip target/release/hbbs target/release/hbbr target/release/mtdesk-utils \
 && rm -f /tmp/build.sqlite3

# ---------------------------------------------------------------------
#  FASE 2 - immagine finale
# ---------------------------------------------------------------------
#  Immagine minima: contiene i due programmi e nulla piu'. Non ci sono
#  compilatore, sorgenti o strumenti di sviluppo.
FROM debian:bookworm-slim AS esecuzione

#  ca-certificates serve alle risoluzioni TLS verso l'esterno; curl lo usa
#  il controllo di salute piu' sotto.
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
        ca-certificates \
        libsodium23 \
 && rm -rf /var/lib/apt/lists/* \
 && useradd --system --create-home --home-dir /data --shell /usr/sbin/nologin mtdesk

COPY --from=compilazione /sorgenti/target/release/hbbs /usr/local/bin/hbbs
COPY --from=compilazione /sorgenti/target/release/hbbr /usr/local/bin/hbbr
COPY --from=compilazione /sorgenti/target/release/mtdesk-utils /usr/local/bin/mtdesk-utils

#  /data e' dove vengono generate e conservate le CHIAVI del centralino
#  (id_ed25519 e id_ed25519.pub) e il database con gli ID dei clienti.
#  Il docker-compose ci monta sopra la cartella deploy/data del VPS.
WORKDIR /data
VOLUME /data

#  Niente root: se un giorno uno dei due programmi venisse compromesso,
#  l'attaccante si troverebbe con i permessi di un utente che possiede
#  soltanto /data.
USER mtdesk

#  Porte, per documentazione (quelle pubblicate le decide il compose):
#    21115 TCP  prova del tipo di NAT
#    21116 TCP  rendezvous
#    21116 UDP  rendezvous / battito (OBBLIGATORIA)
#    21117 TCP  relay
EXPOSE 21115 21116 21116/udp 21117

#  Il programma da avviare lo scegliera' il compose con "command: hbbs ..."
#  oppure "command: hbbr ...". Senza argomenti parte il rendezvous.
ENTRYPOINT []
CMD ["hbbs"]
