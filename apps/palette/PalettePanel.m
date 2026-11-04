#import "PalettePanel.h"
#import "OdiaController.h"
#import <WebKit/WebKit.h>
#import <ApplicationServices/ApplicationServices.h>
#import <Carbon/Carbon.h>

// A web view that reacts to the very first click and reports the pointer (the window is never key, so WebKit gets no mouse-move events of its own).
@interface PalWebView : WKWebView
@end
@implementation PalWebView
- (BOOL)acceptsFirstMouse:(NSEvent *)event { return YES; }
- (BOOL)mouseDownCanMoveWindow { return NO; }
- (void)updateTrackingAreas {
    for (NSTrackingArea *a in [self.trackingAreas copy]) if (a.owner == self) [self removeTrackingArea:a];
    NSTrackingAreaOptions o = NSTrackingMouseMoved | NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways | NSTrackingInVisibleRect;
    [self addTrackingArea:[[NSTrackingArea alloc] initWithRect:self.bounds options:o owner:self userInfo:nil]];
    [super updateTrackingAreas];
}
- (void)mouseMoved:(NSEvent *)event {
    NSPoint p = [self convertPoint:event.locationInWindow fromView:nil];
    CGFloat y = self.isFlipped ? p.y : self.bounds.size.height - p.y;
    [self evaluateJavaScript:[NSString stringWithFormat:@"window.SKPalette&&SKPalette.native&&SKPalette.native.hover(%.1f,%.1f)", p.x, y] completionHandler:nil];
}
- (void)mouseExited:(NSEvent *)event {
    [self evaluateJavaScript:@"window.SKPalette&&SKPalette.native&&SKPalette.native.hoverLeave()" completionHandler:nil];
}
@end

// Never the key window: the program you are typing into keeps the keyboard focus, so the caret, the selection and undo stay as they were.
@interface PalWindow : NSPanel
@end
@implementation PalWindow
- (BOOL)canBecomeKeyWindow { return NO; }
- (BOOL)canBecomeMainWindow { return NO; }
@end

@interface PalettePanel () <WKScriptMessageHandler, WKNavigationDelegate>
@end

static NSString *const kPalState = @"SulekhakPaletteState";     // favourites, recent symbols, pin, window frame
static BOOL gPalHotKeyOK = NO;
static const UInt32 kPalHotKeyID = 5;

static OSStatus PalHotKeyHandler(EventHandlerCallRef next, EventRef ev, void *ud) {
    EventHotKeyID hid = { 0, 0 };
    GetEventParameter(ev, kEventParamDirectObject, typeEventHotKeyID, NULL, sizeof(hid), NULL, &hid);
    if (hid.signature != 'SKPL' || hid.id != kPalHotKeyID) return eventNotHandledErr;
    dispatch_async(dispatch_get_main_queue(), ^{ [[PalettePanel shared] toggle]; });
    return noErr;
}

@implementation PalettePanel {
    PalWindow *_win;
    PalWebView *_web;
    BOOL _loaded, _pinned, _searching, _visible;
    NSPoint _dragMouse, _dragOrigin, _sizeMouse;
    NSRect _sizeFrame;
    int _drag, _size;
    id _globalClick;
    NSMutableDictionary *_state;
}

+ (instancetype)shared {
    static PalettePanel *p; static dispatch_once_t once;
    dispatch_once(&once, ^{ p = [PalettePanel new]; });
    return p;
}

// Option+comma as a system-wide hot key, as asked. (It replaces the ≤ that Option+comma types on a US keyboard; the Sulekhak menu item is the other way in.)
+ (void)installHotKey {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        EventTypeSpec spec = { kEventClassKeyboard, kEventHotKeyPressed };
        OSStatus a = InstallApplicationEventHandler(&PalHotKeyHandler, 1, &spec, NULL, NULL);
        EventHotKeyID h = { 'SKPL', kPalHotKeyID }; EventHotKeyRef ref = NULL;
        OSStatus b = RegisterEventHotKey(kVK_ANSI_Comma, optionKey, h, GetApplicationEventTarget(), 0, &ref);
        gPalHotKeyOK = (a == noErr && b == noErr);
        if (!gPalHotKeyOK) NSLog(@"Sulekhak palette: Option+comma could not be registered (%d, %d); the menu item still works", (int)a, (int)b);
    });
}
+ (BOOL)hotKeyActive { return gPalHotKeyOK; }

