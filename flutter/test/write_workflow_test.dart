import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_test_button/diagnostics/core.dart';
import 'package:github_test_button/diagnostics/write_test.dart';

class FakeWriteDiagnostics extends Diagnostics {
  String? localPath;
  final String failure;
  int creates = 0;
  final List<List<String>> invocations = [];
  FakeWriteDiagnostics(this.failure) : super(mobile: false);
  @override
  Future<Check> authentication() async {
    account = {'login': 'owner'};
    return const Check('authentication', 'CONNECTED', 'mock authenticated');
  }

  @override
  Future<ProcessResult> command(String exe, List<String> args,
      {String? directory}) async {
    localPath = directory;
    invocations.add([exe, ...args]);
    if (args.contains('create')) creates++;
    if ((failure == 'commit' && args.contains('commit')) ||
        (failure == 'push' && args.contains('push'))) {
      return ProcessResult(0, 1, '', 'failure ghp_privateSecretExample');
    }
    return ProcessResult(0, 0, args.contains('rev-parse') ? 'abc123' : '', '');
  }

  @override
  Future<ApiResponse> ghApi(String path) async {
    if (path.contains('/contents/')) {
      final content =
          await File('$localPath${Platform.pathSeparator}GTB-VERIFY.txt')
              .readAsString();
      return ApiResponse(200, {}, {
        'encoding': 'base64',
        'content': base64
            .encode(utf8.encode(failure == 'mismatch' ? 'wrong' : content))
      });
    }
    if (path.contains('/commits/')) {
      return ApiResponse(
          200, {}, {'sha': failure == 'sha' ? 'wrong' : 'abc123'});
    }
    return const ApiResponse(200, {}, {
      'permissions': {'push': true}
    });
  }

  Future<void> cleanup() async {
    final path = localPath;
    if (path != null) {
      final normalized = Directory(path).absolute.path;
      final temp = Directory.systemTemp.absolute.path;
      if (!normalized.startsWith(temp) || !normalized.contains('gtb-write-')) {
        throw StateError('Unsafe test cleanup');
      }
      await Directory(path).delete(recursive: true);
    }
  }
}

void main() {
  for (final failure in ['', 'commit', 'push', 'mismatch', 'sha']) {
    test('write workflow ${failure.isEmpty ? 'successful readback' : failure}',
        () async {
      final d = FakeWriteDiagnostics(failure);
      addTearDown(d.cleanup);
      final r = await WriteTest(d)
          .run(repository: 'owner/repo', createNew: false, confirmed: true);
      expect(d.creates, 0);
      if (failure.isEmpty) {
        expect(r.status, 'CONNECTED');
        expect(r.details['state'], 'REMOTE_VERIFIED');
        expect(r.details['commit'], 'abc123');
        expect(d.invocations.where((v) => v.contains('push')).single.last,
            startsWith('HEAD:refs/heads/gtb-verify-'));
      }
      if (failure == 'commit') {
        expect(r.details['state'], 'FILES_STAGED');
        expect(d.invocations.any((v) => v.contains('push')), false);
        expect(r.message, isNot(contains('privateSecretExample')));
        expect(r.message, contains('git failed (1)'));
        expect(r.message, isNot(contains('RangeError')));
      }
      if (failure == 'push') {
        expect(r.details['state'], 'REMOTE_READY');
        expect(r.status, isNot('CONNECTED'));
        expect(
            File('${d.localPath}${Platform.pathSeparator}GTB-VERIFY.txt')
                .existsSync(),
            true);
      }
      if (failure == 'mismatch' || failure == 'sha') {
        expect(r.details['state'], 'PUSH_COMPLETED');
        expect(r.status, isNot('CONNECTED'));
      }
    });
  }
  test('new private repo follows verified local commit', () async {
    final d = FakeWriteDiagnostics('');
    addTearDown(d.cleanup);
    final r = await WriteTest(d).run(
        repository: 'owner/GTB-VERIFY-test', createNew: true, confirmed: true);
    expect(r.status, 'CONNECTED');
    expect(d.creates, 1);
    final commit = d.invocations.indexWhere((v) => v.contains('commit'));
    final create = d.invocations.indexWhere((v) => v.contains('create'));
    expect(create, greaterThan(commit));
    expect(d.invocations[create], contains('--private'));
  });
  test('other owner is denied before local or remote mutation', () async {
    final d = FakeWriteDiagnostics('');
    final r = await WriteTest(d)
        .run(repository: 'different/repo', createNew: false, confirmed: true);
    expect(r.status, 'ACCESS_DENIED');
    expect(d.invocations, isEmpty);
  });
  test('fractional cross-runtime duration accepted', () {
    expect(
        Check.fromJson({
          'id': 'a',
          'status': 'CONNECTED',
          'message': 'ok',
          'duration_ms': 12.7
        }).durationMs,
        13);
  });
}
