#!/usr/bin/env python3
# Adds the Unicode symbols palette to the Sulekhak sources (Windows, Android, iPhone / iPad: the unpacked src.tar.gz tree; Mac: the unpacked Sulekhak-Mac.zip tree).
# It copies the files of apps/palette/ and patches the sources with exact text replacements, and stops with an error if a place it patches is not found.
# usage: python3 overlay_palette.py <root of the unpacked sources, e.g. apps>             (Windows, Android, iPhone / iPad)
#        python3 overlay_palette.py --mac <OdiaPhonetic-Mac folder>                       (Mac)
import sys, os, shutil
HERE = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'palette')

def rd(p):
    with open(p, encoding='utf-8') as f: return f.read()
def wr(p, s):
    with open(p, 'w', encoding='utf-8', newline='') as f: f.write(s)
def put(src, dst):
    os.makedirs(os.path.dirname(dst), exist_ok=True); shutil.copyfile(os.path.join(HERE, src), dst)

def sub(path, old, new, done_marker):
    s = rd(path)
    if done_marker in s: return                       # already applied
    if s.count(old) != 1:
        sys.exit('overlay_palette: "%s" found %d times in %s' % (old[:70].replace('\n', ' '), s.count(old), path))
    wr(path, s.replace(old, new, 1))

def windows(root):
    w = os.path.join(root, 'windows')
    if not os.path.isdir(w): return
    for f in ('SymbolsForm.cs',): put(f, os.path.join(w, f))
    for f in ('palette.html', 'sk-palette.js', 'sk-palette-data.js'): put(f, os.path.join(w, 'oskres', f))
    a = os.path.join(w, 'App.cs')
    M = 'SymbolsForm symbols;'
    sub(a, '        Osk3dForm osk3d;', '        SymbolsForm symbols;           // the Unicode symbols palette (Win+comma)\n        Osk3dForm osk3d;', M)
    sub(a, '            osk3d.SuggestPicked += OskSuggest;\n', '''            osk3d.SuggestPicked += OskSuggest;
            ExtractPalette();
            symbols = new SymbolsForm(dir);
            symbols.LastExternal = delegate { return lastExternal; };
            symbols.BeforeInsert = delegate { if (enabled && host != null && buf.Length > 0) Commit(sel, false); prev = "<s>"; };
            symbols.StartAsync();
''', 'ExtractPalette();')
    sub(a, '            menu.Items.Add(miOsk);\n', '''            menu.Items.Add(miOsk);
            var miSymbols = new ToolStripMenuItem("Unicode symbols palette   (Win+,  or Ctrl+Alt+,)");
            miSymbols.Click += delegate { symbols.Toggle(); };
            menu.Items.Add(miSymbols);
''', 'miSymbols')
    sub(a, 'bool own = fg == osk3d.Handle || fg == oskFlat.Handle || fg == popup.Handle;\n                if (!own) lastExternal = fg;',
           'bool own = fg == osk3d.Handle || fg == oskFlat.Handle || fg == popup.Handle || fg == symbols.Handle;\n                if (!own) lastExternal = fg;', 'fg == symbols.Handle')
    sub(a, 'try { popup.Close(); oskFlat.Close(); osk3d.Close(); host.Close(); } catch { }', 'try { popup.Close(); oskFlat.Close(); osk3d.Close(); symbols.Close(); host.Close(); } catch { }', 'symbols.Close()')
    sub(a, '        static void CopyResIfPresent(', '''        // The palette page and its data are copied again at every start (small files), so an update never leaves an old palette behind.
        void ExtractPalette()
        {
            try { Directory.CreateDirectory(dir); foreach (var n in new[] { "palette.html", "sk-palette.js", "sk-palette-data.js" }) CopyRes(n, Path.Combine(dir, n), false); }
            catch (Exception ex) { Log("palette files: " + ex.Message); }
        }

        static void CopyResIfPresent(''', 'void ExtractPalette()')