- (BOOL)isVisible { return _win != nil && _win.isVisible; }
- (BOOL)isSearching { return _searching && [self isVisible]; }

// ---- saved state (favourites, recent, pin, frame)
- (NSMutableDictionary *)state {
    if (!_state) {
        NSDictionary *d = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kPalState];
        _state = d ? [d mutableCopy] : [NSMutableDictionary new];
    }
    return _state;
}
- (void)persist { [[NSUserDefaults standardUserDefaults] setObject:[self state] forKey:kPalState]; }
- (void)saveFrame { if (!_win) return; [self state][@"frame"] = NSStringFromRect(_win.frame); [self persist]; }

- (void)build {
    if (_win) return;
    NSRect scr = [NSScreen mainScreen].visibleFrame;
    NSRect fr = NSMakeRect(NSMidX(scr) - 320, NSMidY(scr) - 240, 640, 480);
    NSString *saved = [self state][@"frame"];
    if (saved.length) {
        NSRect r = NSRectFromString(saved);
        if (r.size.width >= 320 && r.size.height >= 240) {
            BOOL on = NO; for (NSScreen *s in [NSScreen screens]) if (NSIntersectsRect(s.visibleFrame, r)) { on = YES; break; }
            if (on) fr = r;
        }
    }
    _win = [[PalWindow alloc] initWithContentRect:fr
                                        styleMask:NSWindowStyleMaskBorderless | NSWindowStyleMaskNonactivatingPanel | NSWindowStyleMaskResizable
                                          backing:NSBackingStoreBuffered defer:NO];
    _win.level = NSFloatingWindowLevel;
    _win.opaque = NO;
    _win.backgroundColor = [NSColor clearColor];
    _win.hasShadow = YES;
    _win.hidesOnDeactivate = NO;
    _win.releasedWhenClosed = NO;
    _win.becomesKeyOnlyIfNeeded = YES;
    _win.minSize = NSMakeSize(320, 240);
    _win.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces | NSWindowCollectionBehaviorFullScreenAuxiliary;

    WKWebViewConfiguration *cfg = [WKWebViewConfiguration new];
    [cfg.userContentController addScriptMessageHandler:self name:@"palette"];
    _web = [[PalWebView alloc] initWithFrame:NSMakeRect(0, 0, fr.size.width, fr.size.height) configuration:cfg];
    _web.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    _web.navigationDelegate = self;
    @try { [_web setValue:@NO forKey:@"drawsBackground"]; } @catch (NSException *e) {}
    _web.wantsLayer = YES;
    _web.layer.cornerRadius = 10; _web.layer.masksToBounds = YES;
    _win.contentView = _web;
    _pinned = [[self state][@"pin"] boolValue];

    NSURL *page = [[NSBundle mainBundle] URLForResource:@"palette" withExtension:@"html"];
    if (page) [_web loadFileURL:page allowingReadAccessToURL:[page URLByDeletingLastPathComponent]];
}

- (void)toggle {
    if ([self isVisible]) { [self hide]; return; }
    [self show];
}

- (void)show {
    [self build];
    [_win orderFrontRegardless];
    _visible = YES; _searching = NO;
    [self pushShown];
    [self startOutsideClickWatch];
}

- (void)hide {
    _searching = NO; _visible = NO;
    [self stopOutsideClickWatch];
    [self saveFrame];
    [_win orderOut:nil];
    if (_loaded) [_web evaluateJavaScript:@"window.SKPalette&&SKPalette.native&&SKPalette.native.hidden()" completionHandler:nil];
}

// ---- dismiss on a click outside (unless pinned). Mouse clicks in other programs reach a global monitor without any permission.
- (void)startOutsideClickWatch {
    if (_globalClick) return;
    __weak PalettePanel *ws = self;
    _globalClick = [NSEvent addGlobalMonitorForEventsMatchingMask:(NSEventMaskLeftMouseDown | NSEventMaskRightMouseDown | NSEventMaskOtherMouseDown)
                                                          handler:^(NSEvent *e) {
        PalettePanel *me = ws; if (!me || me->_pinned || !me->_win.isVisible) return;
        if (!NSPointInRect([NSEvent mouseLocation], me->_win.frame)) [me hide];
    }];
}
- (void)stopOutsideClickWatch { if (_globalClick) { [NSEvent removeMonitor:_globalClick]; _globalClick = nil; } }

