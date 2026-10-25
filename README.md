<p align="center">
  <img src="docs/img/banner.png" alt="Sulekhak Indic Phonetic Keyboard. Type Odia first, then Devanagari, Marathi, Assamese and Bangla with English letters on Mac, Windows, Android and the web." width="100%">
</p>

# ସୁलेখk · Sulekhak Indic Phonetic Keyboard

## type your way

**Type in your own language with plain English letters. Odia comes first.** Say it the way it sounds: `buRhaaTi kahilaa, "baagZdebiinku namaskaar"` → ବୁଢ଼ାଟି କହିଲା, "ବାଗ୍‌ଦେବୀଙ୍କୁ ନମସ୍କାର". A small box offers real words, Sulekhak learns the ones you pick, and after each word it suggests the next one.

## 🗣️ Languages and writing styles

| | Script | What you get |
|---|---|---|
| **ଓଡ଼ିଆ** | **Odia** | The main language. Smart word choices (vowels optional), conjuncts, next-word suggestions, and the rare letters ୠ ଌ ୡ ଽ ୰ |
| **देवनागरी** | **Devanagari** | Hindi and other languages written in Devanagari, with a choice of full conjuncts (कुण्डल) or anusvara ं |
| **मराठी** | **Marathi** (Devanagari) | Switch the **Marathi ळ** option on and `kuNDaLa` gives **कुण्डळ**; with it off, **कुण्डल** |
| **অসমীয়া** | **Assamese** | Assamese letters **ৰ** and **ৱ** (`byavahar` → ব্যৱহাৰ), kept apart from the Bangla ra and ba. Wherever ত্ is possible, the **ৎ** spelling is offered right beside it (`jagat` → জগত · জগৎ) |
| **বাংলা** | **Bangla** | Bangla script from the same keys and the same dictionary |
| **English** | Mixed typing, and an English keyboard | Every choice list also offers what you typed, so English words sit between Odia words. The **English** mode (Mac, Windows, Android, iPad and iPhone) completes words, corrects spelling when you press Space (`teh` → the; Backspace puts back what you typed) and learns the words you choose, on your own device only |
| **IPA · extIPA · IAST** | Phonetic symbols (web, Mac, Windows, Android) | Type a key, then pick the symbol that looks like it |

Every language is available on Mac, Windows, Android, iPad and iPhone, Keyman and the web: pick your device in the Download table below.

The same word in each script: `kuNDaLa` → କୁଣ୍ଡଳ (Odia) · कुण्डल (Devanagari) · कुण्डळ (Marathi option) · কুণ্ডল (Bangla)

<p align="center"><img src="docs/img/languages.png" alt="Odia, Devanagari, Assamese, Bangla, English and phonetic symbols" width="100%"></p>

### English typing

Switch to **English** and the same box offers completions and spelling fixes while you type English: the letters stay in your text, **Space** puts in the first suggestion (`teh ` → `the `, `dont ` → `don't `), a tap picks another one, and **Backspace** straight after a correction gives back exactly what you typed. Words you pick or type often are remembered and move up, and a correction you refuse is not made again. After a word and a space it also offers the **next word** (`thank ` → you, god, the …; at the start of a sentence the usual first words) on every platform that types English: Mac and Windows show them under the cursor (**Tab** takes the highlighted one, **Shift+Tab** moves the highlight, a click takes the one you click; a menu item switches them off), Android, iPhone/iPad and the web typist show them in the suggestion strip. In Keyman, install `sai_sudeep.en.sulekhak.model.kmp` for English word completion next to any English keyboard (there is no spelling correction or next-word prediction in Keyman). Everything is learnt and kept on your own device: this public app has no sign-in and asks for no network permission on Android and iPhone/iPad. (The word lists are built from open sources; see `core/english` in the app sources.)

## ✨ ZWNJ done right
Type **Z** after the letter to get a halant followed by a zero-width non-joiner, so the letters stay apart the way Odia is written. `Z` is halant + ZWNJ, `z` is ZWNJ alone (hold `z` on a phone or in the key guide for **ZWJ**), and the backtick is the halant alone. In a word with a Z the choices run: the ZWNJ spelling, what you typed, the same without ZWNJ, the same with ZWJ, then every other choice. `bagdebi` also finds **ବାଗ୍‌ଦେବୀ** straight away.

