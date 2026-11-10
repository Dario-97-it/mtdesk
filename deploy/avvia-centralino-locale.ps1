<#
  =====================================================================
   MTDesk - Avvia il centralino SUL QUESTO PC (prova in rete locale)
   Marketing Tools - marketingtools.digital
  ---------------------------------------------------------------------
   A COSA SERVE

   A provare MTDesk fra due computer in casa, SENZA VPS e senza DNS.
   Il centralino (hbbs + hbbr) gira su questo PC Windows; l'altro
   computer - per esempio il PC Linux - si collega all'indirizzo di
   rete locale di questa macchina.

   NON e' il modo di mandarlo in produzione: appena spegni questo PC il
   centralino si ferma, e funziona solo dentro casa. Per l'uso vero con
   i clienti serve il VPS, ed e' spiegato in GUIDA-MESSA-IN-OPERA.md.

   COME SI USA

       powershell -ExecutionPolicy Bypass -File deploy\avvia-centralino-locale.ps1

   Lo script: controlla le chiavi, apre le porte nel firewall (chiede
   una conferma UAC la prima volta), avvia i due programmi e stampa
   l'indirizzo da scrivere nei client.

   Per fermarlo: chiudi questa finestra, oppure Ctrl+C.
  =====================================================================
#>
[CmdletBinding()]
param(
  # Cartella con le chiavi. Deve contenere id_ed25519 e id_ed25519.pub.
  [string]$CartellaDati = (Join-Path $PSScriptRoot 'data'),
  # Binari del centralino, prodotti da: cd server; cargo +stable build --release
  [string]$CartellaBinari = (Join-Path (Split-Path $PSScriptRoot -Parent) 'server\target\release'),
  # Salta la configurazione del firewall (se l'hai gia' fatta)
  [switch]$SaltaFirewall
)

$ErrorActionPreference = 'Stop'

function Titolo($t) { Write-Host "`n=== $t ===" -ForegroundColor Cyan }
function Ok($t)     { Write-Host "  OK   $t" -ForegroundColor Green }
function Problema($t) { Write-Host "  !!   $t" -ForegroundColor Red }
function Nota($t)   { Write-Host "       $t" -ForegroundColor DarkGray }