def android(root):
    base = os.path.join(root, 'android', 'app', 'src', 'main')
    jd = os.path.join(base, 'java', 'com', 'saisudeep', 'sulekhak')
    if not os.path.isdir(jd): return
    put('SymbolPage.java', os.path.join(jd, 'SymbolPage.java'))
    put('palette.json', os.path.join(base, 'assets', 'sulekhak', 'palette.json'))
    k = os.path.join(jd, 'KeyboardView.java')
    sub(k, 'V_SYM_PAGE = 23, V_DIGITSTYLE = 24;', 'V_SYM_PAGE = 23, V_DIGITSTYLE = 24, V_SYMBOLS = 25;\n    /** Set by the keyboard service: opens the Unicode symbols page (the \u03A9 key on the ?123 page). */\n    public Runnable onOpenSymbols;', 'onOpenSymbols')
    sub(k, '            rows.add(bottomPanel());\n        } else if (layer == L_ODIA) {', '            rows.add(symBottomPanel());\n        } else if (layer == L_ODIA) {', 'symBottomPanel()')
    sub(k, '    /** A dependent sign or mark (it needs a letter to sit on), in any of the four scripts. */', '''    /** The bottom row of the ?123 pages: the usual keys and, new, the \u03A9 key that opens the page of all Unicode symbols. */
    private Key[] symBottomPanel() {
        Key sy = layerKey("#+=", L_SYM1, 1f);
        Key em = layerKey("😊", L_EMOJI, 1f);
        Key nm = layerKey("123", L_NUM, 1f);
        Key od = layerKey(phonMode ? "\u0251" : sc("\u0B05"), L_ODIA, 1f);
        Key all = key("\u03A9", V_SYMBOLS, "", 1f, S_ACCENT);
        all.deferred = true;
        return join(one(layerKey("ABC", L_ABC, 1.2f)), one(globe()), one(sy), one(nm), one(em), one(od), one(all), one(space(1.5f)), one(period()), one(enter()));
    }

    /** A dependent sign or mark (it needs a letter to sit on), in any of the four scripts. */''', 'private Key[] symBottomPanel()')
    sub(k, '            case V_SYM_PAGE:\n                layer = (layer == L_SYM1) ? L_SYM2 : L_SYM1;', '            case V_SYMBOLS:\n                if (onOpenSymbols != null) onOpenSymbols.run();\n                break;\n            case V_SYM_PAGE:\n                layer = (layer == L_SYM1) ? L_SYM2 : L_SYM1;', 'case V_SYMBOLS:')
    i = os.path.join(jd, 'SulekhakIME.java')
    sub(i, '    private ScrollView panel;', '    private ScrollView panel;\n    private SymbolPage symbols;               // the Unicode symbols page (the \u03A9 key on the ?123 page)\n    private boolean symbolsOpen;', 'SymbolPage symbols;')
    sub(i, '        kb.setOdiaDigits(prefs.getBoolean("digits_odia", false));\n        applyTheme();\n        applyMode();\n        return root;', '''        symbols = new SymbolPage(this, new SymbolPage.Host() {
            public int onSymbol(String t) { return commitSymbol(t); }
            public void onBack() { showSymbols(false); }
            public void onBackspace() { onKey(KeyboardView.K_BACKSPACE, ""); }
            public void onSpace() { onKey(KeyboardView.K_SPACE, ""); }
            public int dp(int v) { return SulekhakIME.this.dp(v); }
        }, prefs);
        symbols.setVisibility(View.GONE);
        root.addView(symbols, new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, kb.preferredHeight()));
        kb.onOpenSymbols = new Runnable() { public void run() { showSymbols(true); } };

        kb.setOdiaDigits(prefs.getBoolean("digits_odia", false));
        applyTheme();
        applyMode();
        return root;''', 'new SymbolPage(this')
    sub(i, '        root.setBackgroundColor(kb.bgColor());\n', '        root.setBackgroundColor(kb.bgColor());\n        if (symbols != null) symbols.setColors(kb.bgColor(), kb.keyColor(), kb.textColor(), kb.hintColor(), kb.accentColor());\n', 'symbols.setColors(kb.bgColor()')
    sub(i, '    private void showSettings(boolean on) {', '''    /** Shows the Unicode symbols page in the place of the keys, or the keys again. */
    private void showSymbols(boolean on) {
        if (kb == null || symbols == null) return;
        if (on && settingsOpen) showSettings(false);
        if (on) { flushPending(); symbols.setColors(kb.bgColor(), kb.keyColor(), kb.textColor(), kb.hintColor(), kb.accentColor()); symbols.onShown(); }
        symbolsOpen = on;
        symbols.setVisibility(on ? View.VISIBLE : View.GONE);
        kb.setVisibility(on ? View.GONE : View.VISIBLE);
    }

    /** A symbol chosen on that page: the real character at the caret of the text box (a selection is replaced; the caret, focus and undo are the program's own),
     *  or, when no text box is being edited, onto the clipboard. @return 1 typed, 2 copied, 0 failed */
    private int commitSymbol(String t) {
        InputConnection ic = getCurrentInputConnection();
        EditorInfo ei = getCurrentInputEditorInfo();
        if (ic != null && ei != null && ei.inputType != InputType.TYPE_NULL) {
            try { flushPending(); commitDirect(t); return 1; } catch (Exception ignored) { }
        }
        try {
            android.content.ClipboardManager cm = (android.content.ClipboardManager) getSystemService(Context.CLIPBOARD_SERVICE);
            cm.setPrimaryClip(android.content.ClipData.newPlainText("symbol", t));
            return 2;
        } catch (Exception e) { return 0; }
    }

    private void showSettings(boolean on) {''', 'private void showSymbols(boolean on)')
    sub(i, '        settingsOpen = on;\n        if (on) rebuildPanel();', '        if (on && symbolsOpen) showSymbols(false);\n        settingsOpen = on;\n        if (on) rebuildPanel();', 'if (on && symbolsOpen)')
    sub(i, '        super.onStartInputView(info, restarting);\n', '        super.onStartInputView(info, restarting);\n        if (symbolsOpen) showSymbols(false);\n', 'if (symbolsOpen) showSymbols(false);')

