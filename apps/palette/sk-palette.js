/* Sulekhak Unicode palette: one module for the web typists (floating dialog) and the Mac / Windows apps (the same page in a native window).
 *
 *   SKPalette.mount({mode:'dialog'|'window', ...}) -> {open, close, toggle, isOpen, setPinned, destroy}
 *
 * dialog  floating, draggable, resizable box inside a web page; closes on an outside click unless pinned.
 * window  fills the page of a native window (Mac NSPanel / Windows form). The native side moves, resizes and dismisses the window, and puts the
 *         character into the focused program (see the messages below), because only it knows which program has the keyboard focus.
 *
 * Native messages (JSON text through webkit.messageHandlers.palette / chrome.webview):
 *   {t:'pal-ins', s:'→', copyOnly:false}   put this character into the focused text box, or copy it when there is none; the host answers SKPalette.native.result()
 *   {t:'pal-pin', on:true}  {t:'pal-hide'}  {t:'pal-drag', s:1|2|0}  {t:'pal-size', s:1|2|0}  {t:'pal-search', on:true|false}  {t:'pal-save', k, v}  {t:'pal-ready'}
 * The page is driven by SKPalette.native: result(status), restore(obj), pinned(on), key(k) (typing forwarded from the native side while searching),
 * hover(x, y) and hoverLeave() (pointer positions, for a window that never gets mouse-move events of its own).
 *
 * A character is always inserted as the plain Unicode code point. A combining mark is only *shown* on a no-break space in the grid so that it
 * has something to sit on; no dotted circle (U+25CC) or other placeholder is ever inserted.
 */
