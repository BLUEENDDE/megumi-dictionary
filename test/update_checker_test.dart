import 'package:flutter_test/flutter_test.dart';

import 'package:indonesia_vocab/services/update_checker.dart';

void main() {
  test('版本号比较', () {
    expect(UpdateChecker.compareVersions('3.30.0', '3.9.0'), 1);
    expect(UpdateChecker.compareVersions('3.9.0', '3.30.0'), -1);
    expect(UpdateChecker.compareVersions('3.30.0', '3.30.0'), 0);
    expect(UpdateChecker.compareVersions('3.30.1', '3.30.0'), 1);
    expect(UpdateChecker.compareVersions('4.0.0', '3.99.99'), 1);
    expect(UpdateChecker.compareVersions('3.30', '3.30.0'), 0);
  });
}
