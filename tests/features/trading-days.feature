Feature: The market closes on weekends and ten holidays

  Scenario: A Thursday trades
    Given the date is 2026-07-02
    Then it is a Thursday
    And it is a trading day

  Scenario: The observed Fourth is closed
    Given the date is 2026-07-03
    Then the market is closed
