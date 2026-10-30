/// 应用版本号（只写版本，不带 build 号）。
///
/// 必须和 pubspec.yaml 里的 `version:` 保持一致；
/// test/version_test.dart 会在测试时读 pubspec 校验，改一处忘了另一处会直接报错。
library;

const String appVersion = '3.9.0';