# ---------------------------------------------------------------------
Titolo "1. Controllo dei programmi"
$hbbs = Join-Path $CartellaBinari 'hbbs.exe'
$hbbr = Join-Path $CartellaBinari 'hbbr.exe'
foreach ($f in @($hbbs, $hbbr)) {
  if (-not (Test-Path $f)) {
    Problema "manca $f"
    Nota "Compilalo cosi':"
    Nota "    cd `"$(Split-Path $PSScriptRoot -Parent)\server`""
    Nota "    cargo +stable build --release"
    Nota "Serve Cargo 1.78 o superiore: la toolchain 1.75 del client NON va bene qui."
    exit 1
  }
}
Ok "hbbs.exe e hbbr.exe trovati"

# ---------------------------------------------------------------------
Titolo "2. Controllo delle chiavi"
if (-not (Test-Path $CartellaDati)) { New-Item -ItemType Directory -Force -Path $CartellaDati | Out-Null }
$chiavePriv = Join-Path $CartellaDati 'id_ed25519'
$chiavePub  = Join-Path $CartellaDati 'id_ed25519.pub'

if (-not (Test-Path $chiavePriv)) {
  Problema "manca la chiave privata: $chiavePriv"
  Nota "Senza, hbbs ne genera una NUOVA: i client gia' compilati non si"
  Nota "collegherebbero piu', perche' dentro hanno la chiave pubblica vecchia."
  exit 1
}
$pub = (Get-Content $chiavePub -Raw).Trim()
Ok "chiave presente"
Nota "chiave pubblica: $pub"

# Confronto con quella compilata nel client: se non combaciano, il client
# rifiuta il centralino e non si capisce perche'.
$configRs = Join-Path (Split-Path $PSScriptRoot -Parent) 'client\libs\hbb_common\src\config.rs'
if (Test-Path $configRs) {
  $m = Select-String -Path $configRs -Pattern 'RS_PUB_KEY:\s*&str\s*=\s*"([^"]+)"' | Select-Object -First 1
  if ($m) {
    $pubClient = $m.Matches[0].Groups[1].Value
    if ($pubClient -eq $pub) { Ok "combacia con la chiave compilata nel client" }
    else {
      Problema "NON combacia con la chiave compilata nel client!"
      Nota "  nel client: $pubClient"
      Nota "  qui:        $pub"
      Nota "I client non si collegheranno. Allinea le due cose prima di continuare."
    }
  }
}

# ---------------------------------------------------------------------
Titolo "3. Indirizzo di questo PC in rete locale"
$ip = (Get-NetIPConfiguration |
  Where-Object { $_.IPv4DefaultGateway -ne $null -and $_.NetAdapter.Status -eq 'Up' } |
  Select-Object -First 1).IPv4Address.IPAddress
if (-not $ip) {
  Problema "non riesco a determinare l'indirizzo locale"
  Nota "Trovalo con: ipconfig    (voce 'Indirizzo IPv4')"
  exit 1
}
Ok "indirizzo locale: $ip"

# ---------------------------------------------------------------------
if (-not $SaltaFirewall) {
  Titolo "4. Porte nel firewall di Windows"
  $regole = @(
    @{ Nome = 'MTDesk centralino 21115 TCP'; Porta = 21115; Protocollo = 'TCP' },
    @{ Nome = 'MTDesk centralino 21116 TCP'; Porta = 21116; Protocollo = 'TCP' },
    @{ Nome = 'MTDesk centralino 21116 UDP'; Porta = 21116; Protocollo = 'UDP' },
    @{ Nome = 'MTDesk centralino 21117 TCP'; Porta = 21117; Protocollo = 'TCP' }
  )
  # Il profilo della rete a cui il PC e' collegato ADESSO. Le regole vanno
  # create per QUESTO profilo: Windows classifica ogni rete come Private o
  # Public, e una regola "solo Private" su una rete che Windows considera
  # Public non ha nessun effetto. Capita spesso che la rete di casa risulti
  # Public (e' il default finche' non la si cambia a mano): la prima versione
  # di questo script creava regole solo Private e su quei PC non apriva nulla.
  $profilo = (Get-NetConnectionProfile | Where-Object { $_.IPv4Connectivity -ne 'Disconnected' } | Select-Object -First 1).NetworkCategory
  if (-not $profilo) { $profilo = 'Private' }
  if ($profilo -eq 'DomainAuthenticated') { $profilo = 'Domain' }
  Nota "rete attuale classificata da Windows come: $profilo"

  # Quando hbbs/hbbr partono la prima volta, Windows mostra la finestra
  # "Consentire l'accesso?": se si e' risposto di si', esistono gia' regole
  # per i due programmi e non serve crearne altre.
  $giaConsentiti = Get-NetFirewallRule -Direction Inbound -Enabled True -Action Allow -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName -match '^(hbbs|hbbr)$' -and ($_.Profile -match $profilo -or $_.Profile -eq 'Any') }
  if (($giaConsentiti | Select-Object -ExpandProperty DisplayName -Unique | Measure-Object).Count -ge 2) {
    Ok "hbbs e hbbr sono gia' consentiti dal firewall sul profilo $profilo"
  } else {
    $admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $admin) {
      Problema "non sei amministratore: non posso aprire le porte"
      Nota "Apri PowerShell COME AMMINISTRATORE e lancia una volta sola:"
      foreach ($r in $regole) {
        Nota "  New-NetFirewallRule -DisplayName '$($r.Nome)' -Direction Inbound -Action Allow -Protocol $($r.Protocollo) -LocalPort $($r.Porta) -Profile $profilo"
      }
      Nota "Poi rilancia questo script con  -SaltaFirewall"
    } else {
      foreach ($r in $regole) {
        if (Get-NetFirewallRule -DisplayName $r.Nome -ErrorAction SilentlyContinue) {
          Ok "regola gia' presente: $($r.Nome)"
        } else {
          New-NetFirewallRule -DisplayName $r.Nome -Direction Inbound -Action Allow `
            -Protocol $r.Protocollo -LocalPort $r.Porta -Profile $profilo | Out-Null
          Ok "creata: $($r.Nome) (profilo $profilo)"
        }
      }
    }
  }
}