// ---- page <-> app
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation { _loaded = YES; if (_visible) [self pushShown]; }

- (void)pushShown {
    if (!_web || !_loaded) return;
    NSMutableDictionary *st = [self state];
    NSMutableDictionary *o = [NSMutableDictionary new];
    if (st[@"fav"]) o[@"fav"] = st[@"fav"];
    if (st[@"recent"]) o[@"recent"] = st[@"recent"];
    o[@"pin"] = @(_pinned);
    NSData *d = [NSJSONSerialization dataWithJSONObject:o options:0 error:nil];
    NSString *js = d ? [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding] : @"{}";
    [_web evaluateJavaScript:[NSString stringWithFormat:@"window.SKPalette&&SKPalette.native&&(SKPalette.native.restore(%@),SKPalette.native.shown())", js] completionHandler:nil];
}

- (void)reportResult:(NSString *)how {
    [_web evaluateJavaScript:[NSString stringWithFormat:@"window.SKPalette&&SKPalette.native&&SKPalette.native.result('%@')", how] completionHandler:nil];
}

static void SKCopyToPasteboard(NSString *s) {
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
    [pb clearContents];
    [pb setString:s forType:NSPasteboardTypeString];
}

// Types the character with a Unicode keyboard event into the focused text box (needs the Accessibility permission, which the on-screen keyboard also asks for).
static BOOL SKFocusedIsEditable(void) {
    if (!AXIsProcessTrusted()) return NO;
    AXUIElementRef sys = AXUIElementCreateSystemWide();
    CFTypeRef f = NULL; BOOL ok = NO;
    if (AXUIElementCopyAttributeValue(sys, kAXFocusedUIElementAttribute, &f) == kAXErrorSuccess && f) {
        AXUIElementRef el = (AXUIElementRef)f;
        CFTypeRef role = NULL;
        NSString *r = nil;
        if (AXUIElementCopyAttributeValue(el, kAXRoleAttribute, &role) == kAXErrorSuccess && role) { r = (__bridge NSString *)role; }
        BOOL roleOK = r && ([r isEqualToString:(__bridge NSString *)kAXTextFieldRole] || [r isEqualToString:(__bridge NSString *)kAXTextAreaRole] ||
                            [r isEqualToString:(__bridge NSString *)kAXComboBoxRole] || [r isEqualToString:@"AXSearchField"]);
        Boolean settable = false;
        BOOL selSettable = (AXUIElementIsAttributeSettable(el, kAXSelectedTextRangeAttribute, &settable) == kAXErrorSuccess && settable);
        settable = false;
        BOOL valSettable = (AXUIElementIsAttributeSettable(el, kAXValueAttribute, &settable) == kAXErrorSuccess && settable);
        ok = (roleOK && (selSettable || valSettable)) || (selSettable && valSettable);
        if (role) CFRelease(role);
        CFRelease(f);
    }
    CFRelease(sys);
    return ok;
}
static void SKPostUnicode(NSString *s) {
    NSUInteger n = s.length; if (!n) return;
    UniChar *buf = malloc(n * sizeof(UniChar)); [s getCharacters:buf range:NSMakeRange(0, n)];
    CGEventSourceRef src = CGEventSourceCreate(kCGEventSourceStateHIDSystemState);
    CGEventRef down = CGEventCreateKeyboardEvent(src, 0, true), up = CGEventCreateKeyboardEvent(src, 0, false);
    if (down && up) {
        CGEventKeyboardSetUnicodeString(down, n, buf); CGEventKeyboardSetUnicodeString(up, n, buf);
        CGEventPost(kCGHIDEventTap, down); CGEventPost(kCGHIDEventTap, up);
    }
    if (down) CFRelease(down); if (up) CFRelease(up); if (src) CFRelease(src);
    free(buf);
}

// 1: the Sulekhak input method is active in a text box: hand the character to it (replaces the selection, keeps the caret and undo).
// 2: another input method, but the focused element is an editable text box (Accessibility permission): type it as a Unicode key event.
// 3: no text box: copy to the clipboard.
- (void)insert:(NSString *)s copyOnly:(BOOL)copyOnly {
    if (!s.length) { [self reportResult:@"failed"]; return; }
    if (copyOnly) { SKCopyToPasteboard(s); [self reportResult:@"copied"]; return; }
    if ([OdiaController insertRawText:s]) { [self reportResult:@"inserted"]; return; }
    if (SKFocusedIsEditable()) { SKPostUnicode(s); [self reportResult:@"inserted"]; return; }
    SKCopyToPasteboard(s); [self reportResult:@"copied"];
}

