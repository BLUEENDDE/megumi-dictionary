import '../models/word_pair.dart';

/// 内置词库。先用手写的几组真实词对，之后可以换成从文件加载。
const List<WordPair> samplePairs = [
  WordPair(
    id: 'besar-luas',
    tag: '尺寸 / 面积',
    summary: 'besar 说体积和尺寸，luas 说面积和范围',
    first: WordSense(form: 'besar', gloss: '大（体积、尺寸、量级）'),
    second: WordSense(form: 'luas', gloss: '大（面积、空间、范围）'),
    axes: [
      ContrastAxis(
        name: '适用对象',
        first: '体积、尺寸、量级',
        second: '面积、空间、范围',
      ),
      ContrastAxis(
        name: '常见搭配',
        first: 'rumah besar（大房子）、pengaruh besar（大影响）',
        second: 'lapangan luas（大操场）、wawasan luas（见识广）',
      ),
      ContrastAxis(
        name: '反义',
        first: 'kecil（小）',
        second: 'sempit（窄）',
      ),
    ],
    example: ExamplePair(
      firstText: 'Mereka tinggal di rumah yang besar.',
      firstGloss: '他们住在一栋大房子里。',
      firstNote: '建筑有体积 → besar',
      secondText: 'Lapangan itu sangat luas.',
      secondGloss: '那个操场很大。',
      secondNote: '场地讲面积 → luas',
    ),
  ),
  WordPair(
    id: 'melihat-menonton',
    tag: '看',
    summary: 'melihat 是看一眼、看见，menonton 是坐下来看节目',
    first: WordSense(form: 'melihat', gloss: '看见、看一眼'),
    second: WordSense(form: 'menonton', gloss: '观看（影剧、比赛、演出）'),
    axes: [
      ContrastAxis(
        name: '对象',
        first: '任何东西',
        second: '电影、比赛、演出等有内容的东西',
      ),
      ContrastAxis(
        name: '时长',
        first: '一瞬间，或泛指',
        second: '持续一段时间',
      ),
      ContrastAxis(
        name: '身体状态',
        first: '经过、瞥见',
        second: '坐下、专门去看',
      ),
    ],
    example: ExamplePair(
      firstText: 'Saya melihat foto itu di dinding.',
      firstGloss: '我在墙上看到那张照片。',
      firstNote: '看见 → melihat',
      secondText: 'Kami menonton film di bioskop.',
      secondGloss: '我们在电影院看电影。',
      secondNote: '看电影 → menonton',
    ),
  ),
  WordPair(
    id: 'mendengar-mendengarkan',
    tag: '听',
    summary: 'mendengar 是听见（被动），mendengarkan 是认真听（主动）',
    first: WordSense(form: 'mendengar', gloss: '听见、听到'),
    second: WordSense(form: 'mendengarkan', gloss: '听、倾听（主动）'),
    axes: [
      ContrastAxis(
        name: '主动性',
        first: '被动，声音自己进来的',
        second: '主动，有意去听',
      ),
      ContrastAxis(
        name: '常见搭配',
        first: 'mendengar suara（听到声音）',
        second: 'mendengarkan musik（听音乐）',
      ),
    ],
    example: ExamplePair(
      firstText: 'Saya mendengar suara aneh tadi malam.',
      firstGloss: '昨晚我听到奇怪的声音。',
      firstNote: '无意听见 → mendengar',
      secondText: 'Dia mendengarkan musik di kamar.',
      secondGloss: '他在房间里听音乐。',
      secondNote: '有意在听 → mendengarkan',
    ),
  ),
  WordPair(
    id: 'senang-bahagia',
    tag: '高兴 / 幸福',
    summary: 'senang 是当下的高兴，bahagia 是长久的幸福',
    first: WordSense(form: 'senang', gloss: '高兴、开心（当下）'),
    second: WordSense(form: 'bahagia', gloss: '幸福（长期状态）'),
    axes: [
      ContrastAxis(
        name: '时长',
        first: '一时一刻的心情',
        second: '长期的生活状态',
      ),
      ContrastAxis(
        name: '程度',
        first: '轻，日常用',
        second: '重，偏郑重',
      ),
      ContrastAxis(
        name: '常见搭配',
        first: 'senang bertemu（很高兴见到）',
        second: 'hidup bahagia（幸福地生活）',
      ),
    ],
    example: ExamplePair(
      firstText: 'Saya senang bertemu kamu.',
      firstGloss: '见到你很高兴。',
      firstNote: '见面那一刻的心情 → senang',
      secondText: 'Mereka hidup bahagia bersama.',
      secondGloss: '他们一起幸福地生活。',
      secondNote: '一辈子的状态 → bahagia',
    ),
  ),
  WordPair(
    id: 'cepat-lekas',
    tag: '快',
    summary: 'cepat 说速度，lekas 说"很快就、尽早"',
    first: WordSense(form: 'cepat', gloss: '快（速度）'),
    second: WordSense(form: 'lekas', gloss: '尽快、很快就要'),
    axes: [
      ContrastAxis(
        name: '侧重',
        first: '速度快、耗时短',
        second: '时间上早、即将发生',
      ),
      ContrastAxis(
        name: '语域',
        first: '通用，口语书面都行',
        second: '偏书面，日常口语更常说 sebentar lagi',
      ),
    ],
    example: ExamplePair(
      firstText: 'Kereta ini sangat cepat.',
      firstGloss: '这列火车很快。',
      firstNote: '说速度 → cepat',
      secondText: 'Lekas sembuh, ya!',
      secondGloss: '祝你早日康复！',
      secondNote: '说"尽快" → lekas',
    ),
  ),
  WordPair(
    id: 'membeli-berbelanja',
    tag: '买 / 购物',
    summary: 'membeli 是买下某样东西，berbelanja 是去逛着买',
    first: WordSense(form: 'membeli', gloss: '买（某样具体的东西）'),
    second: WordSense(form: 'berbelanja', gloss: '购物、采购（过程）'),
    axes: [
      ContrastAxis(
        name: '焦点',
        first: '买到的那件东西',
        second: '买东西这件事、这个过程',
      ),
      ContrastAxis(
        name: '场合',
        first: '任何一笔交易',
        second: '商场、市场，通常买好几样',
      ),
      ContrastAxis(
        name: '常见搭配',
        first: 'membeli tiket（买票）',
        second: 'berbelanja di mal（在商场购物）',
      ),
    ],
    example: ExamplePair(
      firstText: 'Saya membeli tiket kereta.',
      firstGloss: '我买了火车票。',
      firstNote: '买一张票 → membeli',
      secondText: 'Ibu berbelanja di pasar setiap pagi.',
      secondGloss: '妈妈每天早上逛市场买菜。',
      secondNote: '采购这件事 → berbelanja',
    ),
  ),
];
