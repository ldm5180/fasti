# fasti

The SPARK-proven CBOE/NYSE trading-day calendar (Latin: the Roman calendar
of *dies fasti*, the days business could lawfully be conducted), extracted
from arb-ada's `Arb.Calendar` so it is reusable and independently proven.
One pure package (`Fasti`) over packed `YYYYMMDD` dates: holiday
computation (Meeus computus Good Friday, weekend observances, the NYSE
Rule 7.2 Saturday-New-Year's exception), 0-DTE expiration enumeration,
Go-numbered weekdays + digit masks, day arithmetic, and UTC→US/Eastern
conversion with computed DST. The calendar arithmetic stays strictly
inside `Tempus.Calendar`'s proven bounds.

## Commands

- `make build`   — build the library (`alr build`)
- `make test`    — AUnit suite in BOTH modes (release -O3, debug -O0);
  fully offline
- `make features` — the Gherkin features under `tests/features/` in both
  modes, on fabula, printing the report as it goes (in colour on a
  terminal); checks the summary line, since fabula exits 0 for a
  missing path.  `alr test` runs them too
- `make features-report` — the living documentation: the features with
  `--report-json`, rendered by multiple-cucumber-html-reporter
  (`tools/features-report`, node) into `obj/features-report/html`.  CI
  keeps it with every run and publishes it from main to
  https://ldm5180.github.io/fasti/
- `make prove`   — SPARK proof, `--checks-as-errors=on`; must exit 0
- `make format`  — `gnatformat --check` over all committed Ada sources
- `make run`     — build and run the example
- `alr --non-interactive build --validation` — warnings-as-errors gate (CI)

## Layout

- `src/` — the one library unit (`Fasti`), pure SPARK: zero IO, depends
  only on `Tempus.Calendar`.
- `tests/` — AUnit suite (`test_fasti.gpr`, driver `test_runner.adb`) +
  `tests/data/cboe_business_days_2026_2028.csv`, the 1096-day
  characterization fixture.  The same project's second main,
  `fasti_features.ads`, is the fabula runner over `tests/features/*.feature`:
  `Fasti_Steps` is the step registry, each feature's steps an sml machine
  in a child (`Fasti_Steps.Trading`, `.Expirations`, `.Eastern`,
  `.Weekdays`, `.Arithmetic`) run by `Fasti_Steps.Flows`, and
  `Fasti_Steps.Dates` reads the words a feature writes (`2026-07-03`,
  `Thursday`, `16:23:11.998`).  A step taken out of order fails naming
  every feature's state.
- `proof/` — gnatprove harness; `proof.gpr` sources `../src` AND the
  tempus pin cache (`../alire/cache/pins/tempus_<sha8>/src`) directly —
  never fasti.gpr/tempus.gpr, whose Alire config gprs would drag AUnit
  into the proof tree. **Bumping the tempus pin means updating that
  Source_Dir's sha to match.**
- `example/` — one demo main (`next_expirations`).
- `docs/tdd-log.md` — git-ignored TDD audit log.

## Pins (do not break)

- tempus is commit-pinned; a consumer workspace (arb-ada) must pin the
  SAME tempus commit — alr 2.x refuses conflicting pin links — so bumping
  tempus here is coordinated with the application repos. tempus pins sml
  the same way; that link rides along (this crate never pins sml).
- fabula, the TEST dependency the features run on, is commit-pinned too,
  and its own sml pin must equal tempus's — the same no-conflicting-links
  rule.  It never enters `proof/proof.gpr`.

## Behavioral contract (do not break)

- The fixture is characterization truth: 1096 days (2026–2028) dumped
  through options_bot's `IsCboeBusinessDay` (rickar/cal). Every verdict
  matches EXCEPT 2027-12-31, the deliberate NYSE Rule 7.2 deviation —
  the fixture test pins the disagreement BOTH ways, so a regenerated
  fixture that starts agreeing must remove the special case.
- `Weekday_Number` is Go's numbering (Sunday = 0) — consumers' digit
  masks are written in it.
- `Yyyymmdd`/`Day_Milliseconds` stay plain `Natural` subtypes so
  consumers' identically-shaped subtypes remain assignment-compatible.

## Conventions

- Strict TDD (red/green/refactor, logged in `docs/tdd-log.md`), SPARK
  everywhere (`SPARK_Mode` on every unit; `make prove` exit 0 after any
  src change), gnatformat-enforced style, Alire validation profile clean.
- Tests are layers -- guidance for judgement, not a mechanical rule.  A
  unit test typically tests a single function, or at most a simple
  interaction between two, and the unit tests always cover the function
  they test completely.  A feature (BDD) tests the larger interactions
  that form a higher-level, conceptual feature, in the operator's words,
  one fact per step.  Coverage is wanted and duplication across the
  layers is fine: a test is removed only when it is purely redundant --
  an integration test a BDD scenario fully supplants.
- A feature binds behavior a consumer of `Fasti` can observe (a verdict,
  a list of dates, a wall-clock reading, a refusal), never how: a packed
  date, a weekday number or a millisecond count stays in the unit tests.
