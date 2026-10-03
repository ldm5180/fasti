# fasti

A SPARK-proven CBOE/NYSE trading-day calendar for Ada 2022.

`fasti` (Latin: the Roman calendar of *dies fasti* — the days on which
business could lawfully be conducted) computes the US equity-options
trading calendar instead of tabulating it: weekends plus the ten US market
holidays (Good Friday via the Meeus/Jones/Butcher Easter computus), with
weekend observance shifted Saturday → preceding Friday and Sunday →
following Monday, and NYSE Rule 7.2's accounting-period exception matched
exactly (a Saturday New Year's is not observed at all — the preceding
Dec 31 stays open, as in 2011, 2022, and next on 2027-12-31).

## What's in it

- **`Fasti`** — one pure package over packed `YYYYMMDD` dates:
  - `Is_Trading_Day` / `Is_Market_Holiday` / `Valid`
  - `Expirations` — the next N trading days from-and-including a date
    (0-DTE enumeration; SPXW expires every trading day)
  - `Weekday_Of` (Go's Sunday = 0 numbering) and `Weekday_Allowed`
    (decimal digit masks, e.g. `2345` = Tue–Fri)
  - `Days_Between` and `Prior_Trading_Day`
  - `To_Eastern` — UTC epoch milliseconds → the US/Eastern wall-clock
    day + ms-of-day, with DST computed by the same calendar math
- The calendar arithmetic rides the proven
  [tempus](https://github.com/ldm5180/tempus) civil-calendar core; every
  unit carries `SPARK_Mode` and the proof runs at level 2 with
  `--checks-as-errors=on`.
- The behavioral anchor: a **1096-day characterization fixture**
  (2026–2028) dumped from a production Go trading bot's
  `IsCboeBusinessDay` (rickar/cal), matched exactly — except the one
  pinned-both-ways Rule 7.2 deviation above, where NYSE's actual
  behavior wins.

## Use it

Add the dependency (via a git pin until it is in the community index).
The workspace must pin tempus at the same commit fasti pins — alr 2.x
refuses conflicting pin links:

```toml
[[depends-on]]
fasti = "*"
```

```ada
with Fasti;

if Fasti.Is_Trading_Day (20_260_706) then ...
```

## Develop

```sh
make build    # build the library
make test     # AUnit suite, both -O modes (fully offline)
make features # the Gherkin features in tests/features/, both -O modes
make features-report # the living documentation, as CI publishes it
make prove    # SPARK proof, --checks-as-errors=on
make format   # gnatformat --check
make run      # build and run the example
make help     # all targets
```

What the calendar does is stated as Gherkin features in
[tests/features](tests/features), and published as living documentation
at <https://ldm5180.github.io/fasti/> from every push to main.

Conventions (SPARK, strict TDD, commit style) live in [CLAUDE.md](CLAUDE.md).
