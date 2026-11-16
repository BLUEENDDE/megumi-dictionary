const LEVEL_NAME = ['初', '中', '高'];

const state = {
  entries: [],
  newBase: [],
  families: [],
  roots: new Map(),      // 词 -> 词根
  affixes: new Map(),    // 词 -> 词缀
  level: 0,
  query: '',
  shown: 0,
  pageSize: 50,
  filtered: [],
};

const $ = (id) => document.getElementById(id);

async function loadData() {
  // 数据以 js 变量引入，file:// 直接打开也能用
  const dict = window.__DICT__ || [];
  const book = window.__NEWBASE1__ || [];
  const fams = window.__FAMS__ || [];
  const aff = window.__AFFIX__ || {};
  state.entries = dict;
  state.newBase = book.map((e) => Object.assign({}, e, { lvl: -1 }));
  state.families = fams;
  for (const [word, [root, affix]] of Object.entries(aff || {})) {
    state.roots.set(word, root);
    state.affixes.set(word, affix);
  }
  for (const f of fams) {
    if (!state.roots.has(f.r)) state.roots.set(f.r, f.r);
  }
}

function familyOf(word) {
  const curated = state.families.find((f) => f.r === word);
  if (curated) return curated;
  const root = state.roots.get(word);
  if (!root) return null;
  return state.families.find((f) => f.r === root) || null;
}

function hasFamily(word) {
  return state.roots.has(word) || state.families.some((f) => f.r === word);
}

function applyFilter() {
  const q = state.query.trim().toLowerCase();
  const base =
    state.level === -1
      ? state.newBase
      : state.entries.filter((e) => e.lvl === state.level);
  state.filtered = q
    ? state.newBase
        .concat(state.entries)
        .filter(
          (e) =>
            e.w.toLowerCase().includes(q) ||
            (e.g || '').toLowerCase().includes(q)
        )
    : base;
  state.shown = 0;
  $('list').innerHTML = '';
  renderMore();
  $('count').textContent = q
    ? `找到 ${state.filtered.length} 条`
    : `共 ${state.filtered.length} 词`;
  $('hint').textContent = q ? '' : `当前显示 ${Math.min(state.pageSize, state.filtered.length)} 条`;
}

function renderMore() {
  const next = state.filtered.slice(state.shown, state.shown + state.pageSize);
  const frag = document.createDocumentFragment();
  for (const e of next) frag.appendChild(rowOf(e));
  $('list').appendChild(frag);
  state.shown += next.length;
  $('more').style.display = state.shown >= state.filtered.length ? 'none' : '';
  if (!state.query.trim()) {
    $('hint').textContent = `当前显示 ${state.shown} / ${state.filtered.length}`;
  }
}

function rowOf(e) {
  const row = document.createElement('div');
  row.className = 'row';
  row.onclick = () => openDetail(e);

  const lvl = document.createElement('span');
  lvl.className = 'lvl';
  lvl.dataset.l = e.lvl;
  if (e.lesson) {
    const num = (e.lesson.match(/[0-9]+/) || [])[0];
    lvl.textContent = num ? '课' + num : '课';
  } else {
    lvl.textContent = LEVEL_NAME[e.lvl] || '高';
  }
  row.appendChild(lvl);

  const body = document.createElement('div');
  body.className = 'body';

  const wr = document.createElement('div');
  wr.className = 'word-row';
  const w = document.createElement('span');
  w.className = 'word';
  w.textContent = e.w;
  wr.appendChild(w);
  if (e.pos) {
    const pos = document.createElement('span');
    pos.className = 'pos';
    pos.textContent = e.pos;
    wr.appendChild(pos);
  }
  body.appendChild(wr);

  const g = document.createElement('div');
  g.className = 'gloss';
  g.textContent = e.g || '—';
  body.appendChild(g);

  if (e.ex) {
    const ex = document.createElement('div');
    ex.className = 'ex';
    ex.textContent = e.ex;
    body.appendChild(ex);
  }
  row.appendChild(body);

  const fam = document.createElement('button');
  fam.className = 'fam' + (hasFamily(e.w) ? '' : ' off');
  fam.textContent = '◈';
  fam.title = hasFamily(e.w) ? '词根关系' : '暂无词族';
  fam.onclick = (ev) => {
    ev.stopPropagation();
    const f = familyOf(e.w);
    if (!f) return openDetail(e, '这个词还没有词族');
    openDetail(e, null, f);
  };
  row.appendChild(fam);

  return row;
}

function openDetail(e, note, family) {
  const fam = family || familyOf(e.w);
  const parts = [];
  parts.push(`<h2 class="detail-word">${esc(e.w)}</h2>`);
  if (e.pos) parts.push(`<span class="detail-pos">${esc(e.pos)}</span>`);
  if (e.lesson) parts.push(`<span class="detail-pos" style="margin-left:6px">${esc(e.lesson)}</span>`);
  parts.push(`<p class="detail-gloss">${esc(e.g || '（暂无释义）')}</p>`);

  if (e.ex) {
    parts.push('<div class="exbox"><div class="label">例句</div>');
    parts.push(`<div class="id">${esc(e.ex)}</div>`);
    if (e.exc) parts.push(`<div class="cn">${esc(e.exc)}</div>`);
    parts.push('</div>');
  }

  if (e.gr) {
    parts.push('<div class="exbox"><div class="label">语法</div>');
    parts.push(`<div class="cn" style="margin-top:6px">${esc(e.gr)}</div>`);
    parts.push('</div>');
  }

  if (note) parts.push(`<p class="hint" style="margin-top:14px">${esc(note)}</p>`);

  if (fam && fam.m && fam.m.length) {
    const members = [...fam.m].sort((a, b) => (a.a || '').localeCompare(b.a || ''));
    parts.push('<div class="famlist">');
    parts.push(`<h3>同源词 ${members.length} 个 · 词根「${esc(fam.r)}」${fam.rg ? '：' + esc(fam.rg) : ''}</h3>`);
    for (const m of members.slice(0, 60)) {
      parts.push(
        `<div class="famitem"><span class="aff">${esc(m.a || '')}</span>` +
          `<span><span class="fw">${esc(m.w)}</span> <span class="fg">${esc(m.g || '')}</span></span></div>`
      );
    }
    parts.push('</div>');
  }

  $('modalBody').innerHTML = parts.join('');
  $('modal').hidden = false;
}

