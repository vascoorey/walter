# Tests

Behavioural suites for the hooks. Plain bash, no framework, no dependencies beyond
what walter itself needs: `bash`, `jq`, `git`, and the `backlog` CLI.

Run one, or all of them:

```bash
bash tests/bd33-e2e.sh
for f in tests/*-e2e.sh; do bash "$f"; done
```

Each suite prints `PASS=n FAIL=n` and exits non-zero on failure. Each builds its own
disposable git repo and board under `mktemp -d`; set `WALTER_TEST_ROOT` to put those
somewhere you can inspect afterwards.

| suite | asserts |
|---|---|
| `bd18-e2e.sh` | read-only board queries are not denied by the transition guard |
| `bd19-e2e.sh` | only columns the board actually has are ever offered |
| `bd25-e2e.sh` | the commitment rule, subtask denial, and `parent.sh` byte preservation |
| `bd31-e2e.sh` | green cache, `dod_baseline`, dependency marking, terminal cap, claim gate |
| `bd32-e2e.sh` | `parent.sh` never truncates a task file and never reports a false success |
| `bd33-e2e.sh` | every hook entry point survives macOS system bash 3.2 |
| `bd40-e2e.sh` | the contract drift report never emits a verdict and always names what it skipped |
| `pairing-e2e.sh` | `Pairing` is human-only to enter and survives a stop |
| `cpprobe.sh` | the write guard's source-versus-destination rule (called by `bd31`) |

## Two things to know before changing them

**These are not wired into `test_command`, deliberately.** The repo's verification gate
is still the syntax check. These suites create git repos, write to `/tmp` and shell out
to the `backlog` CLI, so a flaky or environment-dependent one would block every stop in
this repo rather than just failing a run. Wiring them in is worth doing and is tracked
separately; it needs its own thought about which suites are safe on the hot path.

**Run them under `/bin/bash` as well as whichever bash is on `PATH`.** macOS ships bash
3.2 and homebrew installs 5.x. `bd33-e2e.sh` exists because 183 assertions once passed
green while a hook was broken on 3.2, purely because every suite invoked hooks through
`PATH` bash. A suite that only ever sees one interpreter is not testing the one your
users have.

## Adding a suite

Copy the harness from any existing file: `ok`/`has`/`hasnt` helpers, a disposable board
per case, `PASS=`/`FAIL=` totals at the end.

The rule worth keeping is that **a regression suite must be shown to detect the bug it
covers**. Revert the fix in a copy and confirm the suite goes red. Both `bd32` and `bd33`
were verified this way, and it mattered: an earlier version of the `bd33` check passed
vacuously because the library it was meant to exclude loaded anyway, so it never
exercised the path it existed to test.
