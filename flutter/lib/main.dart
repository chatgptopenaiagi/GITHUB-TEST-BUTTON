import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'diagnostics/core.dart';
import 'diagnostics/write_test.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GtbApp());
}

const translations = {
  'en': {
    'test': 'TEST GITHUB CONNECTION',
    'ready': 'One button. Clear answers.',
    'subtitle': 'Understand your connection, account and repository access.',
    'dashboard': 'Connection',
    'repositories': 'Repositories',
    'advanced': 'Details & reports',
    'settings': 'Settings',
    'checking': 'Checking',
    'public': 'Public access works without signing in.',
    'inspect': 'Inspect repository',
    'write': 'TEST GITHUB WRITE ACCESS',
    'copy': 'Copy report',
    'json': 'Export JSON',
    'txt': 'Export TXT',
    'share': 'Share JSON',
    'theme': 'Appearance',
    'system': 'System',
    'dark': 'Dark',
    'light': 'Light',
    'language': 'Language',
    'font': 'Text size',
    'history': 'Recent tests',
    'notTested': 'Not tested yet',
    'account': 'GitHub account',
    'readOnly': 'Read-only diagnostics · No repositories or files are changed',
    'profile': 'Open profile',
    'repository': 'Open repository',
    'confirm': 'Create and verify',
    'cancel': 'Cancel',
    'writeTitle': 'Choose a write test',
    'existing': 'Existing owned repository',
    'new': 'New private test repository',
    'notice':
        'This creates a local commit and a unique remote branch containing GTB-VERIFY.txt. A new repository is private. Nothing is deleted automatically.',
    'target': 'Target repository',
    'pending':
        'Mobile authentication is pending OAuth registration and a secure exchange service. Public diagnostics are fully available.',
    'save': 'Save',
    'scope': 'Account lookup (public username)',
    'permission':
        'Write capability remains NOT TESTED until you run an explicit write test.',
    'empty': 'Run a connection test to see measured results.'
  },
  'ro': {
    'test': 'TESTEAZĂ CONEXIUNEA GITHUB',
    'ready': 'Un buton. Răspunsuri clare.',
    'subtitle': 'Verifică conexiunea, contul și accesul la depozite.',
    'dashboard': 'Conexiune',
    'repositories': 'Depozite',
    'advanced': 'Detalii și rapoarte',
    'settings': 'Setări',
    'checking': 'Se verifică',
    'public': 'Accesul public funcționează fără autentificare.',
    'inspect': 'Verifică depozitul',
    'write': 'TESTEAZĂ ACCESUL DE SCRIERE',
    'copy': 'Copiază raportul',
    'json': 'Exportă JSON',
    'txt': 'Exportă TXT',
    'share': 'Partajează JSON',
    'theme': 'Aspect',
    'system': 'Sistem',
    'dark': 'Întunecat',
    'light': 'Luminos',
    'language': 'Limbă',
    'font': 'Mărimea textului',
    'history': 'Teste recente',
    'notTested': 'Încă netestat',
    'account': 'Cont GitHub',
    'readOnly':
        'Diagnosticare numai pentru citire · Nu se modifică fișiere sau depozite',
    'profile': 'Deschide profilul',
    'repository': 'Deschide depozitul',
    'confirm': 'Creează și verifică',
    'cancel': 'Anulează',
    'writeTitle': 'Alege testul de scriere',
    'existing': 'Depozit existent propriu',
    'new': 'Depozit privat nou de test',
    'notice':
        'Se creează un commit local și o ramură unică cu GTB-VERIFY.txt. Depozitul nou este privat. Nimic nu se șterge automat.',
    'target': 'Depozit țintă',
    'pending':
        'Autentificarea mobilă așteaptă înregistrarea OAuth și un serviciu securizat. Diagnosticarea publică este disponibilă.',
    'save': 'Salvează',
    'scope': 'Cont public de verificat',
    'permission':
        'Scrierea rămâne NETESTATĂ până la rularea explicită a testului.',
    'empty': 'Rulează un test pentru a vedea rezultatele măsurate.'
  },
  'de': {
    'test': 'GITHUB-VERBINDUNG TESTEN',
    'ready': 'Ein Knopf. Klare Antworten.',
    'subtitle': 'Verbindung, Konto und Repository-Zugriff prüfen.',
    'dashboard': 'Verbindung',
    'repositories': 'Repositories',
    'advanced': 'Details und Berichte',
    'settings': 'Einstellungen',
    'checking': 'Prüfung',
    'public': 'Öffentlicher Zugriff funktioniert ohne Anmeldung.',
    'inspect': 'Repository prüfen',
    'write': 'GITHUB-SCHREIBZUGRIFF TESTEN',
    'copy': 'Bericht kopieren',
    'json': 'JSON exportieren',
    'txt': 'TXT exportieren',
    'share': 'JSON teilen',
    'theme': 'Darstellung',
    'system': 'System',
    'dark': 'Dunkel',
    'light': 'Hell',
    'language': 'Sprache',
    'font': 'Textgröße',
    'history': 'Letzte Tests',
    'notTested': 'Noch nicht getestet',
    'account': 'GitHub-Konto',
    'readOnly': 'Nur lesende Diagnose · Keine Repository- oder Dateiänderungen',
    'profile': 'Profil öffnen',
    'repository': 'Repository öffnen',
    'confirm': 'Erstellen und prüfen',
    'cancel': 'Abbrechen',
    'writeTitle': 'Schreibtest auswählen',
    'existing': 'Eigenes vorhandenes Repository',
    'new': 'Neues privates Test-Repository',
    'notice':
        'Erstellt einen lokalen Commit und einen eindeutigen Branch mit GTB-VERIFY.txt. Ein neues Repository ist privat. Es wird nichts automatisch gelöscht.',
    'target': 'Ziel-Repository',
    'pending':
        'Mobile Anmeldung wartet auf OAuth-Registrierung und sicheren Austauschdienst. Öffentliche Diagnose ist verfügbar.',
    'save': 'Speichern',
    'scope': 'Öffentlicher Benutzername',
    'permission':
        'Schreibzugriff bleibt UNGETESTET bis zum ausdrücklich gestarteten Schreibtest.',
    'empty': 'Starten Sie einen Verbindungstest für gemessene Ergebnisse.'
  },
};

