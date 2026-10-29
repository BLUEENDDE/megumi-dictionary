/// 印尼语常见词缀的作用，用于词族里的对比记忆。
const Map<String, String> affixGlossary = {
  'meN-': '主动动词：主语是动作发出者',
  'me-': '主动动词（部分词根用 me-）',
  'di-': '被动动词：主语是受事',
  'peN-': '名词：做这个动作的人或工具',
  'pe-': '名词：做这个动作的人',
  'per-': '使役 / 名词化',
  'memper-': '使役：使某人/某物变成这样',
  'diper-': '被使役',
  'ber-': '不及物：自己处于某种状态 / 拥有',
  'ter-': '无意、意外，或已完成的状态',
  'ke-': '名词化：抽象性质',
  '-an': '名词：动作的结果或对象',
  '-kan': '使役 / 受益：让别人做，或为别人做',
  '-i': '重复、给予，或方向朝向某处',
  '-nya': '带定指或所有格：那个 / 他的',
  'ke-…-an': '抽象名词：状态或性质',
  'peN-…-an': '名词化：过程或行为',
  'per-…-an': '名词化：过程、场所或结果',
  'meN-…-kan': '主动使役：对某物做这个动作',
  'meN-…-i': '主动：重复地做，或施加于某处',
  'di-…-kan': '被动使役',
  'di-…-i': '被动：被施加于',
  'ber-…-an': '相互 / 反复',
  '词根': '这一族的起点',
};

String affixHint(String affix) {
  if (affix.isEmpty) return '';
  final direct = affixGlossary[affix];
  if (direct != null) return direct;
  // 处理 seperti "meN--kan" 这种写法
  final normalized = affix.replaceAll('--', '-…-');
  return affixGlossary[normalized] ?? '';
}
