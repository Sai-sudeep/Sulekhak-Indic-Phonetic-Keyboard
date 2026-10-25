# Installing, updating, rolling back and uninstalling

The rule on every platform: a new release must be recognised as the same program by the operating system, and must keep the user's words and settings.

## Windows

**Use `Sulekhak-Windows-Setup.exe`.** It needs administrator rights once, because Windows only lets administrators register a keyboard (text service) for everyone.

What it does:

1. Closes a running Sulekhak.
2. Copies the app to `C:\Program Files\Sulekhak` and the text-service DLLs (64-bit and 32-bit) to `C:\Program Files\Sulekhak\tip\<version>\`.
3. Registers the text service with Windows (COM class and six keyboard profiles). Because the identifiers never change, a new version registers over the old one.
4. Starts Sulekhak at sign-in (optional checkbox).

Why a folder per version: Windows loads the DLL into every application that has a text box. A loaded file cannot be replaced, so the new version goes in a new folder and the registration moves; each application picks it up the next time it starts. Old folders are deleted at the next install or uninstall, once no program holds them.

After installing, Sulekhak offers to add the keyboards to your list. You can do it later from the tray menu: *Add Sulekhak keyboards to Windows…* Then **Win+Space** lists *Sulekhak — All Languages*, *Odia*, *Hindi (Devanagari)*, *Marathi*, *Bangla*, *Assamese*.

**Upgrade**: run the new Setup.exe. **Rollback**: run an older Setup.exe (the installer allows it). **Uninstall**: Settings → Apps → Sulekhak. The uninstaller unregisters the text service and keeps your words (`%LOCALAPPDATA%\Sulekhak`) and settings (`HKCU\Software\Sulekhak`).

If you used the old single `.exe`: install the Setup.exe, then delete the old `.exe`. The app moves its start-at-sign-in entry to the installed copy by itself.

The portable `Sulekhak-Windows*.exe` files still work but cannot appear in Win+Space; they use the older keyboard hook. Set the `ForceHook` setting to 1 to use hook mode even when the installer is present.

**If the installed Sulekhak does not type.** The installed program decides by itself who types, and never leaves you without typing:

* If the Sulekhak keyboard works on your computer (it is registered, its file is there, it is in your Win+Space list, and it can reach the program), Windows delivers the keys and you choose the keyboard with **Win+Space**. English and the other Win+Space features need this mode.
* If any of those is not true (the keyboards are not in your list yet, the registration was refused, the file is missing, or the computer is Windows for ARM, where a 64-bit-Intel text service cannot be loaded by ARM programs), Sulekhak types with its keyboard hook, exactly like the portable program: Roman letters turn into your script in the programs you type in, and the tray menu switches it off and on. The tray balloon says which mode is active and why.
* The decision is repeated every 20 seconds, so adding the keyboards later (tray menu, *Add Sulekhak keyboards to Windows…*) switches to Windows typing by itself.

For anything unexpected, use the tray menu item **Check installation…**. It lists each check (registered, file present, in your list, pipe answers, word engine running, ARM), says who types and why, copies the report to the clipboard, and writes it to `%LOCALAPPDATA%\Sulekhak\sulekhak.log`. The Win+Space keyboard itself writes the problems it meets (never what you type) to `%LOCALAPPDATA%\Sulekhak\tip.log`. Sending those two files is enough to find the cause.

The Win+Space keyboard also carries its own copy of the Odia engine (the same engine the Mac keyboard uses). If the Sulekhak program answers too slowly or is not running, the Odia, Hindi/Marathi, Bangla and Assamese keyboards still type real words from that copy instead of showing Roman letters; English needs the program. The keyboard now waits up to 0.7 s to send and 2 s for an answer (older, busy or slow-starting computers took longer than the earlier 0.3 s and 0.4 s), and after one miss it uses its own copy for 8 s before asking again.

The installer no longer stops when Windows refuses the registration of the text service (`noregerror`): the installation completes and the program types with the hook. A refused single keyboard (a language your Windows edition does not have) no longer stops the others from being registered.


Not yet covered: the installer is not code-signed (Windows SmartScreen may warn). A signing certificate can be added through the `SignTool` define in `Sulekhak.iss` without other changes.

## Android

Every release APK is signed with the same release key, and has a version code that only ever grows (minutes since 1970, set by CI). That is what lets Android install a new APK over the old one and keep the data.

* **One-time step for people who already have a build installed**: those builds were signed with a temporary key that changed on every build, which is why Android said *App not installed*. Uninstall once; every later release then updates in place.
* Forged updates (same name, different key) are refused by Android. The CI test proves this.
* Anyone can still download and install an APK from the repository; signing does not stop that. It only stops someone else's file from replacing yours on a phone that already has yours.
* Downgrading is refused by Android (a lower version code). To roll back, publish the old code again with a new, higher version code.
* Check an APK: `apksigner verify --print-certs Sulekhak-Android.apk` must show certificate SHA-256 `C9:21:F8:93:C2:20:02:FD:C5:3D:69:AE:F7:4F:8C:39:0B:6E:F4:85:BC:1A:AE:E2:07:B7:78:75:82:5E:29:82` (file `apps/android/release-cert.sha256`).
* The release key must never be lost or published. If it is lost, no update can ever replace existing installs. CI reads it from four GitHub secrets: `SK_KEYSTORE_B64`, `SK_KEYSTORE_PASS`, `SK_KEY_ALIAS`, `SK_KEY_PASS`. Without them the build still runs but marks the release *signed with a temporary key* and says so in the release notes.

## macOS

The all-in-one keeps the identity `com.saisudeep.inputmethod.OdiaPhonetic`; each single-language edition has its own. Open the DMG, double-click *Install Sulekhak …command*. It stops the running copy, replaces the app in `~/Library/Input Methods`, refreshes the system's registration and the input menu, and leaves `~/Library/Application Support/LekhaniOdia` (your words) alone. The app is not notarised, so macOS asks once (right-click → Open). *Uninstall.command* removes the app and keeps the words.

## iPhone and iPad

The IPA is unsigned. A sideloading tool (AltStore, SideStore, Sideloadly) signs it with your Apple ID. Updating works only when the bundle ids (`com.saisudeep.sulekhak`, `com.saisudeep.sulekhak.keyboard`) and the signing identity are unchanged and the build number is higher; CI sets the build number from the clock. With a free Apple ID, the signature expires after 7 days and must be refreshed (Apple's rule). The web app on iPad needs no install.

## Tests that guard this

| Platform | Test | Where |
|---|---|---|
| Windows | install, upgrade while a program holds the old DLL, repair removes the old folder, six keyboards listed, driver through TSF, keyboards added to the user's list, rollback, forward again, uninstall removes every registration, user data stays | `windows/installer/test_install.ps1`, job `windows-installer` |
| Android | install, enable keyboard, upgrade in place, data survives, keyboard still enabled, forged update refused, downgrade refused, uninstall | `android/ci/upgrade_test.sh`, job `android-upgrade-test` |
| macOS | install over an older install: id unchanged, app replaced, one copy only, data kept, uninstall keeps data | job `mac` |
| iOS | bundle ids exactly as expected, build number grows | job `ios` |

The Windows, Android, macOS and iOS checks above all ran in GitHub Actions on real Windows, macOS and an Android 11 emulator; see `docs/engineering.md` for what each run proved and what it did not (nothing was tried on a physical phone, and the visible Win+Space menu was not looked at by a person).