(function (root) {
  'use strict';
  var DATA = root.SK_PALETTE_DATA;
  if (!DATA || !DATA.cats) { return; }

  var NBSP = ' ';
  var FAV_MAX = 200, RECENT_MAX = 30;
  var hasProp = true, reMark, reEmoji;
  try { reMark = new RegExp('^[\\p{M}]$', 'u'); reEmoji = new RegExp('^[\\p{Emoji}]$', 'u'); } catch (e) { hasProp = false; }

  function cpStr(cp) { return String.fromCodePoint(cp); }
  function hex(cp) { var h = cp.toString(16).toUpperCase(); while (h.length < 4) { h = '0' + h; } return h; }
  function isMark(cp) { return hasProp && reMark.test(cpStr(cp)); }
  function wantsText(cp) { return hasProp && cp >= 0x203C && reEmoji.test(cpStr(cp)); }
  function esc(s) { return String(s).replace(/[&<>"]/g, function (c) { return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]; }); }

  /* what is drawn in a cell: the character itself (a mark on a no-break space, an emoji-like sign kept in text style), or a short label for invisible ones */
  function glyphOf(cat, it) {
    var cp = it[0];
    if (cat.id === 'invisible') { return { text: it[2] || ('U+' + hex(cp)), label: true }; }
    var s = cpStr(cp);
    if (isMark(cp)) { s = NBSP + s; } else if (wantsText(cp)) { s += '︎'; }
    return { text: s, label: false };
  }

  /* ---------- the search index ---------- */
  var ALL = [];
  DATA.cats.forEach(function (c) {
    c.items.forEach(function (it) {
      var h = hex(it[0]);
      it.idx = (it[1] + ' u+' + h + ' ' + h + ' ' + (it[2] || '') + ' ' + c.title + ' ' + cpStr(it[0])).toLowerCase();
      it.cat = c;
      ALL.push(it);
    });
  });
  var BYCP = {};
  ALL.forEach(function (it) { if (!BYCP[it[0]]) { BYCP[it[0]] = it; } });

  function matches(it, toks) {
    for (var i = 0; i < toks.length; i++) { if (it.idx.indexOf(toks[i]) < 0) { return false; } }
    return true;
  }
  function tokens(q) {
    q = String(q || '').toLowerCase().replace(/^\s+|\s+$/g, '');
    if (!q) { return []; }
    return q.split(/\s+/);
  }
  function search(q) {
    var t = tokens(q), out = [];
    if (!t.length) { return ALL.slice(); }
    ALL.forEach(function (it) { if (matches(it, t)) { out.push(it); } });
    return out;
  }

  /* ---------- styles ---------- */
  var CSS = [
    '.skp{--bg:#f7f6f2;--fg:#1c2430;--mut:#5b6577;--line:#d9d6cc;--cell:#fff;--cellh:#e9f3f0;--acc:#1f6f64;--hd:#ece9e0;--shadow:0 10px 36px rgba(20,30,50,.28);',
    'box-sizing:border-box;display:flex;flex-direction:column;background:var(--bg);color:var(--fg);font:12px/1.25 system-ui,-apple-system,"Segoe UI",Roboto,sans-serif;border:1px solid var(--line);border-radius:10px;overflow:hidden;-webkit-user-select:none;user-select:none}',
    '.skp[data-skt=dark]{--bg:#1d2331;--fg:#e7ebf3;--mut:#9aa6bd;--line:#323b50;--cell:#262e42;--cellh:#2f3c52;--acc:#5cc8b6;--hd:#252c3f;--shadow:0 10px 36px rgba(0,0,0,.55)}',
    '.skp *{box-sizing:border-box}.skp[hidden],.skp-tip[hidden]{display:none!important}',
    '.skp-dialog{position:fixed;z-index:2147483000;box-shadow:var(--shadow);resize:both;min-width:300px;min-height:220px;max-width:96vw;max-height:94vh}',
    '.skp-window{position:fixed;left:0;top:0;right:0;bottom:0;border-radius:0;border:0}',
    '.skp-hd{display:flex;align-items:center;gap:6px;padding:5px 6px 5px 10px;background:var(--hd);border-bottom:1px solid var(--line);cursor:move;flex:none}',
    '.skp-ttl{font-weight:650;letter-spacing:.02em;white-space:nowrap}',
    '.skp-q{flex:1;min-width:60px;height:24px;border:1px solid var(--line);border-radius:6px;background:var(--cell);color:var(--fg);padding:0 8px;font:inherit;font-size:12px;outline:none;-webkit-user-select:text;user-select:text;cursor:text}',
    '.skp-q:focus,.skp-q.on{border-color:var(--acc);box-shadow:0 0 0 2px color-mix(in srgb,var(--acc) 30%,transparent)}',
    '.skp-b{width:24px;height:24px;border:0;background:transparent;color:var(--mut);border-radius:6px;display:inline-flex;align-items:center;justify-content:center;padding:0;cursor:pointer;flex:none}',
    '.skp-b:hover{background:var(--cellh);color:var(--fg)}.skp-b.on{color:var(--acc);background:var(--cellh)}',
    '.skp-b svg{width:15px;height:15px;fill:none;stroke:currentColor;stroke-width:1.7;stroke-linecap:round;stroke-linejoin:round}',
    '.skp-b.on svg .fill{fill:currentColor}',
    '.skp-body{flex:1;min-height:0;overflow-y:auto;overflow-x:hidden;padding:2px 0 4px}',
    '.skp-row{padding:0 0 1px}',
    '.skp-rh{display:flex;align-items:baseline;gap:6px;padding:3px 10px 1px;color:var(--mut);font-size:10.5px;font-weight:650;letter-spacing:.04em;text-transform:uppercase}',
    '.skp-rh i{font-style:normal;font-weight:400;opacity:.75;letter-spacing:0;text-transform:none}',
    '.skp-strip{display:flex;gap:3px;overflow-x:auto;overflow-y:hidden;padding:1px 10px 3px;scrollbar-width:thin;overscroll-behavior-x:contain}',
    '.skp-strip::-webkit-scrollbar{height:5px}.skp-strip::-webkit-scrollbar-thumb{background:var(--line);border-radius:3px}',
    '.skp-c{position:relative;flex:none;width:58px;height:56px;border:1px solid var(--line);border-radius:6px;background:var(--cell);color:var(--fg);padding:2px 2px 1px;display:flex;flex-direction:column;align-items:center;justify-content:flex-start;cursor:pointer;font:inherit;overflow:hidden}',
    '.skp-c:hover,.skp-c:focus-visible,.skp-c.hv{background:var(--cellh);border-color:var(--acc);outline:none}',
    '.skp-g{display:block;height:25px;line-height:25px;font-size:21px;max-width:100%;white-space:nowrap;overflow:hidden;font-family:"Noto Sans Math","Noto Sans Symbols 2","Noto Sans Symbols","Segoe UI Symbol","Apple Symbols","Cambria Math","Noto Sans Oriya","Noto Sans",system-ui,sans-serif}',
    '.skp-g.lb{font-size:10px;font-weight:700;letter-spacing:.03em;color:var(--acc);font-family:system-ui,sans-serif}',
    '.skp-n{display:-webkit-box;-webkit-box-orient:vertical;-webkit-line-clamp:3;overflow:hidden;font-size:7.6px;line-height:9px;text-align:center;color:var(--mut);width:100%;overflow-wrap:break-word;word-break:normal}',
    '.skp-f{position:absolute;right:1px;top:0;width:13px;height:13px;line-height:13px;font-size:11px;text-align:center;color:var(--mut);opacity:0;border-radius:3px}',
    '.skp-c:hover .skp-f,.skp-f.on{opacity:1}.skp-f.on{color:#d19a1a}.skp-f:hover{color:#d19a1a;background:var(--hd)}',
    '.skp-ft{display:flex;align-items:center;gap:8px;padding:3px 10px;border-top:1px solid var(--line);background:var(--hd);color:var(--mut);font-size:10.5px;flex:none;min-height:20px}',
    '.skp-ft b{color:var(--fg);font-weight:650}.skp-ft .sp{flex:1}',
    '.skp-ft .ok{color:var(--acc);font-weight:650}',
    '.skp-none{padding:24px 10px;text-align:center;color:var(--mut)}',
    '.skp-grip{position:absolute;right:0;bottom:0;width:16px;height:16px;cursor:nwse-resize;opacity:.6;background:linear-gradient(135deg,transparent 0 55%,var(--mut) 55% 60%,transparent 60% 72%,var(--mut) 72% 77%,transparent 77%)}',
    '.skp-dialog .skp-grip{display:none}',
    '.skp-tip{position:fixed;z-index:2147483100;pointer-events:none;background:#101521;color:#f1f4fb;border-radius:8px;padding:7px 10px;box-shadow:0 6px 22px rgba(0,0,0,.45);max-width:230px;font:11px/1.35 system-ui,sans-serif;display:flex;gap:9px;align-items:center}',
    '.skp-tip .tg{font-size:30px;line-height:1;min-width:34px;text-align:center;font-family:"Noto Sans Math","Noto Sans Symbols 2","Segoe UI Symbol","Apple Symbols",system-ui,sans-serif}',
    '.skp-tip .tg.lb{font-size:13px;font-weight:700;font-family:system-ui,sans-serif}',
    '.skp-tip b{display:block;font-size:12px}.skp-tip span{display:block;color:#b3bdd2}.skp-tip em{display:block;color:#7fd8c8;font-style:normal;font-size:10px;margin-top:2px}',
    '@media (max-width:520px){.skp-dialog{min-width:0}}'
  ].join('\n');

  function injectCss() {
    if (document.getElementById('skp-css')) { return; }
    var s = document.createElement('style'); s.id = 'skp-css'; s.textContent = CSS;
    (document.head || document.documentElement).appendChild(s);
  }

  var SVG = {
    pin: '<svg viewBox="0 0 24 24"><path class="fill" d="M9 3h6l-1 6 3 3v2h-4v6l-1 1-1-1v-6H7v-2l3-3z"/></svg>',
    close: '<svg viewBox="0 0 24 24"><path d="M6 6l12 12M18 6L6 18"/></svg>'
  };

  /* ---------- the host: how a palette talks to the program around it ---------- */
  function post(obj) {
    var j = JSON.stringify(obj);
    try { if (root.webkit && root.webkit.messageHandlers && root.webkit.messageHandlers.palette) { root.webkit.messageHandlers.palette.postMessage(j); return true; } } catch (e) {}
    try { if (root.chrome && root.chrome.webview) { root.chrome.webview.postMessage(j); return true; } } catch (e2) {}
    return false;
  }
  function lsGet(k) { try { return root.localStorage.getItem(k); } catch (e) { return null; } }
  function lsSet(k, v) { try { root.localStorage.setItem(k, v); } catch (e) {} }

  /* ---------- text boxes of a web page ---------- */
  var TEXTTYPES = /^(text|search|url|tel|email|number|password|)$/i;
  function isEditable(el) {
    if (!el || el.nodeType !== 1) { return false; }
    var tn = el.tagName;
    if (tn === 'TEXTAREA') { return !el.readOnly && !el.disabled; }
    if (tn === 'INPUT') { return TEXTTYPES.test(el.type || '') && !el.readOnly && !el.disabled; }
    if (el.isContentEditable) { return true; }
    return (el.getAttribute && el.getAttribute('role') === 'textbox');
  }

  function copyText(s) {
    try {
      if (root.navigator && navigator.clipboard && navigator.clipboard.writeText) {
        return navigator.clipboard.writeText(s).then(function () { return true; }, function () { return legacyCopy(s); });
      }
    } catch (e) {}
    return Promise.resolve(legacyCopy(s));
  }
  function legacyCopy(s) {
    var ta = document.createElement('textarea'), keep = document.activeElement, ok = false;
    ta.value = s; ta.setAttribute('readonly', ''); ta.style.cssText = 'position:fixed;left:-9999px;top:0;opacity:0';
    document.body.appendChild(ta); ta.select();
    try { ok = document.execCommand('copy'); } catch (e) {}
    document.body.removeChild(ta);
    try { if (keep && keep.focus) { keep.focus({ preventScroll: true }); } } catch (e2) {}
    return ok;
  }

  /* ---------- mount ---------- */
  var instance = null;

  function mount(opts) {
    opts = opts || {};
    if (instance) { return instance; }
    injectCss();
    var mode = opts.mode === 'window' ? 'window' : 'dialog';
    var pre = opts.storagePrefix || 'skPalette.';
    var state = { q: '', fav: [], recent: [], pinned: false, open: false, searching: false, toastT: 0 };
    var targetEl = null;            /* the text box that had the focus last (dialog mode) */
    var el = document.createElement('div');
    el.className = 'skp ' + (mode === 'window' ? 'skp-window' : 'skp-dialog');
    el.setAttribute('role', 'dialog'); el.setAttribute('aria-label', 'Unicode symbols');
    el.hidden = true;

    el.innerHTML =
      '<div class="skp-hd"><span class="skp-ttl">Symbols</span>' +
      '<input class="skp-q" type="search" placeholder="Search name or U+code" aria-label="Search symbols" autocomplete="off" spellcheck="false">' +
      '<button type="button" class="skp-b skp-pin" title="Pin: stay open when you click elsewhere" aria-label="Pin" aria-pressed="false">' + SVG.pin + '</button>' +
      '<button type="button" class="skp-b skp-x" title="Close (' + esc(opts.shortcutLabel || 'Esc') + ')" aria-label="Close">' + SVG.close + '</button></div>' +
      '<div class="skp-body" tabindex="-1"></div>' +
      '<div class="skp-ft"><span class="skp-st">Click a symbol to type it &middot; Shift+click copies &middot; right-click = favourite</span><span class="sp"></span><span class="skp-cnt"></span></div>' +
      (mode === 'window' ? '<div class="skp-grip" aria-hidden="true"></div>' : '');
    var hd = el.querySelector('.skp-hd'), qEl = el.querySelector('.skp-q'), body = el.querySelector('.skp-body'),
        pinB = el.querySelector('.skp-pin'), xB = el.querySelector('.skp-x'), stEl = el.querySelector('.skp-st'),
        cntEl = el.querySelector('.skp-cnt'), grip = el.querySelector('.skp-grip');
    var tip = document.createElement('div'); tip.className = 'skp-tip'; tip.hidden = true;
    var host = document.body;
    host.appendChild(el); host.appendChild(tip);

    var defaultSt = stEl.textContent;

    /* ----- persistence ----- */
    function load(k, d) { var v = lsGet(pre + k); if (v == null) { return d; } try { return JSON.parse(v); } catch (e) { return d; } }
    function save(k, v) { lsSet(pre + k, JSON.stringify(v)); if (mode === 'window') { post({ t: 'pal-save', k: k, v: JSON.stringify(v) }); } }
    state.fav = clean(load('fav', []), FAV_MAX); state.recent = clean(load('recent', []), RECENT_MAX); state.pinned = !!load('pin', false);
    function clean(a, max) { var o = []; if (a && a.length) { a.forEach(function (c) { if (BYCP[c] && o.indexOf(c) < 0 && o.length < max) { o.push(c); } }); } return o; }

    /* ----- theme ----- */
    function isDark() {
      var r = document.documentElement, t = (r.getAttribute('data-theme') || (document.body && document.body.getAttribute('data-theme')) || '').toLowerCase();
      if (t === 'dark') { return true; } if (t === 'light') { return false; }
      try { return !!(root.matchMedia && root.matchMedia('(prefers-color-scheme: dark)').matches); } catch (e) { return false; }
    }
    function applyTheme() { el.setAttribute('data-skt', opts.theme || (isDark() ? 'dark' : 'light')); }

    /* ----- rendering ----- */
    function cellHtml(cat, it) {
      var g = glyphOf(cat, it), fav = state.fav.indexOf(it[0]) >= 0;
      return '<button type="button" class="skp-c" data-cp="' + it[0] + '" aria-label="' + esc(it[1] + ', U+' + hex(it[0])) + '">' +
        '<span class="skp-f' + (fav ? ' on' : '') + '" data-fav="1" aria-hidden="true">' + (fav ? '★' : '☆') + '</span>' +
        '<span class="skp-g' + (g.label ? ' lb' : '') + '">' + esc(g.text) + '</span><span class="skp-n">' + esc(it[1]) + '</span></button>';
    }
    function rowHtml(title, count, cells, id) {
      return '<section class="skp-row" data-row="' + id + '"><div class="skp-rh">' + esc(title) + ' <i>' + count + '</i></div><div class="skp-strip">' + cells + '</div></section>';
    }
    function render(keepScroll) {
      var top = body.scrollTop, strips = {};
      if (keepScroll) { [].forEach.call(body.querySelectorAll('.skp-row'), function (r) { strips[r.getAttribute('data-row')] = r.querySelector('.skp-strip').scrollLeft; }); }
      var t = tokens(state.q), out = '', shown = 0, rows = 0;
      function part(title, id, list, catOf) {
        var cells = '', n = 0;
        list.forEach(function (it) { if (!t.length || matches(it, t)) { cells += cellHtml(catOf(it), it); n++; } });
        if (n) { out += rowHtml(title, n, cells, id); rows++; }
        return n;
      }
      var favItems = state.fav.map(function (c) { return BYCP[c]; }).filter(Boolean);
      var recItems = state.recent.map(function (c) { return BYCP[c]; }).filter(Boolean);
      if (favItems.length) { part('★ Favourites', 'fav', favItems, function (it) { return it.cat; }); }
      if (recItems.length) { part('Recent', 'recent', recItems, function (it) { return it.cat; }); }
      DATA.cats.forEach(function (c) { shown += part(c.title, c.id, c.items, function () { return c; }); });
      if (!shown) { out = '<div class="skp-none">No symbol matches &ldquo;' + esc(state.q) + '&rdquo;.<br>Try a name (arrow, alpha), a code (U+2192 or 2192) or paste the symbol.</div>'; }
      body.innerHTML = out;
      cntEl.textContent = (t.length ? shown + ' found' : ALL.length + ' symbols') + ' · ' + rows + ' rows';
      if (keepScroll) {
        body.scrollTop = top;
        [].forEach.call(body.querySelectorAll('.skp-row'), function (r) { var s = strips[r.getAttribute('data-row')]; if (s) { r.querySelector('.skp-strip').scrollLeft = s; } });
      }
    }

    function status(msg, ok) {
      stEl.innerHTML = ok ? '<span class="ok">' + esc(msg) + '</span>' : esc(msg);
      clearTimeout(state.toastT);
      state.toastT = setTimeout(function () { stEl.textContent = defaultSt; }, 1800);
    }

    /* ----- favourites / recent ----- */
    function toggleFav(cp) {
      var i = state.fav.indexOf(cp);
      if (i >= 0) { state.fav.splice(i, 1); } else { state.fav.unshift(cp); state.fav = state.fav.slice(0, FAV_MAX); }
      save('fav', state.fav); render(true);
      status(i >= 0 ? 'Removed from favourites' : 'Added to favourites', true);
    }
    function pushRecent(cp) {
      var i = state.recent.indexOf(cp); if (i >= 0) { state.recent.splice(i, 1); }
      state.recent.unshift(cp); state.recent = state.recent.slice(0, RECENT_MAX); save('recent', state.recent);
    }

    /* ----- putting a character in ----- */
    function describe(cp) { return (isMark(cp) ? NBSP : '') + cpStr(cp).replace(/[\u0000-\u001f\u007f\u200B-\u200F\u2060\uFEFF]/g, '') + ' U+' + hex(cp); }
    function done(cp, how) {
      if (how === 'inserted') { pushRecent(cp); status('Typed ' + describe(cp), true); }
      else if (how === 'copied') { pushRecent(cp); status('Copied ' + describe(cp) + ' — paste it where you need it', true); }
      else { status('Could not type or copy ' + describe(cp), false); }
      renderRecentOnly();
    }
    var recentTimer = 0;
    function renderRecentOnly() { clearTimeout(recentTimer); recentTimer = setTimeout(function () { if (state.open) { render(true); } }, 350); }

    function webTarget() {
      var a = document.activeElement;
      if (a && !el.contains(a) && isEditable(a)) { return a; }
      if (a && el.contains(a) && targetEl && targetEl.isConnected !== false && isEditable(targetEl)) { return targetEl; }
      if (state.pinned && targetEl && targetEl.isConnected !== false && isEditable(targetEl) && (!a || a === document.body)) { return targetEl; }
      return null;
    }
    function insertInto(t, s) {
      var ok = false;
      if (opts.insertHook) { try { if (opts.insertHook(s, t) === true) { return true; } } catch (e) {} }
      try { t.focus({ preventScroll: true }); } catch (e1) {}
      if (t.tagName === 'INPUT' || t.tagName === 'TEXTAREA') {
        var a = t.selectionStart, b = t.selectionEnd;
        try { ok = document.execCommand('insertText', false, s); } catch (e2) { ok = false; }
        if (!ok && typeof a === 'number') {
          try {
            t.setRangeText(s, a, b, 'end');
            t.dispatchEvent(new Event('input', { bubbles: true })); ok = true;
          } catch (e3) { ok = false; }
        }
      } else {
        try { ok = document.execCommand('insertText', false, s); } catch (e4) { ok = false; }
      }
      return ok;
    }
    function choose(cp, copyOnly) {
      var s = cpStr(cp);
      if (mode === 'window') {
        if (!post({ t: 'pal-ins', s: s, cp: cp, copyOnly: !!copyOnly })) { copyText(s).then(function (ok) { done(cp, ok ? 'copied' : 'failed'); }); }
        else { state.pendingCp = cp; }
        return;
      }
      var t = copyOnly ? null : webTarget();
      if (t && insertInto(t, s)) { done(cp, 'inserted'); return; }
      Promise.resolve(copyText(s)).then(function (ok) { done(cp, ok ? 'copied' : 'failed'); });
    }

    /* ----- tooltip (also driven by native hover for windows that never see mouse-move) ----- */
    var tipCell = null, tipTimer = 0;
    function showTip(c) {
      if (!c) { hideTip(); return; }
      if (tipCell === c) { return; }
      tipCell = c; clearTimeout(tipTimer);
      tipTimer = setTimeout(function () {
        var it = BYCP[+c.getAttribute('data-cp')]; if (!it) { return; }
        var g = glyphOf(it.cat, it), full = unameOf(it);
        tip.innerHTML = '<div class="tg' + (g.label ? ' lb' : '') + '">' + esc(g.text) + '</div><div><b>U+' + hex(it[0]) + '</b><span>' + esc(full) + '</span><em>' +
          esc(it.cat.title) + ' · click types it, Shift+click copies</em></div>';
        tip.hidden = false;
        var r = c.getBoundingClientRect(), tw = tip.offsetWidth, th = tip.offsetHeight, vw = root.innerWidth, vh = root.innerHeight;
        var x = Math.max(4, Math.min(r.left + r.width / 2 - tw / 2, vw - tw - 4)), y = r.bottom + 6;
        if (y + th > vh - 4) { y = Math.max(4, r.top - th - 6); }
        tip.style.left = x + 'px'; tip.style.top = y + 'px';
      }, 260);
    }
    function hideTip() { clearTimeout(tipTimer); tipCell = null; tip.hidden = true; }
    function unameOf(it) {
      /* the Unicode name as published is not kept in the data: the shown name is the readable form */
      return it[1];
    }

    /* ----- events ----- */
    body.addEventListener('mousedown', function (e) { e.preventDefault(); });          /* a click on a symbol never takes the focus from the text box */
    body.addEventListener('click', function (e) {
      var f = e.target.closest && e.target.closest('[data-fav]');
      var c = e.target.closest && e.target.closest('.skp-c'); if (!c) { return; }
      var cp = +c.getAttribute('data-cp');
      if (f) { toggleFav(cp); return; }
      choose(cp, e.shiftKey);
    });
    body.addEventListener('contextmenu', function (e) {
      var c = e.target.closest && e.target.closest('.skp-c'); if (!c) { return; }
      e.preventDefault(); toggleFav(+c.getAttribute('data-cp'));
    });
    var lpT = 0;
    body.addEventListener('touchstart', function (e) { var c = e.target.closest && e.target.closest('.skp-c'); if (!c) { return; } clearTimeout(lpT); lpT = setTimeout(function () { toggleFav(+c.getAttribute('data-cp')); c.setAttribute('data-lp', '1'); }, 600); }, { passive: true });
    ['touchend', 'touchmove', 'touchcancel'].forEach(function (n) { body.addEventListener(n, function () { clearTimeout(lpT); }, { passive: true }); });
    body.addEventListener('mouseover', function (e) { showTip(e.target.closest && e.target.closest('.skp-c')); });
    body.addEventListener('mouseleave', hideTip);
    body.addEventListener('scroll', hideTip, true);
    body.addEventListener('keydown', function (e) {
      var c = document.activeElement; if (!c || !c.classList || !c.classList.contains('skp-c')) { return; }
      var nx = null;
      if (e.key === 'ArrowRight') { nx = c.nextElementSibling; } else if (e.key === 'ArrowLeft') { nx = c.previousElementSibling; }
      else if (e.key === 'ArrowDown' || e.key === 'ArrowUp') {
        var row = c.closest('.skp-row'), r2 = e.key === 'ArrowDown' ? row.nextElementSibling : row.previousElementSibling;
        if (r2) { var idx = [].indexOf.call(c.parentNode.children, c); nx = r2.querySelector('.skp-strip').children[idx] || r2.querySelector('.skp-strip').lastElementChild; }
      }
      if (nx && nx.classList && nx.classList.contains('skp-c')) { e.preventDefault(); nx.focus(); nx.scrollIntoView({ block: 'nearest', inline: 'nearest' }); }
    });

    qEl.addEventListener('input', function () { state.q = qEl.value; render(false); body.scrollTop = 0; });
    qEl.addEventListener('keydown', function (e) {
      if (e.key === 'Escape') { e.preventDefault(); if (qEl.value) { qEl.value = ''; state.q = ''; render(false); } else { api.close(); } e.stopPropagation(); }
      else if (e.key === 'Enter') {
        var t = tokens(state.q), first = null; if (t.length) { for (var i = 0; i < ALL.length; i++) { if (matches(ALL[i], t)) { first = ALL[i]; break; } } }
        if (first) { e.preventDefault(); choose(first[0], e.shiftKey); }
      } else if (e.key === 'ArrowDown') { var c0 = body.querySelector('.skp-c'); if (c0) { e.preventDefault(); c0.focus(); } }
    });
    el.addEventListener('keydown', function (e) {
      if (e.key === 'Escape' && e.target !== qEl) { e.preventDefault(); api.close(); }
      else if (e.key === '/' && e.target !== qEl) { e.preventDefault(); qEl.focus(); qEl.select(); }
    });

    pinB.addEventListener('click', function () { api.setPinned(!state.pinned, true); });
    xB.addEventListener('click', function () { api.close(); });
    [pinB, xB].forEach(function (b) { b.addEventListener('mousedown', function (e) { e.preventDefault(); }); });

    /* the search box in a native window cannot take the focus: the native side forwards the typing (see native.key) */
    if (mode === 'window') {
      qEl.readOnly = true; qEl.setAttribute('inputmode', 'none');
      qEl.addEventListener('mousedown', function (e) { e.preventDefault(); setSearching(true); });
    }
    function setSearching(on) {
      if (state.searching === on) { return; }
      state.searching = on; qEl.classList.toggle('on', on);
      qEl.placeholder = on ? 'Type to search — Esc ends' : 'Search name or U+code';
      post({ t: 'pal-search', on: on });
    }

    /* ----- dragging (header) ----- */
    var drag = null;
    hd.addEventListener('pointerdown', function (e) {
      if (e.target.closest('.skp-b') || e.target === qEl) { return; }
      if (mode === 'window') { post({ t: 'pal-drag', s: 1 }); drag = { win: true }; try { hd.setPointerCapture(e.pointerId); } catch (x) {} e.preventDefault(); return; }
      var r = el.getBoundingClientRect();
      drag = { dx: e.clientX - r.left, dy: e.clientY - r.top };
      try { hd.setPointerCapture(e.pointerId); } catch (x2) {}
      e.preventDefault();
    });
    hd.addEventListener('pointermove', function (e) {
      if (!drag) { return; }
      if (drag.win) { post({ t: 'pal-drag', s: 2 }); return; }
      var x = Math.max(-el.offsetWidth + 60, Math.min(e.clientX - drag.dx, root.innerWidth - 60));
      var y = Math.max(0, Math.min(e.clientY - drag.dy, root.innerHeight - 30));
      el.style.left = x + 'px'; el.style.top = y + 'px'; el.style.right = 'auto'; el.style.bottom = 'auto';
    });
    function endDrag() { if (!drag) { return; } if (drag.win) { post({ t: 'pal-drag', s: 0 }); } else { saveGeom(); } drag = null; }
    hd.addEventListener('pointerup', endDrag); hd.addEventListener('pointercancel', endDrag);
    if (grip) {
      var rs = false;
      grip.addEventListener('pointerdown', function (e) { rs = true; post({ t: 'pal-size', s: 1 }); try { grip.setPointerCapture(e.pointerId); } catch (x) {} e.preventDefault(); });
      grip.addEventListener('pointermove', function () { if (rs) { post({ t: 'pal-size', s: 2 }); } });
      var re = function () { if (rs) { rs = false; post({ t: 'pal-size', s: 0 }); } };
      grip.addEventListener('pointerup', re); grip.addEventListener('pointercancel', re);
    }

    /* ----- geometry of the dialog ----- */
    function saveGeom() { if (mode !== 'dialog' || !state.open) { return; } var r = el.getBoundingClientRect(); if (r.width < 200 || r.height < 120) { return; } save('geom', { x: Math.round(r.left), y: Math.round(r.top), w: Math.round(r.width), h: Math.round(r.height) }); }
    function placeDialog() {
      var g = load('geom', null); if (g && !(g.w >= 280 && g.h >= 200)) { g = null; } var vw = root.innerWidth, vh = root.innerHeight;
      var w = g && g.w ? g.w : Math.min(600, vw - 16), h = g && g.h ? g.h : Math.min(430, vh - 24);
      w = Math.max(280, Math.min(w, vw - 8)); h = Math.max(200, Math.min(h, vh - 8));
      var x = g ? g.x : Math.max(8, vw - w - 24), y = g ? g.y : Math.max(8, Math.min(84, vh - h - 8));
      x = Math.max(-w + 80, Math.min(x, vw - 80)); y = Math.max(0, Math.min(y, vh - 40));
      el.style.width = w + 'px'; el.style.height = h + 'px'; el.style.left = x + 'px'; el.style.top = y + 'px';
    }
    var ro = null;
    if (mode === 'dialog' && root.ResizeObserver) {
      var rt = 0; ro = new ResizeObserver(function () { if (!state.open) { return; } clearTimeout(rt); rt = setTimeout(saveGeom, 250); }); ro.observe(el);
    }

    /* ----- outside clicks, focus tracking (dialog) ----- */
    function onDocDown(e) {
      if (!state.open) { return; }
      var t = e.target;
      if (el.contains(t) || tip.contains(t)) { return; }
      if (opts.toggleEl && opts.toggleEl.contains && opts.toggleEl.contains(t)) { return; }
      if (isEditable(t) || (t.closest && t.closest('[role=textbox]'))) { targetEl = t.closest('[role=textbox]') || t; } else { targetEl = null; }
      if (!state.pinned) { api.close(); }
    }
    function onFocusIn(e) { var t = e.target; if (el.contains(t)) { return; } if (isEditable(t)) { targetEl = t; } }
    if (mode === 'dialog') { document.addEventListener('pointerdown', onDocDown, true); document.addEventListener('focusin', onFocusIn, true); }
    root.addEventListener('blur', function () { /* a click into an iframe or another window counts as "outside" */
      if (mode === 'dialog' && state.open && !state.pinned && document.activeElement && document.activeElement.tagName === 'IFRAME') { api.close(); }
    });

    function setPinnedUi() {
      pinB.classList.toggle('on', state.pinned); pinB.setAttribute('aria-pressed', state.pinned ? 'true' : 'false');
      pinB.title = state.pinned ? 'Unpin: close when you click elsewhere' : 'Pin: stay open when you click elsewhere';
    }

    /* ----- the API ----- */
    var api = {
      el: el, mode: mode,
      isOpen: function () { return state.open; },
      open: function () {
        if (state.open) { return; }
        var a = document.activeElement; if (a && !el.contains(a) && isEditable(a)) { targetEl = a; }
        applyTheme(); render(false); setPinnedUi();
        el.hidden = false; state.open = true;
        if (mode === 'dialog') { placeDialog(); }
        if (opts.onOpen) { opts.onOpen(); }
      },
      close: function () {
        if (!state.open) { return; }
        if (mode === 'dialog') { saveGeom(); }
        state.open = false; el.hidden = true; hideTip(); setSearching(false);
        if (mode === 'dialog') { var t = targetEl; if (t && t.isConnected !== false && isEditable(t)) { try { t.focus({ preventScroll: true }); } catch (e) {} } }
        else { post({ t: 'pal-hide' }); }
        if (opts.onClose) { opts.onClose(); }
      },
      toggle: function () { if (state.open) { api.close(); } else { api.open(); } },
      setPinned: function (on, fromUi) {
        state.pinned = !!on; save('pin', state.pinned); setPinnedUi();
        if (mode === 'window' && fromUi) { post({ t: 'pal-pin', on: state.pinned }); }
      },
      isPinned: function () { return state.pinned; },
      search: search,
      destroy: function () {
        document.removeEventListener('pointerdown', onDocDown, true); document.removeEventListener('focusin', onFocusIn, true);
        if (ro) { ro.disconnect(); } el.remove(); tip.remove(); instance = null;
      }
    };
    instance = api;

    /* ----- the native side drives these (window mode) ----- */
    SKPalette.native = {
      result: function (how) { var cp = state.pendingCp; state.pendingCp = 0; if (cp) { done(cp, how); } },
      restore: function (o) {
        if (!o) { return; }
        if (o.fav) { state.fav = clean(o.fav, FAV_MAX); lsSet(pre + 'fav', JSON.stringify(state.fav)); }
        if (o.recent) { state.recent = clean(o.recent, RECENT_MAX); lsSet(pre + 'recent', JSON.stringify(state.recent)); }
        if (typeof o.pin === 'boolean') { state.pinned = o.pin; setPinnedUi(); }
        if (state.open) { render(true); }
      },
      pinned: function (on) { state.pinned = !!on; setPinnedUi(); },
      shown: function () { applyTheme(); state.open = true; el.hidden = false; qEl.value = ''; state.q = ''; setSearching(false); render(false); setPinnedUi(); body.scrollTop = 0; },
      hidden: function () { state.open = false; hideTip(); state.searching = false; qEl.classList.remove('on'); qEl.placeholder = 'Search name or U+code'; },
      searchEnded: function () { state.searching = false; qEl.classList.remove('on'); qEl.placeholder = 'Search name or U+code'; },
      key: function (k) {                                   /* typing forwarded by the native side while the search box is active */
        if (!state.searching) { return; }
        if (k === 'Backspace') { qEl.value = qEl.value.slice(0, -1); }
        else if (k === 'Escape') { if (qEl.value) { qEl.value = ''; } else { setSearching(false); return; } }
        else if (k === 'Enter') { var t = tokens(state.q); if (t.length) { for (var i = 0; i < ALL.length; i++) { if (matches(ALL[i], t)) { choose(ALL[i][0], false); break; } } } return; }
        else if (k.length) { qEl.value += k; }
        state.q = qEl.value; render(false); body.scrollTop = 0;
      },
      hover: function (x, y) { var n = document.elementFromPoint(x, y); showTip(n && n.closest ? n.closest('.skp-c') : null); },
      hoverLeave: function () { hideTip(); }
    };
    if (mode === 'window') { post({ t: 'pal-ready' }); }
    return api;
  }

  /* Shortcut helper for web pages: Alt (Option on a Mac) + comma, or Ctrl+Alt + comma, shows or hides the palette. */
  function installShortcut(inst, extra) {
    function onKey(e) {
      if (e.code !== 'Comma' && e.key !== ',' && e.key !== '≤') { return; }
      if (e.code && e.code !== 'Comma') { return; }
      var alt = e.altKey && !e.metaKey && !e.shiftKey;
      if (!alt) { return; }
      e.preventDefault(); e.stopPropagation(); inst.toggle();
    }
    document.addEventListener('keydown', onKey, true);
    return function () { document.removeEventListener('keydown', onKey, true); };
  }

  var SKPalette = {
    version: 1, data: DATA, all: ALL, byCp: BYCP, mount: mount, installShortcut: installShortcut, search: search,
    glyphOf: glyphOf, hex: hex, isMark: isMark, native: null, instance: function () { return instance; }
  };
  root.SKPalette = SKPalette;
})(typeof window !== 'undefined' ? window : this);
