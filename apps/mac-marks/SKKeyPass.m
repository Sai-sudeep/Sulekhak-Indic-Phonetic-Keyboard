#import "SKKeyPass.h"
#import <ApplicationServices/ApplicationServices.h>

static const int64_t kSKRepostMark = 0x534B5031;        // 'SKP1' in the "source user data" field of the key press we send

static void SKPassTrace(NSString *m) {                  // same switch and file as the typing trace of the keyboard
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"SKImeTrace"]) return;
    NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Logs/SulekhakIME.log"];
    NSString *line = [NSString stringWithFormat:@"%@ keypass: %@\n", [NSDate date], m];
    NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:path];
    if (!fh) { [line writeToFile:path atomically:NO encoding:NSUTF8StringEncoding error:nil]; return; }
    [fh seekToEndOfFile]; [fh writeData:[line dataUsingEncoding:NSUTF8StringEncoding]]; [fh closeFile];
}

BOOL SKKeyIsReposted(NSEvent *event) {
    CGEventRef c = event.CGEvent;
    return c && CGEventGetIntegerValueField(c, kCGEventSourceUserData) == kSKRepostMark;
}

// Which keys are worth sending again: every shortcut (Command, Control or Option held), the keys that move the caret or select
// (arrows, Home, End, Page Up/Down, forward delete, function keys), and Return, Enter, Tab. A plain letter or punctuation key is not
// one of them: it would be typed a moment late and could swap places with the next key.
static BOOL KeyWorthRepost(NSEvent *e) {
    NSEventModifierFlags f = e.modifierFlags;
    if (f & (NSEventModifierFlagCommand | NSEventModifierFlagControl | NSEventModifierFlagOption)) return YES;
    unsigned short kc = e.keyCode;
    if (kc >= 123 && kc <= 126) return YES;                                   // arrows
    if (kc == 115 || kc == 119 || kc == 116 || kc == 121 || kc == 117) return YES;   // Home End PgUp PgDn forward delete
    if (kc == 36 || kc == 76 || kc == 48) return YES;                         // Return, Enter, Tab
    NSString *c = e.characters;
    unichar u = c.length == 1 ? [c characterAtIndex:0] : 0;
    if (u >= 0xF700 && u <= 0xF8FF) return YES;                               // function keys and the other special keys
    return NO;
}

BOOL SKPassKeyAfterCommit(NSEvent *e) {
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    if ([d boolForKey:@"SKNoKeyRepost"]) return NO;                           // switch off: defaults write com.saisudeep.inputmethod.OdiaPhonetic SKNoKeyRepost -bool YES
    if (!e || !KeyWorthRepost(e)) return NO;
    CGEventRef src = e.CGEvent;
    if (!src) { SKPassTrace(@"no CGEvent for this key, old behaviour"); return NO; }
    if (!AXIsProcessTrusted()) {
        // Ask once (the system dialog), then keep the old behaviour until the permission is given.
        if (![d boolForKey:@"SKAskedKeyPassAccess"]) {
            [d setBool:YES forKey:@"SKAskedKeyPassAccess"];
            NSDictionary *opts = @{(__bridge id)kAXTrustedCheckOptionPrompt: @YES};
            AXIsProcessTrustedWithOptions((__bridge CFDictionaryRef)opts);
        }
        SKPassTrace([NSString stringWithFormat:@"no Accessibility permission, key %hu passed the old way", e.keyCode]);
        return NO;
    }
    // never twice in a row for the same key (a safety net against a loop)
    static unsigned short lastKc = 0xFFFF; static CFAbsoluteTime lastT = 0;
    CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
    if (e.keyCode == lastKc && now - lastT < 0.06) { SKPassTrace(@"same key again within 60 ms, old behaviour"); return NO; }
    lastKc = e.keyCode; lastT = now;

    CGEventRef down = CGEventCreateCopy(src), up = CGEventCreateCopy(src);
    if (!down || !up) { if (down) CFRelease(down); if (up) CFRelease(up); return NO; }
    CGEventSetType(down, kCGEventKeyDown);
    CGEventSetType(up, kCGEventKeyUp);
    CGEventSetIntegerValueField(down, kCGKeyboardEventAutorepeat, 0);
    CGEventSetIntegerValueField(up, kCGKeyboardEventAutorepeat, 0);
    CGEventSetIntegerValueField(down, kCGEventSourceUserData, kSKRepostMark);
    CGEventSetIntegerValueField(up, kCGEventSourceUserData, kSKRepostMark);
    SKPassTrace([NSString stringWithFormat:@"key %hu flags %lx kept back, sent again after the word was written", e.keyCode, (unsigned long)e.modifierFlags]);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.02 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        CGEventPost(kCGHIDEventTap, down);
        CGEventPost(kCGHIDEventTap, up);
        CFRelease(down); CFRelease(up);
    });
    return YES;
}