In the choice list the three look different on purpose: halant + ZWNJ is shown as **୍ + ┊**, halant + ZWJ as **୍ + [**, and a plain halant is just **୍**.

| ZWNJ (✓) | Without ZWNJ (✗) |
|---|---|
| ଦିଗ୍‌ଦର୍ଶନ | ଦିଗ୍ଦର୍ଶନ |
| ବାକ୍‌ଶକ୍ତି | ବାକ୍ଶକ୍ତି |
| ଋଗ୍‌ବେଦ | ଋଗ୍ବେଦ |
| ଜଗଦ୍‌ଜନନୀ | ଜଗଦ୍ଜନନୀ |
| ଦିଗ୍‌ବିଜୟ | ଦିଗ୍ବିଜୟ |
| ଉଦ୍‌ବେଗ | ଉଦ୍ବେଗ |
| ଉଦ୍‌ବିଗ୍ନ | ଉଦ୍ବିଗ୍ନ |

Both spellings are valid, and both are in the dictionary: ବାଙ୍‌ମୟ / ବାଙ୍ମୟ · ତତ୍‌ସମ / ତତ୍ସମ · ତଦ୍‌ଭବ / ତଦ୍ଭବ.

<p align="center"><img src="docs/img/zwnj.png" alt="ZWNJ spellings compared with the spellings without ZWNJ" width="100%"></p>

Want the ya-phala form of ର୍ୟ? A ZWJ between the ra and the halant gives **ର‍୍ୟ** (ର + ZWJ + ୍ + ୟ).

## ଡ ଢ ଡ଼ ଢ଼
`D` ଡ · `Dh` ଢ · `R` ଡ଼ (U+0B5C) · `Rh` ଢ଼ (U+0B5D). Type `>` after `D` or `Dh` for the nukta spelling (ଡ + ଼). Both look the same on screen.

<p align="center"><img src="docs/img/dtab.png" alt="The four letters ଡ ଢ ଡ଼ ଢ଼ and the keys that type them" width="100%"></p>

Lowercase `d` and `dh` list the same letters: `d` → ଦ · ଡ · ଡ଼ (ଡ + nukta) · ଡ଼ (U+0B5C), and `dh` → ଧ · ଢ · ଢ଼ (ଢ + nukta) · ଢ଼ (U+0B5D).

## ✳️ Rare Odia signs on one key (PC keyboards)
On the Mac app, Windows and the web typist, **Shift + 8 ( \* )** opens a small list: the star itself first, then the Odia signs that no letter key gives. Press 1 to 9 to pick (space or Enter takes the highlighted one).

| Pick | Sign | Name |
|---|---|---|
| 1 | * | the star |
| 2 | ଽ | avagraha (U+0B3D) |
| 3 | ୰ | Isshar (U+0B70) |
| 4 | ୲ | fraction one quarter (U+0B72) |
| 5 | ୳ | fraction one half (U+0B73) |
| 6 | ୴ | fraction three quarters (U+0B74) |
| 7 | ୵ | fraction one sixteenth (U+0B75) |
| 8 | ୶ | fraction one eighth (U+0B76) |
| 9 | ୷ | fraction three sixteenths (U+0B77) |
| next page | ୕ | sign overline (U+0B55) |

The **|** key (Shift + backslash) lists ।, | and \\ the same way. Phones and tablets keep their own shift-number rows, so this is for PC keyboards only. The picture under *Languages and writing styles* shows the same list.

Other keys, in the order they are offered: `v` ଵ · ଭ · ବ · ୱ (ଵ first only where it is a valid spelling), `w` ୱ, `s` / `S` ସ · ଶ · ଷ, `sh` / `Sh` ଷ · ଶ, `ksh`, `Ksh`, `x`, `X`, `khy`, `khya` କ୍ଷ, `ru` ରୁ · ଋ · ୠ · ୃ · ୄ, `e` ଏ · େ, `ai` ଐ · ୈ, `o` ଓ · ୋ, `au` / `ou` ଔ · ୌ.

## ⬇️ Download

Every platform comes as the **all-in-one** (Odia first, then Devanagari, Assamese, Bangla and Phonetic IPA) and as a **separate keyboard for each language**, so you can install only the language you write. Every separate keyboard also carries **English** (with its English language model) and **Phonetic IPA**, so whichever one you install, you can switch between at least two languages: your own, and English. All files are also on the [Releases page](https://github.com/Sai-sudeep/Sulekhak-Indic-Phonetic-Keyboard/releases/latest); GitHub builds them from the source in this repository.

| | 🍎 Mac | 🪟 Windows | 🤖 Android | 📱 iPad · iPhone | ⌨️ Keyman (any device) | 🌐 Web |
|---|---|---|---|---|---|---|
| **All-in-one**<br>Odia, Devanagari, Assamese, Bangla, Phonetic | [DMG](https://github.com/Sai-sudeep/Sulekhak-Indic-Phonetic-Keyboard/releases/latest/download/Sulekhak-Mac.dmg) · [ZIP (builds on your Mac)](https://github.com/Sai-sudeep/Sulekhak-Indic-Phonetic-Keyboard/raw/main/Sulekhak-Mac.zip) | [Installer](https://github.com/Sai-sudeep/Sulekhak-Indic-Phonetic-Keyboard/releases/latest/download/Sulekhak-Windows-Setup.exe) · [portable EXE](https://github.com/Sai-sudeep/Sulekhak-Indic-Phonetic-Keyboard/releases/latest/download/Sulekhak-Windows.exe) | [APK](https://github.com/Sai-sudeep/Sulekhak-Indic-Phonetic-Keyboard/releases/latest/download/Sulekhak-Android.apk) | [IPA](https://github.com/Sai-sudeep/Sulekhak-Indic-Phonetic-Keyboard/releases/latest/download/Sulekhak-iPad.ipa) · [web app, no install](https://sai-sudeep.github.io/assets/tools/sulekhak.html) | [KMP](https://github.com/Sai-sudeep/Sulekhak-Indic-Phonetic-Keyboard/raw/main/keyman/sulekhak_all.kmp) | [sulekhak.html](https://sai-sudeep.github.io/assets/tools/sulekhak.html) |
| **ଓଡ଼ିଆ** Odia | [DMG](https://github.com/Sai-sudeep/Sulekhak-Indic-Phonetic-Keyboard/releases/latest/download/Sulekhak-Mac-Odia.dmg) | [EXE](https://github.com/Sai-sudeep/Sulekhak-Indic-Phonetic-Keyboard/releases/latest/download/Sulekhak-Windows-Odia.exe) | [APK](https://github.com/Sai-sudeep/Sulekhak-Indic-Phonetic-Keyboard/releases/latest/download/Sulekhak-Android-Odia.apk) | in the iPad app (language key) | [KMP](https://github.com/Sai-sudeep/Sulekhak-Indic-Phonetic-Keyboard/raw/main/keyman/sulekhak_odia.kmp) + [words](https://github.com/Sai-sudeep/Sulekhak-Indic-Phonetic-Keyboard/raw/main/keyman/sai_sudeep.or.sulekhak.model.kmp) | [sulekhak-odia.html](https://sai-sudeep.github.io/assets/tools/sulekhak-odia.html) |
| **देवनागरी** Devanagari (Marathi option) | [DMG](https://github.com/Sai-sudeep/Sulekhak-Indic-Phonetic-Keyboard/releases/latest/download/Sulekhak-Mac-Devanagari.dmg) | [EXE](https://github.com/Sai-sudeep/Sulekhak-Indic-Phonetic-Keyboard/releases/latest/download/Sulekhak-Windows-Devanagari.exe) | [APK](https://github.com/Sai-sudeep/Sulekhak-Indic-Phonetic-Keyboard/releases/latest/download/Sulekhak-Android-Devanagari.apk) | in the iPad app (language key) | [KMP](https://github.com/Sai-sudeep/Sulekhak-Indic-Phonetic-Keyboard/raw/main/keyman/sulekhak_devanagari.kmp) + [words](https://github.com/Sai-sudeep/Sulekhak-Indic-Phonetic-Keyboard/raw/main/keyman/sai_sudeep.hi.sulekhak.model.kmp) | [sulekhak-devanagari.html](https://sai-sudeep.github.io/assets/tools/sulekhak-devanagari.html) |
| **অসমীয়া** Assamese | [DMG](https://github.com/Sai-sudeep/Sulekhak-Indic-Phonetic-Keyboard/releases/latest/download/Sulekhak-Mac-Assamese.dmg) | [EXE](https://github.com/Sai-sudeep/Sulekhak-Indic-Phonetic-Keyboard/releases/latest/download/Sulekhak-Windows-Assamese.exe) | [APK](https://github.com/Sai-sudeep/Sulekhak-Indic-Phonetic-Keyboard/releases/latest/download/Sulekhak-Android-Assamese.apk) | in the iPad app (language key) | [KMP](https://github.com/Sai-sudeep/Sulekhak-Indic-Phonetic-Keyboard/raw/main/keyman/sulekhak_assamese.kmp) + [words](https://github.com/Sai-sudeep/Sulekhak-Indic-Phonetic-Keyboard/raw/main/keyman/sai_sudeep.as.sulekhak.model.kmp) | [sulekhak-assamese.html](https://sai-sudeep.github.io/assets/tools/sulekhak-assamese.html) |
| **বাংলা** Bangla | [DMG](https://github.com/Sai-sudeep/Sulekhak-Indic-Phonetic-Keyboard/releases/latest/download/Sulekhak-Mac-Bangla.dmg) | [EXE](https://github.com/Sai-sudeep/Sulekhak-Indic-Phonetic-Keyboard/releases/latest/download/Sulekhak-Windows-Bangla.exe) | [APK](https://github.com/Sai-sudeep/Sulekhak-Indic-Phonetic-Keyboard/releases/latest/download/Sulekhak-Android-Bangla.apk) | in the iPad app (language key) | [KMP](https://github.com/Sai-sudeep/Sulekhak-Indic-Phonetic-Keyboard/raw/main/keyman/sulekhak_bangla.kmp) + [words](https://github.com/Sai-sudeep/Sulekhak-Indic-Phonetic-Keyboard/raw/main/keyman/sai_sudeep.bn.sulekhak.model.kmp) | [sulekhak-bangla.html](https://sai-sudeep.github.io/assets/tools/sulekhak-bangla.html) |
| **IPA · extIPA · IAST** Phonetic | [DMG](https://github.com/Sai-sudeep/Sulekhak-Indic-Phonetic-Keyboard/releases/latest/download/Sulekhak-Mac-Phonetic.dmg) | [EXE](https://github.com/Sai-sudeep/Sulekhak-Indic-Phonetic-Keyboard/releases/latest/download/Sulekhak-Windows-Phonetic.exe) | in every Android keyboard (the IPA button) | in the iPad app (language key) | not in Keyman | [sulekhak-phonetic.html](https://sai-sudeep.github.io/assets/tools/sulekhak-phonetic.html) |
| **English** mixed typing | in every Mac keyboard (**Control+Option+8**, or the input menu) | in the installer: **Sulekhak — English** in Win+Space, and **Ctrl+Alt+8** inside every Windows language keyboard | in every Android keyboard (the EN button) | in the iPad app (language key) | words only: [KMP](https://github.com/Sai-sudeep/Sulekhak-Indic-Phonetic-Keyboard/raw/main/keyman/sai_sudeep.en.sulekhak.model.kmp) (works with any English keyboard in Keyman) | [sulekhak-english.html](https://sai-sudeep.github.io/assets/tools/sulekhak-english.html) |

* **Mac.** A DMG holds the keyboard, an *Install* file (double-click it; the first time right-click → Open) and an *Uninstall* file. Editions are separate programs with their own names, so you can have several side by side (they share the Control+Option+K hot key and your learned words). The ZIP is the same keyboard as a folder that builds on your Mac (see below). Neither is notarised by Apple.
* **Windows.** Use the **Installer**: it adds Sulekhak to the Windows keyboard list (**Win+Space**), updates in place and keeps your words. The portable EXE needs no install but cannot appear in Win+Space. Neither is code-signed, so Windows may show a SmartScreen warning: choose **More info, Run anyway**. Details: [install and update](docs/install-and-update.md).
* **Android.** Signed with the project's release key, so each new APK installs over the previous one (if you have an older build installed, uninstall it once first). Android asks you to allow installing from your browser or files app. Check the key: [install and update](docs/install-and-update.md).
* **iPad and iPhone.** The IPA is a system keyboard for every app, with swipe typing (on by default), the language model's word choices and next-word suggestions, installed with AltStore, SideStore or Sideloadly ([how](docs/ios.md)). The web app needs no install file: open it in Safari, Share, Add to Home Screen.
* **Keyman.** Open the KMP file with Keyman (Windows, Mac, Linux, Android, iPad, iPhone); for the suggestion strip also install the matching *words* file. One keyboard per language, plus an all-in-one package, with the same key choices as the apps and every rare Odia sign ([how to type](keyman/README.md)).
* **Web.** Nothing to install. On a computer the web typist uses the full word list; phones, tablets and low-memory machines automatically get a lighter list. Both use the same language model (it ranks words by the one or two words before) and the same spelling rules, and offer just as many choices. On a phone or tablet you can also swipe across the on-screen keyboard to type a word.

## 📸 See it

<p align="center"><img src="docs/img/web-typist.png" alt="The web typist with the word choices box open" width="100%"></p>

<p align="center"><img src="docs/img/keyboards.png" alt="The 3D on-screen keyboard drawn as a Mac, Windows, iPad or Android keyboard" width="100%"></p>

<p align="center"><img src="docs/img/phone.png" alt="The phone keyboard with suggested next words" width="320"></p>

## 🚀 Install on a Mac in 3 steps
1. Unzip the download and double-click **Build and Install.command**. First time only: macOS may say the file is from the internet. Right-click it → Open → Open. If a window asks for the Command Line Tools, let it install, then double-click the file again. Everything the keyboard needs, including the dictionary and the language model, is inside the folder, so it installs and works offline.
2. Click the input icon in the menu bar and choose **ସୁलेখk**. Not in the list? System Settings → Keyboard → Input Sources → + → Odia → ସୁलेখk.
3. Start typing in any app. 🎉

Installing again later updates the keyboard in place and keeps your own words.

**Candidate box.** On Mac and Windows the input menu (Windows: the tray menu) has a *Candidate box* choice: follow the system, always light, or always dark. Special choices are marked in the list so they are never blank: a lone ZWNJ / ZWJ shows as `ZWNJ` / `ZWJ`, halant + ZWNJ as `◌୍ + ┊`, halant + ZWJ as `◌୍ + [`, and a bare sign as `◌`; these use a blue (joiners) or violet (signs) colour, different from normal words.

Output script: from the input-source menu, or Control+Option+1 Odia, 2 Devanagari, 3 Bangla, 6 Assamese, 7 Phonetic (IPA, extIPA, IAST). Control+Option+4 switches the Marathi ळ option on and off.

**3D on-screen keyboard.** The input menu has "3D keyboard: show / hide" (also Control+Option+K). It is the same keyboard as in the web tool, drawn as a Mac, Windows, iPad or Android keyboard, and clicking its keys types through the input method. macOS asks once for the Accessibility permission, which it needs to accept key presses from an on-screen keyboard. Make it bigger or smaller with the − and + buttons, **Control+Option+=** and **Control+Option+-**, or the matching input-menu items.

**Hover to see (Phonetic keyboard).** Point at a key on the 3D keyboard and a ring of bevelled tiles opens around it, one tile for every IPA, extIPA or IAST symbol that looks like that key. The strongest match is at the top, then clockwise; the small light under each tile is green (strong), yellow (medium) or orange (weak). Click a tile to type that symbol.

**What it learns (Mac, v17 / 3.0).** While you type, the Mac app keeps the words you pick, how often, and in which script, in one readable file, `~/Library/Application Support/LekhaniOdia/sulekhak-learn.json` ([format](docs/learning-cache-format.md)). The web typist can import it ("Import learning file") so the online suggestions improve too, and `tools/learn_merge.py` turns it into the plain word lists the Windows and Android apps read.

**Add to Sulekhak Dictionary (Mac).** Select a word or an expression in any app and add it to your own dictionary: click the small **+** that appears beside a mouse selection, press **Control+Option+D** (works for a keyboard selection too), use the input menu item, the **+ Dict** button of the 3D keyboard, or right-click → Services → *Add to Sulekhak Dictionary*. A box shows the word and a Roman spelling guessed for it; change it if you like, then add. Dictionary words are trusted (never filtered out as impossible spellings) and are stored in the same learning file and in `lexicon.tsv`.

## 🪟 Windows and 🤖 Android

> **Engineering status** (what is tested and what is not yet, the keyboard mapping spec, swipe evaluation, update rules): [docs/engineering.md](docs/engineering.md).
- **Android: [Sulekhak-Android.apk](https://github.com/Sai-sudeep/Sulekhak-Indic-Phonetic-Keyboard/releases/latest/download/Sulekhak-Android.apk)** (Android asks you to allow installing from your browser or files app; an older build must be uninstalled once, later ones update in place). Install it, open **Sulekhak**, switch the keyboard on, then choose it as your input method. It has the web keyboard's QWERTY layout, a number pad, symbols, emoji and Odia-letter pages, suggested next words, a globe key (and a long press on space) to change keyboard, a long press on a letter for its matras and conjuncts, a long press on the full stop for all punctuation, a long press on `'` or `~` for the rare signs, and, under **?123**, a page with every character of the script. Swipe typing is on from the start; the keyboard's ⚙ settings (*Swipe across the letters to type a word*) switch it off.
- **Windows: [Sulekhak-Windows-Setup.exe](https://github.com/Sai-sudeep/Sulekhak-Indic-Phonetic-Keyboard/releases/latest/download/Sulekhak-Windows-Setup.exe)** (installer, needs administrator rights once). It registers Sulekhak as a real Windows text service: press **Win+Space** and choose *Sulekhak — All Languages*, *Odia*, *Hindi*, *Marathi*, *Bangla*, *Assamese* or *English*. Inside a language keyboard, **Ctrl+Alt+8** types English (with suggestions) and the language's own key (Ctrl+Alt+1 Odia, 2 Hindi or Marathi, 3 Bangla, 6 Assamese) comes back. Roman letters you type are shown as the word being typed, with the candidate window beside it; Space, Enter or a number picks. **Ctrl+Alt+K** shows the 3D on-screen keyboard. It needs the Microsoft Edge WebView2 runtime (already present on current Windows 10 and 11). Updating means running the new Setup.exe over the old one; uninstalling keeps your words. The older one-file program ([Sulekhak-Windows.exe](https://github.com/Sai-sudeep/Sulekhak-Indic-Phonetic-Keyboard/releases/latest/download/Sulekhak-Windows.exe)) still works without installing, as a keyboard hook (tray menu on/off, **Ctrl+Alt+P** Phonetic/IPA; each language edition lists its own language, Phonetic and English, but English typing itself needs the installer's text service). Windows may show a "SmartScreen" warning because the files are not code-signed: choose **More info, Run anyway**.

**If the installed Windows app does not type:** it falls back to the keyboard-hook typing of the portable program whenever the Win+Space keyboard cannot work (no Sulekhak keyboard in your list yet, a refused registration, Windows on ARM), and the tray item **Check installation…** says why. Details: [docs/install-and-update.md](docs/install-and-update.md).

Both keep the words you pick and offer them first next time. These two apps were built and compiled by GitHub but have had less hands-on testing than the Mac and web versions, so please report anything odd in [Issues](https://github.com/Sai-sudeep/Sulekhak-Indic-Phonetic-Keyboard/issues).

## 🧭 Keys that differ by platform

The letter keys behave the same everywhere, because they all follow the same Sulekhak rules: `d` / `dh`, `y`, `w`, `v`, `sh` / `Sh`, `s` / `S`, `ksh` / `x` / `khy`, `ru`, `e`, `ai`, `o`, `au` and `ou` give the same choices, and Z, z, the backtick and `>` (nukta) work the same way. What differs is where the rare signs and the punctuation keys live, because a phone or tablet has no Shift + 8 list and Keyman works by fixed rules:

| | 🍎 Mac · 🪟 Windows · 🌐 web typist (computer) | 🤖 Android | 📱 iPad · iPhone | 🌐 web typist (phone, tablet) | ⌨️ Keyman |
|---|---|---|---|---|---|
| **\*** (Shift + 8) | opens the sign list: `*` first, then ଽ ୰ ୲ ୳ ୴ ୵ ୶ ୷ ୕ | a plain star | a plain star | a plain star | on a computer `*` and a letter gives a sign (`*a` ଽ); the touch star key is plain |
| **\|** (Shift + backslash) | opens the list ।, \|, \ | a plain bar; the danda । is on the symbols page and under a long press of the full stop | a plain bar | a plain bar; ।  ॥ are on the symbols page | types the danda । |
| **ଽ ୰ ୲ ୳ ୴ ୵ ୶ ୷ ୕ ୖ ୗ** | the `*` list (all but ୖ ୗ) | long press `'` or `~`, or the script page under **?123** | long press `` ` ``, `~` or `'` | long press `'` or `~`, or **Sym** then the **Odia** tab | `*a` ଽ, `*i` ୰, `*q` ୲, `*h` ୳, `*t` ୴, `*s` ୵, `*e` ୶, `*u` ୷, `*o` ୕, `*ai` ୖ, `*au` ୗ; or long press `'` / `~` on a phone; or the sixth touch page |
| **Every character of the script on one page** | not needed (the keyboard has the keys) | **?123**, then the ଅ key | long press the language key | **Sym**, then the **Odia** tab | the vowels-and-signs pages of the touch layout |
| **Choice lists** (ଦ ଡ ଡ଼ for `d`, ୟ ଯ for `y`, ...) | yes | yes | yes | yes | no list: Keyman types by fixed rules (`D` ଡ, `R` ଡ଼, `x` or `ksh` କ୍ଷ) |
| **Swipe typing** | not needed (a physical keyboard) | yes, on by default; ⚙ settings turn it off | yes, the scribble button on the bar (on by default) | yes, the *Gesture typing* box under the editor (on by default) | not available in Keyman |

The `*` and `|` lists are only for PC keyboards: the Mac app, Windows and the web typist on a computer. Phones and tablets keep their own shift-number rows and long presses instead, so a star or a bar typed there is always just a star or a bar.

## 👆 Swipe typing (phones and tablets)
Put a finger on the first letter of a word, slide it across the letters and lift it: the words that fit the path appear above the keys. Space (or a tap on a word) puts it in, Backspace drops the suggestions, and any other key takes the first word and carries on. It uses the same word list and rules as tapping, and it forgives a finger that brushes a neighbouring key on the way, a dropped inner *a* (you can swipe `rhibe` for ରହିବେ) and the chandrabindu words (ପାଇଁ, ମୁଁ), so ZWNJ and the nukta spellings come out as they do everywhere else, and the words you take rank higher next time. The path is also weighed against the word you typed just before it, by the same language model that orders the suggestions. It works in Odia, Devanagari, Assamese and Bangla.

| | How to turn it on or off | Default |
|---|---|---|
| 🌐 Web typist on a phone or tablet | the **Gesture typing** box under the editor | on |
| 📱 iPad · iPhone keyboard | the scribble button at the right of the suggestion bar | on |
| 🤖 Android keyboard | keyboard ⚙ settings, **Swipe across the letters to type a word** | on |

## 🧠 The language model
Every Sulekhak app, on every platform (Mac, Windows, Android, iPad and iPhone, and the web typist on a computer or a phone), orders its suggestions with the same bigram and trigram model: it looks at the one or two words you typed before and moves the likelier word to the front. The same model gives the *next word* suggestions after you finish a word, and weighs swiped paths. The spelling rules (the nukta, ZWNJ, `d` / `dh`, `y`, `w`, `sh` / `s` and the others) are shared too, so the same letters give the same choices wherever you type; the order of the lower choices can differ a little between the full list and the lighter one. The web typist on a computer uses the largest word list; the apps and the web on phones use a lighter one that fits in a phone's memory.

## ✍️ How to use
Type Odia the way it sounds, in English letters. A small box shows choices:

| Do this | To get this |
|---|---|
| 1–9 or click a choice | pick it (a space follows) |
| Space | accept the highlighted choice |
| Enter | accept it with a space; press again for a new line |
| ↑ ↓ Tab | move the highlight · ← → change page |
| Shift+Tab (PC) | the next page of choices when there is more than one page, otherwise the previous choice |
| Backspace | removes one letter · Esc cancels |
| Z / z / ` (backtick) | halant + ZWNJ (୍‌) / ZWNJ alone (hold for ZWJ) / halant (୍) |
| > | nukta (଼) for ଡ଼ ଢ଼ |

Good to know
- 🧠 Vowels optional. `pasnd`, `kn`, `pustk`, `krishna` find real words even if you skip or mix up vowels.
- ❜ Apostrophe words. `kn` / `ka'na` → କ'ଣ · `tr` → ତା'ର · `mr` → ମୋ'ର · `ma` → ମା'
  Both spellings are always offered side by side (ତା'ର and ତାର, କ'ଣ and କଣ), and the short head words also offer their usual phrases (ମା' ପାଖକୁ and ମା ପାଖକୁ, କ'ଣ ପାଇଁ and କଣ ପାଇଁ …).
- 🔤 Abbreviations. `pa` → ପି.ଏ. (also PA, P.A., ପିଏ)
- ୟ vs ଯ: `y` gives ୟ first and ଯ a little later (`kaifiyat` → କୈଫିୟତ୍, `yoga` → ୟୋଗ · ଯୋଗ); `j` gives ଜ first, then ଯ. `w` is only ୱ.
- Z after a word (`ghar` + Shift+Z) gives ଘର୍‌ (halant + ZWNJ) first, not a guess.
- 🔤 Whatever you typed is always choice 2, in every language, so the plain English word is one number key away.
- ⌨️ The on-screen keyboard changes its key letters with the language you pick (Odia, Devanagari, Assamese, Bangla, Phonetic).
- 📒 Add your own words in `~/Library/Application Support/LekhaniOdia/lexicon.tsv` (roman⇥odia).

## 🔲 Auto-surround
Select some text, type an opening mark, and the selection is wrapped instead of replaced: `(hello)`, `[hello]`, `{hello}`, `"hello"`, `'hello'`, `` `hello` `` and `<hello>`. Nothing but the two marks is added, so the text, its line breaks and its indentation stay exactly as they were, and where the app allows it the text stays selected so you can stack marks (`((hello))`). It is a setting you can switch off, and it is remembered.

| | Where the switch is | Selection afterwards |
|---|---|---|
| Web typist, iPad | the **Auto-surround** box under the keyboard | text stays selected |
| Android | keyboard ⚙ settings → **Auto-surround** | text stays selected |
| Mac | input-source menu → **Auto-surround selected text** (on by default) | caret after the closing mark |
| Windows | tray icon → **Auto-surround selected text** (off by default, single-line selections in apps that expose their text to Windows) | text stays selected for plain Latin text |
| iPhone / iPad keyboard | the **( )** button at the right of the suggestion bar | caret after the closing mark |
| Keyman packages | not available (Keyman gives keyboards no access to the selection) | |

## 🌐 Try it in the browser
Same engine, no install: [Sulekhak, the web typist](https://sai-sudeep.github.io/assets/tools/sulekhak.html). It also writes Devanagari, Assamese (ৰ, ৱ), Bangla, English, and a **Phonetic** mode: type a key, then pick the IPA, extIPA or IAST symbols that *look like* that key (hover a key, or long-press it on a phone or iPad, to see them all). It has a realistic 3D keyboard guide drawn as the keyboard you use (Mac, Windows, iPad / iPhone or Android) that can be detached, pinned, zoomed and resized, and it works on phones and tablets: slide a finger across the letters to type a whole word, hold and drag the space bar to move the cursor, hold the full stop for every punctuation mark, open the symbols and emoji page from the bottom-left key, double-tap a word, triple-tap a paragraph, drag the selection handles.
It also plugs into [OMMNISKRIPT](https://sai-sudeep.github.io/assets/tools/ommniskript.html) as a "Write in" pad.

## 📄 License
CC BY-NC-SA 4.0: share and adapt with credit, not for commercial use, and keep the same license. The download includes the full source, so you can read how it works.

© 2026 Sai Sudeep Das
