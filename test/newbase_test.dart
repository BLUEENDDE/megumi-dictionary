import 'package:flutter_test/flutter_test.dart';
import 'package:indonesia_vocab/services/settings_store.dart';

void main() {
  test('词单包含教材《新编基础印尼语一》', () {
    expect(SettingsStore.listOptions.containsKey('newbase1'), isTrue);
    expect(SettingsStore.listOptions['newbase1'], '新编基础印尼语一');
  });

  test('教材归在「教材词库」分类下', () {
    expect(SettingsStore.categories['教材词库'], contains('newbase1'));
  });
}