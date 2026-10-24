# Desktop keyboard mapping: one specification, three implementations

`apps/core/keymap/sulekhak-keymap.json` says, for each **state** (idle, word, digits, dots, sym) and each **key class** (letter, mark, `>`, digits, `.`, `|`, `*`, other punctuation, Space, Enter, Esc, Backspace, Tab, arrows, page keys, selection keys, chords) what happens, as an ordered list of **effects** (start, append, commit, commitAuto, commitSpace, commitTyped, pick, bksp, discard, candidate/page next/previous, nukta, delCodepoint, pass, swallow). A few rules are conditional on whether the list has several pages, or whether a number points at a choice that exists.

| Implementation | File | Used by |
|---|---|---|
| JavaScript reference | `core/keymap/keymachine.js` | the tests, the web typist |
| C# | `windows/KeyMachine.cs` + generated `KeyTable.g.cs` | Windows hook mode |
| C++ | `windows/tip/tipcore.cpp` + generated `keytable.inc` | Windows text service (Win+Space) |
| Objective-C | `OdiaController.m` (macOS) | macOS. **Not generated from the spec**: it is the reference the spec was derived from, and it has not been changed. |

Conformance: 199 key-sequence vectors (`vectors.json`) + 11 nukta vectors run in JS; the same vectors run in C# (84 that apply to the C# machine); the C++ core is compared against the JS decision table for every state × class × condition (535 decisions). All pass; CI repeats them and also checks the generated files are current.

## Decisions (where Windows used to differ from macOS and now follows it)

1. **Shift+`.` (`>`) on its own** puts a nukta on the ଡ/ଢ of the word just typed; with none, it types a lone nukta. (Windows did not.) Also in Devanagari (ड़, ढ़) and Bangla (ড়, ঢ়). Inside a word `>` is the virama+ZWNJ marker.
2. **`` ` ``, `~`, `'` start a word** (they are scheme keys): halant, chandrabindu/anusvara, nukta marker.
3. **`.`** opens the danda / full stop / double danda list; `|` and `*` open symbol lists; a digit typed alone starts a number (Odia digits first, ASCII second).
4. **Space** always types a space after the word. (Windows dropped it after a word ending in halant or ZWNJ.)
5. **Enter** picks the highlighted word with a following space unless the word goes on, and does not also start a new line. (Windows did both.) With no word being typed it is a normal new line.
6. **Left/Right** with a single page of choices take the word and then move the caret (Windows swallowed the key). With several pages they turn the page.
7. **Shift+arrow/Home/End/Page** take the word and extend the selection in the application.
8. **Backspace with no word being typed** removes one code point on macOS. On Windows the text service does the same inside TSF-aware applications; elsewhere the application decides (see limits in `engineering.md`).
9. **Arrow, Home, End, Page keys never move the caret by themselves**: the application moves over whole letter clusters. Only candidate navigation uses them while a word is being typed.

## Findings about macOS found by reading (not executing) the source

* The macOS behaviour above is taken from `handleEvent` in `OdiaController.m` by reading it. It was **not run** in this pass because no Mac was available to the tooling. The Windows work was written to match it; if the Mac turns out to differ from the table, the table (and the three implementations) should be corrected, not the other way round, since the Mac is the reference users know.
* Mac Backspace removes one code point because the system would otherwise remove a whole letter plus signs. That is deliberate, and is copied.

## Manual checklist for macOS (10 minutes, in TextEdit)

Select the Sulekhak input source, then type and compare with the right column.

| Type | Expect |
|---|---|
| `badi` Space | ବଡି followed by a space |
| `badi` then `>` (Shift+.) | ବଡ଼ି (nukta on ଡ) |
| `>` alone, then anything | a lone nukta ଼ |
| `ba` `` ` `` then Space | ବ୍ and a space |
| `ba` then Enter | ବ and a space; no new line |
| Enter with nothing typed | new line |
| `.` then `1` | । followed by a space |
| `ba` Esc | nothing typed |
| `ba` Left (single page of choices) | ବ typed, caret moved left |
| `ba` Shift+Left | ବ typed, selection extended |
| type କ୍ଷି then Backspace | କ୍ଷ (only the vowel sign removed) |
| type abc then Backspace | ab |
| Ctrl+Option+K | on-screen keyboard toggles |

If a row differs, note the row and the actual result; that is a spec correction to make.

## Adding a platform (Linux later)

Write an adapter that turns the platform's key event into one of the key classes and applies the effects; generate the table from the JSON like `gen_cs.js` does; run `vectors.json` through it. Do not add rules in the adapter.
