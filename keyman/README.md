# Sulekhak keyboards for Keyman

Four Keyman phonetic keyboards made from the same tables as the Sulekhak engine: **Odia**, Devanagari, Assamese and Bangla. They have touch layouts for phones and tablets and a hardware layout for computers.

* `sulekhak_all.kmp`: all four in one package
* `sulekhak_odia.kmp`, `sulekhak_devanagari.kmp`, `sulekhak_assamese.kmp`, `sulekhak_bangla.kmp`: one language each
* `sulekhak-keyman-source.zip`: the sources (`gen.js` writes the rules from the engine tables, `sim.js` tests them, `kmc build sulekhak.kpj` compiles them)

Install: open a `.kmp` file with Keyman (Windows, Mac, Linux, Android, iPad, iPhone), or in Keyman Developer choose Install. Then add the language in Keyman and switch to it.

## How it types

A Keyman keyboard types by rules and cannot offer a list of candidate words, so spell the long vowels out. For word suggestions and learning use the Sulekhak apps.

| Type | Get |
|---|---|
| `k kh g gh c ch chh j jh` | କ ଖ ଗ ଘ ଚ ଚ ଛ ଜ ଝ (`ch` is the plain letter and `chh` the aspirated one) |
| `T Th D Dh N`, `R Rh` | ଟ ଠ ଡ ଢ ଣ, ଡ଼ ଢ଼ |
| `t th d dh n p ph b bh m y r l L w v s sh S h` | the rest (`sh` ଶ, `S` ଷ) |
| `x`, `gy` or `jn` | କ୍ଷ, ଜ୍ଞ |
| `a i u e o` | vowels; after a consonant `a` only marks the sound, so `ka` is କ and `kaa` is କା |
| `aa ii uu ee oo ai au`, or `A I U` | long vowels and diphthongs |
| `rri` | ଋ, and ୃ after a consonant |
| consonant + consonant | joins by itself (`stra` ସ୍ତ୍ର, `ksh` କ୍ଷ); type `a` between them to keep them apart (`kah` is କହ) |
| `nk ng` and `nc nj` | ଙ୍କ ଙ୍ଗ and ଞ୍ଚ ଞ୍ଜ (the nasal of the same class) |
| `` ` `` | halant |
| `z`, `Z` | ZWNJ, halant + ZWNJ (ବାଗ୍‌ଦେବୀ is `baagZdebii`) |
| `M H ~ >` | ଂ ଃ ଁ and the nukta |
| `\|` | danda |

The Devanagari, Assamese and Bangla keyboards use the same keys. Not tested inside Keyman itself: the packages compile with Keyman's own compiler (kmc 18) and the rules pass a test of their own, but I could not run them in the Keyman app. Please tell me what looks wrong.
