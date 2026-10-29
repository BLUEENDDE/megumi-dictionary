import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:indonesia_vocab/models/word_pair.dart';
import 'package:indonesia_vocab/services/progress_store.dart';

WordPair _pair(String id) => WordPair(
      id: id,
      tag: '',
      summary: '',
      first: const WordSense(form: 'a', gloss: ''),
      second: const WordSense(form: 'b', gloss: ''),
      axes: const [],
      example: const ExamplePair(
        firstText: '',
        firstGloss: '',
        firstNote: '',
        secondText: '',
        secondGloss: '',
        secondNote: '',
      ),
    );

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('答对推进盒子，答错打回 0', () async {
    final store = ProgressStore();
    await store.load();

    await store.record('p1', true);
    expect(store.statFor('p1').box, 1);
    expect(store.statFor('p1').dueAt, isNotNull);

    await store.record('p1', true);
    expect(store.statFor('p1').box, 2);

    await store.record('p1', false);
    expect(store.statFor('p1').box, 0);
    // 打回 0 之后立刻又该复习
    expect(store.statFor('p1').isDue, isTrue);
  });

  test('答对后当天不应再到期（box1 = 1 天后）', () async {
    final store = ProgressStore();
    await store.load();
    await store.record('p1', true);

    final stat = store.statFor('p1');
    expect(stat.isDue, isFalse);
    expect(stat.dueAt! > DateTime.now().millisecondsSinceEpoch, isTrue);
  });

  test('没学过的词不进复习队列', () async {
    final store = ProgressStore();
    await store.load();

    final fresh = _pair('fresh');
    final learned = _pair('learned');

    await store.record('learned', true); // 学过，明天才到期

    expect(store.statFor('fresh').learned, isFalse);
    expect(store.statFor('fresh').isDue, isFalse, reason: '没学过不该算到期');
    expect(store.dueQueue([fresh, learned]), isEmpty);
    expect(store.unlearned([fresh, learned]).map((p) => p.id), ['fresh']);
    expect(store.dueCount([fresh, learned]), 0);
  });

  test('学过的到期后才进复习，且早到期的排前面', () async {
    final store = ProgressStore();
    await store.load();

    final fresh = _pair('fresh');
    final due = _pair('due');
    final later = _pair('later');

    await store.record('due', true);
    await store.record('later', true);
    await store.record('later', true);

    // 把 due 的到期时间手动拉到过去，模拟到期
    final data = store.toJson();
    final pairs = data['pairs'] as Map<String, dynamic>;
    (pairs['due'] as Map<String, dynamic>)['dueAt'] =
        DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch;
    store.loadFromMap(data);

    final queue = store.dueQueue([later, fresh, due]);
    expect(queue.map((p) => p.id), ['due'], reason: '只有到期且学过的进队列');
    expect(store.dueCount([fresh, due, later]), 1);
    expect(store.unlearned([fresh, due, later]).map((p) => p.id), ['fresh']);
  });

  test('盒子不会超过上限', () async {
    final store = ProgressStore();
    await store.load();
    for (var i = 0; i < 12; i++) {
      await store.record('p1', true);
    }
    expect(store.statFor('p1').box, ProgressStore.maxBox);
  });
}
