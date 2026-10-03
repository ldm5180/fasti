Feature: SPXW expires every trading day, so a chain fetch counts trading days

  A chain fetch asks for the next expirations from and including the
  day it runs.  SPXW expires every trading day, so the expirations are
  the trading days: weekends and holidays are stepped over.

  Scenario: The Thursday before the Fourth, then the week after
    Given a chain fetch on 2026-07-02 wants 4 expirations
    Then it finds 4
    And the expirations are:
      | 2026-07-02 |
      | 2026-07-06 |
      | 2026-07-07 |
      | 2026-07-08 |

  Scenario: A fetch on a Saturday starts at the next trading day
    Given a chain fetch on 2026-07-04 wants 1 expiration
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
