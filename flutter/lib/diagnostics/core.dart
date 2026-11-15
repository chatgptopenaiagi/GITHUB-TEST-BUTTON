import 'dart:async';
import 'dart:convert';
import 'dart:io';

const appVersion = '0.1.0-beta.1';
String classifyHttp(int code, Map<String, String> headers, [String body = ""]) {
  final h = headers.map((k, v) => MapEntry(k.toLowerCase(), v));
  if (code >= 200 && code < 300) return 'CONNECTED';
  if (code == 401) return 'AUTHENTICATION_EXPIRED';
  if (code == 429 ||
      (code == 403 &&
          (h['x-ratelimit-remaining'] == '0' ||
              h.containsKey('retry-after') ||
              body.toLowerCase().contains('rate limit')))) {
    return 'RATE_LIMITED';
  }
  if (code == 403 || code == 404) return 'ACCESS_DENIED';
  if (code >= 500) return 'API_UNAVAILABLE';
  return 'UNKNOWN_ERROR';
}

String classifyErrorKind(String kind) =>
    const {
      'dns': 'DNS_FAILURE',
      'tls': 'TLS_FAILURE',
      'timeout': 'TIMEOUT',
      'network': 'NETWORK_UNAVAILABLE',
      'malformed': 'API_UNAVAILABLE'
    }[kind] ??
    'UNKNOWN_ERROR';
String errorStatus(Object error, {bool dns = false}) {
  if (error is TimeoutException) return 'TIMEOUT';
  if (error is HandshakeException || error is TlsException) {
    return 'TLS_FAILURE';
  }
  if (error is SocketException) {
    return dns ? 'DNS_FAILURE' : 'NETWORK_UNAVAILABLE';
  }
  if (error is FormatException) return 'API_UNAVAILABLE';
  if (error is ProcessException) return 'TOOL_NOT_INSTALLED';
  return 'UNKNOWN_ERROR';
}

String redact(String value) => value
    .replaceAll(
        RegExp(r'(?:gh[pousr]_|github_pat_)[A-Za-z0-9_]+'), '[REDACTED]')
    .replaceAll(RegExp(r'(?:https?|ssh)://[^\s/@]+@'), 'https://[REDACTED]@')
    .replaceAll(
        RegExp(r'authorization\s*[:=]\s*[^\r\n]+', caseSensitive: false),
        'authorization: [REDACTED]')
    .replaceAll(
        RegExp(r'[?&](?:access_token|token|password|client_secret)=[^&\s]+',
            caseSensitive: false),
        '?secret=[REDACTED]');

class AuthenticationUnavailable implements Exception {
  const AuthenticationUnavailable();
}

dynamic sanitize(dynamic value) {
  if (value is Map) {
    return value.map((key, item) => MapEntry(
        key.toString(),
        RegExp(r'^(authorization|token|access_token|password|client_secret|cookie|private_key)$',
                    caseSensitive: false)
                .hasMatch(key.toString())
            ? '[REDACTED]'
            : sanitize(item)));
  }
  if (value is List) return value.map(sanitize).toList();
  if (value is String) return redact(value);
  return value;
}

class Check {
  final String id, status, message;
  final int durationMs;
  final Map<String, dynamic> details;
  const Check(this.id, this.status, this.message,
      {this.durationMs = 0, this.details = const {}});
  Map<String, dynamic> toJson() => {
        'id': id,
        'status': status,
        'message': redact(message),
        'duration_ms': durationMs,
        'details': sanitize(details)
      };
  factory Check.fromJson(Map<String, dynamic> j) =>
      Check(j['id'], j['status'], j['message'],
          durationMs: (j['duration_ms'] as num?)?.round() ?? 0,
          details: Map<String, dynamic>.from(j['details'] ?? {}));
}

