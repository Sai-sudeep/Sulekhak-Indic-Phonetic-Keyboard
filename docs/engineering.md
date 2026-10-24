# Sulekhak engineering notes: swipe, keyboard mapping, Windows text service, updates

This page is the honest status of the October 2026 engineering pass. It separates three things everywhere:

* **Verified**: run by an automated test, and the result is recorded here or in CI.
* **Implemented, not yet verified**: the code is written and compiles, but no test has run it on the real operating system or device. These are listed so nobody mistakes them for finished.
* **Known limits**: things that are not solved, with the reason.

Nothing below is called "fixed" unless it is in the Verified column.

## 1. One shared core, thin platform adapters

| Layer | Single source of truth | Used by |
|---|---|---|
| Language engine (roman to Odia/Devanagari/Bangla/Assamese, dictionary, bigram/trigram model, swipe decoder) | `shared/sulekhak.js` (+ data from `sai-sudeep.github.io/assets/tools/sulekhak/`) | web, Android, iOS, Windows, Mac (Mac also keeps a C copy of the typing path) |
| Desktop keyboard behaviour (what each key does, in each state) | `apps/core/keymap/sulekhak-keymap.json` | JS reference, generated C# table (Windows hook mode), generated C++ table (Windows text service) |
| Nukta key behaviour | `apps/core/keymap/nukta.js` + `nukta_vectors.json` | same three |
| Swipe evaluation | `apps/core/swipe/` | CI regression guard |

The generated files (`KeyTable.g.cs`, `KeyVectors.g.cs`, `tip/keytable.inc`, `tip/tests/decisions.txt`) are rebuilt in CI and compared byte for byte with the committed copies, so a platform cannot drift from the spec silently.

Phone and tablet keyboards are deliberately a different input strategy (touch, swipe, suggestion bar). They share only the language engine. The physical-keyboard spec covers desktop only (Windows and macOS). Linux is left out for now.

## 2. What is verified and what is not

