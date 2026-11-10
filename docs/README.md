# Cartella `docs/` — il "cartello degli aggiornamenti" e le pagine di aiuto

Questa cartella viene pubblicata da **GitHub Pages**: quello che c'è qui dentro
diventa un piccolo sito pubblico, e MTDesk ha l'indirizzo di quel sito scritto
dentro. Il programma lo usa per due cose.

**L'avviso di aggiornamento.** MTDesk legge `version.json` all'avvio e, se il
numero di versione scritto lì è più recente di quello installato, mostra al
cliente un cartellino con il pulsante di download. Il programma **non scarica
e non installa niente da solo**.

Indirizzo pubblico del file:
<https://dario-97-it.github.io/mtdesk/version.json>

**Le pagine di aiuto.** I cartellini di avviso dentro MTDesk hanno un link
"Aiuto" che apre nel browser `aiuto.html`, e la voce "Informativa sulla
privacy" apre `privacy.html`.

Questa pagina contiene anche **la procedura completa per pubblicare una
versione**, dal numero scritto nel codice fino al PC del cliente.

> **Stato a novembre 2026 — righe da togliere man mano che le cose vengono
> fatte.**
>
> - **GitHub Pages non è ancora attivo.** Gli indirizzi di questa cartella
>   rispondono con un errore 404. Finché è così l'avviso di aggiornamento non
>   compare mai (MTDesk gestisce il 404 in silenzio, senza mostrare errori) e i
>   link di aiuto e dell'informativa dentro il programma aprono una pagina di
>   errore. Come si attiva è scritto in "Come attivare GitHub Pages (una volta
>   sola)".
> - **Nessuna Release è ancora stata pubblicata.** I tre link di download
>   scritti in `version.json` oggi danno 404.
> - **La compilazione automatica su GitHub non è ancora mai arrivata in
>   fondo.** I dettagli sono al passo 2 della procedura qui sotto.
> - **La pagina di download per i clienti non è online**, e ha ancora i
>   segnaposto al posto dei contatti: vedi "La pagina di download (la
>   landing)".
> - **Il centralino non è ancora in opera**: vedi il riquadro alla fine del
>   passo 7.

## Cosa c'è in questa cartella

| File           | A cosa serve | Chi lo apre |
|----------------|--------------|-------------|
| `version.json` | Dice qual è l'ultima versione pubblicata e da dove si scarica. | MTDesk, da solo, a ogni avvio. |
| `aiuto.html`   | Spiega come risolvere i problemi più comuni (Wayland su Ubuntu, schermata di accesso, permessi, centralino). | Il link "Aiuto" dei cartellini di avviso dentro MTDesk. |
| `privacy.html` | Informativa sul trattamento dei dati. | La voce "Informativa sulla privacy" in *Impostazioni → Info programma* e, su Windows, il link "Contratto di licenza utente finale" della schermata di installazione. |
| `index.html`   | Pagina iniziale del sito: presenta MTDesk e rimanda alle altre pagine. | Chi apre l'indirizzo base <https://dario-97-it.github.io/mtdesk/>. |
| `_stile.css`   | La grafica delle tre pagine qui sopra. | Le pagine stesse. |
| `.nojekyll`    | File vuoto: dice a GitHub di pubblicare i file così come sono. | GitHub. |
| `README.md`    | Queste istruzioni. | Tu. |

> **Non rinominare questi file, e non cambiare gli `id` dei titoli dentro
> `aiuto.html`.** Gli indirizzi sono compilati dentro il programma, sezione
> compresa: per esempio, su Ubuntu, il cartellino di avviso su Wayland apre
> `aiuto.html#x11-richiesto`. Gli `id` usati dal programma sono cinque:
> `x11-richiesto`, `schermata-di-accesso`, `permessi`, `centralino` e
> `permessi-macos`. Se rinomini un file, i link dei programmi già installati
> sui PC dei clienti portano a una pagina di errore; se cambi un `id`, portano
> nel punto sbagliato della pagina. In tutti e due i casi per rimediare
> servirebbe una nuova versione del programma. Il **testo** delle pagine,
> invece, lo puoi correggere quando vuoi: basta un push.

Tutto quello che metti in questa cartella diventa pubblico: non lasciarci
appunti privati.

---

## Come pubblico una nuova versione

**L'ordine conta: prima il numero dentro il programma, poi la Release con i
file dentro, e SOLO ALLA FINE il numero in `version.json`.** Se tocchi
`version.json` prima, i clienti vedono l'avviso di aggiornamento ma il pulsante
li porta ancora al file della versione vecchia (o a un errore 404, se non
esiste nessuna Release): scaricano, riaprono, e l'avviso è ancora lì. E non per
qualche minuto: per tutto il tempo che GitHub impiega a compilare, che può
essere di ore.

I passi sono sette. I primi tre producono i file, gli altri quattro li fanno
arrivare ai clienti:

