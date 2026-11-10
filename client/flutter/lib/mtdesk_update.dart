// =====================================================================
//  MTDesk - Controllo aggiornamenti "a rischio zero"
// ---------------------------------------------------------------------
//  COSA FA, in parole semplici:
//  All'avvio del programma, dopo qualche secondo, MTDesk scarica un
//  piccolissimo file di testo pubblicato su GitHub Pages:
//
//      https://dario-97-it.github.io/mtdesk/version.json
//
//  Dentro c'e' scritto qual e' l'ultima versione disponibile. Se e' piu'
//  recente di quella installata, nella schermata principale compare un
//  cartellino con un pulsante che apre il browser sulla pagina di
//  download. Nient'altro.
//
//  COSA NON FA (ed e' la parte importante):
//  - NON scarica il programma da solo
//  - NON installa niente
//  - NON manda nessuna informazione sul PC del cliente: e' una semplice
//    lettura di un file pubblico, come aprire una pagina web
//  - Se GitHub e' irraggiungibile non succede assolutamente nulla:
//    nessun errore a schermo, nessun rallentamento all'avvio
//
//  PERCHE' UN FILE A PARTE:
//  MTDesk e' un fork di RustDesk. Tenere questo codice in un file nuovo e
//  separato significa che quando in futuro si aggiorna il codice di
//  RustDesk non ci sono conflitti da risolvere qui dentro.
//
//  NOTA: l'aggiornamento automatico originale di RustDesk (src/updater.rs)
//  resta SPENTO di proposito: punta ai server di RustDesk e scaricherebbe
//  RustDesk al posto di MTDesk.
//
//  PER PUBBLICARE UNA NUOVA VERSIONE non serve toccare questo file:
//  basta modificare docs/version.json. Vedi docs/README.md.
// =====================================================================

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/models/platform_model.dart';

// ---------------------------------------------------------------------
//  Indirizzi fissi
// ---------------------------------------------------------------------

/// Il file con il numero dell'ultima versione, pubblicato da GitHub Pages
/// partendo dalla cartella `docs/` del repository.
const String kMTDeskVersionJsonUrl =
    'https://dario-97-it.github.io/mtdesk/version.json';

/// Pagina delle release. Usata come ripiego se il file JSON non contiene
/// un link valido, cosi' il pulsante porta sempre da qualche parte.
const String kMTDeskReleasesUrl =
    'https://github.com/Dario-97-it/mtdesk/releases/latest';

/// Quanto aspettiamo al massimo la risposta di GitHub. Volutamente corto:
/// se la rete del cliente e' lenta ci arrendiamo subito e non disturbiamo.
const Duration _kTimeoutRete = Duration(seconds: 5);

/// Piccolo ritardo dopo l'avvio, per non rubare banda e CPU mentre il
/// programma si sta ancora collegando al centralino.
const Duration _kRitardoAvvio = Duration(seconds: 3);

// ---------------------------------------------------------------------
//  Stato osservabile, letto dalla schermata principale
// ---------------------------------------------------------------------

/// Numero della versione nuova trovata su GitHub (per esempio "1.4.10").
/// Resta vuoto se non ci sono aggiornamenti o se il controllo e' fallito:
/// finche' e' vuoto il cartellino non compare.
final RxString mtdeskNewVersion = ''.obs;

/// Indirizzo su cui mandare il browser quando si premi il pulsante.
/// Cambia in base al sistema: l'installer per Windows, il pacchetto .deb
/// per Ubuntu.
final RxString mtdeskUpdateDownloadUrl = ''.obs;

/// Indirizzo della pagina con l'elenco delle novita' (il link
/// "Novita' programma" sotto il pulsante).
final RxString mtdeskUpdateChangelogUrl = ''.obs;

// ---------------------------------------------------------------------
//  Confronto fra due numeri di versione
// ---------------------------------------------------------------------

/// Estrae i numeri da una stringa di versione: "1.4.10" diventa [1, 4, 10].
///
/// Prende SOLO il primo gruppo di numeri separati da punti e butta via tutto
/// il resto: "v1.4.10" diventa [1, 4, 10] e "1.4.9-beta1" diventa [1, 4, 9].
/// E' importante: se contassimo anche l'1 finale di "-beta1", quella versione
/// risulterebbe piu' recente di "1.4.9", e il cliente vedrebbe un avviso di
/// aggiornamento che non esiste.
List<int> _pezziVersione(String v) {
  final trovato = RegExp(r'\d+(?:\.\d+)*').firstMatch(v);
  if (trovato == null) return <int>[];
  return trovato
      .group(0)!
      .split('.')
      .map((p) => int.tryParse(p) ?? 0)
      .toList();
}

/// Confronta due versioni numero per numero.
/// Restituisce  1 se [a] e' piu' recente di [b],
///             -1 se e' piu' vecchia,
///              0 se sono uguali.
///
/// Serve perche' un confronto fra testi darebbe il risultato sbagliato:
/// come testo "1.4.9" viene DOPO "1.4.10", mentre come versione e' PRIMA.
int mtdeskConfrontaVersioni(String a, String b) {
  final pa = _pezziVersione(a);
  final pb = _pezziVersione(b);
  final quanti = pa.length > pb.length ? pa.length : pb.length;
  for (var i = 0; i < quanti; i++) {
    final va = i < pa.length ? pa[i] : 0;
    final vb = i < pb.length ? pb[i] : 0;
    if (va != vb) return va > vb ? 1 : -1;
  }
  return 0;
}

