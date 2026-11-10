# MTDesk — Come collegare i client al tuo server

Vale sia per il **client MTDesk** gia' compilato, sia per un **RustDesk "stock"**
(non brandizzato) che si puo' usare come banco di prova per verificare che il server
risponda, prima ancora di distribuire MTDesk ai clienti.

---

## A) TEST SUBITO in LAN (senza build, in 5 minuti)

Serve il server MTDesk acceso su un PC della rete locale. Segnati il suo indirizzo IP
locale (`ipconfig` su Windows, `hostname -I` su Ubuntu): nell'esempio lo chiamiamo
`<IP-LOCALE-DEL-SERVER>`, ed e' un indirizzo del tipo `192.168.1.x`.
Poi, su **due PC della stessa rete**:

1. Scarica RustDesk (portable) da https://github.com/rustdesk/rustdesk/releases
2. Apri RustDesk → **≡ (menu)** → **Impostazioni** → **Rete** (ID/Relay Server):
   - **ID Server:**  `<IP-LOCALE-DEL-SERVER>`
   - **Relay Server:** *(vuoto — lo comunica hbbs)*
   - **Key:** `jc63wRwdyqs465Ndu5fP61fvB4x4CHdIAIIpw6YrQcw=`
3. Salva. In basso a sinistra l'indicatore deve diventare **verde**.
4. Sul PC-A leggi l'**ID a 9 cifre** e la **password**. Sul PC-B inserisci quell'ID,
   premi **Connetti**, digita la password → **controlli il PC-A**. ✅

Se funziona in LAN, il pacchetto server è corretto: su internet cambia solo l'host.

---

## B) USO SU INTERNET (come AnyDesk)

Dopo aver messo il server su un VPS pubblico (vedi `README-SERVER.md`), nei client:

- **ID Server:**  `mtdesk.marketingtools.digital`  *(o l'IP pubblico del VPS)*
- **Key:** `jc63wRwdyqs465Ndu5fP61fvB4x4CHdIAIIpw6YrQcw=`
  *(oppure la chiave che genera il VPS: `cat data/id_ed25519.pub`)*

> Nel **client MTDesk compilato** questi valori saranno **già dentro** (hardcoded):
> il cliente scarica l'exe, lo apre, e vede solo ID + password. Zero configurazione.

---

## C) Flusso "assistenza cliente" (unattended)

Per entrare quando vuoi senza che il cliente confermi ogni volta:

1. Sul PC del cliente, in MTDesk: **Imposta password di accesso permanente**
   (Impostazioni → Sicurezza → Accesso non presidiato).
2. Il cliente ti comunica **ID + quella password** una volta sola.
3. Tu ti colleghi quando serve, anche a schermo bloccato.

Per assistenza "usa e getta": il cliente ti detta ID + password temporanea a video.

---

## D) Deploy "zero-config" ai clienti (avanzato)

RustDesk/MTDesk può incorporare la configurazione nel **nome del file .exe**, così il
client parte già puntato al tuo server senza toccare le impostazioni:

```
mtdesk-host=mtdesk.marketingtools.digital,key=jc63wRwdyqs465Ndu5fP61fvB4x4CHdIAIIpw6YrQcw=.exe
```

(Con il client brandizzato questo non serve: la config è compilata dentro.)
