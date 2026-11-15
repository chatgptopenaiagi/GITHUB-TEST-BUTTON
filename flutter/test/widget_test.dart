import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:github_test_button/main.dart';
import 'package:github_test_button/diagnostics/core.dart';

class FakeDiagnostics extends Diagnostics {
  final Completer<void>? pending;
  FakeDiagnostics({this.pending}) : super(mobile: true);
  @override
  Future<DiagnosticReport> run(
      {String publicAccount = 'octocat',
      void Function(Check)? onCheck,
      void Function(String)? onProgress}) async {
    onProgress?.call('github.api');
    await pending?.future;
    const c = Check('github.api', 'CONNECTED', 'API verified', durationMs: 12);
    onCheck?.call(c);
    return DiagnosticReport([c],
        timestamp: '2026-11-15T00:00:00Z', platform: 'android', durationMs: 12);
  }

  @override
  Future<Check> repository(String name) async => const Check(
      'repository', 'ACCESS_DENIED', 'Repository absent or inaccessible.');
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final size in [
    const Size(390, 844),
    const Size(768, 1024),
    const Size(1280, 900)
  ]) {
    testWidgets('responsive layout ${size.width}', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(GtbApp(diagnostics: FakeDiagnostics()));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('test-button')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('button loading then measured status', (tester) async {
    final pending = Completer<void>();
    await tester
        .pumpWidget(GtbApp(diagnostics: FakeDiagnostics(pending: pending)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('test-button')));
    await tester.pump();
    expect(find.text('Checking…'), findsOneWidget);
    expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('test-button')))
            .onPressed,
        isNull);
    pending.complete();
    await tester.pumpAndSettle();
    expect(find.text('CONNECTED'), findsWidgets);
    expect(find.text('github.api'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  for (final dark in [false, true]) {
    testWidgets('${dark ? 'dark' : 'light'} theme setting persists',
        (tester) async {
      await tester.pumpWidget(GtbApp(diagnostics: FakeDiagnostics()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settings').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text(dark ? 'Dark' : 'Light'));
      await tester.pumpAndSettle();
      expect((await SharedPreferences.getInstance()).getInt('theme'),
          dark ? 2 : 1);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('repository failure is shown', (tester) async {
    await tester.pumpWidget(GtbApp(diagnostics: FakeDiagnostics()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Repositories').last);
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('repo-field')), 'owner/private');
    await tester.tap(find.text('Inspect repository'));
    await tester.pumpAndSettle();
    expect(find.text('ACCESS DENIED'), findsOneWidget);
    expect(find.text('Repository absent or inaccessible.'), findsOneWidget);
  });
  testWidgets('reports controls render', (tester) async {
    await tester.pumpWidget(GtbApp(diagnostics: FakeDiagnostics()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Details & reports').last);
    await tester.pumpAndSettle();
    expect(find.text('Export JSON'), findsOneWidget);
    expect(find.text('Export TXT'), findsOneWidget);
    expect(find.text('Copy report'), findsOneWidget);
  });
}