class DiagnosticReport {
  final List<Check> checks;
  final String timestamp, platform;
  final int durationMs;
  final Map<String, dynamic>? account;
  DiagnosticReport(this.checks,
      {required this.timestamp,
      required this.platform,
      required this.durationMs,
      this.account});
  Map<String, dynamic> toJson() => {
        'application': 'GITHUB TEST BUTTON',
        'version': appVersion,
        'schema_version': '1.0',
        'platform': platform,
        'timestamp': timestamp,
        'duration_ms': durationMs,
        'checks': checks.map((e) => e.toJson()).toList(),
        'account': sanitize(account),
        'overall': overall,
        'repository_write': {'status': 'NOT_TESTED'}
      };
  String get json => const JsonEncoder.withIndent('  ').convert(toJson());
  String get text =>
      'GITHUB TEST BUTTON $appVersion\n$timestamp · $platform · ${durationMs}ms\n\n${checks.map((c) => '${c.id}: ${c.status}\n${redact(c.message)}\n${jsonEncode(c.toJson()['details'])}').join('\n\n')}';
  String get overall {
    final mandatory = checks.where((c) =>
        c.id == 'github.api' ||
        c.id == 'github.https' ||
        c.id == 'dns.github.com');
    if (mandatory.isEmpty) return 'NOT_TESTED';
    final failures = mandatory.where((c) => c.status != 'CONNECTED');
    if (failures.isNotEmpty) return failures.first.status;
    return checks
            .any((c) => c.id == 'github.service' && c.status != 'CONNECTED')
        ? 'CONNECTED_WITH_LIMITATIONS'
        : 'CONNECTED';
  }
}

class ApiResponse {
  final int code;
  final Map<String, String> headers;
  final dynamic data;
  const ApiResponse(this.code, this.headers, this.data);
  String get status => classifyHttp(
      code, headers, data is Map ? (data["message"] ?? "").toString() : "");
}

typedef Requester = Future<ApiResponse> Function(Uri uri, bool expectJson);
typedef Resolver = Future<List<String>> Function(String host);

class Diagnostics {
  final Duration timeout;
  final Requester? requester;
  final Resolver? resolver;
  final bool mobile;
  Map<String, dynamic>? account;
  Diagnostics(
      {this.timeout = const Duration(seconds: 10),
      this.requester,
      this.resolver,
      bool? mobile})
      : mobile = mobile ?? (Platform.isAndroid || Platform.isIOS);
  Future<ApiResponse> request(Uri uri, {bool expectJson = true}) async {
    if (requester != null) return requester!(uri, expectJson);
    for (var attempt = 0; attempt < 2; attempt++) {
      final client = HttpClient()
        ..connectionTimeout = timeout
        ..userAgent = 'GITHUB-TEST-BUTTON/$appVersion';
      try {
        final response = await (() async {
          final req = await client.getUrl(uri);
          req.followRedirects = false;
          if (uri.host == 'api.github.com') {
            req.headers.set('Accept', 'application/vnd.github+json');
            req.headers.set('X-GitHub-Api-Version', '2022-11-28');
          }
          final res = await req.close();
          final headers = <String, String>{};
          res.headers.forEach((k, v) {
            if (k.startsWith('x-ratelimit-') ||
                k == 'retry-after' ||
                k == 'content-type') {
              headers[k] = v.join(',');
            }
          });
          if (!expectJson) {
            await res.drain<void>();
            return ApiResponse(res.statusCode, headers, null);
          }
          final bytes = <int>[];
          await for (final chunk in res) {
            bytes.addAll(chunk);
            if (bytes.length > 2 * 1024 * 1024) {
              throw const FormatException('Response exceeds safe size');
            }
          }
          dynamic body;
          try {
            body = jsonDecode(utf8.decode(bytes));
          } on FormatException {
            if (res.statusCode >= 200 && res.statusCode < 300) rethrow;
          }
          return ApiResponse(res.statusCode, headers, body);
        })()
            .timeout(timeout);
        if (response.code >= 500 && attempt == 0) continue;
        return response;
      } on TimeoutException {
        if (attempt == 1) rethrow;
      } finally {
        client.close(force: true);
      }
    }
    throw TimeoutException('Request timed out');
  }

  Future<ProcessResult> command(String exe, List<String> args,
      {String? directory}) async {
    final p = await Process.start(exe, args,
        workingDirectory: directory,
        runInShell: false,
        environment: {
          'GIT_TERMINAL_PROMPT': '0',
          'GH_PROMPT_DISABLED': '1',
          'GH_HOST': 'github.com'
        });
    final out = p.stdout.transform(utf8.decoder).join();
    final err = p.stderr.transform(utf8.decoder).join();
    try {
      final code = await p.exitCode.timeout(const Duration(seconds: 30));
      return ProcessResult(p.pid, code, await out, await err);
    } on TimeoutException {
      p.kill();
      rethrow;
    }
  }

