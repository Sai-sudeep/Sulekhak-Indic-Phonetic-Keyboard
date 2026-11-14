// SKKeyPass: the keys that finish a word and then belong to the application (Cmd+A, Cmd+C, arrows, Home/End, Enter ...).
//
// THE PROBLEM THIS SOLVES (Mac). While a word is being typed it is "marked text" in the application. A shortcut such as Cmd+A has to
// finish the word first (the choice is written into the text) and then reach the application. The keyboard used to do both inside the
// same key press: write the word, then answer "I did not use this key" so that the application runs the shortcut. Many applications
// (Chrome, Google Sheets and Docs, Electron programs, some native views) treat a key press during which the input method wrote text as
// a key press that the input method used, and drop the shortcut. The result: the first Cmd+A only finished the word, the second one
// selected everything.
//
// THE FIX. After the word has been written the original key press is kept back (the keyboard answers "used") and the same key press is
// sent again a moment later, when the word is already in the text. It needs the Accessibility permission (macOS only lets a program
// send key presses with it, the on-screen keyboard asks for the same permission). Without it the old behaviour stays.
#import <Cocoa/Cocoa.h>

#ifdef __cplusplus
extern "C" {
#endif

/// YES for a key press that Sulekhak itself sent again (never handle it a second time).
BOOL SKKeyIsReposted(NSEvent *event);

/// Call right after a word was written into the application during `event`, instead of answering NO ("not mine").
/// YES  = the key press is kept back and sent again shortly: the caller answers YES.
/// NO   = nothing was changed (no permission, a plain text key, switched off): the caller answers NO as before.
BOOL SKPassKeyAfterCommit(NSEvent *event);

#ifdef __cplusplus
}
#endif
