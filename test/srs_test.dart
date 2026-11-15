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

    await store.record('p1', true, isReview: true);
    expect(store.statFor('p1').box, 1);
    expect(store.statFor('p1').dueAt, isNotNull);

    await store.record('p1', true, isReview: true);
    expect(store.statFor('p1').box, 2);

    await store.record('p1', false, isReview: true);
    expect(store.statFor('p1').box, 0);
    // 打回 0 之后立刻又该复习
    expect(store.statFor('p1').isDue, isTrue);
  });

  test('答对后当天不应再到期（box1 = 1 天后）', () async {
    final store = ProgressStore();
    await store.load();
    await store.record('p1', true, isReview: true);

    final stat = store.statFor('p1');
    expect(stat.isDue, isFalse);
    expect(stat.dueAt! > DateTime.now().millisecondsSinceEpoch, isTrue);
  });

  test('没学过的词不进复习队列', () async {
    final store = ProgressStore();
    await store.load();

    final fresh = _pair('fresh');
    final learned = _pair('learned');

    await store.record('learned', true, isReview: true); // 学过，明天才到期

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

    await store.record('due', true, isReview: true);
    await store.record('later', true, isReview: true);
    await store.record('later', true, isReview: true);

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
      await store.record('p1', true, isReview: true);
    }
    expect(store.statFor('p1').box, ProgressStore.maxBox);
  });

  test('复习一次并答对才算掌握', () async {
    final store = ProgressStore();
    await store.load();

    final learning = _pair('learning');
    final mastered = _pair('mastered');

    // learning：只新学，没复习
    await store.record('learning', true);
    // mastered：新学 + 一次复习答对
    await store.record('mastered', true);
    await store.record('mastered', true, isReview: true);

    expect(store.isMastered('learning'), isFalse);
    expect(store.isMastered('mastered'), isTrue);
    expect(
      store.learningPairs([learning, mastered]).map((p) => p.id),
      ['learning'],
    );
    expect(
      store.masteredPairs([learning, mastered]).map((p) => p.id),
      ['mastered'],
    );
    expect(store.learnedPairs([learning, mastered]).length, 2);
  });


  group('新学与复习的区别', () {
    test('新学只标记学过，不算掌握，盒子不动', () async {
      final store = ProgressStore();
      await store.load();

      await store.record('w:baru', true);

      final stat = store.statFor('w:baru');
      expect(stat.learned, isTrue);
      expect(stat.reviews, 0);
      expect(stat.box, 0);
      expect(store.isMastered('w:baru'), isFalse);
    });

    test('新学完马上可以复习', () async {
      final store = ProgressStore();
      await store.load();

      await store.record('w:baru', true);
      expect(store.statFor('w:baru').isDue, isTrue);
    });

    test('复习答对：复习次数 +1，盒子推进，变掌握', () async {
      final store = ProgressStore();
      await store.load();

      await store.record('w:x', true); // 新学
      await store.record('w:x', true, isReview: true); // 复习

      final stat = store.statFor('w:x');
      expect(stat.reviews, 1);
      expect(stat.box, 1);
      expect(store.isMastered('w:x'), isTrue);
    });

    test('复习答错：不算掌握，但复习次数已计入', () async {
      final store = ProgressStore();
      await store.load();

      await store.record('w:y', true);
      await store.record('w:y', false, isReview: true);

      final stat = store.statFor('w:y');
      expect(stat.reviews, 1);
      expect(stat.box, 0);
      expect(store.isMastered('w:y'), isFalse);
    });

    test('复习次数会存进备份并读回', () async {
      final store = ProgressStore();
      await store.load();

      await store.record('w:z', true);
      await store.record('w:z', true, isReview: true);

      final dump = store.toJson();
      final restored = ProgressStore();
      restored.loadFromMap(dump);

      expect(restored.statFor('w:z').reviews, 1);
      expect(restored.isMastered('w:z'), isTrue);
    });
  });
}
