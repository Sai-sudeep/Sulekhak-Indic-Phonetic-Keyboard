// The Unicode symbols palette for the Mac input method: a floating, draggable, resizable window (the same page as the web typist's dialog),
// opened with Option+, or from the Sulekhak menu. A click on a symbol types the character into the program being typed in, or copies it when there is no text box.
#import <Cocoa/Cocoa.h>

@interface PalettePanel : NSObject
+ (instancetype)shared;
+ (void)installHotKey;              // Option+, from anywhere (no Accessibility permission needed)
+ (BOOL)hotKeyActive;
- (void)toggle;
- (BOOL)isVisible;
- (BOOL)isSearching;                // the palette's search box has the typing (the input method forwards the keys)
- (BOOL)handleSearchKey:(NSEvent *)event;   // YES when the key was taken by the search box
@end
