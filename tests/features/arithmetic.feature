Feature: Days between two dates count civil days, signed

  Days to expiration and an option's year fraction both count the
  calendar days from one date to another: every day counts, trading or
  not, and a date in the past counts back as a negative number.

  Scenario Outline: From one date to another
    Then there are <days> days from <from> to <to>

    Examples:
      | from       | to         | days |
      | 2026-07-10 | 2026-07-10 | 0    |
      | 2026-07-10 | 2026-07-13 | 3    |
      | 2026-02-28 | 2026-03-01 | 1    |
      | 2028-02-28 | 2028-03-01 | 2    |
      | 2026-07-13 | 2026-07-10 | -3   |
