-- =====================================================================
--  MTDesk - schema del database del centralino
-- ---------------------------------------------------------------------
--  A COSA SERVE QUESTO FILE
--
--  Il centralino usa sqlx con le macro `sqlx::query!` e `sqlx::query_as!`
--  (src/database.rs). Quelle macro verificano le query CONTRO UN DATABASE
--  VERO AL MOMENTO DELLA COMPILAZIONE: senza un database raggiungibile da
--  DATABASE_URL, `cargo build` non parte nemmeno.
--
--  Prima questo funzionava solo per caso: sul PC di sviluppo esistevano
--  server/.env (con DATABASE_URL) e server/db_v2.sqlite3. Ma quel file .sqlite3
--  e' escluso da .gitignore - e giustamente, perche' contiene gli ID e gli
--  indirizzi IP dei clienti. Risultato: da un clone pulito del repository il
--  centralino NON si compilava, e nessun documento lo diceva.
--
--  Questo file risolve il problema: contiene solo la STRUTTURA, zero dati.
--  Il Dockerfile ne crea un database vuoto prima di compilare.
--
--  COME RICREARE IL DATABASE DI COMPILAZIONE A MANO (se serve in locale):
--      cd server
--      rm -f db_v2.sqlite3
--      sqlite3 db_v2.sqlite3 < schema.sql
--      echo 'DATABASE_URL=sqlite://db_v2.sqlite3' > .env
--
--  IMPORTANTE: questo schema deve restare identico a quello creato a runtime
--  da `create_tables()` in src/database.rs. Se li' viene aggiunta una colonna,
--  va aggiunta anche qui, altrimenti la compilazione fallira' con un errore
--  di sqlx su una colonna mancante.
-- =====================================================================

create table if not exists peer (
    guid blob primary key not null,
    id varchar(100) not null,
    uuid blob not null,
    pk blob not null,
    created_at datetime not null default(current_timestamp),
    user blob,
    status tinyint,
    note varchar(300),
    info text not null
) without rowid;

create unique index if not exists index_peer_id on peer (id);
create index if not exists index_peer_user on peer (user);
create index if not exists index_peer_created_at on peer (created_at);
create index if not exists index_peer_status on peer (status);