1. alzi il numero di versione dentro il programma;
2. crei il tag: GitHub compila e crea la Release;
3. controlli che la Release contenga tutti e sei i file;
4. controlli che GitHub Pages risponda;
5. controlli la pagina di download (la landing);
6. solo adesso cambi il numero in `version.json`;
7. fai la prova finale da un PC che non sia quello su cui lavori.

Negli esempi si passa dalla versione `1.4.9` alla `1.4.10`. Il numero nuovo
deve essere più alto del precedente contando numero per numero, non lettera
per lettera: `1.4.10` viene **dopo** `1.4.9`.

### Passo 1 — Alza il numero di versione dentro il programma

**Perché.** L'avviso di aggiornamento funziona per confronto: MTDesk prende il
numero scritto in `version.json` e lo confronta con **il proprio**, che gli
viene compilato dentro. Se pubblichi i file nuovi senza aver alzato il numero
nel codice, il programma nuovo continua a dichiararsi `1.4.9`: appena scrivi
`1.4.10` in `version.json` l'avviso compare a tutti, **anche a chi ha appena
scaricato la versione nuova**, e non si spegne più.

Il numero è scritto in quattro file, che vanno cambiati tutti insieme:

| File | Cosa cambiare | A cosa serve quel numero |
|------|---------------|--------------------------|
| `client/Cargo.toml` | riga 3: `version = "1.4.9"` | **È quello che conta.** È il numero che il programma dichiara (lo leggi in *Impostazioni → Info programma*), quello che viene confrontato con `version.json` e quello scritto dentro il pacchetto `.deb`. |
| `client/libs/portable/Cargo.toml` | riga 3: `version = "1.4.9"` | È il numero che Windows mostra nelle *Proprietà* dei due file `.exe` da distribuire. |
| `client/flutter/pubspec.yaml` | riga 19: `version: 1.4.9+67` | Lo usa la parte grafica del programma: è il numero di riserva del controllo aggiornamenti, ed è quello scritto nelle proprietà di `MTDesk.exe`, il file che sta dentro il pacchetto. Prima del `+` va lo stesso numero degli altri; dopo il `+` c'è un contatore, che per convenzione si alza di uno a ogni rilascio (`1.4.10+68`). |
| `client/Cargo.lock` | due righe, vedi qui sotto | È l'elenco bloccato delle librerie usate, e riporta anche i due numeri dei file `Cargo.toml` qui sopra. |

**Le due righe di `client/Cargo.lock`.** Aprilo con un editor di testo (è un
file di oltre undicimila righe: usa "Cerca") e:

- cerca `name = "rustdesk"`: la riga subito sotto è `version = "1.4.9"`, e lì
  scrivi il numero nuovo;
- cerca `name = "rustdesk-portable-packer"`: stessa cosa sulla riga subito
  sotto.

A novembre 2026 sono le righe 7149 e 7259. **Non usare "Sostituisci tutto"**:
nel file ci sono più di mille altre righe `version = ...`, una per ogni
libreria, e quelle non vanno toccate.

