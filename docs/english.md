# English suggestions and swipe typing (personal build)

One engine file, `shared/english.js`, with no platform code. Android loads it in the hidden engine page; the Windows host loads it in its engine page (typing: see "English on Windows" in docs/personal.md); the Mac host is meant to (see the status table there).

## What it does

* **Completion** of the word being typed, ranked by frequency and by the word before it (bigram table).
* **Spelling**: a table of 87 000 common misspellings and missing apostrophes, plus a keyboard-aware edit-distance search (neighbouring keys, doubled letters, swapped letters cost less). The space key applies a correction only when it is clear; the typed text always stays in the strip, and **backspace right after a correction puts your letters back and the word is never corrected again**.
* **Next word** chips after a space.
* **Swipe typing** on the English layout: the finger's path is compared with the path through the keys of every candidate word (shape, position, start and end keys), then ranked with the language model.
* **Your own words**: a word you type twice, a correction you make twice, a suggestion you keep choosing and a swipe you accept are all learned, in the `en` file only (never mixed with Odia, Hindi, Marathi, Bangla or Assamese), and synced to your other devices like the other languages. Fields that ask for no personalised learning (incognito) are not recorded, and password, e-mail and web-address fields get no suggestions at all.

## Vocabulary

390 000 forms. General English (SCOWL, WordNet, Google-Books frequency), social-media and Gen Z terms, AI-era and software jargon, Indian English, Anglo-Indian words, loanwords, linguistics (the headwords of Crystal's dictionary, headwords only), political, scientific and medical terms, and names of people, places, institutions and companies. The hand-written lists are in `core/english/sources`; the build is `core/english/build/build_en.py`. Adding a corpus later means adding a list or a source to that script and rebuilding.

## What was measured (and what was not)

Measured by the scripts in `core/english/tests` on this machine, with the engine in node:

| test | result |
|---|---|
| completion, word picked by frequency, prefix 35-65 % of the word | right word in the top 5: about 76 % (top 1: 36 %, top 3: 65 %) |
| 3 000 real misspellings **left out of the fix table** | corrected automatically and right: 66 %; right word in the top 3: 91 % |
| keyboard slips on frequent words (neighbour key, missing, extra, swapped letter) | right word in the top 3: 87-99 % depending on the kind of slip |
| 6 000 correctly typed words | 1 changed by autocorrect (the contraction "cant") |
| 117 plausible words not in the list (Indian names, new slang, brands) | 2 changed by autocorrect |
| next word, Brown and Reuters text **left out of the model** (old model; see the language-model section for the current one) | right word in the top 3: 22 % (always offering the/to/of: 13.5 %) |
| swipe, simulated finger paths (generated from the key positions with noise; not real fingers) | at moderate noise right word first 94 %, in the top 3 99 %; at heavy noise first 84 %, top 3 94 % |
| speed in node | 2.6 ms per suggestion, 1.5 ms per swipe |

Not measured: real people's swipes on a real phone, real typing sessions, speed inside a phone's WebView, and prediction quality after weeks of personal learning. The thresholds in the test scripts are regression gates (they stop a change from making things worse), not accuracy claims.

Known limits: autocorrect is conservative for words of three letters or fewer (only the written-out fix list applies); words missing from the list are left as typed until you type them twice; a first-time unknown word of five letters or more that is one slip away from a common word can be corrected once (e.g. "ashwini" lower case), and then it is yours after you undo it.

## Swipe: the first letter is not typed

On Android the keyboard types a letter the moment a finger touches it, because a tap has to feel instant. When the finger then turns out to be starting a swipe, that first letter was already in the word being composed, and the word that the swipe produced was added after it with a space ("b bed" for a swipe of "bed"). The keyboard now takes that first letter back as soon as it sees the finger move far enough to be a swipe, so only the swiped word is inserted. A swipe that starts on a key of another kind (a key that is not typed at once) is not affected. Compiled in CI; not yet tried on a real phone. The iPhone and iPad swipe already takes the first letter back when the swipe begins, and the web page does the same for the on-screen keyboard.

## English on the web

The web typist has an **English** tab (also the separate English page and the iPad web app). It uses the same word lists and rules as the apps: letters stay in the text as you type, Space puts in the first suggestion (so "teh" becomes "the"), Backspace right after gives your letters back, apostrophes and punctuation are handled like the apps. What it learns is kept in the browser only (there is no sign-in on the web), and the English data (about 2.9 MB compressed) is loaded the first time English is used. After a word and a space the strip also shows the words that usually come next (the same model; two words of context); clicking one puts it in with a space.

## The English language model (October 2026)

The word list (`en_lex`, 391 511 words) and the fix table (`en_fix`) were **not touched**: the new model only adds counts. `en_ng` now holds the old rows (kept, at 40 % weight in the merge), about 1.08 million new word-pair counts, and about 200 000 three-word rows (`w1 w2<TAB>*L w3:q ...`, where L is the share of probability owned by the three-word counts). The engine mixes three-word, two-word and single-word probabilities and remembers the last two committed words (`note`), so hosts that pass only one word still get two-word context.

How it is built: `.github/workflows/build-english-lm.yml` (run it by changing `english-lm.trigger`) downloads the corpora on a GitHub runner, trains with `core/english/build/lm/build_lm.py`, cuts a web tier and a lite tier, tests the result on sentences held out of the counts (`core/english/tests/eval_lm.js`) and publishes a release `english-lm-<N>` with the data, the report, the source list and the example-sentence file.

| source | licence | used |
|---|---|---|
| Wikipedia (English) | CC BY-SA 4.0 | 2.05 M training sentences |
| Simple English Wikipedia | CC BY-SA 4.0 | 2.11 M |
| FineWeb-Edu | ODC-By 1.0 | 1.70 M |
| Tatoeba | CC BY 2.0 FR | 2.03 M |
| Mozilla Common Voice sentences | CC0 | 1.58 M |
| NLTK corpora (Brown, Reuters, Gutenberg, ...) | various | 0.25 M |
| Wiktionary examples (via kaikki.org) | CC BY-SA 4.0 | example sentences only |

About 165 million word tokens were counted. For the existing vocabulary the build also collected example sentences (up to 10 per word, several vocabulary words per sentence): 109 458 words have 10, 209 005 have at least one, **182 506 words have none** because they are rare, technical or names that none of these sources contain (`words_without_sentences.txt` in the release). Those words stay in the list and keep their frequency; the model simply has no context for them.

Measured on sentences that are in none of the counts (n = 91 705 words, full tier):

| | old model | new model (full) | web tier | lite tier |
|---|---|---|---|---|
| next word in the top 3, one word of context | 23.0 % | 25.3 % | 25.3 % | 23.8 % |
| next word in the top 3, two words of context | 23.0 % | 30.5 % | 30.2 % | 27.1 % |
| right word in the top 3 after typing 2 letters, two words of context (words of 4+ letters) | 33.6 % | 44.0 % | 43.5 % | 34.8 % |

The old model had no three-word counts, so its two-word rows equal its one-word rows. The ten regression gates in `eval.js` (completion, misspellings, false corrections, speed) pass with the new data. Tuning on the held-out set moved the bigram weight (`LAMBDA`) from 0.55 to 0.8, which gave a small gain (top 1 after two letters, two words: 31.9 % to 32.4 %).

Where each tier is used: full on Mac, Windows and Android; web on the website typists and the iPad web app; lite on iPhone/iPad (built from the full file in CI by `make_lite.py`). Next-word choices (after a finished word and a space, and the usual first words at the start of a sentence) are on every platform that types English: **Mac** (choices under the cursor and on the 3D keyboard strip and Touch Bar; Tab takes the highlighted one, Shift+Tab moves it, a click takes the one clicked), **Windows** (the same popup under the cursor; Tab and Shift+Tab; not shown in windows that draw the candidate list themselves, such as the Start box), **Android** and **iPhone/iPad** (chips in the suggestion bar) and the **web typists and iPad web app** (the suggestion strip). On Mac and Windows the choices can be switched off in the menu ("English: offer the next word"). The Keyman keyboards (docs/keyman-ipad.md) are Odia-only and have no English prediction; for English on an iPad use the Sulekhak keyboard or the iPad web app. Checked: the typing rules and the Tab handling by 25 native tests (Windows and Mac share the code), the web strip in a headless browser, and the engine's answers in Node; the Mac, iPhone and Android panels were not seen on a real device by me.

Limits: the held-out text is encyclopedic and web text, so the numbers describe that kind of writing, not chat or email; the model does not learn from the user beyond the existing word learning; names, jargon and rare words are poorly covered (see above).
