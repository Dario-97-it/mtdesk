#!/usr/bin/env bash
# Stampa la CHIAVE PUBBLICA del server (da incollare nel client MTDesk)
# Eseguire DOPO il primo avvio del server (docker compose up -d)
KEY_FILE="./data/id_ed25519.pub"
if [ -f "$KEY_FILE" ]; then
  echo "==================================================="
  echo " CHIAVE PUBBLICA MTDesk (campo 'Key' nel client):"
  echo "==================================================="
  cat "$KEY_FILE"; echo
else
  echo "Chiave non ancora generata. Avvia prima: docker compose up -d"
fi