class GtbApp extends StatefulWidget {
  final Diagnostics? diagnostics;
  const GtbApp({super.key, this.diagnostics});
  @override
  State<GtbApp> createState() => _GtbAppState();
}

class _GtbAppState extends State<GtbApp> {
  late final Diagnostics diagnostics = widget.diagnostics ?? Diagnostics();
  ThemeMode mode = ThemeMode.system;
  String language = 'en';
  double fontScale = 1;
  int page = 0;
  bool busy = false;
  String progress = '';
  DiagnosticReport? report;
  Check? repoResult;
  Check? writeResult;
  final checks = <Check>[];
  final history = <Map<String, dynamic>>[];
  final repoController = TextEditingController();
  final publicController = TextEditingController(text: 'octocat');
  SharedPreferences? preferences;
  String t(String key) =>
      translations[language]?[key] ?? translations['en']![key] ?? key;
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    repoController.dispose();
    publicController.dispose();
    super.dispose();
  }

  Future<void> load() async {
    preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      language = preferences!.getString('language') ?? 'en';
      if (!translations.containsKey(language)) language = 'en';
      mode = ThemeMode.values[(preferences!.getInt('theme') ?? 0).clamp(0, 2)];
      fontScale = (preferences!.getDouble('fontScale') ?? 1).clamp(.85, 1.3);
      publicController.text =
          preferences!.getString('publicAccount') ?? 'octocat';
      try {
        history.addAll(
            (jsonDecode(preferences!.getString('history') ?? '[]') as List)
                .map((e) => Map<String, dynamic>.from(e)));
      } catch (_) {}
    });
  }

  Future<void> save() async {
    await preferences?.setString('language', language);
    await preferences?.setInt('theme', mode.index);
    await preferences?.setDouble('fontScale', fontScale);
    await preferences?.setString('publicAccount', publicController.text.trim());
  }

  Future<void> testConnection() async {
    if (busy) return;
    setState(() {
      busy = true;
      checks.clear();
      report = null;
      progress = 'network';
    });
    try {
      final result = await diagnostics.run(
          publicAccount: publicController.text.trim().isEmpty
              ? 'octocat'
              : publicController.text.trim(),
          onCheck: (c) {
            if (mounted) setState(() => checks.add(c));
          },
          onProgress: (s) {
            if (mounted) setState(() => progress = s);
          });
      if (!mounted) return;
      setState(() {
        report = result;
        history.insert(0, {
          'timestamp': result.timestamp,
          'status': result.overall,
          'duration_ms': result.durationMs
        });
        if (history.length > 10) history.removeLast();
      });
      await preferences?.setString('history', jsonEncode(history));
    } catch (e) {
      if (mounted) {
        setState(() => checks.add(Check('application', 'UNKNOWN_ERROR',
            'Diagnostic suite stopped: ${e.runtimeType}')));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> inspect() async {
    if (busy) return;
    setState(() {
      busy = true;
      progress = 'repository';
    });
    final result = await diagnostics.repository(repoController.text.trim());
    if (mounted) {
      setState(() {
        repoResult = result;
        busy = false;
      });
    }
  }

  String exportText(bool json) {
    final data = report?.toJson() ??
        {
          'application': 'GITHUB TEST BUTTON',
          'version': appVersion,
          'schema_version': '1.0',
          'checks': checks.map((e) => e.toJson()).toList()
        };
    if (repoResult != null) data['repository'] = repoResult!.toJson();
    if (writeResult != null) data['repository_write'] = writeResult!.toJson();
    return json
        ? const JsonEncoder.withIndent('  ').convert(data)
        : '${report?.text ?? 'GITHUB TEST BUTTON'}\n\n${repoResult?.message ?? ''}\n${writeResult?.message ?? ''}\n${const JsonEncoder.withIndent('  ').convert(data)}';
  }

  void message(BuildContext context, String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  Future<void> export(BuildContext context, bool json) async {
    try {
      final base = await getApplicationDocumentsDirectory();
      final dir =
          await Directory('${base.path}${Platform.pathSeparator}GTB-Reports')
              .create(recursive: true);
      final file = File(
          '${dir.path}${Platform.pathSeparator}gtb-${DateTime.now().millisecondsSinceEpoch}.${json ? 'json' : 'txt'}');
      await file.writeAsString(exportText(json));
      if (context.mounted) message(context, 'Saved: ${file.path}');
    } catch (e) {
      if (context.mounted) message(context, 'Export failed: ${e.runtimeType}');
    }
  }

  Future<void> openLink(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null ||
        uri.scheme != 'https' ||
        !(uri.host == 'github.com' || uri.host == 'www.githubstatus.com')) {
      return;
    }
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
          context.mounted) {
        message(context, 'Could not open browser.');
      }
    } catch (e) {
      if (context.mounted) {
        message(context, 'Could not open browser: ${e.runtimeType}');
      }
    }
  }

  Future<void> writeDialog(BuildContext context) async {
    var createNew = false;
    var accepted = false;
    final target = TextEditingController(text: repoController.text.trim());
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
            builder: (ctx, update) => AlertDialog(
                    title: Text(t('writeTitle')),
                    content: SizedBox(
                        width: 460,
                        child: SingleChildScrollView(
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                              Text(t('notice')),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<bool>(
                                  initialValue: false,
                                  items: [
                                    DropdownMenuItem(
                                        value: false,
                                        child: Text(t('existing'))),
                                    DropdownMenuItem(
                                        value: true, child: Text(t('new')))
                                  ],
                                  onChanged: (v) => update(() {
                                        createNew = v!;
                                        if (v) {
                                          target.text =
                                              '${diagnostics.account?['login'] ?? 'OWNER'}/GTB-VERIFY-${DateTime.now().toUtc().millisecondsSinceEpoch}';
                                        }
                                      })),
                              const SizedBox(height: 16),
                              TextField(
                                  controller: target,
                                  decoration: InputDecoration(
                                      labelText: t('target'),
                                      hintText: 'OWNER/REPOSITORY')),
                              CheckboxListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                      'I authorize writing to the exact target above.'),
                                  value: accepted,
                                  onChanged: (v) =>
                                      update(() => accepted = v!)),
                            ]))),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(t('cancel'))),
                      FilledButton(
                          onPressed:
                              accepted ? () => Navigator.pop(ctx, true) : null,
                          child: Text(t('confirm')))
                    ])));
    final repository = target.text.trim();
    target.dispose();
    if (confirmed != true || !mounted) return;
    setState(() {
      busy = true;
      progress = 'repository_write';
    });
    final result = await WriteTest(diagnostics).run(
        repository: repository,
        createNew: createNew,
        confirmed: true,
        onProgress: (s) {
          if (mounted) setState(() => progress = s);
        });
    if (mounted) {
      setState(() {
        writeResult = result;
        busy = false;
      });
    }
  }

  Color statusColor(String status) => switch (status) {
        'CONNECTED' => const Color(0xff25ba91),
        'NOT_TESTED' ||
        'UNSUPPORTED_ON_PLATFORM' ||
        'TOOL_NOT_INSTALLED' =>
          Colors.blueGrey,
        'UNAUTHENTICATED' ||
        'CONNECTED_WITH_LIMITATIONS' =>
          const Color(0xffd9a634),
        _ => const Color(0xffe46a75)
      };
  Widget statusPill(String status) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: statusColor(status).withValues(alpha: .12),
          borderRadius: BorderRadius.circular(9)),
      child: Text(status.replaceAll('_', ' '),
          style: TextStyle(
              color: statusColor(status),
              fontSize: 11,
              fontWeight: FontWeight.w700)));
  Widget section(String title, List<Widget> children) => Card(
      child: Padding(
          padding: const EdgeInsets.all(22),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ...children
          ])));
  Widget checkCard(Check check, {bool expanded = false}) => Card(
          child: ExpansionTile(
              initiallyExpanded: expanded,
              leading: Icon(
                  check.status == 'CONNECTED'
                      ? Icons.check_circle_outline
                      : check.status == 'NOT_TESTED'
                          ? Icons.radio_button_unchecked
                          : Icons.info_outline,
                  color: statusColor(check.status)),
              title: Text(check.id,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        statusPill(check.status),
                        Text('${check.durationMs} ms',
                            style: const TextStyle(fontSize: 12))
                      ])),
              children: [
            Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(check.message),
                      if (check.details.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        SelectableText(
                            const JsonEncoder.withIndent('  ')
                                .convert(check.toJson()['details']),
                            style: const TextStyle(
                                fontFamily: 'monospace', fontSize: 12))
                      ]
                    ]))
          ]));
  Widget dashboard(BuildContext context) {
    final account = diagnostics.account;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xff173c48), Color(0xff152c45)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(26)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('GITHUB TEST BUTTON',
                style: TextStyle(
                    color: Color(0xff7ceacb),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    fontSize: 12)),
            const SizedBox(height: 16),
            Text(t('ready'),
                style: const TextStyle(
                    fontSize: 34,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    height: 1.15)),
            const SizedBox(height: 10),
            Text(t('subtitle'),
                style: const TextStyle(color: Color(0xffbfd2dc), fontSize: 16)),
            const SizedBox(height: 26),
            SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                    key: const Key('test-button'),
                    onPressed: busy ? null : testConnection,
                    icon: busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.bolt, size: 28),
                    label: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(busy ? '${t('checking')}…' : t('test'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w800))),
                    style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xff7ceacb),
                        foregroundColor: const Color(0xff102e36),
                        disabledBackgroundColor: const Color(0xff365d65)))),
            const SizedBox(height: 13),
            Text(t('readOnly'),
                style: const TextStyle(color: Color(0xffbfd2dc), fontSize: 12)),
            if (busy) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(value: checks.length / 16),
              const SizedBox(height: 6),
              Text(progress, style: const TextStyle(color: Colors.white))
            ],
          ])),
      const SizedBox(height: 20),
      if (report != null)
        Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Wrap(
                spacing: 16,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  statusPill(report!.overall),
                  Text('${report!.durationMs} ms · ${report!.timestamp}')
                ])),
      section(t('account'), [
        Text(account?['login'] ?? t('public'),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(account != null
            ? 'GitHub CLI · ${account['public_repos']} public repositories'
            : diagnostics.mobile
                ? t('pending')
                : 'Authentication is not configured. Existing GitHub CLI authentication is detected when you run a test.'),
        if (account != null)
          TextButton.icon(
              onPressed: () => openLink(context, account['html_url']),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: Text(t('profile')))
      ]),
      const SizedBox(height: 8),
      if (checks.isEmpty)
        Padding(padding: const EdgeInsets.all(20), child: Text(t('empty')))
      else
        ...checks
            .where((c) =>
                !c.id.startsWith('dns.') &&
                c.id != 'network' &&
                c.id != 'repository_write')
            .map((c) => checkCard(c)),
      if (history.isNotEmpty)
        section(
            t('history'),
            history
                .map((h) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Wrap(spacing: 12, runSpacing: 5, children: [
                      statusPill(h['status']),
                      Text('${h['timestamp']} · ${h['duration_ms']} ms')
                    ])))
                .toList()),
    ]);
  }

  Widget repositories(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        section(t('repositories'), [
          TextField(
              key: const Key('repo-field'),
              controller: repoController,
              decoration: const InputDecoration(
                  labelText: 'OWNER/REPOSITORY', hintText: 'flutter/flutter'),
              onSubmitted: (_) {
                if (!busy) inspect();
              }),
          const SizedBox(height: 16),
          FilledButton.icon(
              onPressed: busy ? null : inspect,
              icon: const Icon(Icons.search),
              label: Text(t('inspect'))),
          const SizedBox(height: 16),
          Text(t('permission'))
        ]),
        if (repoResult != null) ...[
          checkCard(repoResult!, expanded: true),
          if (repoResult!.details['html_url'] != null)
            TextButton.icon(
                onPressed: () =>
                    openLink(context, repoResult!.details['html_url']),
                icon: const Icon(Icons.open_in_new),
                label: Text(t('repository')))
        ],
        const SizedBox(height: 20),
        section(t('write'), [
          Text(t('notice')),
          const SizedBox(height: 14),
          OutlinedButton.icon(
              onPressed: busy || diagnostics.mobile
                  ? null
                  : () => writeDialog(context),
              icon: const Icon(Icons.edit_note),
              label: Text(t('write'))),
          if (diagnostics.mobile)
            const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text(
                    'UNSUPPORTED ON PLATFORM · Git push verification requires desktop Git and GitHub CLI.')),
          if (busy)
            Padding(
                padding: const EdgeInsets.only(top: 10), child: Text(progress))
        ]),
        if (writeResult != null) checkCard(writeResult!, expanded: true)
      ]);
  Widget advanced(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        section(t('advanced'), [
          const Text(
              'Reports contain measured results and sanitized technical details. Account names, local tool paths and repository names can still be personal information.'),
          const SizedBox(height: 16),
          Wrap(spacing: 10, runSpacing: 10, children: [
            OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: exportText(true)));
                  message(context, 'Report copied');
                },
                icon: const Icon(Icons.copy),
                label: Text(t('copy'))),
            FilledButton.tonal(
                onPressed: () => export(context, true), child: Text(t('json'))),
            FilledButton.tonal(
                onPressed: () => export(context, false), child: Text(t('txt'))),
            if (Platform.isAndroid)
              FilledButton.tonal(
                  onPressed: () async {
                    try {
                      await const MethodChannel('dev.gtb/share')
                          .invokeMethod('share', {'text': exportText(true)});
                    } catch (e) {
                      if (context.mounted) {
                        message(
                            context, 'Sharing unavailable: ${e.runtimeType}');
                      }
                    }
                  },
                  child: Text(t('share')))
          ]),
          const SizedBox(height: 12),
          const Text(
              'Green: verified operation · Yellow: limitation · Red: failure · Gray: not tested or not applicable',
              style: TextStyle(fontSize: 12))
        ]),
        ...checks.map((c) => checkCard(c)),
        if (repoResult != null) checkCard(repoResult!),
        if (writeResult != null) checkCard(writeResult!)
      ]);
  Widget settings(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        section(t('settings'), [
          DropdownButtonFormField<String>(
              key: const Key('language'),
              initialValue: language,
              decoration: InputDecoration(labelText: t('language')),
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'ro', child: Text('Română')),
                DropdownMenuItem(value: 'de', child: Text('Deutsch'))
              ],
              onChanged: (v) {
                setState(() => language = v!);
                save();
              }),
          const SizedBox(height: 24),
          Text(t('theme')),
          const SizedBox(height: 10),
          Wrap(
              spacing: 8,
              children: ThemeMode.values
                  .map((m) => ChoiceChip(
                      label: Text(t(m.name)),
                      selected: mode == m,
                      onSelected: (_) {
                        setState(() => mode = m);
                        save();
                      }))
                  .toList()),
          const SizedBox(height: 24),
          Text('${t('font')} · ${(fontScale * 100).round()}%'),
          Slider(
              value: fontScale,
              min: .85,
              max: 1.3,
              divisions: 9,
              onChanged: (v) {
                setState(() => fontScale = v);
                save();
              }),
          const SizedBox(height: 20),
          TextField(
              controller: publicController,
              decoration: InputDecoration(labelText: t('scope')),
              onChanged: (_) => save()),
          const SizedBox(height: 24),
          const Text(
              'GTB 0.1.0-beta.1 · Contract 1.0\nNo account is needed to change these settings.\nMobile sign-in is pending. No credentials are stored by GTB.'),
        ]),
      ]);
  @override
  Widget build(BuildContext context) {
    ThemeData theme(Brightness b) => ThemeData(
        useMaterial3: true,
        brightness: b,
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xff157e70), brightness: b),
        scaffoldBackgroundColor: b == Brightness.dark
            ? const Color(0xff0d1620)
            : const Color(0xfff3f6f8),
        cardTheme: CardThemeData(
            elevation: 0,
            color:
                b == Brightness.dark ? const Color(0xff17232f) : Colors.white,
            margin: const EdgeInsets.symmetric(vertical: 5),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18))),
        inputDecorationTheme: InputDecorationTheme(
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
        filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)))));
    return MaterialApp(
        title: 'GITHUB TEST BUTTON',
        debugShowCheckedModeBanner: false,
        theme: theme(Brightness.light),
        darkTheme: theme(Brightness.dark),
        themeMode: mode,
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(fontScale)),
            child: child!),
        home: Builder(
            builder: (context) =>
                LayoutBuilder(builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 850;
                  final labels = [
                    t('dashboard'),
                    t('repositories'),
                    t('advanced'),
                    t('settings')
                  ];
                  const icons = [
                    Icons.bolt,
                    Icons.folder_outlined,
                    Icons.analytics_outlined,
                    Icons.tune
                  ];
                  final content = SafeArea(
                      child: SingleChildScrollView(
                          key: ValueKey(page),
                          padding: EdgeInsets.all(wide ? 28 : 16),
                          child: Center(
                              child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 1040),
                                  child: switch (page) {
                                    0 => dashboard(context),
                                    1 => repositories(context),
                                    2 => advanced(context),
                                    _ => settings(context)
                                  }))));
                  return Scaffold(
                      appBar: AppBar(
                          title: const FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Row(children: [
                                Icon(Icons.hub_outlined,
                                    color: Color(0xff25ba91)),
                                SizedBox(width: 12),
                                Text('GTB',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 3)),
                                SizedBox(width: 10),
                                Text(' /  GITHUB TEST BUTTON',
                                    style: TextStyle(
                                        fontSize: 10, letterSpacing: 1))
                              ])),
                          actions: [
                            Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: Center(
                                    child: Text('BETA 01',
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .outline))))
                          ]),
                      body: wide
                          ? Row(children: [
                              NavigationRail(
                                  selectedIndex: page,
                                  onDestinationSelected: (i) =>
                                      setState(() => page = i),
                                  labelType: NavigationRailLabelType.all,
                                  destinations: List.generate(
                                      4,
                                      (i) => NavigationRailDestination(
                                          icon: Icon(icons[i]),
                                          label: Text(labels[i])))),
                              const VerticalDivider(width: 1),
                              Expanded(child: content)
                            ])
                          : content,
                      bottomNavigationBar: wide
                          ? null
                          : NavigationBar(
                              selectedIndex: page,
                              onDestinationSelected: (i) =>
                                  setState(() => page = i),
                              destinations: List.generate(
                                  4,
                                  (i) => NavigationDestination(
                                      icon: Icon(icons[i]),
                                      label: labels[i]))));
                })));
  }
}