SYM_FUNC = """    // MARK: Unicode symbols page
    private func toggleSymbols() {
        flush()
        if clipOpen { clipOpen = false; renderBar() }
        if let sv = symbolView {
            sv.removeFromSuperview(); symbolView = nil
            styleTools()
            return
        }
        let sv = SymbolPageView(frame: CGRect(x: 0, y: toolsHeight(), width: view.bounds.width, height: view.bounds.height - toolsHeight()))
        sv.onSymbol = { [weak self] s in
            guard let self = self else { return }
            self.flush(); self.put(s); self.autoSpace = false
            self.styleTools(); self.renderBar()
        }
        sv.onSpace = { [weak self] in self?.flush(); self?.put(" "); self?.autoSpace = false }
        sv.onBackspace = { [weak self] in self?.flush(); self?.rub(); self?.styleTools() }
        sv.onBack = { [weak self] in
            guard let self = self else { return }
            self.symbolView?.removeFromSuperview(); self.symbolView = nil
            self.styleTools(); self.renderBar()
        }
        view.addSubview(sv)
        symbolView = sv
        sv.willShow()
    }

"""

def ios(root):
    k = os.path.join(root, 'ios', 'SulekhakKeyboard')
    if not os.path.isdir(k): return
    put('SymbolPage.swift', os.path.join(k, 'SymbolPage.swift'))
    put('palette.json', os.path.join(k, 'palette.json'))
    v = os.path.join(k, 'KeyboardViewController.swift')
    sub(v, '    private let toolsBar = UIView()\n', '    private let toolsBar = UIView()\n    private var symbolView: SymbolPageView?          // the Unicode symbols page (the Omega button of the tools row)\n', 'symbolView: SymbolPageView')
    sub(v, 'let names = ["Undo", "Redo", "Cut", "Copy", "Paste", "Clip"]', 'let names = ["Undo", "Redo", "Cut", "Copy", "Paste", "Clip", "\u03a9"]', '"Clip", "\u03a9"]')
    sub(v, '    @objc private func toolTapped(_ b: UIButton) {\n        if b.tag == 5 {', '    @objc private func toolTapped(_ b: UIButton) {\n        if b.tag == 6 { toggleSymbols(); return }\n        if b.tag == 5 {', 'toggleSymbols(); return')
    sub(v, '        grid.frame = CGRect(x: 0, y: tH + 50, width: w, height: h - tH - 50)\n', '        grid.frame = CGRect(x: 0, y: tH + 50, width: w, height: h - tH - 50)\n        symbolView?.frame = CGRect(x: 0, y: tH, width: w, height: h - tH)\n', 'symbolView?.frame')
    sub(v, '    // MARK: tools row (Undo, Redo, Cut, Copy, Paste, Clip)', SYM_FUNC + '    // MARK: tools row (Undo, Redo, Cut, Copy, Paste, Clip, Symbols)', 'func toggleSymbols()')