  Future<ApiResponse> ghApi(String path) async {
    final r = await command(
        'gh', ['api', '--hostname', 'github.com', '--include', path]);
    final raw = r.stdout.toString().replaceAll('\r\n', '\n');
    final split = raw.indexOf('\n\n');
    if (split < 0) {
      if (r.exitCode != 0) {
        final error = r.stderr.toString().toLowerCase();
        if (error.contains('not logged') || error.contains('gh auth login')) {
          throw const AuthenticationUnavailable();
        }
        if (error.contains('timeout') || error.contains('deadline exceeded')) {
          throw TimeoutException('GitHub CLI timeout');
        }
        if (error.contains('certificate') || error.contains('tls')) {
          throw const HandshakeException('GitHub CLI TLS failure');
        }
        if (error.contains('connect') ||
            error.contains('no such host') ||
            error.contains('network')) {
          throw const SocketException('GitHub CLI network failure');
        }
        throw StateError('GitHub CLI request failed without HTTP response');
      }
      throw const FormatException('Missing API response');
    }
    final lines = raw.substring(0, split).split('\n');
    final code =
        int.tryParse(lines.first.split(' ').elementAtOrNull(1) ?? '') ?? 500;
    final headers = <String, String>{};
    for (final line in lines.skip(1)) {
      final i = line.indexOf(':');
      if (i > 0) {
        final key = line.substring(0, i).toLowerCase();
        if (key.startsWith('x-ratelimit-') || key == 'retry-after') {
          headers[key] = line.substring(i + 1).trim();
        }
      }
    }
    return ApiResponse(code, headers, jsonDecode(raw.substring(split + 2)));
  }

  Future<Check> authentication() async {
    if (mobile) {
      return const Check('authentication', 'UNAUTHENTICATED',
          'Public diagnostics available. Mobile sign-in awaits a registered OAuth application and secure exchange service. No PC credentials are used.');
    }
    try {
      final res = await ghApi('user');
      if (res.status == 'CONNECTED' &&
          res.data is Map &&
          res.data['login'] is String) {
        account = {
          for (final k in ['login', 'html_url', 'avatar_url', 'public_repos'])
            k: res.data[k],
          'provider': 'GitHub CLI'
        };
        return Check('authentication', 'CONNECTED',
            'Authenticated as ${account!['login']}', details: {
          ...account!,
          'http_status': res.code,
          'rate_limit': res.headers
        });
      }
      final status =
          await command('gh', ['auth', 'status', '--hostname', 'github.com']);
      final absent = status.stderr.toString().contains('not logged into') ||
          status.stderr.toString().contains('not logged in');
      return Check(
          'authentication',
          absent ? 'UNAUTHENTICATED' : res.status,
          absent
              ? 'Public access is available. Run gh auth login to configure authentication.'
              : 'GitHub CLI authentication could not be verified.',
          details: {'http_status': res.code});
    } on AuthenticationUnavailable {
      return const Check('authentication', 'UNAUTHENTICATED',
          'GitHub CLI sign-in is not configured. Public diagnostics remain available.');
    } on ProcessException {
      return const Check('authentication', 'UNAUTHENTICATED',
          'GitHub CLI not installed. Public diagnostics remain available.');
    } catch (e) {
      return Check('authentication', errorStatus(e),
          'Authentication probe failed: ${e.runtimeType}');
    }
  }

