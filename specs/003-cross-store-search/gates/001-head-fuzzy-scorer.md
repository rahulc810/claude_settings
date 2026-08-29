status: consumed
updated: 2026-08-29
skill: implement
step: 3

# Gate 001 — Step 3's head fuzzy scorer contradicts its own Verify

## The conflict

Step 3 spec text defines the fuzzy branch of `_term_score` as:

> `W_HEAD_FUZZ * fuzz.token_set_ratio(term, head)` when that ratio ≥ `FUZZ_FLOOR_HEAD`

Step 3 Verify feeds `_term_score('dnsmaq', 'fujitsu dnsmasq dhcp', '')` and expects
"a value strictly between 0 and 100 (the fuzzy hit)".

Measured with rapidfuzz 3.14.5:

| scorer | `('dnsmaq', 'fujitsu dnsmasq dhcp')` |
|---|---|
| `fuzz.token_set_ratio`          | 46.2  |
| `fuzz.partial_token_set_ratio`  | 83.3  |
| `fuzz.WRatio`                   | 75.0  |
| `fuzz.token_set_ratio('dnsmaq','dnsmasq')` (term vs best token) | 92.3 |

`token_set_ratio(term, head)` against the whole head string = 46.2, below the
floor of 70 → the fuzzy branch yields 0.0, and the Verify's second value comes
back `0.0` not "between 0 and 100". The literal spec text cannot pass its own
Verify.

This also breaks Step 9's fuzzy test ("`dnsmaq` finds a `dnsmasq` record"): a
one-character typo would score 0 on a title-only match.

## Why this needs a decision, not a guess

The scorer shape feeds every ranking assertion in Step 9. Decision 9 says the
*constants* are tunable without rewriting the suite, but the *scorer function*
is not a constant. Changing it is a design call that belongs to the plan author.

## Options

**A (recommended) — score the term against the best single token of head.**
`fuzz.token_set_ratio(term, best_token_of_head)` where `best_token` maximises the
ratio. `dnsmaq`→`dnsmasq` = 92.3 → 0.7·92.3 = 64.6 (between 0 and 100, passes
Verify). Standard fuzzy-search practice; keeps false positives low because an
unrelated short token won't clear floor 70. Body branch stays as written
(`partial_token_set_ratio(term, body)` already handles the long-string case).

**B — swap the head scorer to `fuzz.WRatio(term, head)`.** Minimal text change,
whole-head comparison preserved. `dnsmaq` vs the head = 75.0 → 0.7·75 = 52.5,
passes. But WRatio is a composite heuristic; its behaviour on longer heads is
harder to reason about for the Step 9 orderings.

**C — lower `FUZZ_FLOOR_HEAD` to ~45 and keep `token_set_ratio(term, head)`.**
Passes the Verify (46.2·0.7 = 32.3) but a 46 floor admits a lot of weak matches;
likely to make Step 9's "exact title ranks above description-only" and the 4 KB
brief case flaky.

## Response

response: Option A, with `FUZZ_FLOOR_HEAD` raised 70 -> 80.

Head fuzzy branch scores the term against the BEST SINGLE TOKEN of `head`, not
the whole concatenated string: `max(fuzz.token_set_ratio(term, tok) for tok in
head.casefold().split())`. This removes the multi-token dilution that made
`token_set_ratio('dnsmaq', 'fujitsu dnsmasq dhcp')` = 46.2. Term-vs-single-token
is effectively `fuzz.ratio`, pure and explainable (keeps decision 9's
tunability, stays in decision 3's token-set family).

Floor 70 -> 80 because per-token ratios run higher than the diluted whole-string
metric; 80 restores selectivity (`dnsmaq`/`dnsmasq` = 92.3 clears it; near-miss
noise like `wifi`/`wiki` = 75 is rejected).

Verify points under A:
- `_term_score('dnsmasq', head, '')` -> 100.0 (exact-token short-circuit)
- `_term_score('dnsmaq', head, '')`  -> 0.7 * 92.3 = 64.6 (0 < x < 100)
- `_term_score('zzzz', head, '')`    -> 0.0 (best per-token ratio < 80)

Scope: per-token logic is HEAD-ONLY. Body branch stays exactly as the plan wrote
it -- `fuzz.partial_token_set_ratio(term, whole_body)` with `FUZZ_FLOOR_BODY`
unchanged (long prose; `partial_token_set_ratio('dnsmaq', <body>)` = 83.3). So
`_one_side` splits into a head path (per-token max) and a body path (unchanged).

Not B (WRatio): composite heuristic with baked-in length penalties, hard to
reason about for Step 9's ordering assertions, abandons the token-set decision.
Not C (drop floor to ~45): fuzzy hits compress to 31-32 after the *0.7, barely
clear SCORE_CUTOFF=30, don't separate -> flaky ranking suite.
