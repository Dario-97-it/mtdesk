# Cartella `docs/` — il "cartello degli aggiornamenti"

Questa cartella viene pubblicata da **GitHub Pages**. L'unico file che conta è
`version.json`: MTDesk lo legge all'avvio e, se il numero di versione scritto lì
è più recente di quello installato, mostra al cliente un cartellino con il
pulsante di download. Il programma **non scarica e non installa niente da solo**.

Indirizzo pubblico del file:
<https://dario-97-it.github.io/mtdesk/version.json>

---

## Come pubblico una nuova versione

**L'ordine conta: prima la Release con i file dentro, e SOLO DOPO il numero
in `version.json`.** Se fai il contrario, per qualche minuto i clienti vedono
l'avviso di aggiornamento e il pulsante li porta su un download che non
esiste ancora.

1. Crea la Release su GitHub allegando i tre file con i **nomi esatti**
   `MTDesk-windows-x86_64.exe`, `MTDesk-qs.exe`, `mtdesk-ubuntu-amd64.deb`.
   I due file Windows li carichi tu a mano (il pacchetto Ubuntu lo allega da solo
   GitHub Actions). **Prima di caricarli**, calcola la loro impronta SHA-256 e
   incollala nelle note della release: il README di root dice ai clienti di
   trovarla li', e serve a chi vuole controllare di aver scaricato il file giusto.
   In PowerShell, nella cartella dove stanno i due file:

   ```powershell
   Get-FileHash .\MTDesk-windows-x86_64.exe, .\MTDesk-qs.exe -Algorithm SHA256 |
       Format-List Path, Hash
   ```

2. Apri `docs/version.json`, cambia **solo** il numero dentro `"version"`
   (esempio: da `1.4.9` a `1.4.10`), salva e fai push. Fine: i link non vanno
   mai toccati.

Dopo il push GitHub Pages si aggiorna da sé in un paio di minuti, e i clienti
vedranno l'avviso al successivo avvio di MTDesk.

> **Nel campo `version` scrivi solo numeri separati da punti** (`1.4.10`), mai
> etichette come `1.4.10-beta` oppure `v1.4.10 RC2`. MTDesk legge soltanto la
> parte numerica e butta via il resto: scrivere `1.4.9-beta` per lui è
> identico a scrivere `1.4.9`, quindi l'avviso non comparirebbe.

---

## Perché i link non si toccano mai

Puntano tutti a `/releases/latest/download/<nome del file>`: GitHub li gira
automaticamente all'ultima Release pubblicata. È per questo motivo che i nomi
dei file **non contengono il numero di versione**: se lo contenessero, ogni
rilascio romperebbe i link della landing e di questo file.

## Cosa significa ogni campo di `version.json`

| Campo                | A cosa serve |
|----------------------|--------------|
| `version`            | Il numero dell'ultima versione pubblicata. **È l'unico da aggiornare.** |
| `notes_url`          | Pagina aperta dal link "Novità programma" sotto il pulsante. |
| `download.windows`   | Installer/portable per Windows. |
| `download.windows_qs`| Quick Support per Windows (da mandare al cliente, non si installa). |
| `download.ubuntu`    | Pacchetto `.deb` per Ubuntu. |

MTDesk sceglie da solo il link giusto: Windows prende `download.windows`,
Ubuntu prende `download.ubuntu`. Se il campo mancasse, il pulsante apre
comunque la pagina delle Release, quindi un errore di battitura non lascia il
cliente a mani vuote.

---

## Come attivare GitHub Pages (una volta sola)

Nel repository: **Settings → Pages → Build and deployment → Source: Deploy from
a branch**, poi **Branch: `main`** e **cartella `/docs`**. Salva. Dopo qualche
minuto l'indirizzo qui sopra risponde.

Il file `.nojekyll` presente in questa cartella dice a GitHub di pubblicare i
file così come sono, senza passarli al motore per i blog.

## Come provo che funziona

Apri l'indirizzo del file nel browser: devi vedere il testo del JSON. Se vedi
una pagina di errore 404, GitHub Pages non è ancora attivo o la cartella
impostata nelle opzioni non è `/docs`.