  Future<Check> tool(String name) async {
    if (mobile) {
      return Check('tool.$name', 'UNSUPPORTED_ON_PLATFORM',
          'Not required for Android public diagnostics.');
    }
    final watch = Stopwatch()..start();
    try {
      final r = await command(name, ['--version']);
      var path = name;
      try {
        final location =
            await command(Platform.isWindows ? 'where.exe' : 'which', [name]);
        if (location.exitCode == 0) {
          path = location.stdout.toString().trim().split('\n').first.trim();
        }
      } catch (_) {}
      return Check(
          'tool.$name',
          r.exitCode == 0 ? 'CONNECTED' : 'CONNECTED_WITH_LIMITATIONS',
          r.exitCode == 0
              ? r.stdout.toString().trim().split('\n').first
              : 'Executable found but version check failed.',
          durationMs: watch.elapsedMilliseconds,
          details: {
            'path': path,
            'version_verified': r.exitCode == 0,
            'repository_operations_verified': false
          });
    } on AuthenticationUnavailable {
      return const Check('authentication', 'UNAUTHENTICATED',
          'GitHub CLI sign-in is not configured. Public diagnostics remain available.');
    } on ProcessException {
      return Check('tool.$name', 'TOOL_NOT_INSTALLED',
          'Optional tool is not installed.');
    } catch (e) {
      return Check(
          'tool.$name', errorStatus(e), 'Tool probe failed: ${e.runtimeType}');
    }
  }

  Future<DiagnosticReport> run(
      {String publicAccount = 'octocat',
      void Function(Check)? onCheck,
      void Function(String)? onProgress}) async {
    account = null;
    final watch = Stopwatch()..start();
    final checks = <Check>[];
    void add(Check c) {
      checks.add(c);
      onCheck?.call(c);
    }

    onProgress?.call('network');
    try {
      final interfaces = await NetworkInterface.list().timeout(timeout);
      add(Check(
          'network',
          interfaces.isEmpty
              ? 'NETWORK_UNAVAILABLE'
              : 'CONNECTED_WITH_LIMITATIONS',
          interfaces.isEmpty
              ? 'No active network interface was detected.'
              : 'Network interface detected; internet reachability is tested separately.',
          details: {'interface_count': interfaces.length}));
    } catch (e) {
      add(Check('network', errorStatus(e),
          'Interface inspection unavailable; HTTPS probes still run.'));
    }
    for (final host in [
      'github.com',
      'api.github.com',
      'www.githubstatus.com'
    ]) {
      final id = 'dns.$host';
      onProgress?.call(id);
      final step = Stopwatch()..start();
      try {
        final addresses = await (resolver != null
                ? resolver!(host)
                : InternetAddress.lookup(host)
                    .then((l) => l.map((a) => a.address).toList()))
            .timeout(timeout);
        add(Check(id, addresses.isEmpty ? 'DNS_FAILURE' : 'CONNECTED',
            addresses.isEmpty ? 'No DNS answers.' : 'Host resolved.',
            durationMs: step.elapsedMilliseconds,
            details: {'addresses': addresses}));
      } catch (e) {
        add(Check(id, errorStatus(e, dns: true),
            'DNS lookup failed: ${e.runtimeType}',
            durationMs: step.elapsedMilliseconds));
      }
    }
    final targets = {
      'github.https': 'https://github.com',
      'github.api': 'https://api.github.com',
      'github.public_account':
          'https://api.github.com/users/${Uri.encodeComponent(publicAccount)}',
      'github.service': 'https://www.githubstatus.com/api/v2/summary.json',
      'github.rate_limit': 'https://api.github.com/rate_limit'
    };
    for (final target in targets.entries) {
      onProgress?.call(target.key);
      final step = Stopwatch()..start();
      try {
        final res = await request(Uri.parse(target.value),
            expectJson: target.key != 'github.https');
        var status = res.status;
        final details = <String, dynamic>{
          'url': target.value,
          'http_status': res.code,
          'headers': res.headers,
          'retrieved_at': DateTime.now().toUtc().toIso8601String()
        };
        var message = 'HTTPS response ${res.code}';
        if (status == 'CONNECTED') {
          if (target.key != 'github.https' && res.data is! Map) {
            throw const FormatException('Expected JSON object');
          }
          if (target.key == 'github.service') {
            final service = res.data['status'];
            if (service is! Map || service['indicator'] is! String) {
              throw const FormatException('Missing service status');
            }
            details['published_status'] = service;
            details['incidents'] = (res.data['incidents'] as List? ?? [])
                .map((e) => {
                      'name': e['name'],
                      'status': e['status'],
                      'shortlink': e['shortlink']
                    })
                .toList();
            details['components'] = (res.data['components'] as List? ?? [])
                .map((e) => {'name': e['name'], 'status': e['status']})
                .toList();
            if (service['indicator'] != 'none') {
              status = 'CONNECTED_WITH_LIMITATIONS';
            }
            message =
                'Published GitHub service status: ${service['description']}. Independent of your connection.';
          } else if (target.key == 'github.public_account') {
            if (res.data['login'] is! String) {
              throw const FormatException('Missing login');
            }
            details['login'] = res.data['login'];
            message =
                'Public profile ${res.data['login']} is accessible; this does not authenticate you.';
          } else if (target.key == 'github.rate_limit') {
            if (res.data['rate'] is! Map) {
              throw const FormatException('Missing rate limit');
            }
            details['rate'] = res.data['rate'];
            message =
                'Public API rate limit retrieved. Authenticated limits appear in the account check.';
            if (res.data['rate']['remaining'] == 0) status = 'RATE_LIMITED';
          } else if (target.key == 'github.api' &&
              res.data['current_user_url'] is! String) {
            throw const FormatException('Missing API root fields');
          }
        }
        add(Check(target.key, status, message,
            durationMs: step.elapsedMilliseconds, details: details));
      } catch (e) {
        add(Check(
            target.key, errorStatus(e), 'Request failed: ${e.runtimeType}',
            durationMs: step.elapsedMilliseconds));
      }
    }
    onProgress?.call('authentication');
    add(await authentication());
    for (final name in ['git', 'gh', 'codex', 'pwsh']) {
      onProgress?.call('tool.$name');
      add(await tool(name));
    }
    add(const Check('repository_write', 'NOT_TESTED',
        'Read-only diagnostics never create repositories or push commits.'));
    return DiagnosticReport(checks,
        timestamp: DateTime.now().toUtc().toIso8601String(),
        platform: Platform.operatingSystem,
        durationMs: watch.elapsedMilliseconds,
        account: account);
  }

