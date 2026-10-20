# Sulekhak for iPad and iPhone (system keyboard)

A real iPadOS / iOS keyboard: type with English letters in any app and get Odia, Devanagari, Assamese or Bangla, plus a Phonetic (IPA) mode and plain English.
Same language engine as the web, Android and Windows apps (JavaScript in JavaScriptCore). It asks for no Full Access, has no network code, and keeps what you choose on the device only.

If you only want to type inside Sulekhak itself, the web app needs no install file: open `sai-sudeep.github.io/assets/tools/sulekhak.html` in Safari, tap Share, Add to Home Screen.

## Install (free, no paid Apple account)

Apple only allows an app that is not from the App Store to be installed after it is signed for your own Apple ID, and a free Apple ID signature lasts 7 days.
These tools sign it for you and renew it in the background, so it behaves like an install-once app:

* **AltStore** (altstore.io): install AltServer on a Mac or PC, install AltStore on the iPad, then open `Sulekhak-iPad.ipa` from the Releases page with AltStore. Keep AltServer running on the same Wi-Fi once a week.
* **SideStore** (sidestore.io): the same, but it renews on the iPad itself.
* **Sideloadly** (sideloadly.io): sign and install from a Mac or PC with a cable; renew by repeating.

A paid Apple Developer account ($99 a year) makes the signature last a year, and TestFlight installs need no warnings at all. The same project signs with that account in Xcode: `brew install xcodegen`, `cd ios`, `xcodegen generate`, open `Sulekhak.xcodeproj`, choose your team, run.

After installing: Settings > General > Keyboard > Keyboards > Add New Keyboard > Sulekhak. In any app, touch and hold the globe key and choose Sulekhak. The bottom left key switches the language.

## Typing features

* **Swipe typing**, on by default (the same method as the Android keyboard): put a finger on the first letter of a word and drag it over the letters, then lift it. The words that fit appear in the bar (marked *Swiped*), ranked by the language model together with the word before; press space, or tap a word, to put it in. Backspace drops them; any other key takes the first one and goes on. The scribble button on the bar turns swipe typing on or off. It works in Odia, Devanagari, Assamese and Bangla.
* **Smart words and next words**: the same bigram and trigram language model as the Mac, Windows, Android and web typists. While you type, its words join the list; after a word, the bar shows the words that usually follow (marked *Next*), and a tap puts one in. The model files are memory-mapped and read only when you start typing, and they are let go when iOS asks for memory back. If the system ever stops the keyboard while the model is loading, the keyboard switches the model off by itself and goes on with the rule engine alone; touch and hold the scribble button to switch it on again.
* **Rare signs**: touch and hold the `` ` `` / `~` / `'` key for the avagraha, Isshar, the Odia fractions and the other signs no letter key gives; touch and hold the language key for every character of the script.
* On this keyboard `*` and `|` are plain keys. (The Shift+8 list of rare signs is for the Mac, Windows and web typists, which have a physical keyboard.)
## What it is and what it is not (yet)

* Candidates come from the rule engine, the built-in word list, the language model and the words you have chosen before. The model needs the data files `sk_*.txt`, `sk_cfg.json`, `sk_ng.bin` and `sk_idx.bin` in `SulekhakKeyboard/`; the GitHub build downloads them from the Sulekhak web typist pack. Without them the keyboard still works with the rule engine alone.
* What you choose is kept on this device (`sulekhak.learned.v1`, up to 3000 words). It is not synced to the Mac `sulekhak-learn.json`, because that needs the App Groups feature of a paid account.
* Not tested on a real iPad by me: the GitHub build proves it compiles, nothing more. Please tell me what looks wrong.

## Source

`project.yml` is an XcodeGen file. `SulekhakKeyboard/` is the keyboard extension (`KeyboardViewController.swift` the keys and bar, `SKEngine.swift` the engine host, `SmartEngine.swift` + `ios_smart.js` + `sulekhak.js` the language model and swipe decoding, `SwipeRecognizer.swift` the finger path, `ScriptPages.swift` the character pages, `ios_ime.js`, `engine.js`, `phon-*.js`); `SulekhakApp/` is the small app that explains how to turn it on.