def mac(m):
    for f in ('PalettePanel.m', 'PalettePanel.h'): put(f, os.path.join(m, 'src', f))
    for f in ('palette.html', 'sk-palette.js', 'sk-palette-data.js'): put(f, os.path.join(m, 'html', f))
    c = os.path.join(m, 'src', 'OdiaController.m')
    sub(c, '#import "OSKPanel.h"\n', '#import "OSKPanel.h"\n#import "PalettePanel.h"\n', '#import "PalettePanel.h"')
    sub(c, 'static __weak OdiaController *gActive;', 'static BOOL gClientLive = NO;           // the input method is active in a text box right now (the symbols palette types through it)\nstatic __weak OdiaController *gActive;', 'gClientLive = NO')
    sub(c, '- (void)activateServer:(id)sender { gActive = self; _client = sender; [super activateServer:sender]; }',
           '- (void)activateServer:(id)sender { gActive = self; _client = sender; gClientLive = YES; [super activateServer:sender]; }', 'gClientLive = YES; [super')
    sub(c, '/// Add to Sulekhak Dictionary without the Accessibility permission', '''/// A symbol from the Unicode palette: the real character, as it is (no script conversion), at the caret of the active text box; a selection is replaced.
/// NO when the input method is not active in a text box (the palette then types it with a key event or copies it).
+ (BOOL)insertRawText:(NSString *)t {
    OdiaController *c = gActive;
    if (!gClientLive || !c || !c->_client || t.length == 0) return NO;
    @try {
        if (c->_buf.length) [c commitIndex:c->_sel client:c->_client suffix:nil bySelection:NO];
        [c->_en finishWithClient:c->_client];
        c->_markedShown = nil;
        [(id<IMKTextInput>)c->_client insertText:t replacementRange:NSMakeRange(NSNotFound, NSNotFound)];
        return YES;
    } @catch (NSException *e) { return NO; }
}

/// Add to Sulekhak Dictionary without the Accessibility permission''', 'insertRawText')
    sub(c, '    gActive = self; _client = sender;\n    NSEventModifierFlags f = event.modifierFlags;',
           '    gActive = self; _client = sender; gClientLive = YES;\n    if ([[PalettePanel shared] handleSearchKey:event]) return YES;        // typing goes to the symbols palette\'s search box while it has the typing\n    NSEventModifierFlags f = event.modifierFlags;', 'handleSearchKey')
    sub(c, '- (void)deactivateServer:(id)sender { if (_buf.length)', '- (void)deactivateServer:(id)sender { if (gActive == self) gClientLive = NO; if (_buf.length)', 'gClientLive = NO; if (_buf')
    sub(c, '    NSMenuItem *zb = [[NSMenuItem alloc] initWithTitle:@"3D keyboard: bigger',
           '    NSMenuItem *sy = [[NSMenuItem alloc] initWithTitle:@"Unicode symbols palette  (⌥,)" action:@selector(menuPalette:) keyEquivalent:@""]; sy.target = self; sy.state = [[PalettePanel shared] isVisible] ? NSControlStateValueOn : NSControlStateValueOff; [m addItem:sy];\n    NSMenuItem *zb = [[NSMenuItem alloc] initWithTitle:@"3D keyboard: bigger', 'menuPalette:')
    sub(c, '- (void)menuOSK:(id)s { [[OSKPanel shared] toggle]; }', '- (void)menuOSK:(id)s { [[OSKPanel shared] toggle]; }\n- (void)menuPalette:(id)s { [[PalettePanel shared] toggle]; }', '- (void)menuPalette:')
    h = os.path.join(m, 'src', 'OdiaController.h')
    sub(h, '+ (void)oskInsert:(NSString *)text;', '+ (void)oskInsert:(NSString *)text;\n+ (BOOL)insertRawText:(NSString *)text;                // a symbol from the Unicode palette, typed as it is at the caret of the active text box (NO when none)', 'insertRawText')
    mm = os.path.join(m, 'src', 'main.m')
    sub(mm, '#import "OSKPanel.h"', '#import "OSKPanel.h"\n#import "PalettePanel.h"', '#import "PalettePanel.h"')
    sub(mm, '        [OSKPanel installHotKey];     // Ctrl+Option+K shows or hides the 3D keyboard', '        [OSKPanel installHotKey];     // Ctrl+Option+K shows or hides the 3D keyboard\n        [PalettePanel installHotKey]; // Option+comma shows or hides the Unicode symbols palette', 'PalettePanel installHotKey')
    o = os.path.join(m, 'src', 'OSKPanel.m')
    sub(o, '    UInt32 which = hid.id;\n', "    if (hid.signature != 'SKOS') return eventNotHandledErr;       // another module's hot key (the symbols palette's Option+comma)\n    UInt32 which = hid.id;\n", 'eventNotHandledErr')
    b = os.path.join(m, 'build.sh')
    sub(b, 'for f in main OdiaController SKEngine OSKPanel SuggestBar SKLearn SKPersonal; do', 'for f in main OdiaController SKEngine OSKPanel PalettePanel SuggestBar SKLearn SKPersonal; do', 'OSKPanel PalettePanel')
    sub(b, 'cp src/skel.dat "$BUILD/Contents/Resources/skel.dat"', 'cp html/palette.html html/sk-palette.js html/sk-palette-data.js "$BUILD/Contents/Resources/"       # the Unicode symbols palette (Option+comma)\ncp src/skel.dat "$BUILD/Contents/Resources/skel.dat"', 'html/palette.html')

if __name__ == '__main__':
    if len(sys.argv) >= 3 and sys.argv[1] == '--mac':
        mac(sys.argv[2]); print('overlay_palette: Mac palette applied')
    elif len(sys.argv) == 2:
        windows(sys.argv[1]); android(sys.argv[1]); ios(sys.argv[1]); print('overlay_palette: palette applied to', sys.argv[1])
    else:
        sys.exit(__doc__ if __doc__ else 'usage: overlay_palette.py <apps root> | --mac <mac root>')
