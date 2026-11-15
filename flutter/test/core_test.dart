import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_test_button/diagnostics/core.dart';
import 'package:github_test_button/diagnostics/write_test.dart';

void main() {
  final vectors =
      jsonDecode(File('../contracts/test-vectors.json').readAsStringSync())
          as Map;
  for (final v in vectors['http']) {
    test('HTTP contract ${v['code']} ${v['headers']}', () {
      expect(
          classifyHttp(v['code'], Map<String, String>.from(v['headers']),
              v['body'] ?? ''),
          v['expected']);
    });
  }
  for (final v in vectors['errors']) {
    test('Error contract ${v['kind']}', () {
      expect(classifyErrorKind(v['kind']), v['expected']);
    });
  }
  test('secondary rate limit body', () {
    expect(
        const ApiResponse(403, {},
            {'message': 'You have exceeded a secondary rate limit'}).status,
        'RATE_LIMITED');
  });
  test('recursive secret redaction preserves JSON', () {
    final c =
        Check('safe', 'CONNECTED', 'authorization: Bearer secret', details: {
      'Authorization': 'Bearer private',
      'nested': [
        {'token': 'abc', 'url': 'https://secret@github.com/o/r'}
      ],
      'remote': 'https://user:password@github.com/o/r',
      'pat': 'github_pat_abcdefg'
    });
    final raw = jsonEncode(c.toJson());
    expect(raw, isNot(contains('private')));
    expect(raw, isNot(contains('password')));
    expect(raw, isNot(contains('abcdefg')));
    expect(raw, isNot(contains('secret@')));
    expect(jsonDecode(raw)['details']['Authorization'], '[REDACTED]');
  });
  test('timeout TLS DNS classification', () {
    expect(errorStatus(TimeoutException('x')), 'TIMEOUT');
    expect(errorStatus(const HandshakeException()), 'TLS_FAILURE');
    expect(errorStatus(const SocketException('x'), dns: true), 'DNS_FAILURE');
    expect(errorStatus(const SocketException('x')), 'NETWORK_UNAVAILABLE');
    expect(errorStatus(const FormatException()), 'API_UNAVAILABLE');
  });
  test('write test requires confirmation without side effects', () async {
    final result = await WriteTest(Diagnostics())
        .run(repository: 'user/repo', createNew: true, confirmed: false);
    expect(result.status, 'NOT_TESTED');
  });
  test('write state prerequisites enforced', () {
    final engine = WriteTest(Diagnostics());
    expect(() => engine.transition('COMMIT_CREATED', 'REMOTE_READY'),
        throwsStateError);
    expect(engine.state, 'NOT_INITIALIZED');
  });
  test('mobile git writes unsupported', () async {
    expect(
        (await WriteTest(Diagnostics(mobile: true)).run(
                repository: 'user/repo', createNew: false, confirmed: true))
            .status,
        'UNSUPPORTED_ON_PLATFORM');
  });
  test('mobile missing tools never become connectivity failure', () async {
    expect((await Diagnostics(mobile: true).tool('git')).status,
        'UNSUPPORTED_ON_PLATFORM');
    expect((await Diagnostics(mobile: true).authentication()).status,
        'UNAUTHENTICATED');
  });
  test('private repository 404 remains uncertain', () async {
    final d = Diagnostics(
        mobile: true,
        requester: (uri, json) async => const ApiResponse(404, {}, {}));
    final r = await d.repository('owner/private');
    expect(r.status, 'ACCESS_DENIED');
    expect(r.message, contains('may exist'));
  });
  test('repo rejects path traversal', () async {
    expect(
        (await Diagnostics().repository('owner/..')).status, 'UNKNOWN_ERROR');
  });
  test('read-only suite progress and genuine status rules', () async {
    final ids = <String>[];
    final d = Diagnostics(
        mobile: true,
        resolver: (host) async => ['127.0.0.1'],
        requester: (uri, json) async {
          if (uri.host == 'github.com') return const ApiResponse(200, {}, null);
          if (uri.path.contains('summary')) {
            return const ApiResponse(200, {}, {
              'status': {'indicator': 'minor', 'description': 'Minor incident'},
              'incidents': [],
              'components': []
            });
          }
          if (uri.path.contains('rate_limit')) {
            return const ApiResponse(200, {}, {
              'rate': {'remaining': 40}
            });
          }
          if (uri.path.contains('users')) {
            return const ApiResponse(200, {}, {'login': 'octocat'});
          }
          return const ApiResponse(
              200, {}, {'current_user_url': 'https://api.github.com/user'});
        });
    final report = await d.run(onProgress: ids.add);
    expect(report.overall, 'CONNECTED_WITH_LIMITATIONS');
    expect(report.toJson()['repository_write']['status'], 'NOT_TESTED');
    expect(ids, contains('github.api'));
    expect(report.checks.where((c) => c.id == 'authentication').single.status,
        'UNAUTHENTICATED');
  });
  test('DNS failure is not silently connected', () async {
    final d = Diagnostics(
        mobile: true,
        resolver: (host) async => throw const SocketException('dns'),
        requester: (uri, json) async => const ApiResponse(503, {}, {}));
    final report = await d.run();
    expect(report.overall, 'DNS_FAILURE');
    expect(report.checks.firstWhere((c) => c.id == 'github.api').status,
        'API_UNAVAILABLE');
  });
  test('malformed account shape fails rather than passes', () async {
    final d = Diagnostics(
        mobile: true,
        resolver: (host) async => ['1.1.1.1'],
        requester: (uri, json) async => const ApiResponse(200, {}, {}));
    final report = await d.run();
    expect(
        report.checks.firstWhere((c) => c.id == 'github.public_account').status,
        'API_UNAVAILABLE');
  });
  group('controlled local HTTP server', () {
    late HttpServer server;
    late Diagnostics d;
    var requests = 0;
    setUp(() async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      d = Diagnostics(timeout: const Duration(milliseconds: 150));
      requests = 0;
    });
    tearDown(() async {
      await server.close(force: true);
    });
    Uri url() => Uri.parse('http://127.0.0.1:${server.port}/test');
    test('successful JSON response', () async {
      server.listen((r) {
        r.response.headers.set('content-type', 'application/json');
        r.response.write('{"ok":true}');
        r.response.close();
      });
      final response = await d.request(url());
      expect(response.data['ok'], true);
      expect(response.status, 'CONNECTED');
    });
    test('malformed JSON response', () async {
      server.listen((r) {
        r.response.write('not json');
        r.response.close();
      });
      expect(() => d.request(url()), throwsFormatException);
    });
    test('authorization errors never retried', () async {
      server.listen((r) {
        requests++;
        r.response.statusCode = 401;
        r.response.write('{}');
        r.response.close();
      });
      expect((await d.request(url())).status, 'AUTHENTICATION_EXPIRED');
      expect(requests, 1);
    });
    test('rate limits never retried', () async {
      server.listen((r) {
        requests++;
        r.response.statusCode = 403;
        r.response.headers.set('x-ratelimit-remaining', '0');
        r.response.write('{}');
        r.response.close();
      });
      expect((await d.request(url())).status, 'RATE_LIMITED');
      expect(requests, 1);
    });
    test('server failures bounded to one retry', () async {
      server.listen((r) {
        requests++;
        r.response.statusCode = 503;
        r.response.write('{}');
        r.response.close();
      });
      expect((await d.request(url())).status, 'API_UNAVAILABLE');
      expect(requests, 2);
    });
    test('timeouts bounded to one retry', () async {
      server.listen((r) {
        requests++;
      });
      await expectLater(d.request(url()), throwsA(isA<TimeoutException>()));
      expect(requests, 2);
    });
  });
}
