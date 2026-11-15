import 'dart:convert';
import 'dart:io';
import 'package:github_test_button/diagnostics/core.dart';

Future<void> main(List<String> args) async {
  final d = Diagnostics();
  final report = await d.run();
  final json = report.toJson();
  if (args.isNotEmpty) {
    json['repository'] = (await d.repository(args.first)).toJson();
  }
  stdout.writeln(const JsonEncoder.withIndent('  ').convert(json));
}