// ---------------------------------------------------------------------
//  Il controllo
// ---------------------------------------------------------------------

/// Legge la versione di MTDesk attualmente in esecuzione.
Future<String> _versioneInstallata() async {
  try {
    final v = (await bind.mainGetVersion()).trim();
    if (v.isNotEmpty) return v;
  } catch (e) {
    debugPrint('MTDesk aggiornamenti: versione locale non leggibile ($e)');
  }
  // Ripiego: la variabile globale riempita all'avvio da PackageInfo.
  return version.trim();
}

/// Sceglie il link giusto per il sistema su cui stiamo girando.
String _linkPerQuestoSistema(Map<String, dynamic> dati) {
  final download = dati['download'];
  if (download is Map) {
    String? scelto;
    if (isWindows) {
      scelto = download['windows']?.toString();
    } else if (isLinux) {
      scelto = download['ubuntu']?.toString();
    }
    if (scelto != null && scelto.isNotEmpty) return scelto;
  }
  final pagina = dati['notes_url']?.toString() ?? '';
  return pagina.isNotEmpty ? pagina : kMTDeskReleasesUrl;
}

/// Avvia il controllo aggiornamenti. Non blocca mai l'avvio: parte un
/// timer e tutto il resto avviene in sottofondo, dentro un try/catch che
/// inghiotte qualunque problema (rete assente, DNS bloccato, file JSON
/// malformato, GitHub offline...).
void mtdeskCheckUpdate() {
  // Nella versione web non ha senso: si aggiorna ricaricando la pagina.
  if (isWeb) return;

  Timer(_kRitardoAvvio, () async {
    try {
      final risposta =
          await http.get(Uri.parse(kMTDeskVersionJsonUrl)).timeout(_kTimeoutRete);
      if (risposta.statusCode != 200) {
        debugPrint(
            'MTDesk aggiornamenti: risposta ${risposta.statusCode}, lascio perdere');
        return;
      }

      final decodificato = jsonDecode(risposta.body);
      if (decodificato is! Map) return;
      final dati = Map<String, dynamic>.from(decodificato);

      final versioneRemota = (dati['version']?.toString() ?? '').trim();
      if (versioneRemota.isEmpty) return;

      final versioneLocale = await _versioneInstallata();
      if (versioneLocale.isEmpty) return;

      if (mtdeskConfrontaVersioni(versioneRemota, versioneLocale) <= 0) {
        debugPrint(
            'MTDesk aggiornamenti: sei aggiornato ($versioneLocale >= $versioneRemota)');
        return;
      }

      final changelog = (dati['notes_url']?.toString() ?? '').trim();

      // Prima i link, per ultimo il numero di versione: e' quest'ultima
      // assegnazione che fa comparire il cartellino, quindi quando compare
      // i link sono sicuramente gia' pronti.
      mtdeskUpdateDownloadUrl.value = _linkPerQuestoSistema(dati);
      mtdeskUpdateChangelogUrl.value =
          changelog.isNotEmpty ? changelog : kMTDeskReleasesUrl;
      mtdeskNewVersion.value = versioneRemota;

      debugPrint(
          'MTDesk aggiornamenti: disponibile $versioneRemota (installata $versioneLocale)');
    } catch (e) {
      // Volutamente silenzioso: un aggiornamento non trovato non e' un
      // problema dell'utente, e il cliente non deve vedere errori.
      debugPrint('MTDesk aggiornamenti: controllo non riuscito ($e)');
    }
  });
}

// ---------------------------------------------------------------------
//  Quello che serve alla schermata principale
// ---------------------------------------------------------------------

/// Testo del cartellino, per esempio:
/// "E' disponibile una nuova versione di MTDesk (1.4.10)."
/// Usa la traduzione gia' presente in src/lang/*.rs, quindi il messaggio
/// resta multilingua senza scrivere frasi fisse in italiano nel codice.
String mtdeskTestoBannerAggiornamento() {
  final nomeApp = bind.mainGetAppNameSync();
  return '${translate("new-version-of-{$nomeApp}-tip")} (${mtdeskNewVersion.value}).';
}

/// Link da usare per il "Novita' programma" sotto il pulsante.
String mtdeskLinkChangelog() {
  final l = mtdeskUpdateChangelogUrl.value;
  return l.isNotEmpty ? l : kMTDeskReleasesUrl;
}

/// Apre il browser di sistema sulla pagina (o sul file) di download.
/// Non scarica nulla da dentro il programma: da qui in poi decide l'utente.
Future<void> mtdeskApriPaginaDownload() async {
  var indirizzo = mtdeskUpdateDownloadUrl.value;
  if (indirizzo.isEmpty) indirizzo = kMTDeskReleasesUrl;
  try {
    await launchUrl(Uri.parse(indirizzo));
  } catch (e) {
    debugPrint('MTDesk aggiornamenti: browser non apribile ($e)');
  }
}