// ---- the search box takes its letters from the input method (it sees every key the focused program gets), so the focus never leaves the text box
- (BOOL)handleSearchKey:(NSEvent *)event {
    if (![self isSearching] || event.type != NSEventTypeKeyDown) return NO;
    NSEventModifierFlags f = event.modifierFlags & (NSEventModifierFlagCommand | NSEventModifierFlagControl | NSEventModifierFlagOption);
    if (f) return NO;
    NSString *k = nil;
    switch (event.keyCode) {
        case 53: k = @"Escape"; break;
        case 51: k = @"Backspace"; break;
        case 36: case 76: k = @"Enter"; break;
        case 48: case 123: case 124: case 125: case 126: return NO;
        default: { NSString *c = event.characters; if (c.length && [c characterAtIndex:0] >= 0x20 && [c characterAtIndex:0] != 0x7F) k = c; }
    }
    if (!k) return NO;
    NSData *d = [NSJSONSerialization dataWithJSONObject:@[k] options:0 error:nil];
    NSString *arr = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
    [_web evaluateJavaScript:[NSString stringWithFormat:@"window.SKPalette&&SKPalette.native&&SKPalette.native.key(%@[0])", arr] completionHandler:nil];
    return YES;
}

- (void)userContentController:(WKUserContentController *)ucc didReceiveScriptMessage:(WKScriptMessage *)message {
    if (![message.body isKindOfClass:[NSString class]]) return;
    NSData *data = [(NSString *)message.body dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *m = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    if (![m isKindOfClass:[NSDictionary class]]) return;
    NSString *t = m[@"t"];
    if ([t isEqualToString:@"pal-ins"]) {
        NSString *s = m[@"s"]; BOOL co = [m[@"copyOnly"] boolValue];
        dispatch_async(dispatch_get_main_queue(), ^{ [self insert:s copyOnly:co]; });
    } else if ([t isEqualToString:@"pal-pin"]) {
        _pinned = [m[@"on"] boolValue];
    } else if ([t isEqualToString:@"pal-hide"]) {
        dispatch_async(dispatch_get_main_queue(), ^{ [self hide]; });
    } else if ([t isEqualToString:@"pal-search"]) {
        _searching = [m[@"on"] boolValue];
    } else if ([t isEqualToString:@"pal-save"]) {
        NSString *k = m[@"k"], *v = m[@"v"];
        if (![k isKindOfClass:[NSString class]] || ![v isKindOfClass:[NSString class]]) return;
        id obj = [NSJSONSerialization JSONObjectWithData:[v dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:nil];
        if (obj && ([k isEqualToString:@"fav"] || [k isEqualToString:@"recent"] || [k isEqualToString:@"pin"])) {
            [self state][k] = obj; if ([k isEqualToString:@"pin"]) _pinned = [obj boolValue]; [self persist];
        }
    } else if ([t isEqualToString:@"pal-drag"]) {
        int s = [m[@"s"] intValue];
        if (s == 1) { _drag = 1; _dragMouse = [NSEvent mouseLocation]; _dragOrigin = _win.frame.origin; }
        else if (s == 2 && _drag) { NSPoint c = [NSEvent mouseLocation]; [_win setFrameOrigin:NSMakePoint(_dragOrigin.x + c.x - _dragMouse.x, _dragOrigin.y + c.y - _dragMouse.y)]; }
        else { if (_drag) [self saveFrame]; _drag = 0; }
    } else if ([t isEqualToString:@"pal-size"]) {
        int s = [m[@"s"] intValue];
        if (s == 1) { _size = 1; _sizeMouse = [NSEvent mouseLocation]; _sizeFrame = _win.frame; }
        else if (s == 2 && _size) {
            NSPoint c = [NSEvent mouseLocation];
            CGFloat w = MAX(320, _sizeFrame.size.width + (c.x - _sizeMouse.x)), h = MAX(240, _sizeFrame.size.height - (c.y - _sizeMouse.y));
            [_win setFrame:NSMakeRect(_sizeFrame.origin.x, NSMaxY(_sizeFrame) - h, w, h) display:YES animate:NO];     // the top left corner stays
        } else { if (_size) [self saveFrame]; _size = 0; }
    }
}

@end
