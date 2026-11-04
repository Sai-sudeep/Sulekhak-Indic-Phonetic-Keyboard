using System;
using System.Collections.Generic;
using System.Drawing;
using System.IO;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;
using System.Windows.Forms;
using Microsoft.Web.WebView2.Core;
using Microsoft.Web.WebView2.WinForms;

namespace Sulekhak
{
    /// <summary>
    /// The Unicode symbols palette: a floating, draggable, resizable window (the page palette.html in a WebView2) that never takes the keyboard focus, so the program
    /// being typed in keeps its caret, selection and undo. Win+comma (or Ctrl+Alt+comma, in case Windows keeps Win+comma for itself) and the tray menu show and hide it.
    /// A click on a symbol types the character into the focused text box (a Unicode key event, as the on-screen keyboard does), or copies it to the clipboard when no text box has the focus.
    /// The page is the same sk-palette.js that the web typist uses; its messages are listed at the top of that file.
    /// </summary>
    class SymbolsForm : Form
    {
        public Func<IntPtr> LastExternal;        // the program that was being typed in (set by the app)
        public Action BeforeInsert;              // the app finishes the word in progress before a symbol goes in
        public bool Ready;

        readonly WebView2 wv = new WebView2();
        readonly string dir, statePath;
        readonly Dictionary<string, string> state = new Dictionary<string, string>();
        bool pinned, searching, dragging, sizing;
        Point dragStart, formStart, sizeStart; Size sizeFrom;

        // ---- hooks: the keyboard hook is on all the time (Win+comma has to work from anywhere); the mouse hook only while the window shows
        Native.LowLevelProc keyProc, mouseProc;
        IntPtr keyHook = IntPtr.Zero, mouseHook = IntPtr.Zero;
        readonly HashSet<uint> swallowedUp = new HashSet<uint>();

