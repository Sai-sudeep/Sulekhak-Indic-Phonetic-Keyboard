# Sulekhak for iPad and iPhone (system keyboard)

A real iPadOS / iOS keyboard: type with English letters in any app and get Odia, Devanagari, Assamese or Bangla, plus a Phonetic (IPA) mode and plain English.
Same language engine as the web, Android and Windows apps (JavaScript in JavaScriptCore). It asks for no Full Access, has no network code, and keeps what you choose on the device only.

If you only want to type inside Sulekhak itself, the web app needs no install file: open `sai-sudeep.github.io/assets/tools/sulekhak-ipad/` in Safari, tap Share, Add to Home Screen.

## Install (free, no paid Apple account)

Apple only allows an app that is not from the App Store to be installed after it is signed for your own Apple ID, and a free Apple ID signature lasts 7 days.
These tools sign it for you and renew it in the background, so it behaves like an install-once app:

* **AltStore** (altstore.io): install AltServer on a Mac or PC, install AltStore on the iPad, then open `Sulekhak-iPad.ipa` from the Releases page with AltStore. Keep AltServer running on the same Wi-Fi once a week.
* **SideStore** (sidestore.io): the same, but it renews on the iPad itself.
* **Sideloadly** (sideloadly.io): sign and install from a Mac or PC with a cable; renew by repeating.

A paid Apple Developer account ($99 a year) makes the signature last a year, and TestFlight installs need no warnings at all. The same project signs with that account in Xcode: `brew install xcodegen`, `cd ios`, `xcodegen generate`, open `Sulekhak.xcodeproj`, choose your team, run.

After installing: Settings > General > Keyboard > Keyboards > Add New Keyboard > Sulekhak. In any app, touch and hold the globe key and choose Sulekhak. The bottom left key switches the language.

## What it is and what it is not (yet)

* Candidates come from the rule engine, the built-in word list and the words you have chosen before (the same order as the other apps without their language model). The big language-model files of the Mac, Windows and Android apps are left out because an iOS keyboard may use very little memory.
* What you choose is kept on this device (`sulekhak.learned.v1`, up to 3000 words). It is not synced to the Mac `sulekhak-learn.json`, because that needs the App Groups feature of a paid account.
* Not tested on a real iPad by me: the GitHub build proves it compiles, nothing more. Please tell me what looks wrong.

## Source

`project.yml` is an XcodeGen file. `SulekhakKeyboard/` is the keyboard extension (`KeyboardViewController.swift` the keys and bar, `SKEngine.swift` the engine host, `ios_ime.js`, `engine.js`, `phon-*.js`); `SulekhakApp/` is the small app that explains how to turn it on.
