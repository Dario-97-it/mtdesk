#!/bin/sh
# =====================================================================
#  MTDesk - avvio dei programmi del centralino dentro il contenitore
# ---------------------------------------------------------------------
#  PERCHE' ESISTE
#
#  I programmi del centralino (hbbs, hbbr) girano come utente "mtdesk",
#  senza privilegi: se uno dei due venisse compromesso, l'attaccante si
#  troverebbe a possedere soltanto la cartella /data.
#
#  Ma /data e' la cartella dell'ospite montata dal docker-compose
#  (deploy/data), e in due casi appartiene a root:
#    - installazione NUOVA: Docker la crea da solo, a nome di root;
#    - MIGRAZIONE: la vecchia immagine girava come root e ha lasciato
#      chiavi e database a nome di root.
#  In entrambi i casi l'utente mtdesk non puo' scriverci, e hbbs si ferma
#  con "unable to open database file" e riparte all'infinito.
#  (Verificato il 10/11/2026 con una prova di avvio da zero.)
#
#  COSA FA
#  Parte come root, assegna /data all'utente mtdesk, poi cede i privilegi
#  ed esegue il programma richiesto. Da quel momento nel contenitore non
#  gira piu' niente come root.
# =====================================================================
set -e

if [ "$(id -u)" = "0" ]; then
    chown -R mtdesk:mtdesk /data
    # La chiave privata del centralino deve essere leggibile solo dal suo
    # proprietario. Se esiste, lo si impone a ogni avvio.
    if [ -f /data/id_ed25519 ]; then
        chmod 600 /data/id_ed25519
    fi
    exec setpriv --reuid=mtdesk --regid=mtdesk --init-groups "$@"
fi

# Se il contenitore e' stato avviato gia' senza privilegi (--user), si
# esegue direttamente: i permessi di /data in quel caso sono a carico di
# chi lo ha avviato cosi'.
exec "$@"
