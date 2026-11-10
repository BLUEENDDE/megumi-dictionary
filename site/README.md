# megumi辞書 网页版

纯静态页面，不需要后端，也不需要构建。

## 打开方式

直接双击 `index.html` 就能用（数据已经打成 js 文件，`file://` 下也不会被 CORS 拦住）。

如果要用本地服务器：

```bash
python -m http.server 8400 --directory site
# 然后打开 http://127.0.0.1:8400/
```

## 功能

- **分级词单**：初级 2,500 / 中级 7,500 / 高级 39,255
- **搜索**：按单词或中文释义过滤
- **详情**：点词条看词性、释义、例句与翻译
- **词根关系**：点右侧 ◈ 看同源词按词缀排列
- **测验**：四选一，可选每组 10/20/30/50 词

## 数据

页面读取 `data/` 下三个文件：

| 文件 | 内容 |
|---|---|
| `dictionary.js` | 词库（`window.__DICT__`） |
| `families.js` | 词族（`window.__FAMS__`） |
| `affixes.js` | 语素拆解（`window.__AFFIX__`） |

这三个文件由 Flutter 工程 `assets/` 里的同名 JSON 转换而来，**没有提交到仓库**（词典内容不公开分发）。自己要用的话，在仓库根目录执行：

```bash
python - <<'PY'
import json, os
base, out = 'assets', 'site/data'
for name, var in [('dictionary', '__DICT__'), ('families', '__FAMS__'), ('affixes', '__AFFIX__')]:
    raw = json.load(open(os.path.join(base, name + '.json'), encoding='utf-8'))
    with open(os.path.join(out, name + '.js'), 'w', encoding='utf-8') as f:
        f.write('window.' + var + '=' + json.dumps(raw, ensure_ascii=False, separators=(',', ':')) + ';')
PY
```

## 结构

```
site/
├── index.html   页面骨架
├── styles.css   样式（浅色 / 深色自动切换）
├── app.js       列表、搜索、详情、测验
└── data/        数据（本地生成，不入库）
```
