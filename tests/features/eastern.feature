Feature: A UTC instant is read on the US/Eastern wall clock

  Every US-market stamp lives on the Eastern wall clock: an instant in
  epoch milliseconds (what Schwab emits) is read as an Eastern date and
  time.  Daylight time runs from the second Sunday of March to the
  first Sunday of November, so the same UTC hour is an hour later on
  the Eastern clock in summer than in winter.

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

  Scenario Outline: Daylight time begins between the Saturday and the Monday
    Given the instant <epoch_ms> ms after the epoch
    Then in Eastern time it is <date> at <time>

    Examples:
      | utc                  | epoch_ms      | date       | time         |
      | 2026-03-07 10:00 UTC | 1772877600000 | 2026-03-07 | 05:00:00.000 |
      | 2026-03-09 10:00 UTC | 1773050400000 | 2026-03-09 | 06:00:00.000 |

  Scenario Outline: Outside the supported window there is no Eastern day
    Given the instant <epoch_ms> ms after the epoch
    Then it has no Eastern day

    Examples:
      | when                   | epoch_ms      |
      | before the epoch       | -5            |
      | 2200-01-01 12:00 UTC   | 7258161600000 |
