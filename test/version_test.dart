import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:indonesia_vocab/app_info.dart';

void main() {
  test('设置页显示的版本号跟 pubspec 一致', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final match =
        RegExp(r'^version:\s*(\S+)', multiLine: true).firstMatch(pubspec);

    expect(match, isNotNull, reason: 'pubspec.yaml 里找不到 version:');
    final version = match!.group(1)!.split('+').first;
    expect(version, appVersion);
  });
}
