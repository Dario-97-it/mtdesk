# `third_party/` — le librerie portate dentro al progetto

Scritto per chi manutiene MTDesk.

## Cosa c'è qui dentro

Librerie Rust che prima venivano **scaricate a ogni compilazione** da repository GitHub di altri,
in gran parte sotto l'organizzazione `rustdesk-org`. Adesso stanno qui, al **commit esatto** che
`Cargo.lock` già fissava: il codice compilato è identico a prima, byte per byte, ma la build non
contatta più nessuno.

Ogni cartella contiene un file `.commit-originale` con il commit da cui proviene, perché le
cartelle `.git` sono state rimosse (altrimenti git le tratterebbe come sottomoduli — ed è proprio
il problema che stavamo togliendo).

## Perché, in concreto

Tre ragioni, in ordine di importanza:

1. **Se quei repository spariscono, MTDesk non si compila più.** Sono repository di terzi su cui
   non abbiamo nessun controllo: possono essere rinominati, resi privati o cancellati.
2. **Non avevamo controllo su cosa contenevano.** `Cargo.lock` fissa il commit, quindi un
   cambiamento non sarebbe entrato di nascosto — ma solo finché nessuno esegue `cargo update`.
3. **È una richiesta esplicita del progetto:** MTDesk non deve dipendere dall'infrastruttura di
   RustDesk. Il codice derivato resta AGPL e gli avvisi di copyright restano intatti — quella è
   un'altra cosa, ed è un obbligo di legge.

## Come sono state prese

Per ciascuna: `git init`, `git fetch --depth 1 origin <commit>`, `git checkout <commit>`, poi
rimozione di `.git`. Quattro di esse avevano **sottomoduli con codice C** indispensabile alla
compilazione, presi con `git submodule update --init --recursive`:

| Cartella | Sottomodulo | Serve a |
|---|---|---|
| `hwcodec/externals` | `rustdesk-org/externals` | intestazioni per l'accelerazione hardware |
| `kcp-sys/kcp` | `skywind3000/kcp` | `ikcp.c`, il protocollo di trasporto |
| `rust-webm/src/sys/libwebm` | `chromium.googlesource.com/webm/libwebm` | muxer WebM |
| `tao/deps/apk-builder` | — | solo Android, non preso: non serve |

Senza quei sottomoduli `cargo check` falliva con
`failed to run custom build command for webm-sys / kcp-sys`.

**`wezterm` è stata sfoltita di proposito**: il repository originale pesa 233 MB (ha dentro
documentazione, asset e una ventina di crate), ma a MTDesk servono solo `filedescriptor` e `pty`,
che non dipendono dal resto. Ridotta a 193 KB, licenza inclusa.

## Come si collegano al progetto

Con i blocchi `[patch]` in fondo a `client/Cargo.toml` e `server/Cargo.toml`, che reindirizzano
ogni sorgente git al percorso locale. In `[workspace]` la cartella è dichiarata in `exclude`,
altrimenti Cargo pretenderebbe che ogni crate qui dentro sia un membro del workspace.

Verifica che non sia rimasto nulla da scaricare:

```bash
grep -c 'source = "git+' client/Cargo.lock   # deve dare 0
grep -c 'source = "git+' server/Cargo.lock   # deve dare 0
```

## Come si aggiorna una libreria

Serve solo se c'è una ragione precisa — tipicamente una correzione di sicurezza. Non esiste più un
`cargo update` che lo faccia da solo, ed è voluto.

```bash
cd client/third_party
rm -rf <nome>
mkdir <nome> && cd <nome>
git init && git remote add origin <url-dal-blocco-patch>
git fetch --depth 1 origin <nuovo-commit>
git checkout <nuovo-commit>
git submodule update --init --recursive --depth 1   # solo se ha sottomoduli
rm -rf .git && echo <nuovo-commit> > .commit-originale
cd ../.. && cargo check --release --features flutter,hwcodec
```

## Licenze

Ogni cartella conserva il proprio file di licenza. Sono licenze permissive (MIT, Apache-2.0) o
AGPL-3.0 come il resto del progetto. **Non vanno rimossi**: distribuire questo codice senza i suoi
avvisi di licenza è violazione di copyright, indipendentemente dal fatto che il repository sia
nostro.

## `libdrmtap`

Caso a parte. Serve solo alla variante Linux per l'accesso non presidiato su Wayland
(`build.py --drm`) e non è un crate Rust ma una libreria C costruita con meson. Prima `build.py` la
scaricava da `rustdesk-org/libdrmtap` a ogni build e `.gitignore` la escludeva.

Adesso è qui, al commit `5da68a3a36` (libdrmtap 0.5.4), come albero **non-git**: `build.py` in quel
caso salta sia il download sia la verifica del commit e usa quello che trova, quindi non serve
nessuna modifica al codice di build. Il commit è registrato in `.commit-originale`.
