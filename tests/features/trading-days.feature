Feature: The market closes on weekends and ten holidays

  The CBOE calendar: Saturdays and Sundays never trade, and ten US
  market holidays close the market.  A holiday that falls on a weekend
  is observed on the nearest weekday -- a Saturday one on the Friday
  before, a Sunday one on the Monday after -- except New Year's Day on
  a Saturday, which NYSE Rule 7.2 leaves unobserved.

  Scenario Outline: A weekday that is no holiday trades
    Given the date is <date>
    Then it is a <day>
    And it is not a market holiday
    And it is a trading day

    Examples:
      | date       | day      |
      | 2026-07-02 | Thursday |
      | 2026-07-06 | Monday   |

  Scenario Outline: A weekend never trades
    Given the date is <date>
    Then it is a <day>
    And it is not a market holiday
    And the market is closed

    Examples:
      | date       | day      |
      | 2026-07-04 | Saturday |
      | 2026-07-05 | Sunday   |

  Scenario Outline: The ten holidays, each on its 2026 date
    Given the date is <date>
    Then it is a market holiday
    And the market is closed

    Examples:
      | date       | holiday                    |
      | 2026-01-01 | New Year's Day             |
      | 2026-01-19 | MLK Day                    |
      | 2026-02-16 | Presidents Day             |
      | 2026-04-03 | Good Friday                |
      | 2026-05-25 | Memorial Day               |
      | 2026-06-19 | Juneteenth                 |
      | 2026-07-03 | Independence Day, observed |
      | 2026-09-07 | Labor Day                  |
      | 2026-11-26 | Thanksgiving               |
      | 2026-12-25 | Christmas                  |

  Scenario: A Saturday holiday closes the Friday before it
    Given the date is 2026-07-03
    Then it is a Friday
    And it is a market holiday
    And the market is closed

  Scenario: A Sunday holiday closes the Monday after it
    Given the date is 2023-01-02
    Then it is a Monday
    And it is a market holiday
    And the market is closed

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
