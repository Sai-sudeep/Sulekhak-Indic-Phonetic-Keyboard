# sulekhak-learn.json — what Sulekhak learns while you type

Written by the Mac app (v17 / 3.0 and later) to  
`~/Library/Application Support/LekhaniOdia/sulekhak-learn.json`  
and shared by every Mac edition. The web typist can import and export the same format ("Import learning file" / "Export learning file"), so what the Mac learned can improve the online app, and the other way round. `tools/learn_merge.py` converts it to and from the plain `history.tsv` / `lexicon.tsv` lists the Windows and Android apps read.

```json
{
  "format": "sulekhak-learn",
  "version": 1,
  "device": "mac",            // mac, web, ...
  "app": "3.0",
  "updated": 1760000000,      // Unix seconds
  "picks": {                  // what you chose for the Roman letters you typed
    "bharata": [
      { "w": "ଭାରତ", "n": 14, "first": 1750000000, "last": 1759999999, "sc": 1 }
    ]
  },
  "dict": [                   // your own Sulekhak Dictionary (Add to Sulekhak Dictionary)
    { "w": "ସୁଦୀପ ଦାସ", "roman": "sudipdas", "wt": 6, "added": 1759000000, "src": "mac" }
  ],
  "next": {                   // next-word pairs: after the word, how often this word followed
    "ଭାରତ": { "ସରକାର": 3 }
  }
}
```

* **Words are always Odia.** The engine works in Odia and carries every candidate over to Devanagari, Bangla or Assamese, so a pick made while typing Devanagari is stored as its Odia form. `sc` is a bit set of the scripts it was typed in (1 = Odia, 2 = Devanagari, 4 = Bangla, 32 = Assamese; bit number = script number 0, 1, 2, 5).
* **picks.n** is how many times the word was chosen for that Roman text (the Roman text keeps its capitals: `T` is not `t`). At start-up each pick gets the engine weight `3 × min(n, 20)`, so a word you use a lot ranks first and one word cannot take over for ever.
* **dict** entries are trusted: they are never dropped as an "impossible spelling", and they can be a whole expression (`iitdelhi` → `ଆଇଆଇଟି ଦିଲ୍ଲୀ`). The Roman text has no spaces. `wt` is the weight (default 6).
* **Merging** two files: picks add up the larger `n`, keep the earlier `first` and the later `last`, and OR the `sc` bits; dictionary entries are the union (same `roman` + `w` is one entry); next-word counts take the larger value.
* The Mac app writes the file a moment after a change (atomic write), checks every 20 seconds whether another program changed it and merges that in, and writes once more when it quits. `lexicon.tsv` (one `roman<TAB>Odia<TAB>weight` per line) is still read: each line becomes a dictionary entry the first time it is seen, and a word added with **Add to Sulekhak Dictionary** is also appended to it. The old `history.tsv` is folded into `picks` the first time and kept as `history.tsv.migrated`.
* Everything stays on your computer. Nothing is sent anywhere.
