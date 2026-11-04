package com.saisudeep.sulekhak;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.RectF;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.os.Build;
import android.os.VibrationEffect;
import android.os.Vibrator;
import android.text.Layout;
import android.text.StaticLayout;
import android.text.TextPaint;
import android.view.Gravity;
import android.view.GestureDetector;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.widget.LinearLayout;
import android.widget.OverScroller;
import android.widget.ScrollView;
import android.widget.TextView;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.InputStream;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

/**
 * The Unicode symbols page of the keyboard (reached with the Ω key on the ?123 page): every category in its own row, each row scrolling sideways on its own,
 * with the symbol large and its name under it. A tap puts the real character at the caret of the text box (a selection is replaced) or, when there is no
 * text box, copies it to the clipboard; a long press adds or removes a favourite. Search (names and U+ codes) uses a small keypad of its own, because
 * a view inside a keyboard cannot take the text focus. The data (palette.json) is the same list the web, Mac and Windows palettes use.
 * Combining marks are drawn on a no-break space here and are always inserted alone: no dotted circle is ever typed.
 */
final class SymbolPage extends LinearLayout {
    /** What the keyboard does with a chosen symbol, and the other buttons of the page. */
    interface Host {
        /** @return 1 typed at the caret, 2 copied to the clipboard, 0 failed */
        int onSymbol(String text);
        void onBack();            // the letters keyboard again
        void onBackspace();
        void onSpace();
        int dp(int v);
    }

    private static final String NBSP = " ";

    static final class Item {
        final int cp; final String name; final String abbr; final String cat; String search;
        Item(int cp, String name, String abbr, String cat) { this.cp = cp; this.name = name; this.abbr = abbr; this.cat = cat; }
        String shown() {
            if (abbr != null) return abbr;
            String s = new String(Character.toChars(cp));
            int t = Character.getType(cp);
            if (t == Character.NON_SPACING_MARK || t == Character.COMBINING_SPACING_MARK || t == Character.ENCLOSING_MARK) return NBSP + s;
            return s;
        }
        String text() { return new String(Character.toChars(cp)); }
        String hex() { String h = Integer.toHexString(cp).toUpperCase(Locale.ROOT); while (h.length() < 4) h = "0" + h; return h; }
    }

    private final Host host;
    private final android.content.SharedPreferences prefs;
    private final List<String> catIds = new ArrayList<>(), catTitles = new ArrayList<>();
    private final List<List<Item>> catItems = new ArrayList<>();
    private final Map<Integer, Item> byCp = new HashMap<>();
    private final List<Item> all = new ArrayList<>();
    private final ArrayList<Integer> fav = new ArrayList<>(), recent = new ArrayList<>();
    private int cBg = Color.WHITE, cKey = 0xFFEEEEEE, cText = Color.BLACK, cHint = 0xFF666666, cAccent = 0xFF1F6F64;
    private LinearLayout browse, searchBox, rowsBox;
    private ScrollView scroll;
    private TextView status, query, back;
    private RowStrip results;
    private final StringBuilder q = new StringBuilder();
    private boolean searching, loaded;
    private final List<RowStrip> strips = new ArrayList<>();
    private final List<TextView> titles = new ArrayList<>();

    SymbolPage(Context ctx, Host host, android.content.SharedPreferences prefs) {
        super(ctx);
        this.host = host; this.prefs = prefs;
        setOrientation(VERTICAL);
        loadData();
        loadLists();
        build();
    }

