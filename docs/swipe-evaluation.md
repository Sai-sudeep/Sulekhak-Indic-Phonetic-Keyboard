# Swipe recognition: evaluation method and results

## What was measured, and how

* **Dataset** (`apps/core/swipe/gen_dataset.js`): 7,645 synthetic gestures from a fixed seed, so the file is byte-identical on every run (md5 07f96c4a…). Words come from two sources: sentences of ordinary Odia text, and strata chosen to stress particular spellings (conjuncts, chandrabindu, nukta, ZWNJ, ୱ, ୟ, schwa-optional spellings, typed shorthand). Each gesture is made from the roman spelling, with a finger-path model, a speed profile (fast, normal, precise) and an error profile (precise, normal, sloppy, stray touches of a neighbouring key on the way). Geometries: phone portrait, phone landscape, desktop.
* **Split**: one fifth of the word types are held out (`--split test`, 1,527 gestures). No word in the test split is used when choosing weights.
* **Metrics**: top-1 (the word the keyboard auto-picks is right), top-3 (right word among the 3 chips), top-5, top-8, MRR@8, WER = 1 − top-1 and WER@3, and decode latency (mean, p50, p95, max in ms, one Node process, not a phone).
* **Failure report**: separates "the right word never entered the candidate pool" (retrieval miss) from "it was in the pool but ranked low".

## Results (test split, 1,527 gestures)

| Decoder | top-1 | top-3 | top-8 | MRR | WER | mean ms | p95 ms |
|---|---|---|---|---|---|---|---|
| v7 (before this work) | 65.9 | 74.2 | 78.2 | 0.704 | 34.1 | 18.6 | 45.6 |
| **v9 (production; elastic matching for stray touches)** | **74.4** | **86.6** | **92.3** | **0.811** | **25.6** | 45.5 | 115.6 |
| v10 (hand weights) | 73.9 | 85.8 | 91.0 | 0.804 | 26.1 | 111.8 | 297.1 |
| v10 (weights fitted on the training split) | 74.8 | 86.2 | 91.4 | 0.809 | 25.2 | 100.1 | 263.4 |
| v11 | 74.3 | 84.9 | 91.2 | 0.804 | 25.7 | 165.6 | 394.0 |

The v10 and v11 research decoders were not adopted: they are not better than v9 beyond noise and cost 2–4 times the time.

Selected slices for v9: desktop 89.3 top-1, phone portrait 73.0, sloppy 68.6, stray-neighbour-touch 70.8 (it was far lower before elastic matching), nukta words 40.7, chandrabindu words 48.9, ZWNJ words 50.0, plain words 77.3, conjunct words 80.2.

## What the ablation says

Removing one feature at a time (fitted on the training split, scored on the test split; numbers differ slightly from the table above because the ranker is refitted):

| Removed | top-1 |
|---|---|
| nothing | 74.9 |
| language model | 63.8 |
| saliency (corner points) | 72.3 |
| elastic matching (DTW) | 73.1 |
| coverage | 74.3 |
| edit distance, location, shape, length ratio, cluster features | 74.9 (no change) |
| gesture only, no language model | 64.5 |
| language model + cluster only, no gesture | 39.9 |

The language model matters most; saliency and elastic matching are the next most useful gesture features; several features add nothing and could be dropped to save time. About 5.8% of gestures are retrieval misses (the right word was never proposed), which is a ceiling on any re-ranking.

## Limits

1. Synthetic gestures only. Real fingers differ. Treat the numbers as a regression guard and a way to compare decoders, not as user-visible accuracy.
2. Latency is measured on a desktop CPU. A mid-range phone will be several times slower; the 250,000-word search is the reason.
3. Nukta, chandrabindu and ZWNJ words are the weak slice. Their spellings are ambiguous from the gesture (the nukta and the chandrabindu keys are not on the swipe path); only the language model can choose between them.

## CI guard

`core-tests` regenerates the dataset, runs the test split with the shipped engine (`apps/shared/sulekhak.js`) and fails the build if top-1 < 72, top-3 < 85, top-8 < 90 or p95 > 400 ms. The bounds are set a little below the measured values; raise them when the decoder improves.
