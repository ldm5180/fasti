# Feature tests plan

Status: in progress on branch `feature-tests`: F0-F2 done; F3-F10 to do.

The calendar's behavior, stated in Gherkin and run against the proven
functions with nothing to fake.  `*.feature` files under
`tests/features/` say what the trading calendar does -- a Saturday
holiday closes the Friday before it, a Saturday New Year's closes
nothing, a chain fetch on the Thursday before the Fourth expires
Thursday then Monday, a UTC midnight is the previous Eastern evening --
and a small Ada step registry on
[fabula](https://github.com/ldm5180/fabula) runs them, each feature's
steps an sml state machine.  The AUnit suite keeps the mechanism and
the 1096-day fixture; the features keep the story.

This is the third of a family: `fructus/docs/feature-tests-plan.md`
and `nuntius/docs/feature-tests-plan.md` came first, and nuntius's was
implemented (its PR #4) before this was written, so this plan starts
from what that implementation settled: the step code as machines, a
streaming coloured `make features`, published living documentation,
and the testing-layers guidance.  What is different here is the world:
nuntius IS the wire and opened loopback sockets; fasti is a pure SPARK
core, so a feature's world is a date, an instant or a mask, and most
scenarios are outlines in the operator's words.

## How to use this plan

Work the items in order; each is one TDD cycle (RED first, the exact
assertion given) and one commit, logged in `docs/tdd-log.md`.  F0 is
the dependency, F1 the runner (as a machine from the first step) and
F2 the world and vocabulary, with nothing of the calendar's behavior
in them; F3-F7 are the five features of the first wave; F8 streams the
runner's report; F9 publishes it; F10 is the documentation and the
testing-layers note.  After each item: `alr --non-interactive build
--validation`, `make test`, `make features`, `make format`.  Nothing in
this plan touches `src/`, so `make prove` is never owed by it -- and
`proof/proof.gpr` never learns fabula's name.

Five decisions, taken up front:

- **The proven functions are the seam.**  A feature's world is a date
  written as the operator writes it (`2026-07-03`), an epoch instant,
  a weekday mask; the step calls `Fasti` directly.  No clock, no file,
  no task: the `Before` hook resets the world and that is the whole
  lifecycle.
- **The steps are sml machines from the first commit.**  `Fasti_Steps.Flows`
  is the runner nuntius settled on (`Sml.Simple_Machines` over
  `Step_Kind` and a `Step_Context`, the operator layer, a bounded
  follow-up); each feature's steps are a machine in a child package
  with real states, and the registry offers every step to each feature
  as a region.  A step taken out of order fails naming every feature's
  state, rather than doing something undefined.
- **One test project, two mains.**  `tests/test_fasti.gpr` gains
  `with "fabula"` and `fasti_features.ads`; the step packages live in
  `tests/src/` beside the suite.  `make format` already covers that
  directory.
- **Nothing is removed from the AUnit suite.**  Every test in
  `tests/src/fasti_tests.adb` is a unit test by the house guidance (one
  function, a few inputs) and must keep covering its function
  completely; the fixture test is the characterization anchor.  The
  features duplicate their facts in the operator's words, which is
  wanted.  Section 7 says so item by item.
- **A feature binds behavior; the unit tests hold the how.**  A step
  checks only what a consumer of `Fasti` can observe and would want
  promised -- a verdict, a count, a list, a wall-clock reading, a
  refusal -- never how the calendar arrives at it.  Setup may be
  white-box (a date word, a mask, an instant); the checks stay
  external.  Where a feature lifts a unit test's fixture, the test's
  own assertions stay in the suite and the feature restates the
  outcome only.  Byte-level and representation detail (a packed date,
  a weekday number, ms-of-day arithmetic) is pinned by the unit tests
  of the functions that own it.

### Do not

- Do not check how.  A step that wants a packed date, a weekday
  number, a millisecond count, a branch taken or any other internal is
  a unit test of that function, not a feature step; write or extend
  the unit test and keep the feature's step at the outcome.

- Do not reach for a file or a clock in a step.  The fixture CSV stays
  the AUnit suite's; a feature states a date's verdict in its own
  line, and the suite proves 1096 of them against the dump.
- Do not spell a date as a number in a feature.  `20260703` is what
  the API takes; the feature says `2026-07-03`, and the step packs it.
  A date that does not read fails the step by name.
- Do not restate the AUnit suite assertion for assertion.  "The Friday
  before a Saturday Fourth is closed" is a feature; "`Weekday_Of
  (20_260_704) = 6`" stays a unit test.
- Do not put byte-level or representation detail in a feature: the
  packed `YYYYMMDD` shape, Go's weekday numbering as a number, the
  ms-of-day arithmetic.  A feature says "a Sunday", "16:23:11.998 ET".
- Do not add fabula to `proof/proof.gpr`.  It is a test dependency;
  the proof tree sources `src`, the tempus pin cache and `sml` only.
- Do not fix fabula's `-gnatwu` warning (`fabula-run.adb:258`, a GNAT
  15 false positive) from here; under the dependency profile it is a
  warning and this crate builds clean with it (section 5).
- Do not remove an AUnit test.  See the fourth decision and section 7.

## 1. What fabula is, in the terms this crate uses

A fabula binary is one instantiation of `Fabula.Main` over a
`Fabula.Registry` instance: an enumeration of step kinds, a table that
maps a Cucumber-expression pattern to a kind
(`Step ("the date is {word}") >= E_Day_Given`), an enumeration of hook
kinds with its table, a `Context` record one scenario owns, and two
procedures -- `Execute (Kind, Ctx, Args, Frame, Outcome)` and
`Run_Hook`.  Checks record into an `Outcome`
(`Fabula.Check.Ints.Equal`, `Fabula.Check.Is_True`, `Fail_Step`); a
step body that raises becomes a failed step and the run goes on.
Captures read 1-based (`Fabula.Args.Int`, `.Word`, `.Text`); a step's
data table reads as raw cells or as hashes; a `Scenario Outline`'s
`Examples` substitute into the step text, which is how most of this
crate's features are written.  The binary walks its paths sorted,
exits 1 on any failed scenario, and prints `N Scenarios (...)`.

Three fabula facts shape the vocabulary here:

- `{word}` captures a run of non-blanks, so a date is `{word}`
  (`2026-07-03`) and so is a clock time (`16:23:11.998`).  A `{string}`
  is double-quoted only.  A `/` after a letter in a pattern is a
  choice (`is/are`), not a slash -- no pattern here needs one.
- A capture's `String` does not start at index 1.  Every slice of a
  capture is written against `'First` (section 5 caught the first
  attempt).
- `Fabula.Numbers.Parse_Integer` reads `-?[0-9]+` and nothing else, so
  a packed date is parsed from the word's digits run together, and an
  epoch in milliseconds needs `Parse_Long` (it is past `Integer`).

## 2. Where things live

```
tests/
  features/
    trading-days.feature       F3  holidays, observances, Rule 7.2
    expirations.feature        F4  0-DTE enumeration, the prior session
    eastern.feature            F5  UTC instants in Eastern wall-clock
    weekdays.feature           F6  day names and entry masks
    arithmetic.feature         F7  civil days between dates
  src/
    fasti_features.ads         F1  the main: Fabula.Main instantiated
    fasti_steps.ads/.adb       F1  Step_Kind, the tables, the regions
    fasti_steps-flows.ads/.adb F1  the one runner every feature's machine uses
    fasti_steps-dates.ads/.adb F2  the date words: parse, pack, name
    fasti_steps-trading.ads/.adb    F3
    fasti_steps-expirations.ads/.adb F4
    fasti_steps-eastern.ads/.adb    F5
    fasti_steps-weekdays.ads/.adb   F6
    fasti_steps-arithmetic.ads/.adb F7
    fasti_tests.ads/.adb       unchanged, every test kept
  test_fasti.gpr               F1  with "fabula"; a second main
tools/
  features-report/             F9  report.js, package.json, package-lock.json
```

A feature file is named for the behavior it holds.  The vocabulary is
small enough (about twenty patterns) that the registry's `Step_Kind`
stays one enumeration; the machines are one child each.

## 3. The step vocabulary

Every pattern, the kind it names, and what the body does.  A date is
`YYYY-MM-DD`; a time is `HH:MM:SS.mmm` ET; an instant is epoch
milliseconds, written as the number Schwab emits.  Every "Given" that
takes a date has a guard that it reads and is in the supported window
(`Fasti.Valid`), with a refusing fallback row that names the word.

| Pattern | Kind | Body |
|---|---|---|
| `the date is {word}` | `E_Day_Given` | pack and keep the date |
| `it is a trading day` | `E_Check_Trades` | `Is_Trading_Day` |
| `the market is closed` | `E_Check_Closed` | `not Is_Trading_Day` |
| `it is a market holiday` | `E_Check_Holiday` | `Is_Market_Holiday` |
| `it is not a market holiday` | `E_Check_No_Holiday` | the negation |
| `it is a {word}` | `E_Check_Weekday` | `Weekday_Of` against the day name (`Sunday` .. `Saturday`) |
| `a chain fetch on {word} wants {int} expirations` | `E_Fetch` | `Expirations (From, Wanted)`; list and count kept |
| `it finds {int}` | `E_Check_Count` | the count |
| `the expirations are:` + one-column table | `E_Check_List` | each row a date, in order |
| `the prior trading day of {word} is {word}` | `E_Check_Prior` | `Prior_Trading_Day` |
| `the instant {int} ms after the epoch` | `E_Instant_Given` | `To_Eastern`; day, ms and Ok kept (the capture read with `Parse_Long`) |
| `in Eastern time it is {word} at {word}` | `E_Check_Eastern` | the day and the ms-of-day from `HH:MM:SS.mmm` |
| `it is before the epoch` / `past the supported window` | `E_Check_Refused` | `not Ok` |
| `the entry mask is {int}` | `E_Mask_Given` | the mask kept |
| `entry is allowed` / `entry is refused` | `E_Check_Allowed` / `E_Check_Refused_Entry` | `Weekday_Allowed (Mask, Day)` |
| `there are {int} days from {word} to {word}` | `E_Check_Between` | `Days_Between` |

### 3.1 The dates child

`Fasti_Steps.Dates` is the pure half every machine's guards read: a
word is a date (`Reads (Word)`), its packed value (`Packed (Word)`),
a day name's `Weekday_Number`, a `HH:MM:SS.mmm` word's milliseconds.
Guards call the queries; actions call the conversions after the guard
held.  No machine parses a word twice in two ways.

### 3.2 Bytes that do not fit a line

None are expected: every input here is a date, a time, a count or a
mask, and all fit a word.  Should one appear (a long instant table, a
dump), it is a named flat file under `tests/features/bytes/<name>.hex`
read by name, as the family rule says -- never an escape in a cell.

## 4. Items

### F0 -- fabula is a test dependency

- **Where:** `alire.toml:16` (`aunit`, the one existing test
  dependency), `:24` (`[[pins]]`, whose comment says tempus pins sml
  and "this crate never pins sml directly").
- **What is wrong:** nothing runs a `.feature` file.
- **Why:** the suite is AUnit end to end.
- **Fix:** `fabula = "*"` after `aunit`, and under `[[pins]]`
  `fabula = { url = "https://github.com/ldm5180/fabula.git", commit = "746a234df5581c2e38c4202aeee8b07473fb6a51" }`
  with a comment in the house shape: a test dependency, pinned by
  commit, whose own `sml` pin (`3ccd0e4`) equals the one tempus
  carries -- Alire follows a pinned crate's pins and refuses two links
  to one crate at different commits, so that equality is the
  precondition.  The pins comment gains the sentence.
- **RED first:** `fabula = "*"` without the pin: `alr build` warns
  `Generating possibly incomplete configuration because of missing
  dependencies` (it is in no index).  GREEN is the pin, verified in
  section 5: one `sml_3ccd0e4b` link in the cache, both routes agree,
  validation build 2.1 s.

### F1 -- The feature binary builds, and its steps are a machine

- **Where:** `tests/test_fasti.gpr:1-2` (`with "aunit"; with
  "../fasti.gpr";`) and `:16` (`for Main`); `alire.toml:36-51` (the
  four `[[actions]]` of type `test`); `Makefile:16-21` (`test:`),
  `:28-33` (`format:`, whose `tests/src/*.ad[sb]` glob covers the new
  packages); `.github/workflows/ci.yml:39-44` (the `alr test` step).
- **What is wrong:** no runner, and -- the lesson nuntius paid for --
  a runner that starts as a `case` over step kinds gets rewritten
  into machines later.
- **Why:** nuntius was built case-first and converted.
- **Fix:** `with "fabula";` beside `aunit` and
  `for Main use ("test_runner.adb", "fasti_features.ads");` -- a
  generic instantiation is a SPEC, so the main is an `.ads`.
  `tests/src/fasti_features.ads` instantiates `Fabula.Main` over
  `Fasti_Steps`.  `fasti_steps.ads` declares `Step_Kind`, the
  `Step_Context` (World, args, frame, outcome, `Has_Next`/`Next`),
  `Then_Take`, and the pattern table; `fasti_steps-flows.ads/.adb` is
  the runner, copied from nuntius's `Nuntius_Steps.Flows` with the
  name changed (`Sml.Simple_Machines` over `Step_Kind` and
  `Step_Context`, `with Sml.Machines.Operators` so the operator layer
  of the instance can be instantiated, `Take` with four bounded
  follow-ups).  The first machine is in `fasti_steps.adb` itself --
  three steps, two states -- and moves to `Fasti_Steps.Trading` in F3:

  ```ada
  type State is (Undated, Dated);
  type Guard_Kind is (Always, Date_Valid);
  type Action_Kind is
    (A_Nothing, A_Keep_Day, A_Refuse_Day, A_Check_Trades, A_Check_Closed);

  --!format off
  Table : constant Transition_Table :=
    [Undated + Day_Given (Date_Valid) / A_Keep_Day     >= Dated,
     Undated + Day_Given              / A_Refuse_Day   >= Undated,
     Dated   + Day_Given (Date_Valid) / A_Keep_Day     >= Dated,
     Dated   + Check_Trades           / A_Check_Trades >= Dated,
     Dated   + Check_Closed           / A_Check_Closed >= Dated];
  --!format on
  ```

  `Execute` wraps the world in a `Step_Context`, calls `Flow.Take`,
  copies the world and outcome back, and fails a step no row took
  with the state's name.  The `Before` hook resets the world and the
  machine's `Current`.  Two more `[[actions]]` after the existing
  four, argv-only like them:
  `["alr", "exec", "--", "tests/bin/release/fasti_features", "tests/features"]`
  and its `debug` twin.  A first `features` target (F8 makes it
  stream):

  ```make
  ## features    Build and run the Gherkin features in both modes.  fabula
  ##             exits 0 for a missing path or an empty file, so the
  ##             summary line is what says every scenario ran and passed
  features:
  	alr exec -- gprbuild -p -j0 -XMODE=debug -P tests/test_fasti.gpr
  	alr exec -- gprbuild -p -j0 -XMODE=release -P tests/test_fasti.gpr
  	@for mode in debug release; do \
  	  out=$$(alr exec -- tests/bin/$$mode/fasti_features tests/features) || \
  	    { printf '%s\n' "$$out"; exit 1; }; \
  	  printf '%s\n' "$$out" | grep -qE '^[1-9][0-9]* Scenarios? \([0-9]+ passed\)$$' || \
  	    { printf '%s\n' "$$out"; echo "features: $$mode: a scenario did not pass"; exit 1; }; \
  	done; echo 'features: every scenario passed in both modes'
  ```

  The CI workflow needs no new step for this: `alr test` runs the
  actions.
- **RED first:** `make features` -- "No rule to make target".  Then,
  with the target, the main and an EMPTY pattern table, the smoke
  feature's steps are `UNDEFINED` and the binary exits 1; the three
  rows turn it green.  The smoke feature, verified in section 5:

  ```gherkin
  Feature: The feature runner runs

    Scenario: A Thursday trades
      Given the date is 2026-07-02
      Then it is a trading day

    Scenario: The observed Fourth is closed
      Given the date is 2026-07-03
      Then the market is closed
  ```

  The smoke feature and its three steps go when F3 brings the real
  vocabulary.

### F2 -- The world and the date words

- **Where:** `src/fasti.ads:23-26` (`Yyyymmdd`, `Day_Milliseconds`,
  `Day`), `:34` (`Valid`), `:38` (`Weekday_Number`, Go's numbering);
  `tests/src/fasti_tests.adb:89-96` (`Test_Weekdays`, the four dates a
  feature will name by day).
- **What is wrong:** a feature says `2026-07-03`, `Saturday`,
  `16:23:11.998`; the API takes `20_260_703`, `6`, `58_991_998`.  Every
  machine would parse the same words.
- **Why:** the core is deliberately plain `Natural` subtypes so
  consumers' shapes stay assignment-compatible (`CLAUDE.md:54-55`).
- **Fix:** `Fasti_Steps.Dates`: `Reads (Word) return Boolean` (ten
  characters, digits in the right places, `Parse_Integer` of the
  digits run together, in `Fasti.Day`, `Fasti.Valid`); `Packed (Word)
  return Fasti.Day` with `Pre => Reads (Word)`; `Day_Named (Word)
  return Weekday_Number` and `Is_Day_Name` for `Sunday` .. `Saturday`;
  `Time_Reads` / `Ms_Of (Word)` for `HH:MM:SS.mmm`.  Every slice is
  against the word's `'First`.  The `World` record carries what a
  scenario reads back: the day, the expiration list and count, the
  Eastern day/ms/Ok, the mask, the prior day.
- **RED first:** `Given the date is 2026-07-02` followed by `Then it
  is a Thursday`, `UNDEFINED` until the dates child and the
  `E_Check_Weekday` row exist; green when it passes.  The harness's own
  refusal -- `Given the date is 2026-13-40` fails with `not a calendar
  date: 2026-13-40` -- is checked in a scratch feature directory, as
  the out-of-order steps are, never committed as a scenario: it binds
  the step vocabulary, not a behavior of `Fasti`.  The word parsers
  themselves (`Reads`, `Packed`, `Ms_Of`) get their own AUnit routine
  in `fasti_tests.adb`, since they are test code with edges of their
  own.

### F3 -- `trading-days.feature`: holidays, observances, Rule 7.2

- **Where:** `tests/src/fasti_tests.adb:17-66` (`Test_Cboe_Fixture`),
  `:72-85` (`Test_New_Years_Rule`); `src/fasti.ads:1-15` (the header
  that states the rules); `README.md:7-13`.
- **What is wrong:** the calendar's rules -- ten holidays, Saturday ->
  Friday and Sunday -> Monday observance, Good Friday by the computus,
  the Saturday New Year's that is not observed at all -- are stated in
  a spec comment and proved by a 1096-row CSV nobody reads.
- **Why:** the crate was extracted whole from arb-ada with its
  characterization fixture; the rules were never written as sentences
  with examples.
- **Fix:** the first feature, mostly outlines, the machine of F1
  moved into `Fasti_Steps.Trading` with `E_Check_Holiday`,
  `E_Check_No_Holiday` and `E_Check_Weekday` added:

  ```gherkin
  Feature: The market closes on weekends and ten holidays

    Scenario Outline: A weekday that is no holiday trades
      Given the date is <date>
      Then it is a <day>
      And it is a trading day

      Examples:
        | date       | day      |
        | 2026-07-02 | Thursday |
        | 2026-07-06 | Monday   |

    Scenario Outline: A weekend never trades
      Given the date is <date>
      Then it is a <day>
      And the market is closed
      And it is not a market holiday

      Examples:
        | date       | day      |
        | 2026-07-04 | Saturday |
        | 2026-07-05 | Sunday   |

    Scenario Outline: The ten holidays, each on its 2026 date
      Given the date is <date>
      Then it is a market holiday
      And the market is closed

      Examples:
        | date       | holiday          |
        | 2026-01-01 | New Year's Day   |
        | 2026-01-19 | MLK Day          |
        | 2026-02-16 | Presidents Day   |
        | 2026-04-03 | Good Friday      |
        | 2026-05-25 | Memorial Day     |
        | 2026-06-19 | Juneteenth       |
        | 2026-07-03 | Independence Day, observed |
        | 2026-09-07 | Labor Day        |
        | 2026-11-26 | Thanksgiving     |
        | 2026-12-25 | Christmas        |

    Scenario: A Saturday holiday closes the Friday before it
      Given the date is 2026-07-03
      Then it is a Friday
      And it is a market holiday

    Scenario: A Sunday holiday closes the Monday after it
      Given the date is 2023-01-02
      Then it is a Monday
      And it is a market holiday

    Scenario: A Saturday New Year's closes nothing
      Given the date is 2027-12-31
      Then it is a Friday
      And it is a trading day
      Given the date is 2028-01-03
      Then it is a Monday
      And it is a trading day

    Scenario Outline: Good Friday moves with Easter
      Given the date is <date>
      Then it is a Friday
      And it is a market holiday

      Examples:
        | date       |
        | 2026-04-03 |
        | 2027-03-26 |
        | 2028-04-14 |
  ```

  The holiday column of the third outline is a label fabula ignores
  (no step reads it); it is there for the reader of the living
  documentation.  The three Good Friday dates are taken from the
  fixture CSV (`tests/data/cboe_business_days_2026_2028.csv`) when
  the feature is written, not assumed.  `Test_Cboe_Fixture` and
  `Test_New_Years_Rule` keep every assertion they have; the feature
  restates the rules as dated sentences and never the fixture's
  row-by-row verdicts.
- **RED first:** `it is a market holiday` is `UNDEFINED`; green when
  the ten rows pass.  Then one mutation: change `2026-07-03` to
  `2026-07-06` in the Saturday-holiday scenario and see `the market
  trades` as the reason.

### F4 -- `expirations.feature`: 0-DTE enumeration and the prior session

- **Where:** `tests/src/fasti_tests.adb:103-124` (`Test_Expirations`),
  `:178-195` (`Test_Prior_Day`); `src/fasti.ads:53-66` (`Max_Span`,
  `Expirations`), `:82-83` (`Prior_Trading_Day`).
- **What is wrong:** that a chain fetch on Thursday 2026-07-02 asking
  for four expirations gets Thursday, Monday, Tuesday, Wednesday --
  the Friday is the observed Fourth, the weekend is skipped, and
  Monday trades (where the predecessor's Saturday->Monday rule got it
  wrong) -- is the one fact a consumer schedules by, stated as four
  array indexes.
- **Why:** the unit test pins the array; the sentence was never
  written.
- **Fix:** `Fasti_Steps.Expirations`, states `Unfetched`, `Fetched`:

  ```gherkin
  Feature: SPXW expires every trading day, so a chain fetch counts trading days

    Scenario: The Thursday before the Fourth, then the week after
      Given a chain fetch on 2026-07-02 wants 4 expirations
      Then it finds 4
      And the expirations are:
        | 2026-07-02 |
        | 2026-07-06 |
        | 2026-07-07 |
        | 2026-07-08 |

    Scenario: A fetch on a Saturday starts at the next trading day
      Given a chain fetch on 2026-07-04 wants 1 expirations
      Then it finds 1
      And the expirations are:
        | 2026-07-06 |

    Scenario Outline: The prior session steps over weekends and holidays
      Then the prior trading day of <date> is <prior>

      Examples:
        | date       | prior      |
        | 2026-07-10 | 2026-07-09 |
        | 2026-07-13 | 2026-07-10 |
        | 2026-07-06 | 2026-07-02 |
  ```

  A count past `Max_Span` (16) fails the step by name; the guard is
  `Count_Read` and `<= Max_Span`.  `Test_Expirations` and
  `Test_Prior_Day` keep their array and index assertions; the feature
  states the dates a consumer gets, in order.
- **RED first:** `a chain fetch on 2026-07-02 wants 4 expirations` is
  `UNDEFINED`; green on the four-row table.

### F5 -- `eastern.feature`: an instant in Eastern wall-clock

- **Where:** `tests/src/fasti_tests.adb:132-155` (`Test_To_Eastern`);
  `src/fasti.ads:94-99` (`To_Eastern`, DST at day granularity).
- **What is wrong:** three instants pinned against Python's zoneinfo
  -- a summer one (EDT), a winter one (EST), and a UTC midnight that
  is the previous Eastern evening -- are the whole statement of the
  conversion every market stamp lives in, as three magic numbers.
- **Why:** they were pinned, not explained.
- **Fix:** `Fasti_Steps.Eastern`, states `No_Instant`, `Converted`:

  ```gherkin
  Feature: A UTC instant is read on the US/Eastern wall clock

    Scenario Outline: Summer is EDT, winter is EST
      Given the instant <epoch_ms> ms after the epoch
      Then in Eastern time it is <date> at <time>

      Examples:
        | epoch_ms      | date       | time         |
        | 1720038191998 | 2024-07-03 | 16:23:11.998 |
        | 1768478400000 | 2026-01-15 | 07:00:00.000 |

    Scenario: A UTC midnight is the previous Eastern evening
      Given the instant 1767225600000 ms after the epoch
      Then in Eastern time it is 2025-12-31 at 19:00:00.000

    Scenario: Before the epoch there is no Eastern day
      Given the instant -5 ms after the epoch
      Then it is before the epoch
  ```

  The instant capture is read with `Fabula.Args.Long` (section 1).
  A DST-boundary pair (the Saturday before and the Monday after the
  second Sunday of March 2026, same UTC hour, one Eastern hour apart)
  is the one scenario the unit suite does not have and the feature
  adds: `2026-03-07 10:00 UTC is 05:00 EST; 2026-03-09 10:00 UTC is
  06:00 EDT` -- the two epochs computed when the feature is written
  and checked against `date -d`.  `Test_To_Eastern` keeps its three
  pinned instants and their ms-of-day values; the feature says the
  wall-clock time, and the ms arithmetic stays below.
- **RED first:** `the instant 1720038191998 ms after the epoch` is
  `UNDEFINED`; green on the summer row.

### F6 -- `weekdays.feature`: day names and the entry mask

- **Where:** `tests/src/fasti_tests.adb:89-96` (`Test_Weekdays`),
  `:160-174` (`Test_Weekday_Mask`); `src/fasti.ads:38-41`
  (`Weekday_Number`, `Weekday_Of`), `:70-71` (`Weekday_Allowed`).
- **What is wrong:** that an `entry_weekday` mask of `2345` admits
  Tuesday to Friday, that `5` is Friday only, and that `0` admits
  every day, is the operator's own knob and is stated as digit
  arithmetic.
- **Why:** it was ported from the predecessor's config semantics.
- **Fix:** `Fasti_Steps.Weekdays`, states `Unmasked`, `Masked`; the
  day-name step from F3 is reused:

  ```gherkin
  Feature: The entry mask names the weekdays a trade may enter on

    Scenario Outline: A digit mask admits the days it spells
      Given the entry mask is <mask>
      And the date is <date>
      Then it is a <day>
      And entry is <verdict>

      Examples:
        | mask | date       | day      | verdict |
        | 0    | 2026-07-02 | Thursday | allowed |
        | 2345 | 2026-07-02 | Thursday | allowed |
        | 2345 | 2026-07-10 | Friday   | allowed |
        | 1234 | 2026-07-10 | Friday   | refused |
        | 5    | 2026-07-10 | Friday   | allowed |
        | 5    | 2026-07-02 | Thursday | refused |
  ```

  `entry is {word}` is one step whose guard reads `allowed`/`refused`
  and whose fallback names any other word.  `Test_Weekdays` and
  `Test_Weekday_Mask` keep Go's numbering as numbers; the feature
  never shows a weekday as a number.
- **RED first:** `the entry mask is 2345` is `UNDEFINED`; green on the
  six rows.

### F7 -- `arithmetic.feature`: civil days between dates

- **Where:** `tests/src/fasti_tests.adb:198-210` (`Test_Days_Between`);
  `src/fasti.ads:75-76` (`Days_Between`).
- **What is wrong:** the signed civil-day difference DTE math and the
  greeks year fraction hang off is four asserts.
- **Fix:** `Fasti_Steps.Arithmetic`, one state, one outline:

  ```gherkin
  Feature: Days between two dates count civil days, signed

    Scenario Outline: From one date to another
      Then there are <days> days from <from> to <to>

      Examples:
        | from       | to         | days |
        | 2026-07-10 | 2026-07-10 | 0    |
        | 2026-07-10 | 2026-07-13 | 3    |
        | 2026-02-28 | 2026-03-01 | 1    |
        | 2028-02-28 | 2028-03-01 | 2    |
        | 2026-07-13 | 2026-07-10 | -3   |
  ```

  The leap-year row is the one the unit suite lacks; `Test_Days_Between`
  keeps its four asserts and may gain the row too (section 7).
- **RED first:** `there are 0 days from 2026-07-10 to 2026-07-10` is
  `UNDEFINED`; green on five rows.

### F8 -- `make features` streams its report, in colour

- **Where:** the `features:` target F1 added to `Makefile`.
- **What is wrong:** F1's target holds the output until the end and
  prints it only on a failure; and fabula colours only a terminal, so
  a `tee` loses the colour.
- **Why:** both were learned on nuntius.
- **Fix:** per mode, `{ runner; echo $? > rc; } | tee log`; when make
  itself writes to a terminal (`[ -t 1 ]`, tested BEFORE the pipe) run
  the runner as `script -qefc "$run" /dev/null` so it sees a pty; then
  check the exit status from `rc` and the summary line from the log
  with the colour codes and `\r` stripped (`sed -e 's/\x1b\[[0-9;]*m//g'
  -e 's/\r$//'`).  POSIX sh, no `PIPESTATUS`.  The exact recipe is
  nuntius's `Makefile` `features:` target.
- **RED first:** `script -qefc "make features" log` shows no `\x1b[32m`
  before; after, it does, and a piped run shows none.  A deliberately
  broken expectation still fails the target and prints the failed step
  in red.

### F9 -- The living documentation, published

- **Where:** `.github/workflows/ci.yml:39-47` (the test step and the
  `make run` step of `build-and-test`); `.gitignore:9`
  (`/example/bin/`).
- **What is wrong:** the features are readable only with a checkout.
- **Fix:** `tools/features-report/` with `package.json`
  (`multiple-cucumber-html-reporter`), its committed `package-lock.json`,
  and `report.js` (copy nuntius's, retitled "fasti -- what the
  calendar does"); `.gitignore` gains
  `/tools/features-report/node_modules/`; a `features-report` target
  that runs the release binary with `--report-json
  obj/features-report/json/features.json`, then `npm ci --prefix
  tools/features-report` and `node tools/features-report/report.js`
  into `obj/features-report/html`, exiting with the runner's status
  AFTER the page is made.  In CI, after `make run`: `actions/setup-node@v7`
  (node 22, npm cache on the lockfile), `make features-report`
  (`if: success() || failure()`), `actions/upload-artifact@v7` of the
  html, and on a push to `main` `actions/upload-pages-artifact@v5`;
  a `pages` job (`needs: build-and-test`, `permissions: pages: write,
  id-token: write`, environment `github-pages`) with
  `actions/deploy-pages@v5`.  Enable Pages once:
  `gh api -X POST repos/ldm5180/fasti/pages -f build_type=workflow`.
  The page lands at `https://ldm5180.github.io/fasti/`.
- **RED first:** `make features-report` -- no rule; then the page
  exists at `obj/features-report/html/index.html` and lists five
  features; a broken expectation still produces the page and fails
  the target.

### F10 -- The docs say so, and the layers

- **Where:** `CLAUDE.md:13-21` ("Commands"), `:27-29` (the `tests/`
  layout line), `:57-61` ("Conventions"); `README.md:52-60` ("Develop").
- **Fix:** `make features` and `make features-report` lines in both;
  the layout line names `tests/features/`, `fasti_features.ads` and
  the per-feature machines; the README links the published page; and
  a Conventions bullet states the testing layers as the house settled
  them: a unit test typically tests a single function, or at most a
  simple interaction between two, and the unit tests always cover
  the function they test completely; a feature tests the larger
  interactions that form a higher-level, conceptual feature; coverage
  is wanted and duplication across the layers is fine; a test is
  removed only when it is an integration test a BDD scenario fully
  supplants.  Guidance for judgement, not a mechanical rule.

## 5. Verified in a scratch worktree (iteration 3)

Against the tree at `9e18c07`, in a detached worktree under the
session scratchpad, GNAT 15.2.0, gprbuild 26.0.1, 2026-10-03:

1. `fabula = "*"` pinned at `746a234` beside `aunit`:
   `alr --non-interactive build --validation` succeeds in 2.1 s
   (5.2 s wall with the deploys).  The pin cache holds exactly
   `fabula_746a234d`, `sml_3ccd0e4b`, `tempus_51712384` -- one `sml`
   link, reached through tempus and through fabula alike.  No
   conflict, so F0 is the one line.
2. The F1 sketch typed in: `with "fabula"`, the second main as an
   `.ads`, `Fasti_Steps.Flows` as above, the three-step machine with
   its guarded and fallback rows, the two-scenario smoke feature.
   `gprbuild -P tests/test_fasti.gpr` builds in 2.4 s.  The first run
   FAILED both scenarios with `fasti_steps.adb:21 range check failed`:
   the date word was sliced at `(1 .. 4)`, and a fabula capture's
   `String` does not start at 1.  Sliced against `'First`, the run
   prints `2 Scenarios (2 passed) / 4 Steps (4 passed)`, exit 0 --
   the correction is F2's rule, and section 1's second bullet.
3. Out-of-order and bad-input refusals, from a scratch feature: `Then
   it is a trading day` with no date given fails `E_CHECK_TRADES is
   not a step this scenario can take now: UNDATED`; `Given the date is
   2026-13-40` fails `not a calendar date: 2026-13-40`.
4. Not verified here: the `script(1)` colour recipe and the report
   tool, both copied from nuntius where they run in CI today.

## 6. The second wave, sketched

- **The supported window's edges** (`First_Year`, `Last_Year`): a date
  in 1969 or 2200 is refused by `Valid`, an instant past the window by
  `To_Eastern`.  One outline, if the operator ever cares.
- **`Prior_Trading_Day`'s `Ok` False**: two weeks back with no trading
  day never happens in practice; a scenario at the window's first days
  is the only way to show it.
- **Rule 7.2's next occurrences** (2033-12-31 and on): an outline that
  grows a row a decade.

## 7. The AUnit suite stays whole

By the house guidance, nothing in `tests/src/fasti_tests.adb` is an
integration test: each routine calls one `Fasti` function on a handful
of inputs, and `Test_Cboe_Fixture` is the characterization anchor the
`CLAUDE.md` contract names.  Every one keeps covering its function
completely, and the features restate their facts in the operator's
words, which is wanted -- so this plan removes no test.  The two facts
the features add that no unit test holds (a DST-boundary pair in F5, a
leap-year row in F7) may be added to the suite as well, in the same
commit, so the unit layer stays complete.

## Revision notes

- **Iteration 1 (draft):** the seam, the layout, the vocabulary, eleven
  items, the second wave; the nuntius plan's shape with the loopback
  world replaced by dates and instants.
- **Iteration 2 (as a newcomer):** added "How to use this plan" with
  the four up-front decisions (the machines-from-the-first-commit one
  and the no-removal one are what the nuntius implementation settled),
  the "Do not" list, section 1 with the three fabula facts that shape
  date and instant captures, the dates child (3.1), full Gherkin
  sketches for every feature, the F1 machine and Makefile sketches, a
  RED per item, section 7 on the suite, and the two facts the features
  add that the unit suite lacks.
- **Iteration 3 (against the tree at `9e18c07`, and the scratch
  builds of section 5):** every `file:line` re-located.  Corrected: the
  date capture is sliced against `'First`, not `1` (a range check in
  the scratch); the instant capture needs `Parse_Long`, `Parse_Integer`
  cannot hold `1_720_038_191_998`; `alire.toml`'s `aunit` is line 16
  and `[[pins]]` 24, the actions `36-51`; the CI test step is
  `ci.yml:39-44` and `make run` follows at 46-47; `Test_To_Eastern` is
  `132-155` and `Test_Prior_Day` `178-195`; every `fasti.ads` anchor
  moved by one or two lines from the draft (`Valid` is 34, not 36;
  `Weekday_Number` 38; `Expirations` 60; `Weekday_Allowed` 70;
  `Days_Between` 75; `Prior_Trading_Day` 82; `To_Eastern` 94), as did
  the `CLAUDE.md` contract line (54-55).  Confirmed: `for Main` at
  `tests/test_fasti.gpr:16`, `test:` at `Makefile:17`, `format:` at
  29, the eight test routines at the lines cited, `/example/bin/` at
  `.gitignore:9`, the README's Rule 7.2 paragraph at 7-13.
- **After the behavior guidelines (2026-10-03):** audited every check
  step against the two rules -- a feature binds what a consumer of
  `Fasti` can observe; the how stays in the unit tests.  Every step
  already read a public outcome (a verdict, a count, a list, an
  Eastern reading, a refusal), so none was rewritten.  Changed: the
  fifth up-front decision and the first Do-not state the rules; F2's
  RED no longer commits a scenario about the harness's own date
  refusal (it is a scratch check, and the word parsers get an AUnit
  routine); F6 is "day names and the entry mask" -- Go's numbering is
  the unit tests' word, not the feature's; F3-F7 each say the lifted
  unit test keeps its assertions and the feature restates the outcome
  only.
- **During F1 (2026-10-03):** the first machine was written in
  `Fasti_Steps.Trading` from the start, not in `fasti_steps.adb` to be
  moved in F3, and the smoke feature is the first two scenarios of
  `trading-days.feature`, which F3 grows rather than deletes -- the
  history stays linear, with nothing written to be moved or removed.
  `Fasti_Steps.Dates` is born here with `Reads` and `Packed`, which the
  first guard needs; F2 adds the day names, the clock words and their
  unit tests.  The table gained `Dated + Day_Given / A_Refuse_Day`, so
  a bad second date is refused by name like the first.  Confirmed in a
  scratch directory: a check before any date fails `E_CHECK_TRADES is
  not a step this scenario can take now: trading days=UNDATED`;
  `2026-13-40` and `20260702` fail `not a calendar date: <word>`.
- **During F2 (2026-10-03):** the day-name half is `Name_Of
  (Weekday_Number)` and `Is_Day_Name`, not `Day_Named`: the check
  compares the date's own name with the word, so its failure says
  which day it is (`it is a Thursday`).  Both shape checks are one
  `Fits (Word, "dddd-dd-dd")` template match.  The parsers' unit
  tests are a pair of their own, `Fasti_Steps_Dates_Tests`, beside
  `Fasti_Tests` rather than inside it, one pair per unit.  The `World`
  grows a field with the feature that first reads it, not all at once.
