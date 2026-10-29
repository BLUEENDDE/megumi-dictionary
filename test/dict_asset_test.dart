import 'package:flutter_test/flutter_test.dart';
import 'package:indonesia_vocab/services/dictionary.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('词典资源能在测试环境加载', () async {
    await Dictionary.load();
    expect(Dictionary.size, greaterThan(1000));
    expect(Dictionary.countOf(level: 0), greaterThan(0));
  });
}