        [StructLayout(LayoutKind.Sequential)]
        struct MSLLHOOKSTRUCT { public Native.POINT pt; public uint mouseData, flags, time; public IntPtr dwExtraInfo; }
        [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern int GetClassName(IntPtr hWnd, StringBuilder sb, int max);
        [DllImport("user32.dll")] static extern int GetWindowLong(IntPtr hWnd, int index);

        public SymbolsForm(string dataDir)
        {
            dir = dataDir;
            statePath = Path.Combine(dir, "palette-state.json");
            LoadState();
            FormBorderStyle = FormBorderStyle.None;
            ShowInTaskbar = false;
            TopMost = true;
            StartPosition = FormStartPosition.Manual;
            BackColor = Color.FromArgb(247, 246, 242);
            MinimumSize = new Size(S(320), S(240));
            ClientSize = new Size(S(640), S(480));
            wv.Dock = DockStyle.Fill;
            wv.DefaultBackgroundColor = Color.FromArgb(247, 246, 242);
            Controls.Add(wv);
            pinned = state.ContainsKey("pin") && state["pin"] == "true";
            PlaceFromState();
            keyProc = KeyCallback;
            keyHook = Native.SetWindowsHookEx(Native.WH_KEYBOARD_LL, keyProc, Native.GetModuleHandle(null), 0);      // without it only the tray menu opens the palette
        }

        int S(int px) { return (int)Math.Round(px * DeviceDpi / 96.0); }

        protected override bool ShowWithoutActivation { get { return true; } }

        protected override CreateParams CreateParams
        {
            get
            {
                var cp = base.CreateParams;
                cp.ExStyle |= 0x08000000 | 0x00000080 | 0x00000008;   // NOACTIVATE | TOOLWINDOW | TOPMOST
                return cp;
            }
        }

        protected override void OnHandleCreated(EventArgs e)
        {
            base.OnHandleCreated(e);
            try { int pref = 2; Native.DwmSetWindowAttribute(Handle, 33, ref pref, 4); } catch { }      // rounded corners on Windows 11
        }

        protected override void WndProc(ref Message m)
        {
            if (m.Msg == 0x0021) { m.Result = (IntPtr)3; return; }       // WM_MOUSEACTIVATE: never take the focus
            base.WndProc(ref m);
        }

        protected override void OnFormClosed(FormClosedEventArgs e)
        {
            UnhookMouse();
            if (keyHook != IntPtr.Zero) { Native.UnhookWindowsHookEx(keyHook); keyHook = IntPtr.Zero; }
            base.OnFormClosed(e);
        }

        // ------------------------------------------------------------------ start, show, hide
        /// <summary>Starts the page. The window is created off-screen and hidden again, because the WebView2 needs a window handle first.</summary>
        public async Task StartAsync()
        {
            var home = Location;
            Location = new Point(-32000, -32000);
            Show();
            try
            {
                var env = await CoreWebView2Environment.CreateAsync(null, Path.Combine(dir, "webview2"));
                await wv.EnsureCoreWebView2Async(env);
                var core = wv.CoreWebView2;
                core.SetVirtualHostNameToFolderMapping("sulekhak.local", dir, CoreWebView2HostResourceAccessKind.Allow);
                core.Settings.AreDefaultContextMenusEnabled = false;
                core.Settings.AreDevToolsEnabled = false;
                core.Settings.IsZoomControlEnabled = false;
                core.Settings.IsStatusBarEnabled = false;
                core.Settings.AreBrowserAcceleratorKeysEnabled = false;
                core.WebMessageReceived += OnMessage;
                core.Navigate("https://sulekhak.local/palette.html");
            }
            finally
            {
                Hide();
                Location = home;
            }
        }

        public void Toggle()
        {
            if (Visible) HidePalette(); else ShowPalette();
        }

        public void ShowPalette()
        {
            if (!Ready || wv.CoreWebView2 == null) return;
            PlaceFromState();
            searching = false;
            Show();
            Native.SetWindowPos(Handle, (IntPtr)(-1), 0, 0, 0, 0, 0x0001 | 0x0002 | 0x0010);      // topmost, without moving, sizing or activating
            PushShown();
            HookMouse();
        }

        public void HidePalette()
        {
            if (!Visible) return;
            SaveFrame();
            searching = false;
            UnhookMouse();
            Hide();
            try { wv.CoreWebView2.ExecuteScriptAsync("window.SKPalette&&SKPalette.native&&SKPalette.native.hidden()"); } catch { }
        }

        void PushShown()
        {
            string fav = state.ContainsKey("fav") ? state["fav"] : "[]", rec = state.ContainsKey("recent") ? state["recent"] : "[]";
            if (!ValidJson(fav)) fav = "[]";
            if (!ValidJson(rec)) rec = "[]";
            try { wv.CoreWebView2.ExecuteScriptAsync("window.SKPalette&&SKPalette.native&&(SKPalette.native.restore({fav:" + fav + ",recent:" + rec + ",pin:" + (pinned ? "true" : "false") + "}),SKPalette.native.shown())"); }
            catch { }
        }

        static bool ValidJson(string s) { try { using (JsonDocument.Parse(s)) return true; } catch { return false; } }

        // ------------------------------------------------------------------ saved state: favourites, recent symbols, pin, position and size
        void LoadState()
        {
            try { var d = JsonSerializer.Deserialize<Dictionary<string, string>>(File.ReadAllText(statePath)); if (d != null) foreach (var kv in d) state[kv.Key] = kv.Value; }
            catch { }
        }
        void SaveState() { try { File.WriteAllText(statePath, JsonSerializer.Serialize(state)); } catch { } }
        void SaveFrame() { state["frame"] = Left + "," + Top + "," + Width + "," + Height; SaveState(); }

        void PlaceFromState()
        {
            Rectangle r = Rectangle.Empty;
            try
            {
                if (state.ContainsKey("frame"))
                {
                    var p = state["frame"].Split(',');
                    var f = new Rectangle(int.Parse(p[0]), int.Parse(p[1]), int.Parse(p[2]), int.Parse(p[3]));
                    foreach (var sc in Screen.AllScreens) if (sc.WorkingArea.IntersectsWith(f)) { r = f; break; }
                }
            }
            catch { r = Rectangle.Empty; }
            if (r.Width >= S(320) && r.Height >= S(240)) { Size = r.Size; Location = r.Location; return; }
            var wa = Screen.PrimaryScreen.WorkingArea;
            Size = new Size(S(640), S(480));
            Location = new Point(wa.Left + (wa.Width - Width) / 2, wa.Top + (wa.Height - Height) / 2);
        }

        // ------------------------------------------------------------------ messages from the page
        void OnMessage(object sender, CoreWebView2WebMessageReceivedEventArgs e)
        {
            string j;
            try { j = e.TryGetWebMessageAsString(); } catch { return; }
            try
            {
                using (var d = JsonDocument.Parse(j))
                {
                    var r = d.RootElement;
                    string t = r.GetProperty("t").GetString();
                    if (t == "pal-ready") Ready = true;
                    else if (t == "pal-ins") Insert(r.GetProperty("s").GetString(), r.TryGetProperty("copyOnly", out var co) && co.ValueKind == JsonValueKind.True);
                    else if (t == "pal-pin") { pinned = r.GetProperty("on").GetBoolean(); state["pin"] = pinned ? "true" : "false"; SaveState(); }
                    else if (t == "pal-hide") HidePalette();
                    else if (t == "pal-search") searching = r.GetProperty("on").GetBoolean();
                    else if (t == "pal-save")
                    {
                        string k = r.GetProperty("k").GetString(), v = r.GetProperty("v").GetString();
                        if ((k == "fav" || k == "recent" || k == "pin") && ValidJson(v)) { state[k] = v; if (k == "pin") pinned = v == "true"; SaveState(); }
                    }
                    else if (t == "pal-drag")
                    {
                        int s = r.GetProperty("s").GetInt32();
                        if (s == 1) { dragging = true; dragStart = Cursor.Position; formStart = Location; }
                        else if (s == 2 && dragging) { var c = Cursor.Position; Location = new Point(formStart.X + c.X - dragStart.X, formStart.Y + c.Y - dragStart.Y); }
                        else { if (dragging) SaveFrame(); dragging = false; }
                    }
                    else if (t == "pal-size")
                    {
                        int s = r.GetProperty("s").GetInt32();
                        if (s == 1) { sizing = true; sizeStart = Cursor.Position; sizeFrom = Size; }
                        else if (s == 2 && sizing)
                        {
                            var c = Cursor.Position;
                            Size = new Size(Math.Max(S(320), sizeFrom.Width + c.X - sizeStart.X), Math.Max(S(240), sizeFrom.Height + c.Y - sizeStart.Y));
                        }
                        else { if (sizing) SaveFrame(); sizing = false; }
                    }
                }
            }
            catch { }
        }

        void Result(string how)
        {
            try { wv.CoreWebView2.ExecuteScriptAsync("window.SKPalette&&SKPalette.native&&SKPalette.native.result('" + how + "')"); } catch { }
        }

        // ------------------------------------------------------------------ putting a symbol in
        void Copy(string s)
        {
            try { Clipboard.SetDataObject(s, true, 5, 50); Result("copied"); }
            catch { Result("failed"); }
        }

        void Insert(string s, bool copyOnly)
        {
            if (string.IsNullOrEmpty(s)) { Result("failed"); return; }
            if (copyOnly) { Copy(s); return; }
            IntPtr fg = Native.GetForegroundWindow();
            IntPtr back = LastExternal != null ? LastExternal() : IntPtr.Zero;
            if ((fg == Handle || fg == IntPtr.Zero) && back != IntPtr.Zero) { try { Native.SetForegroundWindow(back); } catch { } fg = back; }
            IntPtr target = fg;
            // Asking another program about its focus can take a while, so it is done off the window's thread and given a short time.
            Task.Run(delegate
            {
                var chk = Task.Run(delegate { return TextFocus.IsEditable(target); });
                return chk.Wait(700) && chk.Result;
            }).ContinueWith(delegate (Task<bool> t)
            {
                bool editable = !t.IsFaulted && t.Result;
                try
                {
                    BeginInvoke(new Action(delegate
                    {
                        if (editable)
                        {
                            try { if (BeforeInsert != null) BeforeInsert(); } catch { }
                            Native.SendText(s);              // the real character, as a Unicode key event: the program puts it at the caret and replaces a selection
                            Result("inserted");
                        }
                        else Copy(s);
                    }));
                }
                catch { }
            });
        }

        // ------------------------------------------------------------------ outside clicks (unless pinned)
        void HookMouse()
        {
            if (mouseHook != IntPtr.Zero) return;
            mouseProc = MouseCallback;
            mouseHook = Native.SetWindowsHookEx(Native.WH_MOUSE_LL, mouseProc, Native.GetModuleHandle(null), 0);
        }
        void UnhookMouse()
        {
            if (mouseHook != IntPtr.Zero) { Native.UnhookWindowsHookEx(mouseHook); mouseHook = IntPtr.Zero; }
        }
        IntPtr MouseCallback(int code, IntPtr wParam, IntPtr lParam)
        {
            if (code >= 0 && !pinned && Visible)
            {
                int msg = wParam.ToInt32();
                if (msg == 0x201 || msg == 0x204 || msg == 0x207)           // left, right, middle button down
                {
                    var m = (MSLLHOOKSTRUCT)Marshal.PtrToStructure(lParam, typeof(MSLLHOOKSTRUCT));
                    if (!Bounds.Contains(m.pt.X, m.pt.Y)) { try { BeginInvoke(new Action(HidePalette)); } catch { } }
                }
            }
            return Native.CallNextHookEx(IntPtr.Zero, code, wParam, lParam);
        }

        // ------------------------------------------------------------------ keys: Win+comma, Ctrl+Alt+comma, and typing in the search box
        IntPtr KeyCallback(int code, IntPtr wParam, IntPtr lParam)
        {
            if (code < 0) return Native.CallNextHookEx(IntPtr.Zero, code, wParam, lParam);
            try
            {
                var k = (Native.KBDLLHOOKSTRUCT)Marshal.PtrToStructure(lParam, typeof(Native.KBDLLHOOKSTRUCT));
                if ((k.flags & 0x10) != 0 || k.dwExtraInfo == (IntPtr)Native.MAGIC) return Native.CallNextHookEx(IntPtr.Zero, code, wParam, lParam);   // injected keys, our own included
                int msg = wParam.ToInt32();
                bool down = msg == Native.WM_KEYDOWN || msg == Native.WM_SYSKEYDOWN, up = msg == Native.WM_KEYUP || msg == Native.WM_SYSKEYUP;
                uint vk = k.vkCode;
                if (up) { if (swallowedUp.Remove(vk)) return (IntPtr)1; return Native.CallNextHookEx(IntPtr.Zero, code, wParam, lParam); }
                if (!down) return Native.CallNextHookEx(IntPtr.Zero, code, wParam, lParam);

                bool win = Native.IsDown(0x5B) || Native.IsDown(0x5C), ctrl = Native.IsDown(0x11), alt = Native.IsDown(0x12);
                if (vk == 0xBC && ((win && !ctrl && !alt) || (ctrl && alt && !win)))                 // VK_OEM_COMMA
                {
                    if (swallowedUp.Add(vk))                                                           // the first press; a held key repeats and is only swallowed
                    {
                        if (win) Native.SendVk(0xE8, false);                                            // an unassigned key between Win and the comma, so that letting go of Win does not open the Start menu
                        try { BeginInvoke(new Action(Toggle)); } catch { }
                    }
                    return (IntPtr)1;
                }
                if (searching && Visible && !ctrl && !alt && !win)
                {
                    string key = null;
                    if (vk == 0x1B) key = "Escape"; else if (vk == 0x08) key = "Backspace"; else if (vk == 0x0D) key = "Enter";
                    else if (vk >= 0x20 && vk != 0x2E && !(vk >= 0x21 && vk <= 0x28) && !(vk >= 0x70 && vk <= 0x87) && vk != 0x5B && vk != 0x5C && vk != 0xA0 && vk != 0xA1)
                    {
                        string c = Native.CharFor(vk, k.scanCode);
                        if (c.Length > 0 && c[0] >= ' ') key = c;
                    }
                    if (key != null)
                    {
                        swallowedUp.Add(vk);
                        string js = "window.SKPalette&&SKPalette.native&&SKPalette.native.key(" + JsonSerializer.Serialize(key) + ")";
                        try { BeginInvoke(new Action(delegate { try { wv.CoreWebView2.ExecuteScriptAsync(js); } catch { } })); } catch { }
                        return (IntPtr)1;
                    }
                }
            }
            catch { }
            return Native.CallNextHookEx(IntPtr.Zero, code, wParam, lParam);
        }

        // ------------------------------------------------------------------ is there a text box to type into?
        static class TextFocus
        {
            static readonly string[] EditClasses = { "Edit", "RichEdit", "RichEdit20W", "RichEdit20A", "RICHEDIT50W", "RICHEDIT60W", "RichEditD2DPT", "Scintilla", "_WwG", "TMemo", "TEdit", "TRichEdit", "SysIPAddress32" };

            public static bool IsEditable(IntPtr fg)
            {
                try
                {
                    if (fg == IntPtr.Zero) return false;
                    uint pid; uint tid = Native.GetWindowThreadProcessId(fg, out pid);
                    var gi = new Native.GUITHREADINFO(); gi.cbSize = Marshal.SizeOf(typeof(Native.GUITHREADINFO));
                    IntPtr focus = fg;
                    if (Native.GetGUIThreadInfo(tid, ref gi))
                    {
                        if (gi.hwndCaret != IntPtr.Zero) return true;                      // a program that shows a text caret has a text box in focus
                        if (gi.hwndFocus != IntPtr.Zero) focus = gi.hwndFocus;
                        string cls = ClassOf(focus);
                        foreach (var c in EditClasses)
                            if (string.Equals(cls, c, StringComparison.OrdinalIgnoreCase)) return (GetWindowLong(focus, -16) & 0x0800) == 0;      // not ES_READONLY
                    }
                    return AccessibleEditable(focus);
                }
                catch { return false; }
            }

            static string ClassOf(IntPtr h) { var sb = new StringBuilder(128); GetClassName(h, sb, sb.Capacity); return sb.ToString(); }

            // Browsers and modern programs draw their own text boxes: ask Microsoft Active Accessibility what has the focus (role "text", not read-only).
            static bool AccessibleEditable(IntPtr hwnd)
            {
                Guid iid = new Guid("618736E0-3C3D-11CF-810C-00AA00389B71");
                object acc;
                if (Native.AccessibleObjectFromWindow(hwnd, 0xFFFFFFFC, ref iid, out acc) != 0 || acc == null) return false;      // OBJID_CLIENT
                for (int depth = 0; depth < 10 && acc != null; depth++)
                {
                    object f = Get(acc, "accFocus", new object[0]);
                    if (f is int || f is short || f == null)
                    {
                        object id = f ?? 0;
                        object role = Get(acc, "accRole", new object[] { id }), st = Get(acc, "accState", new object[] { id });
                        int rl = role is int ? (int)role : -1, state = st is int ? (int)st : 0;
                        return rl == 0x2A && (state & 0x40) == 0;                            // ROLE_SYSTEM_TEXT, not STATE_SYSTEM_READONLY
                    }
                    acc = f;
                }
                return false;
            }

            static object Get(object acc, string prop, object[] args)
            {
                try
                {
                    return acc.GetType().InvokeMember(prop, BindingFlags.GetProperty, null, acc, args);
                }
                catch { return null; }
            }
        }
    }
}