# ---------------------------------------------------------------------
Titolo "5. Avvio"
Nota "I due programmi scrivono le chiavi e il database in: $CartellaDati"
Push-Location $CartellaDati
try {
  # hbbr per primo: hbbs gli si appoggia per il relay.
  # -k _  => accetta solo client con la nostra chiave. Senza, il relay
  #          sarebbe un tunnel aperto a chiunque.
  $pr = Start-Process -FilePath $hbbr -ArgumentList '-k', '_' -PassThru -NoNewWindow
  Start-Sleep -Seconds 2
  $ps = Start-Process -FilePath $hbbs -ArgumentList '-r', "${ip}:21117", '-k', '_' -PassThru -NoNewWindow
  Start-Sleep -Seconds 3

  if ($pr.HasExited) { Problema "hbbr si e' chiuso subito (codice $($pr.ExitCode))" }  else { Ok "hbbr avviato (PID $($pr.Id))" }
  if ($ps.HasExited) { Problema "hbbs si e' chiuso subito (codice $($ps.ExitCode))" }  else { Ok "hbbs avviato (PID $($ps.Id))" }

  Titolo "6. Verifica che stiano ascoltando"
  # NOTA: si prova una CONNESSIONE VERA, non si guarda netstat.
  # hbbs e hbbr aprono socket dual-stack su [::], e su Windows
  # `Get-NetTCPConnection -State Listen` e netstat li riportano come
  # "Closed" o con lo stato vuoto anche quando funzionano benissimo:
  # verificato, le connessioni passano lo stesso. Fidarsi di quel
  # controllo faceva dichiarare guasto un centralino sano.
  foreach ($porta in 21115, 21116, 21117) {
    $c = New-Object System.Net.Sockets.TcpClient
    try {
      $t = $c.ConnectAsync('127.0.0.1', $porta)
      if ($t.Wait(2500) -and $c.Connected) { Ok "$porta/tcp risponde" }
      else { Problema "$porta/tcp non risponde" }
    } catch { Problema "$porta/tcp non risponde" }
    finally { $c.Close() }
  }
  $udp = Get-NetUDPEndpoint -LocalPort 21116 -ErrorAction SilentlyContinue
  if ($udp) { Ok "21116/udp aperta" } else { Problema "21116/udp NON aperta (obbligatoria!)" }

  # -----------------------------------------------------------------
  Write-Host "`n`n======================================================================" -ForegroundColor Green
  Write-Host " CENTRALINO ATTIVO" -ForegroundColor Green
  Write-Host "======================================================================" -ForegroundColor Green
  Write-Host ""
  Write-Host " Su OGNI computer (questo e quello Linux), dentro MTDesk:" -ForegroundColor White
  Write-Host "   Impostazioni  ->  Rete  ->  Server ID/Inoltro" -ForegroundColor White
  Write-Host ""
  Write-Host ("   Server ID        {0}" -f $ip) -ForegroundColor Yellow
  Write-Host ("   Server inoltro   {0}" -f $ip) -ForegroundColor Yellow
  Write-Host  "   Server API       (lascia vuoto)" -ForegroundColor Yellow
  Write-Host ("   Key              {0}" -f $pub) -ForegroundColor Yellow
  Write-Host ""
  Write-Host " Poi chiudi e riapri MTDesk. In basso deve comparire il pallino" -ForegroundColor White
  Write-Host " VERDE e la scritta 'Pronto'. Se resta arancione, il client non" -ForegroundColor White
  Write-Host " raggiunge questo PC: controlla il firewall e che siano sulla" -ForegroundColor White
  Write-Host " stessa rete." -ForegroundColor White
  Write-Host ""
  Write-Host " Per fermare il centralino: chiudi questa finestra." -ForegroundColor DarkGray
  Write-Host "======================================================================" -ForegroundColor Green
  Write-Host ""

  Write-Host "Registro del centralino (Ctrl+C per uscire):`n" -ForegroundColor DarkGray
  Wait-Process -Id $ps.Id
}
finally {
  Pop-Location
  foreach ($p in @($ps, $pr)) {
    if ($p -and -not $p.HasExited) { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue }
  }
  Write-Host "`nCentralino fermato." -ForegroundColor DarkGray
}
