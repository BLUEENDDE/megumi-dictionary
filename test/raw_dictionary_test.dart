import 'package:flutter_test/flutter_test.dart';

import 'package:indonesia_vocab/services/raw_dictionary.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('扫描原文能加载，且能按词取到', () async {
    await RawDictionary.load();
    expect(RawDictionary.isLoaded, isTrue);
    expect(RawDictionary.of('ambil'), isNotNull);
    expect(RawDictionary.of('____不存在的词____'), isNull);
  });
}
