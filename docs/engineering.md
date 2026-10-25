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
| Text service registers, is created and activated through TSF, composes, rewrites for nukta, commits, Backspace over one code point | **Verified on real Windows** (GitHub `windows-latest`): 14 of 14, none skipped, run against the installed DLL. Also 9 of 9 under Wine. | `tip_driver`, job `windows-installer` |
| Windows itself activates the keyboard (what choosing it in Win+Space does) and loads the DLL | **Verified on real Windows**: `ActivateProfile` succeeded, the active keyboard became *Sulekhak Odia*, the DLL was loaded by Windows | `tip_driver --activate` |
| Win+Space lists *Sulekhak — All Languages*, Odia, Hindi, Marathi, Bangla, Assamese | **Verified on real Windows** at the system-API level (all 6 listed and enabled; absent after uninstall). A new install takes a few seconds to appear (3 s measured). The visible Win+Space flyout was not looked at by a person. | `tip_driver --list` |
| Installer: fresh install, upgrade while a program holds the old DLL, repair removes the old folder, rollback, uninstall removes every registration, one entry in Apps & features, user data and settings kept | **Verified on real Windows** | `test_install.ps1` |
| Keyboards added to the user's Windows language list by the app's script | **Verified on real Windows** (after fixing a failure the first CI run found: `New-WinUserLanguage` is absent on some editions) | `AddKeyboards.ps1` |
| Windows app (tray, offering the keyboards, hook-mode rewrite) | **Compiles on Windows** (all six builds). Not run by a person: the first-run offer and the tray menu are untested. | `windows` jobs |
| Named-pipe engine bridge between the text service and the app | Used successfully by the driver on Windows (17 queries). Low-integrity and AppContainer apps untested. | see limits |
| Installed app falls back to the keyboard hook whenever the text service cannot work (not registered, file missing, not in the Win+Space list, pipe unreachable, Windows on ARM) | **Implemented, compiled with mono (type-checked), not yet run on Windows.** Added after a report that the installed version did not type at all while the portable one did. | `App.cs` `ApplyMode`, `WantTsf` |
| Installed Sulekhak.exe answers the text service's pipe with real Odia and English candidates (the word engine inside the installed program) | **Test added (`test_install.ps1`, reported as SOFT-FAIL until seen to pass; set `SK_E2E_STRICT=1` to make it block).** This path was never exercised end to end before: the driver tests used a stand-in program. | job `windows-installer` |
| Windows on ARM | **Not supported by the Win+Space keyboard** (an x64 DLL cannot load into native ARM programs; an ARM64X build is needed). The installer skips the text service there and the app types with the hook. Unverified on real ARM hardware. | `Sulekhak.iss` `IsArmWindows` |
| Android release signing, versionCode that always grows | **Implemented and built in CI**; real-key signing waits for the four GitHub secrets (the job then checks the certificate SHA-256) | `android` job |
| Android in-place upgrade, data kept, keyboard still on, forged update (other key) refused, downgrade refused, uninstall | **Verified on an Android 11 emulator** (12 of 12 on one run; a second run hit a timing race in the test itself, fixed by waiting for the keyboard to register). Run so far with the temporary key because the secrets are not set yet. | `android-upgrade-test` |
| Android historical touch samples for swipe | **Compiles in CI**; not tried on a device | `KeyboardView.java` |
| Windows keyboard keeps typing real words when the Sulekhak program is slow or closed (own copy of the Odia engine inside the DLL; longer pipe waits) | **Implemented; built (64-bit and 32-bit) and the engine output checked natively. Not yet run on a real Windows PC**: the installer test (job `windows-installer`) only proves the pipe path with the real program, not the slow-start case. | `tip/engine/`, `tip.cpp` |
| macOS update identity (bundle id stable, replaced in place, one copy, data kept, uninstall keeps data) | **Verified on a macOS runner** by installing over an older install. The Mac source was not changed, and its key behaviour was checked by reading the source only. | `mac` job |
| iOS identity (the two bundle ids) and a build number that grows | **Verified in CI** on the built IPA. Updating a sideloaded install on a device was not tried. | `ios` job |

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
