# Sulekhak keyboards for Keyman (version 2)

Four Keyman phonetic keyboards made from the same tables as the Sulekhak engine: **Odia**, Devanagari, Assamese and Bangla. Version 2 has a full touch layout for phones and tablets, an on-screen keyboard for computers, and a suggestion strip.

| File | What it is |
|---|---|
| `sulekhak_all.kmp` | all four keyboards in one package |
| `sulekhak_odia.kmp`, `sulekhak_devanagari.kmp`, `sulekhak_assamese.kmp`, `sulekhak_bangla.kmp` | one language each |
| `sai_sudeep.or.sulekhak.model.kmp` (and `.hi.`, `.as.`, `.bn.`) | the word suggestions for each language (up to 40,000 words each; the Hindi list has 24,000) |
| `sulekhak-keyman-source.zip` | the sources: `gen2.js` writes the rules, layouts and word lists, `sim.js` tests the rules, `kmc build sulekhak.kpj` compiles them |

**Install.** Open a `.kmp` file with Keyman (Windows, Mac, Linux, Android, iPad, iPhone), or in Keyman Developer choose Install. Add the language in Keyman and switch to it. **For the suggestion strip, install the matching `.model.kmp` file too** (a keyboard and a suggestion model are always separate packages in Keyman); the strip then appears above the keys on a phone or tablet and finishes the word you are typing.

## What is in version 2

* **Touch layout with five pages.** Letters, the same letters in capitals, numbers, symbols, and a page of every independent vowel, vowel sign and mark of the script. A key with the script's first letter opens that page.
* **Long press everywhere.** Hold a letter for the vowels, signs and common conjuncts that belong to it (the same lists as the Sulekhak Android keyboard). Hold a digit for the native digit. Hold the full stop for all punctuation; the apostrophe and the danda are there.
* **Glowing Z key.** The Z key has its own colour, a soft halo and a band of light that sweeps across it, instead of a label that does not fit. Hold it for ZWNJ, ZWJ and halant with a joiner.
* **Suggestions** (the strip above the keys), with the `.model.kmp` files.
* **On-screen keyboard for computers**, showing what each letter key gives, with the capitals on Shift.
* **Capitals never give Latin letters by accident:** a capital that has no meaning of its own types the same as the small letter.
* **Apostrophe separator.** `k'k` types କକ instead of the conjunct କ୍କ; `ka'a` types କଅ.
* **Native digits from the keyboard:** `^0` to `^9`; `^z` is ZWJ, `^'` a plain apostrophe, `^^` a caret.

## How it types

| Type | Get |
|---|---|
| `k kh g gh c ch chh j jh` | କ ଖ ଗ ଘ ଚ ଚ ଛ ଜ ଝ (`ch` is the plain letter and `chh` the aspirated one) |
| `T Th D Dh N`, `R Rh` | ଟ ଠ ଡ ଢ ଣ, ଡ଼ ଢ଼ |
| `t th d dh n p ph b bh m y r l L w v s sh S h` | the rest (`sh` ଶ, `S` ଷ) |
| `x`, `gy` or `jn` | କ୍ଷ, ଜ୍ଞ |
| `a i u e o` | vowels; after a consonant `a` only marks the sound, so `ka` is କ and `kaa` is କା |
| `aa ii uu ee oo ai au`, or `A I U` | long vowels and diphthongs |
| `rri` | ଋ, and ୃ after a consonant |
| consonant + consonant | joins by itself (`stra` ସ୍ତ୍ର, `ksh` କ୍ଷ); type `a` or `'` between them to keep them apart (`kah` is କହ) |
| `nk ng` and `nc nj` | ଙ୍କ ଙ୍ଗ and ଞ୍ଚ ଞ୍ଜ (the nasal of the same class) |
| `` ` `` | halant |
| `z`, `Z` | ZWNJ, halant + ZWNJ (ବାଗ୍‌ଦେବୀ is `baagZdebii`) |
| `M H ~ >` | ଂ ଃ ଁ and the nukta |
| `\|` | danda |

The Devanagari, Assamese and Bangla keyboards use the same keys.

## What it cannot do

A Keyman keyboard types by rules, so it has no candidate list while you type the Roman letters, no learning of your choices, and no next-word suggestions; the suggestion strip completes the word you have typed so far from a fixed list. The Sulekhak apps have all of those. The Hindi and Bangla lists come from the open `wordfreq` lists; the Odia list is the Sulekhak word list; the Assamese list is the Bengali list with the Assamese ra plus the Odia words in the Assamese script, so it is the roughest of the four.

**Not tested inside the Keyman app.** The packages compile with Keyman's own compiler (kmc 18) and the rules pass a test of their own, but I could not run them in Keyman on a phone or computer. Please tell me what looks wrong, especially the key colours and the Z key animation, which depend on how Keyman's web keyboard draws its keys.