**Perché serve toccare anche il `Cargo.lock`.** La compilazione gira con
l'opzione `--locked` (la mettono `client/build.py` e
`client/libs/portable/generate.py`), che significa "l'elenco delle librerie è
questo, non ricalcolarlo". Se in un `Cargo.toml` c'è `1.4.10` e nel
`Cargo.lock` è rimasto `1.4.9`, la compilazione si ferma subito, sul PC come su
GitHub, con questo errore (al posto dei puntini c'è il percorso del file):

    error: the lock file ... needs to be updated but --locked was passed to prevent this

**Controllo prima di andare avanti.** In PowerShell:

```powershell
cd "D:\2026\VISUAL STUDIO\MTDESK"
Select-String -Path client\Cargo.toml, client\libs\portable\Cargo.toml -Pattern '^version = ' -List
Select-String -Path client\flutter\pubspec.yaml -Pattern '^version: '
Select-String -Path client\Cargo.lock -Pattern '^name = "rustdesk(-portable-packer)?"$' -Context 0,1
```

**Devi vedere** lo stesso numero cinque volte, così (i numeri di riga del
`Cargo.lock` possono essere diversi):

    client\Cargo.toml:3:version = "1.4.10"
    client\libs\portable\Cargo.toml:3:version = "1.4.10"
    client\flutter\pubspec.yaml:19:version: 1.4.10+68
    > client\Cargo.lock:7148:name = "rustdesk"
      client\Cargo.lock:7149:version = "1.4.10"
    > client\Cargo.lock:7258:name = "rustdesk-portable-packer"
      client\Cargo.lock:7259:version = "1.4.10"

Poi registra la modifica e mandala su GitHub:

```powershell
git add client/Cargo.toml client/libs/portable/Cargo.toml client/flutter/pubspec.yaml client/Cargo.lock
git commit -m "Versione 1.4.10"
git push origin main
```

**In questo commit `docs/version.json` NON va toccato.** GitHub Pages pubblica
questa cartella a ogni push: se il numero nuovo finisse online adesso, i
clienti vedrebbero l'avviso ore prima che i file esistano.

> **Altri due posti dove il numero di MTDesk è scritto a mano.** Non entrano
> nel programma, quindi non bloccano niente: il valore proposto nella casella
> del bottone manuale (`default: "v1.4.9"` in
> `.github/workflows/mtdesk-build.yml`) e il nome dell'installer MSI
> facoltativo in `client/scripts/build-mtdesk.ps1` (`MTDesk-1.4.9-x86_64.msi`,
> che non viene pubblicato). Aggiornarli è solo questione di ordine.
>
> **Dove invece leggi "RustDesk 1.4.9", non toccare niente.** Nel `README.md`
> principale, nelle note della Release e in altri documenti quel numero indica
> la versione di RustDesk da cui MTDesk è nato: fa parte della dichiarazione
> di origine e non segue i rilasci di MTDesk.
>
> Se in `client/res/` trovi ancora lo script `bump.sh`, **non usarlo**: è
> quello di RustDesk. Cerca i workflow in una cartella che in MTDesk non c'è
> più, e non conosce né `docs/version.json` né il nostro workflow.

### Passo 2 — Crea il tag: GitHub compila e crea la Release

Il **tag** è un'etichetta attaccata a un commit, che dice "questa è la versione
1.4.10". Quando su GitHub arriva un tag che comincia per `v`, parte da sola la
compilazione automatica descritta in `.github/workflows/mtdesk-build.yml`.

```powershell
cd "D:\2026\VISUAL STUDIO\MTDESK"
git tag v1.4.10
git push origin v1.4.10
```

Il numero dopo la `v` deve essere **identico** a quello che hai scritto in
`client/Cargo.toml`. A novembre 2026 nessuno fa questo confronto al posto tuo:
il workflow prende il nome della Release dal tag e basta. Con un tag `v1.4.10`
su un codice rimasto a `1.4.9` otterresti una Release che si chiama 1.4.10 e
contiene un programma che si dichiara 1.4.9.

Per seguire il lavoro: su GitHub, scheda **Actions**, esecuzione **MTDesk -
Build e Release**. I lavori sono quattro, e alla fine ognuno ha una spunta
verde o una croce rossa:

| Lavoro | Cosa fa | Cosa allega alla Release |
|--------|---------|--------------------------|
| 1. Controllo brand e centralino | Verifica che il codice sia davvero MTDesk (nome, centralino, chiave). Dura meno di un minuto. | niente |
| 2. Genera il bridge Dart-Rust | Prepara i file che collegano le due metà del programma. | niente |
| 3. Compila per Ubuntu (amd64) | Produce il pacchetto `.deb`. È anche il lavoro che scrive titolo e note della Release. | `mtdesk-ubuntu-amd64.deb` e il suo `.sha256` |
| 4. Compila per Windows (x86_64) | Produce i due `.exe`. | `MTDesk-windows-x86_64-install.exe`, `MTDesk-qs.exe` e i loro due `.sha256` |

I lavori 3 e 4 partono insieme, dopo i primi due, e non dipendono l'uno
dall'altro: ognuno allega i propri file appena finisce. Le stime scritte nel
workflow dicono fra una e due ore ciascuno la prima volta, perché vanno
costruite da zero le librerie native (ffmpeg e le altre), e molto meno le
volte successive.

Il file `.sha256` che accompagna ogni file contiene la sua **impronta**: un
codice che cambia se anche un solo byte del file è diverso. La calcola GitHub
durante la compilazione, e serve a chi scarica per controllare di avere il
file giusto e integro. **Non devi più calcolarla né incollarla tu da nessuna
parte.**

> **Non ancora collaudato.** A novembre 2026 questo percorso non è mai arrivato
> in fondo. L'unica esecuzione fatta finora si è fermata nel lavoro 3, al passo
> di vcpkg (quello che costruisce le librerie native), e la causa non è ancora
> stata trovata: lo stesso passo, provato in un contenitore Ubuntu 22.04
> pulito, riesce. Il lavoro 4 su GitHub non è mai partito: i due file Windows
> sono stati prodotti e provati soltanto compilando sul PC, con lo stesso
> `client/build.py` che usa il lavoro 4. La prima volta, quindi, metti in conto
> di dover leggere il registro di un lavoro fallito (vedi "Se un lavoro
> fallisce", al passo 3).

> **Solo per la prima Release (situazione a novembre 2026).** Su GitHub il tag
> `v1.4.9` esiste già, ma è fermo su un commit vecchio (`db2ab14`). A quel
> punto il workflow aveva solo tre lavori, senza Windows, e al programma
> mancavano le ultime modifiche: la finestra compatta dell'assistenza rapida
> e il nome `MTDesk.exe` dell'eseguibile (lì si chiamava ancora
> `rustdesk.exe`), dal quale dipende che l'installazione su Windows funzioni.
> L'esecuzione fallita di cui sopra è partita da lì, e a quel tag non è
> attaccata nessuna Release. Rilanciare quella esecuzione non produrrà mai i
> file Windows, e `git tag v1.4.9` risponde
> `fatal: tag 'v1.4.9' already exists`.
>
> **[DA DECIDERE: con quale numero esce la prima Release]** Le strade pulite
> sono due:
>
> - **come 1.4.10**: segui questa pagina così com'è, dal passo 1. La prima
>   versione pubblica si distingue così dalle copie di prova compilate finora,
>   che si dichiarano tutte `1.4.9`;
> - **come 1.4.9**: nel codice e in `version.json` il numero è già `1.4.9`,
>   quindi i passi 1 e 6 si saltano, ma il tag va tolto e rimesso sul commit
>   di oggi:
>
>   ```powershell
>   git tag -d v1.4.9
>   git push origin --delete v1.4.9
>   git tag v1.4.9
>   git push origin v1.4.9
>   ```
>
> Da evitare, invece, il bottone manuale lasciando `v1.4.9` nella casella:
> compilerebbe il codice di oggi ma lo allegherebbe al tag vecchio. Chi scarica
> i sorgenti da quella Release riceverebbe quelli del commit vecchio, diversi
> da quelli con cui sono fatti gli eseguibili: con la licenza AGPL i sorgenti
> offerti devono essere quelli del programma distribuito.

**Il bottone manuale.** La stessa compilazione si può lanciare a mano: su
GitHub, scheda **Actions** → **MTDesk - Build e Release** → **Run workflow**.
Chiede il nome del tag (la casella propone un valore fisso, oggi `v1.4.9`: va
corretto) e ha una casella **prerelease**. Se la spunti, la Release nasce come
"bozza di prova" (su GitHub porta l'etichetta *Pre-release*) e i link
`/releases/latest/` non si spostano: è il modo giusto di fare una prova senza
toccare quello che scaricano i clienti. Per un rilascio vero usa il tag, come
scritto sopra: così il tag indica esattamente il commit che è stato compilato.

### Passo 3 — Controlla che la Release contenga tutti e sei i file

Apri <https://github.com/Dario-97-it/mtdesk/releases/latest>.

**Devi vedere** la Release **MTDesk v1.4.10** con questi sei allegati:

    MTDesk-windows-x86_64-install.exe
    MTDesk-windows-x86_64-install.exe.sha256
    MTDesk-qs.exe
    MTDesk-qs.exe.sha256
    mtdesk-ubuntu-amd64.deb
    mtdesk-ubuntu-amd64.deb.sha256

GitHub ne aggiunge sempre altri due per conto suo, *Source code (zip)* e
*Source code (tar.gz)*: sono i sorgenti, e non contano.

Poi controlla che i tre link usati da MTDesk e dalla landing rispondano
davvero. In PowerShell (scrivi proprio `curl.exe`, con `.exe`: in PowerShell
`curl` da solo può essere un altro comando):

```powershell
$base = 'https://github.com/Dario-97-it/mtdesk/releases/latest/download'
foreach ($f in 'MTDesk-windows-x86_64-install.exe', 'MTDesk-qs.exe', 'mtdesk-ubuntu-amd64.deb') {
    $codice = curl.exe -s -o NUL -I -L -w '%{http_code}' "$base/$f"
    "$codice  $f"
}
```

**Devi vedere** tre righe che cominciano con `200`:

    200  MTDesk-windows-x86_64-install.exe
    200  MTDesk-qs.exe
    200  mtdesk-ubuntu-amd64.deb

Un `404` vuol dire che quel file nella Release non c'è. **Finché non sono tre
`200`, fermati qui e non toccare `version.json`.**

**Non scrivere niente a mano nel testo della Release.** Titolo e note sono un
testo fisso scritto nel workflow (le righe `name:` e `body:` del lavoro 3),
che viene riscritto da capo a ogni esecuzione: quello che aggiungi a mano va
perso. Oggi quel testo contiene anche l'avviso che il centralino non è ancora
attivo: il giorno in cui lo sarà, l'avviso va tolto da lì, altrimenti
ricompare a ogni rilascio.

**Se un lavoro fallisce.** Te ne accorgi dalla croce rossa in Actions e dal
fatto che nella Release mancano i suoi file. Cose da sapere:

- **La Release esiste lo stesso, ed è già "l'ultima".** I lavori 3 e 4 sono
  indipendenti: appena il primo dei due finisce, la Release viene creata e i
  link `/releases/latest/download/...` puntano a lei. I link dei file che
  ancora mancano danno 404, e con loro i pulsanti corrispondenti della
  landing. Succede anche quando va tutto bene, nell'attesa fra la fine del
  primo lavoro e la fine del secondo: per questo conviene rilasciare in un
  momento in cui non stai mandando clienti a scaricare.
- **Se la Release ha per titolo solo `v1.4.10` e nessun testo**, l'ha creata
  il lavoro 4 e il lavoro 3 non è arrivato in fondo: titolo e note li scrive
  il lavoro 3.
- **Per riprovare**, apri l'esecuzione in Actions e leggi il registro del
  lavoro con la croce rossa, per capire in quale passo si è fermato. Se la
  causa era passeggera (per esempio un download non riuscito), rilancialo con
  **Re-run failed jobs**: i file già allegati dall'altro lavoro restano al
  loro posto. Se invece per sistemare devi modificare qualcosa nel
  repository, la correzione finisce in un commit nuovo, che il tag di prima
  non contiene. La strada più semplice è uscire con il numero successivo:
  rifai i passi 1 e 2 (per esempio con `1.4.11`) e, quando la Release nuova è
  completa, cancella a mano dalla pagina delle Release quella rimasta a metà.
- **Piano B, se GitHub continua a fallire.** I file si possono compilare sul
  PC e caricare a mano nella Release: il workflow non cancella gli allegati
  che trova già. (Se nessuno dei due lavori è arrivato a crearla, la Release
  la crei tu dalla pagina *Releases* del repository, scegliendo il tag.)
  Valgono tre regole. I **nomi** devono essere esattamente quelli dell'elenco
  qui sopra. Ogni file va caricato **insieme al suo `.sha256`**. E le impronte
  **non vanno scritte nel testo della Release**, per il motivo detto prima.
  I due `.exe` escono nella cartella `client\` lanciando
  `client\scripts\build-mtdesk.ps1` (vedi `client/BUILD-WINDOWS.md`), e i loro
  `.sha256` si creano così, in PowerShell, dentro `client\`:

  ```powershell
  foreach ($f in 'MTDesk-windows-x86_64-install.exe', 'MTDesk-qs.exe') {
      $h = (Get-FileHash $f -Algorithm SHA256).Hash.ToLower()
      "$h *$f" | Out-File -FilePath "$f.sha256" -Encoding ascii -NoNewline
  }
  ```

  Per il `.deb` e il suo `.sha256` vedi `BUILD-UBUNTU.md`, nel passo che dà al
  pacchetto il nome definitivo. Tieni presente che le note della Release
  continueranno a dire che tutti i file sono compilati da GitHub Actions: per
  quelli caricati a mano non è vero.

### Passo 4 — Controlla che GitHub Pages risponda

Serve perché il numero che scriverai al passo 6 arrivi davvero ai programmi, e
perché i link di aiuto dentro MTDesk funzionino. Il controllo è quello della
sezione "Come provo che funziona", in fondo a questa pagina: quattro righe che
cominciano con `200`. Se Pages non è mai stato attivato, la sezione "Come
attivare GitHub Pages (una volta sola)" dice come si fa.

### Passo 5 — Controlla la pagina di download (la landing)

La landing non cambia da una versione all'altra: i suoi pulsanti puntano a
`/releases/latest/download/...`, quindi seguono da soli la Release nuova. Va
pubblicata una volta sola e, a ogni rilascio, ricontrollata premendo i tre
pulsanti. Dove si pubblica, e cosa controllare prima di dare l'indirizzo a un
cliente, è scritto più sotto in "La pagina di download (la landing)".

### Passo 6 — Solo adesso: cambia il numero in `version.json`

Apri `docs/version.json`, cambia **solo** il numero dentro `"version"`
(esempio: da `1.4.9` a `1.4.10`), salva e fai push. Fine: i link non vanno
mai toccati.

```powershell
git add docs/version.json
git commit -m "version.json: 1.4.10"
git push origin main
```

Dopo il push GitHub Pages si aggiorna da sé in un paio di minuti, e i clienti
vedranno l'avviso al successivo avvio di MTDesk.

> **Nel campo `version` scrivi solo numeri separati da punti** (`1.4.10`), mai
> etichette come `1.4.10-beta` oppure `v1.4.10 RC2`. MTDesk legge soltanto la
> parte numerica e butta via il resto: scrivere `1.4.9-beta` per lui è
> identico a scrivere `1.4.9`, quindi l'avviso non comparirebbe.

### Passo 7 — Prova finale, da un PC che non sia quello su cui lavori

Sul PC di sviluppo ci sono già file, impostazioni e programmi che un cliente
non ha: una prova fatta lì dimostra poco. Da un altro computer:

1. Scarica i file **dai pulsanti della landing** (o, finché la landing non è
   pubblicata, dalla pagina della Release), e dalla pagina della Release
   scarica nella stessa cartella anche i `.sha256`.
2. Controlla le impronte. Su Windows, in PowerShell, nella cartella dove hai
   scaricato i file:

   ```powershell
   foreach ($f in 'MTDesk-windows-x86_64-install.exe', 'MTDesk-qs.exe') {
       $atteso = ((Get-Content "$f.sha256" -Raw) -split '\s+')[0]
       $reale  = (Get-FileHash $f -Algorithm SHA256).Hash
       if ($reale -eq $atteso) { "OK       $f" } else { "DIVERSO  $f" }
   }
   ```

   **Devi vedere** due righe `OK`. (Le impronte dei due file Windows sono
   identiche fra loro: è giusto così, sono lo stesso programma con due nomi.)
   Su Ubuntu il controllo è `sha256sum -c mtdesk-ubuntu-amd64.deb.sha256`, e
   la risposta deve finire con `OK`.
3. Controlla che siano della versione giusta: vedi "Come capire quale versione
   hai in mano".
4. Apri `MTDesk-qs.exe`, su un PC dove MTDesk **non** è installato (dove è già
   installato, quel file apre il programma completo). I file non sono firmati,
   quindi Windows avvisa due volte, ed è previsto: prima può comparire la
   schermata blu *Windows ha protetto il PC* (si passa con *Ulteriori
   informazioni* → *Esegui comunque*), poi la richiesta dei permessi di
   amministratore, che indica un autore sconosciuto. **Devi vedere** la
   finestra compatta dell'assistenza rapida: logo, ID, password monouso, il
   pulsante Esci e lo stato del collegamento.
5. Apri `MTDesk-windows-x86_64-install.exe`. **Devi vedere** la schermata di
   installazione.
6. Su Ubuntu installa il pacchetto: `sudo apt install ./mtdesk-ubuntu-amd64.deb`.
7. Collegati da un computer all'altro. Se il computer da controllare è un
   Ubuntu con Wayland, qualcuno deve essere lì davanti per confermare la
   condivisione dello schermo.

> **Il collegamento, per ora, si può provare solo in rete locale.** Il
> centralino `mtdesk.marketingtools.digital`, quello scritto dentro il
> programma, a novembre 2026 non è ancora in opera: finché non lo è, due MTDesk
> appena scaricati non si trovano. La messa in opera è in
> `GUIDA-MESSA-IN-OPERA.md`; il suo capitolo 10 ha i cinque controlli di
> collaudo, compresa la prova fra due reti diverse, che è quella che conta.
> Nel frattempo c'è `deploy/avvia-centralino-locale.ps1`, che avvia un
> centralino sul PC Windows per le prove in rete locale e stampa l'indirizzo
> da scrivere a mano nei due MTDesk (*Impostazioni → Rete*).

---

## Perché i link non si toccano mai

Puntano tutti a `/releases/latest/download/<nome del file>`: GitHub li gira
automaticamente all'ultima Release pubblicata. È per questo motivo che i nomi
dei file **non contengono il numero di versione**: se lo contenessero, ogni
rilascio romperebbe i link della landing e di questo file.

Per i due file Windows c'è un motivo in più per non cambiare i nomi, nemmeno a
mano dopo averli scaricati: **è il nome del file a decidere che cosa fa il
programma**. I due file sono lo stesso identico programma. Quello il cui nome
finisce in `install.exe` apre la schermata di installazione; quello il cui
nome contiene `-qs.exe` si apre come assistenza rapida (finestra compatta,
niente installazione). Con un nome diverso da questi il programma si apre
nella versione completa, senza installarsi.

## Cosa significa ogni campo di `version.json`

| Campo                 | A cosa serve |
|-----------------------|--------------|
| `version`             | Il numero dell'ultima versione pubblicata. **È l'unico da aggiornare.** |
| `notes_url`           | Pagina aperta dal link "Novità programma" sotto il pulsante. |
| `download.windows`    | Il file Windows che si installa (`MTDesk-windows-x86_64-install.exe`). |
| `download.windows_qs` | Il file Windows di assistenza rapida (`MTDesk-qs.exe`), che non si installa. **A novembre 2026 il programma non legge questo campo**: vedi qui sotto. |
| `download.ubuntu`     | Pacchetto `.deb` per Ubuntu. |

MTDesk sceglie da solo il link giusto: Windows prende `download.windows`,
Ubuntu prende `download.ubuntu`. Se il campo mancasse, il pulsante apre
comunque la pagina delle Release, quindi un errore di battitura non lascia il
cliente a mani vuote.

**Il caso dell'assistenza rapida.** "Windows prende `download.windows`" vale
anche quando il cliente sta usando `MTDesk-qs.exe`: il programma non distingue
i due casi. La scelta sta nella funzione `_linkPerQuestoSistema` di
`client/flutter/lib/mtdesk_update.dart`, che guarda solo `windows` e `ubuntu`.
Per come è scritto il codice, quindi, quando alzerai il numero in
`version.json` chi apre un `MTDesk-qs.exe` vecchio vedrà il cartellino anche
nella finestra compatta, e il pulsante **Download** gli farà scaricare
`MTDesk-windows-x86_64-install.exe`: il file che si installa, cioè il
contrario di quello che la landing gli ha promesso. Non è ancora stato visto
succedere, perché `version.json` non è mai stato online.

**[DA DECIDERE: far leggere al programma `download.windows_qs` quando gira
come assistenza rapida, oppure togliere il campo]** La prima strada è una
modifica a `mtdesk_update.dart`, dopo la quale il programma va ricompilato e
ripubblicato; la seconda è togliere la riga da `version.json` e da questa
tabella, accettando che dall'assistenza rapida si scarichi l'installer. Fino
alla decisione il campo resta dov'è: non dà fastidio, ed è già il link giusto
per il giorno in cui il programma lo leggerà.

**Non c'è un link "senza installazione" per Ubuntu, e non va aggiunto.** Per
Linux la compilazione produce soltanto il pacchetto `.deb`: un campo in più
qui dentro punterebbe a un file che nessuno produce.

---

## Come arriva la versione nuova sui PC dei clienti

Pubblicare una versione non la porta sui computer: **MTDesk non si aggiorna da
solo**, ed è una scelta. L'aggiornamento automatico ereditato da RustDesk è
stato spento, perché interrogava i server di RustDesk e avrebbe installato
RustDesk al posto di MTDesk; la casella "Auto update" è stata tolta dalle
impostazioni. Al suo posto c'è solo il cartellino: avvisa e apre il browser.

**Chi vede il cartellino, e chi no.** Il controllo lo fa il programma con la
finestra, una volta sola, pochi secondi dopo essere stato avviato; il servizio
che lavora in sottofondo non controlla niente. Quindi:

- chi apre MTDesk lo vede (e può chiuderlo con la X: ricompare all'avvio
  successivo);
- un PC dove MTDesk è installato e lavora in sottofondo per l'accesso non
  presidiato, ma dove nessuno apre mai la finestra, **non lo vede mai**. Quei
  PC restano alla versione vecchia finché qualcuno non li aggiorna di persona.

**Come si aggiorna, caso per caso.**

| Caso | Cosa si fa |
|------|------------|
| Assistenza rapida (`MTDesk-qs.exe`) | Non c'è un programma installato da aggiornare: il cliente scarica di nuovo il file dalla landing, che dà sempre l'ultima versione. |
| Windows, MTDesk installato | Si scarica il nuovo `MTDesk-windows-x86_64-install.exe` (è il file che apre il pulsante **Download** del cartellino) e lo si esegue: ricompare la schermata di installazione, e si conferma con **Accetta e installa**. |
| Ubuntu | Si scarica il nuovo `mtdesk-ubuntu-amd64.deb` e si ripete il comando dell'installazione: `sudo apt install ./mtdesk-ubuntu-amd64.deb`. |

Tre avvertenze.

- **Il file vecchio va cancellato prima di scaricare quello nuovo.** I nomi
  sono sempre gli stessi: se nella cartella dei download c'è ancora il file
  precedente, il browser salva quello nuovo aggiungendo un numero al nome
  (per esempio `MTDesk-qs (1).exe`). Su Windows quel nome non viene più
  riconosciuto (vedi "Perché i link non si toccano mai"): il file si apre
  nella versione completa, e non come assistenza rapida o con la schermata di
  installazione. Su Ubuntu il comando `sudo apt install ./mtdesk-ubuntu-amd64.deb`
  prenderebbe di nuovo il file vecchio.
- **L'aggiornamento sopra una versione già installata non è ancora mai stato
  provato**, né su Windows né su Ubuntu: finora è esistito un solo numero di
  versione. Per come è scritto il codice, su Windows l'installazione comincia
  togliendo quella che trova (servizio e cartella del programma) e poi copia
  la versione nuova. Su Ubuntu `apt` lo tratta come un aggiornamento del
  pacchetto `mtdesk` perché il numero di versione scritto dentro il file
  nuovo è più alto: è un altro motivo per non saltare il passo 1. La prima
  volta fallo su un PC tuo e, prima di ripeterlo da un cliente, controlla che
  l'ID sia rimasto lo stesso e che la password permanente funzioni ancora.
- **Nessuno ti avvisa di quali PC sono rimasti indietro.** I PC con MTDesk
  installato non si aggiornano da soli e, se nessuno apre la finestra, non
  mostrano nemmeno il cartellino. Servono quindi due cose che questa pagina
  non può decidere al posto tuo:
  - **[DA DECIDERE: chi aggiorna i PC dei clienti con MTDesk installato, ed
    entro quanti giorni quando la versione nuova corregge un problema di
    sicurezza]**
  - **[DA DECIDERE: dove tieni l'elenco dei PC su cui MTDesk è installato]**
    Non in questo repository, che è pubblico.

## Come capire quale versione hai in mano

I file hanno sempre lo stesso nome, quindi dal nome non si capisce niente. Il
numero si legge così:

- **Un file `.exe` scaricato.** Tasto destro sul file → *Proprietà* → scheda
  *Dettagli* → riga **Versione prodotto**. Oppure, in PowerShell, nella
  cartella del file:

  ```powershell
  (Get-Item .\MTDesk-qs.exe).VersionInfo.ProductVersion
  ```

- **MTDesk aperto** (programma completo, Windows o Ubuntu). *Impostazioni →
  Info programma*, riga **Versione**.
- **Ubuntu**, dal terminale:

  ```bash
  dpkg -s mtdesk | grep '^Version'              # il pacchetto installato
  dpkg-deb -f mtdesk-ubuntu-amd64.deb Version   # un file .deb appena scaricato
  ```

Il numero dei file `.exe` viene da `client/libs/portable/Cargo.toml`; quello
mostrato dal programma e quello del pacchetto `.deb` vengono da
`client/Cargo.toml`. Se al passo 1 li hai alzati insieme, coincidono.

---

## La pagina di download (la landing)

È `landing/index.html`: la pagina per i clienti, con i tre pulsanti di
download e le istruzioni. **Non sta in questa cartella e, a novembre 2026, non
la pubblica nessuno**: GitHub Pages pubblica solo `docs/`, e il workflow non
la tocca. Va messa online a mano.

**[DA DECIDERE: dove vive la landing, e qual è il suo indirizzo definitivo]**
Le strade sono due:

- **sul sito di Marketing Tools**: si carica il file sul sito, e l'indirizzo
  lo decidi tu;
- **dentro questa cartella**: si copia il file in `docs/` con un altro nome
  (per esempio `docs/scarica.html`: un `index.html` qui c'è già) e dopo il
  push la pagina risponde a `https://dario-97-it.github.io/mtdesk/scarica.html`.
  In questo caso le copie diventano due e vanno tenute uguali: ogni correzione
  fatta a `landing/index.html` va ricopiata.

**Prima di dare l'indirizzo a un cliente**, controlla questi punti uno per uno.

1. **I contatti sono veri.** In fondo alla pagina oggi ci sono due segnaposto,
   `[INSERIRE EMAIL ASSISTENZA]` e `[INSERIRE TELEFONO ASSISTENZA]`: finché
   non li sostituisci con i dati veri, il cliente che ha bisogno di una mano
   legge quelli. Controllo veloce: nel file non deve più comparire `[INSERIRE`.
2. **L'intestazione è completa.** Mancano tre righe che dipendono
   dall'indirizzo definitivo: `og:url` (l'indirizzo della pagina), `og:image`
   (l'immagine che compare quando qualcuno incolla il link in una chat o in
   una mail: il file pronto è `brand/mt-og-image.png`) e l'icona della scheda
   del browser (`<link rel="icon">`: il file pronto è
   `brand/icons/mtdesk-32.png`). Gli indirizzi vanno scritti per intero, da
   `https://` in poi, e i due file immagine vanno caricati insieme alla
   pagina.
3. **I tre pulsanti scaricano davvero.** È il controllo del passo 3: tre
   `200`. Poi provali anche a mano, dalla pagina pubblicata.
4. **L'informativa è completa.** `docs/privacy.html` contiene ancora dei
   segnaposto `[DA COMPLETARE: ...]` (dati del titolare, contatto per la
   privacy, tempi di conservazione): sono dati che puoi mettere solo tu.
5. **Il centralino risponde.** Senza, il cliente scarica, apre, e non riesce a
   farsi trovare: vedi il riquadro alla fine del passo 7.

---

## Come attivare GitHub Pages (una volta sola)

**A novembre 2026 questo passo non è ancora stato fatto**: finché non lo fai,
gli indirizzi di questa cartella rispondono 404.

Nel repository: **Settings → Pages → Build and deployment → Source: Deploy from
a branch**, poi **Branch: `main`** e **cartella `/docs`**. Salva. Dopo qualche
minuto il sito risponde: controllalo con la sezione qui sotto.

Due cose da sapere prima di salvare:

- **Il repository deve essere pubblico.** Serve perché le pagine e i link di
  download rispondano a chiunque, senza chiedere un accesso a GitHub.
- **Va online tutto quello che c'è in questa cartella, così com'è**, e da quel
  momento ogni push su `main` lo aggiorna da solo: non esiste una bozza. Vale
  anche per `privacy.html` con i suoi `[DA COMPLETARE: ...]`, che il programma
  apre già.

Il file `.nojekyll` presente in questa cartella dice a GitHub di pubblicare i
file così come sono, senza passarli al motore per i blog. Non cancellarlo: il
foglio di stile si chiama `_stile.css`, e quel motore scarta proprio i file il
cui nome comincia con un trattino basso. Senza `.nojekyll` le pagine andrebbero
online senza la loro grafica.

## Come provo che funziona

Apri l'indirizzo del file nel browser
(<https://dario-97-it.github.io/mtdesk/version.json>): devi vedere il testo del
JSON. Se vedi una pagina di errore 404, GitHub Pages non è ancora attivo o la
cartella impostata nelle opzioni non è `/docs`.

Per controllare in un colpo solo i quattro indirizzi che MTDesk usa, in
PowerShell:

```powershell
$sito = 'https://dario-97-it.github.io/mtdesk'
foreach ($p in '', 'version.json', 'aiuto.html', 'privacy.html') {
    $codice = curl.exe -s -o NUL -I -L -w '%{http_code}' "$sito/$p"
    "$codice  $sito/$p"
}
```

**Devi vedere** quattro righe che cominciano con `200`:

    200  https://dario-97-it.github.io/mtdesk/
    200  https://dario-97-it.github.io/mtdesk/version.json
    200  https://dario-97-it.github.io/mtdesk/aiuto.html
    200  https://dario-97-it.github.io/mtdesk/privacy.html

Dopo il passo 6, aprendo `version.json` nel browser devi leggere il numero
nuovo.

La prova completa dell'avviso si può fare solo quando esistono due versioni:
apri un MTDesk della versione precedente dopo aver alzato il numero in
`version.json`, e dopo qualche secondo nella finestra deve comparire il
cartellino con il pulsante **Download**.
