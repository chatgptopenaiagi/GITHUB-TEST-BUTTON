import 'dart:convert';
import 'dart:io';
import 'core.dart';

/// Explicitly invoked write operation. Never called by the read-only suite.
class WriteTest {
  final Diagnostics diagnostics;
  String state = 'NOT_INITIALIZED';
  final List<String> transitions = ['NOT_INITIALIZED'];
  WriteTest(this.diagnostics);
  void transition(String expected, String next) {
    if (state != expected) throw StateError('Expected $expected before $next');
    state = next;
    transitions.add(next);
  }

  Future<Check> run(
      {required String repository,
      required bool createNew,
      required bool confirmed,
      void Function(String)? onProgress}) async {
    if (!confirmed) {
      return const Check('repository_write', 'NOT_TESTED',
          'Explicit confirmation is required.');
    }
    if (diagnostics.mobile) {
      return const Check('repository_write', 'UNSUPPORTED_ON_PLATFORM',
          'Local Git write verification requires desktop Git and GitHub CLI. Public mobile diagnostics remain available.');
    }
    if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9-]{0,38}/[A-Za-z0-9_.-]{1,100}$')
            .hasMatch(repository) ||
        [".", ".."].contains(repository.split("/").last)) {
      return const Check(
          'repository_write', 'ACCESS_DENIED', 'Invalid repository name.');
    }
    String? localPath;
    final suffix = DateTime.now().toUtc().microsecondsSinceEpoch.toString();
    final branch = 'gtb-verify-$suffix';
    final content = 'GITHUB TEST BUTTON\nVerification $suffix\n';
    final url = 'https://github.com/$repository';
    Future<String> run(String exe, List<String> args) async {
      final result = await diagnostics.command(exe, args, directory: localPath);
      if (result.exitCode != 0) {
        throw StateError(
            '$exe failed (${result.exitCode}): ${redact(result.stderr.toString()).substring(0, result.stderr.toString().length.clamp(0, 500))}');
      }
      return result.stdout.toString().trim();
    }

    void advance(String expected, String next) {
      transition(expected, next);
      onProgress?.call(next);
    }

    try {
      final auth = await diagnostics.authentication();
      if (auth.status != 'CONNECTED') {
        return Check('repository_write', auth.status,
            'Write test requires verified GitHub CLI authentication.');
      }
      if (diagnostics.account!['login'].toString().toLowerCase() !=
          repository.split('/').first.toLowerCase()) {
        return const Check('repository_write', 'ACCESS_DENIED',
            'Choose a repository owned by the authenticated personal account.');
      }
      if (!createNew) {
        final metadata = await diagnostics.ghApi('repos/$repository');
        if (metadata.status != 'CONNECTED' ||
            metadata.data['permissions']?['push'] != true) {
          return const Check('repository_write', 'ACCESS_DENIED',
              'GitHub does not advertise push permission for this repository.');
        }
      }
      final dir = await Directory.systemTemp.createTemp('gtb-write-');
      localPath = dir.path;
      advance('NOT_INITIALIZED', 'DIRECTORY_CREATED');
      await run('git', ['init', '-b', branch]);
      advance('DIRECTORY_CREATED', 'GIT_INITIALIZED');
      await File('${dir.path}${Platform.pathSeparator}GTB-VERIFY.txt')
          .writeAsString(content);
      advance('GIT_INITIALIZED', 'FILES_CREATED');
      await run('git', ['add', '--', 'GTB-VERIFY.txt']);
      advance('FILES_CREATED', 'FILES_STAGED');
      await run('git', [
        '-c',
        'user.name=GTB Verification',
        '-c',
        'user.email=gtb-test@localhost',
        'commit',
        '-m',
        'GTB explicit write verification'
      ]);
      advance('FILES_STAGED', 'COMMIT_CREATED');
      final sha = await run('git', ['rev-parse', 'HEAD']);
      if (createNew) {
        await run('gh', [
          'repo',
          'create',
          repository,
          '--private',
          '--description',
          'Explicit GITHUB TEST BUTTON write verification'
        ]);
      }
      await run('git', ['remote', 'add', 'origin', '$url.git']);
      advance('COMMIT_CREATED', 'REMOTE_READY');
      await run('git', [
        '-c',
        'credential.helper=',
        '-c',
        'credential.helper=!gh auth git-credential',
        'push',
        'origin',
        'HEAD:refs/heads/$branch'
      ]);
      advance('REMOTE_READY', 'PUSH_COMPLETED');
      final readback = await diagnostics
          .ghApi('repos/$repository/contents/GTB-VERIFY.txt?ref=$branch');
      if (readback.status != 'CONNECTED' ||
          readback.data is! Map ||
          readback.data['encoding'] != 'base64') {
        throw StateError('Remote content unavailable');
      }
      final actual = utf8.decode(base64.decode(readback.data['content']
          .toString()
          .replaceAll(RegExp(r'\s'), ' ')
          .trim()
          .replaceAll(' ', '')));
      if (actual != content) {
        throw StateError('Remote readback content mismatch');
      }
      final remoteCommit =
          await diagnostics.ghApi('repos/$repository/commits/$branch');
      if (remoteCommit.data['sha'] != sha) {
        throw StateError('Remote commit hash mismatch');
      }
      advance('PUSH_COMPLETED', 'REMOTE_VERIFIED');
      return Check('repository_write', 'CONNECTED',
          'Commit, push and remote content verified. No repository or branch was deleted.',
          details: {
            'state': state,
            'transitions': transitions,
            'repository': repository,
            'url': url,
            'branch': branch,
            'commit': sha,
            'local_path': localPath,
            'write_verified': true
          });
    } catch (e) {
      return Check('repository_write', errorStatus(e),
          'Write test stopped at $state. Local data is preserved. ${redact(e.toString())}',
          details: {
            'state': state,
            'transitions': transitions,
            'repository': repository,
            'url': url,
            'branch': branch,
            'local_path': localPath,
            'retry_guidance':
                'Inspect the preserved repository before retrying. Never blindly repeat remote creation.'
          });
    }
  }
}