  Future<Check> repository(String name) async {
    if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9-]{0,38}/[A-Za-z0-9_.-]{1,100}$')
            .hasMatch(name) ||
        [".", ".."].contains(name.split("/").last)) {
      return const Check('repository', 'UNKNOWN_ERROR',
          'Enter OWNER/REPOSITORY using valid GitHub names.');
    }
    final watch = Stopwatch()..start();
    Future<ApiResponse> get(String path) => account != null && !mobile
        ? ghApi(path)
        : request(Uri.parse('https://api.github.com/$path'));
    try {
      final res = await get('repos/$name');
      if (res.status != 'CONNECTED') {
        return Check(
            'repository',
            res.status,
            res.code == 404
                ? 'Repository absent or inaccessible to the current identity. A private repository may exist.'
                : 'Repository request returned HTTP ${res.code}.',
            details: {'http_status': res.code},
            durationMs: watch.elapsedMilliseconds);
      }
      if (res.data is! Map || res.data['full_name'] is! String) {
        throw const FormatException('Invalid repository response');
      }
      final details = <String, dynamic>{
        for (final k in [
          'full_name',
          'description',
          'html_url',
          'clone_url',
          'visibility',
          'private',
          'default_branch',
          'permissions'
        ])
          k: res.data[k],
        'read_verified': true,
        'write_verified': false
      };
      for (final endpoint in {
        'files': 'contents',
        'latest_commit': 'commits?per_page=1',
        'releases': 'releases?per_page=5'
      }.entries) {
        final sub = await get('repos/$name/${endpoint.value}');
        details['${endpoint.key}_status'] = sub.status;
        if (sub.data is List && sub.status == 'CONNECTED') {
          details[endpoint.key] = (sub.data as List)
              .take(20)
              .map((e) => endpoint.key == 'files'
                  ? {'name': e['name'], 'type': e['type']}
                  : endpoint.key == 'releases'
                      ? {'tag_name': e['tag_name'], 'html_url': e['html_url']}
                      : {'sha': e['sha'], 'html_url': e['html_url']})
              .toList();
        }
      }
      return Check('repository', 'CONNECTED',
          'Repository metadata read successfully. Advertised permissions are not write verification.',
          durationMs: watch.elapsedMilliseconds, details: details);
    } catch (e) {
      return Check('repository', errorStatus(e),
          'Repository inspection failed: ${e.runtimeType}',
          durationMs: watch.elapsedMilliseconds);
    }
  }
}