function esc(s) {
  return String(s).replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
}

/* ---------- 测验 ---------- */
let quiz = null;

function startQuiz() {
  const pool = state.filtered.length
    ? state.filtered
    : state.level === -1
      ? state.newBase
      : state.entries.filter((e) => e.lvl === state.level);
  const n = Math.min(Number($('batch').value), pool.length);
  const picked = shuffle([...pool]).slice(0, n);
  quiz = { list: picked, pool, index: 0, right: 0, passes: {}, round: 1, all: picked };
  $('quiz').hidden = false;
  renderQuestion();
}

function renderQuestion() {
  const { list, index, pool } = quiz;
  if (index >= list.length) {
    const remaining = quiz.list.filter((w) => (quiz.passes[w.w] || 0) < 2);
    if (remaining.length) {
      quiz.round++;
      quiz.list = remaining.sort(() => Math.random() - 0.5);
      quiz.index = 0;
      renderQuestion();
      return;
    }
    $('quizBody').innerHTML =
      `<div class="qdone"><div class="score">${quiz.right} / ${quiz.all.length}</div>` +
      `<p class="hint">这一组过完了</p>` +
      `<button class="primary" style="margin-top:18px" onclick="closeQuiz()">完成</button></div>`;
    return;
  }
  const q = list[index];
  const target = (q.g || '').length;
  const source = quiz.all.length >= 4 ? quiz.all : pool;
  const cands = source.filter((c) => {
    const g = (c.g || '').trim();
    return c.w !== q.w && g && g !== q.g && g.length <= Math.max(26, target * 2);
  });
  const distractors = [];
  let guard = 0;
  while (distractors.length < 3 && guard < 600 && cands.length) {
    guard++;
    const c = cands[Math.floor(Math.random() * cands.length)];
    if (distractors.some((d) => d.g === c.g)) continue;
    distractors.push(c);
  }
  const options = shuffle([q, ...distractors]);

  const html = [];
  html.push(`<div class="qprogress"><span style="width:${(index / list.length) * 100}%"></span></div>`);
  html.push(`<div class="qword">${esc(q.w)}</div>`);
  options.forEach((o, i) => {
    html.push(`<button class="opt" data-i="${i}">${esc((o.g || '—').slice(0, 46))}</button>`);
  });
  $('quizBody').innerHTML = html.join('');

  $('quizBody').querySelectorAll('.opt').forEach((btn, i) => {
    btn.onclick = () => answer(btn, options[i], q);
  });
}

function answer(btn, opt, q) {
  const buttons = [...$('quizBody').querySelectorAll('.opt')];
  buttons.forEach((b) => (b.disabled = true));
  const right = opt.w === q.w;
  buttons.forEach((b) => {
    const text = b.textContent;
    if (text === (q.g || '—')) b.classList.add('right');
    else if (b === btn) b.classList.add('wrong');
    else b.classList.add('dim');
  });
  if (right) {
    const pass = (quiz.passes[q.w] || 0) + 1;
    quiz.passes[q.w] = pass;
    if (pass >= 2) quiz.right++;
  } else {
    quiz.passes[q.w] = 0;
  }
  setTimeout(() => {
    quiz.index++;
    renderQuestion();
  }, right ? 420 : 900);
}

function closeQuiz() {
  $('quiz').hidden = true;
}

function shuffle(a) {
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

/* ---------- 事件 ---------- */
$('levels').addEventListener('click', (ev) => {
  const btn = ev.target.closest('.pill');
  if (!btn) return;
  document.querySelectorAll('.pill').forEach((p) => p.classList.remove('active'));
  btn.classList.add('active');
  state.level = btn.dataset.level === 'book' ? -1 : Number(btn.dataset.level);
  applyFilter();
});

let timer = null;
$('search').addEventListener('input', (ev) => {
  clearTimeout(timer);
  timer = setTimeout(() => {
    state.query = ev.target.value;
    applyFilter();
  }, 180);
});

$('more').onclick = () => renderMore();
$('startQuiz').onclick = () => startQuiz();
$('closeModal').onclick = () => ($('modal').hidden = true);
$('closeQuiz').onclick = () => closeQuiz();
$('modal').addEventListener('click', (e) => {
  if (e.target.id === 'modal') $('modal').hidden = true;
});

document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') {
    $('modal').hidden = true;
    closeQuiz();
  }
});

loadData().then(() => {
  applyFilter();
  // 便于截图/直达：?w=单词 打开详情，?quiz=1 直接开始测验
  const params = new URLSearchParams(location.search);
  const lv = params.get('level');
  if (lv) {
    document.querySelectorAll('.pill').forEach((p) => {
      p.classList.toggle('active', p.dataset.level === lv);
    });
    state.level = lv === 'book' ? -1 : Number(lv);
    applyFilter();
  }
  const word = params.get('w');
  if (word) {
    const src = state.newBase.concat(state.entries);
    const entry = src.find((e) => e.w === word) || state.entries.find((e) => e.w === word);
    if (entry) openDetail(entry);
  }
  if (params.get('quiz') === '1') startQuiz();
});