    // ------------------------------------------------------------------ data
    private void loadData() {
        try {
            InputStream in = getContext().getAssets().open("sulekhak/palette.json");
            byte[] b = new byte[in.available()];
            int n = 0; while (n < b.length) { int r = in.read(b, n, b.length - n); if (r < 0) break; n += r; }
            in.close();
            JSONObject o = new JSONObject(new String(b, 0, n, "UTF-8"));
            JSONArray cats = o.getJSONArray("cats");
            for (int i = 0; i < cats.length(); i++) {
                JSONObject c = cats.getJSONObject(i);
                String id = c.getString("id"), title = c.getString("title");
                JSONArray items = c.getJSONArray("items");
                List<Item> list = new ArrayList<>();
                for (int j = 0; j < items.length(); j++) {
                    JSONArray it = items.getJSONArray(j);
                    Item x = new Item(it.getInt(0), it.getString(1), it.length() > 2 ? it.getString(2) : null, title);
                    x.search = (x.name + " u+" + x.hex() + " " + x.hex() + " " + (x.abbr == null ? "" : x.abbr) + " " + title + " " + x.text()).toLowerCase(Locale.ROOT);
                    list.add(x); all.add(x);
                    if (!byCp.containsKey(x.cp)) byCp.put(x.cp, x);
                }
                catIds.add(id); catTitles.add(title); catItems.add(list);
            }
            loaded = !all.isEmpty();
        } catch (Exception e) { loaded = false; }
    }

    private void loadLists() {
        readList("pal_fav", fav); readList("pal_recent", recent);
    }
    private void readList(String key, ArrayList<Integer> to) {
        to.clear();
        String s = prefs.getString(key, "");
        if (s == null || s.isEmpty()) return;
        for (String p : s.split(",")) { try { int cp = Integer.parseInt(p, 16); if (byCp.containsKey(cp) && !to.contains(cp)) to.add(cp); } catch (Exception ignored) { } }
    }
    private void writeList(String key, List<Integer> l) {
        StringBuilder sb = new StringBuilder();
        for (int cp : l) { if (sb.length() > 0) sb.append(','); sb.append(Integer.toHexString(cp)); }
        prefs.edit().putString(key, sb.toString()).apply();
    }

    // ------------------------------------------------------------------ layout
    private TextView button(String label, final Runnable r) {
        TextView t = new TextView(getContext());
        t.setText(label); t.setGravity(Gravity.CENTER); t.setTextSize(15); t.setTypeface(Typeface.DEFAULT_BOLD);
        t.setMinWidth(host.dp(46));
        t.setPadding(host.dp(8), 0, host.dp(8), 0);
        t.setOnTouchListener(new OnTouchListener() {
            private boolean down;
            public boolean onTouch(View v, MotionEvent e) {
                switch (e.getActionMasked()) {
                    case MotionEvent.ACTION_DOWN: down = true; v.setAlpha(0.6f); return true;
                    case MotionEvent.ACTION_UP: v.setAlpha(1f); if (down && e.getX() >= -host.dp(10) && e.getX() <= v.getWidth() + host.dp(10) && e.getY() >= -host.dp(10) && e.getY() <= v.getHeight() + host.dp(10)) r.run(); down = false; return true;
                    case MotionEvent.ACTION_CANCEL: v.setAlpha(1f); down = false; return true;
                }
                return true;
            }
        });
        return t;
    }