| Item | Status | Evidence |
|---|---|---|
| Swipe decoder: v9 stays in production | **Verified** (on synthetic gestures) | `docs/swipe-evaluation.md`; CI re-runs it with bounds |
| Desktop key spec, JS reference | **Verified** | 199/199 vectors, 11/11 nukta vectors (`core-tests`) |
| Windows hook-mode key machine (C#) | **Verified** under mono | 84/84 vectors (`core-tests`) |
| Windows text-service key logic (C++) | **Verified** natively | 535/535 decision-for-decision against the spec (`core-tests`) |
| Text-service DLL builds, 64 and 32 bit | **Verified** | MinGW build in `core-tests` |
| Text service registers, creates, activates, commits text through TSF | **Verified under Wine only** (9 pass, 4 skipped) | Wine's TSF lacks composition and `ITfRange::Clone`. The first CI run on a real Windows runner is the real check (`windows-installer`). |
| Composition underline, Shift+`.` nukta rewrite, Backspace over one code point, inside real TSF | **Implemented, not yet verified** | the skipped Wine tests; they run for the first time on `windows-latest` |
| Win+Space lists "Sulekhak — All Languages", Odia, Hindi, Marathi, Bangla, Assamese | **Verified under Wine** (profile enumeration); **real Windows: runs in CI** | `tip_driver --list` |
| Installer install / upgrade while the DLL is in use / repair / rollback / uninstall | **Implemented**, test written (`test_install.ps1`), **not yet run** on Windows | runs in `windows-installer` |
| Windows keyboard-hook rewrite in the app | **Implemented, compiles** (mcs, except WebView2 types that mono lacks) | not run on Windows |
| Named-pipe engine bridge security (SDDL, AppContainer) | **Implemented, not verified**, in particular low-integrity and AppContainer apps | see limits |
| Android release signing, versionCode that always grows | **Implemented**; needs the four GitHub secrets | `android` job checks cert SHA-256 |
| Android in-place upgrade, data kept, forged update refused | **Implemented**, emulator test written, **not yet run** | `android-upgrade-test` |
| Android historical touch samples for swipe | **Implemented, not verified on a device** | `KeyboardView.java` |
| macOS update identity (bundle id stable, replace in place, data kept) | **Implemented as CI check; not run**. Mac source was not changed. Mac behaviour was validated by reading the source, not by executing it. | `mac` job |
| iOS identity and version growth | **Implemented as CI check; not run** | `ios` job |

## 3. Known limits (not solved)

* **All swipe numbers come from synthetic gestures** made by a seeded model of finger error. No recorded human swipes exist yet. They rank decoders against each other reliably; they do not tell you the accuracy a person will see. Collecting real swipes is the next step and needs a consent flow.
* The language model carries most of the accuracy. Without it the decoder drops from about 75% to about 64% top-1. Out-of-vocabulary words are the hardest case.
* **Windows Backspace over text that is already committed** depends on the application. Inside TSF-aware text boxes the text service deletes one code point (so a vowel sign goes without its letter). In applications that do not expose their text to TSF (some games, terminals, remote desktops) Windows hands the key over unchanged and the application decides.
* **Windows ARM64** is not built. The x64 DLL runs in emulation for x64 apps only; ARM64-native apps would need an ARM64 DLL.
* **Elevated and AppContainer applications**: whether they can reach the engine over the named pipe is untested. If they cannot, they fall back to typing the Roman letters.
* "Sulekhak — All Languages" is registered under English (United States) because Windows keyboard lists are grouped by language, and the all-language keyboard has no language of its own.
* The Phonetic/IPA mode is not in the shared table.
* Wine is not Windows. Passing under Wine is evidence about the code, not about Windows.
* Mac: unchanged in this pass. The behaviour differences found by reading are listed in `docs/keymap.md`. A manual checklist is there too.
* iOS keyboards are installed by sideloading; that depends on the sideloading tool (AltStore, SideStore, Sideloadly) re-signing with the same Apple ID. See `docs/install-and-update.md`.

## 4. Compatibility matrix (updating over an existing install)

| Platform | Stable identity | Update path | Data kept | Needs once |
|---|---|---|---|---|
| Windows (installer) | AppId `{B6A0D5C2-5E3A-4F5B-9A57-2C4D9B7E8F10}`, text service CLSID `{96DB1CE7-2FD4-45AD-BD63-BE53EF2753E6}`, six profile GUIDs | run the new Setup.exe; it closes the old app, installs the DLL in a new versioned folder, re-registers over the old one, removes old folders when no program holds them | `%LOCALAPPDATA%\Sulekhak`, `HKCU\Software\Sulekhak` never touched | nothing; first run offers to add the keyboards to Win+Space |
| Windows (portable .exe) | none | replace the file | same | nothing; keyboard-hook mode only, no Win+Space entry |
| Android | `com.saisudeep.sulekhak` (+ `.odia` etc.), key SHA-256 `C9:21:F8:93:…:82` | install the new APK over the old | app data kept by Android | **one uninstall** if the installed copy was a pre-signing build (debug key) |
| macOS | `com.saisudeep.inputmethod.OdiaPhonetic` (all-in-one), `...<EditionName>` for single-language | run "Install ….command" from the DMG; it replaces the app in `~/Library/Input Methods` and refreshes the input menu | `~/Library/Application Support/LekhaniOdia` | log out/in only if the input source does not appear |
| iOS / iPadOS | `com.saisudeep.sulekhak`, `.keyboard` | sideload the new IPA with the same Apple ID | app data kept if bundle id and team are the same | re-sideload within 7 days with a free Apple ID (Apple's rule, not ours) |

## 5. How to reproduce the checks

```
node apps/core/keymap/run_vectors.js          # spec reference
node apps/core/keymap/run_nukta.js
sh   apps/windows/tests/run.sh                # C# key machine (mono)
sh   apps/windows/tip/tests/run.sh            # C++ key logic, native
cd apps/core/swipe && node gen_dataset.js --pack <compact dir> --prompts prompts.json --out /tmp/ds.json \
  && node run_eval.js --engine ../../shared/sulekhak.js --pack <compact dir> --data /tmp/ds.json --split test --assert "top1>=72,top3>=85,p95<=400"
```

Everything else runs in `.github/workflows/build-apps.yml`.