    private void build() {
        removeAllViews();
        strips.clear(); titles.clear();
        LinearLayout bar = new LinearLayout(getContext());
        bar.setOrientation(HORIZONTAL); bar.setGravity(Gravity.CENTER_VERTICAL);
        back = button("ABC", new Runnable() { public void run() { host.onBack(); } });
        TextView search = button("🔍", new Runnable() { public void run() { setSearching(!searching); } });
        status = new TextView(getContext());
        status.setTextSize(12); status.setGravity(Gravity.CENTER_VERTICAL); status.setSingleLine(true);
        status.setText("Tap: type · long press: favourite");
        TextView bs = button("⌫", new Runnable() { public void run() { host.onBackspace(); } });
        TextView sp = button("␣", new Runnable() { public void run() { host.onSpace(); } });
        bar.addView(back, new LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.MATCH_PARENT));
        bar.addView(search, new LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.MATCH_PARENT));
        LayoutParams slp = new LayoutParams(0, ViewGroup.LayoutParams.MATCH_PARENT, 1f); slp.leftMargin = host.dp(6);
        bar.addView(status, slp);
        bar.addView(sp, new LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.MATCH_PARENT));
        bar.addView(bs, new LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.MATCH_PARENT));
        addView(bar, new LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, host.dp(40)));

        browse = new LinearLayout(getContext());
        browse.setOrientation(VERTICAL);
        scroll = new ScrollView(getContext());
        scroll.setVerticalScrollBarEnabled(false);
        scroll.setOverScrollMode(OVER_SCROLL_NEVER);
        rowsBox = new LinearLayout(getContext());
        rowsBox.setOrientation(VERTICAL);
        scroll.addView(rowsBox, new ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));
        browse.addView(scroll, new LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));
        addView(browse, new LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 0, 1f));

        searchBox = new LinearLayout(getContext());
        searchBox.setOrientation(VERTICAL);
        searchBox.setVisibility(GONE);
        query = new TextView(getContext());
        query.setTextSize(15); query.setSingleLine(true); query.setGravity(Gravity.CENTER_VERTICAL);
        query.setPadding(host.dp(10), 0, host.dp(10), 0);
        searchBox.addView(query, new LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, host.dp(30)));
        results = new RowStrip(getContext());
        searchBox.addView(results, new LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, host.dp(66)));
        searchBox.addView(keypad(), new LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 0, 1f));
        addView(searchBox, new LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 0, 1f));
        fillRows();
        applyColors();
    }

    private LinearLayout keypad() {
        LinearLayout pad = new LinearLayout(getContext());
        pad.setOrientation(VERTICAL);
        String[] rows = {"1234567890", "qwertyuiop", "asdfghjkl+", "zxcvbnm-U"};
        for (String r : rows) {
            LinearLayout line = new LinearLayout(getContext());
            line.setOrientation(HORIZONTAL);
            for (int i = 0; i < r.length(); i++) {
                final String ch = String.valueOf(r.charAt(i));
                TextView k = button(ch.equals("U") ? "U+" : ch, new Runnable() { public void run() { q.append(ch.equals("U") ? "u+" : ch); updateSearch(); } });
                k.setMinWidth(0); k.setPadding(0, 0, 0, 0); k.setTextSize(14); k.setTag("key");
                LayoutParams lp = new LayoutParams(0, ViewGroup.LayoutParams.MATCH_PARENT, 1f); lp.setMargins(host.dp(1), host.dp(1), host.dp(1), host.dp(1));
                line.addView(k, lp);
            }
            if (r.startsWith("zxc")) {
                TextView del = button("⌫", new Runnable() { public void run() { if (q.length() > 0) q.setLength(q.length() - 1); updateSearch(); } });
                del.setMinWidth(0); del.setPadding(0, 0, 0, 0); del.setTag("key");
                LayoutParams lp = new LayoutParams(0, ViewGroup.LayoutParams.MATCH_PARENT, 1.4f); lp.setMargins(host.dp(1), host.dp(1), host.dp(1), host.dp(1));
                line.addView(del, lp);
            }
            pad.addView(line, new LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 0, 1f));
        }
        return pad;
    }

    private void fillRows() {
        rowsBox.removeAllViews(); strips.clear(); titles.clear();
        if (!loaded) {
            TextView t = new TextView(getContext()); t.setText("The symbol list could not be loaded."); t.setPadding(host.dp(12), host.dp(12), host.dp(12), host.dp(12));
            rowsBox.addView(t); titles.add(t); return;
        }
        addRow("★ Favourites", listOf(fav));
        addRow("Recent", listOf(recent));
        for (int i = 0; i < catIds.size(); i++) addRow(catTitles.get(i), catItems.get(i));
        applyColors();
    }

    private List<Item> listOf(List<Integer> cps) { List<Item> l = new ArrayList<>(); for (int cp : cps) { Item x = byCp.get(cp); if (x != null) l.add(x); } return l; }

    private void addRow(String title, List<Item> items) {
        if (items.isEmpty()) return;
        TextView t = new TextView(getContext());
        t.setText(title.toUpperCase(Locale.ROOT)); t.setTextSize(10); t.setTypeface(Typeface.DEFAULT_BOLD); t.setLetterSpacing(0.05f);
        t.setPadding(host.dp(10), host.dp(3), 0, 0);
        rowsBox.addView(t, new LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));
        RowStrip s = new RowStrip(getContext());
        s.setItems(items);
        rowsBox.addView(s, new LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, host.dp(60)));      // the cell is 56 dp tall: the vertical space between rows is kept small
        strips.add(s); titles.add(t);
    }

    // ------------------------------------------------------------------ search
    private void setSearching(boolean on) {
        searching = on;
        browse.setVisibility(on ? GONE : VISIBLE);
        searchBox.setVisibility(on ? VISIBLE : GONE);
        if (on) { q.setLength(0); updateSearch(); } else { fillRows(); }
    }

    private void updateSearch() {
        String s = q.toString().trim().toLowerCase(Locale.ROOT);
        query.setText(s.isEmpty() ? "Type a name (arrow, alpha) or a code (u+2192)" : s);
        query.setTextColor(s.isEmpty() ? cHint : cText);
        List<Item> out = new ArrayList<>();
        if (!s.isEmpty()) {
            String[] toks = s.split("\\s+");
            for (Item x : all) {
                boolean ok = true;
                for (String t : toks) if (!x.search.contains(t)) { ok = false; break; }
                if (ok) { out.add(x); if (out.size() >= 300) break; }
            }
        }
        results.setItems(out);
        results.scrollTo(0, 0);
        status.setText(s.isEmpty() ? "Search" : out.size() + " found");
    }

    // ------------------------------------------------------------------ colours
    void setColors(int bg, int key, int text, int hint, int accent) {
        cBg = bg; cKey = key; cText = text; cHint = hint; cAccent = accent;
        applyColors();
    }

    private void applyColors() {
        setBackgroundColor(cBg);
        if (status != null) { status.setTextColor(cHint); }
        if (back != null) back.setTextColor(cAccent);
        for (TextView t : titles) t.setTextColor(cHint);
        if (query != null) query.setTextColor(q.length() == 0 ? cHint : cText);
        for (int i = 0; i < getChildCount(); i++) tintButtons(getChildAt(i));
        for (RowStrip s : strips) s.invalidate();
        if (results != null) results.invalidate();
    }

    private void tintButtons(View v) {
        if (v instanceof TextView && v != status && v != query && !titles.contains(v)) {
            TextView t = (TextView) v;
            if (v == back) return;
            t.setTextColor(cText);
            if ("key".equals(v.getTag())) {
                GradientDrawable g = new GradientDrawable(); g.setColor(cKey); g.setCornerRadius(host.dp(6)); t.setBackground(g);
            }
        } else if (v instanceof ViewGroup && !(v instanceof RowStrip)) {
            ViewGroup g = (ViewGroup) v;
            for (int i = 0; i < g.getChildCount(); i++) tintButtons(g.getChildAt(i));
        }
    }

    /** The keyboard shows this page: back to the top, and the favourites and recent rows as they now are. */
    void onShown() {
        if (searching) setSearching(false); else fillRows();
        if (scroll != null) scroll.scrollTo(0, 0);
        status.setText("Tap: type · long press: favourite");
    }

    // ------------------------------------------------------------------ choosing
    private void chosen(Item x) {
        int how = host.onSymbol(x.text());
        if (how != 0) {
            recent.remove((Integer) x.cp); recent.add(0, x.cp);
            while (recent.size() > 30) recent.remove(recent.size() - 1);
            writeList("pal_recent", recent);
        }
        status.setText(how == 1 ? "Typed U+" + x.hex() : how == 2 ? "Copied U+" + x.hex() + " — paste it where you need it" : "Could not type or copy it");
    }

    private void toggleFavourite(Item x) {
        boolean had = fav.remove((Integer) x.cp);
        if (!had) { fav.add(0, x.cp); while (fav.size() > 200) fav.remove(fav.size() - 1); }
        writeList("pal_fav", fav);
        status.setText(had ? "Removed from favourites" : "Added to favourites");
        try {
            Vibrator v = (Vibrator) getContext().getSystemService(Context.VIBRATOR_SERVICE);
            if (v != null && v.hasVibrator()) v.vibrate(VibrationEffect.createOneShot(18, VibrationEffect.DEFAULT_AMPLITUDE));
        } catch (Exception ignored) { }
        if (!searching) { int y = scroll.getScrollY(); fillRows(); scroll.scrollTo(0, y); }
    }

    // ------------------------------------------------------------------ one row of cells that scrolls sideways by itself
    final class RowStrip extends View {
        private final TextPaint glyph = new TextPaint(Paint.ANTI_ALIAS_FLAG), name = new TextPaint(Paint.ANTI_ALIAS_FLAG), lab = new TextPaint(Paint.ANTI_ALIAS_FLAG);
        private final Paint fill = new Paint(Paint.ANTI_ALIAS_FLAG), line = new Paint(Paint.ANTI_ALIAS_FLAG), star = new Paint(Paint.ANTI_ALIAS_FLAG);
        private List<Item> items = new ArrayList<>();
        private final Map<Integer, StaticLayout> layouts = new HashMap<>();
        private final int cellW, cellH, gap, pad;
        private final OverScroller scroller;
        private final GestureDetector gd;
        private int pressed = -1;
        private boolean horizontal;

        RowStrip(Context c) {
            super(c);
            float d = c.getResources().getDisplayMetrics().density, sd = c.getResources().getDisplayMetrics().scaledDensity;
            cellW = (int) (52 * d); cellH = (int) (56 * d); gap = (int) (3 * d); pad = (int) (8 * d);
            glyph.setTextSize(21 * sd); glyph.setTextAlign(Paint.Align.CENTER);
            name.setTextSize(8 * sd);
            lab.setTextSize(10 * sd); lab.setTextAlign(Paint.Align.CENTER); lab.setTypeface(Typeface.DEFAULT_BOLD);
            line.setStyle(Paint.Style.STROKE); line.setStrokeWidth(Math.max(1f, d * 0.7f));
            scroller = new OverScroller(c);
            setHorizontalScrollBarEnabled(false);
            gd = new GestureDetector(c, new GestureDetector.SimpleOnGestureListener() {
                @Override public boolean onDown(MotionEvent e) { scroller.forceFinished(true); pressed = indexAt(e.getX()); invalidate(); return true; }
                @Override public boolean onSingleTapUp(MotionEvent e) { int i = indexAt(e.getX()); if (i >= 0) chosen(items.get(i)); pressed = -1; invalidate(); return true; }
                @Override public void onLongPress(MotionEvent e) { int i = indexAt(e.getX()); if (i >= 0) { toggleFavourite(items.get(i)); } pressed = -1; invalidate(); }
                @Override public boolean onScroll(MotionEvent e1, MotionEvent e2, float dx, float dy) {
                    if (!horizontal && Math.abs(dx) > Math.abs(dy)) { horizontal = true; getParent().requestDisallowInterceptTouchEvent(true); }
                    if (horizontal) { pressed = -1; scrollTo(clamp(getScrollX() + (int) dx), 0); return true; }
                    return false;
                }
                @Override public boolean onFling(MotionEvent e1, MotionEvent e2, float vx, float vy) {
                    if (!horizontal) return false;
                    scroller.fling(getScrollX(), 0, (int) -vx, 0, 0, maxScroll(), 0, 0);
                    postInvalidateOnAnimation(); return true;
                }
            });
        }

        void setItems(List<Item> l) { items = l; layouts.clear(); scrollTo(0, 0); invalidate(); }

        private int total() { return pad * 2 + items.size() * (cellW + gap) - gap; }
        private int maxScroll() { return Math.max(0, total() - getWidth()); }
        private int clamp(int x) { return Math.max(0, Math.min(x, maxScroll())); }
        private int indexAt(float x) {
            float ax = x + getScrollX() - pad;
            if (ax < 0) return -1;
            int i = (int) (ax / (cellW + gap));
            if (i < 0 || i >= items.size()) return -1;
            return (ax - i * (cellW + gap)) <= cellW ? i : -1;
        }

        @Override public boolean onTouchEvent(MotionEvent e) {
            int a = e.getActionMasked();
            if (a == MotionEvent.ACTION_DOWN) horizontal = false;
            boolean r = gd.onTouchEvent(e);
            if (a == MotionEvent.ACTION_UP || a == MotionEvent.ACTION_CANCEL) { pressed = -1; horizontal = false; invalidate(); }
            return r;
        }

        @Override public void computeScroll() {
            if (scroller.computeScrollOffset()) { scrollTo(scroller.getCurrX(), 0); postInvalidateOnAnimation(); }
        }

        private StaticLayout nameLayout(int i, Item x) {
            StaticLayout l = layouts.get(i);
            if (l == null) {
                name.setColor(cHint);
                int w = cellW - (int) (4 * getResources().getDisplayMetrics().density);
                l = new StaticLayout(x.name, name, w, Layout.Alignment.ALIGN_CENTER, 0.95f, 0f, false);
                layouts.put(i, l);
            }
            return l;
        }

        @Override protected void onDraw(Canvas c) {
            super.onDraw(c);
            float d = getResources().getDisplayMetrics().density;
            int sx = getScrollX(), from = Math.max(0, (sx - pad) / (cellW + gap)), to = Math.min(items.size() - 1, (sx + getWidth() - pad) / (cellW + gap));
            float top = (getHeight() - cellH) / 2f;
            glyph.setColor(cText); lab.setColor(cAccent); name.setColor(cHint);
            line.setColor((cHint & 0x00FFFFFF) | 0x66000000);
            for (int i = from; i <= to; i++) {
                Item x = items.get(i);
                float l = pad + i * (cellW + gap);
                RectF r = new RectF(l, top, l + cellW, top + cellH);
                fill.setColor(i == pressed ? ((cAccent & 0x00FFFFFF) | 0x44000000) : cKey);
                c.drawRoundRect(r, 6 * d, 6 * d, fill);
                c.drawRoundRect(r, 6 * d, 6 * d, line);
                String s = x.shown();
                if (x.abbr != null) c.drawText(s, r.centerX(), top + 25 * d, lab);
                else {
                    TextPaint p = glyph; p.setTextSize(21 * getResources().getDisplayMetrics().scaledDensity);
                    float w = p.measureText(s), max = cellW - 6 * d;
                    if (w > max) p.setTextSize(p.getTextSize() * max / w);
                    c.drawText(s, r.centerX(), top + 24 * d, p);
                }
                StaticLayout nl = nameLayout(i, x);
                c.save(); c.translate(l + 2 * d, top + 29 * d);
                c.clipRect(0, 0, cellW - 4 * d, 26 * d);
                nl.draw(c); c.restore();
                if (fav.contains(x.cp)) { star.setColor(0xFFD19A1A); star.setTextSize(9 * getResources().getDisplayMetrics().scaledDensity); star.setTextAlign(Paint.Align.RIGHT); c.drawText("★", r.right - 3 * d, top + 11 * d, star); }
            }
        }
    }
}
